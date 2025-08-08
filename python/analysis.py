from pathlib import Path
import hashlib
import re
import xml.etree.ElementTree as ET
from typing import Optional

from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, XSD

# Pfade

XML_DIR = Path("../../doktorat/Diss/Sappho-Rezeption/XML")
WORKS_TTL = Path("../data/rdf/works.ttl")         
FRAGMENTS_TTL = Path("../data/rdf/fragments.ttl") 
OUT_TTL = Path("../data/rdf/analysis.ttl")

BASE = "https://sappho-digital.com/"

# Namespaces

LRMOO = Namespace("http://www.cidoc-crm.org/lrmoo/")
ECRM  = Namespace("http://www.cidoc-crm.org/cidoc-crm/")
INTRO = Namespace("https://w3id.org/lso/intro/currentbeta#")
BASENS = Namespace(BASE)

# Hilfsfunktionen

def stable_id(val: str, length: int = 8) -> str:
    h = hashlib.sha1((val or "").encode("utf-8")).hexdigest()
    return h[:length]

def with_prefix(prefix: str, val: str) -> str:
    return f"{prefix}_{stable_id(val)}"

def uri(path: str) -> URIRef:
    return URIRef(BASE + path.lstrip("/"))

def text_or_type(elem) -> str:
    t = elem.get("type")
    if t and t.strip():
        return t.strip()
    if elem.text and elem.text.strip():
        return elem.text.strip()
    return ""

def literal_text(x) -> str:
    if isinstance(x, Literal):
        return str(x)
    return str(x) if x is not None else ""

# F2/E90 einlesen

g_src = Graph()
if WORKS_TTL.exists():
    g_src.parse(WORKS_TTL.as_posix(), format="turtle")
if FRAGMENTS_TTL.exists():
    g_src.parse(FRAGMENTS_TTL.as_posix(), format="turtle")

text_index = {}
for s, _, otype in g_src.triples((None, RDF.type, None)):
    s_str = str(s)
    if otype == LRMOO.F2_Expression and "/expression/" in s_str:
        tid = s_str.rsplit("/", 1)[-1]
        label = next(g_src.objects(s, RDFS.label), None)
        text_index[tid] = {"uri": s, "type": "F2", "label": label}
    elif otype == ECRM.E90_Symbolic_Object and "/fragment/" in s_str:
        tid = s_str.rsplit("/", 1)[-1]
        label = next(g_src.objects(s, RDFS.label), None)
        text_index[tid] = {"uri": s, "type": "E90", "label": label}

# Graph

g = Graph()
g.bind("", BASENS)
g.bind("lrmoo", LRMOO)
g.bind("ecrm", ECRM)
g.bind("intro", INTRO)
g.bind("rdfs", RDFS)
g.bind("xsd", XSD)

IDTYPE_URI = uri("id_type/sappho-digital")
g.add((IDTYPE_URI, RDF.type, ECRM.E55_Type))
g.add((IDTYPE_URI, RDFS.label, Literal("Sappho Digital ID", lang="en")))

TYPE_LABEL_DE = {
    "character": "character",
    "motif": "motif",
    "plot": "plot",
    "topic": "topic",
    "work_ref": "work",
    "place_ref": "place",
    "person_ref": "person",
}

def add_identifier(g: Graph, id_str: str, thing_uri: URIRef):
    ident_uri = uri(f"identifier/{id_str}")
    g.add((ident_uri, RDF.type, ECRM.E42_Identifier))
    g.add((ident_uri, RDFS.label, Literal(id_str, lang="en")))
    g.add((ident_uri, ECRM.P1i_identifies, thing_uri))
    g.add((ident_uri, ECRM.P2_has_type, IDTYPE_URI))
    g.add((IDTYPE_URI, ECRM.P2i_is_type_of, ident_uri))
    return ident_uri

