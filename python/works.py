import requests
import time
from lxml import etree
from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, XSD, OWL
from pathlib import Path
from typing import Optional

# Wikidata
SESSION = requests.Session()
SESSION.headers.update({
    "User-Agent": "SapphoDigital/1.0 (+mailto:laura.untner@fu-berlin.de)"
})
_WD_CACHE: dict[str, dict] = {}

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

def get_p625_coords_as_string(entity: dict) -> list[str]:
    coords = []
    for cl in entity.get("claims", {}).get("P625", []):
        val = cl.get("mainsnak", {}).get("datavalue", {}).get("value")
        if not isinstance(val, dict):
            continue
        lat = val.get("latitude")
        lon = val.get("longitude")
        if lat is None or lon is None:
            continue
        coords.append(f"{lat}, {lon}")
    return coords

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

# Pfade
INPUT_FILE = "../data/lists/sappho-rez_alle.xml"
OUTPUT_FILE = "../data/rdf/works.ttl"

# Namespaces
NSMAP = {"tei": "http://www.tei-c.org/ns/1.0"}
SD = Namespace("https://sappho-digital.com/")
ECRM = Namespace("http://erlangen-crm.org/current/")
LRMOO = Namespace("http://iflastandards.info/ns/lrm/lrmoo/")
WD = "http://www.wikidata.org/entity/"
WDCOM = "http://commons.wikimedia.org/wiki/Special:FilePath/"
XML_NS = "{http://www.w3.org/XML/1998/namespace}"

# Graph
g = Graph()
g.bind(":", SD)
g.bind("ecrm", ECRM)
g.bind("lrmoo", LRMOO)
g.bind("rdfs", RDFS)
g.bind("xsd", XSD)
g.bind("owl", OWL)

# XML parsen
parser = etree.XMLParser(recover=True)
tree = etree.parse(INPUT_FILE, parser=parser)
root = tree.getroot()
all_bibls = root.findall(".//tei:bibl", namespaces=NSMAP)
top_bibls = [b for b in all_bibls if b.getparent().tag != f"{{{NSMAP['tei']}}}bibl"]

# Hilfsfunktion: ID-Typen anlegen (einmalig)
def ensure_id_type(type_local: str, label_en: str):
    type_uri = SD[f"id_type/{type_local}"]
    if (type_uri, RDF.type, ECRM.E55_Type) not in g:
        g.add((type_uri, RDF.type, ECRM.E55_Type))
        g.add((type_uri, RDFS.label, Literal(label_en, lang="en")))
    return type_uri

idtype_wikidata = ensure_id_type("wikidata", "Wikidata ID")
idtype_dbpedia  = ensure_id_type("dbpedia",  "DBpedia ID")
idtype_gnd      = ensure_id_type("gnd",      "GND ID")
idtype_viaf     = ensure_id_type("viaf",     "VIAF ID")
idtype_gr       = ensure_id_type("goodreads","Goodreads Work ID")

def ensure_genre_type():
    gt_uri = SD["genre_type/sappho-digital"]
    if (gt_uri, RDF.type, ECRM.E55_Type) not in g:
        g.add((gt_uri, RDF.type, ECRM.E55_Type))
        g.add((gt_uri, RDFS.label, Literal("Sappho Digital Genre", lang="en")))
    return gt_uri

genre_type_uri = ensure_genre_type()

