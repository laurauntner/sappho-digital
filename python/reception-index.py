import csv
import math
import re
import sys
import argparse
from collections import defaultdict
from typing import Optional

from rdflib import Graph, Namespace, URIRef
from rdflib.namespace import RDF, RDFS

LRMOO = Namespace("http://iflastandards.info/ns/lrm/lrmoo/")
INTRO  = Namespace("https://w3id.org/lso/intro/currentbeta#")
ECRM   = Namespace("http://erlangen-crm.org/current/")

F2_Expression            = LRMOO.F2_Expression
R18_showsActualization   = INTRO.R18_showsActualization
R17_actualizesFeature    = INTRO.R17_actualizesFeature
R30_hasTextPassage       = INTRO["R30_hasTextPassage"]
R30i_isTextPassageOf     = INTRO["R30i_isTextPassageOf"]
P4_has_time_span         = ECRM["P4_has_time-span"]
P2_has_type              = ECRM.P2_has_type

INT31_IntertextualRelation = INTRO["INT31_IntertextualRelation"]
R24_hasRelatedEntity       = INTRO["R24_hasRelatedEntity"]

ALL_PHENOM_PATTERNS = [
    "/person_ref/",
    "/character/",
    "/place_ref/",
    "/topos/",
    "/motif/",
    "/topic/",
    "/plot/",
    "/work_ref/",
    "/text_passage/",
]

def is_phenomenon(uri: str) -> bool:
    return any(p in uri for p in ALL_PHENOM_PATTERNS)

def clean_label(s: str) -> str:
    s = re.sub(r'^Plot:\s*',      '', s)
    s = re.sub(r'^Motif:\s*',     '', s)
    s = re.sub(r'^Topic:\s*',     '', s)
    s = re.sub(r'^Character:\s*', '', s)
    s = re.sub(r'(?i)^[Rr]eference\s+to\s+', '', s)
    s = re.sub(r'(?i)^Passage\s+from\s+',    '', s)
    s = re.sub(r'(?i)^Expression\s+of\s+',   '', s)
    s = re.sub(r'\s*\([^)]+\)\s*$', '', s)
    return s.strip()

def get_label(g: Graph, uri: URIRef) -> str:
    en = de = any_label = None
    for _, _, label in g.triples((uri, RDFS.label, None)):
        lang = getattr(label, "language", None)
        if lang == "en":   en        = str(label)
        elif lang == "de": de        = str(label)
        else:              any_label = str(label)
    raw = de or en or any_label or str(uri).split("/")[-1]
    return clean_label(raw)

