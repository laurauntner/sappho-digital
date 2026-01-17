from pathlib import Path
import sys
import re
from rdflib import Graph, Namespace, URIRef, BNode, Literal, RDF, RDFS, OWL
from rdflib.collection import Collection

# Namespaces

SKOS = Namespace("http://www.w3.org/2004/02/skos/core#")
CRM = Namespace("http://www.cidoc-crm.org/cidoc-crm/")
ECRM = Namespace("http://erlangen-crm.org/current/")
FRBROO = Namespace("http://iflastandards.info/ns/fr/frbr/frbroo/")
EFRBROO = Namespace("http://erlangen-crm.org/efrbroo/")
LRMOO = Namespace("http://www.cidoc-crm.org/lrmoo/")
INTRO = Namespace("https://w3id.org/lso/intro/currentbeta#")
PROV = Namespace("http://www.w3.org/ns/prov#")
SAPPHO = Namespace("https://sappho-digital.com/")
SAPPHO_PROP = Namespace("https://sappho-digital.com/property/")

BIBO = Namespace("http://purl.org/ontology/bibo/")
CITO = Namespace("http://purl.org/spar/cito/")
DC = Namespace("http://purl.org/dc/terms/")
DCEL = Namespace("http://purl.org/dc/elements/1.1/")
DOCO = Namespace("http://purl.org/spar/doco/")
FABIO = Namespace("http://purl.org/spar/fabio/")
FOAF = Namespace("http://xmlns.com/foaf/0.1/")
GOLEM = Namespace("https://ontology.golemlab.eu/")
DRACOR = Namespace("http://dracor.org/ontology#")
INTERTEXT_AB = Namespace("https://intertextuality.org/abstract#")
INTERTEXT_TX = Namespace("https://intertextuality.org/extensions/text#")
INTERTEXT_AF = Namespace("https://intertextuality.org/extensions/artifacts#")
INTERTEXT_MT = Namespace("https://intertextuality.org/extensions/motifs#")
MIMOTEXT = Namespace("http://data.mimotext.uni-trier.de/entity/")
POSTDATA_CORE = Namespace("http://postdata.linhd.uned.es/ontology/postdata-core#") # https://raw.githubusercontent.com/linhd-postdata/core-ontology/refs/heads/master/postdata-core.owl
POSTDATA_ANALYSIS = Namespace("http://postdata.linhd.uned.es/ontology/postdata-poeticAnalysis#") # https://raw.githubusercontent.com/linhd-postdata/literaryAnalysis-ontology/refs/heads/master/postdata-literaryAnalysisElements.owl
SCHEMA = Namespace("https://schema.org/")
URW = Namespace("https://purl.archive.org/urwriters#")
URB = Namespace("https://purl.archive.org/urbooks#")

# Helpers

def merge_with_precedence(base_dir: Path, out_path: Path) -> Graph:
    order = [
        "authors.ttl",
        "works.ttl",
        "fragments.ttl",
        "analysis.ttl",
        "relations.ttl",
    ]

    files = []
    for name in order:
        p = (base_dir / name).resolve()
        if not p.exists():
            raise FileNotFoundError(f"{name} fehlt im Eingabeordner {base_dir}")
        if p == out_path:
            continue
        files.append(p)

    g_merged = Graph()
    bind_namespaces(g_merged)

    for path in files:
        g_tmp = Graph()
        try:
            g_tmp.parse(path.as_posix(), format="turtle")
        except Exception as e:
            print(f"[WARN] Konnte {path.name} nicht parsen: {e}")
            continue

        for s in set(s for s in g_tmp.subjects() if isinstance(s, URIRef)):
            preds_in_tmp = {p for _, p, _ in g_tmp.triples((s, None, None))}
            for p in preds_in_tmp:
                g_merged.remove((s, p, None))

        for t in g_tmp:
            g_merged.add(t)

        print(f"[OK] Gemerged: {path.name} ({len(g_tmp)} Tripel)")

    return g_merged

def extract_year(label_lit):
    try:
        return int(str(label_lit))
    except Exception:
        m = re.search(r"(-?\d{3,4})", str(label_lit))
        return int(m.group(1)) if m else None

def get_creation_year(g, expr):
    # Expression_Creation
    for ec in g.objects(expr, LRMOO.R17i_was_created_by):
        for ts in g.objects(ec, ECRM["P4_has_time-span"]):
            y = extract_year(g.value(ts, RDFS.label))
            if y is not None:
                return y
    # Manifestation_Creation fallback
    for manif in g.objects(expr, LRMOO.R4i_is_embodied_in):
        for mc in g.subjects(LRMOO.R24_created, manif):
            for ts in g.objects(mc, ECRM["P4_has_time-span"]):
                y = extract_year(g.value(ts, RDFS.label))
                if y is not None:
                    return y
    return None

