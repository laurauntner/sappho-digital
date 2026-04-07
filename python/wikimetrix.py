# This script is based on the project 1001 Books You Must Read Before You Die 
# by Jonas Rohe, Viktor J. Illmer, Lisa Poggel and Frank Fischer
# https://github.com/temporal-communities/1001-books

from pathlib import Path
import io
import time
import shutil
import urllib.request

import polars as pl
import requests
from scipy import stats
from numpy.polynomial import Polynomial
from sklearn.metrics import r2_score

# =========================
# CONFIG
# =========================
INPUT_XLSX = Path("../../doktorat/Diss/Sappho-Rezeption/Sappho-Rez_vollstaendig.xlsx")
OUTPUT_FILE = Path("../data/wikimetrix.csv")
OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

AUTHOR_NAME_COL = "Autor_in"
AUTHOR_INTERNAL_ID_COL = "Interne Autor_in-ID"
AUTHOR_QID_COLNAME = "Autor_in QID"
AUTHOR_QID_COL_INDEX = 12  # M

BATCH_SIZE = 20
REQUEST_SLEEP = 5.0
REQUEST_TIMEOUT = 120
MAX_RETRIES = 6

USER_AGENT = "wikimetrix/0.1 (contact: deine-mail@example.com)"

QRANK_URL = "https://qrank.wmcloud.org/download/qrank.csv.gz"
QRANK_PATH = Path("inputs/qrank.csv.gz")
QRANK_PATH.parent.mkdir(parents=True, exist_ok=True)


# =========================
# WDQS HELPERS
# =========================
def format_query(query: str, qids: list[str]) -> str:
    formatted_qids = " ".join(f"wd:{qid}" for qid in qids)
    return query % formatted_qids


def query_wdqs(query: str, qids: list[str], max_retries: int = MAX_RETRIES) -> pl.DataFrame:
    if not qids:
        return pl.DataFrame()

    url = "https://query.wikidata.org/sparql"
    formatted_query = format_query(query, qids)

    for attempt in range(1, max_retries + 1):
        try:
            res = requests.post(
                url,
                data={"query": formatted_query},
                headers={
                    "Accept": "text/tab-separated-values",
                    "User-Agent": USER_AGENT,
                },
                timeout=REQUEST_TIMEOUT,
            )
            res.raise_for_status()
            print(f"Request took {res.elapsed.total_seconds():.3f} seconds.")

            text = res.text.strip()
            if not text:
                return pl.DataFrame()

            if "Please set a user-agent" in text:
                raise RuntimeError(
                    "WDQS rejected the request because no valid User-Agent was accepted."
                )

            df = pl.read_csv(io.BytesIO(res.content), separator="\t")

            if df.width == 0:
                return pl.DataFrame()

            return (
                df.rename(lambda s: s.strip("?"))
                .with_columns(pl.all().cast(pl.Utf8, strict=False))
                .with_columns(
                    pl.all()
                    .str.strip_chars("<>")
                    .str.strip_prefix("http://www.wikidata.org/entity/")
                )
            )

        except (requests.exceptions.RequestException, RuntimeError) as e:
            if attempt == max_retries:
                raise RuntimeError(
                    f"WDQS request failed after {max_retries} attempts: {e}"
                ) from e

            wait_seconds = REQUEST_SLEEP * (2 ** (attempt - 1))
            print(
                f"⚠️ Versuch {attempt}/{max_retries} fehlgeschlagen: {e}\n"
                f"   Warte {wait_seconds:.1f} Sekunden und versuche es erneut..."
            )
            time.sleep(wait_seconds)

    return pl.DataFrame()


def query_in_batches(query: str, qids: list[str]) -> pl.DataFrame:
    if not qids:
        return pl.DataFrame()

    results = []

    for i in range(0, len(qids), BATCH_SIZE):
        batch = qids[i:i + BATCH_SIZE]
        print(f"Batch {i}–{i + len(batch)} / {len(qids)}")
        df = query_wdqs(query, batch)
        if df.height > 0:
            results.append(df)
        time.sleep(REQUEST_SLEEP)

    if not results:
        return pl.DataFrame()

    return pl.concat(results, how="vertical_relaxed")


# =========================
# HELPERS
# =========================
def clean_qid_value(value: str | None) -> str | None:
    if value is None:
        return None
    value = str(value).strip()
    if not value:
        return None
    value = value.replace("http://www.wikidata.org/entity/", "")
    value = value.replace("https://www.wikidata.org/entity/", "")
    if value.startswith("wd:"):
        value = value[3:]
    value = value.upper()
    return value


def split_csv_field(value: str | None) -> list[str]:
    if value is None:
        return []
    value = str(value).strip()
    if not value:
        return []
    return [part.strip() for part in value.split(",") if part.strip()]


