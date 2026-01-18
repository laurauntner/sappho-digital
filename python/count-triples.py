from rdflib import Graph, URIRef
from rdflib.namespace import SKOS, RDF
from pathlib import Path
from typing import Optional
import os

# Paths
HERE = Path(__file__).resolve().parent
data_dir = (HERE / "../data/rdf").resolve()
vocabs_path = (HERE / "../html/vocab/vocab.ttl").resolve()

files = [
    "authors",
    "works",
    "fragments",
    "analysis",
    "relations",
    "sappho-reception"
]

# Types
GROUP_KEYS = ["motif", "place", "person", "phrase", "plot", "topic", "work"]

# broader + narrower
HIERARCHY_PROPS = [SKOS.broader, SKOS.narrower]

# related
ASSOCIATIVE_PROPS = [SKOS.related]

# *Match
MATCH_PROPS = [
    SKOS.relatedMatch,
    SKOS.narrowMatch,
    SKOS.closeMatch,
    SKOS.broadMatch,
    SKOS.exactMatch,
]

# Helper
def count_triples(file_path: Path) -> int:
    """Zähle Tripel in einer Turtle-Datei."""
    g = Graph()
    g.parse(file_path, format="turtle")
    return len(g)

def local_id(uri: URIRef) -> str:
    s = str(uri)
    if "#" in s:
        return s.rsplit("#", 1)[-1]
    return s.rsplit("/", 1)[-1]

def detect_group(uri: URIRef) -> Optional[str]:
    lid = local_id(uri).lower()
    for key in GROUP_KEYS:
        if lid.startswith(f"{key}_") or f"_{key}_" in lid or lid == key:
            return key
    return None

# Vocabs
def analyze_vocabs(vocabs_file: Path):
    g = Graph()
    g.parse(vocabs_file, format="turtle")

    triples_total = len(g)

    concepts = set(g.subjects(RDF.type, SKOS.Concept))
    total_concepts = len(concepts)
    concepts_per_group = {k: 0 for k in GROUP_KEYS}

    def init_bucket():
        return {
            "hierarchy": 0,       
            "associative": 0,     
            "wikidata_links": 0,  
        }

    totals = init_bucket()
    per_group = {k: init_bucket() for k in GROUP_KEYS}

    for s in concepts:
        grp = detect_group(s)

        h_count = sum(1 for p, o in g.predicate_objects(s) if p in HIERARCHY_PROPS)

        a_count = sum(1 for p, o in g.predicate_objects(s) if p in ASSOCIATIVE_PROPS)

        w_count = sum(
            1
            for p, o in g.predicate_objects(s)
            if p in MATCH_PROPS and isinstance(o, URIRef) and "wikidata.org" in str(o)
        )

        totals["hierarchy"] += h_count
        totals["associative"] += a_count
        totals["wikidata_links"] += w_count

        if grp in per_group:
            concepts_per_group[grp] += 1
            per_group[grp]["hierarchy"] += h_count
            per_group[grp]["associative"] += a_count
            per_group[grp]["wikidata_links"] += w_count

    print("\n=== Vokabular ===")
    print(f"Tripel gesamt: {triples_total}\n")

    print(f"Anzahl SKOS-Konzepte gesamt: {total_concepts}")
    print("Anzahl SKOS-Konzepte pro Typ:")
    for k in GROUP_KEYS:
        print(f"  - {k}: {concepts_per_group[k]}")
    print()

    print("Hierarchische Relationen (broader/narrower):")
    print(f"  Gesamt: {totals['hierarchy']}")
    print("  Nach Typ:")
    for k in GROUP_KEYS:
        print(f"    - {k}: {per_group[k]['hierarchy']}")
    print()

    print("Assoziative Relationen (related):")
    print(f"  Gesamt: {totals['associative']}")
    print("  Nach Typ:")
    for k in GROUP_KEYS:
        print(f"    - {k}: {per_group[k]['associative']}")
    print()

    print("Verlinkungen mit Wikidata (*Match mit Wikidata-Objekt):")
    print(f"  Gesamt: {totals['wikidata_links']}")
    print("  Nach Typ:")
    for k in GROUP_KEYS:
        print(f"    - {k}: {per_group[k]['wikidata_links']}")
    print()

# Main
def main():
    total = 0
    print("=== Instanzen ===")
    for name in files:
        ttl_path = data_dir / f"{name}.ttl"
        if ttl_path.exists():
            try:
                n = count_triples(ttl_path)
                total += n
                print(f"{name}.ttl: {n} Tripel")
            except Exception as e:
                print(f"❌ Fehler beim Parsen von {ttl_path}: {e}")
        else:
            print(f"⚠️ Datei nicht gefunden: {ttl_path}")
    print(f"\nGesamtanzahl der Tripel: {total}")

    if vocabs_path.exists():
        try:
            analyze_vocabs(vocabs_path)
        except Exception as e:
            print(f"❌ Fehler bei der SKOS-Auswertung von {vocabs_path}: {e}")
    else:
        print(f"⚠️ Datei nicht gefunden (SKOS-Auswertung übersprungen): {vocabs_path}")

if __name__ == "__main__":
    main()
