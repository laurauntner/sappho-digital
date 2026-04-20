import requests
import time
import uuid 
import xml.etree.ElementTree as ET
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
WD = "https://www.wikidata.org/entity/"
WDCOM = "http://commons.wikimedia.org/wiki/Special:FilePath/"
NS = {"tei": "http://www.tei-c.org/ns/1.0"}
XML_NS = "{http://www.w3.org/XML/1998/namespace}"

# -----------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------

# Infrastruktur-Typen
IDTYPE_LABELS: dict[str, tuple[str, str]] = {
    "sappho-digital": ("Sappho-Digital-ID",  "Sappho Digital ID"),
    "wikidata":       ("Wikidata-ID",         "Wikidata ID"),
    "gnd":            ("GND-ID",              "GND ID"),
    "viaf":           ("VIAF-ID",             "VIAF ID"),
    "dbpedia":        ("DBpedia-ID",          "DBpedia ID"),
}

GENDER_LABELS: dict[str, tuple[str, str]] = {
    "Q6581072": ("weiblich", "female"),
    "Q6581097": ("männlich", "male"),
}

GENDER_TYPE_LABELS: tuple[str, str] = ("Wikidata-Geschlecht", "Wikidata Gender")


def add_bilingual(g: Graph, uri: URIRef, label_de: str, label_en: str) -> None:
    """Fügt rdfs:label in beiden Sprachen hinzu."""
    g.add((uri, RDFS.label, Literal(label_de, lang="de")))
    g.add((uri, RDFS.label, Literal(label_en, lang="en")))


def ensure_id_type(g: Graph, type_uri: URIRef, key: str) -> None:
    """Legt einen E55_Type-Knoten für einen Identifier-Typ an (einmalig, zweisprachig)."""
    if (type_uri, RDF.type, ECRM.E55_Type) not in g:
        label_de, label_en = IDTYPE_LABELS[key]
        g.add((type_uri, RDF.type, ECRM.E55_Type))
        add_bilingual(g, type_uri, label_de, label_en)


# RDF Graph
g = Graph()
g.bind(":", SD)
g.bind("ecrm", ECRM)
g.bind("rdfs", RDFS)
g.bind("xsd", XSD)
g.bind("prov", PROV)
g.bind("owl", OWL)

# -----------------------------------------------------------------------
# Hilfsfunktionen
# -----------------------------------------------------------------------

def _load_pubplace_index(xml_path: str) -> dict[str, str]:
    idx: dict[str, str] = {}
    try:
        root = ET.parse(xml_path).getroot()
    except Exception:
        return idx
    for el in root.findall(".//tei:pubPlace", NS):
        ref = (el.get("ref") or "").strip()
        xml_id = (el.get(f"{XML_NS}id") or "").strip()
        if not ref or not xml_id:
            continue
        if ref.startswith("http://www.wikidata.org/"):
            ref = "https://" + ref[len("http://"):]
        if ref.startswith("https://www.wikidata.org/entity/"):
            idx.setdefault(ref, xml_id)
    return idx

def _place_uri_from_index_or_random(pubplace_idx: dict[str, str], wikidata_qid: str):
    wd_uri = WD + wikidata_qid
    xml_id = pubplace_idx.get(wd_uri)
    if xml_id:
        return SD[f"place/{xml_id}"], wd_uri
    return SD[f"place/place_{uuid.uuid4().hex[:8]}"], wd_uri

_pubplace_idx = _load_pubplace_index(INPUT_FILE)

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