def split_author_names(value: str | None) -> list[str]:
    if value is None:
        return []
    value = str(value).strip()
    if not value:
        return []

    if " und " in value:
        parts = [part.strip() for part in value.split(" und ") if part.strip()]
        if len(parts) > 1:
            return parts

    return [value]


def resolve_author_qid_column(df: pl.DataFrame) -> str:
    columns = df.columns
    print("Gefundene Spalten:")
    for i, col in enumerate(columns):
        print(f"  {i}: {col}")

    if AUTHOR_QID_COLNAME in columns:
        print(f"\nVerwende Spaltennamen: '{AUTHOR_QID_COLNAME}'")
        return AUTHOR_QID_COLNAME

    print(
        f"\nSpaltenname nicht gefunden, verwende Fallback auf "
        f"Spaltenposition M ({AUTHOR_QID_COL_INDEX})."
    )

    if AUTHOR_QID_COL_INDEX >= len(columns):
        raise IndexError(
            "Die erwartete Spaltenposition M existiert in der Excel-Datei nicht."
        )

    return columns[AUTHOR_QID_COL_INDEX]


def expand_author_rows(
    df: pl.DataFrame,
    author_name_col: str,
    author_internal_id_col: str,
    author_qid_col: str,
) -> tuple[pl.DataFrame, list[dict]]:
    rows = []
    mismatches = []

    for row in df.iter_rows(named=True):
        names = split_author_names(row.get(author_name_col))
        internal_ids = split_csv_field(row.get(author_internal_id_col))
        qids_raw = split_csv_field(row.get(author_qid_col))
        qids = [clean_qid_value(q) for q in qids_raw if clean_qid_value(q)]

        lengths = {
            "names": len(names),
            "internal_ids": len(internal_ids),
            "qids": len(qids),
        }

        non_zero_lengths = sorted({v for v in lengths.values() if v > 0})

        if not non_zero_lengths:
            continue

        if len(non_zero_lengths) != 1:
            mismatches.append({
                "Autor_in": row.get(author_name_col),
                "Interne Autor_in-ID": row.get(author_internal_id_col),
                "Autor_in QID": row.get(author_qid_col),
                "lengths": lengths,
            })
            continue

        n = non_zero_lengths[0]

        if len(names) != n or len(internal_ids) != n or len(qids) != n:
            mismatches.append({
                "Autor_in": row.get(author_name_col),
                "Interne Autor_in-ID": row.get(author_internal_id_col),
                "Autor_in QID": row.get(author_qid_col),
                "lengths": lengths,
            })
            continue

        for name, internal_id, qid in zip(names, internal_ids, qids):
            if qid and qid.startswith("Q") and qid[1:].isdigit():
                rows.append({
                    "Autor_in": name,
                    "Interne Autor_in-ID": internal_id,
                    "Author Wikidata ID": qid,
                })

    expanded_df = pl.DataFrame(rows) if rows else pl.DataFrame(
        schema={
            "Autor_in": pl.Utf8,
            "Interne Autor_in-ID": pl.Utf8,
            "Author Wikidata ID": pl.Utf8,
        }
    )

    return expanded_df, mismatches


# =========================
# LOAD EXCEL
# =========================
print("Loading Excel...")

df = pl.read_excel(INPUT_XLSX)

if df.height == 0:
    raise ValueError("Die Excel-Datei wurde gelesen, enthält aber keine Zeilen.")

author_qid_col = resolve_author_qid_column(df)

required_cols = [AUTHOR_NAME_COL, AUTHOR_INTERNAL_ID_COL, author_qid_col]
missing_required = [c for c in required_cols if c not in df.columns]
if missing_required:
    raise ValueError(f"Fehlende erwartete Spalten: {missing_required}")

base_df, mismatches = expand_author_rows(
    df=df,
    author_name_col=AUTHOR_NAME_COL,
    author_internal_id_col=AUTHOR_INTERNAL_ID_COL,
    author_qid_col=author_qid_col,
)

if base_df.height == 0:
    raise ValueError("Nach der Bereinigung blieben keine gültigen Autor_innen-QIDs übrig.")

print(f"\nExpandierte Autor_innen-Zeilen: {base_df.height}")
print(f"Nicht verarbeitete Mehrfach-Fälle: {len(mismatches)}")

if mismatches:
    print("\nBeispiele für nicht sauber zuordenbare Zeilen:")
    for example in mismatches[:5]:
        print(example)

author_qids = (
    base_df
    .get_column("Author Wikidata ID")
    .unique()
    .sort()
    .to_list()
)

print(f"Unique Author QIDs found for WDQS: {len(author_qids)}")


# =========================
# AUTHOR SITELINKS
# =========================
print("\nFetching author sitelinks...")

sitelinks_query = """
SELECT DISTINCT ?qid ?sitelink WHERE {
    VALUES ?qid {
        %s
    }

    OPTIONAL {
        ?sitelink schema:about ?qid .
    }

    FILTER(CONTAINS(STR(?sitelink), ".wikipedia.org/"))
}
"""