for bibl in top_bibls:
    bibl_id = bibl.get("{http://www.w3.org/XML/1998/namespace}id")
    if not bibl_id:
        continue

    bibl_uri = SD[f"expression/{bibl_id}"]
    creation_expr_uri = SD[f"expression_creation/{bibl_id}"]

    title_el = bibl.find("tei:title[@type='text']", namespaces=NSMAP)
    title_string = title_el.text.strip() if title_el is not None and title_el.text else None

    # Expression
    g.add((bibl_uri, RDF.type, LRMOO.F2_Expression))
    if title_string:
        g.add((bibl_uri, RDFS.label, Literal(title_string, lang="de")))
        title_uri = SD[f"title/expression/{bibl_id}"]
        title_string_uri = SD[f"title_string/expression/{bibl_id}"]
        g.add((bibl_uri, ECRM.P102_has_title, title_uri))
        g.add((title_uri, RDF.type, ECRM.E35_Title))
        g.add((title_uri, ECRM.P102i_is_title_of, bibl_uri))
        g.add((title_uri, ECRM.P190_has_symbolic_content, title_string_uri))
        g.add((title_string_uri, RDF.type, ECRM.E62_String))
        g.add((title_string_uri, RDFS.label, Literal(title_string, lang="de")))
        g.add((title_string_uri, ECRM.P190i_is_content_of, title_uri))

    g.add((bibl_uri, LRMOO.R17i_was_created_by, creation_expr_uri))

    # Expression Creation
    expr_label = title_string if title_string else "[??]"
    g.add((creation_expr_uri, RDF.type, LRMOO.F28_Expression_Creation))
    g.add((creation_expr_uri, RDFS.label, Literal(f"Expression creation of {expr_label}", lang="en")))
    g.add((creation_expr_uri, LRMOO.R17_created, bibl_uri))

    # Identifiers (lokale Sappho-ID)
    g.add((bibl_uri, ECRM.P1_is_identified_by, SD[f"identifier/{bibl_id}"]))
    g.add((SD[f"identifier/{bibl_id}"], RDF.type, ECRM.E42_Identifier))
    g.add((SD[f"identifier/{bibl_id}"], RDFS.label, Literal(bibl_id)))
    g.add((SD[f"identifier/{bibl_id}"], ECRM.P1i_identifies, bibl_uri))
    g.add((SD[f"identifier/{bibl_id}"], ECRM.P2_has_type, SD["id_type/sappho-digital"]))

    # Wikidata-Referenz am bibl
    ref = bibl.get("ref")
    if ref and "wikidata.org/entity/" in ref:
        g.add((bibl_uri, OWL.sameAs, URIRef(ref)))
        qid = ref.split("/")[-1]

        # Wikidata-Identifier für das Werk
        wd_id_uri = SD[f"identifier/{qid}"]
        g.add((bibl_uri, ECRM.P1_is_identified_by, wd_id_uri))
        g.add((wd_id_uri, RDF.type, ECRM.E42_Identifier))
        g.add((wd_id_uri, RDFS.label, Literal(qid)))
        g.add((wd_id_uri, ECRM.P1i_identifies, bibl_uri))
        g.add((wd_id_uri, ECRM.P2_has_type, idtype_wikidata))

        # Zusätzliche IDs über Wikidata
        entity = fetch_wikidata(qid)

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
            g.add((bibl_uri, ECRM.P1_is_identified_by, db_id_uri))
            g.add((db_id_uri, RDF.type, ECRM.E42_Identifier))
            # Label NUR der Teil nach /resource/
            g.add((db_id_uri, RDFS.label, Literal(db_key)))
            g.add((db_id_uri, ECRM.P1i_identifies, bibl_uri))
            g.add((db_id_uri, ECRM.P2_has_type, idtype_dbpedia))
            g.add((bibl_uri, OWL.sameAs, URIRef(link)))

        # GND (P227)
        for gnd in set(get_claim_vals(entity, "P227", expect="str")):
            gnd = (gnd or "").strip().replace(" ", "")
            if not gnd:
                continue
            gnd_uri = SD[f"identifier/{gnd}"]
            g.add((bibl_uri, ECRM.P1_is_identified_by, gnd_uri))
            g.add((gnd_uri, RDF.type, ECRM.E42_Identifier))
            g.add((gnd_uri, RDFS.label, Literal(gnd)))
            g.add((gnd_uri, ECRM.P1i_identifies, bibl_uri))
            g.add((gnd_uri, ECRM.P2_has_type, idtype_gnd))
            g.add((bibl_uri, OWL.sameAs, URIRef(f"https://d-nb.info/gnd/{gnd}")))

        # VIAF (P214)
        for viaf in set(get_claim_vals(entity, "P214", expect="str")):
            viaf = (viaf or "").strip().replace(" ", "")
            if not viaf:
                continue
            viaf_uri = SD[f"identifier/{viaf}"]
            g.add((bibl_uri, ECRM.P1_is_identified_by, viaf_uri))
            g.add((viaf_uri, RDF.type, ECRM.E42_Identifier))
            g.add((viaf_uri, RDFS.label, Literal(viaf)))
            g.add((viaf_uri, ECRM.P1i_identifies, bibl_uri))
            g.add((viaf_uri, ECRM.P2_has_type, idtype_viaf))
            g.add((bibl_uri, OWL.sameAs, URIRef(f"https://viaf.org/viaf/{viaf}")))

        # Goodreads Work (P8383)
        for gr in set(get_claim_vals(entity, "P8383", expect="str")):
            gr = (gr or "").strip()
            if not gr:
                continue
            gr_uri = SD[f"identifier/{gr}"]
            g.add((bibl_uri, ECRM.P1_is_identified_by, gr_uri))
            g.add((gr_uri, RDF.type, ECRM.E42_Identifier))
            g.add((gr_uri, RDFS.label, Literal(gr)))
            g.add((gr_uri, ECRM.P1i_identifies, bibl_uri))
            g.add((gr_uri, ECRM.P2_has_type, idtype_gr))
            # kanonischer Formatter für P8383:
            g.add((bibl_uri, OWL.sameAs, URIRef(f"https://www.goodreads.com/work/show/{gr}")))

        # Wikimedia Image
        img = next((v for v in get_claim_vals(entity, "P18", expect="auto") if v), None)
        if img:
            img_url = WDCOM + img.replace(" ", "_")
            g.add((bibl_uri, RDFS.seeAlso, URIRef(img_url)))

    # Digital Copy
    ref_el = bibl.find("tei:ref", namespaces=NSMAP)
    if ref_el is not None and ref_el.text:
        url = ref_el.text.strip()
        digital_uri = SD[f"digital/{bibl_id}"]
        g.add((digital_uri, RDF.type, ECRM.E73_Information_Object))
        digital_label = title_string or "[??]"
        g.add((digital_uri, RDFS.label, Literal(f"Digital copy of {digital_label}", lang="en")))
        g.add((digital_uri, ECRM.P138_represents, bibl_uri))
        g.add((digital_uri, RDFS.seeAlso, URIRef(url)))
        g.add((bibl_uri, ECRM.P138i_has_representation, digital_uri))

    # Dates
    date_created = bibl.find("tei:date[@type='created']", namespaces=NSMAP)
    date_published = bibl.find("tei:date[@type='published']", namespaces=NSMAP)

    if date_created is not None and "when" in date_created.attrib:
        year = date_created.get("when")
        ts_uri = SD[f"timespan/{year}"]
        g.add((ts_uri, RDF.type, ECRM["E52_Time-Span"]))
        g.add((ts_uri, RDFS.label, Literal(year, datatype=XSD.gYear)))
        g.add((ts_uri, ECRM["P4i_is_time-span_of"], creation_expr_uri))
        g.add((creation_expr_uri, ECRM.P4_has_time_span, ts_uri))

    # Manifestation
    if date_published is not None:
        nested_bibl = bibl.find("tei:bibl", namespaces=NSMAP)
        if nested_bibl is not None:
            nested_id = nested_bibl.get("{http://www.w3.org/XML/1998/namespace}id") or bibl_id
            work_title_el = nested_bibl.find("tei:title[@type='work']", namespaces=NSMAP)
            work_title = work_title_el.text.strip() if work_title_el is not None and work_title_el.text else None
        else:
            nested_id = bibl_id
            work_title = title_string

        final_manifestation_label = work_title or "[??]"
        manifestation_uri = SD[f"manifestation/{nested_id}"]
        creation_manif_uri = SD[f"manifestation_creation/{nested_id}"]

        g.add((manifestation_uri, RDF.type, LRMOO.F3_Manifestation))
        g.add((manifestation_uri, RDFS.label, Literal(final_manifestation_label, lang="de")))
        g.add((manifestation_uri, LRMOO.R4_embodies, bibl_uri))
        g.add((bibl_uri, LRMOO.R4i_is_embodied_in, manifestation_uri))

        g.add((creation_manif_uri, RDF.type, LRMOO.F30_Manifestation_Creation))
        g.add((creation_manif_uri, RDFS.label, Literal(f"Manifestation creation of {final_manifestation_label}", lang="en")))
        g.add((creation_manif_uri, LRMOO.R24_created, manifestation_uri))
        g.add((manifestation_uri, LRMOO.R24i_was_created_through, creation_manif_uri))

        # Zeitspanne
        if "when" in date_published.attrib:
            year_pub = date_published.get("when")
            ts_pub_uri = SD[f"timespan/{year_pub}"]
            g.add((ts_pub_uri, RDF.type, ECRM["E52_Time-Span"]))
            g.add((ts_pub_uri, RDFS.label, Literal(year_pub, datatype=XSD.gYear)))
            g.add((creation_manif_uri, ECRM.P4_has_time_span, ts_pub_uri))
            g.add((ts_pub_uri, ECRM["P4i_is_time-span_of"], creation_manif_uri))

        # Ort
        for pubplace_el in bibl.findall("tei:pubPlace", namespaces=NSMAP):
            place_qid = pubplace_el.get("ref")
            place_ref = pubplace_el.get(f"{XML_NS}id")
            place_label = pubplace_el.text.strip() if pubplace_el.text else "Unknown"

            place_uri = SD[f"place/{place_ref}"]
            g.add((place_uri, RDF.type, ECRM.E53_Place))
            g.add((place_uri, RDFS.label, Literal(place_label, lang="de")))

            qid = None
            if place_qid:
                g.add((place_uri, OWL.sameAs, URIRef(place_qid)))

                if place_qid.startswith("http"):
                    qid = place_qid.rstrip("/").split("/")[-1]
                else:
                    qid = place_qid.strip()

            if qid and qid.startswith("Q"):
                place_entity = fetch_wikidata(qid)
                for coord_str in set(get_p625_coords_as_string(place_entity)):
                    coord_key = f"{qid}-P625-{coord_str.replace(',', '').replace(' ', '_')}"
                    coord_uri = SD[f"spatial_coordinates/{coord_key}"]

                    g.add((coord_uri, RDF.type, ECRM.E47_Spatial_Coordinates))
                    g.add((coord_uri, RDFS.label, Literal(coord_str, datatype=XSD.string)))

                    g.add((place_uri, ECRM.P87_is_identified_by, coord_uri))
                    g.add((coord_uri, ECRM.P87i_identifies, place_uri))

            g.add((place_uri, ECRM.P7i_witnessed, creation_manif_uri))
            g.add((creation_manif_uri, ECRM.P7_took_place_at, place_uri))

        # Publisher
        for pub in bibl.findall("tei:publisher", namespaces=NSMAP):
            if pub.text:
                pub_label = pub.text.strip()
                pub_ref = pub.get("ref")
                pub_uri = (
                    SD[f"publisher/{pub_ref.split('/')[-1]}"]
                    if pub_ref else SD[f"publisher/{pub_label.replace(' ', '_')}"]
                )
                g.add((pub_uri, RDF.type, ECRM.E40_Legal_Body))
                g.add((pub_uri, RDFS.label, Literal(pub_label, lang="de")))
                if pub_ref:
                    g.add((pub_uri, OWL.sameAs, URIRef(pub_ref)))
                g.add((pub_uri, ECRM.P14i_performed, creation_manif_uri))
                g.add((creation_manif_uri, ECRM.P14_carried_out_by, pub_uri))

    # Autor_innen
    for auth in bibl.findall("tei:author", namespaces=NSMAP):
        auth_id = auth.get("{http://www.w3.org/XML/1998/namespace}id")
        if auth_id:
            person_uri = SD[f"person/{auth_id}"]
            g.add((person_uri, RDF.type, ECRM.E21_Person))
            if auth.text:
                g.add((person_uri, RDFS.label, Literal(auth.text.strip(), lang="de")))
            g.add((person_uri, ECRM.P14i_performed, creation_expr_uri))
            g.add((creation_expr_uri, ECRM.P14_carried_out_by, person_uri))
            if date_published is not None:
                g.add((person_uri, ECRM.P14i_performed, creation_manif_uri))

    # Gattung
    for genre_note in bibl.findall("tei:note[@type='genre']", namespaces=NSMAP):
        if not (genre_note.text and genre_note.text.strip()):
            continue

        raw_text = genre_note.text.strip()

        parts = [p.strip() for p in raw_text.split("/") if p.strip()]

        for part in parts:
            genre_key = part.rstrip("?").strip()
            if not genre_key:
                continue

            genre_uri = SD[f"genre/{genre_key}"]

            if (genre_uri, RDF.type, ECRM.E55_Type) not in g:
                g.add((genre_uri, RDF.type, ECRM.E55_Type))

                g.add((genre_uri, RDFS.label, Literal(genre_key, lang="de")))

                g.add((genre_uri, ECRM.P2_has_type, genre_type_uri))
                g.add((genre_type_uri, ECRM.P2i_is_type_of, genre_uri))

            g.add((bibl_uri, ECRM.P2_has_type, genre_uri))

# Speichern
Path(OUTPUT_FILE).parent.mkdir(parents=True, exist_ok=True)
g.serialize(destination=OUTPUT_FILE, format="turtle")

xml_output = OUTPUT_FILE.replace(".ttl", ".rdf")
g.serialize(destination=xml_output, format="pretty-xml")