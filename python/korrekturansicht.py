#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations
import html as htmllib
import re
from pathlib import Path
from collections import defaultdict
import hashlib

IN_DIR = Path("../../doktorat/Diss/Sappho-Rezeption/XML")
OUT_DIR = Path("../../doktorat/Diss/Sappho-Rezeption/HTML")

# Metadaten
META_TAGS = ("id", "status", "vorlageSeiten", "anthologieSeiten")

# Checkliste
HEADER_CHECKLIST = [
    "Analyse durchgegangen",
    'Personen: ggf. "character" bei @art + @appellation bei Sapphos hinzugefügt',
    'Werke: ggf. @art="passage" hinzugefügt',
    "XML-Datei korrigiert",
    'Status auf "korrigiert" gesetzt',
]


def esc(s: str) -> str:
    return htmllib.escape(s, quote=True)


def get_one_text(xml: str, tag: str) -> str:
    m = re.search(rf"<{tag}>(.*?)</{tag}>", xml, flags=re.DOTALL)
    return m.group(1) if m else ""

def extract_header_tags(xml: str) -> list[tuple[str, str, str]]:
    """
    Liefert alle Elemente zwischen </title> und <text> als Liste:
    (tagname, attrs_raw (inkl. führendem Leerzeichen oder ""), inner_xml)
    Reihenfolge bleibt exakt wie im XML.
    """
    m_title = re.search(r"<title>.*?</title>", xml, flags=re.DOTALL)
    m_text = re.search(r"<text>.*?</text>", xml, flags=re.DOTALL)
    if not m_title or not m_text or m_title.end() > m_text.start():
        return []

    header_block = xml[m_title.end():m_text.start()]

    # Nimmt "flache" Elemente: <tag ...>...</tag> (keine verschachtelten gleichnamigen Tags erwartet)
    el_re = re.compile(r"<(?P<tag>\w+)(?P<attrs>\s[^>]*)?>(?P<inner>.*?)</(?P=tag)>", re.DOTALL)

    out: list[tuple[str, str, str]] = []
    for m in el_re.finditer(header_block):
        out.append((m.group("tag"), m.group("attrs") or "", m.group("inner")))
    return out


def attrs_to_brackets(attrs_raw: str) -> str:
    """
    attrs_raw z.B. ' art="real" type="Kleis"' -> '(art=real; type=Kleis)'
    Wenn keine Attribute: ''.
    """
    if not attrs_raw.strip():
        return ""
    pairs = re.findall(r'(\w+)\s*=\s*"([^"]*)"', attrs_raw)
    if not pairs:
        return ""
    return "(" + "; ".join([f"{k}={v}" for k, v in pairs]) + ")"


def stable_key(doc_id: str, tag: str, attrs_raw: str, inner: str, idx_in_tag: int) -> str:
    """
    Stabiler Key pro Checkbox (damit localStorage pro Dokument+Item funktioniert).
    """
    base = f"{doc_id}|{tag}|{attrs_raw}|{inner}|{idx_in_tag}"
    return hashlib.sha1(base.encode("utf-8")).hexdigest()


def stable_key_simple(doc_id: str, scope: str, label: str, idx: int) -> str:
    """
    Stabiler Key für feste Checklisten (Header).
    """
    base = f"{doc_id}|{scope}|{idx}|{label}"
    return hashlib.sha1(base.encode("utf-8")).hexdigest()