def bind_namespaces(g: Graph):
    # Kern
    g.bind("skos", SKOS, override=True)
    g.bind("crm",  CRM,  override=True)
    g.bind("ecrm", ECRM, override=True)
    g.bind("frbroo", FRBROO, override=True)
    g.bind("efrbroo", EFRBROO, override=True)
    g.bind("lrmoo", LRMOO, override=True)
    g.bind("intro", INTRO, override=True)
    g.bind("prov", PROV, override=True)
    g.bind("dc", DC, override=True)

    # Sonstige
    g.bind("bibo", BIBO, override=True)
    g.bind("cito", CITO, override=True)
    g.bind("doco", DOCO, override=True)
    g.bind("fabio", FABIO, override=True)
    g.bind("foaf", FOAF, override=True)
    g.bind("golem", GOLEM, override=True)
    g.bind("dracor", DRACOR, override=True)
    g.bind("intertext_ab", INTERTEXT_AB, override=True)
    g.bind("intertext_tx", INTERTEXT_TX, override=True)
    g.bind("intertext_af", INTERTEXT_AF, override=True)
    g.bind("intertext_mt", INTERTEXT_MT, override=True)
    g.bind("mimotext", MIMOTEXT, override=True)
    g.bind("POSTDATA_core", POSTDATA_CORE, override=True)
    g.bind("POSTDATA_analysis", POSTDATA_ANALYSIS, override=True)
    g.bind("schema", SCHEMA, override=True)
    g.bind("urw", URW, override=True)
    g.bind("urb", URB, override=True)

    g.bind("sappho_prop", SAPPHO_PROP, override=True)

