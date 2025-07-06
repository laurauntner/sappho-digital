import pandas as pd
import re
import xml.etree.ElementTree as ET
from xml.dom import minidom

# Excel-Datei
excel_file = "../../doktorat/Diss/Sappho-Rezeption/Sappho-Rez_vollstaendig.xlsx"

# Spalten inkl. QIDs
use_columns = [
    "Bearbeitungsstand",
    "Entstehungsjahr",
    "Publikationsjahr/Aufführungsjahr",
    "Titel",
    "Enthalten in",
    "Autor_in",
    "Gattung",
    "Publikationsort/Aufführungsort",
    "Verlag",
    "Link",
    "Werk QID",
    "Hauptwerk QID",
    "Autor_in QID",
    "Publikationsort QID",
    "Verlag QID"
]

# TEI-Konfiguration
tei_configs = {
    "alle": {
        "filename": "../data/lists/sappho-rez_alle.xml",
        "title": "Alle Rezeptionszeugnisse",
        "filter": None
    },
    "prosa": {
        "filename": "../data/lists/sappho-rez_prosa.xml",
        "title": "Prosaische Rezeptionszeugnisse",
        "filter": "Prosa"
    },
    "lyrik": {
        "filename": "../data/lists/sappho-rez_lyrik.xml",
        "title": "Lyrische Rezeptionszeugnisse",
        "filter": "Lyrik"
    },
    "drama": {
        "filename": "../data/lists/sappho-rez_drama.xml",
        "title": "Dramatische Rezeptionszeugnisse",
        "filter": "Drama"
    },
    "sonstige": {
        "filename": "../data/lists/sappho-rez_sonstige.xml",
        "title": "Sonstige Rezeptionszeugnisse",
        "filter": "Sonstige"
    }
}

# Datumselemente erzeugen
def create_date_element(tag_type, value):
    value = str(value).strip()
    if not value:
        return None

    date = ET.Element("date", {"type": tag_type})
    original = value

    match_century = re.match(r"(\d{1,2})\.\s*(Jahrhundert|Jhdt)\.?\??", value)
    if match_century:
        century = int(match_century.group(1))
        midpoint = (century - 1) * 100 + 50
        date.attrib["when"] = str(midpoint)
        date.text = original
        return date

    match_decade = re.match(r"(\d{3})0er\??", value)
    if match_decade:
        decade = int(match_decade.group(1)) * 10 + 5
        date.attrib["when"] = str(decade)
        date.text = original
        return date

    match_questionable_year = re.match(r"(\d{4})\?", value)
    if match_questionable_year:
        date.attrib["when"] = match_questionable_year.group(1)
        date.text = original
        return date

    match_year_range = re.match(r"(\d{4})/(\d{4})", value)
    if match_year_range:
        date.attrib["notBefore"] = match_year_range.group(1)
        date.attrib["notAfter"] = match_year_range.group(2)
        date.text = original
        return date

    match_full_range = re.match(r"(\d{4})(/\d{4})?–(\d{4})(/\d{4})?", value)
    if match_full_range:
        not_before = match_full_range.group(1)
        not_after = match_full_range.group(3)
        date.attrib["notBefore"] = not_before
        date.attrib["notAfter"] = not_after
        date.text = original
        return date

    match_approx = re.match(r"um (\d{4})", value)
    if match_approx:
        date.attrib["when"] = match_approx.group(1)
        date.text = original
        return date

    match_nn = re.match(r"n\. n\.\s*(\d{4})", value, re.IGNORECASE)
    if match_nn:
        date.attrib["notAfter"] = match_nn.group(1)
        date.text = original
        return date

    if re.match(r"^\d{4}$", value):
        date.attrib["when"] = value
        date.text = value
        return date

    date.text = value
    return date

# QIDs
def create_element_with_ref(tag, text, qid):
    if not text.strip():
        return None
    attrib = {}
    qid = qid.strip()
    if qid:
        attrib["ref"] = f"https://www.wikidata.org/entity/{qid}"
    elem = ET.Element(tag, attrib)
    elem.text = text.strip()
    return elem

# XML hübsch formatieren
def prettify(elem):
    rough_string = ET.tostring(elem, encoding="utf-8")
    return minidom.parseString(rough_string).toprettyxml(indent="    ")

# Daten laden
df_raw = pd.read_excel(excel_file, dtype=str).fillna("")
df_raw = df_raw[df_raw["Bearbeitungsstand"].str.lower() == "done"]
df = df_raw[use_columns[1:]]

