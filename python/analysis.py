from pathlib import Path
import hashlib
import re
import xml.etree.ElementTree as ET
from typing import Optional, Dict, Tuple
from urllib.parse import quote
from collections import defaultdict

from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, XSD, SKOS

# Pfade

XML_DIR = Path("../../doktorat/Diss/Sappho-Rezeption/XML")
WORKS_TTL = Path("../data/rdf/works.ttl")
FRAGMENTS_TTL = Path("../data/rdf/fragments.ttl")
OUT_TTL = Path("../data/rdf/analysis.ttl")
VOCAB_TTL = Path("../data/rdf/vocab.ttl")

BASE = "https://sappho-digital.com/"

# Namespaces

LRMOO  = Namespace("http://www.cidoc-crm.org/lrmoo/")
ECRM   = Namespace("http://erlangen-crm.org/current/")
INTRO  = Namespace("https://w3id.org/lso/intro/currentbeta#")
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

def clean_uri_component(s: str) -> str:
    s = str(s)
    s_no_parens = re.sub(r"\s*\(.*?\)", "", s)
    s_underscores = s_no_parens.replace(" ", "_")
    return quote(s_underscores, safe="._-~")

def last_token(iri: str) -> str:
    return re.split(r"[#/]", iri)[-1]

# Quellgraph laden

g_src = Graph()
if WORKS_TTL.exists():
    g_src.parse(WORKS_TTL.as_posix(), format="turtle")
if FRAGMENTS_TTL.exists():
    g_src.parse(FRAGMENTS_TTL.as_posix(), format="turtle")

# Taxonomie laden + indexieren (per skos:prefLabel@de)
# sowie: Kategorien, um IDs/URIs abzuleiten

g_vocab = Graph()
if VOCAB_TTL.exists():
    g_vocab.parse(VOCAB_TTL.as_posix(), format="turtle")
else:
    print(f"Warn: Taxonomie {VOCAB_TTL} nicht gefunden – es werden keine skos:exactMatch-Verlinkungen gesetzt.")

# Heuristik: Präfixe je Kategorie
CAT_TO_VOC_PREFIX = {
    "motiv":  "https://sappho-digital.com/voc/motif_",
    "stoff":  "https://sappho-digital.com/voc/plot_",
    "thema":  "https://sappho-digital.com/voc/topic_",
    "werk":   "https://sappho-digital.com/voc/work_",
    "ort":    "https://sappho-digital.com/voc/place_",
    "person": "https://sappho-digital.com/voc/person_",
    "phrase": "https://sappho-digital.com/voc/phrase_",
    "werk":     "https://sappho-digital.com/voc/work_",
}

# Zielpfade (ohne /voc/) für lokale URIs je Kategorie
CAT_TO_LOCAL_PATH = {
    "motiv":  "feature/motif",  
    "stoff":  "feature/plot",  
    "thema":  "feature/topic",  
    "ort":    "place",       
    "person": "person",        
    "phrase": "textpassage",   
}

# Label-Index je Kategorie + globaler Fallback-Index
vocab_label_index: Dict[str, Dict[str, URIRef]] = {k: {} for k in CAT_TO_VOC_PREFIX.keys()}
vocab_label_global: Dict[str, URIRef] = {}

for s in g_vocab.subjects(RDF.type, SKOS.Concept):
    s_str = str(s)
    cat = None
    for k, pref in CAT_TO_VOC_PREFIX.items():
        if s_str.startswith(pref):
            cat = k
            break
    for lab in g_vocab.objects(s, SKOS.prefLabel):
        if isinstance(lab, Literal) and lab.language == "de":
            key = str(lab).strip().lower()
            if cat:
                vocab_label_index[cat].setdefault(key, s)
            vocab_label_global.setdefault(key, s)

def find_vocab(cat: Optional[str], label: str) -> Optional[URIRef]:
    lab_key = (label or "").strip().lower()
    cand = None
    if cat and vocab_label_index.get(cat):
        cand = vocab_label_index[cat].get(lab_key)
    if cand is None:
        cand = vocab_label_global.get(lab_key)
    return URIRef(cand) if cand else None

def local_uri_from_vocab(cat: str, vocab_uri: URIRef) -> Optional[URIRef]:
    local_path = CAT_TO_LOCAL_PATH.get(cat)
    if not local_path:
        return None
    token = last_token(str(vocab_uri))  # z.B. motif_a26b7...
    return uri(f"{local_path}/{token}")

