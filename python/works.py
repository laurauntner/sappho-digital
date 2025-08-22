from lxml import etree
from rdflib import Graph, Namespace, URIRef, Literal
from rdflib.namespace import RDF, RDFS, XSD, OWL
from pathlib import Path

# Pfade
INPUT_FILE = "../data/lists/sappho-rez_alle.xml"
OUTPUT_FILE = "../data/rdf/works.ttl"

# Namespaces
NSMAP = {"tei": "http://www.tei-c.org/ns/1.0"}
SD = Namespace("https://sappho-digital.com/")
ECRM = Namespace("http://erlangen-crm.org/current/")
LRMOO = Namespace("http://www.cidoc-crm.org/lrmoo/")

# Graph
g = Graph()
g.bind(":", SD)
g.bind("ecrm", ECRM)
g.bind("lrmoo", LRMOO)
g.bind("rdfs", RDFS)
g.bind("xsd", XSD)
g.bind("owl", OWL)

# XML parsen
parser = etree.XMLParser(recover=True)
tree = etree.parse(INPUT_FILE, parser=parser)
root = tree.getroot()
all_bibls = root.findall(".//tei:bibl", namespaces=NSMAP)
top_bibls = [b for b in all_bibls if b.getparent().tag != f"{{{NSMAP['tei']}}}bibl"]

