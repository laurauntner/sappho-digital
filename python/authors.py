import requests
import time
from lxml import etree
from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, XSD, OWL
from pathlib import Path
from datetime import datetime
from typing import Optional

SESSION = requests.Session()
SESSION.headers.update({
    "User-Agent": "SapphoDigital/1.0 (+mailto:laura.untner@fu-berlin.de)"
})
_WD_CACHE: dict[str, dict] = {}

# Pfade
INPUT_FILE = "../data/lists/sappho-rez_alle.xml"
OUTPUT_FILE = "../data/rdf/authors.ttl"

# Namespaces
SD = Namespace("https://sappho-digital.com/")
ECRM = Namespace("http://erlangen-crm.org/current/")
PROV = Namespace("http://www.w3.org/ns/prov#")
WD = "http://www.wikidata.org/entity/"
WDCOM = "http://commons.wikimedia.org/wiki/Special:FilePath/"
NS = {"tei": "http://www.tei-c.org/ns/1.0"}

# RDF Graph
g = Graph()
g.bind(":", SD)
g.bind("ecrm", ECRM)
g.bind("rdfs", RDFS)
g.bind("xsd", XSD)
g.bind("prov", PROV)
g.bind("owl", OWL)

# Hilfsfunktionen

def normalize_id(name):
    return name.strip().lower().replace(" ", "_")

def fetch_wikidata(qid: str) -> dict:
    if not qid:
        return {}
    if qid in _WD_CACHE:
        return _WD_CACHE[qid]

    url = f"https://www.wikidata.org/wiki/Special:EntityData/{qid}.json"
    for attempt in range(3):
        try:
            r = SESSION.get(url, timeout=15)
            if r.status_code == 200:
                data = r.json().get("entities", {}).get(qid, {})
                if data:
                    _WD_CACHE[qid] = data
                    return data
            if r.status_code in (429, 503):
                time.sleep(1.5 * (attempt + 1))
                continue
            break
        except requests.RequestException:
            time.sleep(1.0 * (attempt + 1))
            continue
    return {}

def get_claim_val(entity, prop, val_type="id"):
    claims = entity.get("claims", {}).get(prop)
    if not claims:
        return None
    val = claims[0]["mainsnak"]["datavalue"]["value"]
    return val.get(val_type) if isinstance(val, dict) else val

def safe_date_literal(date_str):
    if not date_str or len(date_str) != 10:
        return Literal(date_str)
    try:
        datetime.strptime(date_str, "%Y-%m-%d")
        return Literal(date_str, datatype=XSD.date)
    except ValueError:
        return Literal(date_str)

def get_label(entity):
    labels = entity.get("labels", {})
    return (
        labels.get("de", {}).get("value") or
        labels.get("en", {}).get("value")
    )

# IDs über Wikidata
def get_claim_vals(entity, prop, expect="auto"):
    vals = []
    for cl in entity.get("claims", {}).get(prop, []):
        val = cl.get("mainsnak", {}).get("datavalue", {}).get("value")
        if val is None:
            continue
        if isinstance(val, dict):
            if expect == "id":
                v = val.get("id")
                if v: vals.append(v)
            elif expect in ("url", "auto"):
                v = val.get("id") or val.get("value")
                if isinstance(v, str):
                    vals.append(v)
            else:
                v = val.get("id") or val.get("value")
                if v: vals.append(str(v))
        else:
            vals.append(str(val))
    return vals

def ensure_id_type(g, type_uri, label_en):
    if (type_uri, RDF.type, ECRM.E55_Type) not in g:
        g.add((type_uri, RDF.type, ECRM.E55_Type))
        g.add((type_uri, RDFS.label, Literal(label_en, lang="en")))

def normalize_dbpedia_url(url: Optional[str]) -> Optional[str]:
    if not url:
        return None
    u = url.strip()
    if u.startswith("http://"):
        u = "https://" + u[len("http://"):]
    u = u.replace("://dbpedia.org/page/", "://dbpedia.org/resource/")
    return u if u.startswith("https://dbpedia.org/") else None

