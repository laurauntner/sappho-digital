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
        s = re.sub(r'\s*\(topos\)\s*$',  '', s)
        s = re.sub(r'\s*\(place\)\s*$',  '', s)
        s = re.sub(r'\s*\(person\)\s*$', '', s)
        s = re.sub(r'\s*\(work\)\s*$',   '', s)
        return s.strip()

    def get_label(uri: URIRef) -> str:
        en = de = any_label = None
        for _, _, label in g.triples((uri, RDFS.label, None)):
            lang = getattr(label, "language", None)
            if lang == "en":   en        = str(label)
            elif lang == "de": de        = str(label)
            else:              any_label = str(label)
        raw = en or de or any_label or str(uri).split("/")[-1]
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

    tree = ET.ElementTree(root_el)
    ET.indent(tree, space="  ")
    tree.write(xml_out, encoding="utf-8", xml_declaration=True)
    print(f"Geschrieben: {xml_out}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Verwendung: {sys.argv[0]} <input.ttl> <output.xml>", file=sys.stderr)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])