# ECRM, EFRBROO etc.
ALIGN_ROWS = [
    ("ECRM.term(\"E21_Person\")", "OWL.equivalentClass", "CRM.term(\"E21_Person\")"),
    ("ECRM.term(\"E35_Title\")", "OWL.equivalentClass", "CRM.term(\"E35_Title\")"),
    ("ECRM.term(\"E36_Visual_Item\")", "OWL.equivalentClass", "CRM.term(\"E36_Visual_Item\")"),
    ("ECRM.term(\"E38_Image\")", "OWL.equivalentClass", "CRM.term(\"E38_Image\")"),
    ("ECRM.term(\"E40_Legal_Body\")", "OWL.equivalentClass", "CRM.term(\"E40_Legal_Body\")"),
    ("ECRM.term(\"E42_Identifier\")", "OWL.equivalentClass", "CRM.term(\"E42_Identifier\")"),
    ("ECRM.term(\"E52_Time-Span\")", "OWL.equivalentClass", "CRM.term(\"E52_Time-Span\")"),
    ("ECRM.term(\"E53_Place\")", "OWL.equivalentClass", "CRM.term(\"E53_Place\")"),
    ("ECRM.term(\"E55_Type\")", "OWL.equivalentClass", "CRM.term(\"E55_Type\")"),
    ("ECRM.term(\"E62_String\")", "OWL.equivalentClass", "CRM.term(\"E62_String\")"),
    ("ECRM.term(\"E67_Birth\")", "OWL.equivalentClass", "CRM.term(\"E67_Birth\")"),
    ("ECRM.term(\"E69_Death\")", "OWL.equivalentClass", "CRM.term(\"E69_Death\")"),
    ("ECRM.term(\"E73_Information_Object\")", "OWL.equivalentClass", "CRM.term(\"E73_Information_Object\")"),
    ("ECRM.term(\"E82_Actor_Appellation\")", "OWL.equivalentClass", "CRM.term(\"E82_Actor_Appellation\")"),
    ("ECRM.term(\"E90_Symbolic_Object\")", "OWL.equivalentClass", "CRM.term(\"E90_Symbolic_Object\")"),
    ("lrmoo.F2_Expression", "OWL.equivalentClass", "efrbroo.F2_Expression"),
    ("lrmoo.F2_Expression", "OWL.equivalentClass", "frbroo.F2_Expression"),
    ("LRMOO.term(\"F1_Work\")", "OWL.equivalentClass", "EFRBROO.term(\"F1_Work\")"),
    ("LRMOO.term(\"F1_Work\")", "OWL.equivalentClass", "FRBROO.term(\"F1_Work\")"),
    ("LRMOO.term(\"F27_Work_Creation\")", "OWL.equivalentClass", "EFRBROO.term(\"F27_Work_Conception\")"),
    ("LRMOO.term(\"F27_Work_Creation\")", "OWL.equivalentClass", "FRBROO.term(\"F27_Work_Conception\")"),
    ("LRMOO.term(\"F28_Expression_Creation\")", "OWL.equivalentClass", "EFRBROO.term(\"F28_Expression_Creation\")"),
    ("LRMOO.term(\"F28_Expression_Creation\")", "OWL.equivalentClass", "FRBROO.term(\"F28_Expression_Creation\")"),
    ("LRMOO.term(\"F2_Expression\")", "OWL.equivalentClass", "EFRBROO.term(\"F2_Expression\")"),
    ("LRMOO.term(\"F2_Expression\")", "OWL.equivalentClass", "FRBROO.term(\"F2_Expression\")"),
    ("LRMOO.term(\"F30_Manifestation_Creation\")", "OWL.equivalentClass", "EFRBROO.term(\"F30_Publication_Event\")"),
    ("LRMOO.term(\"F30_Manifestation_Creation\")", "OWL.equivalentClass", "FRBROO.term(\"F30_Publication_Event\")"),
    ("LRMOO.term(\"F32_Item_Production_Event\")", "OWL.equivalentClass", "EFRBROO.term(\"F32_Carrier_Production_Event\")"),
    ("LRMOO.term(\"F32_Item_Production_Event\")", "OWL.equivalentClass", "FRBROO.term(\"F32_Carrier_Production_Event\")"),
    ("LRMOO.term(\"F3_Manifestation\")", "OWL.equivalentClass", "EFRBROO.term(\"F3_Manifestation_Product_Type\")"),
    ("LRMOO.term(\"F3_Manifestation\")", "OWL.equivalentClass", "FRBROO.term(\"F3_Manifestation_Product_Type\")"),
    ("LRMOO.term(\"F5_Item\")", "OWL.equivalentClass", "EFRBROO.term(\"F5_Item\")"),
    ("LRMOO.term(\"F5_Item\")", "OWL.equivalentClass", "FRBROO.term(\"F5_Item\")"),
    ("ECRM.term(\"P100_was_death_of\")", "OWL.equivalentProperty", "CRM.term(\"P100_was_death_of\")"),
    ("ECRM.term(\"P100i_died_in\")", "OWL.equivalentProperty", "CRM.term(\"P100i_died_in\")"),
    ("ECRM.term(\"P131_is_identified_by\")", "OWL.equivalentProperty", "CRM.term(\"P131_is_identified_by\")"),
    ("ECRM.term(\"P131i_identifies\")", "OWL.equivalentProperty", "CRM.term(\"P131i_identifies\")"),
    ("ECRM.term(\"P138_represents\")", "OWL.equivalentProperty", "CRM.term(\"P138_represents\")"),
    ("ECRM.term(\"P138i_has_representation\")", "OWL.equivalentProperty", "CRM.term(\"P138i_has_representation\")"),
    ("ECRM.term(\"P1_is_identified_by\")", "OWL.equivalentProperty", "CRM.term(\"P1_is_identified_by\")"),
    ("ECRM.term(\"P1i_identifies\")", "OWL.equivalentProperty", "CRM.term(\"P1i_identifies\")"),
    ("ECRM.term(\"P2_has_type\")", "OWL.equivalentProperty", "CRM.term(\"P2_has_type\")"),
    ("ECRM.term(\"P2i_is_type_of\")", "OWL.equivalentProperty", "CRM.term(\"P2i_is_type_of\")"),
    ("ECRM.term(\"P4_has_time-span\")", "OWL.equivalentProperty", "CRM.term(\"P4_has_time-span\")"),
    ("ECRM.term(\"P4i_is_time-span_of\")", "OWL.equivalentProperty", "CRM.term(\"P4i_is_time-span_of\")"),
    ("ECRM.term(\"P65_shows_visual_item\")", "OWL.equivalentProperty", "CRM.term(\"P65_shows_visual_item\")"),
    ("ECRM.term(\"P65i_is_shown_by\")", "OWL.equivalentProperty", "CRM.term(\"P65i_is_shown_by\")"),
    ("ECRM.term(\"P7_took_place_at\")", "OWL.equivalentProperty", "CRM.term(\"P7_took_place_at\")"),
    ("ECRM.term(\"P7i_witnessed\")", "OWL.equivalentProperty", "CRM.term(\"P7i_witnessed\")"),
    ("ECRM.term(\"P98_brought_into_life\")", "OWL.equivalentProperty", "CRM.term(\"P98_brought_into_life\")"),
    ("ECRM.term(\"P98i_was_born\")", "OWL.equivalentProperty", "CRM.term(\"P98i_was_born\")"),
    ("ECRM.term(\"P102_has_title\")", "OWL.equivalentProperty", "CRM.term(\"P102_has_title\")"),
    ("ECRM.term(\"P102i_is_title_of\")", "OWL.equivalentProperty", "CRM.term(\"P102i_is_title_of\")"),
    ("ECRM.term(\"P131_is_identified_by\")", "OWL.equivalentProperty", "CRM.term(\"P131_is_identified_by\")"),
    ("ECRM.term(\"P131i_identifies\")", "OWL.equivalentProperty", "CRM.term(\"P131i_identifies\")"),
    ("ECRM.term(\"P138_represents\")", "OWL.equivalentProperty", "CRM.term(\"P138_represents\")"),
    ("ECRM.term(\"P138i_has_representation\")", "OWL.equivalentProperty", "CRM.term(\"P138i_has_representation\")"),
    ("ECRM.term(\"P14_carried_out_by\")", "OWL.equivalentProperty", "CRM.term(\"P14_carried_out_by\")"),
    ("ECRM.term(\"P14i_performed\")", "OWL.equivalentProperty", "CRM.term(\"P14i_performed\")"),
    ("ECRM.term(\"P190_has_symbolic_content\")", "OWL.equivalentProperty", "CRM.term(\"P190_has_symbolic_content\")"),
    ("ECRM.term(\"P190i_is_content_of\")", "OWL.equivalentProperty", "CRM.term(\"P190i_is_content_of\")"),
    ("ECRM.term(\"P1_is_identified_by\")", "OWL.equivalentProperty", "CRM.term(\"P1_is_identified_by\")"),
    ("ECRM.term(\"P1i_identifies\")", "OWL.equivalentProperty", "CRM.term(\"P1i_identifies\")"),
    ("ECRM.term(\"P2_has_type\")", "OWL.equivalentProperty", "CRM.term(\"P2_has_type\")"),
    ("ECRM.term(\"P2i_is_type_of\")", "OWL.equivalentProperty", "CRM.term(\"P2i_is_type_of\")"),
    ("ECRM.term(\"P4_has_time-span\")", "OWL.equivalentProperty", "CRM.term(\"P4_has_time-span\")"),
    ("ECRM.term(\"P4i_is_time-span_of\")", "OWL.equivalentProperty", "CRM.term(\"P4i_is_time-span_of\")"),
    ("ECRM.term(\"P7_took_place_at\")", "OWL.equivalentProperty", "CRM.term(\"P7_took_place_at\")"),
    ("ECRM.term(\"P7i_witnessed\")", "OWL.equivalentProperty", "CRM.term(\"P7i_witnessed\")"),
    ("LRMOO.term(\"R10_has_member\")", "OWL.equivalentProperty", "EFRBROO.term(\"R10_has_member\")"),
    ("LRMOO.term(\"R10i_is_member_of\")", "OWL.equivalentProperty", "EFRBROO.term(\"R10i_is_member_of\")"),
    ("LRMOO.term(\"R16_created\")", "OWL.equivalentProperty", "EFRBROO.term(\"R16_initiated\")"),
    ("LRMOO.term(\"R16_created\")", "OWL.equivalentProperty", "FRBROO.term(\"R16_initiated\")"),
    ("LRMOO.term(\"R16i_was_created_by\")", "OWL.equivalentProperty", "EFRBROO.term(\"R16i_was_initiated_by\")"),
    ("LRMOO.term(\"R16i_was_created_by\")", "OWL.equivalentProperty", "FRBROO.term(\"R16i_was_initiated_by\")"),
    ("LRMOO.term(\"R17_created\")", "OWL.equivalentProperty", "EFRBROO.term(\"R17_created\")"),
    ("LRMOO.term(\"R17_created\")", "OWL.equivalentProperty", "FRBROO.term(\"R17_created\")"),
    ("LRMOO.term(\"R17i_was_created_by\")", "OWL.equivalentProperty", "EFRBROO.term(\"R17i_was_created_by\")"),
    ("LRMOO.term(\"R17i_was_created_by\")", "OWL.equivalentProperty", "FRBROO.term(\"R17i_was_created_by\")"),
    ("LRMOO.term(\"R19_created_a_realisation_of\")", "OWL.equivalentProperty", "EFRBROO.term(\"R19_created_a_realisation_of\")"),
    ("LRMOO.term(\"R19_created_a_realisation_of\")", "OWL.equivalentProperty", "FRBROO.term(\"R19_created_a_realisation_of\")"),
    ("LRMOO.term(\"R19i_was_realised_through\")", "OWL.equivalentProperty", "EFRBROO.term(\"R19i_was_realised_through\")"),
    ("LRMOO.term(\"R19i_was_realised_through\")", "OWL.equivalentProperty", "FRBROO.term(\"R19i_was_realised_through\")"),
    ("LRMOO.term(\"R24_created\")", "OWL.equivalentProperty", "EFRBROO.term(\"R24_created\")"),
    ("LRMOO.term(\"R24_created\")", "OWL.equivalentProperty", "FRBROO.term(\"R24_created\")"),
    ("LRMOO.term(\"R24i_was_created_through\")", "OWL.equivalentProperty", "EFRBROO.term(\"R24i_was_created_through\")"),
    ("LRMOO.term(\"R24i_was_created_through\")", "OWL.equivalentProperty", "FRBROO.term(\"R24i_was_created_through\")"),
    ("LRMOO.term(\"R27_materialized\")", "OWL.equivalentProperty", "EFRBROO.term(\"R27_used_as_source_material\")"),
    ("LRMOO.term(\"R27_materialized\")", "OWL.equivalentProperty", "FRBROO.term(\"R27_used_as_source_material\")"),
    ("LRMOO.term(\"R27i_was_materialized_by\")", "OWL.equivalentProperty", "EFRBROO.term(\"R27i_was_used_by\")"),
    ("LRMOO.term(\"R27i_was_materialized_by\")", "OWL.equivalentProperty", "FRBROO.term(\"R27i_was_used_by\")"),
    ("LRMOO.term(\"R28_produced\")", "OWL.equivalentProperty", "EFRBROO.term(\"R28_produced\")"),
    ("LRMOO.term(\"R28_produced\")", "OWL.equivalentProperty", "FRBROO.term(\"R28_produced\")"),
    ("LRMOO.term(\"R28i_was_produced_by\")", "OWL.equivalentProperty", "EFRBROO.term(\"R28i_was_produced_by\")"),
    ("LRMOO.term(\"R28i_was_produced_by\")", "OWL.equivalentProperty", "FRBROO.term(\"R28i_was_produced_by\")"),
    ("LRMOO.term(\"R3_is_realised_in\")", "OWL.equivalentProperty", "EFRBROO.term(\"R3_is_realised_in\")"),
    ("LRMOO.term(\"R3_is_realised_in\")", "OWL.equivalentProperty", "FRBROO.term(\"R3_is_realised_in\")"),
    ("LRMOO.term(\"R3i_realises\")", "OWL.equivalentProperty", "EFRBROO.term(\"R3i_realises\")"),
    ("LRMOO.term(\"R3i_realises\")", "OWL.equivalentProperty", "FRBROO.term(\"R3i_realises\")"),
    ("LRMOO.term(\"R4_embodies\")", "OWL.equivalentProperty", "EFRBROO.term(\"R4i_comprises_carriers_of\")"),
    ("LRMOO.term(\"R4_embodies\")", "OWL.equivalentProperty", "FRBROO.term(\"R4i_comprises_carriers_of\")"),
    ("LRMOO.term(\"R4i_is_embodied_in\")", "OWL.equivalentProperty", "EFRBROO.term(\"R4_carriers_provided_by\")"),
    ("LRMOO.term(\"R4i_is_embodied_in\")", "OWL.equivalentProperty", "FRBROO.term(\"R4_carriers_provided_by\")"),
    ("LRMOO.term(\"R7_exemplifies\")", "OWL.equivalentProperty", "EFRBROO.term(\"R7_is_example_of\")"),
    ("LRMOO.term(\"R7_exemplifies\")", "OWL.equivalentProperty", "FRBROO.term(\"R7_is_example_of\")"),
    ("LRMOO.term(\"R7i_is_exemplified_by\")", "OWL.equivalentProperty", "EFRBROO.term(\"R7i_has_example\")"),
    ("LRMOO.term(\"R7i_is_exemplified_by\")", "OWL.equivalentProperty", "FRBROO.term(\"R7i_has_example\")"),
    ("ECRM.term(\"P100_was_death_of\")", "OWL.inverseOf", "ECRM.term(\"P100i_died_in\")"),
    ("ECRM.term(\"P100i_died_in\")", "OWL.inverseOf", "ECRM.term(\"P100_was_death_of\")"),
    ("ECRM.term(\"P131_is_identified_by\")", "OWL.inverseOf", "ECRM.term(\"P131i_identifies\")"),
    ("ECRM.term(\"P131i_identifies\")", "OWL.inverseOf", "ECRM.term(\"P131_is_identified_by\")"),
    ("ECRM.term(\"P138_represents\")", "OWL.inverseOf", "ECRM.term(\"P138i_has_representation\")"),
    ("ECRM.term(\"P138i_has_representation\")", "OWL.inverseOf", "ECRM.term(\"P138_represents\")"),
    ("ECRM.term(\"P1_is_identified_by\")", "OWL.inverseOf", "ECRM.term(\"P1i_identifies\")"),
    ("ECRM.term(\"P1i_identifies\")", "OWL.inverseOf", "ECRM.term(\"P1_is_identified_by\")"),
    ("ECRM.term(\"P2_has_type\")", "OWL.inverseOf", "ECRM.term(\"P2i_is_type_of\")"),
    ("ECRM.term(\"P2i_is_type_of\")", "OWL.inverseOf", "ECRM.term(\"P2_has_type\")"),
    ("ECRM.term(\"P4_has_time-span\")", "OWL.inverseOf", "ECRM.term(\"P4i_is_time-span_of\")"),
    ("ECRM.term(\"P4i_is_time-span_of\")", "OWL.inverseOf", "ECRM.term(\"P4_has_time-span\")"),
    ("ECRM.term(\"P65_shows_visual_item\")", "OWL.inverseOf", "ECRM.term(\"P65i_is_shown_by\")"),
    ("ECRM.term(\"P65i_is_shown_by\")", "OWL.inverseOf", "ECRM.term(\"P65_shows_visual_item\")"),
    ("ECRM.term(\"P7_took_place_at\")", "OWL.inverseOf", "ECRM.term(\"P7i_witnessed\")"),
    ("ECRM.term(\"P7i_witnessed\")", "OWL.inverseOf", "ECRM.term(\"P7_took_place_at\")"),
    ("ECRM.term(\"P98_brought_into_life\")", "OWL.inverseOf", "ECRM.term(\"P98i_was_born\")"),
    ("ECRM.term(\"P98i_was_born\")", "OWL.inverseOf", "ECRM.term(\"P98_brought_into_life\")"),
    ("ECRM.term(\"P102_has_title\")", "OWL.inverseOf", "ECRM.term(\"P102i_is_title_of\")"),
    ("ECRM.term(\"P102i_is_title_of\")", "OWL.inverseOf", "ECRM.term(\"P102_has_title\")"),
    ("ECRM.term(\"P131_is_identified_by\")", "OWL.inverseOf", "ECRM.term(\"P131i_identifies\")"),
    ("ECRM.term(\"P131i_identifies\")", "OWL.inverseOf", "ECRM.term(\"P131_is_identified_by\")"),
    ("ECRM.term(\"P138_represents\")", "OWL.inverseOf", "ECRM.term(\"P138i_has_representation\")"),
    ("ECRM.term(\"P138i_has_representation\")", "OWL.inverseOf", "ECRM.term(\"P138_represents\")"),
    ("ECRM.term(\"P14_carried_out_by\")", "OWL.inverseOf", "ECRM.term(\"P14i_performed\")"),
    ("ECRM.term(\"P14i_performed\")", "OWL.inverseOf", "ECRM.term(\"P14_carried_out_by\")"),
    ("ECRM.term(\"P190_has_symbolic_content\")", "OWL.inverseOf", "ECRM.term(\"P190i_is_content_of\")"),
    ("ECRM.term(\"P190i_is_content_of\")", "OWL.inverseOf", "ECRM.term(\"P190_has_symbolic_content\")"),
    ("ECRM.term(\"P1_is_identified_by\")", "OWL.inverseOf", "ECRM.term(\"P1i_identifies\")"),
    ("ECRM.term(\"P1i_identifies\")", "OWL.inverseOf", "ECRM.term(\"P1_is_identified_by\")"),
    ("ECRM.term(\"P2_has_type\")", "OWL.inverseOf", "ECRM.term(\"P2i_is_type_of\")"),
    ("ECRM.term(\"P2i_is_type_of\")", "OWL.inverseOf", "ECRM.term(\"P2_has_type\")"),
    ("ECRM.term(\"P4_has_time-span\")", "OWL.inverseOf", "ECRM.term(\"P4i_is_time-span_of\")"),
    ("ECRM.term(\"P4i_is_time-span_of\")", "OWL.inverseOf", "ECRM.term(\"P4_has_time-span\")"),
    ("ECRM.term(\"P7_took_place_at\")", "OWL.inverseOf", "ECRM.term(\"P7i_witnessed\")"),
    ("ECRM.term(\"P7i_witnessed\")", "OWL.inverseOf", "ECRM.term(\"P7_took_place_at\")"),
    ("ECRM.term(\"P67_refers_to\")", "OWL.inverseOf", "ECRM.term(\"P67i_is_referred_to_by\")"),
    ("ECRM.term(\"P67i_is_referred_to_by\")", "OWL.inverseOf", "ECRM.term(\"P67_refers_to\")"),
    ("LRMOO.term(\"R10_has_member\")", "OWL.inverseOf", "LRMOO.term(\"R10i_is_member_of\")"),
    ("LRMOO.term(\"R10i_is_member_of\")", "OWL.inverseOf", "LRMOO.term(\"R10_has_member\")"),
    ("LRMOO.term(\"R16_created\")", "OWL.inverseOf", "LRMOO.term(\"R16i_was_created_by\")"),
    ("LRMOO.term(\"R16i_was_created_by\")", "OWL.inverseOf", "LRMOO.term(\"R16_created\")"),
    ("LRMOO.term(\"R17_created\")", "OWL.inverseOf", "LRMOO.term(\"R17i_was_created_by\")"),
    ("LRMOO.term(\"R17i_was_created_by\")", "OWL.inverseOf", "LRMOO.term(\"R17_created\")"),
    ("LRMOO.term(\"R19_created_a_realisation_of\")", "OWL.inverseOf", "LRMOO.term(\"R19i_was_realised_through\")"),
    ("LRMOO.term(\"R19i_was_realised_through\")", "OWL.inverseOf", "LRMOO.term(\"R19_created_a_realisation_of\")"),
    ("LRMOO.term(\"R24_created\")", "OWL.inverseOf", "LRMOO.term(\"R24i_was_created_through\")"),
    ("LRMOO.term(\"R24i_was_created_through\")", "OWL.inverseOf", "LRMOO.term(\"R24_created\")"),
    ("LRMOO.term(\"R27_materialized\")", "OWL.inverseOf", "LRMOO.term(\"R27i_was_materialized_by\")"),
    ("LRMOO.term(\"R27i_was_materialized_by\")", "OWL.inverseOf", "LRMOO.term(\"R27_materialized\")"),
    ("LRMOO.term(\"R28_produced\")", "OWL.inverseOf", "LRMOO.term(\"R28i_was_produced_by\")"),
    ("LRMOO.term(\"R28i_was_produced_by\")", "OWL.inverseOf", "LRMOO.term(\"R28_produced\")"),
    ("LRMOO.term(\"R3_is_realised_in\")", "OWL.inverseOf", "LRMOO.term(\"R3i_realises\")"),
    ("LRMOO.term(\"R3i_realises\")", "OWL.inverseOf", "LRMOO.term(\"R3_is_realised_in\")"),
    ("LRMOO.term(\"R4_embodies\")", "OWL.inverseOf", "LRMOO.term(\"R4i_is_embodied_in\")"),
    ("LRMOO.term(\"R4i_is_embodied_in\")", "OWL.inverseOf", "LRMOO.term(\"R4_embodies\")"),
    ("LRMOO.term(\"R7_exemplifies\")", "OWL.inverseOf", "LRMOO.term(\"R7i_is_exemplified_by\")"),
    ("LRMOO.term(\"R7i_is_exemplified_by\")", "OWL.inverseOf", "LRMOO.term(\"R7_exemplifies\")"),
    ("INTRO.term(\"R18_showsActualization\")", "OWL.inverseOf", "INTRO.term(\"R18i_actualizationFoundOn\")"),
    ("INTRO.term(\"R18i_actualizationFoundOn\")", "OWL.inverseOf", "INTRO.term(\"R18_showsActualization\")"),
    ("INTRO.term(\"R24_hasRelatedEntity\")", "OWL.inverseOf", "INTRO.term(\"R24i_isRelatedEntity\")"),
    ("INTRO.term(\"R24i_isRelatedEntity\")", "OWL.inverseOf", "INTRO.term(\"R24_hasRelatedEntity\")"),
    ("INTRO.term(\"R12_hasReferredToEntity\")", "OWL.inverseOf", "INTRO.term(\"R12i_isReferredToEntity\")"),
    ("INTRO.term(\"R12i_isReferredToEntity\")", "OWL.inverseOf", "INTRO.term(\"R12_hasReferredToEntity\")"),
    ("INTRO.term(\"R13_hasReferringEntity\")", "OWL.inverseOf", "INTRO.term(\"R13i_isReferringEntity\")"),
    ("INTRO.term(\"R13i_isReferringEntity\")", "OWL.inverseOf", "INTRO.term(\"R13_hasReferringEntity\")"),
    ("INTRO.term(\"R17_actualizesFeature\")", "OWL.inverseOf", "INTRO.term(\"R17i_featureIsActualizedIn\")"),
    ("INTRO.term(\"R17i_featureIsActualizedIn\")", "OWL.inverseOf", "INTRO.term(\"R17_actualizesFeature\")"),
    ("INTRO.term(\"R18_showsActualization\")", "OWL.inverseOf", "INTRO.term(\"R18i_actualizationFoundOn\")"),
    ("INTRO.term(\"R18i_actualizationFoundOn\")", "OWL.inverseOf", "INTRO.term(\"R18_showsActualization\")"),
    ("INTRO.term(\"R21_identifies\")", "OWL.inverseOf", "INTRO.term(\"R21i_isIdentifiedBy\")"),
    ("INTRO.term(\"R21i_isIdentifiedBy\")", "OWL.inverseOf", "INTRO.term(\"R21_identifies\")"),
    ("INTRO.term(\"R22_providesSimilarityForRelation\")", "OWL.inverseOf", "INTRO.term(\"R22i_relationIsBasedOnSimilarity\")"),
    ("INTRO.term(\"R22i_relationIsBasedOnSimilarity\")", "OWL.inverseOf", "INTRO.term(\"R22_providesSimilarityForRelation\")"),
    ("INTRO.term(\"R30_hasTextPassage\")", "OWL.inverseOf", "INTRO.term(\"R30i_isTextPassageOf\")"),
    ("INTRO.term(\"R30i_isTextPassageOf\")", "OWL.inverseOf", "INTRO.term(\"R30_hasTextPassage\")"),
]

