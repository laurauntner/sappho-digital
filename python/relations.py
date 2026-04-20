from rdflib import Graph, Namespace, URIRef, RDF, RDFS, Literal
from rdflib.namespace import XSD
from pathlib import Path
import re
from typing import Optional, List, Dict, Tuple
import xml.etree.ElementTree as ET

# -----------------------------------------------------------------------
# Pfade
# -----------------------------------------------------------------------
BASE_DIR  = Path(__file__).resolve().parent
DATA_DIR  = (BASE_DIR / "../data/rdf").resolve()
XML_DIR   = (BASE_DIR / "../../doktorat/Diss/Sappho-Rezeption/XML").resolve()

WORKS    = DATA_DIR / "works.ttl"
ANALYSIS = DATA_DIR / "analysis.ttl"
FRAGMENTS = DATA_DIR / "fragments.ttl"
OUTFILE  = DATA_DIR / "relations.ttl"

# -----------------------------------------------------------------------
# Namespaces
# -----------------------------------------------------------------------
NS    = Namespace("https://sappho-digital.com/")
BASE  = "https://sappho-digital.com/"
LRMOO = Namespace("http://iflastandards.info/ns/lrm/lrmoo/")
ECRM  = Namespace("http://erlangen-crm.org/current/")
INTRO = Namespace("https://w3id.org/lso/intro/currentbeta#")

# -----------------------------------------------------------------------
# Hilfsfunktionen
# -----------------------------------------------------------------------

def add_bilingual(g: Graph, u: URIRef, label_de: str, label_en: str) -> None:
    """Fügt rdfs:label in beiden Sprachen hinzu."""
    g.add((u, RDFS.label, Literal(label_de, lang="de")))
    g.add((u, RDFS.label, Literal(label_en, lang="en")))

def local_id(uri: URIRef) -> str:
    return str(uri).rsplit("/", 1)[-1]

def make_uri(*parts: str) -> URIRef:
    return URIRef(BASE + "/".join(p.strip("/") for p in parts))

def ensure_copied(src_graph: Graph, dst_graph: Graph, subj: URIRef):
    for p, o in src_graph.predicate_objects(subj):
        dst_graph.add((subj, p, o))
    for o in src_graph.objects(subj, RDF.type):
        dst_graph.add((subj, RDF.type, o))

def get_label(g: Graph, u: URIRef, fallback: Optional[str] = None) -> str:
    de = en = any_lbl = None
    for lbl in g.objects(u, RDFS.label):
        lang = getattr(lbl, "language", None)
        if lang == "de":
            de = str(lbl)
        elif lang == "en" and en is None:
            en = str(lbl)
        elif any_lbl is None:
            any_lbl = str(lbl)
    raw = de or en or any_lbl
    if raw:
        return clean_label(raw)
    return fallback if fallback is not None else "[??]"

def clean_label(s: str) -> str:
    """Entfernt unerwünschte Präfixe aus RDF-Labels (z. B. 'Expression of ...')."""
    s = re.sub(r"^Expression\s+creation\s+of\s+",   "", s, flags=re.I).strip()
    s = re.sub(r"^Expressionserstellung\s+von\s+",  "", s, flags=re.I).strip()
    s = re.sub(r"^Expression\s+of\s+",              "", s, flags=re.I).strip()
    s = re.sub(r"^Expression\s+von\s+",             "", s, flags=re.I).strip()
    return s

def shorten_r18_key(f2_uri: URIRef, actual_uri: URIRef) -> str:
    f2loc  = local_id(f2_uri)
    actloc = local_id(actual_uri)
    prefix = f2loc + "_"
    if actloc.startswith(prefix):
        return actloc[len(prefix):]
    return actloc

def parse_year_from_timespan_uri(ts_uri: URIRef) -> Optional[int]:
    last = local_id(ts_uri)
    m = re.match(r"^-?\d{1,4}$", last)
    if m:
        return int(last)
    return None

