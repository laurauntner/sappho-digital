from pathlib import Path
import hashlib
import re
import xml.etree.ElementTree as ET
from typing import Optional, Dict, Tuple
from urllib.parse import quote
from collections import defaultdict

from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, XSD, SKOS

# -----------------------------------------------------------------------
# Pfade
# -----------------------------------------------------------------------
XML_DIR      = Path("../../doktorat/Diss/Sappho-Rezeption/XML")
WORKS_TTL    = Path("../data/rdf/works.ttl")
FRAGMENTS_TTL = Path("../data/rdf/fragments.ttl")
OUT_TTL      = Path("../data/rdf/analysis.ttl")
VOCAB_TTL    = Path("../documentation/vocab/vocab.ttl")
VOCAB_RDF    = Path("../documentation/vocab/vocab.rdf")

BASE = "https://sappho-digital.com/"

# -----------------------------------------------------------------------
# Namespaces
# -----------------------------------------------------------------------
LRMOO  = Namespace("http://iflastandards.info/ns/lrm/lrmoo/")
ECRM   = Namespace("http://erlangen-crm.org/current/")
INTRO  = Namespace("https://w3id.org/lso/intro/currentbeta#")
BASENS = Namespace(BASE)

# -----------------------------------------------------------------------
# Zweisprachige Kategorienbezeichnungen
# -----------------------------------------------------------------------
CAT_LABELS: dict[str, tuple[str, str]] = {
    "motiv":      ("Motiv",    "Motif"),
    "stoff":      ("Stoff",    "Plot"),
    "thema":      ("Thema",    "Topic"),
    "topos":      ("Topos",    "Topos"),
    "werk":       ("Werk",     "Work"),
    "ort":        ("Ort",      "Place"),
    "person":     ("Person",   "Person"),
    "motif":      ("Motiv",    "Motif"),
    "plot":       ("Stoff",    "Plot"),
    "topic":      ("Thema",    "Topic"),
    "work_ref":   ("Werk",     "Work"),
    "place_ref":  ("Ort",      "Place"),
    "person_ref": ("Person",   "Person"),
    "character":  ("Figur",    "Character"),
}

# -----------------------------------------------------------------------
# Hilfsfunktionen
# -----------------------------------------------------------------------

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

def _norm_art(s: Optional[str]) -> str:
    return re.sub(r"\s+", " ", (s or "").strip().lower())

def has_art_token(art: str, token: str) -> bool:
    toks = re.split(r"\s+", (art or "").strip().lower())
    return token.lower() in {t for t in toks if t}

def add_bilingual(g: Graph, u: URIRef, label_de: str, label_en: str) -> None:
    """Fügt rdfs:label in beiden Sprachen hinzu."""
    g.add((u, RDFS.label, Literal(label_de, lang="de")))
    g.add((u, RDFS.label, Literal(label_en, lang="en")))

def clean_label(s: str) -> str:
    """Entfernt unerwünschte Präfixe aus RDF-Labels (z. B. 'Expression of ...')."""
    s = re.sub(r"^Expression\s+creation\s+of\s+",   "", s, flags=re.I).strip()
    s = re.sub(r"^Expressionserstellung\s+von\s+",  "", s, flags=re.I).strip()
    s = re.sub(r"^Expression\s+of\s+",              "", s, flags=re.I).strip()
    s = re.sub(r"^Expression\s+von\s+",             "", s, flags=re.I).strip()
    return s

# -----------------------------------------------------------------------
# Quellgraph laden
# -----------------------------------------------------------------------
g_src = Graph()
if WORKS_TTL.exists():
    g_src.parse(WORKS_TTL.as_posix(), format="turtle")
if FRAGMENTS_TTL.exists():
    g_src.parse(FRAGMENTS_TTL.as_posix(), format="turtle")

g_works_only = Graph()
if WORKS_TTL.exists():
    g_works_only.parse(WORKS_TTL.as_posix(), format="turtle")
if FRAGMENTS_TTL.exists():
    g_works_only.parse(FRAGMENTS_TTL.as_posix(), format="turtle")

# -----------------------------------------------------------------------
# Vokabular laden + indexieren
# -----------------------------------------------------------------------
g_vocab = Graph()
if VOCAB_TTL.exists():
    g_vocab.parse(VOCAB_TTL.as_posix(), format="turtle")