author_sitelinks = query_in_batches(sitelinks_query, author_qids)

if author_sitelinks.height == 0:
    print("Warnung: Keine Sitelinks gefunden.")
    author_sitelinks_agg = pl.DataFrame(
        {"Author Wikidata ID": [], "Author Sitelinks": []},
        schema={"Author Wikidata ID": pl.Utf8, "Author Sitelinks": pl.UInt32},
    )
else:
    expected_cols = {"qid", "sitelink"}
    missing = expected_cols - set(author_sitelinks.columns)
    if missing:
        raise ValueError(
            f"Die WDQS-Antwort enthält nicht die erwarteten Spalten. "
            f"Fehlend: {missing}. Vorhanden: {author_sitelinks.columns}"
        )

    author_sitelinks = author_sitelinks.drop_nulls("sitelink")

    author_sitelinks_agg = (
        author_sitelinks.group_by("qid")
        .agg(pl.len().alias("Author Sitelinks"))
        .rename({"qid": "Author Wikidata ID"})
        .sort("Author Sitelinks", descending=True)
    )


# =========================
# BUILD OUTPUT DATAFRAME
# =========================
print("\nBuilding output dataframe...")

work_count_df = (
    base_df
    .group_by(["Interne Autor_in-ID", "Author Wikidata ID"])
    .agg(pl.len().alias("Work Count"))
)

def count_special_chars(name: str) -> int:
    """Count non-alphanumeric, non-space, non-hyphen characters in a name."""
    return sum(1 for c in name if not (c.isalnum() or c in (" ", "-", ".")))

name_candidates = (
    base_df
    .select(["Autor_in", "Interne Autor_in-ID", "Author Wikidata ID"])
    .unique()
)

best_names = (
    name_candidates
    .with_columns(
        pl.col("Autor_in")
        .map_elements(count_special_chars, return_dtype=pl.Int32)
        .alias("_special"),
        pl.col("Autor_in")
        .map_elements(len, return_dtype=pl.Int32)
        .alias("_len"),
    )
    .sort(["Interne Autor_in-ID", "Author Wikidata ID", "_special", "_len"])
    .unique(["Interne Autor_in-ID", "Author Wikidata ID"], keep="first")
    .drop(["_special", "_len"])
)

distinct_authors_df = best_names

out_df = (
    distinct_authors_df
    .join(
        work_count_df,
        on=["Interne Autor_in-ID", "Author Wikidata ID"],
        how="left",
    )
    .join(
        author_sitelinks_agg,
        on="Author Wikidata ID",
        how="left",
    )
    .with_columns(
        pl.col("Author Sitelinks").fill_null(0)
    )
)


# =========================
# QRANK
# =========================
if not QRANK_PATH.exists():
    print("\nDownloading QRank dataset (this may take a while)...")
    urllib.request.urlretrieve(QRANK_URL, QRANK_PATH)
    print("Download finished.")

print("\nJoining QRank...")
qrank = pl.read_csv(QRANK_PATH)

out_df = (
    out_df
    .join(
        qrank.select(["Entity", "QRank"]),
        left_on="Author Wikidata ID",
        right_on="Entity",
        how="left",
        coalesce=True,
    )
    .rename({"QRank": "Author QRank"})
)

out_df = out_df.select([
    "Autor_in",
    "Interne Autor_in-ID",
    "Author Wikidata ID",
    "Author Sitelinks",
    "Author QRank",
    "Work Count",
])


# =========================
# SAVE
# =========================
print(f"\nSaving output to: {OUTPUT_FILE}")
out_df.write_csv(OUTPUT_FILE)


# =========================
# OPTIONAL STATISTICS
# =========================
print("\nStatistics:\n")

subset = (
    out_df
    .select(["Author Wikidata ID", "Author QRank", "Author Sitelinks"])
    .drop_nulls(["Author Wikidata ID", "Author QRank", "Author Sitelinks"])
    .unique("Author Wikidata ID")
)

if subset.height < 3:
    print("Author: skipped (not enough data)")
else:
    x = subset.get_column("Author Sitelinks").cast(pl.Float64).to_numpy()
    y = subset.get_column("Author QRank").cast(pl.Float64).to_numpy()

    print("Author: Spearman correlation")
    print(stats.spearmanr(y, x))
    print()

    try:
        model = Polynomial.fit(x, y, 2)
        r2 = r2_score(y, model(x))
        print(f"Author QRank = {model}")
        print(f"R² = {r2}")
        print()
    except Exception as e:
        print(f"Author: regression skipped ({e})")
        print()

print("Done.")


# =========================
# CLEANUP
# =========================
try:
    if QRANK_PATH.parent.exists():
        print("\nDeleting inputs folder...")
        shutil.rmtree(QRANK_PATH.parent)
except Exception as e:
    print(f"⚠️ Cleanup failed: {e}")