def compute_index(ttl_path: str,
                  csv_out: Optional[str],
                  w_p: float = 0.6,
                  w_i: float = 0.4,
                  use_log: bool = True) -> list[dict]:

    assert abs(w_p + w_i - 1.0) < 1e-9, "w_p + w_i muss 1.0 ergeben."

    print(f"Lese {ttl_path} …", file=sys.stderr)
    g = Graph()
    g.parse(ttl_path, format="turtle")
    print(f"  {len(g)} Tripel geladen.", file=sys.stderr)

    sappho_f2    : set[URIRef] = set()
    reception_f2 : set[URIRef] = set()

    for subj in g.subjects(RDF.type, F2_Expression):
        uri = str(subj)
        if "bibl_sappho_" in uri:
            sappho_f2.add(subj)
        elif "bibl_" in uri:
            reception_f2.add(subj)

    act_to_features: dict[URIRef, set[URIRef]] = defaultdict(set)
    for act, _, feat in g.triples((None, R17_actualizesFeature, None)):
        act_to_features[act].add(feat)

    def get_all_phenomena(f2_uri: URIRef) -> set[URIRef]:
        phenom: set[URIRef] = set()

        # Features via R18_showsActualization → R17_actualizesFeature
        for _, _, act in g.triples((f2_uri, R18_showsActualization, None)):
            for feat in act_to_features.get(act, set()):
                if is_phenomenon(str(feat)):
                    phenom.add(feat)

        # Text Passages
        for _, _, tp in g.triples((f2_uri, R30_hasTextPassage, None)):
            phenom.add(tp)
        for tp, _, _ in g.triples((None, R30i_isTextPassageOf, f2_uri)):
            phenom.add(tp)

        return phenom

    print("  Berechne Phänomene …", file=sys.stderr)
    f2_phenomena: dict[URIRef, set[URIRef]] = {}
    for f2 in reception_f2:
        phenom = get_all_phenomena(f2)
        if phenom:
            f2_phenomena[f2] = phenom

    reception_with_act: set[URIRef] = set(f2_phenomena.keys())
    print(f"  Texte mit Analysedaten: {len(reception_with_act)}", file=sys.stderr)

    # ── INT31-Knoten → beteiligte Texte ──────────────────────────────────────
    print("  Berechne INT31-Beziehungen …", file=sys.stderr)
    f2_to_int31: dict[URIRef, set[URIRef]] = defaultdict(set)

    all_int31: set[URIRef] = set(g.subjects(RDF.type, INT31_IntertextualRelation))

    for node_uri in all_int31:
        for _, _, obj in g.triples((node_uri, R24_hasRelatedEntity, None)):
            # Textpassagen-Knoten ausschließen
            if "/textpassage/" in str(obj).lower():
                continue
            if obj in (reception_with_act | sappho_f2):
                f2_to_int31[obj].add(node_uri)

    print(f"  INT31-Knoten gesamt: {len(all_int31)}", file=sys.stderr)

    p_raw: dict[URIRef, int] = {}
    i_raw: dict[URIRef, int] = {}

    for f2 in reception_with_act:
        p_raw[f2] = len(f2_phenomena[f2])
        i_raw[f2] = len(f2_to_int31.get(f2, set()))

    active = [f2 for f2 in reception_with_act if i_raw[f2] > 0]
    n_active = len(active)

    def median(values: list) -> float:
        s = sorted(values)
        n = len(s)
        if n == 0:
            return 1.0
        mid = n // 2
        return (s[mid] + s[mid - 1]) / 2 if n % 2 == 0 else float(s[mid])

    p_med = median([p_raw[f2] for f2 in active]) if active else 1.0
    i_med = median([i_raw[f2] for f2 in active]) if active else 1.0

    print(f"  Texte mit >=1 INT31-Beziehung:  {n_active}", file=sys.stderr)
    print(f"  Median Phaenomene (aktive Texte): {p_med:.2f}", file=sys.stderr)
    print(f"  Median INT31 (aktive Texte):      {i_med:.2f}", file=sys.stderr)

    # ── Normalisierung relativ zum Median ─────────────────────────────────────
    if use_log:
        log_p_ref = math.log1p(p_med)
        log_i_ref = math.log1p(i_med)
        def norm_p(v): return min(math.log1p(v) / (2 * log_p_ref), 1.0) if log_p_ref > 0 else 0.0
        def norm_i(v): return min(math.log1p(v) / (2 * log_i_ref), 1.0) if log_i_ref > 0 else 0.0
    else:
        def norm_p(v): return min(v / (2 * p_med), 1.0) if p_med > 0 else 0.0
        def norm_i(v): return min(v / (2 * i_med), 1.0) if i_med > 0 else 0.0

    # ── Index berechnen ───────────────────────────────────────────────────────
    results: list[dict] = []
    for f2 in reception_with_act:
        p_n = norm_p(p_raw[f2])
        i_n = norm_i(i_raw[f2])
        idx = w_p * p_n + w_i * i_n

        results.append({
            "uri":             str(f2),
            "label":           get_label(g, f2),
            "n_phenomena":     p_raw[f2],
            "n_int31":         i_raw[f2],
            "p_norm":          round(p_n,  4),
            "i_norm":          round(i_n,  4),
            "reception_index": round(idx,  4),
        })

    # Absteigend nach Index sortieren
    results.sort(key=lambda r: -r["reception_index"])

    # ── Ausgabe ───────────────────────────────────────────────────────────────
    if csv_out:
        fieldnames = ["uri", "label", "n_phenomena", "n_int31",
                      "p_norm", "i_norm", "reception_index"]
        with open(csv_out, "w", newline="", encoding="utf-8") as fh:
            writer = csv.DictWriter(fh, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(results)
        print(f"\nGeschrieben: {csv_out}  ({len(results)} Zeilen)", file=sys.stderr)

    return results


def print_skewness(results: list[dict]) -> None:
    """Gibt deskriptive Statistik und Pearson'sche Schiefe der Rohwerte aus.
    Dient zur Überprüfung der Annahme rechtsschiefer Verteilung vor der
    logarithmischen Transformation."""

    def _mean(vals):
        return sum(vals) / len(vals)

    def _median(vals):
        s = sorted(vals)
        n = len(s)
        mid = n // 2
        return (s[mid] + s[mid - 1]) / 2 if n % 2 == 0 else float(s[mid])

    def _stdev(vals):
        m = _mean(vals)
        variance = sum((v - m) ** 2 for v in vals) / (len(vals) - 1)
        return math.sqrt(variance)

    datasets = [
        ("Phänomene (roh, alle Texte)",     [r["n_phenomena"] for r in results]),
        ("INT31 (roh, Texte mit >=1 Bez.)", [r["n_int31"] for r in results if r["n_int31"] > 0]),
    ]

    print(f"\n{'─'*72}")
    print(f"  Verteilungsdiagnose Rohwerte (vor log-Transformation)")
    print(f"{'─'*72}")

    for name, vals in datasets:
        n = len(vals)
        if n < 2:
            print(f"  {name}: zu wenige Werte (n={n})")
            continue
        mean = _mean(vals)
        med  = _median(vals)
        sd   = _stdev(vals)
        # Pearson'sche Schiefe: 3 * (mean - median) / sd
        skew = 3 * (mean - med) / sd if sd > 0 else 0.0
        print(f"  {name}")
        print(f"    n={n}, min={min(vals)}, max={max(vals)}")
        print(f"    Mittelwert={mean:.2f}, Median={med:.2f}, SD={sd:.2f}")
        print(f"    Pearson-Schiefe ≈ {skew:.3f}  "
              f"({'rechtsschiefe' if skew > 0.5 else 'leicht rechtsschiefe' if skew > 0 else 'symmetrische'} Verteilung)")
        print()

    print(f"{'─'*72}\n")


def print_summary(results: list[dict], top_n: int = 20) -> None:
    print(f"\n{'─'*72}")
    print(f"  Rezeptionsindex – Zusammenfassung  ({len(results)} Texte)")
    print(f"{'─'*72}")
    print(f"  {'URI / Label':<45} {'Phän':>6} {'INT31':>6} {'Index':>7}")
    print(f"{'─'*72}")
    for r in results[:top_n]:
        short = r["label"][:44] if r["label"] else r["uri"].split("/")[-1][:44]
        print(f"  {short:<45} {r['n_phenomena']:>6} {r['n_int31']:>6} "
              f"  {r['reception_index']:.4f}")
    if len(results) > top_n:
        print(f"  … und {len(results) - top_n} weitere Texte.")
    print(f"{'─'*72}")

    indices = [r["reception_index"] for r in results]
    n       = len(indices)
    mean    = sum(indices) / n
    median  = sorted(indices)[n // 2]
    nonzero = sum(1 for v in indices if v > 0)
    print(f"\n  Texte gesamt:   {n}")
    print(f"  Texte > 0:      {nonzero}")
    print(f"  Mittelwert:     {mean:.4f}")
    print(f"  Median:         {median:.4f}")
    print(f"  Maximum:        {max(indices):.4f}")
    print(f"{'─'*72}\n")

    # Verteilungsdiagnose der Rohwerte
    print_skewness(results)


TTL_PATH = "../data/rdf/sappho-reception.ttl"
CSV_PATH = "../data/reception-indices.csv"

def main():
    parser = argparse.ArgumentParser(
        description="Berechnet den Rezeptionsindex für Sappho-Rezeptionszeugnisse."
    )
    parser.add_argument("--w_p", type=float, default=0.75,
        help="Gewicht für Phänomene (Standard: 0.75)")
    parser.add_argument("--w_i", type=float, default=0.25,
        help="Gewicht für INT31-Beziehungen (Standard: 0.25)")
    parser.add_argument("--no-log", action="store_true",
        help="Lineare statt log1p-Normalisierung verwenden")

    args = parser.parse_args()

    if abs(args.w_p + args.w_i - 1.0) > 1e-6:
        print("Fehler: --w_p und --w_i müssen zusammen 1.0 ergeben.", file=sys.stderr)
        sys.exit(1)

    results = compute_index(
        ttl_path = TTL_PATH,
        csv_out  = CSV_PATH,
        w_p      = args.w_p,
        w_i      = args.w_i,
        use_log  = not args.no_log,
    )

    print_summary(results, top_n=25)


if __name__ == "__main__":
    main()