elif VOCAB_RDF.exists():
    g_vocab.parse(VOCAB_RDF.as_posix(), format="xml")
    print(f"Info: vocab.ttl nicht gefunden, lade {VOCAB_RDF}")
else:
    print(f"Warn: Taxonomie nicht gefunden (weder {VOCAB_TTL} noch {VOCAB_RDF}) – keine skos:exactMatch-Verlinkungen.")

CAT_TO_VOC_PREFIX = {
    "motiv":  "https://w3id.org/sappho-digital/vocab/motif_",
    "stoff":  "https://w3id.org/sappho-digital/vocab/plot_",
    "thema":  "https://w3id.org/sappho-digital/vocab/topic_",
    "werk":   "https://w3id.org/sappho-digital/vocab/work_",
    "ort":    "https://w3id.org/sappho-digital/vocab/place_",
    "person": "https://w3id.org/sappho-digital/vocab/person_",
    "topos":  "https://w3id.org/sappho-digital/vocab/topos_",
}

CAT_TO_LOCAL_PATH = {
    "motiv":  "feature/motif",
    "stoff":  "feature/plot",
    "thema":  "feature/topic",
    "ort":    "place",
    "person": "person",
    "topos":  "feature/topos",
    "werk":   "feature/work_ref",
}

# Deutsch-Index
vocab_label_index: Dict[str, Dict[str, URIRef]] = {k: {} for k in CAT_TO_VOC_PREFIX.keys()}
vocab_label_global: Dict[str, URIRef] = {}

# Englisch-Index
vocab_label_en: Dict[URIRef, str] = {}

# Zusätzliche Indizes
vocab_plot_focus_index: Dict[str, URIRef] = {}
vocab_werk_bare_index:  Dict[str, URIRef] = {}

_ALL_PARENS    = re.compile(r"\s*\([^)]*\)\s*$")
_FOKUS_PREFIX  = re.compile(r"^sappho-stoff\s+mit\s+fokus\s+auf\s+(die\s+|den\s+|das\s+)?", flags=re.I)
_TYPE_SUFFIXES = re.compile(
    r"\s*\((Motiv|Motif|Thema|Topic|Stoff|Plot|Topos|Ort|Place|Person|Werk|Work|Figur|Character)\)\s*$",
    flags=re.I,
)

def norm_label_key(s: str) -> str:
    if not s:
        return ""
    s = str(s)
    s = _TYPE_SUFFIXES.sub("", s)
    s = re.sub(r"^\s*(Motif|Motiv|Topic|Thema|Plot|Stoff|Textpassage)\s*:\s*", "", s, flags=re.I)
    s = re.sub(r"^\s*Expression\s+of\s+", "", s, flags=re.I)
    s = s.replace("»", "").replace("«", "").replace('"', "").replace("‚", "").replace("'", "").replace("'", "")
    s = re.sub(r"\s+", " ", s)
    return s.strip().lower()

for s in g_vocab.subjects(RDF.type, SKOS.Concept):
    s_str = str(s)
    cat = None
    for k, pref in CAT_TO_VOC_PREFIX.items():
        if s_str.startswith(pref):
            cat = k
            break
    # Deutsch-Index
    for lab_prop in (SKOS.prefLabel, SKOS.altLabel):
        for lab in g_vocab.objects(s, lab_prop):
            if isinstance(lab, Literal) and lab.language == "de":
                key = norm_label_key(str(lab))
                if not key:
                    continue
                if cat:
                    vocab_label_index[cat].setdefault(key, s)
                vocab_label_global.setdefault(key, s)
                if cat == "stoff":
                    focus_key = _FOKUS_PREFIX.sub("", key).strip()
                    if focus_key and focus_key != key:
                        vocab_plot_focus_index.setdefault(focus_key, s)
                if cat == "werk":
                    bare_key = _ALL_PARENS.sub("", key).strip()
                    if bare_key and bare_key != key:
                        vocab_werk_bare_index.setdefault(bare_key, s)
    # Englisch-Index
    for lab in g_vocab.objects(s, SKOS.prefLabel):
        if isinstance(lab, Literal) and lab.language == "en":
            vocab_label_en[URIRef(s)] = str(lab)

