from rdflib import Graph, URIRef
from rdflib.namespace import SKOS, RDF
from pathlib import Path
from collections import defaultdict
from typing import Optional

# Path
data_dir = Path("../data/rdf")

# Files
files = [
    "authors",
    "works",
    "fragments",
    "analysis",
    "relations",
    "sappho-reception",
    "vocab"
]

# Vocab
vocabs_path = data_dir / "vocab.ttl"

# Vocab Concepts
GROUP_KEYS = ["motif", "place", "person", "phrase", "plot", "topic", "work"]

# Helpers
def count_triples(file_path: Path) -> int:
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

def analyze_vocabs(vocabs_file: Path):
    g = Graph()
    g.parse(vocabs_file, format="turtle")

    # All Concepts
    concepts = set(g.subjects(RDF.type, SKOS.Concept))
    total_concepts = len(concepts)

    # Aggregatspeicher
    groups = {
        key: {
            "concepts": 0,
            "broader": 0,
            "narrower": 0,
            "related": 0,
            "relatedMatch_triples": 0,
            "wikidata_relatedMatch_objects": set(),
        }
        for key in GROUP_KEYS
    }

    overall = {
        "broader": 0,
        "narrower": 0,
        "related": 0,
        "relatedMatch_triples": 0,
        "wikidata_relatedMatch_objects": set(),
    }

    for s in concepts:
        grp = detect_group(s)

        # Relations
        broader_os = list(g.objects(s, SKOS.broader))
        narrower_os = list(g.objects(s, SKOS.narrower))
        related_os = list(g.objects(s, SKOS.related))
        rmatch_os = list(g.objects(s, SKOS.relatedMatch))

        overall["broader"] += len(broader_os)
        overall["narrower"] += len(narrower_os)
        overall["related"] += len(related_os)
        overall["relatedMatch_triples"] += len(rmatch_os)
        for o in rmatch_os:
            if isinstance(o, URIRef) and "wikidata" in str(o):
                overall["wikidata_relatedMatch_objects"].add(str(o))

        if grp in groups:
            groups[grp]["concepts"] += 1
            groups[grp]["broader"] += len(broader_os)
            groups[grp]["narrower"] += len(narrower_os)
            groups[grp]["related"] += len(related_os)
            groups[grp]["relatedMatch_triples"] += len(rmatch_os)
            for o in rmatch_os:
                if isinstance(o, URIRef) and "wikidata" in str(o):
                    groups[grp]["wikidata_relatedMatch_objects"].add(str(o))

    # Print
    print("\n=== vocabs.ttl – SKOS-Übersicht ===")
    print(f"Anzahl SKOS-Konzepte insgesamt: {total_concepts}\n")

    print("Insgesamt (über alle Gruppen):")
    print(f"  skos:broader         : {overall['broader']}")
    print(f"  skos:narrower        : {overall['narrower']}")
    print(f"  skos:related         : {overall['related']}")
    print(f"  skos:relatedMatch    : {overall['relatedMatch_triples']}")
    print(f"  Distinct Wikidata-Objekte via skos:relatedMatch: {len(overall['wikidata_relatedMatch_objects'])}\n")

    print("Pro Gruppe:")
    for key in GROUP_KEYS:
        info = groups[key]
        print(f"- {key}:")
        print(f"    Konzepte                         : {info['concepts']}")
        print(f"    skos:broader                     : {info['broader']}")
        print(f"    skos:narrower                    : {info['narrower']}")
        print(f"    skos:related                     : {info['related']}")
        print(f"    skos:relatedMatch                : {info['relatedMatch_triples']}")
        print(f"    Distinct Wikidata-Objekte (rMatch): {len(info['wikidata_relatedMatch_objects'])}")
    print()

# Main

def main():
    # Count Triples
    total = 0
    print("=== Tripel-Zählung ===")
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
    print(f"\nGesamtanzahl der Tripel (oben gelistete Dateien): {total}")

    # Analyze Vocabs
    if vocabs_path.exists():
        try:
            analyze_vocabs(vocabs_path)
        except Exception as e:
            print(f"❌ Fehler bei der SKOS-Auswertung von {vocabs_path}: {e}")
    else:
        print(f"⚠️ Datei nicht gefunden (SKOS-Auswertung übersprungen): {vocabs_path}")

if __name__ == "__main__":
    main()