def add_actualization_common(
    g: Graph,
    kind: str,
    text_id: str,
    feature_id_suffix: str,   
    feature_uri: URIRef,
    feature_label: str,
    text_res_uri: URIRef,
    text_title: str,
    refers_to_uri: Optional[URIRef] = None
):

    typ = TYPE_LABEL_DE.get(kind, "Feature")
    act_id = f"{text_id}_{feature_id_suffix}"
    act_uri = uri(f"actualization/{kind}/{act_id}")

    # Actualization des Features
    g.add((act_uri, RDF.type, INTRO.INT2_ActualizationOfFeature))
    g.add((act_uri, RDFS.label, Literal(f"{feature_label} ({typ}) in {text_title}", lang="de")))
    g.add((act_uri, INTRO.R17_actualizesFeature, feature_uri))
    g.add((act_uri, INTRO.R18i_actualizationFoundOn, text_res_uri))
    if refers_to_uri is not None:
        g.add((act_uri, ECRM.P67_refers_to, refers_to_uri))

    # Inverse vom Feature
    g.add((feature_uri, INTRO.R17i_featureIsActualizedIn, act_uri))

    # Interpretation-Feature
    interp_feat_uri = uri(f"feature/interpretation/{act_id}")
    g.add((interp_feat_uri, RDF.type, INTRO.INT_Interpretation))
    g.add((interp_feat_uri, RDFS.label, Literal(f"Interpretation von {feature_label} ({typ}) in {text_title}", lang="de")))
    g.add((interp_feat_uri, INTRO.R17i_featureIsActualizedIn, uri(f"actualization/interpretation/{act_id}")))

    # Interpretation-Actualization
    interp_act_uri = uri(f"actualization/interpretation/{act_id}")
    g.add((interp_act_uri, RDF.type, INTRO.INT2_ActualizationOfFeature))
    g.add((interp_act_uri, RDFS.label, Literal(f"Interpretation von {feature_label} ({typ}) in {text_title}", lang="de")))
    g.add((interp_act_uri, INTRO.R17_actualizesFeature, interp_feat_uri))
    g.add((interp_act_uri, INTRO.R21_identifies, act_uri))

    return act_uri

# XML einlesen und Analyseelemente sammeln

elements_per_text = {} 
distinct_value_to_id = {k: {} for k in ["figur","motiv","stoff","thema","werk","ort","person"]}

distinct_phrase_to_id = {}  
phrase_to_texts = {}        

def get_or_make_distinct(cat: str, value: str) -> str:
    if value not in distinct_value_to_id[cat]:
        prefix = {
            "figur": "character",
            "motiv": "motif",
            "stoff": "plot",
            "thema": "topic",
            "werk": "work_ref",
            "ort": "place",
            "person": "person",
        }[cat]
        distinct_value_to_id[cat][value] = with_prefix(prefix, value)
    return distinct_value_to_id[cat][value]

for xml_file in sorted(XML_DIR.glob("*.xml")):
    try:
        root = ET.parse(xml_file).getroot()
    except Exception as e:
        print(f"Warn: konnte {xml_file} nicht parsen: {e}")
        continue

    tid_elem = root.find(".//id")
    if tid_elem is None or not (tid_elem.text and tid_elem.text.strip()):
        print(f"Warn: {xml_file} ohne <id>")
        continue
    text_id = tid_elem.text.strip()

    cats = {k: [] for k in ["figur","motiv","stoff","thema","phrase","werk","ort","person"]}

    for k in cats.keys():
        for el in root.findall(f".//{k}"):
            val = text_or_type(el)
            if not val:
                continue
            cats[k].append(val)

    for phr in cats["phrase"]:
        if phr not in distinct_phrase_to_id:
            distinct_phrase_to_id[phr] = f"textpassage_{stable_id(phr)}"
        phrase_to_texts.setdefault(phr, set()).add(text_id)

    elements_per_text[text_id] = cats

    for k in ["figur","motiv","stoff","thema","werk","ort","person"]:
        for v in cats[k]:
            _ = get_or_make_distinct(k, v)

# Instanzen erzeugen