def find_vocab(cat: Optional[str], label: str) -> Optional[URIRef]:
    lab_key = norm_label_key(label)
    cand = None
    if cat and vocab_label_index.get(cat):
        cand = vocab_label_index[cat].get(lab_key)
    if cand is None:
        cand = vocab_label_global.get(lab_key)
    if cand is None and cat == "stoff":
        cand = vocab_plot_focus_index.get(lab_key)
        if cand is None:
            focus_key = _FOKUS_PREFIX.sub("", lab_key).strip()
            if focus_key != lab_key:
                cand = vocab_plot_focus_index.get(focus_key)
    if cand is None and cat == "werk":
        bare_key = _ALL_PARENS.sub("", lab_key).strip()
        cand = vocab_werk_bare_index.get(bare_key)
    return URIRef(cand) if cand else None

def local_uri_from_vocab(cat: str, vocab_uri: URIRef) -> Optional[URIRef]:
    local_path = CAT_TO_LOCAL_PATH.get(cat)
    if not local_path:
        return None
    token = last_token(str(vocab_uri))
    return uri(f"{local_path}/{token}")

def link_exact_match(node_uri: URIRef, vocab_uri: URIRef):
    g.add((node_uri, SKOS.exactMatch, vocab_uri))

def get_en_label(voc: Optional[URIRef], fallback: str) -> str:
    """Gibt das englische Vokabular-Label zurück; Fallback: der deutsche Rohwert."""
    if voc is not None:
        en = vocab_label_en.get(voc)
        if en:
            return en
    return fallback

# -----------------------------------------------------------------------
# F2-Expressions-Index aufbauen
# -----------------------------------------------------------------------
text_index = {}
werk_index = {}

def is_f2(typ) -> bool:
    return str(typ).endswith("F2_Expression")

def base_id(tid: str) -> str:
    return re.sub(r"^bibl_(?:sappho_)?", "", tid)

def make_keys_for_bibl_variants(tid: str):
    b = base_id(tid)
    return [f"bibl_{b}", f"bibl_sappho_{b}"]

for s, _, otype in g_src.triples((None, RDF.type, None)):
    if is_f2(otype):
        s_str = str(s)
        tid   = last_token(s_str)
        label = next(g_src.objects(s, RDFS.label), None)
        for key in make_keys_for_bibl_variants(tid):
            text_index[key] = {"uri": s, "type": "F2", "label": label}

for s, _, otype in g_works_only.triples((None, RDF.type, None)):
    if is_f2(otype):
        s_str = str(s)
        tid   = last_token(s_str)
        label = next(g_works_only.objects(s, RDFS.label), None)
        for key in make_keys_for_bibl_variants(tid):
            werk_index[key] = {"uri": s, "type": "F2", "label": label}

# -----------------------------------------------------------------------
# Output-Graph
# -----------------------------------------------------------------------
g = Graph()
g.bind("", BASENS)
g.bind("lrmoo", LRMOO)
g.bind("ecrm",  ECRM)
g.bind("intro", INTRO)
g.bind("rdfs",  RDFS)
g.bind("xsd",   XSD)
g.bind("skos",  SKOS)

IDTYPE_URI = uri("id_type/sappho-digital")
g.add((IDTYPE_URI, RDF.type, ECRM.E55_Type))
add_bilingual(g, IDTYPE_URI, "Sappho-Digital-ID", "Sappho Digital ID")