def years_for_f2(f2: URIRef, g_all: Graph) -> List[int]:
    years   = set()
    manifes = set(g_all.objects(f2, LRMOO["R4i_is_embodied_in"]))
    for f30 in g_all.subjects(LRMOO["R24_created"], None):
        if (f30, RDF.type, LRMOO["F30_Manifestation_Creation"]) not in g_all:
            continue
        created = set(g_all.objects(f30, LRMOO["R24_created"]))
        if manifes & created:
            for ts in g_all.objects(f30, ECRM["P4_has_time-span"]):
                yr = parse_year_from_timespan_uri(ts)
                if yr is not None:
                    years.add(yr)
    return sorted(years)

def expr_creation_year_for_f2(f2: URIRef, g_all: Graph) -> Optional[int]:
    years = set()
    for ec in g_all.objects(f2, LRMOO["R17i_was_created_by"]):
        for ts in g_all.objects(ec, ECRM["P4_has_time-span"]):
            yr = parse_year_from_timespan_uri(ts)
            if yr is not None:
                years.add(yr)
    return min(years) if years else None

def pick_f1(frag_g: Graph) -> URIRef:
    candidates = list(frag_g.subjects(RDF.type, LRMOO["F1_Work"]))
    if not candidates:
        raise RuntimeError("Keine F1_Work-Instanz in fragments.ttl gefunden.")
    for c in candidates:
        if "sappho-work" in str(c):
            return c
    return candidates[0]

def build_relation_uris(ref_local: str, referred_local: str):
    rel_id       = f"{ref_local}_{referred_local}"
    relation_uri = make_uri("relation", rel_id)
    feature_uri  = make_uri("feature/interpretation", rel_id)
    actual_uri   = make_uri("actualization/interpretation", rel_id)
    return relation_uri, feature_uri, actual_uri

# -----------------------------------------------------------------------
# XML-Seitenindex laden
# -----------------------------------------------------------------------
def _text(el: Optional[ET.Element]) -> str:
    if el is None:
        return ""
    return (el.text or "").strip()

def load_pages_index(xml_dir: Path) -> Dict[str, Dict[str, str]]:
    idx: Dict[str, Dict[str, str]] = {}
    if not xml_dir.exists():
        return idx
    for xf in sorted(xml_dir.glob("*.xml")):
        try:
            root = ET.parse(xf).getroot()
        except Exception:
            continue
        id_el = root.find(".//id")
        if id_el is None:
            continue
        tid = (id_el.text or "").strip()
        if not tid:
            continue
        anth  = _text(root.find(".//anthologieSeiten"))
        vorl  = _text(root.find(".//vorlageSeiten"))
        if anth or vorl:
            idx[tid] = {"anth": anth, "vorlage": vorl}
    return idx

PAGES_BY_ID = load_pages_index(XML_DIR)

def pages_phrase_for(tid: str) -> str:
    """Gibt eine deutschsprachige Seitenangabe zurück (für rdfs:comment@de)."""
    d = PAGES_BY_ID.get(tid)
    if not d:
        return ""
    parts = []
    if d.get("anth"):
        parts.append(f"die Seite(n) {d['anth']} aus der Anthologie")
    vorlage_suffix = {
        "bibl_632dac82": "aus der Vorlage von 1793",
        "bibl_4fcb8123": "aus der Vorlage von 2009",
        "bibl_e2598fbd": "aus der Vorlage von 2021",
    }.get(tid, "aus dem Erstdruck")
    if d.get("vorlage"):
        parts.append(f"S. {d['vorlage']} {vorlage_suffix}")
    if not parts:
        return ""
    if len(parts) == 2:
        return f"{parts[0]} bzw. {parts[1]}"
    return parts[0]

def pages_phrase_en_for(tid: str) -> str:
    """Gibt eine englischsprachige Seitenangabe zurück (für rdfs:comment@en)."""
    d = PAGES_BY_ID.get(tid)
    if not d:
        return ""
    parts = []
    if d.get("anth"):
        parts.append(f"page(s) {d['anth']} from the anthology")
    vorlage_suffix_en = {
        "bibl_632dac82": "from the 1793 source edition",
        "bibl_4fcb8123": "from the 2009 source edition",
        "bibl_e2598fbd": "from the 2021 source edition",
    }.get(tid, "from the first print edition")
    if d.get("vorlage"):
        parts.append(f"p. {d['vorlage']} {vorlage_suffix_en}")
    if not parts:
        return ""
    if len(parts) == 2:
        return f"{parts[0]} and {parts[1]}"
    return parts[0]

