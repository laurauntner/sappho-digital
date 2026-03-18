import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from typing import Optional
from rdflib import Graph, Namespace, URIRef
from rdflib.namespace import RDF, RDFS

# Namespaces

LRMOO = Namespace("http://iflastandards.info/ns/lrm/lrmoo/")
INTRO  = Namespace("https://w3id.org/lso/intro/currentbeta#")

F2_Expression          = LRMOO.F2_Expression
R18_showsActualization = INTRO.R18_showsActualization
R17_actualizesFeature  = INTRO.R17_actualizesFeature

# Feature-Typ aus URI

FEATURE_TYPES = [
    ("person_ref", "/person_ref/",  "Personenreferenzen"),
    ("place_ref",  "/place_ref/",   "Ortsreferenzen"),
    ("character",  "/character/",   "Figuren"),
    ("topos",      "/topos/",       "Rhetorische Topoi"),
    ("motif",      "/motif/",       "Motive"),
    ("topic",      "/topic/",       "Themen"),
    ("plot",       "/plot/",        "Stoffe"),
]

def feature_type(uri: str) -> Optional[str]:
    for key, pattern, _ in FEATURE_TYPES:
        if pattern in uri:
            return key
    return None


def main(ttl_path: str, xml_out: str) -> None:
    print(f"Lese {ttl_path} ...", file=sys.stderr)
    g = Graph()
    g.parse(ttl_path, format="turtle")
    print(f"  {len(g)} Tripel geladen.", file=sys.stderr)

    # F2-Instanzen klassifizieren
    sappho_f2    = set()
    reception_f2 = set()

    for subj in g.subjects(RDF.type, F2_Expression):
        uri = str(subj)
        if "bibl_sappho_" in uri:
            sappho_f2.add(subj)
        elif "bibl_" in uri:
            reception_f2.add(subj)

    # Actualization-Index aufbauen
    act_to_features: dict[URIRef, set[URIRef]] = defaultdict(set)
    for act, _, feat in g.triples((None, R17_actualizesFeature, None)):
        act_to_features[act].add(feat)

    # Features-Index aufbauen
    def build_f2_index(f2_set: set) -> dict:
        idx: dict[URIRef, set[URIRef]] = defaultdict(set)
        for f2 in f2_set:
            for _, _, act in g.triples((f2, R18_showsActualization, None)):
                for feat in act_to_features.get(act, set()):
                    idx[f2].add(feat)
        return idx

    sappho_idx    = build_f2_index(sappho_f2)
    reception_idx = build_f2_index(reception_f2)

    # Nur F2 mit mindestens einer Aktualisierung zählen
    sappho_with_act    = {f2 for f2, feats in sappho_idx.items()    if feats}
    reception_with_act = {f2 for f2, feats in reception_idx.items() if feats}

    n_sappho    = len(sappho_with_act)
    n_reception = len(reception_with_act)

    print(f"  Sappho-Fragmente mit Aktualisierungen:    {n_sappho}", file=sys.stderr)
    print(f"  Rezeptionszeugnisse mit Aktualisierungen: {n_reception}", file=sys.stderr)

    # Label-Lookup
    def get_label(uri: URIRef) -> str:
        en = de = any_label = None
        for _, _, label in g.triples((uri, RDFS.label, None)):
            lang = getattr(label, "language", None)
            if lang == "en":
                en = str(label)
            elif lang == "de":
                de = str(label)
            else:
                any_label = str(label)
        raw = en or de or any_label or str(uri).split("/")[-1]
        return clean_label(raw)

    def clean_label(s: str) -> str:
        s = re.sub(r'^Plot:\s*',      '', s)
        s = re.sub(r'^Motif:\s*',     '', s)
        s = re.sub(r'^Topic:\s*',     '', s)
        s = re.sub(r'^Character:\s*', '', s)
        s = re.sub(r'\s*\(topos\)\s*$',  '', s)
        s = re.sub(r'\s*\(place\)\s*$',  '', s)
        s = re.sub(r'\s*\(person\)\s*$', '', s)
        return s.strip()

    # Pro Feature-Typ: distinkte Features zählen
    for ftype_key, pattern, ftype_label in FEATURE_TYPES:

        all_feat_uris: set[URIRef] = set()
        for feats in sappho_idx.values():
            for f in feats:
                if pattern in str(f):
                    all_feat_uris.add(f)
        for feats in reception_idx.values():
            for f in feats:
                if pattern in str(f):
                    all_feat_uris.add(f)

        print(f"  {ftype_label}: {len(all_feat_uris)} distinkte Features", file=sys.stderr)

    # XML aufbauen
    root_el = ET.Element("statistics")
    root_el.set("nSappho",    str(n_sappho))
    root_el.set("nReception", str(n_reception))

    for ftype_key, pattern, ftype_label in FEATURE_TYPES:

        feat_counts: dict[URIRef, dict] = {}

        all_feat_uris: set[URIRef] = set()
        for feats in sappho_idx.values():
            for f in feats:
                if pattern in str(f):
                    all_feat_uris.add(f)
        for feats in reception_idx.values():
            for f in feats:
                if pattern in str(f):
                    all_feat_uris.add(f)

        for feat_uri in all_feat_uris:
            cs = sum(1 for f2, feats in sappho_idx.items()
                     if feat_uri in feats and f2 in sappho_with_act)
            cr = sum(1 for f2, feats in reception_idx.items()
                     if feat_uri in feats and f2 in reception_with_act)
            feat_counts[feat_uri] = {
                "label": get_label(feat_uri),
                "cs": cs,
                "cr": cr,
                "pct_s": round(cs / n_sappho    * 100, 2) if n_sappho    > 0 else 0.0,
                "pct_r": round(cr / n_reception  * 100, 2) if n_reception > 0 else 0.0,
            }

        sorted_feats = sorted(
            feat_counts.items(),
            key=lambda x: (-x[1]["cr"], -x[1]["cs"], x[1]["label"].lower())
        )

        cat_el = ET.SubElement(root_el, "category")
        cat_el.set("key",   ftype_key)
        cat_el.set("label", ftype_label)
        cat_el.set("n",     str(len(sorted_feats)))

        for feat_uri, d in sorted_feats:
            item_el = ET.SubElement(cat_el, "item")
            item_el.set("label",          d["label"])
            item_el.set("uri",            str(feat_uri))
            item_el.set("countSappho",    str(d["cs"]))
            item_el.set("countReception", str(d["cr"]))
            item_el.set("pctSappho",      f'{d["pct_s"]:.2f}')
            item_el.set("pctReception",   f'{d["pct_r"]:.2f}')

    # -------------------------------------------------------------------------
    # Statistik 2: Pro Sappho-Fragment – Aktualisierungen in Rezeptionszeugnissen
    # -------------------------------------------------------------------------
    # Namespaces für Statistik 2
    INTRO_NS  = Namespace("https://w3id.org/lso/intro/currentbeta#")
    ECRM_NS   = Namespace("http://www.cidoc-crm.org/cidoc-crm/")

    INT18_Reference          = INTRO_NS.INT18_Reference
    R17i_featureIsActualizedIn = INTRO_NS["R17i_featureIsActualizedIn"]
    R18i_actualizationFoundOn  = INTRO_NS["R18i_actualizationFoundOn"]
    P67_refers_to              = ECRM_NS.P67_refers_to

    # Alle INT18_Reference-Instanzen mit "Voigt" im rdfs:label sammeln
    # Label-Format: "Reference to Expression of Fragment 158 Voigt (work)"
    import re as _re

    voigt_refs: dict[URIRef, str] = {}   # Feature-URI → Fragment-Label ("158 Voigt")
    # Suche über alle rdfs:label-Tripel: Subjects mit "Voigt" im Label
    # und "/work_ref/" in der URI (da INT18_Reference = work_ref-Feature)
    for ref_uri, _, lbl in g.triples((None, RDFS.label, None)):
        lbl_str = str(lbl)
        if "Voigt" not in lbl_str:
            continue
        uri_str = str(ref_uri)
        if "/work_ref/" not in uri_str:
            continue
        # Nur Feature-URIs (nicht Aktualisierungs-URIs)
        if "/actualization/" in uri_str:
            continue
        m = _re.search(r'Fragment\s+([\w]+(?:\s+\w+)*?\s*Voigt)', lbl_str)
        frag_label = m.group(1).strip() if m else lbl_str
        # Bereits gefundene behalten (en-Label bevorzugen)
        if ref_uri not in voigt_refs or getattr(lbl, 'language', None) == 'en':
            voigt_refs[ref_uri] = frag_label

    print(f"  INT18_References mit Voigt: {len(voigt_refs)}", file=sys.stderr)

    # Pro INT18_Reference (work_ref mit Voigt-Label):
    # 1. Via R17i_featureIsActualizedIn zur Aktualisierung
    # 2. Via R18i_actualizationFoundOn zur bibl_-Expression
    # 3. Alle Features dieser bibl_-Expression aus reception_idx sammeln

    # Aufbau: frag_label -> { ftype_key -> { feat_uri -> count } }
    frag_data: dict[str, dict[str, dict[URIRef, int]]] = {}

    for ref_uri, frag_label in voigt_refs.items():
        if frag_label not in frag_data:
            frag_data[frag_label] = {k: {} for k, _, _ in FEATURE_TYPES}

        for _, _, act_uri in g.triples((ref_uri, R17i_featureIsActualizedIn, None)):
            # Finde die bibl_-Expression dieser Aktualisierung
            bibl_expr = None
            for _, _, src in g.triples((act_uri, R18i_actualizationFoundOn, None)):
                src_str = str(src)
                if "/expression/bibl_" in src_str and "bibl_sappho_" not in src_str:
                    bibl_expr = src
                    break
            if bibl_expr is None:
                continue

            # Alle Features dieser bibl_-Expression aus reception_idx
            all_feats = reception_idx.get(bibl_expr, set())
            for feat_uri in all_feats:
                ftype = feature_type(str(feat_uri))
                if ftype is None:
                    continue
                counts = frag_data[frag_label][ftype]
                counts[feat_uri] = counts.get(feat_uri, 0) + 1

    # Fragmente ohne jegliche Daten entfernen
    frag_data = {
        fl: ftypes for fl, ftypes in frag_data.items()
        if any(feat_counts for feat_counts in ftypes.values())
    }

    print(f"  Fragmente mit Rezeptionsdaten: {len(frag_data)}", file=sys.stderr)

    # Numerische Sortierung der Voigt-Nummern: "31 Voigt" → 31, "168b Voigt" → 168
    def voigt_sort_key(label: str):
        m = _re.match(r'(\d+)', label)
        num = int(m.group(1)) if m else 9999
        # Suffix (a, b, …) als zweites Kriterium
        suffix = _re.sub(r'^\d+', '', label.split()[0]) if m else label
        return (num, suffix)

    sorted_frags = sorted(frag_data.keys(), key=voigt_sort_key)

    # XML-Block <fragments> aufbauen
    frags_el = ET.SubElement(root_el, "fragments")
    frags_el.set("n", str(len(sorted_frags)))

    for frag_label in sorted_frags:
        frag_el = ET.SubElement(frags_el, "fragment")
        frag_el.set("label", frag_label)

        ftypes = frag_data[frag_label]
        for ftype_key, pattern, ftype_display in FEATURE_TYPES:
            feat_counts = ftypes.get(ftype_key, {})
            if not feat_counts:
                continue

            ftype_el = ET.SubElement(frag_el, "featureType")
            ftype_el.set("key",   ftype_key)
            ftype_el.set("label", ftype_display)
            ftype_el.set("total", str(sum(feat_counts.values())))

            sorted_feats = sorted(
                feat_counts.items(),
                key=lambda x: (-x[1], get_label(x[0]).lower())
            )
            for feat_uri, count in sorted_feats:
                feat_el = ET.SubElement(ftype_el, "item")
                feat_el.set("label", get_label(feat_uri))
                feat_el.set("uri",   str(feat_uri))
                feat_el.set("count", str(count))

    # XML schreiben
    tree = ET.ElementTree(root_el)
    ET.indent(tree, space="  ")
    tree.write(xml_out, encoding="utf-8", xml_declaration=True)
    print(f"Geschrieben: {xml_out}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Verwendung: {sys.argv[0]} <input.ttl> <output.xml>", file=sys.stderr)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])