import csv
import time
import requests
from pathlib import Path
from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, XSD, OWL
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
INPUT_FILE = "../data/sappho_fragments_qids.csv"
OUTPUT_FILE = "../data/rdf/fragments.ttl"

# Namespaces
SD = Namespace("https://sappho-digital.com/")
ECRM = Namespace("http://erlangen-crm.org/current/")
LRMOO = Namespace("http://www.cidoc-crm.org/lrmoo/")
WD = "http://www.wikidata.org/entity/"

# Graph
g = Graph()
g.bind("", SD)
g.bind("ecrm", ECRM)
g.bind("lrmoo", LRMOO)
g.bind("rdfs", RDFS)
g.bind("xsd", XSD)
g.bind("owl", OWL)

# Einmalige Knoten / Typen

# ID-Typen
g.add((SD["id_type/sappho-digital"], RDF.type, ECRM.E55_Type))
g.add((SD["id_type/sappho-digital"], RDFS.label, Literal("Sappho Digital ID", lang="en")))

g.add((SD["id_type/wikidata"], RDF.type, ECRM.E55_Type))
g.add((SD["id_type/wikidata"], RDFS.label, Literal("Wikidata ID", lang="en")))

g.add((SD["id_type/dbpedia"], RDF.type, ECRM.E55_Type))
g.add((SD["id_type/dbpedia"], RDFS.label, Literal("DBpedia ID", lang="en")))

g.add((SD["id_type/goodreads"], RDF.type, ECRM.E55_Type))
g.add((SD["id_type/goodreads"], RDFS.label, Literal("Goodreads Work ID", lang="en")))