def link_exact_match(node_uri: URIRef, vocab_uri: URIRef):
    g.add((node_uri, SKOS.exactMatch, vocab_uri))

# F2-Expressions-Index aufbauen (aus Quellgraph)

text_index = {}

def is_f2(typ) -> bool:
    t = str(typ)
    return t.endswith("F2_Expression")

def base_id(tid: str) -> str:
    return re.sub(r"^bibl_(?:sappho_)?", "", tid)

def make_keys_for_bibl_variants(tid: str):
    b = base_id(tid)
    return [f"bibl_{b}", f"bibl_sappho_{b}"]

for s, _, otype in g_src.triples((None, RDF.type, None)):
    if is_f2(otype):
        s_str = str(s)
        tid = last_token(s_str)
        label = next(g_src.objects(s, RDFS.label), None)
        for key in make_keys_for_bibl_variants(tid):
            text_index[key] = {"uri": s, "type": "F2", "label": label}

# Output-Graph

g = Graph()
g.bind("", BASENS)
g.bind("lrmoo", LRMOO)
g.bind("ecrm", ECRM)
g.bind("intro", INTRO)
g.bind("rdfs", RDFS)
g.bind("xsd", XSD)
g.bind("skos", SKOS)

IDTYPE_URI = uri("id_type/sappho-digital")
g.add((IDTYPE_URI, RDF.type, ECRM.E55_Type))
g.add((IDTYPE_URI, RDFS.label, Literal("Sappho Digital ID", lang="en")))