for bibl in top_bibls:
    bibl_id = bibl.get("{http://www.w3.org/XML/1998/namespace}id")
    if not bibl_id:
        continue

    bibl_uri = SD[f"expression/{bibl_id}"]
    creation_expr_uri = SD[f"expression_creation/{bibl_id}"]

    title_el = bibl.find("tei:title[@type='text']", namespaces=NSMAP)
    title_string = title_el.text.strip() if title_el is not None and title_el.text else None

    # Expression
    g.add((bibl_uri, RDF.type, LRMOO.F2_Expression))
    if title_string:
        g.add((bibl_uri, RDFS.label, Literal(title_string, lang="de")))
        title_uri = SD[f"title/expression/{bibl_id}"]
        title_string_uri = SD[f"title_string/expression/{bibl_id}"]
        g.add((bibl_uri, ECRM.P102_has_title, title_uri))
        g.add((title_uri, RDF.type, ECRM.E35_Title))
        g.add((title_uri, ECRM.P102i_is_title_of, bibl_uri))
        g.add((title_uri, ECRM.P190_has_symbolic_content, title_string_uri))
        g.add((title_string_uri, RDF.type, ECRM.E62_String))
        g.add((title_string_uri, RDFS.label, Literal(title_string, lang="de")))
        g.add((title_string_uri, ECRM.P190i_is_content_of, title_uri))

    g.add((bibl_uri, LRMOO.R17i_was_created_by, creation_expr_uri))

    # Expression Creation
    expr_label = title_string if title_string else "[??]"
    g.add((creation_expr_uri, RDF.type, LRMOO.F28_Expression_Creation))
    g.add((creation_expr_uri, RDFS.label, Literal(f"Expression creation of {expr_label}", lang="en")))
    g.add((creation_expr_uri, LRMOO.R17_created, bibl_uri))

    # Identifiers
    ref = bibl.get("ref")
    g.add((bibl_uri, ECRM.P1_is_identified_by, SD[f"identifier/{bibl_id}"]))
    g.add((SD[f"identifier/{bibl_id}"], RDF.type, ECRM.E42_Identifier))
    g.add((SD[f"identifier/{bibl_id}"], RDFS.label, Literal(bibl_id)))
    g.add((SD[f"identifier/{bibl_id}"], ECRM.P1i_identifies, bibl_uri))
    g.add((SD[f"identifier/{bibl_id}"], ECRM.P2_has_type, SD["id_type/sappho-digital"]))

    if ref and "wikidata.org/entity/" in ref:
        g.add((bibl_uri, OWL.sameAs, URIRef(ref)))
        qid = ref.split("/")[-1]
        g.add((bibl_uri, ECRM.P1_is_identified_by, SD[f"identifier/{qid}"]))
        g.add((SD[f"identifier/{qid}"], RDF.type, ECRM.E42_Identifier))
        g.add((SD[f"identifier/{qid}"], RDFS.label, Literal(qid)))
        g.add((SD[f"identifier/{qid}"], ECRM.P1i_identifies, bibl_uri))
        g.add((SD[f"identifier/{qid}"], ECRM.P2_has_type, SD["id_type/wikidata"]))

    # Genre
    genre_el = bibl.find("tei:note[@type='genre']", namespaces=NSMAP)
    if genre_el is not None and genre_el.text:
        genre_raw = genre_el.text.strip()

        # Sonderfälle
        genres = []
        if genre_raw == "Lyrik/Prosa":
            genres = ["Lyrik", "Prosa"]
        elif genre_raw.endswith("?"):
            genres = [genre_raw.rstrip("?").strip()]
        else:
            genres = [genre_raw]

        for genre_string in genres:
            genre_uri = SD[f"genre/{genre_string.lower().replace(' ', '_')}"]
            g.add((genre_uri, RDF.type, ECRM.E55_Type))
            g.add((genre_uri, RDFS.label, Literal(genre_string, lang="de")))
            g.add((genre_uri, ECRM.P2_has_type, SD["genre_type/sappho-digital"]))
            g.add((genre_uri, ECRM.P2_is_type_of, bibl_uri))
            g.add((bibl_uri, ECRM.P2_has_type, genre_uri))

    # Digital Copy
    ref_el = bibl.find("tei:ref", namespaces=NSMAP)
    if ref_el is not None and ref_el.text:
        url = ref_el.text.strip()
        digital_uri = SD[f"digital/{bibl_id}"]
        g.add((digital_uri, RDF.type, ECRM.E73_Information_Object))
        digital_label = title_string or work_title or "[??]"
        g.add((digital_uri, RDFS.label, Literal(f"Digital copy of {digital_label}", lang="en")))
        g.add((digital_uri, ECRM.P138_represents, bibl_uri))
        g.add((digital_uri, RDFS.seeAlso, URIRef(url)))
        g.add((bibl_uri, ECRM.P138i_has_representation, digital_uri))

    # Dates
    date_created = bibl.find("tei:date[@type='created']", namespaces=NSMAP)
    date_published = bibl.find("tei:date[@type='published']", namespaces=NSMAP)

    if date_created is not None and "when" in date_created.attrib:
        year = date_created.get("when")
        ts_uri = SD[f"timespan/{year}"]
        g.add((ts_uri, RDF.type, ECRM["E52_Time-Span"]))
        g.add((ts_uri, RDFS.label, Literal(year, datatype=XSD.gYear)))
        g.add((ts_uri, ECRM["P4i_is_time-span_of"], creation_expr_uri))
        g.add((creation_expr_uri, ECRM.P4_has_time_span, ts_uri))

    # Manifestation
    if date_published is not None:
        nested_bibl = bibl.find("tei:bibl", namespaces=NSMAP)
        if nested_bibl is not None:
            nested_id = nested_bibl.get("{http://www.w3.org/XML/1998/namespace}id") or bibl_id
            work_title_el = nested_bibl.find("tei:title[@type='work']", namespaces=NSMAP)
            work_title = work_title_el.text.strip() if work_title_el is not None and work_title_el.text else None
        else:
            nested_id = bibl_id
            work_title = title_string

        final_manifestation_label = work_title or "[??]"
        manifestation_uri = SD[f"manifestation/{nested_id}"]
        creation_manif_uri = SD[f"manifestation_creation/{nested_id}"]

        g.add((manifestation_uri, RDF.type, LRMOO.F3_Manifestation))
        g.add((manifestation_uri, RDFS.label, Literal(final_manifestation_label, lang="de")))
        g.add((manifestation_uri, LRMOO.R4_embodies, bibl_uri))
        g.add((manifestation_uri, LRMOO.R24i_was_created_through, creation_manif_uri))

        g.add((creation_manif_uri, RDF.type, LRMOO.F30_Manifestation_Creation))
        g.add((creation_manif_uri, RDFS.label, Literal(f"Manifestation creation of {final_manifestation_label}", lang="en")))
        g.add((creation_manif_uri, LRMOO.R24_created, manifestation_uri))

        # Zeitspanne
        if "when" in date_published.attrib:
            year_pub = date_published.get("when")
            ts_pub_uri = SD[f"timespan/{year_pub}"]
            g.add((ts_pub_uri, RDF.type, ECRM["E52_Time-Span"]))
            g.add((ts_pub_uri, RDFS.label, Literal(year_pub, datatype=XSD.gYear)))
            g.add((creation_manif_uri, ECRM.P4_has_time_span, ts_pub_uri))
            g.add((ts_pub_uri, ECRM["P4i_is_time-span_of"], creation_manif_uri))

        # Ort
        for pubplace_el in bibl.findall("tei:pubPlace", namespaces=NSMAP):
            place_ref = pubplace_el.get("ref")
            place_label = pubplace_el.text.strip() if pubplace_el.text else "Unknown"
            place_uri = (
                SD[f"place/{place_ref.split('/')[-1]}"]
                if place_ref else SD[f"place/{place_label.replace(' ', '_')}"]
            )
            g.add((place_uri, RDF.type, ECRM.E53_Place))
            g.add((place_uri, RDFS.label, Literal(place_label, lang="de")))
            if place_ref:
                g.add((place_uri, OWL.sameAs, URIRef(place_ref)))
            g.add((place_uri, ECRM.P7i_witnessed, creation_manif_uri))
            g.add((creation_manif_uri, ECRM.P7_took_place_at, place_uri))

        # Publisher
        for pub in bibl.findall("tei:publisher", namespaces=NSMAP):
            if pub.text:
                pub_label = pub.text.strip()
                pub_ref = pub.get("ref")
                pub_uri = (
                    SD[f"publisher/{pub_ref.split('/')[-1]}"]
                    if pub_ref else SD[f"publisher/{pub_label.replace(' ', '_')}"]
                )
                g.add((pub_uri, RDF.type, ECRM.E40_Legal_Body))
                g.add((pub_uri, RDFS.label, Literal(pub_label, lang="de")))
                if pub_ref:
                    g.add((pub_uri, OWL.sameAs, URIRef(pub_ref)))
                g.add((pub_uri, ECRM.P14i_performed, creation_manif_uri))
                g.add((creation_manif_uri, ECRM.P14_carried_out_by, pub_uri))

    # Autor_innen
    for auth in bibl.findall("tei:author", namespaces=NSMAP):
        auth_id = auth.get("{http://www.w3.org/XML/1998/namespace}id")
        if auth_id:
            person_uri = SD[f"person/{auth_id}"]
            g.add((person_uri, RDF.type, ECRM.E21_Person))
            g.add((person_uri, RDFS.label, Literal(auth.text.strip(), lang="de")))
            g.add((person_uri, ECRM.P14i_performed, creation_expr_uri))
            g.add((creation_expr_uri, ECRM.P14_carried_out_by, person_uri))
            if date_published is not None:
                g.add((person_uri, ECRM.P14i_performed, creation_manif_uri))

# Speichern
Path(OUTPUT_FILE).parent.mkdir(parents=True, exist_ok=True)
g.serialize(destination=OUTPUT_FILE, format="turtle")