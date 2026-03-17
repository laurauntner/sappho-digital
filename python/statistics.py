#!/usr/bin/env python3
"""
statistics.py
Liest sappho-reception.ttl, berechnet Feature-Statistiken und schreibt
eine statistics-data.xml, die anschließend von statistics.xsl zu HTML
verarbeitet wird.

Aufruf (via ant):
    python3 python/statistics.py data/rdf/sappho-reception.ttl target/statistics-data.xml
"""

import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from typing import Optional
from rdflib import Graph, Namespace, URIRef
from rdflib.namespace import RDF, RDFS

# ── Namespaces ────────────────────────────────────────────────────────────────

LRMOO = Namespace("http://iflastandards.info/ns/lrm/lrmoo/")
INTRO  = Namespace("https://w3id.org/lso/intro/currentbeta#")

F2_Expression          = LRMOO.F2_Expression
R18_showsActualization = INTRO.R18_showsActualization
R17_actualizesFeature  = INTRO.R17_actualizesFeature

# ── Feature-Typ aus URI ───────────────────────────────────────────────────────

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


# ── Hauptlogik ────────────────────────────────────────────────────────────────

def main(ttl_path: str, xml_out: str) -> None:
    print(f"Lese {ttl_path} ...", file=sys.stderr)
    g = Graph()
    g.parse(ttl_path, format="turtle")
    print(f"  {len(g)} Tripel geladen.", file=sys.stderr)

    # ── F2-Instanzen klassifizieren ───────────────────────────────────────────
    sappho_f2    = set()
    reception_f2 = set()

    for subj in g.subjects(RDF.type, F2_Expression):
        uri = str(subj)
        if "bibl_sappho_" in uri:
            sappho_f2.add(subj)
        elif "bibl_" in uri:
            reception_f2.add(subj)

    # ── Actualization-Index aufbauen: actualization_uri → set(feature_uri) ───
    act_to_features: dict[URIRef, set[URIRef]] = defaultdict(set)
    for act, _, feat in g.triples((None, R17_actualizesFeature, None)):
        act_to_features[act].add(feat)

    # ── F2 → Features-Index aufbauen ─────────────────────────────────────────
    # f2_to_features[f2_uri] = set of feature URIs
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

    # ── Label-Lookup ──────────────────────────────────────────────────────────
    def get_label(uri: URIRef) -> str:
        # Bevorzuge englisches Label, dann deutsches, dann beliebiges, dann URI-Fragment
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

    # ── Pro Feature-Typ: distinkte Features zählen ────────────────────────────
    for ftype_key, pattern, ftype_label in FEATURE_TYPES:

        # Alle Feature-URIs die in irgendeiner Gruppe vorkommen
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

    # ── XML aufbauen ──────────────────────────────────────────────────────────
    root_el = ET.Element("statistics")
    root_el.set("nSappho",    str(n_sappho))
    root_el.set("nReception", str(n_reception))

    for ftype_key, pattern, ftype_label in FEATURE_TYPES:

        # Alle Feature-URIs
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

        # Sortierung: cr absteigend, cs absteigend, label aufsteigend
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

    # ── XML schreiben ─────────────────────────────────────────────────────────
    tree = ET.ElementTree(root_el)
    ET.indent(tree, space="  ")
    tree.write(xml_out, encoding="utf-8", xml_declaration=True)
    print(f"Geschrieben: {xml_out}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Verwendung: {sys.argv[0]} <input.ttl> <output.xml>", file=sys.stderr)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