# Geschlechtstypen
g.add((SD["gender/female"], RDF.type, ECRM.E55_Type))
g.add((SD["gender/female"], RDFS.label, Literal("female", lang="en")))
g.add((SD["gender/female"], OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q6581072")))

g.add((SD["gender/male"], RDF.type, ECRM.E55_Type))
g.add((SD["gender/male"], RDFS.label, Literal("male", lang="en")))
g.add((SD["gender/male"], OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q6581097")))

g.add((SD["gender_type/wikidata"], RDF.type, ECRM.E55_Type))
g.add((SD["gender_type/wikidata"], RDFS.label, Literal("Wikidata Gender", lang="en")))
g.add((SD["gender_type/wikidata"], ECRM.P2i_is_type_of, SD["gender/female"]))
g.add((SD["gender_type/wikidata"], ECRM.P2i_is_type_of, SD["gender/male"]))

g.add((SD["gender/female"], ECRM.P2_has_type, SD["gender_type/wikidata"]))
g.add((SD["gender/male"], ECRM.P2_has_type, SD["gender_type/wikidata"]))

# Genre
g.add((SD["genre/lyrik"], RDF.type, ECRM.E55_Type))
g.add((SD["genre/lyrik"], RDFS.label, Literal("Lyrik", lang="de")))
g.add((SD["genre/lyrik"], ECRM.P2_has_type, SD["genre_type/sappho-digital"]))

g.add((SD["genre_type/sappho-digital"], RDF.type, ECRM.E55_Type))
g.add((SD["genre_type/sappho-digital"], RDFS.label, Literal("Sappho Digital Genre", lang="en")))
g.add((SD["genre_type/sappho-digital"], ECRM.P2i_is_type_of, SD["genre/lyrik"]))

# Autorin Sappho
g.add((SD["person/author_sappho"], RDF.type, ECRM.E21_Person))
g.add((SD["person/author_sappho"], RDFS.label, Literal("Sappho")))
g.add((SD["person/author_sappho"], ECRM.P131_is_identified_by, SD["appellation/author_sappho"]))
g.add((SD["person/author_sappho"], ECRM.P1_is_identified_by, SD["identifier/Q17892"]))
g.add((SD["person/author_sappho"], ECRM.P1_is_identified_by, SD["identifier/author_sappho"]))
g.add((SD["person/author_sappho"], ECRM.P2_has_type, SD["gender/female"]))
g.add((SD["person/author_sappho"], OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q17892")))

# Appellation Sappho
g.add((SD["appellation/author_sappho"], RDF.type, ECRM.E82_Actor_Appellation))
g.add((SD["appellation/author_sappho"], RDFS.label, Literal("Sappho", lang="en")))
g.add((SD["appellation/author_sappho"], ECRM.P131i_identifies, SD["person/author_sappho"]))

# Identifiers Sappho
g.add((SD["identifier/author_sappho"], RDF.type, ECRM.E42_Identifier))
g.add((SD["identifier/author_sappho"], RDFS.label, Literal("author_sappho")))
g.add((SD["identifier/author_sappho"], ECRM.P1i_identifies, SD["person/author_sappho"]))
g.add((SD["identifier/author_sappho"], ECRM.P2_has_type, SD["id_type/sappho-digital"]))
g.add((SD["id_type/sappho-digital"], ECRM.P2i_is_type_of, SD["identifier/author_sappho"]))

g.add((SD["identifier/Q17892"], RDF.type, ECRM.E42_Identifier))
g.add((SD["identifier/Q17892"], RDFS.label, Literal("Q17892")))
g.add((SD["identifier/Q17892"], ECRM.P1i_identifies, SD["person/author_sappho"]))
g.add((SD["identifier/Q17892"], ECRM.P2_has_type, SD["id_type/wikidata"]))
g.add((SD["id_type/wikidata"], ECRM.P2i_is_type_of, SD["identifier/Q17892"]))

# Editor Bagordo
g.add((SD["person/editor_bagordo"], RDF.type, ECRM.E21_Person))
g.add((SD["person/editor_bagordo"], RDFS.label, Literal("Andreas Bagordo")))
g.add((SD["person/editor_bagordo"], ECRM.P131_is_identified_by, SD["appellation/editor_bagordo"]))
g.add((SD["person/editor_bagordo"], ECRM.P1_is_identified_by, SD["identifier/Q495907"]))
g.add((SD["person/editor_bagordo"], ECRM.P1_is_identified_by, SD["identifier/editor_bagordo"]))
g.add((SD["person/editor_bagordo"], ECRM.P2_has_type, SD["gender/male"]))
g.add((SD["person/editor_bagordo"], OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q495907")))

g.add((SD["appellation/editor_bagordo"], RDF.type, ECRM.E82_Actor_Appellation))
g.add((SD["appellation/editor_bagordo"], RDFS.label, Literal("Andreas Bagordo", lang="en")))
g.add((SD["appellation/editor_bagordo"], ECRM.P131i_identifies, SD["person/editor_bagordo"]))

g.add((SD["identifier/editor_bagordo"], RDF.type, ECRM.E42_Identifier))
g.add((SD["identifier/editor_bagordo"], RDFS.label, Literal("editor_bagordo")))
g.add((SD["identifier/editor_bagordo"], ECRM.P1i_identifies, SD["person/editor_bagordo"]))
g.add((SD["identifier/editor_bagordo"], ECRM.P2_has_type, SD["id_type/sappho-digital"]))
g.add((SD["id_type/sappho-digital"], ECRM.P2i_is_type_of, SD["identifier/editor_bagordo"]))

g.add((SD["identifier/Q495907"], RDF.type, ECRM.E42_Identifier))
g.add((SD["identifier/Q495907"], RDFS.label, Literal("Q495907")))
g.add((SD["identifier/Q495907"], ECRM.P1i_identifies, SD["person/editor_bagordo"]))
g.add((SD["identifier/Q495907"], ECRM.P2_has_type, SD["id_type/wikidata"]))
g.add((SD["id_type/wikidata"], ECRM.P2i_is_type_of, SD["identifier/Q495907"]))

# Gesamtwerk
g.add((SD["work/sappho-work"], RDF.type, LRMOO.F1_Work))
g.add((SD["work/sappho-work"], RDFS.label, Literal("Sappho’s Work", lang="en")))
g.add((SD["work/sappho-work"], ECRM.P14_carried_out_by, SD["person/author_sappho"]))
g.add((SD["work/sappho-work"], LRMOO.R16i_was_created_by, SD["work_creation/sappho-work"]))

g.add((SD["work_creation/sappho-work"], RDF.type, LRMOO.F27_Work_Creation))
g.add((SD["work_creation/sappho-work"], RDFS.label, Literal("Creation of Sappho’s Work", lang="en")))
g.add((SD["work_creation/sappho-work"], ECRM.P14_carried_out_by, SD["person/author_sappho"]))
g.add((SD["work_creation/sappho-work"], LRMOO.R16_created, SD["work/sappho-work"]))

# Andreas Bagordos Edition
manifestation_uri = SD["manifestation/sappho_bagordo"]
manifestation_creation_uri = SD["manifestation_creation/sappho_bagordo"]
title_uri = SD["title/manifestation/sappho_bagordo"]
title_string_uri = SD["title_string/manifestation/sappho_bagordo"]
pub_place_uri = SD["pubPlace/pubPlace_42b32e43"]
publisher_uri = SD["publisher/publisher_patmos"]
time_span_uri = SD["timespan/2009"]

# Manifestation
g.add((manifestation_uri, RDF.type, LRMOO.F3_Manifestation))
g.add((manifestation_uri, RDFS.label, Literal("Andreas Bagordo’s Sappho edition", lang="en")))
g.add((manifestation_uri, LRMOO.R24i_was_created_through, manifestation_creation_uri))
g.add((manifestation_uri, ECRM.P102_has_title, title_uri))

# Manifestation Creation
g.add((manifestation_creation_uri, RDF.type, LRMOO.F30_Manifestation_Creation))
g.add((manifestation_creation_uri, RDFS.label, Literal("Manifestation creation of Andreas Bagordo’s Sappho edition", lang="en")))
g.add((manifestation_creation_uri, LRMOO.R24_created, manifestation_uri))
g.add((manifestation_creation_uri, ECRM.P14_carried_out_by, SD["person/editor_bagordo"]))
g.add((manifestation_creation_uri, ECRM.P14_carried_out_by, publisher_uri))
g.add((manifestation_creation_uri, ECRM["P4_has_time-span"], time_span_uri))
g.add((manifestation_creation_uri, ECRM.P7_took_place_at, pub_place_uri))

# Title
g.add((title_uri, RDF.type, ECRM.E35_Title))
g.add((title_uri, ECRM.P102i_is_title_of, manifestation_uri))
g.add((title_uri, ECRM.P190_has_symbolic_content, title_string_uri))

g.add((title_string_uri, RDF.type, ECRM.E62_String))
g.add((title_string_uri, RDFS.label, Literal("Sappho. Gedichte. Griechisch-Deutsch", lang="de")))
g.add((title_string_uri, ECRM.P190i_is_content_of, title_uri))

# Publisher
g.add((publisher_uri, RDF.type, ECRM.E40_Legal_Body))
g.add((publisher_uri, RDFS.label, Literal("Patmos", lang="en")))
g.add((publisher_uri, ECRM.P14i_performed, manifestation_creation_uri))
g.add((publisher_uri, OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q1463096")))

# Publication Place
g.add((pub_place_uri, RDF.type, ECRM.E53_Place))
g.add((pub_place_uri, RDFS.label, Literal("Düsseldorf", lang="en")))
g.add((pub_place_uri, ECRM.P7i_witnessed, manifestation_creation_uri))
g.add((pub_place_uri, OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q1718")))

# Time-Span
g.add((time_span_uri, RDF.type, ECRM["E52_Time-Span"]))
g.add((time_span_uri, RDFS.label, Literal("2009", datatype=XSD.gYear)))
g.add((time_span_uri, ECRM["P4i_is_time-span_of"], manifestation_creation_uri))

# Fragmente einlesen
all_expressions = []
all_fragments = []

with open(INPUT_FILE, newline='', encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter=';')
    for row in reader:
        qid_url = row["Wikidata Link"]
        label = row["Wikidata Label"]
        db_id = row["Database"]

        if "21351,1–8" in label:
            frag_id = "bibl_sappho_21351_1-8"
            frag_num = "21351,1–8"
        elif "21351+21376r" in label:
            frag_id = "bibl_sappho_21351_9-12_21376r_1-8"
            frag_num = "21351,9–12+21376r,1–8"
        else:
            frag_num = db_id
            frag_id = f"bibl_sappho_{frag_num}"

        frag_uri = SD[f"fragment/{frag_id}"]
        expr_uri = SD[f"expression/{frag_id}"]
        all_expressions.append(expr_uri)
        all_fragments.append(frag_uri)
        expr_creation_uri = SD[f"expression_creation/{frag_id}"]
        title_uri = SD[f"title/expression/{frag_id}"]
        title_str_uri = SD[f"title_string/expression/{frag_id}"]

        g.add((frag_uri, RDF.type, ECRM.E90_Symbolic_Object))
        g.add((frag_uri, RDFS.label, Literal(f"Fragment {frag_num} Voigt", lang="en")))
        g.add((frag_uri, LRMOO.R10i_is_member_of, SD["work/sappho-work"]))

        g.add((expr_creation_uri, RDF.type, LRMOO.F28_Expression_Creation))
        g.add((expr_creation_uri, RDFS.label, Literal(f"Expression creation of Fragment {frag_num} Voigt", lang="en")))
        g.add((expr_creation_uri, ECRM.P14_carried_out_by, SD["person/editor_bagordo"]))
        g.add((expr_creation_uri, LRMOO.R17_created, expr_uri))
        g.add((expr_creation_uri, LRMOO.R19_created_a_realisation_of, frag_uri))

        g.add((expr_uri, RDF.type, LRMOO.F2_Expression))
        g.add((expr_uri, RDFS.label, Literal(f"Expression of Fragment {frag_num} Voigt", lang="en")))
        g.add((expr_uri, LRMOO.R3i_realises, frag_uri))
        g.add((expr_uri, LRMOO.R17i_was_created_by, expr_creation_uri))
        g.add((expr_uri, ECRM.P102_has_title, title_uri))
        g.add((expr_uri, ECRM.P2_has_type, SD["genre/lyrik"]))
        g.add((expr_uri, LRMOO.R4i_is_embodied_in, SD["manifestation/sappho_bagordo"]))
        g.add((expr_uri, OWL.sameAs, URIRef(qid_url)))

        g.add((title_uri, RDF.type, ECRM.E35_Title))
        g.add((title_uri, ECRM.P102i_is_title_of, expr_uri))
        g.add((title_uri, ECRM.P190_has_symbolic_content, title_str_uri))

        g.add((title_str_uri, RDF.type, ECRM.E62_String))
        g.add((title_str_uri, RDFS.label, Literal(f"Fragment {frag_num} Voigt", lang="de")))
        g.add((title_str_uri, ECRM.P190i_is_content_of, title_uri))

        qid = qid_url.split("/")[-1]
        g.add((SD[f"identifier/{qid}"], RDF.type, ECRM.E42_Identifier))
        g.add((SD[f"identifier/{qid}"], RDFS.label, Literal(qid)))
        g.add((SD[f"identifier/{qid}"], ECRM.P1i_identifies, expr_uri))
        g.add((SD[f"identifier/{qid}"], ECRM.P2_has_type, SD["id_type/wikidata"]))
        g.add((SD["id_type/wikidata"], ECRM.P2i_is_type_of, SD[f"identifier/{qid}"]))

        g.add((SD[f"identifier/{frag_id}"], RDF.type, ECRM.E42_Identifier))
        g.add((SD[f"identifier/{frag_id}"], RDFS.label, Literal(frag_id)))
        g.add((SD[f"identifier/{frag_id}"], ECRM.P1i_identifies, expr_uri))
        g.add((SD[f"identifier/{frag_id}"], ECRM.P2_has_type, SD["id_type/sappho-digital"]))
        g.add((SD["id_type/sappho-digital"], ECRM.P2i_is_type_of, SD[f"identifier/{frag_id}"]))

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
            g.add((expr_uri, ECRM.P1_is_identified_by, db_id_uri))
            g.add((db_id_uri, RDF.type, ECRM.E42_Identifier))
            g.add((db_id_uri, RDFS.label, Literal(db_key))) 
            g.add((db_id_uri, ECRM.P1i_identifies, expr_uri))
            g.add((db_id_uri, ECRM.P2_has_type, SD["id_type/dbpedia"]))
            g.add((expr_uri, OWL.sameAs, URIRef(link)))

        # Goodreads Work (P8383)
        for gr in set(get_claim_vals(entity, "P8383", expect="str")):
            gr = (gr or "").strip()
            if not gr:
                continue
            gr_uri = SD[f"identifier/{gr}"]
            g.add((expr_uri, ECRM.P1_is_identified_by, gr_uri))
            g.add((gr_uri, RDF.type, ECRM.E42_Identifier))
            g.add((gr_uri, RDFS.label, Literal(gr)))
            g.add((gr_uri, ECRM.P1i_identifies, expr_uri))
            g.add((gr_uri, ECRM.P2_has_type, SD["id_type/goodreads"]))
            g.add((expr_uri, OWL.sameAs, URIRef(f"https://www.goodreads.com/work/show/{gr}")))

work_uri = SD["work/sappho-work"]
for frag_uri in all_fragments:
    g.add((work_uri, LRMOO.R10_has_member, frag_uri))

# Manifestation-Knoten (Sammel-Embodiment)
manifestation_uri = SD["manifestation/sappho_bagordo"]
g.add((manifestation_uri, RDF.type, LRMOO.F3_Manifestation))
g.add((manifestation_uri, RDFS.label, Literal("Andreas Bagordo’s Sappho edition", lang="en")))

for expr_uri in all_expressions:
    g.add((manifestation_uri, LRMOO.R4_embodies, expr_uri))

# Speichern
Path(OUTPUT_FILE).parent.mkdir(parents=True, exist_ok=True)
g.serialize(destination=OUTPUT_FILE, format="turtle")

xml_output = OUTPUT_FILE.replace(".ttl", ".rdf")
g.serialize(destination=xml_output, format="pretty-xml")