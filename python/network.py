import sys
import re
import xml.etree.ElementTree as ET
from xml.dom import minidom
from pathlib import Path
from collections import defaultdict
from rdflib import Graph, BNode, Literal, URIRef


INPUT_FILE  = sys.argv[1] if len(sys.argv) > 1 else "./sappho-digital/data/rdf/sappho-reception.ttl"
OUTPUT_FILE = sys.argv[2] if len(sys.argv) > 2 else "network-data.xml"
HTML_OUT_DIR = Path(OUTPUT_FILE).parent

DEFAULT_TOP_N     = 200
DEFAULT_MAX_EDGES = 800
DEFAULT_NEIGHBORS = 5
MAX_NEIGHBORS     = 30

RDF_TYPE   = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
RDFS_LABEL = "http://www.w3.org/2000/01/rdf-schema#label"

START_URI   = "https://sappho-digital.com/expression/bibl_00e9aff1"
FOCUS_CLASS = "https://w3id.org/lso/intro/currentbeta#INT31_IntertextualRelation"
BASE        = "https://sappho-digital.com/"

NS_COLORS = {
    "crm":      "#3B82F6",
    "ecrm":     "#60A5FA",
    "lrmoo":    "#2563EB",
    "intro":    "#10B981",
    "prov":     "#6B7280",
    "rdf":      "#6B7280",
    "rdfs":     "#9CA3AF",
    "owl":      "#9CA3AF",
    "skos":     "#9CA3AF",
    "schema":   "#9CA3AF",
    "dbpedia":  "#E5E7EB",
    "dnb":      "#E5E7EB",
    "wikidata": "#E5E7EB",
    "viaf":     "#E5E7EB",
    "_bnode":   "#9CA3AF",
    "_unknown": "#E5E7EB",
}

KNOWN_NS = {
    "http://www.cidoc-crm.org/cidoc-crm/":         "crm",
    "http://erlangen-crm.org/current/":             "ecrm",
    "http://erlangen-crm.org/":                     "ecrm",
    "http://iflastandards.info/ns/lrm/lrmoo/":      "lrmoo",
    "https://w3id.org/lso/intro/currentbeta#":      "intro",
    "http://www.w3.org/ns/prov#":                   "prov",
    "http://www.w3.org/1999/02/22-rdf-syntax-ns#":  "rdf",
    "http://www.w3.org/2000/01/rdf-schema#":        "rdfs",
    "http://www.w3.org/2002/07/owl#":               "owl",
    "http://www.w3.org/2004/02/skos/core#":         "skos",
    "https://schema.org/":                          "schema",
    "http://dbpedia.org/resource/":                 "dbpedia",
    "https://dbpedia.org/resource/":                "dbpedia",
    "http://d-nb.info/gnd/":                        "dnb",
    "https://d-nb.info/gnd/":                       "dnb",
    "http://www.wikidata.org/entity/":              "wikidata",
    "https://www.wikidata.org/entity/":             "wikidata",
    "http://viaf.org/viaf/":                        "viaf",
    "https://viaf.org/viaf/":                       "viaf",
}

HIDDEN_BY_DEFAULT = {
    "http://erlangen-crm.org/current/E21_Person",
    "http://erlangen-crm.org/current/E35_Title",
    "http://erlangen-crm.org/current/E36_Visual_Item",
    "http://erlangen-crm.org/current/E42_Identifier",
    "http://erlangen-crm.org/current/E52_Time-Span",
    "http://erlangen-crm.org/current/E53_Place",
    "http://erlangen-crm.org/current/E55_Type",
    "http://erlangen-crm.org/current/E67_Birth",
    "http://erlangen-crm.org/current/E69_Death",
    "http://erlangen-crm.org/current/E73_Information_Object",
    "http://erlangen-crm.org/current/E74_Group",
    "http://erlangen-crm.org/current/E90_Symbolic_Object",
    "http://iflastandards.info/ns/lrm/lrmoo/F27_Work_Creation",
    "http://iflastandards.info/ns/lrm/lrmoo/F28_Expression_Creation",
    "http://iflastandards.info/ns/lrm/lrmoo/F3_Manifestation",
    "http://iflastandards.info/ns/lrm/lrmoo/F30_Manifestation_Creation",
}

