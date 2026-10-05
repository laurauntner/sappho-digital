"""Exportiert einen Auszug der Rezeptionszeugnisse als kompakte Liste (DOCX)."""

from __future__ import annotations

import argparse
import logging
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable, Iterator

from lxml import etree

TEI = "{http://www.tei-c.org/ns/1.0}"
NS = {"t": TEI[1:-1]}

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = ROOT / "data" / "lists" / "sappho-rez_alle.xml"
OUTPUT = ROOT / "data" / "auszug_rezeptionszeugnisse.docx"

FIELDS = ("year", "author", "title", "container", "place", "genre")
DEFAULT_FIELDS = FIELDS
CENTURY_UNKNOWN = "Ohne Datierung"

log = logging.getLogger("reception-list")


@dataclass(frozen=True)
class Entry:
    id: str
    title: str
    authors: tuple[str, ...]
    genre: str
    year_label: str
    sort_year: int | None
    container: str
    place: str

    @property
    def author_label(self) -> str:
        return " / ".join(self.authors) if self.authors else "o. A."

    @property
    def century(self) -> int | None:
        return (self.sort_year - 1) // 100 + 1 if self.sort_year else None


def _text(el: etree._Element | None) -> str:
    return re.sub(r"\s+", " ", "".join(el.itertext())).strip() if el is not None else ""


def _year(date: etree._Element) -> int | None:
    for attr in ("when", "notBefore", "notAfter"):
        match = re.match(r"-?\d{3,4}", date.get(attr, ""))
        if match:
            return int(match.group())
    match = re.search(r"\d{4}", _text(date))
    return int(match.group()) if match else None


DATE_ABBREVIATIONS = {"published": "P", "created": "E"}

LEGEND = (
    "Hinweis: (E) = Entstehungsdatum, (P) = Publikationsdatum. "
    "Einsortiert ist nach dem frühesten bekannten Jahr. "
    "Die Angaben sind nicht bei jedem Eintrag vollständig."
)


def _pick_date(bibl: etree._Element) -> tuple[str, int | None]:
    """Beschriftet alle Datierungen mit ihrer Art, früheste zuerst; das früheste Jahr dient zum Sortieren."""
    dated = []
    for date in bibl.findall("t:date", NS):
        kind = date.get("type")
        year = _year(date)
        if kind in DATE_ABBREVIATIONS and year is not None:
            dated.append((year, kind != "published", _text(date), DATE_ABBREVIATIONS[kind]))
    if not dated:
        return "", None
    labels: dict[str, list[str]] = {}
    for _, _, text, abbreviation in sorted(dated):
        labels.setdefault(text, []).append(abbreviation)
    label = ", ".join(f"{text} ({'/'.join(kinds)})" for text, kinds in labels.items())
    return label, min(dated)[0]


def parse_entries(path: Path) -> list[Entry]:
    # xml:ids von Sammelwerken kommen mehrfach vor, daher tolerantes Parsen
    parser = etree.XMLParser(recover=True, remove_blank_text=True)
    tree = etree.parse(str(path), parser)
    entries = []
    for bibl in tree.iterfind(".//t:listBibl/t:bibl", NS):
        year_label, sort_year = _pick_date(bibl)
        entries.append(
            Entry(
                id=bibl.get("{http://www.w3.org/XML/1998/namespace}id", ""),
                title=_text(bibl.find("t:title", NS)),
                authors=tuple(a for a in (_text(e) for e in bibl.findall("t:author", NS)) if a),
                genre=_text(bibl.find("t:note[@type='genre']", NS)),
                year_label=year_label,
                sort_year=sort_year,
                container=_text(bibl.find("t:bibl/t:title", NS)),
                place=_text(bibl.find("t:pubPlace", NS)),
            )
        )
    log.info("%d Einträge gelesen aus %s", len(entries), path.name)
    return entries


def _norm(value: str) -> str:
    return value.casefold().strip()


def select(
    entries: Iterable[Entry],
    genres: list[str],
    authors: list[str],
    year_from: int | None,
    year_to: int | None,
    sample: int | None,
) -> list[Entry]:
    wanted_genres = {_norm(g) for g in genres}
    wanted_authors = [_norm(a) for a in authors]

    def keep(e: Entry) -> bool:
        if wanted_genres and _norm(e.genre.rstrip("?")) not in wanted_genres:
            return False
        if wanted_authors and not any(a in _norm(e.author_label) for a in wanted_authors):
            return False
        if year_from is not None or year_to is not None:
            if e.sort_year is None:
                return False
            if year_from is not None and e.sort_year < year_from:
                return False
            if year_to is not None and e.sort_year > year_to:
                return False
        return True

    chosen = sorted(
        (e for e in entries if keep(e)),
        key=lambda e: (e.sort_year is None, e.sort_year or 0, _norm(e.author_label), _norm(e.title)),
    )
    if sample and sample < len(chosen):
        chosen = _evenly_spaced(chosen, sample)
    return chosen


def _evenly_spaced(items: list[Entry], n: int) -> list[Entry]:
    """Deterministische Stichprobe, die die chronologische Verteilung beibehält."""
    step = len(items) / n
    return [items[int(i * step + step / 2)] for i in range(n)]


def _sentence(text: str) -> str:
    return text if text.endswith((".", "!", "?")) else f"{text}."


