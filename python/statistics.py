import re
import sys
import xml.etree.ElementTree as ET
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

FEATURE_TYPES = [
    ("person_ref", "/person_ref/",  "Personenreferenzen"),
    ("character",  "/character/",   "Figuren"),
    ("place_ref",  "/place_ref/",   "Ortsreferenzen"),
    ("topos",      "/topos/",       "Rhetorische Topoi"),
    ("motif",      "/motif/",       "Motive"),
    ("topic",      "/topic/",       "Themen"),
    ("plot",       "/plot/",        "Stoffe"),
]

ALL_PHENOM_TYPES = FEATURE_TYPES + [
    ("work_ref",     "/work_ref/",     "Werkreferenzen"),
    ("text_passage", "/text_passage/", "Zitate"),
]

def feature_type(uri: str) -> Optional[str]:
    for key, pattern, _ in ALL_PHENOM_TYPES:
        if pattern in uri:
            return key
    return None


def main(ttl_path: str, xml_out: str) -> None:
    print(f"Lese {ttl_path} ...", file=sys.stderr)
    g = Graph()
    g.parse(ttl_path, format="turtle")
    print(f"  {len(g)} Tripel geladen.", file=sys.stderr)

    sappho_f2    = set()
    reception_f2 = set()

    for subj in g.subjects(RDF.type, F2_Expression):
        uri = str(subj)
        if "bibl_sappho_" in uri:
            sappho_f2.add(subj)
        elif "bibl_" in uri:
            reception_f2.add(subj)

    act_to_features: dict[URIRef, set[URIRef]] = defaultdict(set)
    for act, _, feat in g.triples((None, R17_actualizesFeature, None)):
        act_to_features[act].add(feat)

    # work_ref wird in Statistik 1+2 nicht verwendet
    def build_f2_index(f2_set: set) -> dict:
        idx: dict[URIRef, set[URIRef]] = defaultdict(set)
        for f2 in f2_set:
            for _, _, act in g.triples((f2, R18_showsActualization, None)):
                for feat in act_to_features.get(act, set()):
                    if "/work_ref/" not in str(feat):
                        idx[f2].add(feat)
        return idx

    sappho_idx    = build_f2_index(sappho_f2)
    reception_idx = build_f2_index(reception_f2)

    sappho_with_act    = {f2 for f2, feats in sappho_idx.items()    if feats}
    reception_with_act = {f2 for f2, feats in reception_idx.items() if feats}

    n_sappho    = len(sappho_with_act)
    n_reception = len(reception_with_act)

    print(f"  Sappho-Fragmente mit Aktualisierungen:    {n_sappho}", file=sys.stderr)
    print(f"  Rezeptionszeugnisse mit Aktualisierungen: {n_reception}", file=sys.stderr)

    def clean_label(s: str) -> str:
        s = re.sub(r'^Plot:\s*',      '', s)
        s = re.sub(r'^Motif:\s*',     '', s)
        s = re.sub(r'^Topic:\s*',     '', s)
        s = re.sub(r'^Character:\s*', '', s)
        s = re.sub(r'(?i)^[Rr]eference\s+to\s+', '', s)
        s = re.sub(r'(?i)^Passage\s+from\s+',    '', s)
        s = re.sub(r'(?i)^Expression\s+of\s+',   '', s)
        s = re.sub(r'\s*\(topos\)\s*$',   '', s)
        s = re.sub(r'\s*\(place\)\s*$',   '', s, flags=re.IGNORECASE)
        s = re.sub(r'\s*\(person\)\s*$',  '', s, flags=re.IGNORECASE)
        s = re.sub(r'\s*\(work\)\s*$',    '', s, flags=re.IGNORECASE)
        s = re.sub(r'\s*\(character\)\s*$', '', s, flags=re.IGNORECASE)
        s = re.sub(r'\s*\(motif\)\s*$',   '', s, flags=re.IGNORECASE)
        s = re.sub(r'\s*\(topic\)\s*$',   '', s, flags=re.IGNORECASE)
        s = re.sub(r'\s*\(plot\)\s*$',    '', s, flags=re.IGNORECASE)
        return s.strip()

    def get_label(uri: URIRef) -> str:
        en = de = any_label = None
        for _, _, label in g.triples((uri, RDFS.label, None)):
            lang = getattr(label, "language", None)
            if lang == "en":   en        = str(label)
            elif lang == "de": de        = str(label)
            else:              any_label = str(label)
        raw = de or en or any_label or str(uri).split("/")[-1]
        return clean_label(raw)

    # ── Statistik 1: Kategorien ───────────────────────────────────────────────

    for ftype_key, pattern, ftype_label in FEATURE_TYPES:
        all_feat_uris: set[URIRef] = set()
        for feats in sappho_idx.values():
            all_feat_uris |= {f for f in feats if pattern in str(f)}
        for feats in reception_idx.values():
            all_feat_uris |= {f for f in feats if pattern in str(f)}
        print(f"  {ftype_label}: {len(all_feat_uris)} distinkte Features", file=sys.stderr)

    root_el = ET.Element("statistics")
    root_el.set("nSappho",    str(n_sappho))
    root_el.set("nReception", str(n_reception))

    for ftype_key, pattern, ftype_label in FEATURE_TYPES:
        all_feat_uris = set()
        for feats in sappho_idx.values():
            all_feat_uris |= {f for f in feats if pattern in str(f)}
        for feats in reception_idx.values():
            all_feat_uris |= {f for f in feats if pattern in str(f)}

        feat_counts: dict[URIRef, dict] = {}
        for feat_uri in all_feat_uris:
            cs = sum(1 for f2, feats in sappho_idx.items()
                     if feat_uri in feats and f2 in sappho_with_act)
            cr = sum(1 for f2, feats in reception_idx.items()
                     if feat_uri in feats and f2 in reception_with_act)
            feat_counts[feat_uri] = {
                "label": get_label(feat_uri),
                "cs": cs, "cr": cr,
                "pct_s": round(cs / n_sappho   * 100, 2) if n_sappho   > 0 else 0.0,
                "pct_r": round(cr / n_reception * 100, 2) if n_reception > 0 else 0.0,
            }

        sorted_feats = sorted(
            feat_counts.items(),
            key=lambda x: (-x[1]["cr"], -x[1]["cs"], x[1]["label"].lower())
        )

        cat_el = ET.SubElement(root_el, "category")
        cat_el.set("key", ftype_key)
        cat_el.set("label", ftype_label)
        cat_el.set("n", str(len(sorted_feats)))

        for feat_uri, d in sorted_feats:
            item_el = ET.SubElement(cat_el, "item")
            item_el.set("label",          d["label"])
            item_el.set("uri",            str(feat_uri))
            item_el.set("countSappho",    str(d["cs"]))
            item_el.set("countReception", str(d["cr"]))
            item_el.set("pctSappho",      f'{d["pct_s"]:.2f}')
            item_el.set("pctReception",   f'{d["pct_r"]:.2f}')

    # ── Statistik 2: Fragmente ────────────────────────────────────────────────

    INTRO_NS = Namespace("https://w3id.org/lso/intro/currentbeta#")
    ECRM_NS  = Namespace("http://erlangen-crm.org/current/")

    R17i_featureIsActualizedIn = INTRO_NS["R17i_featureIsActualizedIn"]
    R18i_actualizationFoundOn  = INTRO_NS["R18i_actualizationFoundOn"]

    import re as _re

    voigt_refs: dict[URIRef, str] = {}
    voigt_ref_to_sappho: dict[URIRef, URIRef] = {}

    for ref_uri, _, lbl in g.triples((None, RDFS.label, None)):
        lbl_str = str(lbl)
        if "Voigt" not in lbl_str:
            continue
        uri_str = str(ref_uri)
        if "/work_ref/" not in uri_str or "/actualization/" in uri_str:
            continue
        m = _re.search(r'(?:Fragment|Fr\.)\s+(.*?Voigt(?:\s*\([^)]+\))*)\s*\(work\)', lbl_str)
        frag_label = m.group(1).strip() if m else lbl_str
        if ref_uri not in voigt_refs or getattr(lbl, 'language', None) == 'en':
            voigt_refs[ref_uri] = frag_label

    BASE = "https://sappho-digital.com/expression/bibl_sappho_"
    for ref_uri, frag_label in voigt_refs.items():
        m = _re.match(r'(\S+)\s+Voigt', frag_label)
        if not m:
            continue
        sappho_uri = URIRef(BASE + m.group(1))
        if sappho_uri in sappho_idx:
            voigt_ref_to_sappho[ref_uri] = sappho_uri
        else:
            print(f"  WARNUNG: {sappho_uri} nicht in sappho_idx", file=sys.stderr)

    print(f"  INT18_References mit Voigt:   {len(voigt_refs)}", file=sys.stderr)
    print(f"  davon mit Sappho-F2 URI:      {len(voigt_ref_to_sappho)}", file=sys.stderr)

    frag_data:      dict[str, dict[str, dict[URIRef, int]]] = {}
    frag_biblsets:  dict[str, set[URIRef]] = {}
    frag_sappho_f2: dict[str, URIRef] = {}

    for ref_uri, frag_label in voigt_refs.items():
        if frag_label not in frag_data:
            frag_data[frag_label]     = {k: {} for k, _, _ in FEATURE_TYPES}
            frag_biblsets[frag_label] = set()

        for _, _, act_uri in g.triples((ref_uri, R17i_featureIsActualizedIn, None)):
            bibl_expr = None
            for _, _, src in g.triples((act_uri, R18i_actualizationFoundOn, None)):
                src_str = str(src)
                if "/expression/bibl_" in src_str and "bibl_sappho_" not in src_str:
                    bibl_expr = src
                    break
            if bibl_expr is None:
                continue

            frag_biblsets[frag_label].add(bibl_expr)

            if frag_label not in frag_sappho_f2 and ref_uri in voigt_ref_to_sappho:
                frag_sappho_f2[frag_label] = voigt_ref_to_sappho[ref_uri]

            for feat_uri in reception_idx.get(bibl_expr, set()):
                ftype = feature_type(str(feat_uri))
                if ftype is None:
                    continue
                counts = frag_data[frag_label][ftype]
                counts[feat_uri] = counts.get(feat_uri, 0) + 1

    frag_data = {
        fl: ftypes for fl, ftypes in frag_data.items()
        if any(feat_counts for feat_counts in ftypes.values())
    }

    print(f"  Fragmente mit Rezeptionsdaten: {len(frag_data)}", file=sys.stderr)
    print(f"  Davon mit Sappho-F2 gefunden:  {len(frag_sappho_f2)}", file=sys.stderr)
    if frag_sappho_f2:
        sample = next(iter(frag_sappho_f2.items()))
        feats  = sappho_idx.get(sample[1], set())
        print(f"  Beispiel: '{sample[0]}' -> {sample[1]} -> {len(feats)} Sappho-Features",
              file=sys.stderr)

    def voigt_sort_key(label: str):
        m   = _re.match(r'(\d+)', label)
        num = int(m.group(1)) if m else 9999
        suffix = _re.sub(r'^\d+', '', label.split()[0]) if m else label
        return (num, suffix)

    sorted_frags = sorted(frag_data.keys(), key=voigt_sort_key)

    frags_el = ET.SubElement(root_el, "fragments")
    frags_el.set("n", str(len(sorted_frags)))

    for frag_label in sorted_frags:
        frag_el = ET.SubElement(frags_el, "fragment")
        frag_el.set("label", frag_label)
        frag_el.set("nBibl", str(len(frag_biblsets.get(frag_label, set()))))

        sappho_f2_uri = frag_sappho_f2.get(frag_label)
        if sappho_f2_uri is not None:
            sappho_feats = sappho_idx.get(sappho_f2_uri, set())
            sf_el = ET.SubElement(frag_el, "sapphoFeatures")
            for ftype_key, pattern, ftype_display in FEATURE_TYPES:
                type_feats = sorted(
                    [f for f in sappho_feats if pattern in str(f)],
                    key=lambda f: get_label(f).lower()
                )
                if not type_feats:
                    continue
                sft_el = ET.SubElement(sf_el, "featureType")
                sft_el.set("key",   ftype_key)
                sft_el.set("label", ftype_display)
                for feat_uri in type_feats:
                    sfi_el = ET.SubElement(sft_el, "item")
                    sfi_el.set("label", get_label(feat_uri))
                    sfi_el.set("uri",   str(feat_uri))

        for ftype_key, pattern, ftype_display in FEATURE_TYPES:
            feat_counts = frag_data[frag_label].get(ftype_key, {})
            if not feat_counts:
                continue
            ftype_el = ET.SubElement(frag_el, "featureType")
            ftype_el.set("key",   ftype_key)
            ftype_el.set("label", ftype_display)
            ftype_el.set("total", str(sum(feat_counts.values())))
            for feat_uri, count in sorted(
                feat_counts.items(),
                key=lambda x: (-x[1], get_label(x[0]).lower())
            ):
                feat_el = ET.SubElement(ftype_el, "item")
                feat_el.set("label", get_label(feat_uri))
                feat_el.set("uri",   str(feat_uri))
                feat_el.set("count", str(count))

    # ── Statistik 3: Phänomene nach Zeit ─────────────────────────────────────

    R17i_was_created_by      = LRMOO["R17i_was_created_by"]
    R4i_is_embodied_in       = LRMOO["R4i_is_embodied_in"]
    R24i_was_created_through = LRMOO["R24i_was_created_through"]

    GENRE_BASE   = "https://sappho-digital.com/genre/"
    GENRE_LABELS = {"lyrik": "Lyrik", "prosa": "Prosa", "drama": "Drama", "Comic": "Comic"}

    def get_genre(f2_uri: URIRef) -> str:
        for _, _, type_uri in g.triples((f2_uri, P2_has_type, None)):
            t = str(type_uri)
            if GENRE_BASE in t:
                key = t.split(GENRE_BASE)[-1].strip("/")
                return GENRE_LABELS.get(key, key)
        return "Unbekannt"

    def extract_year(ts_uri: URIRef) -> Optional[int]:
        m = re.search(r'/timespan/(\d{4})', str(ts_uri))
        if m:
            return int(m.group(1))
        for _, _, lbl in g.triples((ts_uri, RDFS.label, None)):
            m2 = re.search(r'\b(\d{4})\b', str(lbl))
            if m2:
                return int(m2.group(1))
        return None

    def get_year_for_f2(f2_uri: URIRef) -> Optional[int]:
        for _, _, f28 in g.triples((f2_uri, R17i_was_created_by, None)):
            for _, _, ts in g.triples((f28, P4_has_time_span, None)):
                y = extract_year(ts)
                if y is not None:
                    return y
        for _, _, f3 in g.triples((f2_uri, R4i_is_embodied_in, None)):
            for _, _, f30 in g.triples((f3, R24i_was_created_through, None)):
                for _, _, ts in g.triples((f30, P4_has_time_span, None)):
                    y = extract_year(ts)
                    if y is not None:
                        return y
        return None

    def get_work_refs(f2_uri: URIRef) -> set[URIRef]:
        refs: set[URIRef] = set()
        for _, _, act in g.triples((f2_uri, R18_showsActualization, None)):
            for _, _, feat in g.triples((act, R17_actualizesFeature, None)):
                if "/work_ref/" in str(feat):
                    refs.add(feat)
        return refs

    def get_text_passages(f2_uri: URIRef) -> set[URIRef]:
        tps: set[URIRef] = set()
        for _, _, tp in g.triples((f2_uri, R30_hasTextPassage, None)):
            tps.add(tp)
        for tp, _, _ in g.triples((None, R30i_isTextPassageOf, f2_uri)):
            tps.add(tp)
        return tps

    dist_records = []
    for f2 in reception_f2:
        if f2 not in reception_with_act:
            continue
        features      = set(reception_idx.get(f2, set())) | get_work_refs(f2)
        text_passages = get_text_passages(f2)
        if not features and not text_passages:
            continue
        dist_records.append({
            "uri":           str(f2),
            "year":          get_year_for_f2(f2),
            "genre":         get_genre(f2),
            "features":      features,
            "text_passages": text_passages,
        })

    n_with_year    = sum(1 for r in dist_records if r["year"] is not None)
    n_without_year = len(dist_records) - n_with_year
    print(f"  PhenomDist-Einträge: {len(dist_records)} "
          f"(ohne Jahr: {n_without_year})", file=sys.stderr)

    def decade(y: Optional[int]) -> str:
        return "n/a" if y is None else f"{(y // 10) * 10}s"

    feat_dist:   dict[URIRef, dict[str, dict[str, int]]] = defaultdict(
                     lambda: defaultdict(lambda: defaultdict(int)))
    feat_labels: dict[URIRef, str] = {}
    feat_ftype:  dict[URIRef, str] = {}
    genres_seen:  set[str] = set()
    decades_seen: set[str] = set()

    for rec in dist_records:
        dec = decade(rec["year"])
        gen = rec["genre"]
        genres_seen.add(gen)
        decades_seen.add(dec)
        for feat_uri in rec["features"]:
            feat_dist[feat_uri][dec][gen] += 1
            if feat_uri not in feat_labels:
                feat_labels[feat_uri] = get_label(feat_uri)
                feat_ftype[feat_uri]  = feature_type(str(feat_uri)) or "other"
        for tp_uri in rec["text_passages"]:
            feat_dist[tp_uri][dec][gen] += 1
            if tp_uri not in feat_labels:
                feat_labels[tp_uri] = get_label(tp_uri)
                feat_ftype[tp_uri]  = "text_passage"

    print(f"  Distinkte Phänomene in PhenomDist: {len(feat_dist)}", file=sys.stderr)
    print(f"  Zeugnisse mit Jahr: {n_with_year}, ohne Jahr: {n_without_year}", file=sys.stderr)

    def decade_sort(d: str) -> int:
        m = re.match(r'(\d+)', d)
        return int(m.group(1)) if m else 9999

    sorted_decades = sorted([d for d in decades_seen if d != "n/a"], key=decade_sort)
    if "n/a" in decades_seen:
        sorted_decades.append("n/a")

    genre_order   = ["Lyrik", "Prosa", "Drama", "Comic", "Unbekannt"]
    sorted_genres = [g for g in genre_order if g in genres_seen]
    sorted_genres += [g for g in sorted(genres_seen) if g not in genre_order]

    def feat_total(fu: URIRef) -> int:
        return sum(cnt for dec_dict in feat_dist[fu].values() for cnt in dec_dict.values())

    feat_totals  = {fu: feat_total(fu) for fu in feat_dist}
    sorted_feats = sorted(feat_dist.keys(),
                          key=lambda fu: (-feat_totals[fu], feat_labels.get(fu, "").lower()))

    pdist_el = ET.SubElement(root_el, "phenomenaDist")
    pdist_el.set("nRecords",     str(len(dist_records)))
    pdist_el.set("nWithYear",    str(n_with_year))
    pdist_el.set("nWithoutYear", str(n_without_year))
    pdist_el.set("nFeatures",    str(len(feat_dist)))

    meta_el = ET.SubElement(pdist_el, "meta")
    for dec in sorted_decades:
        ET.SubElement(meta_el, "decade").set("key", dec)
    for gen in sorted_genres:
        ET.SubElement(meta_el, "genre").set("key", gen)

    feats_el = ET.SubElement(pdist_el, "features")
    for feat_uri in sorted_feats:
        fe = ET.SubElement(feats_el, "feature")
        fe.set("uri",   str(feat_uri))
        fe.set("label", feat_labels.get(feat_uri, str(feat_uri).split("/")[-1]))
        fe.set("ftype", feat_ftype.get(feat_uri, "other"))
        fe.set("total", str(feat_totals[feat_uri]))
        for dec in sorted_decades:
            dec_total = sum(feat_dist[feat_uri].get(dec, {}).values())
            if dec_total:
                cell_el = ET.SubElement(fe, "cell")
                cell_el.set("decade", dec)
                cell_el.set("n",      str(dec_total))

    # ── Statistik 4: Phänomene nach Gattung ──────────────────────────────────

    genre_dist_feat:   dict[URIRef, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    genre_dist_labels: dict[URIRef, str] = {}
    genre_dist_ftype:  dict[URIRef, str] = {}
    genres_stat4:      set[str] = set()

    for rec in dist_records:
        gen = rec["genre"]
        genres_stat4.add(gen)
        for feat_uri in rec["features"]:
            genre_dist_feat[feat_uri][gen] += 1
            if feat_uri not in genre_dist_labels:
                genre_dist_labels[feat_uri] = get_label(feat_uri)
                genre_dist_ftype[feat_uri]  = feature_type(str(feat_uri)) or "other"
        for tp_uri in rec["text_passages"]:
            genre_dist_feat[tp_uri][gen] += 1
            if tp_uri not in genre_dist_labels:
                genre_dist_labels[tp_uri] = get_label(tp_uri)
                genre_dist_ftype[tp_uri]  = "text_passage"

    def feat_genre_total(fu: URIRef) -> int:
        return sum(genre_dist_feat[fu].values())

    genre_n: dict[str, int] = defaultdict(int)
    for rec in dist_records:
        genre_n[rec["genre"]] += 1

    sorted_genres4 = [g for g in genre_order if g in genres_stat4]
    sorted_genres4 += [g for g in sorted(genres_stat4) if g not in genre_order]

    sorted_feats4 = sorted(
        genre_dist_feat.keys(),
        key=lambda fu: (-feat_genre_total(fu), genre_dist_labels.get(fu, "").lower())
    )

    print(f"  GenreDist-Phänomene: {len(sorted_feats4)}", file=sys.stderr)

    gdist_el = ET.SubElement(root_el, "genreDist")
    gdist_el.set("nRecords",  str(len(dist_records)))
    gdist_el.set("nFeatures", str(len(sorted_feats4)))

    gmeta_el = ET.SubElement(gdist_el, "meta")
    for gen in sorted_genres4:
        g_el = ET.SubElement(gmeta_el, "genre")
        g_el.set("key", gen)
        g_el.set("n",   str(genre_n.get(gen, 0)))

    gfeats_el = ET.SubElement(gdist_el, "features")
    for feat_uri in sorted_feats4:
        fe = ET.SubElement(gfeats_el, "feature")
        fe.set("uri",   str(feat_uri))
        fe.set("label", genre_dist_labels.get(feat_uri, str(feat_uri).split("/")[-1]))
        fe.set("ftype", genre_dist_ftype.get(feat_uri, "other"))
        fe.set("total", str(feat_genre_total(feat_uri)))
        for gen in sorted_genres4:
            cnt = genre_dist_feat[feat_uri].get(gen, 0)
            if cnt:
                gc_el = ET.SubElement(fe, "genreCell")
                gc_el.set("genre", gen)
                gc_el.set("n",     str(cnt))

    # ── Statistik 5: Stoff-Komponenten ───────────────────────

    # Vollständiges Feature-Set pro Rezeptionszeugnis aufbauen
    rec_all_feats: dict[URIRef, set] = {}
    for rec in dist_records:
        f2_uri = URIRef(rec["uri"])
        combined: set = set(rec["features"]) | set(rec["text_passages"])
        rec_all_feats[f2_uri] = combined

    # Alle Plot-URIs finden
    plot_uris: set[URIRef] = set()
    for feats in rec_all_feats.values():
        for feat in feats:
            if "/plot/" in str(feat):
                plot_uris.add(feat)

    print(f"  Distinkte Stoffe (plot): {len(plot_uris)}", file=sys.stderr)

    # Co-occurrence berechnen
    plot_docs:    dict[URIRef, set] = defaultdict(set)
    plot_cooccur: dict[URIRef, dict] = defaultdict(lambda: defaultdict(int))

    for f2_uri, feats in rec_all_feats.items():
        plots_in_doc = {f for f in feats if "/plot/" in str(f)}
        for plot_uri in plots_in_doc:
            plot_docs[plot_uri].add(f2_uri)
            for other in feats:
                if other == plot_uri:
                    continue
                ft = feature_type(str(other))
                if ft is not None:
                    plot_cooccur[plot_uri][other] += 1
                elif "/text_passage/" in str(other):
                    plot_cooccur[plot_uri][other] += 1

    # XML aufbauen
    pc_el = ET.SubElement(root_el, "plotComponents")
    pc_el.set("nPlots",   str(len(plot_uris)))
    pc_el.set("nRecords", str(len(dist_records)))

    # Plots nach Häufigkeit sortieren (häufigste zuerst), dann alphabetisch
    sorted_plots = sorted(
        plot_uris,
        key=lambda u: (-len(plot_docs[u]), get_label(u).lower())
    )

    for plot_uri in sorted_plots:
        n_docs = len(plot_docs[plot_uri])
        if n_docs == 0:
            continue

        plot_el = ET.SubElement(pc_el, "plot")
        plot_el.set("uri",   str(plot_uri))
        plot_el.set("label", get_label(plot_uri))
        plot_el.set("nDocs", str(n_docs))

        # Co-features nach Häufigkeit sortieren
        cofeats_sorted = sorted(
            plot_cooccur[plot_uri].items(),
            key=lambda x: (-x[1], get_label(x[0]).lower())
        )
        for co_uri, co_n in cofeats_sorted:
            ft = feature_type(str(co_uri))
            if ft is None:
                if "/text_passage/" in str(co_uri):
                    ft = "text_passage"
                else:
                    continue
            cf_el = ET.SubElement(plot_el, "coFeature")
            cf_el.set("uri",   str(co_uri))
            cf_el.set("label", get_label(co_uri))
            cf_el.set("ftype", ft)
            cf_el.set("n",     str(co_n))

    print(f"  PlotComponents: {len(sorted_plots)} Stoffe verarbeitet", file=sys.stderr)

    # ── Statistik 6: Personenreferenzen vs. Figuren ───────────────────────────

    def count_persons_in_index(f2_index: dict) -> tuple[dict, dict, dict, dict]:
        """Gibt (pr_count, ch_count, pr_labels, pr_by_id, ch_by_id) zurück."""
        pr_count: dict[URIRef, int] = defaultdict(int)
        ch_count: dict[URIRef, int] = defaultdict(int)
        pr_lbls:  dict[URIRef, str] = {}
        for f2, feats in f2_index.items():
            for feat_uri in feats:
                s = str(feat_uri)
                if "/person_ref/" in s:
                    pr_count[feat_uri] += 1
                    if feat_uri not in pr_lbls:
                        pr_lbls[feat_uri] = get_label(feat_uri)
                elif "/character/" in s:
                    ch_count[feat_uri] += 1
        _pr_by_id: dict[str, URIRef] = {}
        for uri in pr_count:
            seg = str(uri).rstrip("/").split("/")[-1]
            _pr_by_id[seg] = uri
        _ch_by_id: dict[str, URIRef] = {}
        for uri in ch_count:
            seg = str(uri).rstrip("/").split("/")[-1]
            _ch_by_id[seg] = uri
        return pr_count, ch_count, pr_lbls, _pr_by_id, _ch_by_id

    # Rezeptionszeugnisse
    rec_pr_count, rec_ch_count, rec_pr_labels, rec_pr_by_id, rec_ch_by_id = \
        count_persons_in_index(reception_idx)

    # Sappho-Fragmente
    sap_pr_count, sap_ch_count, sap_pr_labels, sap_pr_by_id, sap_ch_by_id = \
        count_persons_in_index(sappho_idx)

    all_ids: set[str] = set(rec_pr_by_id) | set(sap_pr_by_id)

    pd_el = ET.SubElement(root_el, "personDuality")
    pd_el.set("nPersonRef",      str(len(rec_pr_by_id)))
    pd_el.set("nCharacter",      str(len(rec_ch_by_id)))
    pd_el.set("nBoth",           str(len(set(rec_pr_by_id) & set(rec_ch_by_id))))
    pd_el.set("nSapphoPersonRef", str(len(sap_pr_by_id)))
    pd_el.set("nSapphoCharacter", str(len(sap_ch_by_id)))

    persons_sorted = sorted(
        all_ids,
        key=lambda seg: (
            -(rec_pr_count.get(rec_pr_by_id.get(seg), 0)),
            -(rec_ch_count.get(rec_ch_by_id.get(seg), 0)),
            -(sap_pr_count.get(sap_pr_by_id.get(seg), 0)),
        )
    )

    for seg in persons_sorted:
        rec_pr_uri = rec_pr_by_id.get(seg)
        rec_ch_uri = rec_ch_by_id.get(seg)
        sap_pr_uri = sap_pr_by_id.get(seg)
        sap_ch_uri = sap_ch_by_id.get(seg)

        rec_pr_n = rec_pr_count.get(rec_pr_uri, 0) if rec_pr_uri else 0
        rec_ch_n = rec_ch_count.get(rec_ch_uri, 0) if rec_ch_uri else 0
        sap_pr_n = sap_pr_count.get(sap_pr_uri, 0) if sap_pr_uri else 0
        sap_ch_n = sap_ch_count.get(sap_ch_uri, 0) if sap_ch_uri else 0

        pct_rec_pr = round(rec_pr_n / n_reception * 100, 2) if n_reception > 0 else 0.0
        pct_rec_ch = round(rec_ch_n / n_reception * 100, 2) if n_reception > 0 else 0.0
        pct_sap_pr = round(sap_pr_n / n_sappho    * 100, 2) if n_sappho    > 0 else 0.0
        pct_sap_ch = round(sap_ch_n / n_sappho    * 100, 2) if n_sappho    > 0 else 0.0

        label = (rec_pr_labels.get(rec_pr_uri)
                 or sap_pr_labels.get(sap_pr_uri)
                 or get_label(rec_pr_uri or sap_pr_uri))

        p_el = ET.SubElement(pd_el, "person")
        p_el.set("label",      label)
        p_el.set("persRefN",   str(rec_pr_n))
        p_el.set("charN",      str(rec_ch_n))
        p_el.set("sapPrN",     str(sap_pr_n))
        p_el.set("sapChN",     str(sap_ch_n))
        p_el.set("pctRecPr",   f"{pct_rec_pr:.2f}")
        p_el.set("pctRecCh",   f"{pct_rec_ch:.2f}")
        p_el.set("pctSapPr",   f"{pct_sap_pr:.2f}")
        p_el.set("pctSapCh",   f"{pct_sap_ch:.2f}")

    print(f"  PersonDuality: {len(persons_sorted)} Personen gesamt, "
          f"Rezeption: {len(rec_pr_by_id)} pers_ref / {len(rec_ch_by_id)} character, "
          f"Sappho: {len(sap_pr_by_id)} pers_ref / {len(sap_ch_by_id)} character",
          file=sys.stderr)

    # ── Statistik 7: Werkreferenzen × Zitate ─────────────────────────────────

    INT21_TextPassage = INTRO["INT21_TextPassage"]

    # Menge aller TextPassage-URIs
    all_tp_uris: set[URIRef] = set(g.subjects(RDF.type, INT21_TextPassage))
    print(f"  INT21_TextPassage gesamt: {len(all_tp_uris)}", file=sys.stderr)

    # tp → {work_ref_uri, ...}  (via R18_showsActualization → R17_actualizesFeature)
    tp_to_cited_works: dict[URIRef, set[URIRef]] = defaultdict(set)
    for tp_uri in all_tp_uris:
        for _, _, act in g.triples((tp_uri, R18_showsActualization, None)):
            for _, _, feat in g.triples((act, R17_actualizesFeature, None)):
                if "/work_ref/" in str(feat):
                    tp_to_cited_works[tp_uri].add(feat)

    # tp → {f2_uri, ...}  (via R30i_isTextPassageOf)
    tp_to_f2: dict[URIRef, set[URIRef]] = defaultdict(set)
    for tp_uri in all_tp_uris:
        for _, _, f2 in g.triples((tp_uri, R30i_isTextPassageOf, None)):
            if f2 in reception_f2:
                tp_to_f2[tp_uri].add(f2)

    # Pro work_ref-URI: Mengen der Rezeptionszeugnisse, die referenzieren/zitieren
    work_ref_docs: dict[URIRef, set[URIRef]] = defaultdict(set)
    work_cite_docs: dict[URIRef, set[URIRef]] = defaultdict(set)

    # referenzieren: direkt aus reception_idx (work_refs via get_work_refs)
    for f2 in reception_f2:
        for wr in get_work_refs(f2):
            work_ref_docs[wr].add(f2)

    # zitieren: über tp_to_cited_works + tp_to_f2
    for tp_uri, cited_works in tp_to_cited_works.items():
        for f2 in tp_to_f2.get(tp_uri, set()):
            for wr in cited_works:
                work_cite_docs[wr].add(f2)

    all_work_uris = set(work_ref_docs) | set(work_cite_docs)
    print(f"  Werke (work_ref) gesamt:       {len(all_work_uris)}", file=sys.stderr)
    print(f"  davon nur referenziert:        "
          f"{sum(1 for w in all_work_uris if w in work_ref_docs and w not in work_cite_docs)}",
          file=sys.stderr)
    print(f"  davon nur zitiert:             "
          f"{sum(1 for w in all_work_uris if w not in work_ref_docs and w in work_cite_docs)}",
          file=sys.stderr)
    print(f"  davon referenziert und zitiert: "
          f"{sum(1 for w in all_work_uris if w in work_ref_docs and w in work_cite_docs)}",
          file=sys.stderr)

    sorted_works = sorted(
        all_work_uris,
        key=lambda w: (
            -len(work_ref_docs[w] & work_cite_docs[w]),
            -len(work_ref_docs[w]),
            -len(work_cite_docs[w]),
            get_label(w).lower()
        )
    )

    wc_el = ET.SubElement(root_el, "workCitation")
    wc_el.set("nWorks",     str(len(all_work_uris)))
    wc_el.set("nReception", str(n_reception))
    wc_el.set("nTP",        str(len(all_tp_uris)))

    for wr_uri in sorted_works:
        ref_docs  = work_ref_docs.get(wr_uri, set())
        cite_docs = work_cite_docs.get(wr_uri, set())
        both_docs = ref_docs & cite_docs

        ref_n  = len(ref_docs)
        cite_n = len(cite_docs)
        both_n = len(both_docs)

        pct_ref  = round(ref_n  / n_reception * 100, 2) if n_reception > 0 else 0.0
        pct_cite = round(cite_n / n_reception * 100, 2) if n_reception > 0 else 0.0
        pct_both = round(both_n / n_reception * 100, 2) if n_reception > 0 else 0.0

        w_el = ET.SubElement(wc_el, "work")
        w_el.set("label",   get_label(wr_uri))
        w_el.set("uri",     str(wr_uri))
        w_el.set("refN",    str(ref_n))
        w_el.set("citeN",   str(cite_n))
        w_el.set("bothN",   str(both_n))
        w_el.set("pctRef",  f"{pct_ref:.2f}")
        w_el.set("pctCite", f"{pct_cite:.2f}")
        w_el.set("pctBoth", f"{pct_both:.2f}")

    print(f"  WorkCitation: {len(sorted_works)} Werke in XML geschrieben", file=sys.stderr)

    # ── Statistik 8: INT31 Co-Occurrence ─────────────────────────────────────

    INT31_IntertextualRelation       = INTRO["INT31_IntertextualRelation"]
    R22i_relationIsBasedOnSimilarity = INTRO["R22i_relationIsBasedOnSimilarity"]
    R24_hasRelatedEntity             = INTRO["R24_hasRelatedEntity"]

    from itertools import combinations as _combinations

    # Alle INT31-Knoten einsammeln
    int31_nodes_all: set[URIRef] = set(g.subjects(RDF.type, INT31_IntertextualRelation))
    print(f"  INT31-Knoten gesamt: {len(int31_nodes_all)}", file=sys.stderr)

    R17i_featureIsActualizedIn = INTRO["R17i_featureIsActualizedIn"]

    int31_to_feats: dict[URIRef, set[URIRef]] = {}
    n_filtered_out = 0
    for node in int31_nodes_all:
        related     = {obj for _, _, obj in g.triples((node, R24_hasRelatedEntity, None))}
        relevant_f2 = related.intersection(reception_with_act | sappho_with_act)
        if not relevant_f2:
            n_filtered_out += 1
            continue
        feats: set[URIRef] = set()
        for _, _, feat in g.triples((node, R22i_relationIsBasedOnSimilarity, None)):
            ft = feature_type(str(feat))
            if ft is not None:
                feats.add(feat)
            for _, _, act in g.triples((feat, R17i_featureIsActualizedIn, None)):
                act_f2s = {obj for _, _, obj in g.triples((act, R18i_actualizationFoundOn, None))
                           if obj in reception_with_act | sappho_with_act}
                if not act_f2s.intersection(relevant_f2):
                    continue
                # TextPassagen
                for _, _, target in g.triples((act, R18i_actualizationFoundOn, None)):
                    if "/textpassage/" in str(target):
                        feats.add(target)
        if feats:
            int31_to_feats[node] = feats

    n_int31_relevant  = len(int31_nodes_all) - n_filtered_out
    n_int31_with_feats = len(int31_to_feats)
    print(f"  INT31 mit reception_with_act-Bezug: {n_int31_relevant}", file=sys.stderr)
    print(f"  davon mit Features:                 {n_int31_with_feats}", file=sys.stderr)

    # ── Häufigkeit einzelner Phänomene als INT31-Grundlage ────────────────
    feat_int31_count: dict[URIRef, int] = defaultdict(int)
    for feats in int31_to_feats.values():
        for f in feats:
            feat_int31_count[f] += 1

    # ── Paar-Co-Occurrence ───────────────────────────
    pair_count: dict[tuple[URIRef, URIRef], int] = defaultdict(int)
    for feats in int31_to_feats.values():
        feat_list = sorted(feats)
        for a, b in _combinations(feat_list, 2):
            pair_count[(a, b)] += 1

    print(f"  Distinkte Phänomene: {len(feat_int31_count)}", file=sys.stderr)
    print(f"  Distinkte Paare:     {len(pair_count)}", file=sys.stderr)

    # ── XML aufbauen ─────────────────────────────────────────────────────────
    co_el = ET.SubElement(root_el, "int31CoOccurrence")
    co_el.set("nInt31All",       str(len(int31_nodes_all)))
    co_el.set("nInt31Relevant",  str(n_int31_relevant))
    co_el.set("nInt31WithFeats", str(n_int31_with_feats))

    def int31_ftype(uri: URIRef) -> str:
        """feature_type fuer Statistik 8: schliesst auch INT21_TextPassage ein."""
        ft = feature_type(str(uri))
        if ft is not None:
            return ft
        if g.value(uri, RDF.type) == INT21_TextPassage or            (RDF.type, INT21_TextPassage) in g.predicate_objects(uri):
            return "text_passage"
        for _, _, rtype in g.triples((uri, RDF.type, None)):
            if "TextPassage" in str(rtype):
                return "text_passage"
        return "other"

    sorted_feats_int31 = sorted(
        feat_int31_count.items(),
        key=lambda x: (-x[1], get_label(x[0]).lower())
    )
    freqs_el = ET.SubElement(co_el, "featFrequencies")
    for feat_uri, cnt in sorted_feats_int31:
        ft = int31_ftype(feat_uri)
        fe = ET.SubElement(freqs_el, "feat")
        fe.set("uri",   str(feat_uri))
        fe.set("label", get_label(feat_uri))
        fe.set("ftype", ft)
        fe.set("n",     str(cnt))

    # Paar-Co-Occurrence
    sorted_pairs = sorted(pair_count.items(), key=lambda x: (-x[1], get_label(x[0][0]).lower()))
    pairs_el = ET.SubElement(co_el, "featPairs")
    for (ua, ub), cnt in sorted_pairs:
        fta = int31_ftype(ua)
        ftb = int31_ftype(ub)
        pe = ET.SubElement(pairs_el, "featPair")
        pe.set("uriA",   str(ua))
        pe.set("labelA", get_label(ua))
        pe.set("ftypeA", fta)
        pe.set("uriB",   str(ub))
        pe.set("labelB", get_label(ub))
        pe.set("ftypeB", ftb)
        pe.set("n",      str(cnt))

    print(f"  INT31CoOccurrence: {len(sorted_feats_int31)} Phänomene, "
          f"{len(sorted_pairs)} Paare in XML geschrieben", file=sys.stderr)

    # ── Statistik 9: Top-N INT31-Knoten ───

    BASE_URL = "https://sappho-digital.com/"

    def f2_page_url(f2_uri: URIRef) -> str:
        """Konstruiert die HTML-Seiten-URL zu einer F2_Expression-URI.
        Muster analog network.py (F2_Expression): BASE + local_id + .html"""
        lid = str(f2_uri).rstrip("/").rsplit("/", 1)[-1].rsplit("#", 1)[-1]
        return BASE_URL + lid + ".html"

    def best_label_for_f2(f2_uri: URIRef) -> str:
        """Bevorzugt deutsches oder englisches rdfs:label, dann URI-Fragment."""
        en = de = any_lbl = None
        for _, _, lbl in g.triples((f2_uri, RDFS.label, None)):
            lang = getattr(lbl, "language", None)
            if lang == "de":   de      = str(lbl)
            elif lang == "en": en      = str(lbl)
            else:              any_lbl = str(lbl)
        raw = de or en or any_lbl
        if raw is None:
            return str(f2_uri).rstrip("/").rsplit("/", 1)[-1]
        return clean_label(raw)

    top_nodes_sorted = sorted(
        int31_to_feats.items(),
        key=lambda x: (-len(x[1]), str(x[0]))
    )

    TOP_PER_TYPE = 20
    seen_uris: set[URIRef] = set()
    top_nodes: list[tuple] = []

    for rel_type_key in ("reception", "mixed", "sappho"):
        count = 0
        for node_uri, feats in top_nodes_sorted:
            if node_uri in seen_uris:
                continue
            related_all   = [obj for _, _, obj in g.triples((node_uri, R24_hasRelatedEntity, None))]
            related_check = [u for u in related_all
                             if "/textpassage/" not in str(u).lower()
                             and u in (sappho_f2 | reception_f2)]
            hs = any(f2 in sappho_f2    for f2 in related_check)
            hr = any(f2 in reception_f2 for f2 in related_check)
            if hs and hr:   rt = "mixed"
            elif hs:        rt = "sappho"
            else:           rt = "reception"
            if rt != rel_type_key:
                continue
            top_nodes.append((node_uri, feats, rt))
            seen_uris.add(node_uri)
            count += 1
            if count >= TOP_PER_TYPE:
                break
        print(f"  Stat9 – {rel_type_key}: {count} Knoten exportiert", file=sys.stderr)

    print(f"  Stat9 – Top-{TOP_PER_TYPE} je relType exportiert, gesamt: {len(top_nodes)}",
          file=sys.stderr)

    # relType-Verteilung
    from collections import Counter as _Counter
    rel_type_counts: dict[str, int] = _Counter()
    for node_uri, feats in top_nodes_sorted:
        related_all = [obj for _, _, obj in g.triples((node_uri, R24_hasRelatedEntity, None))]
        related_f2_check = [u for u in related_all
                             if "/textpassage/" not in str(u).lower()
                             and u in (sappho_f2 | reception_f2)]
        hs = any(f2 in sappho_f2    for f2 in related_f2_check)
        hr = any(f2 in reception_f2 for f2 in related_f2_check)
        if hs and hr:   rel_type_counts["mixed"]     += 1
        elif hs:        rel_type_counts["sappho"]    += 1
        else:           rel_type_counts["reception"] += 1
    print(f"  Stat9 – relType-Verteilung (alle {len(top_nodes_sorted)} Knoten): "
          f"{dict(rel_type_counts)}", file=sys.stderr)

    top_nodes_el = ET.SubElement(root_el, "int31TopNodes")
    top_nodes_el.set("nTotal", str(len(int31_to_feats)))

    for node_uri, feats, rel_type in top_nodes:
        # Verbundene F2 – Textpassagen herausfiltern
        related_f2s_all = sorted(
            {obj for _, _, obj in g.triples((node_uri, R24_hasRelatedEntity, None))},
            key=lambda u: str(u)
        )
        related_f2s = [u for u in related_f2s_all
                       if "/textpassage/" not in str(u).lower()
                       and u in (sappho_f2 | reception_f2)]

        # Karten-Label
        text_labels_for_title = [best_label_for_f2(f2) for f2 in related_f2s]
        card_label = " × ".join(text_labels_for_title) if text_labels_for_title else str(node_uri).split("/")[-1]

        node_el = ET.SubElement(top_nodes_el, "node")
        node_el.set("uri",       str(node_uri))
        node_el.set("cardLabel", card_label)
        node_el.set("nFeats",    str(len(feats)))
        node_el.set("nTexts",    str(len(related_f2s)))
        node_el.set("relType",   rel_type)

        texts_el = ET.SubElement(node_el, "connectedTexts")
        for f2 in related_f2s:
            te = ET.SubElement(texts_el, "text")
            te.set("uri",      str(f2))
            te.set("label",    best_label_for_f2(f2))
            te.set("pageUrl",  f2_page_url(f2))
            te.set("isSappho", "true" if f2 in sappho_f2 else "false")

        # Features und Textpassagen, die die Ähnlichkeit begründen
        feats_el = ET.SubElement(node_el, "basisFeatures")
        feats_el.set("n", str(len(feats)))
        for feat_uri in sorted(feats, key=lambda u: get_label(u).lower()):
            ft = int31_ftype(feat_uri)
            be = ET.SubElement(feats_el, "feat")
            be.set("uri",   str(feat_uri))
            be.set("label", get_label(feat_uri))
            be.set("ftype", ft)

    print(f"  INT31TopNodes: Top-{TOP_PER_TYPE} je relType in XML geschrieben", file=sys.stderr)

    # ── Statistik 10: Durchschnittliche intertextuelle Beziehungen & gemeinsame Phänomene ──

    f2_to_int31: dict[URIRef, set[URIRef]] = defaultdict(set)
    for node_uri in int31_to_feats:
        related_all = [obj for _, _, obj in g.triples((node_uri, R24_hasRelatedEntity, None))]
        for obj in related_all:
            if "/textpassage/" not in str(obj).lower() and obj in (sappho_with_act | reception_with_act):
                f2_to_int31[obj].add(node_uri)

    sappho_int31_counts    = [len(f2_to_int31.get(f2, set())) for f2 in sappho_with_act]
    reception_int31_counts = [len(f2_to_int31.get(f2, set())) for f2 in reception_with_act]

    avg_sappho_int31    = round(sum(sappho_int31_counts)    / len(sappho_int31_counts),    2) if sappho_int31_counts    else 0.0
    avg_reception_int31 = round(sum(reception_int31_counts) / len(reception_int31_counts), 2) if reception_int31_counts else 0.0

    def make_histogram(counts: list, buckets: list) -> list:
        result = []
        for lo, hi in buckets:
            if hi is None:
                n = sum(1 for c in counts if c >= lo)
            else:
                n = sum(1 for c in counts if lo <= c < hi)
            result.append(n)
        return result

    INT31_BUCKETS = [(0,10),(10,25),(25,50),(50,100),(100,150),(150,200),(200,None)]

    sappho_int31_hist    = make_histogram(sappho_int31_counts,    INT31_BUCKETS)
    reception_int31_hist = make_histogram(reception_int31_counts, INT31_BUCKETS)

    f2_shared_phenom_counts: dict[URIRef, list[int]] = defaultdict(list)
    for node_uri, feats in int31_to_feats.items():
        related_f2s = [
            obj for _, _, obj in g.triples((node_uri, R24_hasRelatedEntity, None))
            if "/textpassage/" not in str(obj).lower()
            and obj in (sappho_with_act | reception_with_act)
        ]
        n_feats = len(feats)
        for f2 in related_f2s:
            f2_shared_phenom_counts[f2].append(n_feats)

    def avg_shared(f2_set):
        vals = []
        for f2 in f2_set:
            counts_list = f2_shared_phenom_counts.get(f2, [])
            if counts_list:
                vals.append(sum(counts_list) / len(counts_list))
        return round(sum(vals) / len(vals), 2) if vals else 0.0

    avg_sappho_shared    = avg_shared(sappho_with_act)
    avg_reception_shared = avg_shared(reception_with_act)

    sappho_shared_hist_vals    = []
    reception_shared_hist_vals = []
    for f2 in sappho_with_act:
        lst = f2_shared_phenom_counts.get(f2, [])
        sappho_shared_hist_vals.append(round(sum(lst)/len(lst)) if lst else 0)
    for f2 in reception_with_act:
        lst = f2_shared_phenom_counts.get(f2, [])
        reception_shared_hist_vals.append(round(sum(lst)/len(lst)) if lst else 0)

    SHARED_BUCKETS = [(0,1),(1,2),(2,3),(3,4),(4,5),(5,None)]
    sappho_shared_hist    = make_histogram(sappho_shared_hist_vals,    SHARED_BUCKETS)
    reception_shared_hist = make_histogram(reception_shared_hist_vals, SHARED_BUCKETS)

    print(f"  Stat10 – Ø INT31/Sappho: {avg_sappho_int31}, Ø INT31/Rezeption: {avg_reception_int31}", file=sys.stderr)
    print(f"  Stat10 – Ø Shared/Sappho: {avg_sappho_shared}, Ø Shared/Rezeption: {avg_reception_shared}", file=sys.stderr)

    # XML
    stat10_el = ET.SubElement(root_el, "stat10AvgRelations")
    stat10_el.set("avgSapphoInt31",     str(avg_sappho_int31))
    stat10_el.set("avgReceptionInt31",  str(avg_reception_int31))
    stat10_el.set("avgSapphoShared",    str(avg_sappho_shared))
    stat10_el.set("avgReceptionShared", str(avg_reception_shared))
    stat10_el.set("nSappho",            str(n_sappho))
    stat10_el.set("nReception",         str(n_reception))

    int31hist_el = ET.SubElement(stat10_el, "int31Hist")
    BUCKET_LABELS = ["0–9","10–24","25–49","50–99","100–149","150–199","200+"]
    for i, (lo, hi) in enumerate(INT31_BUCKETS):
        b_el = ET.SubElement(int31hist_el, "bucket")
        b_el.set("label",     BUCKET_LABELS[i])
        b_el.set("sappho",    str(sappho_int31_hist[i]))
        b_el.set("reception", str(reception_int31_hist[i]))

    sharedhist_el = ET.SubElement(stat10_el, "sharedHist")
    SHARED_LABELS = ["0","1","2","3","4","5+"]
    for i, (lo, hi) in enumerate(SHARED_BUCKETS):
        b_el = ET.SubElement(sharedhist_el, "bucket")
        b_el.set("label",     SHARED_LABELS[i])
        b_el.set("sappho",    str(sappho_shared_hist[i]))
        b_el.set("reception", str(reception_shared_hist[i]))

    print(f"  Stat10 in XML geschrieben.", file=sys.stderr)

    # ── Statistik 11–14: Gender ───────────────────────────────────────────────
    #
    # Das Geschlecht hängt als E55_Type an E21_Person via P2_has_type.
    # URI-Muster: .../gender/Q6581097  (männlich)
    #             .../gender/Q6581072  (weiblich)
    #             alles andere         (unbekannt/divers)
    #
    # Autor_innen werden über P14i_performed → F28 / F30 → F2_Expression
    # mit den Rezeptionszeugnissen verknüpft.
    # Wir nutzen die bereits geladenen Tripel; kein neues Parsen nötig.

    E21_Person       = ECRM["E21_Person"]
    P2_has_type_prop = ECRM["P2_has_type"]          # alias (P2_has_type already defined above)
    P14i_performed   = ECRM["P14i_performed"]

    GENDER_MALE    = "https://sappho-digital.com/gender/Q6581097"
    GENDER_FEMALE  = "https://sappho-digital.com/gender/Q6581072"

    def gender_key(person_uri: URIRef) -> str:
        """Gibt 'male', 'female' oder 'unknown' zurück."""
        for _, _, t in g.triples((person_uri, P2_has_type_prop, None)):
            ts = str(t)
            if ts == GENDER_MALE:
                return "male"
            if ts == GENDER_FEMALE:
                return "female"
        return "unknown"

    # Alle E21_Person-Knoten mit Geschlecht
    all_persons: dict[URIRef, str] = {}
    for person in g.subjects(RDF.type, E21_Person):
        all_persons[person] = gender_key(person)

    n_male    = sum(1 for g2 in all_persons.values() if g2 == "male")
    n_female  = sum(1 for g2 in all_persons.values() if g2 == "female")
    n_unknown = sum(1 for g2 in all_persons.values() if g2 == "unknown")
    print(f"  Gender – männlich: {n_male}, weiblich: {n_female}, unbekannt: {n_unknown}",
          file=sys.stderr)

    # Rezeptionszeugnis → Geschlecht(er) der Autor_innen
    # Ein Zeugnis kann mehrere Autor_innen haben → wir speichern alle zugehörigen Geschlechter.
    # Zuordnung: E21_Person –P14i_performed–> (F28_Expression_Creation | F30_Manifestation_Creation)
    # Diese Knoten sind via R17i_was_created_by / R24i_was_created_through mit F2 verknüpft.
    # Einfacherer Weg: Person –P14i_performed–> X, schauen ob X in g zu einer F2 führt.
    # Wir bauen: f2_uri → set of gender_keys

    f2_genders: dict[URIRef, set[str]] = defaultdict(set)

    for person, gk in all_persons.items():
        for _, _, performed in g.triples((person, P14i_performed, None)):
            # performed kann F28_ExpressionCreation oder F30_ManifestationCreation sein
            # F28 → F2 via R17i_was_created_by (inverse: F2 –R17i_was_created_by–> F28)
            for f2 in g.subjects(LRMOO["R17i_was_created_by"], performed):
                if f2 in reception_f2:
                    f2_genders[f2].add(gk)
            # Manche Zeugnisse hängen über F30 → F3 → F2 (R4i_is_embodied_in)
            # F30 hat P94i_was_created_by / R24i_was_created_through  → F3 → F4i_is_embodied_in → F2
            # Alternativ: performed ist eine F28 die über R4i_is_embodied_in mit F3 verbunden ist
            # Direkter: performed → R17i_was_created_by_inverse gibt F2
            # Wir prüfen auch ob performed selbst eine bekannte F2 ist (Sonderfall)
            if performed in reception_f2:
                f2_genders[performed].add(gk)

    # Für Zeugnisse ohne Autor_innen-Treffer: explizit "unknown" setzen
    for f2 in reception_with_act:
        if f2 not in f2_genders:
            f2_genders[f2].add("unknown")

    print(f"  Gender – Rezeptionszeugnisse mit Genderzuordnung: {len(f2_genders)}",
          file=sys.stderr)

    # ── Stat 11: Gesamtverteilung ─────────────────────────────────────────────
    # Zählung auf Autoren-Ebene (eindeutige Personen)
    gender_el = ET.SubElement(root_el, "genderStats")
    gender_el.set("nMale",    str(n_male))
    gender_el.set("nFemale",  str(n_female))
    gender_el.set("nUnknown", str(n_unknown))
    gender_el.set("nTotal",   str(len(all_persons)))

    # Zählung auf Zeugnisebene (ein Zeugnis zählt für alle Geschlechter seiner Autor_innen;
    # Zeugnisse mit gemischtem Autorschaft erscheinen in mehreren Gruppen)
    texts_by_gender: dict[str, set[URIRef]] = {"male": set(), "female": set(), "unknown": set()}
    for f2, genders in f2_genders.items():
        if f2 not in reception_with_act:
            continue
        for gk in genders:
            texts_by_gender[gk].add(f2)

    gender_el.set("nTextsMale",    str(len(texts_by_gender["male"])))
    gender_el.set("nTextsFemale",  str(len(texts_by_gender["female"])))
    gender_el.set("nTextsUnknown", str(len(texts_by_gender["unknown"])))
    gender_el.set("nTextsTotal",   str(len(reception_with_act)))

    # ── Stat 12: Zeitliche Verteilung nach Geschlecht ─────────────────────────
    # Alle Texte aller Autor_innen (nicht nur analysierte Zeugnisse).
    # Pro Jahrzehnt werden DISTINKTE Texte pro Geschlecht gezählt.
    # Ein Text mit Autor_innen beider Geschlechter zählt für jedes Geschlecht einmal,
    # aber nie doppelt für dasselbe Geschlecht.
    decades_gender_seen: set[str] = set()

    # f2 → set of gender_keys für ALLE Texte (nicht nur analysierte)
    # Nur via R17i_was_created_by (keine Doppelzählung über performed direkt)
    all_f2_genders: dict[URIRef, set[str]] = defaultdict(set)
    for person, gk in all_persons.items():
        for _, _, performed in g.triples((person, P14i_performed, None)):
            for f2 in g.subjects(LRMOO["R17i_was_created_by"], performed):
                if "/bibl_sappho_" not in str(f2):
                    all_f2_genders[f2].add(gk)

    print(f"  Gender – Zeitverlauf: {len(all_f2_genders)} Texte mit Genderzuordnung",
          file=sys.stderr)

    # Pro Jahrzehnt: distinkte F2-URIs pro Geschlecht sammeln, dann zählen
    decade_gender_texts: dict[str, dict[str, set]] = defaultdict(
        lambda: {"male": set(), "female": set(), "unknown": set()}
    )
    for f2, genders in all_f2_genders.items():
        year = get_year_for_f2(f2)
        if year is None:
            continue
        dec = decade(year)
        decades_gender_seen.add(dec)
        for gk in genders:
            decade_gender_texts[dec][gk].add(f2)

    decade_gender_counts: dict[str, dict[str, int]] = {
        dec: {gk: len(texts) for gk, texts in gk_dict.items()}
        for dec, gk_dict in decade_gender_texts.items()
    }

    sorted_decades_gender = sorted(
        [d for d in decades_gender_seen if d != "n/a"], key=decade_sort
    )
    if "n/a" in decades_gender_seen:
        sorted_decades_gender.append("n/a")

    timedist_el = ET.SubElement(gender_el, "genderTimeDist")
    for dec in sorted_decades_gender:
        d_el = ET.SubElement(timedist_el, "decade")
        d_el.set("key",     dec)
        d_el.set("male",    str(decade_gender_counts[dec]["male"]))
        d_el.set("female",  str(decade_gender_counts[dec]["female"]))
        d_el.set("unknown", str(decade_gender_counts[dec]["unknown"]))

    # ── Stat 13: Phänomene nach Geschlecht ───────────────────────────────────
    # Analog zu genreDist (Stat 4), aber Gattung → Geschlecht.
    # Ein Phänomen kann von Texten mehrerer Geschlechter aktualisiert werden.
    gender_phenom_feat:   dict[URIRef, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    gender_phenom_labels: dict[URIRef, str] = {}
    gender_phenom_ftype:  dict[URIRef, str] = {}

    for f2 in reception_with_act:
        genders = f2_genders.get(f2, {"unknown"})
        feats_here = set(reception_idx.get(f2, set())) | get_work_refs(f2)
        for feat_uri in feats_here:
            for gk in genders:
                gender_phenom_feat[feat_uri][gk] += 1
            if feat_uri not in gender_phenom_labels:
                gender_phenom_labels[feat_uri] = get_label(feat_uri)
                gender_phenom_ftype[feat_uri]  = feature_type(str(feat_uri)) or "other"

    def feat_gender_total(fu: URIRef) -> int:
        return sum(gender_phenom_feat[fu].values())

    sorted_feats_gender = sorted(
        gender_phenom_feat.keys(),
        key=lambda fu: (-feat_gender_total(fu), gender_phenom_labels.get(fu, "").lower())
    )

    gender_phenom_n: dict[str, int] = {
        "male":    len(texts_by_gender["male"]),
        "female":  len(texts_by_gender["female"]),
        "unknown": len(texts_by_gender["unknown"]),
    }

    print(f"  GenderPhenom – Phänomene: {len(sorted_feats_gender)}", file=sys.stderr)

    gpfeat_el = ET.SubElement(gender_el, "genderPhenomDist")
    gpfeat_el.set("nFeatures", str(len(sorted_feats_gender)))
    for gk, gn in gender_phenom_n.items():
        gpfeat_el.set(f"n{gk.capitalize()}", str(gn))

    gfeat_container = ET.SubElement(gpfeat_el, "features")
    for feat_uri in sorted_feats_gender:
        fe = ET.SubElement(gfeat_container, "feature")
        fe.set("uri",   str(feat_uri))
        fe.set("label", gender_phenom_labels.get(feat_uri, str(feat_uri).split("/")[-1]))
        fe.set("ftype", gender_phenom_ftype.get(feat_uri, "other"))
        fe.set("total", str(feat_gender_total(feat_uri)))
        for gk in ("male", "female", "unknown"):
            cnt = gender_phenom_feat[feat_uri].get(gk, 0)
            if cnt:
                gc_el = ET.SubElement(fe, "genderCell")
                gc_el.set("gender", gk)
                gc_el.set("n",      str(cnt))

    # ── Stat 14: Gattung × Geschlecht ─────────────────────────────────────────
    # Welche Gattungen dominieren bei welchem Geschlecht?
    genre_gender_counts: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    genres_gender_seen: set[str] = set()

    for f2 in reception_with_act:
        gen     = get_genre(f2)
        genders = f2_genders.get(f2, {"unknown"})
        genres_gender_seen.add(gen)
        for gk in genders:
            genre_gender_counts[gen][gk] += 1

    sorted_genres_gender = [g2 for g2 in genre_order if g2 in genres_gender_seen]
    sorted_genres_gender += [g2 for g2 in sorted(genres_gender_seen) if g2 not in genre_order]

    gg_el = ET.SubElement(gender_el, "genreGenderDist")
    gg_el.set("nGenres", str(len(sorted_genres_gender)))
    for gen in sorted_genres_gender:
        g_el = ET.SubElement(gg_el, "genre")
        g_el.set("key",     gen)
        g_el.set("male",    str(genre_gender_counts[gen]["male"]))
        g_el.set("female",  str(genre_gender_counts[gen]["female"]))
        g_el.set("unknown", str(genre_gender_counts[gen]["unknown"]))

    print(f"  Gender-Statistiken in XML geschrieben.", file=sys.stderr)

    tree = ET.ElementTree(root_el)
    ET.indent(tree, space="  ")
    tree.write(xml_out, encoding="utf-8", xml_declaration=True)
    print(f"Geschrieben: {xml_out}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Verwendung: {sys.argv[0]} <input.ttl> <output.xml>", file=sys.stderr)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])