# -----------------------------------------------------------------------
# Autor_innen aus XML lesen
# -----------------------------------------------------------------------

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

    person_uri = SD[f"person/{xml_id}"]
    identifier_uri = SD[f"identifier/{xml_id}"]

    g.add((person_uri, RDF.type, ECRM.E21_Person))
    g.add((person_uri, RDFS.label, Literal(name, lang="de")))
    g.add((person_uri, ECRM.P1_is_identified_by, identifier_uri))

    g.add((identifier_uri, RDF.type, ECRM.E42_Identifier))
    g.add((identifier_uri, RDFS.label, Literal(xml_id)))
    g.add((identifier_uri, ECRM.P1i_identifies, person_uri))
    g.add((identifier_uri, ECRM.P2_has_type, SD["id_type/sappho-digital"]))
    ensure_id_type(g, SD["id_type/sappho-digital"], "sappho-digital")

    # Wikidata-Verlinkung
    wikidata_ref = el.get("ref")
    if wikidata_ref and "wikidata.org/entity/" in wikidata_ref:
        qid = wikidata_ref.split("/")[-1]
        entity = fetch_wikidata(qid)

        # Wikidata-Identifier
        wd_id_uri = SD[f"identifier/{qid}"]
        g.add((person_uri, ECRM.P1_is_identified_by, wd_id_uri))
        g.add((wd_id_uri, RDF.type, ECRM.E42_Identifier))
        g.add((wd_id_uri, RDFS.label, Literal(qid)))
        g.add((wd_id_uri, ECRM.P1i_identifies, person_uri))
        g.add((wd_id_uri, ECRM.P2_has_type, SD["id_type/wikidata"]))

        ensure_id_type(g, SD["id_type/wikidata"], "wikidata")
        g.add((SD["id_type/wikidata"], ECRM.P2i_is_type_of, wd_id_uri))
        g.add((SD["id_type/wikidata"], OWL.sameAs, URIRef("http://wikidata.org/entity/Q43649390")))

        g.add((person_uri, OWL.sameAs, URIRef(WD + qid)))

        ensure_id_type(g, SD["id_type/dbpedia"], "dbpedia")
        ensure_id_type(g, SD["id_type/gnd"],     "gnd")
        ensure_id_type(g, SD["id_type/viaf"],    "viaf")

        # DBpedia
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
            g.add((db_id_uri, RDFS.label, Literal(db_key)))
            g.add((db_id_uri, ECRM.P1i_identifies, person_uri))
            g.add((db_id_uri, ECRM.P2_has_type, SD["id_type/dbpedia"]))
            g.add((person_uri, OWL.sameAs, URIRef(link)))

        # GND
        for gnd in set(get_claim_vals(entity, "P227", expect="str")):
            gnd = (gnd or "").strip().replace(" ", "")
            if not gnd:
                continue
            gnd_uri = SD[f"identifier/{gnd}"]
            g.add((person_uri, ECRM.P1_is_identified_by, gnd_uri))
            g.add((gnd_uri, RDF.type, ECRM.E42_Identifier))
            g.add((gnd_uri, RDFS.label, Literal(gnd)))
            g.add((gnd_uri, ECRM.P1i_identifies, person_uri))
            g.add((gnd_uri, ECRM.P2_has_type, SD["id_type/gnd"]))
            g.add((person_uri, OWL.sameAs, URIRef(f"https://d-nb.info/gnd/{gnd}")))

        # VIAF
        for viaf in set(get_claim_vals(entity, "P214", expect="str")):
            viaf = (viaf or "").strip().replace(" ", "")
            if not viaf:
                continue
            viaf_uri = SD[f"identifier/{viaf}"]
            g.add((person_uri, ECRM.P1_is_identified_by, viaf_uri))
            g.add((viaf_uri, RDF.type, ECRM.E42_Identifier))
            g.add((viaf_uri, RDFS.label, Literal(viaf)))
            g.add((viaf_uri, ECRM.P1i_identifies, person_uri))
            g.add((viaf_uri, ECRM.P2_has_type, SD["id_type/viaf"]))
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
            add_bilingual(g, birth_uri, f"Geburt von {name}", f"Birth of {name}")
            g.add((birth_uri, ECRM["P4_has_time-span"], time_uri))
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
            add_bilingual(g, death_uri, f"Tod von {name}", f"Death of {name}")
            g.add((death_uri, ECRM.P100_was_death_of, person_uri))
            g.add((death_uri, ECRM["P4_has_time-span"], time_uri))
            g.add((death_uri, PROV.wasDerivedFrom, URIRef(WD + qid)))
            g.add((time_uri, RDF.type, ECRM["E52_Time-Span"]))
            g.add((time_uri, RDFS.label, safe_date_literal(ddate)))
            g.add((time_uri, ECRM["P4i_is_time-span_of"], death_uri))

        # Geburtsort
        birth_place_qid = get_claim_val(entity, "P19")
        if birth_place_qid:
            place_entity = fetch_wikidata(birth_place_qid)
            place_label_de = (place_entity.get("labels", {}).get("de", {}).get("value")
                              or place_entity.get("labels", {}).get("en", {}).get("value")
                              or birth_place_qid)
            place_label_en = (place_entity.get("labels", {}).get("en", {}).get("value")
                              or place_label_de)
            place_uri, same_as = _place_uri_from_index_or_random(_pubplace_idx, birth_place_qid)
            g.add((place_uri, RDF.type, ECRM.E53_Place))
            add_bilingual(g, place_uri, place_label_de, place_label_en)
            g.add((place_uri, OWL.sameAs, URIRef(same_as)))
            g.add((place_uri, ECRM["P7i_witnessed"], SD[f"birth/{xml_id}"]))

        # Sterbeort
        death_place_qid = get_claim_val(entity, "P20")
        if death_place_qid:
            place_entity = fetch_wikidata(death_place_qid)
            place_label_de = (place_entity.get("labels", {}).get("de", {}).get("value")
                              or place_entity.get("labels", {}).get("en", {}).get("value")
                              or death_place_qid)
            place_label_en = (place_entity.get("labels", {}).get("en", {}).get("value")
                              or place_label_de)
            place_uri, same_as = _place_uri_from_index_or_random(_pubplace_idx, death_place_qid)
            g.add((place_uri, RDF.type, ECRM.E53_Place))
            add_bilingual(g, place_uri, place_label_de, place_label_en)
            g.add((place_uri, OWL.sameAs, URIRef(same_as)))
            g.add((place_uri, ECRM["P7i_witnessed"], SD[f"death/{xml_id}"]))

        # Geschlecht
        gender_qid = get_claim_val(entity, "P21")
        if gender_qid:
            if gender_qid in GENDER_LABELS:
                g_label_de, g_label_en = GENDER_LABELS[gender_qid]
            else:
                fallback = get_label(fetch_wikidata(gender_qid)) or gender_qid
                g_label_de, g_label_en = fallback, fallback

            gender_uri = SD[f"gender/{gender_qid}"]
            gender_type_uri = SD["gender_type/wikidata"]

            g.add((gender_uri, RDF.type, ECRM.E55_Type))
            add_bilingual(g, gender_uri, g_label_de, g_label_en)
            g.add((gender_uri, OWL.sameAs, URIRef(WD + gender_qid)))
            g.add((gender_uri, ECRM.P2i_is_type_of, person_uri))
            g.add((person_uri, ECRM.P2_has_type, gender_uri))

            if (gender_type_uri, RDF.type, ECRM.E55_Type) not in g:
                g.add((gender_type_uri, RDF.type, ECRM.E55_Type))
                add_bilingual(g, gender_type_uri, *GENDER_TYPE_LABELS)
            g.add((gender_uri, ECRM.P2_has_type, gender_type_uri))

        # Bild
        image = get_claim_val(entity, "P18", val_type=None)
        if image:
            img_name = image.replace(" ", "_")
            vis_uri = SD[f"visual_item/{xml_id}"]
            g.add((vis_uri, RDFS.seeAlso, URIRef(WDCOM + img_name)))
            g.add((vis_uri, PROV.wasDerivedFrom, URIRef(WD + qid)))
            g.add((vis_uri, RDF.type, ECRM.E36_Visual_Item))
            add_bilingual(g, vis_uri,
                          f"Bildliche Darstellung von {name}",
                          f"Visual representation of {name}")
            g.add((vis_uri, ECRM.P138_represents, person_uri))
            g.add((person_uri, ECRM.P138i_has_representation, vis_uri))

# -----------------------------------------------------------------------
# Speichern
# -----------------------------------------------------------------------
Path(OUTPUT_FILE).parent.mkdir(parents=True, exist_ok=True)
g.serialize(destination=OUTPUT_FILE, format="turtle")

xml_output = OUTPUT_FILE.replace(".ttl", ".rdf")
g.serialize(destination=xml_output, format="pretty-xml")

jsonld_output = OUTPUT_FILE.replace(".ttl", ".jsonld")
g.serialize(destination=jsonld_output, format="json-ld")