for text_id, cats in elements_per_text.items():
    txt = text_index.get(text_id) or text_index.get(text_id.replace("bibl_", "")) or text_index.get(f"bibl_{text_id}")
    if not txt and "sappho" in text_id.lower():
        txt = text_index.get(text_id) or text_index.get(f"bibl_{text_id}")

    if not txt:
        print(f"Warn: Keine F2/E90-Instanz für {text_id} gefunden.")
        continue

    text_uri = txt["uri"]
    text_title = literal_text(txt["label"]) or text_id

    for p, o in g_src.predicate_objects(text_uri):
        g.add((text_uri, p, o))

    # INT_Character
    for v in cats["figur"]:
        fid = get_or_make_distinct("figur", v)
        feat_uri = uri(f"feature/character/{fid}")
        g.add((feat_uri, RDF.type, INTRO.INT_Character))
        g.add((feat_uri, RDFS.label, Literal(f"Character: {v}", lang="de")))
        add_identifier(g, fid, feat_uri)
        act_uri = add_actualization_common(
            g, "character", text_id, fid, feat_uri, v, text_uri, text_title
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT_Motif
    for v in cats["motiv"]:
        fid = get_or_make_distinct("motiv", v)
        feat_uri = uri(f"feature/motif/{fid}")
        g.add((feat_uri, RDF.type, INTRO.INT_Motif))
        g.add((feat_uri, RDFS.label, Literal(f"Motif: {v}", lang="de")))
        add_identifier(g, fid, feat_uri)
        act_uri = add_actualization_common(
            g, "motif", text_id, fid, feat_uri, v, text_uri, text_title
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT_Plot
    for v in cats["stoff"]:
        fid = get_or_make_distinct("stoff", v)
        feat_uri = uri(f"feature/plot/{fid}")
        g.add((feat_uri, RDF.type, INTRO.INT_Plot))
        g.add((feat_uri, RDFS.label, Literal(f"Plot: {v}", lang="de")))
        add_identifier(g, fid, feat_uri)
        act_uri = add_actualization_common(
            g, "plot", text_id, fid, feat_uri, v, text_uri, text_title
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT_Topic
    for v in cats["thema"]:
        fid = get_or_make_distinct("thema", v) 
        feat_uri = uri(f"feature/topic/{fid}")
        g.add((feat_uri, RDF.type, INTRO.INT_Topic))
        g.add((feat_uri, RDFS.label, Literal(f"Topic: {v}", lang="de")))
        add_identifier(g, fid, feat_uri)
        act_uri = add_actualization_common(
            g, "topic", text_id, fid, feat_uri, v, text_uri, text_title
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT18_Reference: WORK
    for v in cats["werk"]:
        feat_uri = uri(f"feature/work_ref/{text_id}_{v}")
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))

        target = (text_index.get(v)
                  or text_index.get(v.replace("bibl_", ""))
                  or text_index.get(f"bibl_{v}"))
        ref_target_uri = target["uri"] if target else None
        ref_label = literal_text(target["label"]) if (target and target.get("label")) else v

        g.add((feat_uri, RDFS.label, Literal(f"Reference to {ref_label} (work)", lang="en")))

        act_uri = add_actualization_common(
            g, "work_ref", text_id, v, feat_uri, ref_label, text_uri, text_title,
            refers_to_uri=ref_target_uri
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

        if ref_target_uri is not None:
            g.add((ref_target_uri, ECRM.P67i_is_referred_to_by, act_uri))
            for p, o in g_src.predicate_objects(ref_target_uri):
                g.add((ref_target_uri, p, o))

    # INT18_Reference: PLACE
    for v in cats["ort"]:
        pid = get_or_make_distinct("ort", v)  
        feat_uri = uri(f"feature/place_ref/{pid}")
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))
        g.add((feat_uri, RDFS.label, Literal(f"Reference to {v} (place)", lang="en")))
        place_uri = uri(f"place/{pid}")
        g.add((place_uri, RDF.type, ECRM.E53_Place))
        g.add((place_uri, RDFS.label, Literal(v, lang="en")))
        add_identifier(g, pid, place_uri)
        act_uri = add_actualization_common(
            g, "place_ref", text_id, pid, feat_uri, v, text_uri, text_title,
            refers_to_uri=place_uri
        )
        g.add((place_uri, ECRM.P67i_is_referred_to_by, act_uri))
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT18_Reference: PERSON
    for v in cats["person"]:
        per_id = get_or_make_distinct("person", v)
        feat_uri = uri(f"feature/person_ref/{per_id}")
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))
        g.add((feat_uri, RDFS.label, Literal(f"Reference to {v} (person)", lang="en")))
        person_uri = uri(f"person/{per_id}")
        g.add((person_uri, RDF.type, ECRM.E21_Person))
        g.add((person_uri, RDFS.label, Literal(v, lang="en")))
        add_identifier(g, per_id, person_uri)
        act_uri = add_actualization_common(
            g, "person_ref", text_id, per_id, feat_uri, v, text_uri, text_title,
            refers_to_uri=person_uri
        )
        g.add((person_uri, ECRM.P67i_is_referred_to_by, act_uri))
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

# INT21_TextPassage: 1x pro Korpus + Verlinkungen zu allen Texten

for phr, pid in distinct_phrase_to_id.items():
    tp_uri = uri(f"textpassage/{pid}")
    g.add((tp_uri, RDF.type, INTRO.INT21_TextPassage))
    g.add((tp_uri, RDFS.label, Literal(f"Textpassage: {phr}", lang="de")))
    for tid in sorted(phrase_to_texts.get(phr, [])):
        txt = text_index.get(tid) or text_index.get(tid.replace("bibl_", "")) or text_index.get(f"bibl_{tid}")
        if not txt and "sappho" in tid.lower():
            txt = text_index.get(tid) or text_index.get(f"bibl_{tid}")
        if not txt:
            continue
        text_uri = txt["uri"]
        g.add((tp_uri, INTRO.R30i_isTextPassageOf, text_uri))
        g.add((text_uri, INTRO.R30_hasTextPassage, tp_uri))

# Schreiben

OUT_TTL.parent.mkdir(parents=True, exist_ok=True)
g.serialize(destination=OUT_TTL.as_posix(), format="turtle")
