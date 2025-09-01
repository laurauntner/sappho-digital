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
ONTOPOETRY_CORE = Namespace("http://postdata.linhd.uned.es/ontology/postdata-core#")
ONTOPOETRY_ANALYSIS = Namespace("http://postdata.linhd.uned.es/ontology/postdata-poeticAnalysis#")
SCHEMA = Namespace("https://schema.org/")

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
    g.bind("ontopoetry_core", ONTOPOETRY_CORE, override=True)
    g.bind("ontopoetry_analysis", ONTOPOETRY_ANALYSIS, override=True)
    g.bind("schema", SCHEMA, override=True)

    g.bind("sappho_prop", SAPPHO_PROP, override=True)

# Alignment

def add_alignments(g: Graph):
    bind_namespaces(g)

    ## Classes ##
    if any(g.triples((None, RDF.type, ECRM.E21_Person))):
        g.add((DRACOR.author, SKOS.broadMatch, ECRM.E21_Person))
        g.add((FOAF.Agent, SKOS.closeMatch, ECRM.E21_Person))
        g.add((MIMOTEXT.Q11, SKOS.broadMatch, ECRM.E21_Person))  # author
        g.add((MIMOTEXT.Q10, SKOS.closeMatch, ECRM.E21_Person))  # person
        g.add((ONTOPOETRY_CORE.Person, SKOS.closeMatch, ECRM.E21_Person))

    if any(g.triples((None, RDF.type, ECRM.E35_Title))):
        g.add((DOCO.Title, SKOS.closeMatch, ECRM.E35_Title))

    if any(g.triples((None, RDF.type, ECRM.E38_Image))):
        g.add((BIBO.Image, SKOS.closeMatch, ECRM.E38_Image))
        g.add((FOAF.Image, SKOS.closeMatch, ECRM.E38_Image))

    if any(g.triples((None, RDF.type, ECRM.E40_Legal_Body))):
        g.add((FOAF.Agent, SKOS.closeMatch, ECRM.E40_Legal_Body))
        g.add((ONTOPOETRY_CORE.Organisation, SKOS.broadMatch, ECRM.E40_Legal_Body))

    if any(g.triples((None, RDF.type, ECRM["E52_Time-Span"]))):
        g.add((DC.PeriodOfTime, SKOS.closeMatch, ECRM["E52_Time-Span"]))
        g.add((ONTOPOETRY_CORE.TimeSpan, SKOS.closeMatch, ECRM["E52_Time-Span"]))

    if any(g.triples((None, RDF.type, ECRM.E53_Place))):
        g.add((DC.Location, SKOS.closeMatch, ECRM.E53_Place))
        g.add((MIMOTEXT.Q26, SKOS.closeMatch, ECRM.E53_Place))  # spatial concept
        g.add((ONTOPOETRY_CORE.Place, SKOS.closeMatch, ECRM.E53_Place))

    if any(g.triples((None, RDF.type, ECRM.E55_Type))):
        g.add((DRACOR.genre, SKOS.broadMatch, ECRM.E55_Type))
        g.add((INTERTEXT_TX.TextGenre, SKOS.broadMatch, ECRM.E55_Type))
        g.add((MIMOTEXT.Q33, SKOS.broadMatch, ECRM.E55_Type))  # genre

    if any(g.triples((None, RDF.type, ECRM.E67_Birth))):
        g.add((ONTOPOETRY_CORE.Birth, SKOS.closeMatch, ECRM.E67_Birth))

    if any(g.triples((None, RDF.type, ECRM.E69_Death))):
        g.add((ONTOPOETRY_CORE.Death, SKOS.closeMatch, ECRM.E69_Death))

    if any(g.triples((None, RDF.type, ECRM.E73_Information_Object))):
        g.add((FABIO.DigitalItem, SKOS.broadMatch, ECRM.E73_Information_Object))

    if any(g.triples((None, RDF.type, LRMOO.F1_Work))):
        g.add((FABIO.Work, SKOS.broadMatch, LRMOO.F1_Work))
        g.add((FABIO.LiteraryArtisticWork, SKOS.broadMatch, LRMOO.F1_Work))
        g.add((ONTOPOETRY_CORE.Work, SKOS.closeMatch, LRMOO.F1_Work))
        g.add((ONTOPOETRY_CORE.PoeticWork, SKOS.broadMatch, LRMOO.F1_Work))

    if any(g.triples((None, RDF.type, LRMOO.F2_Expression))):
        g.add((FOAF.Document, SKOS.closeMatch, LRMOO.F2_Expression))
        g.add((BIBO.Manuscript, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((DRACOR.play, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((FABIO.Expression, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((INTERTEXT_TX.Text, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((INTERTEXT_TX.SingleText, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((INTERTEXT_AF.Work, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((INTERTEXT_AB.Reference, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((MIMOTEXT.Q2, SKOS.broadMatch, LRMOO.F2_Expression))  # literary work
        g.add((ONTOPOETRY_CORE.Expression, SKOS.closeMatch, LRMOO.F2_Expression))
        g.add((ONTOPOETRY_ANALYSIS.Intertextuality, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((ONTOPOETRY_ANALYSIS.Source, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((ONTOPOETRY_ANALYSIS.Redaction, SKOS.broadMatch, LRMOO.F2_Expression))
        g.add((ONTOPOETRY_ANALYSIS.Excerpt, SKOS.broadMatch, LRMOO.F2_Expression))

    if any(g.triples((None, RDF.type, LRMOO.F3_Manifestation))):
        g.add((BIBO.Book, SKOS.broadMatch, LRMOO.F3_Manifestation))
        g.add((DC.BibliographicResource, SKOS.broadMatch, LRMOO.F3_Manifestation))
        g.add((FABIO.Manifestation, SKOS.broadMatch, LRMOO.F3_Manifestation))
        g.add((FOAF.Document, SKOS.closeMatch, LRMOO.F3_Manifestation))

    if any(g.triples((None, RDF.type, LRMOO.F5_Item))):
        g.add((FABIO.Item, SKOS.broadMatch, LRMOO.F5_Item))
        g.add((FOAF.Document, SKOS.closeMatch, LRMOO.F5_Item))

    if any(g.triples((None, RDF.type, LRMOO.F27_Work_Creation))):
        g.add((ONTOPOETRY_CORE.WorkConception, SKOS.closeMatch, LRMOO.F27_Work_Creation))

    if any(g.triples((None, RDF.type, LRMOO.F28_Expression_Creation))):
        g.add((ONTOPOETRY_CORE.ExpressionCreation, SKOS.closeMatch, LRMOO.F28_Expression_Creation))

    if any(g.triples((None, RDF.type, INTRO.INT1_Segment))):
        g.add((INTERTEXT_AF.Segment, SKOS.broadMatch, INTRO.INT1_Segment))

    if any(g.triples((None, RDF.type, INTRO.INT2_ActualizationOfFeature))):
        g.add((FRBROO.F38_Character, SKOS.broadMatch, INTRO.INT2_ActualizationOfFeature))
        g.add((EFRBROO.F38_Character, SKOS.broadMatch, INTRO.INT2_ActualizationOfFeature))
        g.add((DRACOR.character, SKOS.broadMatch, INTRO.INT2_ActualizationOfFeature))
        g.add((GOLEM.G1_Character, SKOS.broadMatch, INTRO.INT2_ActualizationOfFeature))
        g.add((GOLEM.G7_Narrative_Sequence, SKOS.broadMatch, INTRO.INT2_ActualizationOfFeature))
        g.add((ONTOPOETRY_CORE.Character, SKOS.broadMatch, INTRO.INT2_ActualizationOfFeature))

    if any(g.triples((None, RDF.type, INTRO.INT4_Feature))):
        g.add((INTERTEXT_AB.Mediator, SKOS.closeMatch, INTRO.INT4_Feature))
        g.add((GOLEM.G9_Narrative_Unit, SKOS.broadMatch, INTRO.INT4_Feature))

    if any(g.triples((None, RDF.type, INTRO.INT6_Architext))):
        g.add((INTERTEXT_AF.System, SKOS.broadMatch, INTRO.INT6_Architext))

    if any(g.triples((None, RDF.type, INTRO.INT11_TypeOfInterrelation))):
        g.add((INTERTEXT_AB.IntertexualSpecification, SKOS.closeMatch, INTRO.INT11_TypeOfInterrelation))

    if any(g.triples((None, RDF.type, INTRO.INT21_TextPassage))):
        g.add((DOCO.Part, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.BackMatter, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.BodyMatter, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.CaptionedBox, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.Chapter, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.ComplexRunInQuotation, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.Footnote, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.Formula, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.FormulaBox, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.FrontMatter, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.List, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.Section, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((DOCO.Table, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((INTERTEXT_AB.Mediator, SKOS.closeMatch, INTRO.INT21_TextPassage))
        g.add((BIBO.Quote, SKOS.broadMatch, INTRO.INT21_TextPassage))
        g.add((FABIO.Quotation, SKOS.broadMatch, INTRO.INT21_TextPassage))
        g.add((INTERTEXT_TX.TextSegment, SKOS.closeMatch, INTRO.INT21_TextPassage))

    if any(g.triples((None, RDF.type, INTRO.INT31_IntertextualRelation))):
        g.add((INTERTEXT_AB.IntertexualRelation, SKOS.closeMatch, INTRO.INT31_IntertextualRelation))

    if any(g.triples((None, RDF.type, INTRO.INT_Character))):
        g.add((GOLEM["G0_Character-Stoff"], SKOS.closeMatch, INTRO.INT_Character))
        g.add((FRBROO.F38_Character, SKOS.broadMatch, INTRO.INT_Character))
        g.add((EFRBROO.F38_Character, SKOS.broadMatch, INTRO.INT_Character))
        g.add((DRACOR.character, SKOS.broadMatch, INTRO.INT_Character))
        g.add((ONTOPOETRY_CORE.Character, SKOS.broadMatch, INTRO.INT_Character))

    if any(g.triples((None, RDF.type, INTRO.INT_Plot))):
        g.add((GOLEM.G14_Narrative_Stoff, SKOS.closeMatch, INTRO.INT_Plot))

    if any(g.triples((None, RDF.type, INTRO.INT_Motif))):
        g.add((INTERTEXT_MT.Motive, SKOS.closeMatch, INTRO.INT_Motif))

    if any(g.triples((None, RDF.type, INTRO.INT_Topic))):
        g.add((MIMOTEXT.Q20, SKOS.closeMatch, INTRO.INT_Topic))  # thematic concept

    ## Properties ##
    if any(g.triples((None, ECRM.P1_is_identified_by, None))):
        g.add((DC.identifier, SKOS.broadMatch, ECRM.P1_is_identified_by))

    if any(g.triples((None, ECRM.P2_has_type, None))):
        g.add((DC.type, SKOS.broadMatch, ECRM.P2_has_type))
        g.add((DRACOR.has_genre, SKOS.broadMatch, ECRM.P2_has_type))
        g.add((FOAF.gender, SKOS.broadMatch, ECRM.P2_has_type))
        g.add((MIMOTEXT.P12, SKOS.broadMatch, ECRM.P2_has_type))  # genre
        g.add((ONTOPOETRY_CORE.gender, SKOS.broadMatch, ECRM.P2_has_type))
        g.add((ONTOPOETRY_CORE.genre, SKOS.broadMatch, ECRM.P2_has_type))
        g.add((SCHEMA.genre, SKOS.broadMatch, ECRM.P2_has_type))

    if any(g.triples((None, ECRM["P4_has_time-span"], None))):
        g.add((DC.date, SKOS.broadMatch, ECRM["P4_has_time-span"]))
        g.add((DC.created, SKOS.broadMatch, ECRM["P4_has_time-span"]))
        g.add((DC.dateCopyrighted, SKOS.broadMatch, ECRM["P4_has_time-span"]))
        g.add((DRACOR.printYear, SKOS.broadMatch, ECRM["P4_has_time-span"]))
        g.add((DRACOR.writtenYear, SKOS.broadMatch, ECRM["P4_has_time-span"]))
        g.add((MIMOTEXT.P9, SKOS.broadMatch, ECRM["P4_has_time-span"]))  # publication date
        g.add((ONTOPOETRY_CORE.hasTimeSpan, SKOS.closeMatch, ECRM["P4_has_time-span"]))
        g.add((SCHEMA.dateCreated, SKOS.broadMatch, ECRM["P4_has_time-span"]))
        g.add((SCHEMA.datePublished, SKOS.broadMatch, ECRM["P4_has_time-span"]))

    if any(g.triples((None, ECRM["P4i_is_time-span_of"], None))):
        g.add((ONTOPOETRY_CORE.isTimeSpanOf, SKOS.closeMatch, ECRM["P4i_is_time-span_of"]))

    if any(g.triples((None, ECRM.P7_took_place_at, None))):
        g.add((FABIO.hasPlaceOfPublication, SKOS.broadMatch, ECRM.P7_took_place_at))
        g.add((MIMOTEXT.P10, SKOS.broadMatch, ECRM.P7_took_place_at))  # publication place
        g.add((ONTOPOETRY_CORE.tookPlaceAt, SKOS.closeMatch, ECRM.P7_took_place_at))
        g.add((SCHEMA.locationCreated, SKOS.broadMatch, ECRM.P7_took_place_at))

    if any(g.triples((None, ECRM.P7i_witnessed, None))):
        g.add((ONTOPOETRY_CORE.witnessed, SKOS.closeMatch, ECRM.P7i_witnessed))

    if any(g.triples((None, ECRM.P14_carried_out_by, None))):
        g.add((BIBO.editor, SKOS.broadMatch, ECRM.P14_carried_out_by))
        g.add((DRACOR.has_author, SKOS.broadMatch, ECRM.P14_carried_out_by))
        g.add((FOAF.maker, SKOS.broadMatch, ECRM.P14_carried_out_by))
        g.add((MIMOTEXT.P5, SKOS.broadMatch, ECRM.P14_carried_out_by))  # has author
        g.add((SCHEMA.author, SKOS.broadMatch, ECRM.P14_carried_out_by))
        g.add((SCHEMA.creator, SKOS.broadMatch, ECRM.P14_carried_out_by))

    if any(g.triples((None, ECRM.P14i_performed, None))):
        g.add((DC.creator, SKOS.broadMatch, ECRM.P14i_performed))
        g.add((DC.publisher, SKOS.broadMatch, ECRM.P14i_performed))
        g.add((FOAF.made, SKOS.broadMatch, ECRM.P14i_performed))
        g.add((MIMOTEXT.P7, SKOS.broadMatch, ECRM.P14i_performed))  # author of

    if any(g.triples((None, ECRM.P98i_was_born, None))):
        g.add((ONTOPOETRY_CORE.wasBorn, SKOS.closeMatch, ECRM.P98i_was_born))

    if any(g.triples((None, ECRM.P98_brought_into_life, None))):
        g.add((ONTOPOETRY_CORE.broughtIntoLife, SKOS.closeMatch, ECRM.P98_brought_into_life))

    if any(g.triples((None, ECRM.P100_was_death_of, None))):
        g.add((ONTOPOETRY_CORE.wasDeathOf, SKOS.closeMatch, ECRM.P100_was_death_of))

    if any(g.triples((None, ECRM.P100i_died_in, None))):
        g.add((ONTOPOETRY_CORE.diedIn, SKOS.closeMatch, ECRM.P100i_died_in))

    if any(g.triples((None, ECRM.P102_has_title, None))):
        g.add((DC.title, SKOS.broadMatch, ECRM.P102_has_title))
        g.add((MIMOTEXT.P4, SKOS.broadMatch, ECRM.P102_has_title))  # title

    if any(g.triples((None, ECRM.P131_is_identified_by, None))):
        g.add((FOAF.name, SKOS.broadMatch, ECRM.P131_is_identified_by))
        g.add((MIMOTEXT.P8, SKOS.broadMatch, ECRM.P131_is_identified_by))  # name

    if any(g.triples((None, ECRM.P138i_has_representation, None))):
        g.add((FOAF.img, SKOS.broadMatch, ECRM.P138i_has_representation))
        g.add((MIMOTEXT.P21, SKOS.broadMatch, ECRM.P138i_has_representation))  # full work URL

    if any(g.triples((None, LRMOO.R3_is_realised_in, None))):
        g.add((FABIO.realization, SKOS.closeMatch, LRMOO.R3_is_realised_in))

    if any(g.triples((None, LRMOO.R4i_is_embodied_in, None))):
        g.add((FABIO.embodiment, SKOS.closeMatch, LRMOO.R4i_is_embodied_in))

    if any(g.triples((None, LRMOO.R7i_is_exemplified_by, None))):
        g.add((FABIO.exemplar, SKOS.closeMatch, LRMOO.R7i_is_exemplified_by))

    if any(g.triples((None, LRMOO.R16_created, None))):
        g.add((ONTOPOETRY_CORE.initiated, SKOS.closeMatch, LRMOO.R16_created))

    if any(g.triples((None, LRMOO.R16i_was_created_by, None))):
        g.add((ONTOPOETRY_CORE.wasInitiatedBy, SKOS.closeMatch, LRMOO.R16i_was_created_by))

    if any(g.triples((None, LRMOO.R17_created, None))):
        g.add((ONTOPOETRY_CORE.createdExpressionFromExpressionCreation, SKOS.closeMatch, LRMOO.R17_created))

    if any(g.triples((None, LRMOO.R17i_was_created_by, None))):
        g.add((ONTOPOETRY_CORE.wasCreatedByExpressionCreationForExpression, SKOS.closeMatch, LRMOO.R17i_was_created_by))

    if any(g.triples((None, LRMOO.R19_created_a_realisation_of, None))):
        g.add((ONTOPOETRY_CORE.createdWorkByExpressionCreation, SKOS.closeMatch, LRMOO.R19_created_a_realisation_of))

    if any(g.triples((None, LRMOO.R19i_was_realised_through, None))):
        g.add((ONTOPOETRY_CORE.realisedThroughExpressionCreation, SKOS.closeMatch, LRMOO.R19i_was_realised_through))

    if any(g.triples((None, INTRO.R12i_isReferredToEntity, None))):
        g.add((INTERTEXT_AB.there, SKOS.broadMatch, INTRO.R12i_isReferredToEntity))

    if any(g.triples((None, INTRO.R13i_isReferringEntity, None))):
        g.add((INTERTEXT_AB.here, SKOS.broadMatch, INTRO.R13i_isReferringEntity))

    if any(g.triples((None, INTRO.R18_showsActualization, None))):
        g.add((ONTOPOETRY_ANALYSIS.presentsIntertextuality, SKOS.broadMatch, INTRO.R18_showsActualization))

    if any(g.triples((None, INTRO.R18i_actualizationFoundOn, None))):
        g.add((ONTOPOETRY_ANALYSIS.isIntertextualityPresentAt, SKOS.broadMatch, INTRO.R18i_actualizationFoundOn))

    if any(g.triples((None, INTRO.R19i_isTypeOf, None))):
        g.add((INTERTEXT_AB.specifiedBy, SKOS.broadMatch, INTRO.R19i_isTypeOf))
        g.add((ONTOPOETRY_ANALYSIS.typeOfIntertextuality, SKOS.broadMatch, INTRO.R19i_isTypeOf))

    if any(g.triples((None, INTRO.R22i_relationIsBasedOnSimilarity, None))):
        g.add((INTERTEXT_AB.mediatedBy, SKOS.closeMatch, INTRO.R22i_relationIsBasedOnSimilarity))

    if any(g.triples((None, INTRO.R24_hasRelatedEntity, None))):
        g.add((INTERTEXT_AB.mediatedBy, SKOS.closeMatch, INTRO.R24_hasRelatedEntity))

    if any(g.triples((None, INTRO.R30_hasTextPassage, None))):
        g.add((DC.hasPart, SKOS.closeMatch, INTRO.R30_hasTextPassage))
        g.add((ONTOPOETRY_ANALYSIS.presentsIntertextuality, SKOS.broadMatch, INTRO.R30_hasTextPassage))

    if any(g.triples((None, INTRO.R30i_isTextPassageOf, None))):
        g.add((ONTOPOETRY_ANALYSIS.isIntertextualityPresentAt, SKOS.broadMatch, INTRO.R30i_isTextPassageOf))

    if any(g.triples((None, PROV.wasDerivedFrom, None))):
        g.add((DC.source, SKOS.closeMatch, PROV.wasDerivedFrom))
        g.add((MIMOTEXT.P17, SKOS.broadMatch, PROV.wasDerivedFrom))  # reference URL

    # Complex properties: has_manifestation / has_portrayal / has_representation
    if (
        any(g.triples((None, RDF.type, LRMOO.F1_Work))) and
        any(g.triples((None, RDF.type, LRMOO.F3_Manifestation)))
    ):
        g.add((SAPPHO_PROP.has_manifestation, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.has_manifestation, RDFS.label, Literal("has manifestation", lang="en")))
        g.add((SAPPHO_PROP.has_manifestation, SKOS.closeMatch, FABIO.hasManifestation))
        g.add((SAPPHO_PROP.has_manifestation, RDFS.domain, LRMOO.F1_Work))
        g.add((SAPPHO_PROP.has_manifestation, RDFS.range, LRMOO.F3_Manifestation))

        bnode = BNode()
        Collection(g, bnode, [LRMOO.R3_is_realised_in, LRMOO.R4i_is_embodied_in])
        g.add((SAPPHO_PROP.has_manifestation, OWL.propertyChainAxiom, bnode))

        for work in g.subjects(RDF.type, LRMOO.F1_Work):
            for expr in g.objects(work, LRMOO.R3_is_realised_in):
                for mani in g.objects(expr, LRMOO.R4i_is_embodied_in):
                    g.add((work, SAPPHO_PROP.has_manifestation, mani))

    if (
        any(g.triples((None, RDF.type, LRMOO.F1_Work))) and
        any(g.triples((None, RDF.type, LRMOO.F5_Item)))
    ):
        g.add((SAPPHO_PROP.has_portrayal, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.has_portrayal, RDFS.label, Literal("has portrayal", lang="en")))
        g.add((SAPPHO_PROP.has_portrayal, SKOS.closeMatch, FABIO.hasPortrayal))
        g.add((SAPPHO_PROP.has_portrayal, RDFS.domain, LRMOO.F1_Work))
        g.add((SAPPHO_PROP.has_portrayal, RDFS.range, LRMOO.F5_Item))

        bnode = BNode()
        Collection(g, bnode, [LRMOO.R3_is_realised_in, LRMOO.R4i_is_embodied_in, LRMOO.R7i_is_exemplified_by])
        g.add((SAPPHO_PROP.has_portrayal, OWL.propertyChainAxiom, bnode))

        for work in g.subjects(RDF.type, LRMOO.F1_Work):
            for expr in g.objects(work, LRMOO.R3_is_realised_in):
                for mani in g.objects(expr, LRMOO.R4i_is_embodied_in):
                    for item in g.objects(mani, LRMOO.R7i_is_exemplified_by):
                        g.add((work, SAPPHO_PROP.has_portrayal, item))

    if (
        any(g.triples((None, RDF.type, LRMOO.F2_Expression))) and
        any(g.triples((None, RDF.type, LRMOO.F5_Item)))
    ):
        g.add((SAPPHO_PROP.has_representation, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.has_representation, RDFS.label, Literal("has representation", lang="en")))
        g.add((SAPPHO_PROP.has_representation, SKOS.closeMatch, FABIO.hasRepresentation))
        g.add((SAPPHO_PROP.has_representation, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.has_representation, RDFS.range, LRMOO.F5_Item))

        bnode = BNode()
        Collection(g, bnode, [LRMOO.R4i_is_embodied_in, LRMOO.R7i_is_exemplified_by])
        g.add((SAPPHO_PROP.has_representation, OWL.propertyChainAxiom, bnode))

        for expr in g.subjects(RDF.type, LRMOO.F2_Expression):
            for mani in g.objects(expr, LRMOO.R4i_is_embodied_in):
                for item in g.objects(mani, LRMOO.R7i_is_exemplified_by):
                    g.add((expr, SAPPHO_PROP.has_representation, item))

    # sappho_prop:about
    if any(g.triples((None, RDF.type, INTRO.INT_Topic))):
        g.add((SAPPHO_PROP.about, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.about, RDFS.label, Literal("Link from expression to topic", lang="en")))
        b_about = BNode()
        Collection(g, b_about, [INTRO.R18_showsActualization, INTRO.R17_actualizesFeature])
        g.add((SAPPHO_PROP.about, OWL.propertyChainAxiom, b_about))
        g.add((SAPPHO_PROP.about, SKOS.closeMatch, DC.subject))
        g.add((SAPPHO_PROP.about, SKOS.closeMatch, FOAF.topic))
        g.add((SAPPHO_PROP.about, SKOS.closeMatch, MIMOTEXT.P36))
        g.add((SAPPHO_PROP.about, SKOS.closeMatch, SCHEMA.about))
        g.add((SAPPHO_PROP.about, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.about, RDFS.range, INTRO.INT_Topic))

        for expr in g.subjects(RDF.type, LRMOO.F2_Expression):
            for act in g.objects(expr, INTRO.R18_showsActualization):
                topic = g.value(act, INTRO.R17_actualizesFeature)
                if topic and (topic, RDF.type, INTRO.INT_Topic) in g:
                    g.add((expr, SAPPHO_PROP.about, topic))

    # compute directions for INT31 relations (younger vs older)
    directions = []  # list of (younger_expr, older_expr, younger_tp, older_tp)
    relation_directions = {}  # map rel -> (younger_expr, older_expr)

    for rel in g.subjects(RDF.type, INTRO.INT31_IntertextualRelation):
        tp_expr = []
        for tp in g.objects(rel, INTRO.R24_hasRelatedEntity):
            expr = g.value(tp, INTRO.R30i_isTextPassageOf)
            if expr:
                tp_expr.append((tp, expr))

        if len(tp_expr) != 2:
            continue

        exprs = {e for _, e in tp_expr}
        if len(exprs) != 2:
            continue

        (tp1, expr1), (tp2, expr2) = tp_expr[:2]
        y1 = get_creation_year(g, expr1)
        y2 = get_creation_year(g, expr2)
        if y1 is None or y2 is None:
            continue

        if y1 < y2:
            older_expr, younger_expr = expr1, expr2
            older_tp, younger_tp = tp1, tp2
        else:
            older_expr, younger_expr = expr2, expr1
            older_tp, younger_tp = tp2, tp1

        directions.append((younger_expr, older_expr, younger_tp, older_tp))
        relation_directions[rel] = (younger_expr, older_expr)

    # expr_relation + annotate direction on each relation node
    if any(g.triples((None, RDF.type, INTRO.INT31_IntertextualRelation))):
        g.add((SAPPHO_PROP.expr_relation, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.expr_relation, RDFS.label, Literal("Relation between two expressions", lang="en")))

        first_elem = BNode()
        g.add((first_elem, OWL.inverseOf, INTRO.R18i_actualizationFoundOn))
        chain_list = [first_elem, INTRO.R24i_isRelatedEntity, INTRO.R24_hasRelatedEntity, INTRO.R18i_actualizationFoundOn]
        chain_bnode = BNode()
        Collection(g, chain_bnode, chain_list)
        g.add((SAPPHO_PROP.expr_relation, OWL.propertyChainAxiom, chain_bnode))
        g.add((SAPPHO_PROP.expr_relation, RDF.type, OWL.SymmetricProperty))
        g.add((SAPPHO_PROP.expr_relation, SKOS.closeMatch, DC.relation))
        g.add((SAPPHO_PROP.expr_relation, SKOS.closeMatch, MIMOTEXT.P34))  # relation
        g.add((SAPPHO_PROP.expr_relation, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.expr_relation, RDFS.range, LRMOO.F2_Expression))

        # annotate younger/older on the INT31 relation nodes
        for rel, (younger_expr, older_expr) in relation_directions.items():
            g.add((rel, INTRO.R13_hasReferringEntity, younger_expr))
            g.add((younger_expr, INTRO.R13i_isReferringEntity, rel))
            g.add((rel, INTRO.R12_hasReferredToEntity, older_expr))
            g.add((older_expr, INTRO.R12i_isReferredToEntity, rel))

        # materialize symmetric links between expressions via the relation
        for rel in g.subjects(RDF.type, INTRO.INT31_IntertextualRelation):
            acts = list(g.objects(rel, INTRO.R24_hasRelatedEntity))
            exprs = {
                expr
                for act in acts
                for expr in g.subjects(INTRO.R18_showsActualization, act)
            }
            for e1 in exprs:
                for e2 in exprs:
                    if e1 != e2:
                        g.add((e1, SAPPHO_PROP.expr_relation, e2))

    # possibly cites / cited_by
    if any(g.triples((None, INTRO.R30i_isTextPassageOf, None))):
        g.add((SAPPHO_PROP.expr_possibly_cites, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.expr_possibly_cites, RDFS.label,
               Literal("Younger expression possibly cites older expression", lang="en")))
        g.add((SAPPHO_PROP.expr_possibly_cites, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.expr_possibly_cites, RDFS.range, LRMOO.F2_Expression))

        inv_rel = BNode(); g.add((inv_rel, OWL.inverseOf, INTRO.R24_hasRelatedEntity))
        inv_tp = BNode(); g.add((inv_tp, OWL.inverseOf, INTRO.R30i_isTextPassageOf))
        chain_nodes = [INTRO.R30_hasTextPassage, inv_rel, INTRO.R24_hasRelatedEntity, inv_tp]
        chain_bnode = BNode(); Collection(g, chain_bnode, chain_nodes)
        g.add((SAPPHO_PROP.expr_possibly_cites, OWL.propertyChainAxiom, chain_bnode))

        g.add((SAPPHO_PROP.expr_possibly_cited_by, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.expr_possibly_cited_by, RDFS.label,
               Literal("Older expression possibly cited by younger expression", lang="en")))
        g.add((SAPPHO_PROP.expr_possibly_cited_by, OWL.inverseOf, SAPPHO_PROP.expr_possibly_cites))
        g.add((SAPPHO_PROP.expr_possibly_cited_by, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.expr_possibly_cited_by, RDFS.range, LRMOO.F2_Expression))

        # ecrm alignment
        g.add((SAPPHO_PROP.expr_possibly_cites, RDFS.subPropertyOf, ECRM.P148_has_component))
        g.add((SAPPHO_PROP.expr_possibly_cited_by, RDFS.subPropertyOf, ECRM.P148i_is_component_of))
        g.add((SAPPHO_PROP.expr_possibly_cites, RDFS.subPropertyOf, ECRM.P130_shows_features_of))
        g.add((SAPPHO_PROP.expr_possibly_cited_by, RDFS.subPropertyOf, ECRM.P130i_features_are_also_found_on))

        # lrmoo alignment
        g.add((LRMOO.R76_is_derivative_of, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cites))
        g.add((LRMOO.R76i_has_derivative, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cited_by))

        # other ontologies
        g.add((BIBO.cites, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cites))
        g.add((BIBO.citedBy, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cited_by))
        g.add((CITO.cites, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cites))
        g.add((CITO.isCitedBy, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cited_by))
        g.add((ONTOPOETRY_ANALYSIS.usedAsRedaction, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cites))
        g.add((ONTOPOETRY_ANALYSIS.usedAsSource, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cites))
        g.add((ONTOPOETRY_ANALYSIS.showsInfluencesOf, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cites))
        g.add((ONTOPOETRY_ANALYSIS.isDerivativeOf, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cites))
        g.add((ONTOPOETRY_ANALYSIS.isUsedRedactionIn, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cited_by))
        g.add((ONTOPOETRY_ANALYSIS.isUsedSourceIn, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cited_by))
        g.add((ONTOPOETRY_ANALYSIS.influencesAreFoundOn, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cited_by))
        g.add((ONTOPOETRY_ANALYSIS.hasDerivative, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cited_by))
        g.add((SCHEMA.citation, SKOS.broadMatch, SAPPHO_PROP.expr_possibly_cites))

        # text passage level
        g.add((SAPPHO_PROP.tp_possibly_cites, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.tp_possibly_cites, RDFS.label,
               Literal("The younger text possibly cites the text passage of the older text", lang="en")))
        g.add((SAPPHO_PROP.tp_possibly_cites, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.tp_possibly_cites, RDFS.range, INTRO.INT21_TextPassage))

        g.add((SAPPHO_PROP.tp_possibly_cited_by, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.tp_possibly_cited_by, RDFS.label,
               Literal("The older text is possibly cited by the younger text passage", lang="en")))
        g.add((SAPPHO_PROP.tp_possibly_cited_by, RDFS.domain, INTRO.INT21_TextPassage))
        g.add((SAPPHO_PROP.tp_possibly_cited_by, RDFS.range, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.tp_possibly_cited_by, OWL.inverseOf, SAPPHO_PROP.tp_possibly_cites))

        g.add((LRMOO.R75_incorporates, SKOS.broadMatch, SAPPHO_PROP.tp_possibly_cites))
        g.add((LRMOO.R75i_is_incorporated_in, SKOS.broadMatch, SAPPHO_PROP.tp_possibly_cites))
        g.add((SAPPHO_PROP.tp_possibly_cites, RDFS.subPropertyOf, ECRM.P148_has_component))
        g.add((SAPPHO_PROP.tp_possibly_cited_by, RDFS.subPropertyOf, ECRM.P148i_is_component_of))
        g.add((SAPPHO_PROP.tp_possibly_cites, RDFS.subPropertyOf, ECRM.P130_shows_features_of))
        g.add((SAPPHO_PROP.tp_possibly_cited_by, RDFS.subPropertyOf, ECRM.P130i_features_are_also_found_on))

        chain21 = [INTRO.R30_hasTextPassage]
        b21 = BNode()
        Collection(g, b21, chain21)
        g.add((SAPPHO_PROP.tp_possibly_cites, OWL.propertyChainAxiom, b21))

        for younger_expr, older_expr, younger_tp, older_tp in directions:
            g.add((younger_expr, SAPPHO_PROP.expr_possibly_cites, older_expr))
            g.add((older_expr, SAPPHO_PROP.expr_possibly_cited_by, younger_expr))
            g.add((younger_expr, SAPPHO_PROP.tp_possibly_cites, older_tp))
            g.add((older_tp, SAPPHO_PROP.tp_possibly_cited_by, younger_expr))

        g.add((CITO.hasCitedEntity, SKOS.broadMatch, SAPPHO_PROP.tp_possibly_cites))
        g.add((CITO.hasCitingEntity, SKOS.broadMatch, SAPPHO_PROP.tp_possibly_cited_by))

    # expr_references (+ person/place specializations)
    if any(g.triples((None, ECRM.P67_refers_to, None))):
        g.add((SAPPHO_PROP.expr_references, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.expr_references, RDFS.label,
               Literal("Reference from expression to person, place or expression", lang="en")))
        chain_bnode = BNode()
        Collection(g, chain_bnode, [INTRO.R18_showsActualization, ECRM.P67_refers_to])
        g.add((SAPPHO_PROP.expr_references, OWL.propertyChainAxiom, chain_bnode))

        g.add((SAPPHO_PROP.expr_references, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.expr_references, RDFS.range, ECRM.E21_Person))
        g.add((SAPPHO_PROP.expr_references, RDFS.range, ECRM.E53_Place))
        g.add((SAPPHO_PROP.expr_references, RDFS.range, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.expr_references, RDFS.subPropertyOf, ECRM.P67_refers_to))

        g.add((SAPPHO_PROP.referenced_by_expr, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.referenced_by_expr, RDFS.label,
               Literal("Person, place or expression referenced by expression", lang="en")))
        g.add((SAPPHO_PROP.referenced_by_expr, OWL.inverseOf, SAPPHO_PROP.expr_references))
        g.add((SAPPHO_PROP.referenced_by_expr, RDFS.domain, ECRM.E21_Person))
        g.add((SAPPHO_PROP.referenced_by_expr, RDFS.domain, ECRM.E53_Place))
        g.add((SAPPHO_PROP.referenced_by_expr, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.referenced_by_expr, RDFS.range, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.referenced_by_expr, RDFS.subPropertyOf, ECRM.P67i_is_referred_to_by))

        for expr in g.subjects(RDF.type, LRMOO.F2_Expression):
            for act in g.objects(expr, INTRO.R18_showsActualization):
                for target in g.objects(act, ECRM.P67_refers_to):
                    g.add((expr, SAPPHO_PROP.expr_references, target))
                    if (target, RDF.type, ECRM.E21_Person) in g:
                        g.add((expr, SAPPHO_PROP.references_person, target))
                    elif (target, RDF.type, ECRM.E53_Place) in g:
                        g.add((expr, SAPPHO_PROP.references_place, target))
                    elif (target, RDF.type, LRMOO.F2_Expression) in g:
                        pass

        g.add((SAPPHO_PROP.expr_references, SKOS.closeMatch, DC.references))
        g.add((DC.isReferencedBy, OWL.inverseOf, DC.references))
        g.add((SAPPHO_PROP.expr_references, SKOS.narrowMatch, MIMOTEXT.P50))  # mentions
        g.add((MIMOTEXT.P51, OWL.inverseOf, MIMOTEXT.P50))
        g.add((ONTOPOETRY_CORE.mentions, SKOS.broadMatch, SAPPHO_PROP.expr_references))
        g.add((ONTOPOETRY_CORE.isMentionedIn, OWL.inverseOf, ONTOPOETRY_CORE.mentions))
        g.add((SCHEMA.mentions, SKOS.broadMatch, SAPPHO_PROP.expr_references))  # fixed to SAPPHO_PROP

    if any(g.triples((None, ECRM.P67_refers_to, ECRM.E21_Person))):
        g.add((SAPPHO_PROP.references_person, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.references_person, RDFS.label, Literal("Reference to person", lang="en")))
        chain_bnode = BNode()
        Collection(g, chain_bnode, [INTRO.R18_showsActualization, ECRM.P67_refers_to])
        g.add((SAPPHO_PROP.references_person, OWL.propertyChainAxiom, chain_bnode))
        g.add((SAPPHO_PROP.references_person, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.references_person, RDFS.range, ECRM.E21_Person))
        g.add((SAPPHO_PROP.references_person, RDFS.subPropertyOf, ECRM.P67_refers_to))

        g.add((SAPPHO_PROP.person_referenced_by, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.person_referenced_by, RDFS.label, Literal("Person referenced by expression", lang="en")))
        g.add((SAPPHO_PROP.person_referenced_by, OWL.inverseOf, SAPPHO_PROP.references_person))
        g.add((SAPPHO_PROP.person_referenced_by, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.person_referenced_by, RDFS.range, ECRM.E21_Person))
        g.add((SAPPHO_PROP.person_referenced_by, RDFS.subPropertyOf, ECRM.P67i_is_referred_to_by))

        g.add((ONTOPOETRY_CORE.mentionsAgent, SKOS.broadMatch, SAPPHO_PROP.references_person))
        g.add((ONTOPOETRY_CORE.isAgentMentionedIn, OWL.inverseOf, ONTOPOETRY_CORE.mentionsAgent))

    if any(g.triples((None, ECRM.P67_refers_to, ECRM.E53_Place))):
        g.add((SAPPHO_PROP.references_place, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.references_place, RDFS.label, Literal("Reference to place", lang="en")))
        chain_bnode = BNode()
        Collection(g, chain_bnode, [INTRO.R18_showsActualization, ECRM.P67_refers_to])
        g.add((SAPPHO_PROP.references_place, OWL.propertyChainAxiom, chain_bnode))
        g.add((SAPPHO_PROP.references_place, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.references_place, RDFS.range, ECRM.E53_Place))
        g.add((SAPPHO_PROP.references_place, RDFS.subPropertyOf, ECRM.P67_refers_to))

        g.add((SAPPHO_PROP.place_referenced_by, RDF.type, OWL.ObjectProperty))
        g.add((SAPPHO_PROP.place_referenced_by, RDFS.label, Literal("Place referenced by expression", lang="en")))
        g.add((SAPPHO_PROP.place_referenced_by, OWL.inverseOf, SAPPHO_PROP.references_place))
        g.add((SAPPHO_PROP.place_referenced_by, RDFS.domain, LRMOO.F2_Expression))
        g.add((SAPPHO_PROP.place_referenced_by, RDFS.range, ECRM.E53_Place))
        g.add((SAPPHO_PROP.place_referenced_by, RDFS.subPropertyOf, ECRM.P67i_is_referred_to_by))

        g.add((ONTOPOETRY_CORE.mentionsPlace, SKOS.broadMatch, SAPPHO_PROP.references_place))
        g.add((ONTOPOETRY_CORE.isPlaceMentionedIn, OWL.inverseOf, ONTOPOETRY_CORE.mentionsPlace))

    # has_character / is_character_in
    if any(g.triples((None, RDF.type, INTRO.INT_Character))):
        properties = [
            ("has_character", GOLEM.GP1i_has_character),
            ("is_character_in", GOLEM.GP1i_is_character_in),
        ]
        for local_name, golem_prop in properties:
            prop = SAPPHO_PROP[local_name]
            g.add((prop, RDF.type, OWL.ObjectProperty))
            g.add((prop, RDFS.label, Literal(local_name, lang="en")))
            g.add((prop, SKOS.closeMatch, golem_prop))
            if local_name == "has_character":
                g.add((prop, RDFS.domain, LRMOO.F2_Expression))
                g.add((prop, RDFS.range, INTRO.INT2_ActualizationOfFeature))
                g.add((prop, RDFS.subPropertyOf, ECRM.P148_has_component))
            else:
                g.add((prop, RDFS.domain, INTRO.INT2_ActualizationOfFeature))
                g.add((prop, RDFS.range, LRMOO.F2_Expression))
                g.add((prop, RDFS.subPropertyOf, ECRM.P148i_is_component_of))

        for expr in g.subjects(RDF.type, LRMOO.F2_Expression):
            for act in g.objects(expr, INTRO.R18_showsActualization):
                feat = g.value(act, INTRO.R17_actualizesFeature)
                if feat and (feat, RDF.type, INTRO.INT_Character) in g:
                    g.add((expr, SAPPHO_PROP.has_character, act))
                    g.add((act, SAPPHO_PROP.is_character_in, expr))

        g.add((ONTOPOETRY_CORE.characterIn, SKOS.closeMatch, SAPPHO_PROP.is_character_in))
        g.add((ONTOPOETRY_CORE.hasCharacter, SKOS.closeMatch, SAPPHO_PROP.has_character))
        g.add((SCHEMA.character, SKOS.closeMatch, SAPPHO_PROP.has_character))

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

    tmp_path = out_path.with_suffix(".ttl.tmp")
    g.serialize(destination=tmp_path.as_posix(), format="turtle", encoding="utf-8")
    Path(tmp_path).replace(out_path)

    print(f"\nFertig. Datei gespeichert: {out_path}")
    print(f"Gesamtzahl Tripel: {len(g)}")

if __name__ == "__main__":
    main()