ECRM  = "http://erlangen-crm.org/current/"
INTRO = "https://w3id.org/lso/intro/currentbeta#"
RDFS_SEE_ALSO         = "http://www.w3.org/2000/01/rdf-schema#seeAlso"
P138_REPRESENTS       = ECRM + "P138_represents"
P98_BROUGHT_INTO_LIFE = ECRM + "P98_brought_into_life"
P100_WAS_DEATH_OF     = ECRM + "P100_was_death_of"
P4I_IS_TIMESPAN_OF    = ECRM + "P4i_is_time-span_of"
P7I_WITNESSED         = ECRM + "P7i_witnessed"
P1I_IDENTIFIES        = ECRM + "P1i_identifies"
P2_HAS_TYPE           = ECRM + "P2_has_type"
R18I_FOUND_ON         = INTRO + "R18i_actualizationFoundOn"
R30I_IS_PASSAGE_OF    = INTRO + "R30i_isTextPassageOf"


def get_prefix(uri):
    best, best_len = "_unknown", 0
    for ns, px in KNOWN_NS.items():
        if uri.startswith(ns) and len(ns) > best_len:
            best, best_len = px, len(ns)
    return best

def shorten(uri):
    m = re.search(r'[/#:]([^/#:]+)$', uri)
    return m.group(1) if m else uri

def get_labels(g):
    """Liest rdfs:label-Werte; @de wird bevorzugt, dann @en, dann sprachneutral."""
    de:   dict[str, str] = {}
    en:   dict[str, str] = {}
    any_: dict[str, str] = {}
    for s, p, o in g.triples((None, URIRef(RDFS_LABEL), None)):
        if not isinstance(o, Literal):
            continue
        key  = str(s)
        lang = (o.language or "").lower()
        if lang == "de":
            de[key] = str(o)
        elif lang == "en":
            en.setdefault(key, str(o))
        else:
            any_.setdefault(key, str(o))
    merged = {**any_, **en, **de}
    return {k: clean_label(v) for k, v in merged.items()}


def clean_label(s: str) -> str:
    """Entfernt unerwünschte Präfixe und Suffixe aus RDF-Labels."""
    s = re.sub(r"^Expression\s+creation\s+of\s+",    "", s, flags=re.I).strip()
    s = re.sub(r"^Expressionserstellung\s+von\s+",   "", s, flags=re.I).strip()
    s = re.sub(r"^Expression\s+of\s+",               "", s, flags=re.I).strip()
    s = re.sub(r"^Expression\s+von\s+",              "", s, flags=re.I).strip()
    s = re.sub(r"^(Motif|Motiv|Topic|Thema|Plot|Stoff|Character|Figur)\s*:\s*",
               "", s, flags=re.I).strip()
    s = re.sub(r"^(Reference\s+to|Referenz\s+auf)\s+",           "", s, flags=re.I).strip()
    s = re.sub(r"^(Passage\s+from|Passage\s+aus)\s+",            "", s, flags=re.I).strip()
    s = re.sub(
        r"\s*\((Motif|Motiv|Topic|Thema|Plot|Stoff|Character|Figur|"
        r"place|Ort|person|Person|work|Werk|topos|Topos)\)\s*$",
        "", s, flags=re.I).strip()
    s = s.replace("»", "").replace("«", "")
    return s.strip()

def local_id(uri):
    return uri.rstrip("/").rsplit("/", 1)[-1].rsplit("#", 1)[-1]

def first_obj(g, subject, predicate):
    for _, _, o in g.triples((URIRef(subject), URIRef(predicate), None)):
        if not isinstance(o, Literal):
            return str(o)
    return None

