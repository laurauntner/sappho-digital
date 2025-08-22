import csv
from pathlib import Path
from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, XSD, OWL

# Pfade
INPUT_FILE = "../data/sappho_fragments_qids.csv"
OUTPUT_FILE = "../data/rdf/fragments.ttl"

# Namespaces
SD = Namespace("https://sappho-digital.com/")
ECRM = Namespace("http://erlangen-crm.org/current/")
LRMOO = Namespace("http://www.cidoc-crm.org/lrmoo/")

# Graph
g = Graph()
g.bind("", SD)
g.bind("ecrm", ECRM)
g.bind("lrmoo", LRMOO)
g.bind("rdfs", RDFS)
g.bind("xsd", XSD)
g.bind("owl", OWL)

# Einmalige Knoten

# ID-Typen
g.add((SD["id_type/sappho-digital"], RDF.type, ECRM.E55_Type))
g.add((SD["id_type/sappho-digital"], RDFS.label, Literal("Sappho Digital ID", lang="en")))

g.add((SD["id_type/wikidata"], RDF.type, ECRM.E55_Type))
g.add((SD["id_type/wikidata"], RDFS.label, Literal("Wikidata ID", lang="en")))

# Geschlechtstypen
g.add((SD["gender/female"], RDF.type, ECRM.E55_Type))
g.add((SD["gender/female"], RDFS.label, Literal("female", lang="en")))
g.add((SD["gender/female"], OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q6581072")))

g.add((SD["gender/male"], RDF.type, ECRM.E55_Type))
g.add((SD["gender/male"], RDFS.label, Literal("male", lang="en")))
g.add((SD["gender/male"], OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q6581097")))

g.add((SD["gender_type/wikidata"], RDF.type, ECRM.E55_Type))
g.add((SD["gender_type/wikidata"], RDFS.label, Literal("Wikidata Gender", lang="en")))
g.add((SD["gender_type/wikidata"], ECRM.P2i_is_type_of, SD["gender/female"]))
g.add((SD["gender_type/wikidata"], ECRM.P2i_is_type_of, SD["gender/male"]))

g.add((SD["gender/female"], ECRM.P2_has_type, SD["gender_type/wikidata"]))
g.add((SD["gender/male"], ECRM.P2_has_type, SD["gender_type/wikidata"]))

# Genre
g.add((SD["genre/lyrik"], RDF.type, ECRM.E55_Type))
g.add((SD["genre/lyrik"], RDFS.label, Literal("Lyrik", lang="de")))
g.add((SD["genre/lyrik"], ECRM.P2_has_type, SD["genre_type/sappho-digital"]))

g.add((SD["genre_type/sappho-digital"], RDF.type, ECRM.E55_Type))
g.add((SD["genre_type/sappho-digital"], RDFS.label, Literal("Sappho Digital Genre", lang="en")))
g.add((SD["genre_type/sappho-digital"], ECRM.P2i_is_type_of, SD["genre/lyrik"]))

# Autorin Sappho
g.add((SD["person/author_sappho"], RDF.type, ECRM.E21_Person))
g.add((SD["person/author_sappho"], RDFS.label, Literal("Sappho")))
g.add((SD["person/author_sappho"], ECRM.P131_is_identified_by, SD["appellation/author_sappho"]))
g.add((SD["person/author_sappho"], ECRM.P1_is_identified_by, SD["identifier/Q17892"]))
g.add((SD["person/author_sappho"], ECRM.P1_is_identified_by, SD["identifier/author_sappho"]))
g.add((SD["person/author_sappho"], ECRM.P2_has_type, SD["gender/female"]))
g.add((SD["person/author_sappho"], OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q17892")))

# Appellation Sappho
g.add((SD["appellation/author_sappho"], RDF.type, ECRM.E82_Actor_Appellation))
g.add((SD["appellation/author_sappho"], RDFS.label, Literal("Sappho", lang="en")))
g.add((SD["appellation/author_sappho"], ECRM.P131i_identifies, SD["person/author_sappho"]))

# Identifiers Sappho
g.add((SD["identifier/author_sappho"], RDF.type, ECRM.E42_Identifier))
g.add((SD["identifier/author_sappho"], RDFS.label, Literal("author_sappho")))
g.add((SD["identifier/author_sappho"], ECRM.P1i_identifies, SD["person/author_sappho"]))
g.add((SD["identifier/author_sappho"], ECRM.P2_has_type, SD["id_type/sappho-digital"]))
g.add((SD["id_type/sappho-digital"], ECRM.P2i_is_type_of, SD["identifier/author_sappho"]))

g.add((SD["identifier/Q17892"], RDF.type, ECRM.E42_Identifier))
g.add((SD["identifier/Q17892"], RDFS.label, Literal("Q17892")))
g.add((SD["identifier/Q17892"], ECRM.P1i_identifies, SD["person/author_sappho"]))
g.add((SD["identifier/Q17892"], ECRM.P2_has_type, SD["id_type/wikidata"]))
g.add((SD["id_type/wikidata"], ECRM.P2i_is_type_of, SD["identifier/Q17892"]))

# Editor Bagordo
g.add((SD["person/editor_bagordo"], RDF.type, ECRM.E21_Person))
g.add((SD["person/editor_bagordo"], RDFS.label, Literal("Andreas Bagordo")))
g.add((SD["person/editor_bagordo"], ECRM.P131_is_identified_by, SD["appellation/editor_bagordo"]))
g.add((SD["person/editor_bagordo"], ECRM.P1_is_identified_by, SD["identifier/Q495907"]))
g.add((SD["person/editor_bagordo"], ECRM.P1_is_identified_by, SD["identifier/editor_bagordo"]))
g.add((SD["person/editor_bagordo"], ECRM.P2_has_type, SD["gender/male"]))
g.add((SD["person/editor_bagordo"], OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q495907")))

g.add((SD["appellation/editor_bagordo"], RDF.type, ECRM.E82_Actor_Appellation))
g.add((SD["appellation/editor_bagordo"], RDFS.label, Literal("Andreas Bagordo", lang="en")))
g.add((SD["appellation/editor_bagordo"], ECRM.P131i_identifies, SD["person/editor_bagordo"]))

g.add((SD["identifier/editor_bagordo"], RDF.type, ECRM.E42_Identifier))
g.add((SD["identifier/editor_bagordo"], RDFS.label, Literal("editor_bagordo")))
g.add((SD["identifier/editor_bagordo"], ECRM.P1i_identifies, SD["person/editor_bagordo"]))
g.add((SD["identifier/editor_bagordo"], ECRM.P2_has_type, SD["id_type/sappho-digital"]))
g.add((SD["id_type/sappho-digital"], ECRM.P2i_is_type_of, SD["identifier/editor_bagordo"]))

g.add((SD["identifier/Q495907"], RDF.type, ECRM.E42_Identifier))
g.add((SD["identifier/Q495907"], RDFS.label, Literal("Q495907")))
g.add((SD["identifier/Q495907"], ECRM.P1i_identifies, SD["person/editor_bagordo"]))
g.add((SD["identifier/Q495907"], ECRM.P2_has_type, SD["id_type/wikidata"]))
g.add((SD["id_type/wikidata"], ECRM.P2i_is_type_of, SD["identifier/Q495907"]))

# Gesamtwerk
g.add((SD["work/sappho-work"], RDF.type, LRMOO.F1_Work))
g.add((SD["work/sappho-work"], RDFS.label, Literal("Sappho’s Work", lang="en")))
g.add((SD["work/sappho-work"], ECRM.P14_carried_out_by, SD["person/author_sappho"]))
g.add((SD["work/sappho-work"], LRMOO.R16i_was_created_by, SD["work_creation/sappho-work"]))

g.add((SD["work_creation/sappho-work"], RDF.type, LRMOO.F27_Work_Creation))
g.add((SD["work_creation/sappho-work"], RDFS.label, Literal("Creation of Sappho’s Work", lang="en")))
g.add((SD["work_creation/sappho-work"], ECRM.P14_carried_out_by, SD["person/author_sappho"]))
g.add((SD["work_creation/sappho-work"], LRMOO.R16_created, SD["work/sappho-work"]))

# Andreas Bagordos Edition

manifestation_uri = SD["manifestation/sappho_bagordo"]
manifestation_creation_uri = SD["manifestation_creation/sappho_bagordo"]
title_uri = SD["title/manifestation/sappho_bagordo"]
title_string_uri = SD["title_string/manifestation/sappho_bagordo"]
pub_place_uri = SD["pubPlace/pubPlace_42b32e43"]
publisher_uri = SD["publisher/publisher_patmos"]
time_span_uri = SD["timespan/2009"]

# Manifestation
g.add((manifestation_uri, RDF.type, LRMOO.F3_Manifestation))
g.add((manifestation_uri, RDFS.label, Literal("Andreas Bagordo’s Sappho edition", lang="en")))
g.add((manifestation_uri, LRMOO.R24i_was_created_through, manifestation_creation_uri))
g.add((manifestation_uri, ECRM.P102_has_title, title_uri))

# Manifestation Creation
g.add((manifestation_creation_uri, RDF.type, LRMOO.F30_Manifestation_Creation))
g.add((manifestation_creation_uri, RDFS.label, Literal("Manifestation creation of Andreas Bagordo’s Sappho edition", lang="en")))
g.add((manifestation_creation_uri, LRMOO.R24_created, manifestation_uri))
g.add((manifestation_creation_uri, ECRM.P14_carried_out_by, SD["person/editor_bagordo"]))
g.add((manifestation_creation_uri, ECRM.P14_carried_out_by, publisher_uri))
g.add((manifestation_creation_uri, ECRM.P4_has_time_span, time_span_uri))
g.add((manifestation_creation_uri, ECRM.P7_took_place_at, pub_place_uri))

# Title
g.add((title_uri, RDF.type, ECRM.E35_Title))
g.add((title_uri, ECRM.P102i_is_title_of, manifestation_uri))
g.add((title_uri, ECRM.P190_has_symbolic_content, title_string_uri))

g.add((title_string_uri, RDF.type, ECRM.E62_String))
g.add((title_string_uri, RDFS.label, Literal("Sappho. Gedichte. Griechisch-Deutsch", lang="de")))
g.add((title_string_uri, ECRM.P190i_is_content_of, title_uri))

# Publisher
g.add((publisher_uri, RDF.type, ECRM.E40_Legal_Body))
g.add((publisher_uri, RDFS.label, Literal("Patmos", lang="en")))
g.add((publisher_uri, ECRM.P14i_performed, manifestation_creation_uri))
g.add((publisher_uri, OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q1463096")))

# Publication Place
g.add((pub_place_uri, RDF.type, ECRM.E53_Place))
g.add((pub_place_uri, RDFS.label, Literal("Düsseldorf", lang="en")))
g.add((pub_place_uri, ECRM.P7i_witnessed, manifestation_creation_uri))
g.add((pub_place_uri, OWL.sameAs, URIRef("http://www.wikidata.org/entity/Q1718")))

# Time-Span
g.add((time_span_uri, RDF.type, ECRM.E52_Time_Span))
g.add((time_span_uri, RDFS.label, Literal("2009", datatype=XSD.gYear)))
g.add((time_span_uri, ECRM.P4_is_time_span_of, manifestation_creation_uri))

# Fragmente einlesen
all_expressions = []

with open(INPUT_FILE, newline='', encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter=';')
    for row in reader:
        qid_url = row["Wikidata Link"]
        label = row["Wikidata Label"]
        db_id = row["Database"]

        if "21351,1–8" in label:
            frag_id = "bibl_sappho_21351_1-8"
            frag_num = "21351,1–8"
        elif "21351+21376r" in label:
            frag_id = "bibl_sappho_21351_9-12_21376r_1-8"
            frag_num = "21351,9–12+21376r,1–8"
        else:
            frag_num = db_id
            frag_id = f"bibl_sappho_{frag_num}"

        frag_uri = SD[f"fragment/{frag_id}"]
        expr_uri = SD[f"expression/{frag_id}"]
        all_expressions.append(expr_uri)
        expr_creation_uri = SD[f"expression_creation/{frag_id}"]
        title_uri = SD[f"title/expression/{frag_id}"]
        title_str_uri = SD[f"title_string/expression/{frag_id}"]

        g.add((frag_uri, RDF.type, ECRM.E90_Symbolic_Object))
        g.add((frag_uri, RDFS.label, Literal(f"Fragment {frag_num} Voigt", lang="en")))
        g.add((frag_uri, LRMOO.R10i_is_member_of, SD["work/sappho-work"]))

        g.add((expr_creation_uri, RDF.type, LRMOO.F28_Expression_Creation))
        g.add((expr_creation_uri, RDFS.label, Literal(f"Expression creation of Fragment {frag_num} Voigt", lang="en")))
        g.add((expr_creation_uri, ECRM.P14_carried_out_by, SD["person/editor_bagordo"]))
        g.add((expr_creation_uri, LRMOO.R17_created, expr_uri))
        g.add((expr_creation_uri, LRMOO.R19_created_a_realisation_of, frag_uri))

        g.add((expr_uri, RDF.type, LRMOO.F2_Expression))
        g.add((expr_uri, RDFS.label, Literal(f"Expression of Fragment {frag_num} Voigt", lang="en")))
        g.add((expr_uri, LRMOO.R3i_realises, frag_uri))
        g.add((expr_uri, LRMOO.R17i_was_created_by, expr_creation_uri))
        g.add((expr_uri, ECRM.P102_has_title, title_uri))
        g.add((expr_uri, ECRM.P2_has_type, SD["genre/lyrik"]))
        g.add((expr_uri, LRMOO.R4i_is_embodied_in, SD["manifestation/sappho_bagordo"]))
        g.add((expr_uri, OWL.sameAs, URIRef(qid_url)))

        g.add((title_uri, RDF.type, ECRM.E35_Title))
        g.add((title_uri, ECRM.P102i_is_title_of, expr_uri))
        g.add((title_uri, ECRM.P190_has_symbolic_content, title_str_uri))

        g.add((title_str_uri, RDF.type, ECRM.E62_String))
        g.add((title_str_uri, RDFS.label, Literal(f"Fragment {frag_num} Voigt", lang="de")))
        g.add((title_str_uri, ECRM.P190i_is_content_of, title_uri))

        qid = qid_url.split("/")[-1]
        g.add((SD[f"identifier/{qid}"], RDF.type, ECRM.E42_Identifier))
        g.add((SD[f"identifier/{qid}"], RDFS.label, Literal(qid)))
        g.add((SD[f"identifier/{qid}"], ECRM.P1i_identifies, expr_uri))
        g.add((SD[f"identifier/{qid}"], ECRM.P2_has_type, SD["id_type/wikidata"]))
        g.add((SD["id_type/wikidata"], ECRM.P2i_is_type_of, SD[f"identifier/{qid}"]))

        g.add((SD[f"identifier/{frag_id}"], RDF.type, ECRM.E42_Identifier))
        g.add((SD[f"identifier/{frag_id}"], RDFS.label, Literal(frag_id)))
        g.add((SD[f"identifier/{frag_id}"], ECRM.P1i_identifies, expr_uri))
        g.add((SD[f"identifier/{frag_id}"], ECRM.P2_has_type, SD["id_type/sappho-digital"]))
        g.add((SD["id_type/sappho-digital"], ECRM.P2i_is_type_of, SD[f"identifier/{frag_id}"]))
    
    manifestation_uri = SD["manifestation/sappho_bagordo"]
    g.add((manifestation_uri, RDF.type, LRMOO.F3_Manifestation))
    g.add((manifestation_uri, RDFS.label, Literal("Andreas Bagordo’s Sappho edition", lang="en")))

    for expr_uri in all_expressions:
        g.add((manifestation_uri, LRMOO.R4_embodies, expr_uri))

# Speichern
Path(OUTPUT_FILE).parent.mkdir(parents=True, exist_ok=True)
g.serialize(destination=OUTPUT_FILE, format="turtle")