def entry_text(e: Entry, fields: tuple[str, ...]) -> str:
    """Baut die Eintragszeile aus den gewählten Feldern."""
    parts: list[str] = []
    add = parts.append

    if "year" in fields and e.year_label:
        add(f"{e.year_label}\u2002")
    if "author" in fields:
        add(e.author_label + (": " if "title" in fields else ". "))
    if "title" in fields:
        add(_sentence(e.title) + " " if e.title else "o. T. ")
    if "container" in fields and e.container:
        add(f"In: {_sentence(e.container)} ")
    if "place" in fields and e.place:
        add(_sentence(e.place) + " ")
    if "genre" in fields and e.genre:
        add(f"[{e.genre}]")
    return "".join(parts).rstrip()


def group_key(group_by: str) -> Callable[[Entry], str]:
    if group_by == "genre":
        return lambda e: e.genre or "Ohne Gattung"
    if group_by == "century":
        return lambda e: f"{e.century}. Jahrhundert" if e.century else CENTURY_UNKNOWN
    return lambda e: ""


def grouped(entries: list[Entry], group_by: str) -> Iterator[tuple[str, list[Entry]]]:
    key = group_key(group_by)
    groups: dict[str, list[Entry]] = {}
    for e in entries:
        groups.setdefault(key(e), []).append(e)
    yield from groups.items()


def write_docx(
    path: Path,
    entries: list[Entry],
    fields: tuple[str, ...],
    group_by: str,
    font: str,
    size: float,
    spacing: float,
) -> None:
    from docx import Document
    from docx.enum.style import WD_STYLE_TYPE
    from docx.oxml.ns import qn
    from docx.shared import Cm, Pt

    doc = Document()
    style = doc.styles.add_style("Rezeptionsliste", WD_STYLE_TYPE.PARAGRAPH)
    style.base_style = doc.styles["Normal"]
    style.font.name = font
    style.font.size = Pt(size)
    style.element.rPr.rFonts.set(qn("w:eastAsia"), font)
    fmt = style.paragraph_format
    fmt.left_indent = Cm(0.6)
    fmt.first_line_indent = Cm(-0.6)
    fmt.space_before = Pt(0)
    fmt.space_after = Pt(spacing)
    fmt.line_spacing = 1.0

    legend = doc.add_paragraph(LEGEND, style="Rezeptionsliste")
    legend.paragraph_format.left_indent = Cm(0)
    legend.paragraph_format.first_line_indent = Cm(0)
    legend.paragraph_format.space_after = Pt(spacing * 3)

    for heading, group in grouped(entries, group_by):
        if heading:
            p = doc.add_paragraph(style="Rezeptionsliste")
            p.paragraph_format.left_indent = Cm(0)
            p.paragraph_format.first_line_indent = Cm(0)
            p.paragraph_format.keep_with_next = True
            p.add_run(heading).bold = True
        for e in group:
            p = doc.add_paragraph(style="Rezeptionsliste")
            p.add_run(entry_text(e, fields))
    doc.save(path)


def _csv_list(value: str) -> list[str]:
    return [v.strip() for v in value.split(",") if v.strip()]


def _fields(value: str) -> tuple[str, ...]:
    chosen = tuple(_csv_list(value))
    unknown = set(chosen) - set(FIELDS)
    if unknown:
        raise argparse.ArgumentTypeError(
            f"Unbekannte Felder: {', '.join(sorted(unknown))}. Erlaubt: {', '.join(FIELDS)}"
        )
    return chosen


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("-i", "--input", type=Path, default=DEFAULT_INPUT, help="TEI-Liste (Standard: sappho-rez_alle.xml)")
    p.add_argument("--fields", type=_fields, default=DEFAULT_FIELDS, metavar="F1,F2,…", help=f"Felder in Ausgabereihenfolge-Logik; wählbar: {', '.join(FIELDS)}")
    p.add_argument("--genre", type=_csv_list, default=[], metavar="G1,G2", help="Nur diese Gattungen, z. B. Lyrik,Drama")
    p.add_argument("--author", type=_csv_list, default=[], metavar="A1,A2", help="Nur Autor:innen, deren Name den Text enthält")
    p.add_argument("--from", dest="year_from", type=int, help="frühestes Jahr")
    p.add_argument("--to", dest="year_to", type=int, help="spätestes Jahr")
    p.add_argument("--sample", type=int, metavar="N", help="N chronologisch gleichmäßig verteilte Einträge")
    p.add_argument("--group-by", choices=("none", "genre", "century"), default="none", help="Zwischenüberschriften")
    p.add_argument("--font", default="Times New Roman")
    p.add_argument("--size", type=float, default=9.0, help="Schriftgröße in pt")
    p.add_argument("--spacing", type=float, default=2.0, help="Abstand nach Eintrag in pt")
    return p


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    args = build_parser().parse_args(argv)

    if not args.input.is_file():
        log.error("Eingabedatei nicht gefunden: %s", args.input)
        return 1

    entries = select(
        parse_entries(args.input),
        genres=args.genre,
        authors=args.author,
        year_from=args.year_from,
        year_to=args.year_to,
        sample=args.sample,
    )
    if not entries:
        log.error("Keine Einträge entsprechen den Filtern.")
        return 1

    write_docx(OUTPUT, entries, args.fields, args.group_by, args.font, args.size, args.spacing)

    log.info("%d Einträge geschrieben nach %s", len(entries), OUTPUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
