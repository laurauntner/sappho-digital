from pathlib import Path
import sys
import re
from rdflib import Graph, Namespace, URIRef, BNode, Literal, RDF, RDFS, OWL
from rdflib.collection import Collection

# Namespaces

ECRM = Namespace("http://erlangen-crm.org/current/")
LRMOO = Namespace("http://www.cidoc-crm.org/lrmoo/")
INTRO = Namespace("https://w3id.org/lso/intro/currentbeta#")
PROV = Namespace("http://www.w3.org/ns/prov#")
SAPPHO = Namespace("https://sappho-digital.com/")

# Helpers

def merge_with_precedence(base_dir: Path, out_path: Path) -> Graph:
    order = [
        "authors.ttl",
        "works.ttl",
        "fragments.ttl",
        "analysis.ttl",
        "relations.ttl",
    ]

    files = []
    for name in order:
        p = (base_dir / name).resolve()
        if not p.exists():
            raise FileNotFoundError(f"{name} fehlt im Eingabeordner {base_dir}")
        if p == out_path:
            continue
        files.append(p)

    g_merged = Graph()
    bind_namespaces(g_merged)

    for path in files:
        g_tmp = Graph()
        try:
            g_tmp.parse(path.as_posix(), format="turtle")
        except Exception as e:
            print(f"[WARN] Konnte {path.name} nicht parsen: {e}")
            continue

        for s in set(s for s in g_tmp.subjects() if isinstance(s, URIRef)):
            preds_in_tmp = {p for _, p, _ in g_tmp.triples((s, None, None))}
            for p in preds_in_tmp:
                g_merged.remove((s, p, None))

        for t in g_tmp:
            g_merged.add(t)

        print(f"[OK] Gemerged: {path.name} ({len(g_tmp)} Tripel)")

    return g_merged

def bind_namespaces(g: Graph):
    g.bind("ecrm", ECRM, override=True)
    g.bind("lrmoo", LRMOO, override=True)
    g.bind("intro", INTRO, override=True)
    g.bind("prov", PROV, override=True)

# Main

def main():
    base_dir = Path("../data/rdf").resolve()
    out_path = (base_dir / "sappho-reception.ttl").resolve()

    if not base_dir.exists():
        sys.exit(f"Verzeichnis nicht gefunden: {base_dir}")

    g = merge_with_precedence(base_dir, out_path)

    # Turtle
    tmp_ttl = out_path.with_suffix(".ttl.tmp")
    g.serialize(destination=tmp_ttl.as_posix(), format="turtle", encoding="utf-8")
    Path(tmp_ttl).replace(out_path)

    # RDF/XML
    rdf_out = out_path.with_suffix(".rdf")       
    tmp_rdf = rdf_out.with_suffix(".rdf.tmp")
    g.serialize(destination=tmp_rdf.as_posix(), format="pretty-xml", encoding="utf-8")
    Path(tmp_rdf).replace(rdf_out)

    print(f"\nFertig. Dateien gespeichert:\n  {out_path}\n  {rdf_out}")
    print(f"Gesamtzahl Tripel: {len(g)}")

if __name__ == "__main__":
    main()
