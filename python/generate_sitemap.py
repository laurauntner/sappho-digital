"""Generates sitemap.xml by scanning the built HTML pages in the target directory.

Mirrors the DE/EN slug mapping and the opaque-id "-en" suffix convention defined
in xslt/partials/params.xsl (i18n:href / i18n:switch-href), so every page ends up
with a self-referencing hreflang alternate plus a link to its counterpart page.
"""
import os
import sys
from datetime import date, datetime

BASE_URL = "https://sappho-digital.com"

# mirrors i18n:en-page-slugs in xslt/partials/params.xsl
SLUG_MAP_DE_TO_EN = {
    "index.html": "home.html",
    "projekt.html": "project.html",
    "orientierung.html": "guidance.html",
    "analyse.html": "analysis.html",
    "publikationen.html": "publications.html",
    "bibliographie.html": "bibliography.html",
    "texte.html": "texts.html",
    "404.html": "not-found.html",
    "imprint.html": "legal-notice.html",
    "toc-alle.html": "toc-all.html",
    "toc-drama.html": "toc-plays.html",
    "toc-lyrik.html": "toc-poetry.html",
    "toc-prosa.html": "toc-prose.html",
    "toc-sonstige.html": "toc-other.html",
    "alignments.html": "ontology-alignments.html",
    "netzwerk.html": "network.html",
    "statistik.html": "statistics.html",
    "vokabular.html": "vocabulary.html",
    "intertexte.html": "intertexts.html",
    "personen.html": "persons.html",
    "orte.html": "places.html",
    "werke.html": "works.html",
    "topoi.html": "rhetorical-topoi.html",
    "motive.html": "motifs.html",
    "themen.html": "topics.html",
    "stoffe.html": "plots.html",
    "query.html": "query-builder.html",
}
SLUG_MAP_EN_TO_DE = {v: k for k, v in SLUG_MAP_DE_TO_EN.items()}

# mirrors i18n:lang-independent-pages in xslt/partials/params.xsl
LANG_INDEPENDENT_PAGES = {"ontology.html"}


def counterpart(filename: str) -> str | None:
    if filename in LANG_INDEPENDENT_PAGES:
        return None
    if filename in SLUG_MAP_DE_TO_EN:
        return SLUG_MAP_DE_TO_EN[filename]
    if filename in SLUG_MAP_EN_TO_DE:
        return SLUG_MAP_EN_TO_DE[filename]
    if filename.endswith("-en.html"):
        return filename[: -len("-en.html")] + ".html"
    return filename[: -len(".html")] + "-en.html"


def lang_of(filename: str) -> str:
    if filename in LANG_INDEPENDENT_PAGES:
        return "de"
    if filename in SLUG_MAP_EN_TO_DE or filename.endswith("-en.html"):
        return "en"
    return "de"


def main(html_dir: str, out_path: str) -> None:
    files = sorted(f for f in os.listdir(html_dir) if f.endswith(".html") and not f.startswith("_"))
    existing = set(files)

    entries = []
    for f in files:
        mtime = os.path.getmtime(os.path.join(html_dir, f))
        lastmod = date.fromtimestamp(mtime).isoformat()
        cp = counterpart(f)
        alt = cp if (cp and cp in existing) else None
        entries.append((f, lastmod, lang_of(f), alt))

    lines = []
    lines.append('<?xml version="1.0" encoding="UTF-8"?>')
    lines.append(
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" '
        'xmlns:xhtml="http://www.w3.org/1999/xhtml">'
    )
    for f, lastmod, lang, alt in entries:
        lines.append("  <url>")
        lines.append(f"    <loc>{BASE_URL}/{f}</loc>")
        lines.append(f"    <lastmod>{lastmod}</lastmod>")
        if alt:
            self_href = f"{BASE_URL}/{f}"
            alt_href = f"{BASE_URL}/{alt}"
            de_href, en_href = (self_href, alt_href) if lang == "de" else (alt_href, self_href)
            lines.append(f'    <xhtml:link rel="alternate" hreflang="de" href="{de_href}"/>')
            lines.append(f'    <xhtml:link rel="alternate" hreflang="en" href="{en_href}"/>')
            lines.append(f'    <xhtml:link rel="alternate" hreflang="x-default" href="{de_href}"/>')
        lines.append("  </url>")
    lines.append("</urlset>")

    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")

    print(f"sitemap.xml: {len(entries)} URLs -> {out_path}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: generate_sitemap.py <html_dir> <out_path>", file=sys.stderr)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