def all_objs(g, subject, predicate):
    return [str(o) for _, _, o in g.triples((URIRef(subject), URIRef(predicate), None))
            if not isinstance(o, Literal)]


def page_exists(url):
    if not url or not url.startswith(BASE):
        return True
    rel  = url[len(BASE):]
    path = HTML_OUT_DIR / rel
    return path.exists()

def extract_bibl_from_uri(uri):
    for part in uri.split("/"):
        if not part.startswith("bibl_"):
            continue
        identifier = re.split(r'_bibl_', part, maxsplit=1)[0]
        segs = identifier.split("_")
        kept = ["bibl"]
        id_started = False 
        for seg in segs[1:]:
            is_pure_alpha = bool(re.fullmatch(r'[a-zA-Z]+', seg))
            has_hyphen    = '-' in seg
            if id_started and is_pure_alpha:
                break
            if has_hyphen and not re.match(r'\d', seg):
                break
            kept.append(seg)
            if not is_pure_alpha:
                id_started = True
        return "_".join(kept)
    return None

def resolve_url(uri, classes, g, labels):

    # E21_Person
    if "http://erlangen-crm.org/current/E21_Person" in classes:
        lid = local_id(uri)
        if lid.startswith("author_"):   return BASE + "analyse.html", None
        if lid.startswith("person_"):   return BASE + "pers-refs.html", None
        if lid.startswith("editor_"):   return "", None
        return uri, f"E21_Person: unbekanntes Muster: {uri}"

    # E35_Title
    if "http://erlangen-crm.org/current/E35_Title" in classes:
        lid = local_id(uri)
        if lid.startswith("bibl_"):     return BASE + lid + ".html", None
        return BASE + "analyse.html", None

    # E36_Visual_Item
    if "http://erlangen-crm.org/current/E36_Visual_Item" in classes:
        see_also = first_obj(g, uri, RDFS_SEE_ALSO)
        if see_also: return see_also, None
        return uri, f"E36_Visual_Item: kein rdfs:seeAlso fuer {uri}"

    # E42_Identifier
    if "http://erlangen-crm.org/current/E42_Identifier" in classes:
        lid     = local_id(uri)
        id_type = first_obj(g, uri, P2_HAS_TYPE) or ""

        if "id_type/dbpedia" in id_type:
            label = labels.get(uri)
            if label: return f"https://dbpedia.org/resource/{label}", None
            return uri, f"E42_Identifier (dbpedia): kein rdfs:label fuer {uri}"

        if "id_type/wikidata" in id_type:
            label = labels.get(uri)
            if label: return f"https://www.wikidata.org/entity/{label}", None
            return uri, f"E42_Identifier (wikidata): kein rdfs:label fuer {uri}"

        if "id_type/gnd" in id_type:
            label = labels.get(uri)
            if label: return f"https://d-nb.info/gnd/{label}", None
            return uri, f"E42_Identifier (gnd): kein rdfs:label fuer {uri}"

        if "id_type/viaf" in id_type:
            label = labels.get(uri)
            if label: return f"http://viaf.org/viaf/{label}", None
            return uri, f"E42_Identifier (viaf): kein rdfs:label fuer {uri}"

        if "id_type/goodreads" in id_type:
            label = labels.get(uri)
            if label: return f"https://www.goodreads.com/work/show/{label}", None
            return uri, f"E42_Identifier (goodreads): kein rdfs:label fuer {uri}"

        identifies = first_obj(g, uri, P1I_IDENTIFIES)
        if identifies:
            t_lid = local_id(identifies)
            if t_lid.startswith("author_"):  return BASE + "analyse.html", None
            if t_lid.startswith("bibl_"):    return BASE + t_lid + ".html", None
            if t_lid.startswith("motif_"):   return BASE + "motifs.html", None
            if t_lid.startswith("plot_"):    return BASE + "plots.html", None
            if t_lid.startswith("topic_"):   return BASE + "topics.html", None
            if t_lid.startswith("topos_"):   return BASE + "topoi.html", None
            if t_lid.startswith("person_"):  return BASE + "pers-refs.html", None
            if t_lid.startswith("editor_"):  return BASE + "analyse.html", None
            if t_lid.startswith("place_"):   return BASE + "place-refs.html", None
            if "/work_ref/"  in identifies:  return BASE + "work-refs.html", None
            if "/place_ref/" in identifies:  return BASE + "place-refs.html", None
            return uri, f"E42_Identifier: P1i_identifies-Ziel nicht erkannt: {identifies}"

        if lid.startswith("bibl_"):   return BASE + lid + ".html", None
        if lid.startswith("author_"): return BASE + "analyse.html", None
        return uri, f"E42_Identifier: kein Mapping fuer {uri} (Typ: {id_type or 'unbekannt'})"

    # E52_Time-Span
    if "http://erlangen-crm.org/current/E52_Time-Span" in classes:
        for o_str in all_objs(g, uri, P4I_IS_TIMESPAN_OF):
            o_lid = local_id(o_str)
            if "/birth/" in o_str or "/death/" in o_str:
                person = first_obj(g, o_str, P98_BROUGHT_INTO_LIFE) or \
                         first_obj(g, o_str, P100_WAS_DEATH_OF)
                if person: return BASE + local_id(str(person)) + ".html", None
            if o_lid.startswith("bibl_"): return BASE + o_lid + ".html", None
        return BASE + "analyse.html", None

    # E53_Place
    if "http://erlangen-crm.org/current/E53_Place" in classes:
        lid = local_id(uri)
        if lid.startswith("place_"):
            return BASE + lid + ".html", None
        return uri, f"E53_Place: unbekanntes Muster: {uri}"

    # E55_Type
    if "http://erlangen-crm.org/current/E55_Type" in classes:
        if "/genre/Prosa" in uri:  return BASE + "toc-prosa.html", None
        if "/genre/Lyrik" in uri or "/genre/lyrik" in uri: return BASE + "toc-lyrik.html", None
        if "/genre/Drama" in uri or "/genre/drama" in uri: return BASE + "toc-drama.html", None
        if "/genre/Comic" in uri or "/genre/comic" in uri: return BASE + "toc-sonstige.html", None
        if "/id_type/gnd"            in uri: return "https://www.dnb.de/DE/Professionell/Standardisierung/GND/gnd_node.html", None
        if "/id_type/wikidata"        in uri: return "https://www.wikidata.org", None
        if "/id_type/dbpedia"         in uri: return "https://dbpedia.org", None
        if "/id_type/viaf"            in uri: return "https://viaf.org", None
        if "/id_type/goodreads"       in uri: return "https://www.goodreads.com", None
        if "/id_type/sappho-digital"  in uri or "/gender/" in uri or "/genre_type/" in uri: return BASE, None
        if "/gender_type/wikidata"    in uri: return "https://www.wikidata.org", None
        return uri, f"E55_Type: kein Mapping fuer {uri}"

    # E67_Birth
    if "http://erlangen-crm.org/current/E67_Birth" in classes:
        person = first_obj(g, uri, P98_BROUGHT_INTO_LIFE)
        if person: return BASE + local_id(str(person)) + ".html", None
        return uri, f"E67_Birth: kein P98_brought_into_life fuer {uri}"

    # E69_Death
    if "http://erlangen-crm.org/current/E69_Death" in classes:
        person = first_obj(g, uri, P100_WAS_DEATH_OF)
        if person: return BASE + local_id(str(person)) + ".html", None
        return uri, f"E69_Death: kein P100_was_death_of fuer {uri}"

    # E73_Information_Object
    if "http://erlangen-crm.org/current/E73_Information_Object" in classes:
        see_also = first_obj(g, uri, RDFS_SEE_ALSO)
        if see_also: return see_also, None
        return uri, f"E73_Information_Object: kein rdfs:seeAlso fuer {uri}"

    # E74_Group
    if "http://erlangen-crm.org/current/E74_Group" in classes:
        lid = local_id(uri)
        if lid.startswith("publisher_"): return BASE + "analyse.html", None
        return uri, f"E74_Group: unbekanntes Muster: {uri}"

    # E90_Symbolic_Object
    if "http://erlangen-crm.org/current/E90_Symbolic_Object" in classes:
        return BASE + local_id(uri) + ".html", None

    # INT_Character
    if "https://w3id.org/lso/intro/currentbeta#INT_Character" in classes:
        return BASE + "pers-refs.html", None

    # INT_Interpretation
    if "https://w3id.org/lso/intro/currentbeta#INT_Interpretation" in classes:
        return BASE + "analyse.html", None

    # INT_Motif
    if "https://w3id.org/lso/intro/currentbeta#INT_Motif" in classes:
        return BASE + "motifs.html", None

    # INT_Plot
    if "https://w3id.org/lso/intro/currentbeta#INT_Plot" in classes:
        return BASE + "plots.html", None

    # INT_Topic
    if "https://w3id.org/lso/intro/currentbeta#INT_Topic" in classes:
        return BASE + "topics.html", None

    # INT_Topos
    if "https://w3id.org/lso/intro/currentbeta#INT_Topos" in classes:
        return BASE + "topoi.html", None

    # INT18_Reference
    if "https://w3id.org/lso/intro/currentbeta#INT18_Reference" in classes:
        if "/person_ref/" in uri: return BASE + "pers-refs.html",  None
        if "/work_ref/"   in uri: return BASE + "work-refs.html",  None
        if "/place_ref/"  in uri: return BASE + "place-refs.html", None
        return uri, f"INT18_Reference: Typ nicht erkannt: {uri}"

    # INT2_ActualizationOfFeature
    if "https://w3id.org/lso/intro/currentbeta#INT2_ActualizationOfFeature" in classes:
        expr = first_obj(g, uri, R18I_FOUND_ON)
        if expr:
            lid = local_id(str(expr))
            if lid.startswith("bibl_"): return BASE + lid + ".html", None
        bibl_id = extract_bibl_from_uri(uri)
        if bibl_id:
            return BASE + bibl_id + ".html", None
        return uri, f"INT2_ActualizationOfFeature: kein bibl_ auflösbar fuer {uri}"

    # INT21_TextPassage
    if "https://w3id.org/lso/intro/currentbeta#INT21_TextPassage" in classes:
        exprs = all_objs(g, uri, R30I_IS_PASSAGE_OF)
        if exprs:
            urls = ",".join(BASE + local_id(str(e)) + ".html" for e in exprs)
            return urls, None
        return uri, f"INT21_TextPassage: kein R30i_isTextPassageOf fuer {uri}"

    # INT31_IntertextualRelation
    if "https://w3id.org/lso/intro/currentbeta#INT31_IntertextualRelation" in classes:
        return BASE + "intertexts.html", None

    # F1_Work
    if "http://iflastandards.info/ns/lrm/lrmoo/F1_Work" in classes:
        return BASE + "analyse.html", None

    # F2_Expression
    if "http://iflastandards.info/ns/lrm/lrmoo/F2_Expression" in classes:
        return BASE + local_id(uri) + ".html", None

    # F27_Work_Creation
    if "http://iflastandards.info/ns/lrm/lrmoo/F27_Work_Creation" in classes:
        return BASE + "analyse.html", None

    # F28_Expression_Creation
    if "http://iflastandards.info/ns/lrm/lrmoo/F28_Expression_Creation" in classes:
        lid = local_id(uri)
        if lid.startswith("bibl_"): return BASE + lid + ".html", None
        return BASE + "analyse.html", None

    # F3_Manifestation
    if "http://iflastandards.info/ns/lrm/lrmoo/F3_Manifestation" in classes:
        lid = local_id(uri)
        if lid.startswith("bibl_"): return BASE + lid + ".html", None
        return BASE + "analyse.html", None

    # F30_Manifestation_Creation
    if "http://iflastandards.info/ns/lrm/lrmoo/F30_Manifestation_Creation" in classes:
        lid = local_id(uri)
        if lid.startswith("bibl_"): return BASE + lid + ".html", None
        return BASE + "analyse.html", None

    return "", f"KEIN URL-MAPPING fuer {uri} (Klassen: {', '.join(sorted(classes)) or 'keine'})"

