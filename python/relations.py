from rdflib import Graph, Namespace, URIRef, RDF, RDFS, Literal
from rdflib.namespace import XSD
from pathlib import Path
import re
from typing import Optional, List

# Pfade
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = (BASE_DIR / "../data/rdf").resolve()

WORKS = DATA_DIR / "works.ttl"
ANALYSIS = DATA_DIR / "analysis.ttl"
FRAGMENTS = DATA_DIR / "fragments.ttl"
OUTFILE = DATA_DIR / "relations.ttl"

# Namespaces
NS = Namespace("https://sappho-digital.com/")
BASE = "https://sappho-digital.com/"

LRMOO = Namespace("http://www.cidoc-crm.org/lrmoo/")
ECRM = Namespace("http://erlangen-crm.org/current/")
INTRO = Namespace("https://w3id.org/lso/intro/currentbeta#")

# Hilfsfunktionen
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
    lbls = list(g.objects(u, RDFS.label))
    if lbls:
        return str(lbls[0])
    return "[??]"

def shorten_r18_key(f2_uri: URIRef, actual_uri: URIRef) -> str:
    f2loc = local_id(f2_uri)
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
    years = set()
    manifes = set(g_all.objects(f2, LRMOO["R4i_is_embodied_in"]))
    for f30 in g_all.subjects(LRMOO["R24_created"], None):
        if (f30, RDF.type, LRMOO["F30_Manifestation_Creation"]) not in g_all:
            continue
        created = set(g_all.objects(f30, LRMOO["R24_created"]))
        if manifes & created:
            for ts in g_all.objects(f30, ECRM["P4_has_time_span"]):
                yr = parse_year_from_timespan_uri(ts)
                if yr is not None:
                    years.add(yr)
    return sorted(years)

def pick_f1(frag_g: Graph) -> URIRef:
    candidates = list(frag_g.subjects(RDF.type, LRMOO["F1_Work"]))
    if not candidates:
        raise RuntimeError("Keine F1_Work-Instanz in fragments.ttl gefunden.")
    for c in candidates:
        if "sappho-work" in str(c):
            return c
    return candidates[0]

def build_relation_uris(ref_local: str, referred_local: str):
    rel_id = f"{ref_local}_{referred_local}"
    relation_uri = make_uri("relation", rel_id)
    feature_uri = make_uri("feature/interpretation", rel_id)
    actual_uri = make_uri("actualization/interpretation", rel_id)
    return relation_uri, feature_uri, actual_uri

# Graphs laden
g_works = Graph().parse(WORKS, format="turtle")
g_analysis = Graph().parse(ANALYSIS, format="turtle")
g_frag = Graph().parse(FRAGMENTS, format="turtle")

# Union für Jahrermittlung
g_all = Graph()
for t in g_works: g_all.add(t)
for t in g_analysis: g_all.add(t)
for t in g_frag: g_all.add(t)

# Ausgabegraf
out = Graph()
out.bind("", NS)
out.bind("lrmoo", LRMOO)
out.bind("ecrm", ECRM)
out.bind("rdfs", RDFS)
out.bind("xsd", XSD)
out.bind("intro", INTRO)

# F1 holen
f1 = pick_f1(g_frag)
f1_label = get_label(g_frag, f1, "Work")
f1_local = local_id(f1)

# F2-F1-Relationen
f2_works = set(g_works.subjects(RDF.type, LRMOO["F2_Expression"]))
f2_analysis = set(g_analysis.subjects(RDF.type, LRMOO["F2_Expression"]))
f2_works_only = sorted(f2_works - f2_analysis, key=lambda u: str(u))

relations_to_create = []  

for f2 in f2_works_only:
    relations_to_create.append({
        "ref_uri": f2,                 
        "referred_uri": f1,            
        "ref_label": get_label(g_works, f2, local_id(f2)),
        "referred_label": f1_label,
        "ref_graph": g_works,
        "referred_graph": g_frag,
        "mode": "F2_to_F1"
    })

# F2-Relationen
info = {}
for f2 in f2_analysis:
    r18_keys = set(shorten_r18_key(f2, a) for a in g_analysis.objects(f2, INTRO["R18_showsActualization"]))
    r30_uris = set(str(u) for u in g_analysis.objects(f2, INTRO["R30_hasTextPassage"]))
    f2_loc = local_id(f2)
    yrs = years_for_f2(f2, g_all)
    info[f2] = {
        "r18": r18_keys,
        "r30": r30_uris,
        "label": get_label(g_analysis, f2, f2_loc),
        "local": f2_loc,
        "is_sappho": ("sappho" in f2_loc.lower()),
        "years": yrs,
        "year_min": yrs[0] if yrs else None
    }