# -----------------------------------------------------------------------
# Graphs laden
# -----------------------------------------------------------------------
g_works    = Graph().parse(WORKS,    format="turtle")
g_analysis = Graph().parse(ANALYSIS, format="turtle")
g_frag     = Graph().parse(FRAGMENTS, format="turtle")

FRAG_F2 = set(g_frag.subjects(RDF.type, LRMOO["F2_Expression"]))

g_all = Graph()
for t in g_works:    g_all.add(t)
for t in g_analysis: g_all.add(t)
for t in g_frag:     g_all.add(t)

# Ausgabegraph
out = Graph()
out.bind("",      NS)
out.bind("lrmoo", LRMOO)
out.bind("ecrm",  ECRM)
out.bind("rdfs",  RDFS)
out.bind("xsd",   XSD)
out.bind("intro", INTRO)

# -----------------------------------------------------------------------
# F1 holen
# -----------------------------------------------------------------------
f1       = pick_f1(g_frag)
f1_label = get_label(g_frag, f1, "Work")
f1_local = local_id(f1)

# -----------------------------------------------------------------------
# F2–F1-Relationen 
# -----------------------------------------------------------------------
f2_works = set(g_works.subjects(RDF.type, LRMOO["F2_Expression"]))
relations_to_create: List[Dict] = []

for f2 in sorted(f2_works, key=lambda u: str(u)):
    relations_to_create.append({
        "ref_uri":        f2,
        "referred_uri":   f1,
        "ref_label":      get_label(g_works, f2, local_id(f2)),
        "referred_label": f1_label,
        "ref_graph":      g_works,
        "referred_graph": g_frag,
        "mode":           "F2_to_F1"
    })

# -----------------------------------------------------------------------
# F2-Relationen 
# -----------------------------------------------------------------------
info: Dict[URIRef, Dict] = {}
for f2 in set(g_analysis.subjects(RDF.type, LRMOO["F2_Expression"])):
    r18_keys   = set(shorten_r18_key(f2, a) for a in g_analysis.objects(f2, INTRO["R18_showsActualization"]))
    r30_uris   = set()
    work_keys  = set()
    f2_targets = set()

    for a in g_analysis.objects(f2, INTRO["R18_showsActualization"]):
        for tp in g_analysis.objects(a, INTRO["R18i_actualizationFoundOn"]):
            if "/textpassage/" in str(tp):
                r30_uris.add(str(tp))
        for feat in g_analysis.objects(a, INTRO["R17_actualizesFeature"]):
            if (feat, RDF.type, INTRO["INT18_Reference"]) in g_analysis:
                if str(feat).startswith(BASE + "feature/work_ref/"):
                    work_keys.add(local_id(feat))
                for tgt in g_analysis.objects(a, ECRM["P67_refers_to"]):
                    if (tgt, RDF.type, LRMOO["F2_Expression"]) in g_all:
                        f2_targets.add(tgt)

    r18_keys |= work_keys

    f2_loc = local_id(f2)
    yrs    = years_for_f2(f2, g_all)
    info[f2] = {
        "r18":       r18_keys,
        "r30":       r30_uris,
        "work_keys": work_keys,
        "f2_targets": f2_targets,
        "label":     get_label(g_analysis, f2, f2_loc),
        "local":     f2_loc,
        "is_sappho": ("sappho" in f2_loc.lower()) or (f2 in FRAG_F2),
        "years":     yrs,
        "year_min":  yrs[0] if yrs else None,
    }

def pick_older_younger(a: URIRef, b: URIRef):
    ia, ib = info[a], info[b]
    if ia["is_sappho"] and not ib["is_sappho"]: return a, b
    if ib["is_sappho"] and not ia["is_sappho"]: return b, a
    ya, yb = ia["year_min"], ib["year_min"]
    if ya is not None and yb is not None:
        if ya < yb: return a, b
        if yb < ya: return b, a
    elif ya is not None and yb is None: return a, b
    elif yb is not None and ya is None: return b, a
    return (a, b) if str(a) < str(b) else (b, a)

f2_list    = sorted(info.keys(), key=lambda u: str(u))
seen_pairs = set()