def build_graph_data(g):
    labels       = get_labels(g)
    degree       = defaultdict(int)
    subject_uris = set()
    node_classes = defaultdict(set)
    raw_triples  = []

    for s, p, o in g:
        if isinstance(o, Literal): continue
        ss, ps, os = str(s), str(p), str(o)
        raw_triples.append((ss, ps, os))
        degree[ss] += 1
        degree[os] += 1
        subject_uris.add(ss)
        if ps == RDF_TYPE:
            node_classes[ss].add(os)
            node_classes[os].add("http://www.w3.org/2002/07/owl#Class")

    uris      = [u for u in degree if u in subject_uris]
    uri_to_id = {u: i for i, u in enumerate(uris)}

    nodes = []
    for uri, nid in uri_to_id.items():
        grp   = "_bnode" if uri.startswith("_:") else get_prefix(uri)
        label = labels.get(uri, shorten(uri))
        nodes.append({
            "id": nid, "label": label, "uri": uri,
            "group": grp, "degree": degree[uri],
            "classes": sorted(node_classes.get(uri, [])),
        })

    seen  = set()
    edges = []
    for ss, ps, os in raw_triples:
        if ss not in uri_to_id or os not in uri_to_id: continue
        key = (uri_to_id[ss], uri_to_id[os], ps)
        if key in seen: continue
        seen.add(key)
        edges.append({
            "from": uri_to_id[ss], "to": uri_to_id[os],
            "label": shorten(ps), "predicate": ps,
        })

    return nodes, edges, labels