def add_additional_alignments(g: Graph):
    import re

    def _resolve(tok: str):
        tok = tok.strip()
        m = re.match(r'^([A-Za-z_]+)\.term\("([^"]+)"\)$', tok)
        if m:
            ns = globals()[m.group(1).upper()]
            return ns.term(m.group(2))
        m = re.match(r'^([A-Za-z_]+)\.([A-Za-z_][A-Za-z0-9_]*)$', tok)
        if m:
            ns = globals()[m.group(1).upper()]
            return getattr(ns, m.group(2))
        raise ValueError(f"Unbekanntes Alignment-Format: {tok}")

    seen_equiv = set()  
    seen_inverse = set()

    for s_str, p_str, o_str in ALIGN_ROWS:
        s = _resolve(s_str); p = _resolve(p_str); o = _resolve(o_str)

        if s == o and (p in (OWL.equivalentClass, OWL.equivalentProperty, OWL.inverseOf)):
            continue

        should_add = False
        if p == OWL.equivalentClass:
            if any(g.triples((None, RDF.type, s))) or any(g.triples((None, RDF.type, o))):
                # Kanonische Richtung wählen (alphabetisch nach IRI)
                key = (str(min(s, o)), str(max(s, o)), 'equiv')
                if key in seen_equiv:
                    continue
                seen_equiv.add(key)
                should_add = True

        elif p == OWL.equivalentProperty:
            if any(g.triples((None, s, None))) or any(g.triples((None, o, None))):
                key = (str(min(s, o)), str(max(s, o)), 'equiv')
                if key in seen_equiv:
                    continue
                seen_equiv.add(key)
                should_add = True

        elif p == OWL.inverseOf:
            if any(g.triples((None, s, None))) or any(g.triples((None, o, None))):
                key = (str(min(s, o)), str(max(s, o)), 'inv')
                if key in seen_inverse:
                    continue
                seen_inverse.add(key)
                should_add = True

        if should_add:
            g.add((s, p, o))

# Main

def main():
    base_dir = Path("../data/rdf").resolve()
    out_path = (base_dir / "sappho-reception.ttl").resolve()

    if not base_dir.exists():
        sys.exit(f"Verzeichnis nicht gefunden: {base_dir}")

    g = merge_with_precedence(base_dir, out_path)

    add_alignments(g)
    add_additional_alignments(g)

    # Turtle
    tmp_ttl = out_path.with_suffix(".ttl.tmp")
    g.serialize(destination=tmp_ttl.as_posix(), format="turtle", encoding="utf-8")
    Path(tmp_ttl).replace(out_path)

    # RDF/XML
    rdf_out = out_path.with_suffix(".rdf")       
    tmp_rdf = rdf_out.with_suffix(".rdf.tmp")
    g.serialize(destination=tmp_rdf.as_posix(), format="pretty-xml", encoding="utf-8")
    Path(tmp_rdf).replace(rdf_out)

    print(f"\nFertig. Dateien gespeichert:\n  {out_path}\n  {rdf_out}")
    print(f"Gesamtzahl Tripel: {len(g)}")

if __name__ == "__main__":
    main()