def build_html(xml: str) -> str:
    title = get_one_text(xml, "title").strip()
    doc_id = (get_one_text(xml, "id").strip() or title or "doc").strip()

    meta = {t: get_one_text(xml, t) for t in META_TAGS}
    header_elems = extract_header_tags(xml)

    # Reihenfolge der Gruppen: nach erstem Auftreten im Header
    groups: list[str] = []
    grouped: dict[str, list[tuple[str, str, str]]] = defaultdict(list)  # tag -> [(key, attrs_br, inner)]
    per_tag_count: dict[str, int] = defaultdict(int)

    for tag, attrs_raw, inner in header_elems:
        if tag not in grouped:
            groups.append(tag)
        per_tag_count[tag] += 1
        idx_in_tag = per_tag_count[tag]
        key = stable_key(doc_id, tag, attrs_raw, inner, idx_in_tag)
        grouped[tag].append((key, attrs_to_brackets(attrs_raw), inner))

    text = get_one_text(xml, "text")

    header_checks = [
        (stable_key_simple(doc_id, "header-check", label, i + 1), label)
        for i, label in enumerate(HEADER_CHECKLIST)
    ]

    return f"""<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{esc(title)}</title>
  <style>
    body {{
      margin: 0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Noto Sans", "Liberation Sans", sans-serif;
      line-height: 1.35;
    }}
    header {{
      padding: 16px 20px;
      border-bottom: 1px solid #ddd;
    }}
    header h1 {{
      margin: 0 0 10px 0;
      font-size: 20px;
      font-weight: 650;
    }}

    .meta {{
      display: grid;
      grid-template-columns: 180px 1fr;
      gap: 4px 14px;
      font-size: 13px;
    }}
    .meta .k {{ color: #333; font-weight: 600; }}
    .meta .v {{ color: #111; }}

    .header-checklist {{
      margin: 12px 0 0 0;
      padding: 10px 12px;
      border: 1px solid #e3e3e3;
      background: #f7f9ff;
      border-radius: 8px;
    }}
    .header-checklist h3 {{
      margin: 0 0 8px 0;
      font-size: 13px;
      font-weight: 750;
      color: #1f2a55;
    }}

    main {{
      display: grid;
      grid-template-columns: 35% 65%;
      gap: 0;
      height: calc(100vh - 110px);
    }}
    .col {{
      padding: 16px 20px;
      overflow: auto;
    }}
    .left {{
      border-right: 1px solid #ddd;
    }}

    h2 {{
      margin: 0 0 12px 0;
      font-size: 16px;
    }}

    .group {{
      margin: 0 0 18px 0;
      padding: 0 0 18px 0;
      border-bottom: 1px solid #f0f0f0;
    }}
    .group:last-child {{
      border-bottom: none;
      padding-bottom: 0;
      margin-bottom: 0;
    }}
    .group .gname {{
      font-weight: 700;
      margin: 0 0 8px 0;
      font-size: 13px;
      color: #222;
      text-transform: none;
    }}

    .item {{
      margin: 0 0 6px 0;
      font-size: 14px;
      display: flex;
      align-items: flex-start;
      gap: 8px;
    }}
    .header-checklist .item {{
      margin: 0 0 4px 0;
    }}

    .chk {{
      margin-top: 2px;
      flex-shrink: 0;
      width: 16px;
      height: 16px;
    }}
    .label {{
      line-height: 1.3;
      white-space: normal;
      overflow-wrap: anywhere;
    }}
    .attrs {{
      color: #555;
      font-size: 12px;
      margin-left: 6px;
      white-space: normal;
      overflow-wrap: anywhere;
    }}

    pre.text {{
      margin: 0;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
      font-size: 14px;
      white-space: pre-wrap;
    }}
  </style>
</head>
<body>
  <header>
    <h1>{esc(title)}</h1>

    <div class="meta">
      <div class="k">Metadaten</div><div></div>
      <div class="k">&lt;id&gt;</div><div class="v">{esc(meta["id"])}</div>
      <div class="k">&lt;status&gt;</div><div class="v">{esc(meta["status"])}</div>
      <div class="k">&lt;vorlageSeiten&gt;</div><div class="v">{esc(meta["vorlageSeiten"])}</div>
      <div class="k">&lt;anthologieSeiten&gt;</div><div class="v">{esc(meta["anthologieSeiten"])}</div>
    </div>

    <div class="header-checklist">
      <h3>Checkliste</h3>
      {"".join(
        f'<div class="item" data-key="{esc(k)}">'
          f'<input type="checkbox" class="chk" /> '
          f'<span class="label">{esc(lbl)}</span>'
        f'</div>'
        for k, lbl in header_checks
      )}
    </div>
  </header>

  <main data-docid="{esc(doc_id)}">
    <section class="col left">
      <h2>Analyse</h2>
      {"".join(
        f'<div class="group"><div class="gname">&lt;{esc(tag)}&gt;</div>' +
        "".join(
          f'<div class="item" data-key="{esc(key)}">'
            f'<input type="checkbox" class="chk" /> '
            f'<span class="label">{esc(inner)}</span>'
            + (f'<span class="attrs">{esc(attrs)}</span>' if attrs else "")
            + '</div>'
          for key, attrs, inner in grouped[tag]
        ) +
        '</div>'
        for tag in groups
      )}
    </section>

    <section class="col right">
      <h2>Text</h2>
      <pre class="text">{esc(text)}</pre>
    </section>
  </main>

  <script>
  (function() {{
    const root = document.querySelector("main[data-docid]");
    if (!root) return;

    const docid = root.getAttribute("data-docid") || "doc";
    const storagePrefix = "sappho-check:" + docid + ":";

    function restoreAll() {{
      document.querySelectorAll(".item[data-key]").forEach((item) => {{
        const key = item.getAttribute("data-key");
        const cb = item.querySelector("input[type=checkbox]");
        if (!key || !cb) return;
        const v = localStorage.getItem(storagePrefix + key);
        cb.checked = (v === "1");
      }});
    }}

    restoreAll();

    document.addEventListener("change", (ev) => {{
      const t = ev.target;
      if (!(t instanceof HTMLInputElement)) return;
      if (t.type !== "checkbox") return;

      const item = t.closest(".item[data-key]");
      if (!item) return;

      const key = item.getAttribute("data-key");
      if (!key) return;

      localStorage.setItem(storagePrefix + key, t.checked ? "1" : "0");
    }});
  }})();
  </script>
</body>
</html>
"""


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for in_path in sorted(IN_DIR.glob("*.xml")):
        xml = in_path.read_text(encoding="utf-8")
        out_html = build_html(xml)
        out_path = OUT_DIR / (in_path.stem + ".html")
        out_path.write_text(out_html, encoding="utf-8")


if __name__ == "__main__":
    main()