def build_class_stats(nodes):
    stats = defaultdict(int)
    for n in nodes:
        for c in n["classes"]:
            stats[c] += 1
    return dict(stats)


def compute_int31_neighbors(nodes, edges):
    int31_ids = {n["id"] for n in nodes if FOCUS_CLASS in n["classes"]}
    neighbors = set()
    for e in edges:
        if e["from"] in int31_ids: neighbors.add(e["to"])
        if e["to"]   in int31_ids: neighbors.add(e["from"])
    neighbors -= int31_ids
    return sorted(neighbors)


def resolve_all_urls(nodes, g, labels):
    url_map  = {}
    warnings = []
    for n in nodes:
        uri     = n["uri"]
        classes = set(n["classes"])
        if uri.startswith("_:"):
            url_map[n["id"]] = ""
            continue
        url, warn = resolve_url(uri, classes, g, labels)
        if warn:
            warnings.append(warn)

        # Komma-getrennte URLs einzeln prüfen
        if url:
            valid_urls = []
            for single_url in url.split(","):
                single_url = single_url.strip()
                if not single_url:
                    continue
                if single_url.startswith(BASE) and not page_exists(single_url):
                    warnings.append(f"HTML nicht gefunden (kein Link gesetzt): {single_url} <- {uri}")
                else:
                    valid_urls.append(single_url)
            url = ",".join(valid_urls)

        url_map[n["id"]] = url
    return url_map, warnings