TYPE_LABEL_DE = {
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
    g.add((interp_feat_uri, RDFS.label, Literal(f"Interpretation of {feature_label} ({typ}) in {text_title}", lang="de")))
    g.add((interp_feat_uri, INTRO.R17i_featureIsActualizedIn, uri(f"actualization/interpretation/{act_id}")))

    # Interpretation-Actualization
    interp_act_uri = uri(f"actualization/interpretation/{act_id}")
    g.add((interp_act_uri, RDF.type, INTRO.INT2_ActualizationOfFeature))
    g.add((interp_act_uri, RDFS.label, Literal(f"Interpretation of {feature_label} ({typ}) in {text_title}", lang="de")))
    g.add((interp_act_uri, INTRO.R17_actualizesFeature, interp_feat_uri))
    g.add((interp_act_uri, INTRO.R21_identifies, act_uri))

    return act_uri

# XML einlesen & Daten sammeln (+ DF-Filterung >=2 Docs)

elements_per_text = {}
distinct_value_to_id = {k: {} for k in ["motiv","stoff","thema","werk","ort","person"]}

# Phrasen
distinct_phrase_to_id: Dict[str, str] = {}
phrase_to_texts: Dict[str, set] = {}

# Dokument-Frequenzen (Sets pro Wert)
doc_occurs = {
    "motiv": defaultdict(set),
    "thema": defaultdict(set),
    "ort": defaultdict(set),
    "person": defaultdict(set),
    "phrase": defaultdict(set),
    # "stoff" und "werk" sind explizit ausgenommen
}

def get_or_make_distinct(cat: str, value: str) -> str:
    if value not in distinct_value_to_id[cat]:
        prefix = {
            "motiv": "motif",
            "stoff": "plot",
            "thema": "topic",
            "werk":  "work_ref",
            "ort":   "place",
            "person":"person",
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

    cats = {k: [] for k in ["motiv","stoff","thema","phrase","werk","ort","person"]}

    for k in cats.keys():
        for el in root.findall(f".//{k}"):
            val = text_or_type(el)
            if not val:
                continue
            cats[k].append(val)

    # DF sammeln (Sets: Mehrfachnennungen im selben Dokument zählen nicht)
    for k in ["motiv","thema","ort","person"]:
        for v in set(cats[k]):
            doc_occurs[k][v].add(text_id)

    for phr in set(cats["phrase"]):
        phrase_to_texts.setdefault(phr, set()).add(text_id)
        doc_occurs["phrase"][phr].add(text_id)
        if phr not in distinct_phrase_to_id:
            # ID wird evtl. später durch Taxonomie-ID ersetzt
            distinct_phrase_to_id[phr] = f"textpassage_{stable_id(phr)}"

    elements_per_text[text_id] = cats

    for k in ["motiv","stoff","thema","werk","ort","person"]:
        for v in cats[k]:
            _ = get_or_make_distinct(k, v)

# Erlaubte Werte je Kategorie nach Filterregel (>= 2 Dokumente),
# Ausnahme: "stoff" und "werk"
allowed_values = {
    "motiv":  {v for v, s in doc_occurs["motiv"].items()  if len(s) >= 2},
    "thema":  {v for v, s in doc_occurs["thema"].items()  if len(s) >= 2},
    "ort":    {v for v, s in doc_occurs["ort"].items()    if len(s) >= 2},
    "person": {v for v, s in doc_occurs["person"].items() if len(s) >= 2},
    "phrase": {v for v, s in doc_occurs["phrase"].items() if len(s) >= 2},
}

def passes_filter(cat: str, val: str) -> bool:
    if cat in ("stoff", "werk"):
        return True
    return val in allowed_values.get(cat, set())

# Instanzen erzeugen

# Hilfsfunktionen zum Erzeugen mit Taxonomie-ID-Übernahme
def get_feature_uri_with_vocab(cat: str, label: str, fallback_id: str) -> Tuple[URIRef, str]:
    voc = find_vocab(cat, label)
    if voc:
        local = local_uri_from_vocab(cat, voc)
        if local is not None:
            used_id = last_token(str(voc))
            return local, used_id
    # Fallback: Logik mit Hash-ID
    return uri(f"{CAT_TO_LOCAL_PATH[cat]}/{fallback_id}"), fallback_id

def get_entity_uri_with_vocab(cat: str, label: str, fallback_id: str) -> Tuple[URIRef, str]:
    voc = find_vocab(cat, label)
    if voc:
        local = local_uri_from_vocab(cat, voc)
        if local is not None:
            used_id = last_token(str(voc))
            return local, used_id
    return uri(f"{CAT_TO_LOCAL_PATH[cat]}/{fallback_id}"), fallback_id

for text_id, cats in elements_per_text.items():
    txt = text_index.get(text_id)
    if not txt:
        print(f"Warn: Keine F2-Instanz für {text_id} gefunden.")
        continue

    text_uri = txt["uri"]
    text_title = literal_text(txt["label"]) or text_id

    # alle vorhandenen Aussagen zur F2 übernehmen
    for p, o in g_src.predicate_objects(text_uri):
        g.add((text_uri, p, o))

    # INT_Motif (Feature)
    for v in cats["motiv"]:
        if not passes_filter("motiv", v):
            continue
        fid_fallback = get_or_make_distinct("motiv", v) 
        feat_uri, used_id = get_feature_uri_with_vocab("motiv", v, fid_fallback)
        g.add((feat_uri, RDF.type, INTRO.INT_Motif))
        g.add((feat_uri, RDFS.label, Literal(f"Motif: {v}", lang="de")))
        add_identifier(g, used_id, feat_uri)
        voc = find_vocab("motiv", v)
        if voc:
            link_exact_match(feat_uri, voc)
        act_uri = add_actualization_common(
            g, "motif", text_id, used_id, feat_uri, v, text_uri, text_title
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT_Plot (Feature)
    for v in cats["stoff"]:
        fid_fallback = get_or_make_distinct("stoff", v)  
        feat_uri, used_id = get_feature_uri_with_vocab("stoff", v, fid_fallback)
        g.add((feat_uri, RDF.type, INTRO.INT_Plot))
        g.add((feat_uri, RDFS.label, Literal(f"Plot: {v}", lang="de")))
        add_identifier(g, used_id, feat_uri)
        voc = find_vocab("stoff", v)
        if voc:
            link_exact_match(feat_uri, voc)
        act_uri = add_actualization_common(
            g, "plot", text_id, used_id, feat_uri, v, text_uri, text_title
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT_Topic (Feature)
    for v in cats["thema"]:
        if not passes_filter("thema", v):
            continue
        fid_fallback = get_or_make_distinct("thema", v) 
        feat_uri, used_id = get_feature_uri_with_vocab("thema", v, fid_fallback)
        g.add((feat_uri, RDF.type, INTRO.INT_Topic))
        g.add((feat_uri, RDFS.label, Literal(f"Topic: {v}", lang="de")))
        add_identifier(g, used_id, feat_uri)
        voc = find_vocab("thema", v)
        if voc:
            link_exact_match(feat_uri, voc)
        act_uri = add_actualization_common(
            g, "topic", text_id, used_id, feat_uri, v, text_uri, text_title
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT18_Reference: WORK
    for v in cats["werk"]:
        v_clean = clean_uri_component(v)

        target = (text_index.get(v)
                or text_index.get(v.replace("bibl_", ""))
                or text_index.get(f"bibl_{v}"))
        ref_target_uri = target["uri"] if target else None
        ref_label = literal_text(target["label"]) if (target and target.get("label")) else v

        if ref_label.strip().lower() == "sappho-work":
            ref_label = "Sappho’s Work"

        voc = find_vocab("werk", ref_label)
        if voc:
            work_id = last_token(str(voc))             
            feat_id = work_id                    
        else:
            feat_id = f"{text_id}_{v_clean}"            

        feat_uri = uri(f"feature/work_ref/{feat_id}")
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))
        g.add((feat_uri, RDFS.label, Literal(f"Reference to {ref_label} (work)", lang="en")))

        if ref_target_uri is not None:
            voc_target = voc or find_vocab("werk", ref_label)
            if voc_target:
                link_exact_match(ref_target_uri, voc_target)

        act_uri = add_actualization_common(
            g, "work_ref", text_id, feat_id, feat_uri, ref_label, text_uri, text_title,
            refers_to_uri=ref_target_uri
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

        if ref_target_uri is not None:
            g.add((ref_target_uri, ECRM.P67i_is_referred_to_by, act_uri))
            for p, o in g_src.predicate_objects(ref_target_uri):
                g.add((ref_target_uri, p, o))


    # INT18_Reference: PLACE
    for v in cats["ort"]:
        if not passes_filter("ort", v):
            continue
        pid_fallback = get_or_make_distinct("ort", v) 
        place_uri_local, used_id = get_entity_uri_with_vocab("ort", v, pid_fallback)

        feat_uri = uri(f"feature/place_ref/{used_id}")  
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))
        g.add((feat_uri, RDFS.label, Literal(f"Reference to {v} (place)", lang="en")))

        g.add((place_uri_local, RDF.type, ECRM.E53_Place))
        g.add((place_uri_local, RDFS.label, Literal(v, lang="en")))
        add_identifier(g, used_id, place_uri_local)

        voc = find_vocab("ort", v)
        if voc:
            link_exact_match(place_uri_local, voc)

        act_uri = add_actualization_common(
            g, "place_ref", text_id, used_id, feat_uri, v, text_uri, text_title,
            refers_to_uri=place_uri_local
        )
        g.add((place_uri_local, ECRM.P67i_is_referred_to_by, act_uri))
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT18_Reference: PERSON
    for v in cats["person"]:
        if not passes_filter("person", v):
            continue
        per_fallback = get_or_make_distinct("person", v)  
        person_uri_local, used_id = get_entity_uri_with_vocab("person", v, per_fallback)

        feat_uri = uri(f"feature/person_ref/{used_id}")
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))
        g.add((feat_uri, RDFS.label, Literal(f"Reference to {v} (person)", lang="en")))

        g.add((person_uri_local, RDF.type, ECRM.E21_Person))
        g.add((person_uri_local, RDFS.label, Literal(v, lang="en")))
        add_identifier(g, used_id, person_uri_local)

        voc = find_vocab("person", v)
        if voc:
            link_exact_match(person_uri_local, voc)

        act_uri = add_actualization_common(
            g, "person_ref", text_id, used_id, feat_uri, v, text_uri, text_title,
            refers_to_uri=person_uri_local
        )
        g.add((person_uri_local, ECRM.P67i_is_referred_to_by, act_uri))
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

# INT21_TextPassage
for phr, old_pid in list(distinct_phrase_to_id.items()):
    docs = phrase_to_texts.get(phr, set())
    if len(docs) < 2:
        continue

    voc = find_vocab("phrase", phr)
    if voc:
        pid = last_token(str(voc))
        tp_uri = local_uri_from_vocab("phrase", voc)
    else:
        pid = old_pid
        tp_uri = uri(f"textpassage/{pid}")

    g.add((tp_uri, RDF.type, INTRO.INT21_TextPassage))
    g.add((tp_uri, RDFS.label, Literal(f"Textpassage: {phr}", lang="de")))
    if voc:
        link_exact_match(tp_uri, voc)

    for tid in sorted(docs):
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