def dbpedia_from_sitelinks(entity: dict) -> Optional[str]:
    sl = entity.get("sitelinks", {}) or {}
    title = None
    if "enwiki" in sl:
        title = sl["enwiki"].get("title")
    elif "dewiki" in sl:
        title = sl["dewiki"].get("title")
    else:
        for k, v in sl.items():
            if k.endswith("wiki") and isinstance(v, dict) and v.get("title"):
                title = v["title"]
                break
    if not title:
        return None
    return f"https://dbpedia.org/resource/{title.replace(' ', '_')}"

# Autor_innen aus XML lesen
parser = etree.XMLParser(recover=True)
tree = etree.parse(INPUT_FILE, parser=parser)
root = tree.getroot()
authors = root.findall(".//tei:author", namespaces=NS)
seen = set()

for el in authors:
    name = el.text.strip()
    xml_id = el.get("{http://www.w3.org/XML/1998/namespace}id")
    if not xml_id:
        continue
    if (xml_id, el.text.strip()) in seen:
        continue
    seen.add((xml_id, el.text.strip()))

    norm_id = xml_id
    person_uri = SD[f"person/{xml_id}"]
    appellation_uri = SD[f"appellation/{xml_id}"]
    identifier_uri = SD[f"identifier/{xml_id}"]

    g.add((person_uri, RDF.type, ECRM.E21_Person))
    g.add((person_uri, RDFS.label, Literal(name, lang="de")))
    g.add((person_uri, ECRM.P131_is_identified_by, appellation_uri))
    g.add((person_uri, ECRM.P1_is_identified_by, identifier_uri))

    g.add((appellation_uri, RDF.type, ECRM.E82_Actor_Appellation))
    g.add((appellation_uri, RDFS.label, Literal(name, lang="de")))
    g.add((appellation_uri, ECRM.P131i_identifies, person_uri))

    g.add((identifier_uri, RDF.type, ECRM.E42_Identifier))
    g.add((identifier_uri, RDFS.label, Literal(xml_id)))
    g.add((identifier_uri, ECRM.P1i_identifies, person_uri))
    g.add((identifier_uri, ECRM.P2_has_type, SD["id_type/sappho-digital"]))

    # Wikidata-Verlinkung
    wikidata_ref = el.get("ref")
    if wikidata_ref and "wikidata.org/entity/" in wikidata_ref:
        qid = wikidata_ref.split("/")[-1]
        entity = fetch_wikidata(qid)

        # Extra Identifier
        wd_id_uri = SD[f"identifier/{qid}"]
        g.add((person_uri, ECRM.P1_is_identified_by, wd_id_uri))
        g.add((wd_id_uri, RDF.type, ECRM.E42_Identifier))
        g.add((wd_id_uri, RDFS.label, Literal(qid)))
        g.add((wd_id_uri, ECRM.P1i_identifies, person_uri))
        g.add((wd_id_uri, ECRM.P2_has_type, SD["id_type/wikidata"]))

        g.add((SD["id_type/wikidata"], RDF.type, ECRM.E55_Type))
        g.add((SD["id_type/wikidata"], RDFS.label, Literal("Wikidata ID", lang="en")))
        g.add((SD["id_type/wikidata"], ECRM.P2i_is_type_of, wd_id_uri))
        g.add((SD["id_type/wikidata"], OWL.sameAs, URIRef("http://wikidata.org/entity/Q43649390")))

        g.add((person_uri, OWL.sameAs, URIRef(WD + qid)))

        idtype_dbpedia = SD["id_type/dbpedia"]
        idtype_gnd     = SD["id_type/gnd"]
        idtype_viaf    = SD["id_type/viaf"]
        if (idtype_dbpedia, RDF.type, ECRM.E55_Type) not in g:
            g.add((idtype_dbpedia, RDF.type, ECRM.E55_Type))
            g.add((idtype_dbpedia, RDFS.label, Literal("DBpedia ID", lang="en")))
        if (idtype_gnd, RDF.type, ECRM.E55_Type) not in g:
            g.add((idtype_gnd, RDF.type, ECRM.E55_Type))
            g.add((idtype_gnd, RDFS.label, Literal("GND ID", lang="en")))
        if (idtype_viaf, RDF.type, ECRM.E55_Type) not in g:
            g.add((idtype_viaf, RDF.type, ECRM.E55_Type))
            g.add((idtype_viaf, RDFS.label, Literal("VIAF ID", lang="en")))

        dbpedia_links = set()
        for p in ("P2888", "P1709"):
            for raw in get_claim_vals(entity, p, expect="url"):
                norm = normalize_dbpedia_url(raw)
                if norm:
                    dbpedia_links.add(norm)
        if not dbpedia_links:
            maybe = normalize_dbpedia_url(dbpedia_from_sitelinks(entity))
            if maybe:
                dbpedia_links.add(maybe)

        for link in dbpedia_links:
            db_key = link.rsplit("/", 1)[-1] or "resource"
            db_id_uri = SD[f"identifier/{db_key}"]
            g.add((person_uri, ECRM.P1_is_identified_by, db_id_uri))
            g.add((db_id_uri, RDF.type, ECRM.E42_Identifier))
            db_label = link.rsplit("/", 1)[-1]
            g.add((db_id_uri, RDFS.label, Literal(db_label)))
            g.add((db_id_uri, ECRM.P1i_identifies, person_uri))
            g.add((db_id_uri, ECRM.P2_has_type, idtype_dbpedia))
            g.add((person_uri, OWL.sameAs, URIRef(link)))

        for gnd in set(get_claim_vals(entity, "P227", expect="str")):
            gnd = (gnd or "").strip().replace(" ", "")
            if not gnd:
                continue
            gnd_uri = SD[f"identifier/{gnd}"]
            g.add((person_uri, ECRM.P1_is_identified_by, gnd_uri))
            g.add((gnd_uri, RDF.type, ECRM.E42_Identifier))
            g.add((gnd_uri, RDFS.label, Literal(gnd)))
            g.add((gnd_uri, ECRM.P1i_identifies, person_uri))
            g.add((gnd_uri, ECRM.P2_has_type, idtype_gnd))
            g.add((person_uri, OWL.sameAs, URIRef(f"https://d-nb.info/gnd/{gnd}")))

        for viaf in set(get_claim_vals(entity, "P214", expect="str")):
            viaf = (viaf or "").strip().replace(" ", "")
            if not viaf:
                continue
            viaf_uri = SD[f"identifier/{viaf}"]
            g.add((person_uri, ECRM.P1_is_identified_by, viaf_uri))
            g.add((viaf_uri, RDF.type, ECRM.E42_Identifier))
            g.add((viaf_uri, RDFS.label, Literal(viaf)))
            g.add((viaf_uri, ECRM.P1i_identifies, person_uri))
            g.add((viaf_uri, ECRM.P2_has_type, idtype_viaf))
            g.add((person_uri, OWL.sameAs, URIRef(f"https://viaf.org/viaf/{viaf}")))

        # Geburtsdatum
        birth_date = get_claim_val(entity, "P569", "time")
        if birth_date:
            bdate = birth_date.lstrip("+")[:10]
            b_id = bdate.replace("-", "")
            birth_uri = SD[f"birth/{xml_id}"]
            time_uri = SD[f"timespan/{b_id}"]
            g.add((person_uri, ECRM.P98i_was_born, birth_uri))
            g.add((birth_uri, RDF.type, ECRM.E67_Birth))
            g.add((birth_uri, RDFS.label, Literal(f"Birth of {name}", lang="en")))
            g.add((birth_uri, ECRM.P4_has_time_span, time_uri))
            g.add((birth_uri, ECRM.P98_brought_into_life, person_uri))
            g.add((birth_uri, PROV.wasDerivedFrom, URIRef(WD + qid)))
            g.add((time_uri, RDF.type, ECRM["E52_Time-Span"]))
            g.add((time_uri, RDFS.label, safe_date_literal(bdate)))
            g.add((time_uri, ECRM["P4i_is_time-span_of"], birth_uri))

        # Sterbedatum
        death_date = get_claim_val(entity, "P570", "time")
        if death_date:
            ddate = death_date.lstrip("+")[:10]
            d_id = ddate.replace("-", "")
            death_uri = SD[f"death/{xml_id}"]
            time_uri = SD[f"timespan/{d_id}"]
            g.add((person_uri, ECRM.P100i_died_in, death_uri))
            g.add((death_uri, RDF.type, ECRM.E69_Death))
            g.add((death_uri, RDFS.label, Literal(f"Death of {name}", lang="en")))
            g.add((death_uri, ECRM.P100_was_death_of, person_uri))
            g.add((death_uri, ECRM.P4_has_time_span, time_uri))
            g.add((death_uri, PROV.wasDerivedFrom, URIRef(WD + qid)))
            g.add((time_uri, RDF.type, ECRM["E52_Time-Span"]))
            g.add((time_uri, RDFS.label, safe_date_literal(ddate)))
            g.add((time_uri, ECRM["P4i_is_time-span_of"], death_uri))

        # Geburtsort
        birth_place_qid = get_claim_val(entity, "P19")
        if birth_place_qid:
            place_uri = SD[f"place/{birth_place_qid}"]
            place_label = get_label(fetch_wikidata(birth_place_qid)) or birth_place_qid
            g.add((place_uri, RDF.type, ECRM.E53_Place))
            g.add((place_uri, RDFS.label, Literal(place_label, lang="de")))
            g.add((place_uri, OWL.sameAs, URIRef(WD + birth_place_qid)))
            g.add((place_uri, ECRM["P7i_witnessed"], SD[f"birth/{xml_id}"]))

        # Sterbeort
        death_place_qid = get_claim_val(entity, "P20")
        if death_place_qid:
            place_uri = SD[f"place/{death_place_qid}"]
            place_label = get_label(fetch_wikidata(death_place_qid)) or death_place_qid
            g.add((place_uri, RDF.type, ECRM.E53_Place))
            g.add((place_uri, RDFS.label, Literal(place_label, lang="de")))
            g.add((place_uri, OWL.sameAs, URIRef(WD + death_place_qid)))
            g.add((place_uri, ECRM["P7i_witnessed"], SD[f"death/{xml_id}"]))

        # Geschlecht
        GENDER_LABELS = {
            "Q6581072": "female",
            "Q6581097": "male",
        }
        gender_qid = get_claim_val(entity, "P21")
        if gender_qid:
            gender_label = GENDER_LABELS.get(gender_qid) or get_label(fetch_wikidata(gender_qid)) or gender_qid
            gender_uri = SD[f"gender/{gender_qid}"]
            gender_type_uri = SD["gender_type/wikidata"]

            # Gender-Instanz
            g.add((gender_uri, RDF.type, ECRM.E55_Type))
            g.add((gender_uri, RDFS.label, Literal(gender_label, lang="en")))
            g.add((gender_uri, OWL.sameAs, URIRef(WD + gender_qid)))
            g.add((gender_uri, ECRM.P2i_is_type_of, person_uri))
            g.add((person_uri, ECRM.P2_has_type, gender_uri))

            # Typ-Verknüpfung
            if not (gender_type_uri, RDF.type, ECRM.E55_Type) in g:
                g.add((gender_type_uri, RDF.type, ECRM.E55_Type))
                g.add((gender_type_uri, RDFS.label, Literal("Wikidata Gender", lang="en")))
            g.add((gender_type_uri, ECRM.P2i_is_type_of, gender_uri))

        # Bild
        image = get_claim_val(entity, "P18", val_type=None)
        if image:
            img_name = image.replace(" ", "_")
            img_uri = SD[f"image/{xml_id}"]
            vis_uri = SD[f"visual_item/{xml_id}"]
            g.add((img_uri, RDF.type, ECRM.E38_Image))
            g.add((img_uri, ECRM.P65_shows_visual_item, vis_uri))
            g.add((img_uri, RDFS.seeAlso, URIRef(WDCOM + img_name)))
            g.add((img_uri, PROV.wasDerivedFrom, URIRef(WD + qid)))
            g.add((vis_uri, RDF.type, ECRM.E36_Visual_Item))
            g.add((vis_uri, RDFS.label, Literal(f"Visual representation of {name}", lang="en")))
            g.add((vis_uri, ECRM.P138_represents, person_uri))
            g.add((vis_uri, ECRM.P65i_is_shown_by, img_uri))

# Speichern
Path(OUTPUT_FILE).parent.mkdir(parents=True, exist_ok=True)
g.serialize(destination=OUTPUT_FILE, format="turtle")