def build_xml(nodes, edges, class_stats, int31_neighbors, total_triples, url_map):
    root = ET.Element("network")

    meta = ET.SubElement(root, "meta")
    ET.SubElement(meta, "totalTriples").text     = str(total_triples)
    ET.SubElement(meta, "totalNodes").text       = str(len(nodes))
    ET.SubElement(meta, "totalEdges").text       = str(len(edges))
    ET.SubElement(meta, "defaultTopN").text      = str(DEFAULT_TOP_N)
    ET.SubElement(meta, "defaultMaxEdges").text  = str(DEFAULT_MAX_EDGES)
    ET.SubElement(meta, "defaultNeighbors").text = str(DEFAULT_NEIGHBORS)
    ET.SubElement(meta, "maxNeighbors").text     = str(MAX_NEIGHBORS)
    ET.SubElement(meta, "startUri").text         = START_URI
    ET.SubElement(meta, "focusClass").text       = FOCUS_CLASS

    nss = ET.SubElement(meta, "namespaces")
    for uri, prefix in KNOWN_NS.items():
        el = ET.SubElement(nss, "ns")
        el.set("uri", uri); el.set("prefix", prefix)

    colors = ET.SubElement(meta, "colors")
    for prefix, color in NS_COLORS.items():
        el = ET.SubElement(colors, "color")
        el.set("prefix", prefix); el.set("value", color)

    hidden = ET.SubElement(meta, "hiddenByDefault")
    for cls in sorted(HIDDEN_BY_DEFAULT):
        ET.SubElement(hidden, "class").text = cls

    cs = ET.SubElement(root, "classStats")
    for cls, count in sorted(class_stats.items(), key=lambda x: -x[1]):
        el = ET.SubElement(cs, "classStat")
        el.set("uri", cls); el.set("count", str(count))
        el.set("short", shorten(cls)); el.set("prefix", get_prefix(cls))
        el.set("hiddenByDefault", "true" if cls in HIDDEN_BY_DEFAULT else "false")

    nb_el = ET.SubElement(root, "int31Neighbors")
    for nid in int31_neighbors:
        ET.SubElement(nb_el, "id").text = str(nid)

    nodes_el = ET.SubElement(root, "nodes")
    for n in nodes:
        el = ET.SubElement(nodes_el, "node")
        el.set("id",      str(n["id"]))
        el.set("label",   n["label"])
        el.set("uri",     n["uri"])
        el.set("group",   n["group"])
        el.set("degree",  str(n["degree"]))
        el.set("pageUrl", url_map.get(n["id"], ""))
        for cls in n["classes"]:
            ET.SubElement(el, "class").text = cls

    edges_el = ET.SubElement(root, "edges")
    for e in edges:
        el = ET.SubElement(edges_el, "edge")
        el.set("from",      str(e["from"]))
        el.set("to",        str(e["to"]))
        el.set("label",     e["label"])
        el.set("predicate", e["predicate"])

    return root


def pretty_print(root):
    raw      = ET.tostring(root, encoding="unicode")
    reparsed = minidom.parseString(raw)
    return reparsed.toprettyxml(indent="  ", encoding=None)


def main():
    print(f"Lade RDF: {INPUT_FILE}")
    g = Graph()
    g.parse(INPUT_FILE)
    total_triples = len(g)
    print(f"Tripel: {total_triples:,}")

    nodes, edges, labels = build_graph_data(g)
    class_stats          = build_class_stats(nodes)
    int31_neighbors      = compute_int31_neighbors(nodes, edges)

    print("Löse URLs auf …")

    url_map, warnings = resolve_all_urls(nodes, g, labels)

    if warnings:
        print(f"\n⚠️  {len(warnings)} URL-Mapping-Warnungen:")
        for w in sorted(set(warnings)):
            print(f"   {w}")
        print()
    else:
        print("✓ Alle URLs erfolgreich aufgelöst.")

    root    = build_xml(nodes, edges, class_stats, int31_neighbors, total_triples, url_map)
    xml_str = pretty_print(root)
    Path(OUTPUT_FILE).write_text(xml_str, encoding="utf-8")

    print(f"✓ gespeichert: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()