for i in range(len(f2_list)):
    for j in range(i + 1, len(f2_list)):
        a, b = f2_list[i], f2_list[j]
        overlap_r18  = info[a]["r18"]       & info[b]["r18"]
        overlap_r30  = info[a]["r30"]       & info[b]["r30"]
        overlap_work = info[a]["work_keys"] & info[b]["work_keys"]

        if not overlap_r18 and not overlap_r30 and not overlap_work:
            continue

        older, younger = pick_older_younger(a, b)
        key = (str(older), str(younger))
        if key in seen_pairs:
            continue
        seen_pairs.add(key)

        relations_to_create.append({
            "ref_uri":             younger,
            "referred_uri":        older,
            "ref_label":           info[younger]["label"],
            "referred_label":      info[older]["label"],
            "ref_graph":           g_analysis,
            "referred_graph":      g_analysis,
            "mode":                "F2_to_F2_overlap",
            "trigger_feature_ids": overlap_r18,
            "trigger_textpassages": overlap_r30,
        })

# gerichtete INT31 für direkte F2→F2-Referenzen
seen_direct = set()
for src, meta in info.items():
    for tgt in meta["f2_targets"]:
        pair = (str(src), str(tgt))
        if pair in seen_direct:
            continue
        seen_direct.add(pair)
        relations_to_create.append({
            "ref_uri":        src,
            "referred_uri":   tgt,
            "ref_label":      info[src]["label"],
            "referred_label": get_label(g_analysis if tgt in info else g_all, tgt, local_id(tgt)),
            "ref_graph":      g_analysis,
            "referred_graph": g_analysis if (tgt, None, None) in g_analysis else g_all,
            "mode":           "F2_direct_reference",
        })

# -----------------------------------------------------------------------
# Evidenz-Helfer
# -----------------------------------------------------------------------
FID_PREFIX_MAP: List[Tuple[str, Tuple[str, str]]] = [
    ("motif_",     ("feature/motif",      "motif")),
    ("plot_",      ("feature/plot",       "plot")),
    ("topic_",     ("feature/topic",      "topic")),
    ("topos_",     ("feature/topos",      "topos")),
    ("person_",    ("feature/person_ref", "person_ref")),
    ("character_", ("feature/character",  "character")),
    ("place_",     ("feature/place_ref",  "place_ref")),
    ("work_",      ("feature/work_ref",   "work_ref")),
]

def infer_feature_uri_from_id(fid: str) -> Optional[URIRef]:
    for pref, (path, _) in FID_PREFIX_MAP:
        if fid.startswith(pref):
            if pref == "character_":
                used_id = fid[len("character_"):]
                return make_uri("feature/character", used_id)
            return make_uri(path, fid)
    return None

def infer_kind_from_id(fid: str) -> Optional[str]:
    for pref, (_, kind) in FID_PREFIX_MAP:
        if fid.startswith(pref):
            return kind
    return None

def infer_kind_from_feature_uri(feat: URIRef) -> Optional[str]:
    s = str(feat)
    if "/feature/motif/"      in s: return "motif"
    if "/feature/plot/"       in s: return "plot"
    if "/feature/topic/"      in s: return "topic"
    if "/feature/topos/"      in s: return "topos"
    if "/feature/person_ref/" in s: return "person_ref"
    if "/feature/place_ref/"  in s: return "place_ref"
    if "/feature/work_ref/"   in s: return "work_ref"
    if "/feature/character/"  in s: return "character"
    return None

def collect_f2_evidence(f2: URIRef) -> Tuple[Dict[str, Dict], set]:
    features_map: Dict[str, Dict] = {}
    passages = set()
    for a in g_analysis.objects(f2, INTRO["R18_showsActualization"]):
        for feat in g_analysis.objects(a, INTRO["R17_actualizesFeature"]):
            if isinstance(feat, URIRef):
                kind = infer_kind_from_feature_uri(feat) or infer_kind_from_id(local_id(feat))
                if kind:
                    entry = features_map.setdefault(
                        str(feat),
                        {"kind": kind, "feature_uri": feat, "actualizations": set()}
                    )
                    entry["actualizations"].add(a)
        for tp in g_analysis.objects(a, INTRO["R18i_actualizationFoundOn"]):
            if "/textpassage/" in str(tp):
                passages.add(str(tp))
    return features_map, passages