# TEI erzeugen
def generate_tei(df_filtered, title_text):
    tei = ET.Element("TEI", xmlns="http://www.tei-c.org/ns/1.0")
    teiHeader = ET.SubElement(tei, "teiHeader")
    fileDesc = ET.SubElement(teiHeader, "fileDesc")
    titleStmt = ET.SubElement(fileDesc, "titleStmt")
    title = ET.SubElement(titleStmt, "title", {"type": "main"})
    title.text = title_text

    publicationStmt = ET.SubElement(fileDesc, "publicationStmt")
    ET.SubElement(publicationStmt, "publisher").text = "Laura Untner"
    ET.SubElement(publicationStmt, "pubPlace").text = "Wien/Berlin"
    ET.SubElement(publicationStmt, "date", {"when": "2025"}).text = "2025"
    availability = ET.SubElement(publicationStmt, "availability")
    licence = ET.SubElement(availability, "licence", {"target": "https://creativecommons.org/licenses/by/4.0/deed.de"})
    ET.SubElement(licence, "p").text = "CC BY 4.0"
    sourceDesc = ET.SubElement(fileDesc, "sourceDesc")
    ET.SubElement(sourceDesc, "p").text = "Born digital"

    text = ET.SubElement(tei, "text")
    body = ET.SubElement(text, "body")
    listBibl = ET.SubElement(body, "listBibl")

    for _, row in df_filtered.iterrows():
        bibl = ET.SubElement(listBibl, "bibl")

        # URIs
        qid = row.get("Werk QID", "").strip()
        if qid:
            bibl.attrib["ref"] = f"https://www.wikidata.org/entity/{qid}"

        date_created = create_date_element("created", row["Entstehungsjahr"])
        if date_created is not None:
            bibl.append(date_created)

        date_published = create_date_element("published", row["Publikationsjahr/Aufführungsjahr"])
        if date_published is not None:
            bibl.append(date_published)

        if row["Titel"].strip():
            ET.SubElement(bibl, "title", {"type": "text"}).text = row["Titel"]

        if row["Enthalten in"].strip():
            title_text = row["Enthalten in"].strip()
            qid = row.get("Hauptwerk QID", "").strip()
            if qid:
                work_bibl = ET.Element("bibl", {"ref": f"https://www.wikidata.org/entity/{qid}"})
            else:
                work_bibl = ET.Element("bibl")
        
            ET.SubElement(work_bibl, "title", {"type": "work"}).text = title_text
            bibl.append(work_bibl)

        authors = [a.strip() for a in row["Autor_in"].split("und") if a.strip()]
        author_ids = [a.strip() for a in row.get("Autor_in QID", "").split("und")]

        for i, author in enumerate(authors):
            ref = author_ids[i] if i < len(author_ids) else ""
            author_elem = create_element_with_ref("author", author, ref)
            if author_elem is not None:
                bibl.append(author_elem)

        if row["Gattung"].strip():
            ET.SubElement(bibl, "note", {"type": "genre"}).text = row["Gattung"].strip()

        places = [p.strip() for p in row["Publikationsort/Aufführungsort"].split("/") if p.strip()]
        place_ids = [p.strip() for p in row.get("Publikationsort QID", "").split("/")]

        for i, place in enumerate(places):
            ref = place_ids[i] if i < len(place_ids) else ""
            place_elem = create_element_with_ref("pubPlace", place, ref)
            if place_elem is not None:
                bibl.append(place_elem)

        publishers = [p.strip() for p in row["Verlag"].split("/") if p.strip()]
        publisher_ids = [p.strip() for p in row.get("Verlag QID", "").split("/")]

        for i, publisher in enumerate(publishers):
            ref = publisher_ids[i] if i < len(publisher_ids) else ""
            pub_elem = create_element_with_ref("publisher", publisher, ref)
            if pub_elem is not None:
                bibl.append(pub_elem)

        if row["Link"].strip():
            ref = ET.SubElement(bibl, "ref", {"target": row["Link"].strip()})
            ref.text = row["Link"].strip()

    return tei

# Export
for key, config in tei_configs.items():
    if config["filter"] == "Sonstige":
        df_filtered = df[
            df["Gattung"].apply(
                lambda x: all(
                    g.strip("? ") not in ["Prosa", "Lyrik", "Drama"]
                    for g in str(x).split("/")
                )
            )
        ]
    elif config["filter"]:
        df_filtered = df[
            df["Gattung"].apply(
                lambda x: any(
                    g.strip("? ") == config["filter"]
                    for g in str(x).split("/")
                )
            )
        ]
    else:
        df_filtered = df

    tei_element = generate_tei(df_filtered, config["title"])
    xml_str = prettify(tei_element)

    with open(config["filename"], "w", encoding="utf-8") as f:
        f.write(xml_str)