import re
import sys
import xml.etree.ElementTree as ET
from typing import Optional
from rdflib import Graph, Namespace, URIRef
from rdflib.namespace import RDF, RDFS

LRMOO = Namespace("http://iflastandards.info/ns/lrm/lrmoo/")
INTRO  = Namespace("https://w3id.org/lso/intro/currentbeta#")
ECRM   = Namespace("http://erlangen-crm.org/current/")


def main(ttl_path: str, xml_out: str) -> None:
    print(f"Lese {ttl_path} ...", file=sys.stderr)
    g = Graph()
    g.parse(ttl_path, format="turtle")
    n_triples = len(g)
    print(f"  {n_triples} Tripel geladen.", file=sys.stderr)

    # ── F2_Expressions aufteilen ──────────────────────────────────────────────
    F2_Expression = LRMOO.F2_Expression
    sappho_f2    = set()
    reception_f2 = set()
    for subj in g.subjects(RDF.type, F2_Expression):
        uri = str(subj)
        if "bibl_sappho_" in uri:
            sappho_f2.add(subj)
        elif "bibl_" in uri:
            reception_f2.add(subj)
    n_reception = len(reception_f2)
    print(f"  Rezeptionszeugnisse: {n_reception}", file=sys.stderr)

    # ── Autor_innen ───────────────────────────────────────────────────────────
    E21_Person = ECRM["E21_Person"]
    n_authors = sum(1 for p in g.subjects(RDF.type, E21_Person)
                    if "/author_" in str(p))
    print(f"  Autor_innen: {n_authors}", file=sys.stderr)

    # ── Aktualisierungen aufbauen (für analysierte Texte) ─────────────────────
    R18 = INTRO.R18_showsActualization
    R17 = INTRO.R17_actualizesFeature
    act_to_feats: dict = {}
    for act, _, feat in g.triples((None, R17, None)):
        act_to_feats.setdefault(act, set()).add(feat)

    # ── Exemplarisch analysierte Texte ────────────────────────────────────────
    reception_with_act: set = set()
    for f2 in reception_f2:
        for _, _, act in g.triples((f2, R18, None)):
            if act_to_feats.get(act):
                reception_with_act.add(f2)
                break
    n_analysed = len(reception_with_act)
    print(f"  Exemplarisch analysierte Texte: {n_analysed}", file=sys.stderr)

    # ── INT31-Beziehungen ─────────────────────────────────────────────────────
    INT31 = INTRO["INT31_IntertextualRelation"]
    n_int31 = sum(1 for _ in g.subjects(RDF.type, INT31))
    print(f"  INT31-Beziehungen: {n_int31}", file=sys.stderr)

    # ── Zeitspanne der Rezeptionszeugnisse ────────────────────────────────────
    P4               = ECRM["P4_has_time-span"]
    R17i_cb          = LRMOO["R17i_was_created_by"]
    R4i_embodied     = LRMOO["R4i_is_embodied_in"]
    R24i_created_thr = LRMOO["R24i_was_created_through"]

    def extract_year(ts_uri: URIRef) -> Optional[int]:
        m = re.search(r'/timespan/(\d{4})', str(ts_uri))
        if m:
            return int(m.group(1))
        for _, _, lbl in g.triples((ts_uri, RDFS.label, None)):
            m2 = re.search(r'\b(\d{4})\b', str(lbl))
            if m2:
                return int(m2.group(1))
        return None

    def get_year(f2_uri: URIRef) -> Optional[int]:
        for _, _, f28 in g.triples((f2_uri, R17i_cb, None)):
            for _, _, ts in g.triples((f28, P4, None)):
                y = extract_year(ts)
                if y is not None:
                    return y
        for _, _, f3 in g.triples((f2_uri, R4i_embodied, None)):
            for _, _, f30 in g.triples((f3, R24i_created_thr, None)):
                for _, _, ts in g.triples((f30, P4, None)):
                    y = extract_year(ts)
                    if y is not None:
                        return y
        return None

    years = [y for f2 in reception_f2 if (y := get_year(f2)) is not None]
    year_min = min(years) if years else 0
    year_max = max(years) if years else 0
    print(f"  Zeitspanne: {year_min}–{year_max}", file=sys.stderr)

    # ── XML schreiben ─────────────────────────────────────────────────────────
    root = ET.Element("homepage-counter")
    root.set("nTriples",   str(n_triples))
    root.set("nReception", str(n_reception))
    root.set("nAuthors",   str(n_authors))
    root.set("nAnalysed",  str(n_analysed))
    root.set("nInt31",     str(n_int31))
    root.set("yearMin",    str(year_min))
    root.set("yearMax",    str(year_max))

    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    tree.write(xml_out, encoding="utf-8", xml_declaration=True)
    print(f"Geschrieben: {xml_out}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Verwendung: {sys.argv[0]} <input.ttl> <output.xml>", file=sys.stderr)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])