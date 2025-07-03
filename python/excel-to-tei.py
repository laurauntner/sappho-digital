import pandas as pd
import re
import xml.etree.ElementTree as ET
from xml.dom import minidom

# excel file
excel_file = "../../doktorat/Diss/Sappho-Rezeption/Sappho_Rez_vollstaendig.xlsx"

# columns
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
    "Link"
]

# tei files
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

# date elements
def create_date_element(tag_type, value):
    value = str(value).strip()
    if not value:
        return None

    date = ET.Element("date", {"type": tag_type})
    original = value

    # Jahrhundert/Jhdt.
    match_century = re.match(r"(\d{1,2})\.\s*(Jahrhundert|Jhdt)\.?\??", value)
    if match_century:
        century = int(match_century.group(1))
        midpoint = (century - 1) * 100 + 50
        date.attrib["when"] = str(midpoint)
        date.text = original
        return date

    # Jahrzehnt
    match_decade = re.match(r"(\d{3})0er\??", value)
    if match_decade:
        decade = int(match_decade.group(1)) * 10 + 5
        date.attrib["when"] = str(decade)
        date.text = original
        return date

    # Fragezeichen
    match_questionable_year = re.match(r"(\d{4})\?", value)
    if match_questionable_year:
        date.attrib["when"] = match_questionable_year.group(1)
        date.text = original
        return date

    # Schrägstriche
    match_year_range = re.match(r"(\d{4})/(\d{4})", value)
    if match_year_range:
        date.attrib["notBefore"] = match_year_range.group(1)
        date.attrib["notAfter"] = match_year_range.group(2)
        date.text = original
        return date

    # Halbgeviertstriche
    match_full_range = re.match(r"(\d{4})(/\d{4})?–(\d{4})(/\d{4})?", value)
    if match_full_range:
        not_before = match_full_range.group(1)
        not_after = match_full_range.group(3)
        date.attrib["notBefore"] = not_before
        date.attrib["notAfter"] = not_after
        date.text = original
        return date

    # um
    match_approx = re.match(r"um (\d{4})", value)
    if match_approx:
        date.attrib["when"] = match_approx.group(1)
        date.text = original
        return date

    # n. n.
    match_nn = re.match(r"n\. n\.\s*(\d{4})", value, re.IGNORECASE)
    if match_nn:
        date.attrib["notAfter"] = match_nn.group(1)
        date.text = original
        return date

    # normal
    if re.match(r"^\d{4}$", value):
        date.attrib["when"] = value
        date.text = value
        return date

    date.text = value
    return date

# format
def prettify(elem):
    rough_string = ET.tostring(elem, encoding="utf-8")
    return minidom.parseString(rough_string).toprettyxml(indent="    ")

# load excel file
df_raw = pd.read_excel(excel_file, dtype=str).fillna("")

# only "done"
df_raw = df_raw[df_raw["Bearbeitungsstand"].str.lower() == "done"]

df = df_raw[use_columns[1:]]

# create tei files
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

        date_created = create_date_element("created", row["Entstehungsjahr"])
        if date_created is not None:
            bibl.append(date_created)

        date_published = create_date_element("published", row["Publikationsjahr/Aufführungsjahr"])
        if date_published is not None:
            bibl.append(date_published)

        if row["Titel"].strip():
            ET.SubElement(bibl, "title", {"type": "text"}).text = row["Titel"]

        if row["Enthalten in"].strip():
            ET.SubElement(bibl, "title", {"type": "work"}).text = row["Enthalten in"]

        authors = [a.strip() for a in row["Autor_in"].split("und") if a.strip()]
        for author in authors:
            ET.SubElement(bibl, "author").text = author

        if row["Gattung"].strip():
            ET.SubElement(bibl, "note", {"type": "genre"}).text = row["Gattung"].strip()

        for place in [p.strip() for p in row["Publikationsort/Aufführungsort"].split("/") if p.strip()]:
            ET.SubElement(bibl, "pubPlace").text = place

        for publisher in [p.strip() for p in row["Verlag"].split("/") if p.strip()]:
            ET.SubElement(bibl, "publisher").text = publisher

        if row["Link"].strip():
            ref = ET.SubElement(bibl, "ref", {"target": row["Link"]})
            ref.text = row["Link"]

    return tei

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