# -----------------------------------------------------------------------
# Materialisierung
# -----------------------------------------------------------------------
if relations_to_create:
    ensure_copied(g_frag, out, f1)

relevant_f2 = set()

for rel in relations_to_create:
    ref_uri        = rel["ref_uri"]
    referred_uri   = rel["referred_uri"]
    ref_label      = rel["ref_label"]
    referred_label = rel["referred_label"]
    ref_graph      = rel["ref_graph"]
    referred_graph = rel["referred_graph"]
    mode           = rel["mode"]

    ensure_copied(ref_graph, out, ref_uri)
    ensure_copied(referred_graph, out, referred_uri)

    if (ref_uri,      RDF.type, LRMOO["F2_Expression"]) in g_all: relevant_f2.add(ref_uri)
    if (referred_uri, RDF.type, LRMOO["F2_Expression"]) in g_all: relevant_f2.add(referred_uri)

    ref_loc      = local_id(ref_uri)
    referred_loc = local_id(referred_uri)
    relation_uri, feature_uri, actual_uri = build_relation_uris(ref_loc, referred_loc)

    # Gerichtetheit
    directional = True
    if mode in ("F2_to_F2_overlap", "F2_direct_reference"):
        older_expr  = referred_uri
        younger_expr = ref_uri
        if older_expr in FRAG_F2:
            directional = True
        else:
            older_f3_year   = info.get(older_expr,  {}).get("year_min")
            younger_ec_year = expr_creation_year_for_f2(younger_expr, g_all)
            younger_mc_year = info.get(younger_expr, {}).get("year_min")
            younger_year    = younger_ec_year if younger_ec_year is not None else younger_mc_year
            if older_f3_year is None or younger_year is None or older_f3_year > younger_year:
                directional = False

    # Basis-Kanten
    if directional:
        out.add((ref_uri,      INTRO["R13i_isReferringEntity"],  relation_uri))
        out.add((referred_uri, INTRO["R12i_isReferredToEntity"], relation_uri))
        out.add((relation_uri, INTRO["R13_hasReferringEntity"],  ref_uri))
        out.add((relation_uri, INTRO["R12_hasReferredToEntity"], referred_uri))

    # INT31 & Interpretation
    rel_label_de = f"Intertextuelle Relation zwischen {ref_label} und {referred_label}"
    rel_label_en = f"Intertextual Relation between {ref_label} and {referred_label}"
    out.add((relation_uri, RDF.type, INTRO["INT31_IntertextualRelation"]))
    add_bilingual(out, relation_uri, rel_label_de, rel_label_en)
    out.add((relation_uri, INTRO["R21i_isIdentifiedBy"], actual_uri))

    feat_label_de = f"Interpretation der intertextuellen Relation zwischen {ref_label} und {referred_label}"
    feat_label_en = f"Interpretation of Intertextual Relation between {ref_label} and {referred_label}"
    out.add((feature_uri, RDF.type, INTRO["INT_Interpretation"]))
    add_bilingual(out, feature_uri, feat_label_de, feat_label_en)
    out.add((feature_uri, INTRO["R17i_featureIsActualizedIn"], actual_uri))

    out.add((actual_uri, RDF.type, INTRO["INT2_ActualizationOfFeature"]))
    add_bilingual(out, actual_uri, feat_label_de, feat_label_en)
    out.add((actual_uri, INTRO["R17_actualizesFeature"], feature_uri))
    out.add((actual_uri, INTRO["R21_identifies"], relation_uri))

    # Evidenz
    features_a, passages_a = collect_f2_evidence(ref_uri)
    features_b, passages_b = collect_f2_evidence(referred_uri)

    trigger_fids     = set()
    trigger_passages = set()

    if mode == "F2_to_F2_overlap":
        trigger_fids     = set(rel.get("trigger_feature_ids",   set()))
        trigger_passages = set(rel.get("trigger_textpassages",  set()))
    elif mode == "F2_direct_reference":
        for fid, data in features_a.items():
            if data["kind"] != "work_ref":
                continue
            for act in data["actualizations"]:
                if (act, ECRM["P67_refers_to"], referred_uri) in g_analysis:
                    trigger_fids.add(fid)

    for fid in sorted(trigger_fids):
        feat_uri_ev = (infer_feature_uri_from_id(fid)
                       or features_a.get(fid, {}).get("feature_uri")
                       or features_b.get(fid, {}).get("feature_uri"))
        if feat_uri_ev is None:
            continue
        out.add((relation_uri, INTRO["R22i_relationIsBasedOnSimilarity"], feat_uri_ev))
        out.add((feat_uri_ev,  INTRO["R22_providesSimilarityForRelation"], relation_uri))

    for fid in sorted(trigger_fids):
        for act in features_a.get(fid, {}).get("actualizations", set()):
            out.add((relation_uri, INTRO["R24_hasRelatedEntity"],  act))
            out.add((act,          INTRO["R24i_isRelatedEntity"],  relation_uri))
        for act in features_b.get(fid, {}).get("actualizations", set()):
            out.add((relation_uri, INTRO["R24_hasRelatedEntity"],  act))
            out.add((act,          INTRO["R24i_isRelatedEntity"],  relation_uri))

    for tp in sorted(trigger_passages):
        tp_uri = URIRef(tp)
        out.add((relation_uri, INTRO["R24_hasRelatedEntity"], tp_uri))
        out.add((tp_uri,       INTRO["R24i_isRelatedEntity"], relation_uri))

    out.add((relation_uri, INTRO["R24_hasRelatedEntity"], ref_uri))
    out.add((relation_uri, INTRO["R24_hasRelatedEntity"], referred_uri))
    out.add((ref_uri,      INTRO["R24i_isRelatedEntity"], relation_uri))
    out.add((referred_uri, INTRO["R24i_isRelatedEntity"], relation_uri))

    # rdfs:comment (Seitenangaben)
    ref_pages_de      = pages_phrase_for(ref_loc)
    referred_pages_de = pages_phrase_for(referred_loc)
    ref_pages_en      = pages_phrase_en_for(ref_loc)
    referred_pages_en = pages_phrase_en_for(referred_loc)

    parts_de, parts_en = [], []
    if (ref_uri, RDF.type, LRMOO["F2_Expression"]) in g_all:
        if ref_pages_de: parts_de.append(f"für {ref_label} {ref_pages_de}")
        if ref_pages_en: parts_en.append(f"for {ref_label} {ref_pages_en}")
    if (referred_uri, RDF.type, LRMOO["F2_Expression"]) in g_all:
        if referred_pages_de: parts_de.append(f"für {referred_label} {referred_pages_de}")
        if referred_pages_en: parts_en.append(f"for {referred_label} {referred_pages_en}")

    if parts_de:
        out.add((relation_uri, RDFS.comment,
                 Literal("Für die Analyse wurden " + " sowie ".join(parts_de) + " herangezogen.", lang="de")))
    if parts_en:
        out.add((relation_uri, RDFS.comment,
                 Literal("The analysis is based on " + " and ".join(parts_en) + ".", lang="en")))

# -----------------------------------------------------------------------
# Aufräumen
# -----------------------------------------------------------------------
if relations_to_create:
    all_f2_in_out = set(out.subjects(RDF.type, LRMOO["F2_Expression"]))
    for f2 in all_f2_in_out:
        if f2 not in relevant_f2:
            for p, o in list(out.predicate_objects(f2)):
                out.remove((f2, p, o))
            for o in list(out.objects(f2, RDF.type)):
                out.remove((f2, RDF.type, o))

# -----------------------------------------------------------------------
# Serialisieren
# -----------------------------------------------------------------------
OUTFILE.parent.mkdir(parents=True, exist_ok=True)
out.serialize(destination=OUTFILE.as_posix(), format="turtle")

OUT_RDF = OUTFILE.with_suffix(".rdf")
out.serialize(destination=OUT_RDF.as_posix(), format="pretty-xml", encoding="utf-8")

OUT_JSONLD = OUTFILE.with_suffix(".jsonld")
out.serialize(destination=OUT_JSONLD.as_posix(), format="json-ld", encoding="utf-8")