def add_identifier(g: Graph, id_str: str, thing_uri: URIRef):
    ident_uri = uri(f"identifier/{id_str}")
    g.add((ident_uri, RDF.type, ECRM.E42_Identifier))
    g.add((ident_uri, RDFS.label, Literal(id_str)))
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
    feature_label_de: str,
    text_res_uri: URIRef,
    text_title: str,
    refers_to_uri: Optional[URIRef] = None,
    feature_label_en: Optional[str] = None,
):
    label_de_cat, label_en_cat = CAT_LABELS.get(kind, (kind, kind))
    if feature_label_en is None:
        feature_label_en = feature_label_de

    act_id  = f"{text_id}_{feature_id_suffix}"
    act_uri = uri(f"actualization/{kind}/{act_id}")

    g.add((act_uri, RDF.type, INTRO.INT2_ActualizationOfFeature))
    add_bilingual(
        g, act_uri,
        f"{feature_label_de} ({label_de_cat}) in {text_title}",
        f"{feature_label_en} ({label_en_cat}) in {text_title}",
    )
    g.add((act_uri, INTRO.R17_actualizesFeature, feature_uri))
    g.add((act_uri, INTRO.R18i_actualizationFoundOn, text_res_uri))
    if refers_to_uri is not None:
        g.add((act_uri, ECRM.P67_refers_to, refers_to_uri))

    g.add((feature_uri, INTRO.R17i_featureIsActualizedIn, act_uri))

    interp_feat_uri = uri(f"feature/interpretation/{act_id}")
    g.add((interp_feat_uri, RDF.type, INTRO.INT_Interpretation))
    add_bilingual(
        g, interp_feat_uri,
        f"Interpretation von {feature_label_de} ({label_de_cat}) in {text_title}",
        f"Interpretation of {feature_label_en} ({label_en_cat}) in {text_title}",
    )
    g.add((interp_feat_uri, INTRO.R17i_featureIsActualizedIn, uri(f"actualization/interpretation/{act_id}")))

    interp_act_uri = uri(f"actualization/interpretation/{act_id}")
    g.add((interp_act_uri, RDF.type, INTRO.INT2_ActualizationOfFeature))
    add_bilingual(
        g, interp_act_uri,
        f"Interpretation von {feature_label_de} ({label_de_cat}) in {text_title}",
        f"Interpretation of {feature_label_en} ({label_en_cat}) in {text_title}",
    )
    g.add((interp_act_uri, INTRO.R17_actualizesFeature, interp_feat_uri))
    g.add((interp_act_uri, INTRO.R21_identifies, act_uri))
    g.add((act_uri, INTRO.R21i_isIdentifiedBy, interp_act_uri))

    return act_uri

# -----------------------------------------------------------------------
# XML einlesen & Daten sammeln
# -----------------------------------------------------------------------
elements_per_text = {}
distinct_value_to_id = {k: {} for k in ["motiv","stoff","thema","werk","ort","person"]}

distinct_topos_to_id: Dict[str, str] = {}
topos_to_texts: Dict[str, set] = {}

doc_occurs = {
    "motiv":  defaultdict(set),
    "thema":  defaultdict(set),
    "ort":    defaultdict(set),
    "person": defaultdict(set),
    "topos":  defaultdict(set),
}