def pick_older_younger(a: URIRef, b: URIRef):
    ia, ib = info[a], info[b]
    # „sappho“ -> älter
    if ia["is_sappho"] and not ib["is_sappho"]:
        return a, b
    if ib["is_sappho"] and not ia["is_sappho"]:
        return b, a
    # Jahrvergleich
    ya, yb = ia["year_min"], ib["year_min"]
    if ya is not None and yb is not None:
        if ya < yb: return a, b
        if yb < ya: return b, a
    elif ya is not None and yb is None:
        return a, b
    elif yb is not None and ya is None:
        return b, a
    return (a, b) if str(a) < str(b) else (b, a)

f2_list = sorted(info.keys(), key=lambda u: str(u))
seen_pairs = set()

for i in range(len(f2_list)):
    for j in range(i + 1, len(f2_list)):
        a, b = f2_list[i], f2_list[j]
        overlap_r18 = info[a]["r18"] & info[b]["r18"]
        overlap_r30 = info[a]["r30"] & info[b]["r30"]
        if not overlap_r18 and not overlap_r30:
            continue 

        older, younger = pick_older_younger(a, b)
        key = (str(older), str(younger))
        if key in seen_pairs:
            continue
        seen_pairs.add(key)

        relations_to_create.append({
            "ref_uri": younger,                 
            "referred_uri": older,              
            "ref_label": info[younger]["label"],
            "referred_label": info[older]["label"],
            "ref_graph": g_analysis,           
            "referred_graph": g_analysis,
            "mode": "F2_to_F2"
        })

if relations_to_create:
    ensure_copied(g_frag, out, f1)

relevant_f2 = set()

for rel in relations_to_create:
    ref_uri = rel["ref_uri"]
    referred_uri = rel["referred_uri"]
    ref_label = rel["ref_label"]
    referred_label = rel["referred_label"]
    ref_graph = rel["ref_graph"]
    referred_graph = rel["referred_graph"]

    ensure_copied(ref_graph, out, ref_uri)
    ensure_copied(referred_graph, out, referred_uri)

    if (ref_uri, RDF.type, LRMOO["F2_Expression"]) in g_all:
        relevant_f2.add(ref_uri)
    if (referred_uri, RDF.type, LRMOO["F2_Expression"]) in g_all:
        relevant_f2.add(referred_uri)

    ref_loc = local_id(ref_uri)
    referred_loc = local_id(referred_uri)
    relation_uri, feature_uri, actual_uri = build_relation_uris(ref_loc, referred_loc)

    out.add((ref_uri, INTRO["R13i_isReferringEntity"], relation_uri))
    out.add((referred_uri, INTRO["R12i_isReferredToEntity"], relation_uri))

    # INT31 anlegen
    rel_label = f"Intertextual relation between {ref_label} and {referred_label}"
    out.add((relation_uri, RDF.type, INTRO["INT31_IntertextualRelation"]))
    out.add((relation_uri, RDFS.label, Literal(rel_label, lang="en")))
    out.add((relation_uri, INTRO["R13_hasReferringEntity"], ref_uri))
    out.add((relation_uri, INTRO["R12_hasReferredToEntity"], referred_uri))
    out.add((relation_uri, INTRO["R21i_isIdentifiedBy"], actual_uri))

    # INT_Interpretation + INT2_ActualizationOfFeature
    feat_label = f"Interpretation of intertextual relation between {ref_label} and {referred_label}"
    out.add((feature_uri, RDF.type, INTRO["INT_Interpretation"]))
    out.add((feature_uri, RDFS.label, Literal(feat_label, lang="en")))
    out.add((feature_uri, INTRO["R17i_featureIsActualizedIn"], actual_uri))

    out.add((actual_uri, RDF.type, INTRO["INT2_ActualizationOfFeature"]))
    out.add((actual_uri, RDFS.label, Literal(feat_label, lang="en")))
    out.add((actual_uri, INTRO["R17_actualizesFeature"], feature_uri))
    out.add((actual_uri, INTRO["R21_identifies"], relation_uri))

# Aufräumen
if relations_to_create:
    all_f2_in_out = set(out.subjects(RDF.type, LRMOO["F2_Expression"]))
    for f2 in all_f2_in_out:
        if f2 not in relevant_f2:
            # Entferne alle Tripel mit diesem Subjekt
            for p, o in list(out.predicate_objects(f2)):
                out.remove((f2, p, o))
            for o in list(out.objects(f2, RDF.type)):
                out.remove((f2, RDF.type, o))

# Serialisieren
OUTFILE.parent.mkdir(parents=True, exist_ok=True)
out.serialize(destination=str(OUTFILE), format="turtle")