import pandas as pd
import re
import xml.etree.ElementTree as ET
from xml.dom import minidom

# Excel-Datei
excel_file = "../../doktorat/Diss/Sappho-Rezeption/Sappho-Rez_vollstaendig.xlsx"

# Spalten
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
    "Verlag QID",
    "Interne Werk-ID",
    "Interne Hauptwerk-ID",
    "Interne Autor_in-ID",
    "Interne Ort-ID",
    "Interne Verlag-ID"
]

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
    },
}

def create_date_element(tag_type, value):
    value = str(value).strip()
    if not value:
        return None

    date = ET.Element("date", {"type": tag_type})
    original = value

    # Jahrhundert
    match_century = re.match(r"(\d{1,2})\.\s*(Jahrhundert|Jhdt)\.??", value)
    if match_century:
        century = int(match_century.group(1))
        midpoint = (century - 1) * 100 + 50
        date.attrib["when"] = str(midpoint)
        date.text = original
        return date

    # Dekade
    match_decade = re.match(r"(\d{3})0er??", value)
    if match_decade:
        decade = int(match_decade.group(1)) * 10 + 5
        date.attrib["when"] = str(decade)
        date.text = original
        return date

    # Unklarheit
    match_questionable_year = re.match(r"(\d{4})\?", value)
    if match_questionable_year:
        date.attrib["when"] = match_questionable_year.group(1)
        date.text = original
        return date

    # Jahrspanne mit Schrägstrich
    match_year_range = re.match(r"(\d{4})/(\d{4})", value)
    if match_year_range:
        date.attrib["notBefore"] = match_year_range.group(1)
        date.attrib["notAfter"] = match_year_range.group(2)
        date.text = original
        return date

    # Spannweite
    match_full_range = re.match(r"(\d{4})(/\d{4})?–(\d{4})(/\d{4})?", value)
    if match_full_range:
        date.attrib["notBefore"] = match_full_range.group(1)
        date.attrib["notAfter"] = match_full_range.group(3)
        date.text = original
        return date

    # "um XXXX"
    match_approx = re.match(r"um (\d{4})", value)
    if match_approx:
        date.attrib["when"] = match_approx.group(1)
        date.text = original
        return date

    # "n. n. XXXX"
    match_nn = re.match(r"n\. n\.\s*(\d{4})", value, re.IGNORECASE)
    if match_nn:
        date.attrib["notAfter"] = match_nn.group(1)
        date.text = original
        return date

    # Normales Jahr
    if re.match(r"^\d{4}$", value):
        date.attrib["when"] = value
        date.text = value
        return date

    # Fallback
    date.text = value
    return date

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

def prettify(elem):
    rough_string = ET.tostring(elem, encoding="utf-8")
    return minidom.parseString(rough_string).toprettyxml(indent="    ")

# Daten laden
df_raw = pd.read_excel(excel_file, dtype=str).fillna("")
df_raw = df_raw[df_raw["Bearbeitungsstand"].str.lower() == "done"]
df = df_raw[use_columns[1:]]

def generate_tei(df_filtered, title_text):
    tei = ET.Element("TEI", xmlns="http://www.tei-c.org/ns/1.0")
    teiHeader = ET.SubElement(tei, "teiHeader")
    fileDesc = ET.SubElement(teiHeader, "fileDesc")
    titleStmt = ET.SubElement(fileDesc, "titleStmt")
    ET.SubElement(titleStmt, "title", {"type": "main"}).text = title_text
    pubStmt = ET.SubElement(fileDesc, "publicationStmt")
    ET.SubElement(pubStmt, "publisher").text = "Laura Untner"
    ET.SubElement(pubStmt, "pubPlace").text = "Wien/Berlin"
    ET.SubElement(pubStmt, "date", {"when": "2025"}).text = "2025"
    availability = ET.SubElement(pubStmt, "availability")
    licence = ET.SubElement(availability, "licence", {"target": "https://creativecommons.org/licenses/by/4.0/deed.de"})
    ET.SubElement(licence, "p").text = "CC BY 4.0"
    sourceDesc = ET.SubElement(fileDesc, "sourceDesc")
    ET.SubElement(sourceDesc, "p").text = "Born digital"

    text = ET.SubElement(tei, "text")
    body = ET.SubElement(text, "body")
    listBibl = ET.SubElement(body, "listBibl")

    for _, row in df_filtered.iterrows():
        bibl = ET.SubElement(listBibl, "bibl")

        if row["Werk QID"].strip():
            bibl.attrib["ref"] = f"https://www.wikidata.org/entity/{row['Werk QID'].strip()}"
        if row["Interne Werk-ID"].strip():
            bibl.attrib["xml:id"] = row["Interne Werk-ID"].strip()

        ET.SubElement(bibl, "title", {"type": "text"}).text = row["Titel"]

        date_created = create_date_element("created", row["Entstehungsjahr"])
        if date_created is not None:
            bibl.append(date_created)

        date_published = create_date_element("published", row["Publikationsjahr/Aufführungsjahr"])
        if date_published is not None:
            bibl.append(date_published)

        # Enthaltene Werke
        work_titles = [row["Enthalten in"].strip()] if row["Enthalten in"].strip() else []
        work_ids = [t.strip() for t in row["Interne Hauptwerk-ID"].split(",") if t.strip()]
        for i, title_text in enumerate(work_titles):
            work_bibl = ET.Element("bibl")
            if i < len(work_ids):
                work_bibl.attrib["xml:id"] = work_ids[i]
            ET.SubElement(work_bibl, "title", {"type": "work"}).text = title_text
            bibl.append(work_bibl)

        for i, author in enumerate(row["Autor_in"].split("und")):
            author = author.strip()
            qid = row["Autor_in QID"].split("und")[i].strip() if i < len(row["Autor_in QID"].split("und")) else ""
            elem = create_element_with_ref("author", author, qid)
            if elem is not None and row["Interne Autor_in-ID"].strip():
                elem.attrib["xml:id"] = row["Interne Autor_in-ID"].strip()
            if elem is not None:
                bibl.append(elem)

        if row["Gattung"].strip():
            ET.SubElement(bibl, "note", {"type": "genre"}).text = row["Gattung"].strip()

        for i, place in enumerate(row["Publikationsort/Aufführungsort"].split("/")):
            place = place.strip()
            qid = row["Publikationsort QID"].split("/")[i].strip() if i < len(row["Publikationsort QID"].split("/")) else ""
            elem = create_element_with_ref("pubPlace", place, qid)
            ids = [t.strip() for t in row["Interne Ort-ID"].split(",") if t.strip()]
            if elem is not None and i < len(ids):
                elem.attrib["xml:id"] = ids[i]
            if elem is not None:
                bibl.append(elem)

        for i, verlag in enumerate(row["Verlag"].split("/")):
            verlag = verlag.strip()
            qid = row["Verlag QID"].split("/")[i].strip() if i < len(row["Verlag QID"].split("/")) else ""
            elem = create_element_with_ref("publisher", verlag, qid)
            ids = [t.strip() for t in row["Interne Verlag-ID"].split(",") if t.strip()]
            if elem is not None and i < len(ids):
                elem.attrib["xml:id"] = ids[i]
            if elem is not None:
                bibl.append(elem)

        if row["Link"].strip():
            ET.SubElement(bibl, "ref", {"target": row["Link"].strip()}).text = row["Link"].strip()

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