def get_or_make_distinct(cat: str, value: str) -> str:
    if value not in distinct_value_to_id[cat]:
        prefix = {
            "motiv":  "motif",
            "stoff":  "plot",
            "thema":  "topic",
            "werk":   "work_ref",
            "ort":    "place",
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

    cats = {k: [] for k in ["motiv","stoff","thema","topos","werk","ort","person"]}

    for k in list(cats.keys()):
        for el in root.findall(f".//{k}"):
            val = text_or_type(el)
            if not val:
                continue
            if k == "person":
                cats[k].append({
                    "label": val,
                    "art":   _norm_art(el.get("art")),
                    "appellation": (el.get("appellation") or "").strip() or None,
                })
            elif k == "werk":
                cats[k].append({"label": val, "art": _norm_art(el.get("art"))})
            elif k == "stoff":
                cats[k].append({"label": val, "modus": (el.get("modus") or "").strip()})
            else:
                cats[k].append(val)

    for k in ["motiv","thema","ort"]:
        for v in set(cats[k]):
            doc_occurs[k][v].add(text_id)

    for v in {p["label"] for p in cats["person"]}:
        doc_occurs["person"][v].add(text_id)

    for phr in set(cats["topos"]):
        topos_to_texts.setdefault(phr, set()).add(text_id)
        doc_occurs["topos"][phr].add(text_id)
        if phr not in distinct_topos_to_id:
            distinct_topos_to_id[phr] = f"topos_{stable_id(phr)}"

    elements_per_text[text_id] = cats

    for k in ["motiv","stoff","thema","ort"]:
        for v in cats[k]:
            _ = get_or_make_distinct(k, v if isinstance(v, str) else v["label"])
    for w in cats["werk"]:
        _ = get_or_make_distinct("werk", w["label"])
    for p in cats["person"]:
        _ = get_or_make_distinct("person", p["label"])

allowed_values = {
    "motiv":  {v for v, s in doc_occurs["motiv"].items()  if len(s) >= 2},
    "thema":  {v for v, s in doc_occurs["thema"].items()  if len(s) >= 2},
    "ort":    {v for v, s in doc_occurs["ort"].items()    if len(s) >= 2},
    "person": {v for v, s in doc_occurs["person"].items() if len(s) >= 2},
    "topos":  {v for v, s in doc_occurs["topos"].items()  if len(s) >= 2},
}

def passes_filter(cat: str, val: str) -> bool:
    if cat in ("stoff", "werk"):
        return True
    return val in allowed_values.get(cat, set())

# -----------------------------------------------------------------------
# URI-Helfer
# -----------------------------------------------------------------------
def get_feature_uri_with_vocab(cat: str, label: str, fallback_id: str) -> Tuple[URIRef, str]:
    voc = find_vocab(cat, label)
    if voc:
        local = local_uri_from_vocab(cat, voc)
        if local is not None:
            return local, last_token(str(voc))
    return uri(f"{CAT_TO_LOCAL_PATH[cat]}/{fallback_id}"), fallback_id

def get_entity_uri_with_vocab(cat: str, label: str, fallback_id: str) -> Tuple[URIRef, str]:
    voc = find_vocab(cat, label)
    if voc:
        local = local_uri_from_vocab(cat, voc)
        if local is not None:
            return local, last_token(str(voc))
    return uri(f"{CAT_TO_LOCAL_PATH[cat]}/{fallback_id}"), fallback_id

# -----------------------------------------------------------------------
# Instanzen erzeugen
# -----------------------------------------------------------------------
for text_id, cats in elements_per_text.items():
    txt = text_index.get(text_id)
    if not txt:
        print(f"Warn: Keine F2-Instanz für {text_id} gefunden.")
        continue

    text_uri   = txt["uri"]
    text_title = clean_label(literal_text(txt["label"]) or text_id)

    for p, o in g_src.predicate_objects(text_uri):
        g.add((text_uri, p, o))

    # INT_Motif
    for v in cats["motiv"]:
        if not passes_filter("motiv", v):
            continue
        fid_fallback = get_or_make_distinct("motiv", v)
        feat_uri, used_id = get_feature_uri_with_vocab("motiv", v, fid_fallback)
        voc = find_vocab("motiv", v)
        label_en = get_en_label(voc, v)

        g.add((feat_uri, RDF.type, INTRO.INT_Motif))
        add_bilingual(g, feat_uri, f"{v} (Motiv)", f"{label_en} (Motif)")
        add_identifier(g, used_id, feat_uri)
        if voc:
            link_exact_match(feat_uri, voc)
        act_uri = add_actualization_common(
            g, "motif", text_id, used_id, feat_uri, v, text_uri, text_title,
            feature_label_en=label_en,
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT_Plot
    for sinfo in cats["stoff"]:
        v          = sinfo["label"]
        modus      = sinfo.get("modus", "")
        v_with_modus = f"{v} ({modus})" if modus else v
        voc = find_vocab("stoff", v_with_modus) if modus else find_vocab("stoff", v)
        label_en = get_en_label(voc, v_with_modus)

        fid_fallback = get_or_make_distinct("stoff", v_with_modus)
        if voc:
            feat_uri = local_uri_from_vocab("stoff", voc) or uri(f"feature/plot/{fid_fallback}")
            used_id  = last_token(str(voc))
        else:
            feat_uri, used_id = uri(f"feature/plot/{fid_fallback}"), fid_fallback

        g.add((feat_uri, RDF.type, INTRO.INT_Plot))
        add_bilingual(g, feat_uri, f"{v_with_modus} (Stoff)", f"{label_en} (Plot)")
        add_identifier(g, used_id, feat_uri)
        if voc:
            link_exact_match(feat_uri, voc)
        act_uri = add_actualization_common(
            g, "plot", text_id, used_id, feat_uri, v_with_modus, text_uri, text_title,
            feature_label_en=label_en,
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT_Topic
    for v in cats["thema"]:
        if not passes_filter("thema", v):
            continue
        fid_fallback = get_or_make_distinct("thema", v)
        feat_uri, used_id = get_feature_uri_with_vocab("thema", v, fid_fallback)
        voc = find_vocab("thema", v)
        label_en = get_en_label(voc, v)

        g.add((feat_uri, RDF.type, INTRO.INT_Topic))
        add_bilingual(g, feat_uri, f"{v} (Thema)", f"{label_en} (Topic)")
        add_identifier(g, used_id, feat_uri)
        if voc:
            link_exact_match(feat_uri, voc)
        act_uri = add_actualization_common(
            g, "topic", text_id, used_id, feat_uri, v, text_uri, text_title,
            feature_label_en=label_en,
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT18_Reference: WORK
    for w in cats["werk"]:
        v   = w["label"]
        art = w.get("art") or ""

        target         = (werk_index.get(v)
                          or werk_index.get(v.replace("bibl_", ""))
                          or werk_index.get(f"bibl_{v}"))
        ref_target_uri = target["uri"] if target else None
        ref_label      = literal_text(target["label"]) if (target and target.get("label")) else v

        if ref_label.strip().lower() == "sappho-work":
            ref_label = "Sapphos Werk"
        ref_label = clean_label(ref_label)

        voc      = find_vocab("werk", ref_label)
        label_en = get_en_label(voc, ref_label)

        if voc:
            feat_id = last_token(str(voc))
        else:
            feat_id = with_prefix("work_ref", ref_label)

        feat_uri = uri(f"feature/work_ref/{feat_id}")
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))
        add_bilingual(g, feat_uri,
                      f"Referenz auf {ref_label} (Werk)",
                      f"Reference to {label_en} (Work)")
        add_identifier(g, feat_id, feat_uri)

        if voc:
            link_exact_match(feat_uri, voc)
        if ref_target_uri is not None:
            voc_target = voc or find_vocab("werk", ref_label)
            if voc_target:
                link_exact_match(ref_target_uri, voc_target)

        if has_art_token(art, "passage"):
            tp_id  = f"textpassage_{stable_id(f'{text_id}|{ref_label}|{v}')}"
            tp_uri = uri(f"textpassage/{tp_id}")
            g.add((tp_uri, RDF.type, INTRO.INT21_TextPassage))
            add_bilingual(g, tp_uri,
                          f"Passage aus {ref_label}",
                          f"Passage from {label_en}")
            g.add((tp_uri, INTRO.R30i_isTextPassageOf, text_uri))
            g.add((text_uri, INTRO.R30_hasTextPassage, tp_uri))
            if ref_target_uri is not None:
                g.add((tp_uri, INTRO.R30i_isTextPassageOf, ref_target_uri))
                g.add((ref_target_uri, INTRO.R30_hasTextPassage, tp_uri))
        else:
            tp_uri = None

        act_uri = add_actualization_common(
            g, "work_ref", text_id, feat_id, feat_uri, ref_label, text_uri, text_title,
            refers_to_uri=ref_target_uri,
            feature_label_en=label_en,
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

        if ref_target_uri is not None:
            g.add((ref_target_uri, ECRM.P67i_is_referred_to_by, act_uri))
            for p, o in g_src.predicate_objects(ref_target_uri):
                g.add((ref_target_uri, p, o))

        if tp_uri is not None:
            g.add((tp_uri, INTRO.R18_showsActualization, act_uri))
            g.add((act_uri, INTRO.R18i_actualizationFoundOn, tp_uri))

    # INT18_Reference: PLACE
    for v in cats["ort"]:
        if not passes_filter("ort", v):
            continue
        pid_fallback = get_or_make_distinct("ort", v)
        place_uri_local, used_id = get_entity_uri_with_vocab("ort", v, pid_fallback)
        voc      = find_vocab("ort", v)
        label_en = get_en_label(voc, v)

        feat_uri = uri(f"feature/place_ref/{used_id}")
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))
        add_bilingual(g, feat_uri,
                      f"Referenz auf {v} (Ort)",
                      f"Reference to {label_en} (Place)")

        g.add((place_uri_local, RDF.type, ECRM.E53_Place))
        g.add((place_uri_local, RDFS.label, Literal(v, lang="de")))
        if label_en != v:
            g.add((place_uri_local, RDFS.label, Literal(label_en, lang="en")))
        add_identifier(g, used_id, place_uri_local)

        if voc:
            link_exact_match(place_uri_local, voc)

        act_uri = add_actualization_common(
            g, "place_ref", text_id, used_id, feat_uri, v, text_uri, text_title,
            refers_to_uri=place_uri_local,
            feature_label_en=label_en,
        )
        g.add((place_uri_local, ECRM.P67i_is_referred_to_by, act_uri))
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

    # INT18_Reference: PERSON
    for pinfo in cats["person"]:
        v          = pinfo["label"]
        art        = pinfo.get("art") or ""
        appellation = pinfo.get("appellation")

        if not passes_filter("person", v):
            continue

        label      = appellation if appellation else v
        per_fallback = get_or_make_distinct("person", v)
        person_uri_local, used_id = get_entity_uri_with_vocab("person", v, per_fallback)
        voc      = find_vocab("person", v)
        label_en = get_en_label(voc, v)

        feat_uri = uri(f"feature/person_ref/{used_id}")
        g.add((feat_uri, RDF.type, INTRO.INT18_Reference))
        add_bilingual(g, feat_uri,
                      f"Referenz auf {v} (Person)",
                      f"Reference to {label_en} (Person)")

        g.add((person_uri_local, RDF.type, ECRM.E21_Person))
        g.add((person_uri_local, RDFS.label, Literal(v, lang="de")))
        if label_en != v:
            g.add((person_uri_local, RDFS.label, Literal(label_en, lang="en")))
        add_identifier(g, used_id, person_uri_local)

        if voc:
            link_exact_match(person_uri_local, voc)

        act_uri = add_actualization_common(
            g, "person_ref", text_id, used_id, feat_uri, label, text_uri, text_title,
            refers_to_uri=person_uri_local,
            feature_label_en=get_en_label(voc, label),
        )
        g.add((person_uri_local, ECRM.P67i_is_referred_to_by, act_uri))
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

        if has_art_token(art, "character"):
            char_feat_uri = uri(f"feature/character/{used_id}")
            g.add((char_feat_uri, RDF.type, INTRO.INT_Character))
            add_bilingual(g, char_feat_uri,
                          f"{v} (Figur)",
                          f"{label_en} (Character)")

            char_act_uri = add_actualization_common(
                g, "character", text_id, f"character_{used_id}", char_feat_uri,
                label, text_uri, text_title,
                refers_to_uri=person_uri_local,
                feature_label_en=get_en_label(voc, label),
            )
            g.add((text_uri, INTRO.R18_showsActualization, char_act_uri))

    # INT_Topos
    for phr in cats["topos"]:
        if not passes_filter("topos", phr):
            continue

        topos_id = distinct_topos_to_id.get(phr) or f"topos_{stable_id(phr)}"
        feat_uri = uri(f"feature/topos/{topos_id}")
        voc      = find_vocab("topos", phr)
        label_en = get_en_label(voc, phr)

        g.add((feat_uri, RDF.type, INTRO.INT_Topos))
        add_bilingual(g, feat_uri,
                      f"{phr} (Topos)",
                      f"{label_en} (Topos)")
        add_identifier(g, topos_id, feat_uri)

        if voc:
            link_exact_match(feat_uri, voc)

        act_uri = add_actualization_common(
            g, "topos", text_id, topos_id, feat_uri, phr, text_uri, text_title,
            feature_label_en=label_en,
        )
        g.add((text_uri, INTRO.R18_showsActualization, act_uri))

# -----------------------------------------------------------------------
# Schreiben
# -----------------------------------------------------------------------
OUT_TTL.parent.mkdir(parents=True, exist_ok=True)
g.serialize(destination=OUT_TTL.as_posix(), format="turtle")

OUT_RDF = OUT_TTL.with_suffix(".rdf")
g.serialize(destination=OUT_RDF.as_posix(), format="pretty-xml", encoding="utf-8")

OUT_JSONLD = OUT_TTL.with_suffix(".jsonld")
g.serialize(destination=OUT_JSONLD.as_posix(), format="json-ld", encoding="utf-8")