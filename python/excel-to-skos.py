import hashlib
import os
import re
import sys
from typing import Dict, List, Tuple, Optional, Set, DefaultDict
from collections import defaultdict

import pandas as pd

# Pfade
BASE_DIR = os.path.dirname(__file__)
DATA_DIR_OUT = os.path.abspath(os.path.join(BASE_DIR, "..", "data"))
XLSX_PATH = os.path.abspath(os.path.join(
    BASE_DIR, "..", "..", "doktorat", "Diss", "Sappho-Rezeption", "vocab.xlsx"
))
TTL_PATH_OUT = os.path.join(DATA_DIR_OUT, "rdf/vocab.ttl")

RDF_DIR = os.path.join(DATA_DIR_OUT, "rdf")
FRAG_TTL = os.path.join(RDF_DIR, "fragments.ttl")
WORK_TTL = os.path.join(RDF_DIR, "works.ttl")

# Ressourcentypen
SHEET_KIND = {
    "Motive": "motif",
    "Orte": "place",
    "Personen": "person",
    "Phrasen": "phrase",
    "Stoffe": "plot",
    "Themen": "topic",
    "Werke": "work",
}

# Namespaces
TTL_PREFIX = """@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix wd:   <http://www.wikidata.org/entity/> .

"""

URI_BASE = "https://sappho-digital.com/voc"
SCHEME_URI = f"{URI_BASE}"

# Regex
CANON_PROP = {
    "skos:exactmatch":  "skos:exactMatch",
    "skos:closematch":  "skos:closeMatch",
    "skos:broadmatch":  "skos:broadMatch",
    "skos:narrowmatch": "skos:narrowMatch",
    "skos:relatedmatch":"skos:relatedMatch",
}
PROP_RE = r"(?:skos:(?:exactMatch|closeMatch|broadMatch|narrowMatch|relatedMatch))"
QID_ONLY_RE = r"(?:wd:)?(Q[1-9]\d*)"
MAP_TOKEN_RE = rf"(?:{PROP_RE}\s+{QID_ONLY_RE}|{QID_ONLY_RE})"
MAP_LIST_FULL_RE = rf"^\s*(?:{MAP_TOKEN_RE}\s*(?:[,;]\s*)?)+\s*$"

# Hilfsfunktionen
def slug_id(sheet: str, label: str) -> str:
    key = f"{sheet}::{label}".encode("utf-8")
    return hashlib.sha256(key).hexdigest()[:16]  # 16 hex chars

def is_qid_like(s: str) -> bool:
    return bool(re.fullmatch(rf"\s*{QID_ONLY_RE}\s*$", (s or "").strip()))

def is_mapping_only_cell(s: str) -> bool:
    return bool(re.fullmatch(MAP_LIST_FULL_RE, (s or "").strip()))

def cell_text(v) -> str:
    if v is None:
        return ""
    if isinstance(v, float) and pd.isna(v):
        return ""
    s = str(v).strip()
    return "" if s.lower() in {"nan", "none"} else s

def normalize_label(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip())

def parse_mapping_cell(cell: str) -> List[Tuple[str, str]]:
    out: List[Tuple[str, str]] = []
    if not cell:
        return out
    parts = [p.strip() for p in re.split(r"[;,]", cell) if p.strip()]
    current_prop: Optional[str] = None
    for part in parts:
        m = re.match(rf"^\s*({PROP_RE})\s+{QID_ONLY_RE}\s*$", part, flags=re.IGNORECASE)
        if m:
            prop_raw = m.group(1)
            prop = CANON_PROP.get(prop_raw.lower(), prop_raw)
            qid = re.search(QID_ONLY_RE, part, flags=re.IGNORECASE).group(1).upper()
            out.append((prop, qid))
            current_prop = prop  # ab hier erben nackte QIDs diese Property
            continue
        m2 = re.match(rf"^\s*{QID_ONLY_RE}\s*$", part, flags=re.IGNORECASE)
        if m2:
            qid = m2.group(1).upper()
            prop = current_prop if current_prop else "skos:exactMatch"
            out.append((prop, qid))
            continue
    return out

