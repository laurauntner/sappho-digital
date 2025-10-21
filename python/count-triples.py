from rdflib import Graph
from pathlib import Path

# Path
data_dir = Path("../data/rdf")

# File names
files = [
    "authors",
    "works",
    "fragments",
    "analysis",
    "relations",
    "sappho-reception",
    "vocab"
]

def count_triples(file_path: Path) -> int:
    g = Graph()
    g.parse(file_path, format="turtle")
    return len(g)

def main():
    total = 0
    for name in files:
        ttl_path = data_dir / f"{name}.ttl"
        if ttl_path.exists():
            n = count_triples(ttl_path)
            total += n
            print(f"{name}.ttl: {n} Tripel")
        else:
            print(f"⚠️ Datei nicht gefunden: {ttl_path}")
    print(f"\nGesamtanzahl der Tripel: {total}")

if __name__ == "__main__":
    main()