# bibl-Labels
def load_bibl_labels_de(ttl_path: str) -> Dict[str, Tuple[str, str]]:
    out: Dict[str, Tuple[str, str]] = {}
    if not os.path.exists(ttl_path):
        return out

    current_subject: Optional[str] = None
    current_block_lines: List[str] = []

    def flush_block(lines: List[str], subj: Optional[str]):
        if not subj or not lines:
            return
        m_id = re.search(r"(bibl_[A-Za-z0-9_]+)", subj)
        if not m_id:
            return
        bid = m_id.group(1)
        for ln in lines:
            m_lab = re.search(r'rdfs:label\s+"(.+?)"@de\s*[;.]', ln)
            if m_lab:
                label_de = m_lab.group(1)
                out[bid] = (subj, label_de)
                return

    with open(ttl_path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            if line.startswith("<") and ">" in line and current_subject is None:
                current_subject = line.split(">")[0][1:]
                current_block_lines = [line]
                if line.endswith("."):
                    flush_block(current_block_lines, current_subject)
                    current_subject = None
                    current_block_lines = []
                continue

            if current_subject is not None:
                current_block_lines.append(line)
                if line.endswith("."):
                    flush_block(current_block_lines, current_subject)
                    current_subject = None
                    current_block_lines = []
    return out

# Modell
class Concept:
    def __init__(self, uri: str, label: str, notation: str, sheet: str):
        self.uri = uri
        self.label = label
        self.notation = notation
        self.sheet = sheet
        self.broader: Set[str] = set()
        self.narrower: Set[str] = set()
        self.mappings: Set[Tuple[str, str]] = set()  # (prop, QID)

    def to_turtle(self) -> str:
        lines = [
            f"<{self.uri}> a skos:Concept ;",
            f'    skos:prefLabel "{self.label}"@de ;',
            f'    skos:notation "{self.notation}" ;',
            f"    skos:inScheme <{SCHEME_URI}> ;"
        ]

        def write_prop(prop: str, values: List[str]):
            if not values:
                return
            if len(values) == 1:
                lines.append(f"    {prop} {values[0]} ;")
            else:
                first, rest = values[0], values[1:]
                lines.append(f"    {prop} {first},")
                for val in rest[:-1]:
                    lines.append(f"        {val},")
                lines.append(f"        {rest[-1]} ;")

        write_prop("skos:broader", [f"<{b}>" for b in sorted(self.broader)])
        write_prop("skos:narrower", [f"<{n}>" for n in sorted(self.narrower)])

        propmap: Dict[str, List[str]] = defaultdict(list)
        for prop, qid in sorted(self.mappings):
            propmap[prop].append(f"wd:{qid}")
        for prop, vals in propmap.items():
            write_prop(prop, vals)

        if lines[-1].endswith(";"):
            lines[-1] = lines[-1][:-1] + "."
        else:
            lines.append(".")

        return "\n".join(lines) + "\n\n"

# Verarbeitung
def process_sheet(df: pd.DataFrame, sheet: str, kind: str,
                  concepts: Dict[Tuple[str, str], Concept],
                  bibl_labels_de: Dict[str, Tuple[str, str]]) -> None:
    df = df.fillna("")
    n_rows, n_cols = df.shape

    def get_concept(label: str) -> Concept:
        key = (sheet, label)
        if key not in concepts:
            cid = slug_id(sheet, label)
            uri = f"{URI_BASE}/{kind}_{cid}"
            concepts[key] = Concept(uri=uri, label=label, notation=f"{kind}_{cid}", sheet=sheet)
        return concepts[key]

    last_label_in_col: Dict[int, Optional[str]] = {c: None for c in range(n_cols)}

    for r in range(n_rows):
        labels_positions: List[int] = []
        labels_at_col: Dict[int, str] = {}

        for c in range(n_cols):
            raw = cell_text(df.iat[r, c])
            if not raw:
                continue
            if is_mapping_only_cell(raw) or is_qid_like(raw) or raw.lower().startswith("skos:"):
                continue
            labels_positions.append(c)
            labels_at_col[c] = normalize_label(raw)

        for c in labels_positions:
            label = labels_at_col[c]
            node = get_concept(label)

            for lc in range(c - 1, -1, -1):
                parent_label = last_label_in_col.get(lc)
                if parent_label:
                    parent_node = get_concept(parent_label)
                    node.broader.add(parent_node.uri)
                    parent_node.narrower.add(node.uri)
                    break

            for prop, qid in parse_mapping_cell(cell_text(df.iat[r, c])):
                node.mappings.add((prop, qid))

            cc = c + 1
            while cc < n_cols:
                val = cell_text(df.iat[r, cc])
                if not val:
                    cc += 1
                    continue
                if is_mapping_only_cell(val):
                    for prop, qid in parse_mapping_cell(val):
                        node.mappings.add((prop, qid))
                    cc += 1
                    continue
                break

            last_label_in_col[c] = label
            for k in range(c + 1, n_cols):
                last_label_in_col[k] = None

            if sheet == "Werke" and label.startswith("bibl_"):
                entry = bibl_labels_de.get(label)
                if entry:
                    _uri, lab_de = entry
                    node.label = lab_de  # ersetze prefLabel mit deutschem TTL-Label

# Prozessieren
def main():
    if not os.path.exists(XLSX_PATH):
        print(f"XLSX nicht gefunden: {XLSX_PATH}", file=sys.stderr)
        sys.exit(1)

    bibl_labels_de: Dict[str, Tuple[str, str]] = {}
    for src in (FRAG_TTL, WORK_TTL):
        part = load_bibl_labels_de(src)
        bibl_labels_de.update(part)

    xls = pd.ExcelFile(XLSX_PATH)
    concepts: Dict[Tuple[str, str], Concept] = {}

    for sheet in xls.sheet_names:
        kind = SHEET_KIND.get(sheet)
        if not kind:
            continue
        df = pd.read_excel(XLSX_PATH, sheet_name=sheet, header=0)
        process_sheet(df, sheet, kind, concepts, bibl_labels_de)

    members_by_sheet: DefaultDict[str, List[str]] = defaultdict(list)
    for (_, _), concept in concepts.items():
        members_by_sheet[concept.sheet].append(concept.uri)

    os.makedirs(os.path.dirname(TTL_PATH_OUT), exist_ok=True)
    with open(TTL_PATH_OUT, "w", encoding="utf-8") as f:
        f.write(TTL_PREFIX)

        f.write(f"<{SCHEME_URI}> a skos:ConceptScheme ;\n")
        f.write('    skos:prefLabel "Vokabular zur literarischen Sappho-Rezeption"@de .\n\n')

        # Collections
        for sheet, kind in SHEET_KIND.items():
            uricol = f"{URI_BASE}/collection_{kind}"
            label = {
                "motif":"Motive",
                "place":"Orte",
                "person":"Personen",
                "phrase":"Phrasen",
                "plot":"Stoffe",
                "topic":"Themen",
                "work":"Werke",
            }[kind]
            f.write(f"<{uricol}> a skos:Collection ;\n")
            f.write(f'    skos:prefLabel "{label}"@de ;\n')
            members = members_by_sheet.get(sheet, [])
            for m in members[:-1]:
                f.write(f"    skos:member <{m}> ;\n")
            if members:
                f.write(f"    skos:member <{members[-1]}> .\n\n")
            else:
                f.write("    .\n\n")

        # Konzepte
        for (_, _), concept in sorted(concepts.items(), key=lambda kv: (kv[0][0], kv[1].label.lower())):
            f.write(concept.to_turtle())

    print(f"OK: {len(concepts)} Konzepte nach {TTL_PATH_OUT} geschrieben.")

if __name__ == "__main__":
    main()