import os
import xml.etree.ElementTree as ET
import csv
from collections import defaultdict

IGNORE_TAGS = {"XML", "title", "text", "status", "id", "vorlageSeiten", "anthologieSeiten"}

PERSON_ARTS = {"real", "fictional", "type"}
ORT_ARTS = {"real", "fictional"}


def remove_namespace(tag):
    return tag.split('}', 1)[1] if '}' in tag else tag


def find_tags(folder_path):

    tag_docs = defaultdict(set)
    tag_value_docs = defaultdict(lambda: defaultdict(set))
    value_canonical = defaultdict(dict)

    for filename in os.listdir(folder_path):
        if not filename.endswith(".xml"):
            continue
        file_path = os.path.join(folder_path, filename)
        try:
            tree = ET.parse(file_path)
            root = tree.getroot()

            for elem in root.iter():
                tag = remove_namespace(elem.tag)

                if tag in IGNORE_TAGS:
                    continue

                if "type" in elem.attrib:
                    value = elem.attrib["type"].strip()
                else:
                    value = (elem.text or "").strip()

                if tag == "stoff" and "modus" in elem.attrib:
                    modus = elem.attrib["modus"].strip()
                    if modus:
                        value = f"{value} ({modus})" if value else f"({modus})"

                if not value:
                    continue

                if "art" in elem.attrib:
                    art_val = elem.attrib["art"].strip().lower()

                    if tag == "person":
                        if art_val in PERSON_ARTS:
                            tag_key = f"{tag}@{art_val}"
                        else:
                            print(f"⚠️ Warnung: Unerwarteter art-Wert bei <person>: {art_val}")
                            tag_key = f"{tag}@{art_val}"

                    elif tag == "ort":
                        if art_val in ORT_ARTS:
                            tag_key = f"{tag}@{art_val}"
                        else:
                            print(f"⚠️ Warnung: Unerwarteter art-Wert bei <ort>: {art_val}")
                            tag_key = f"{tag}@{art_val}"

                    else:
                        tag_key = f"{tag}@{art_val}"
                else:
                    tag_key = tag

                tag_docs[tag_key].add(filename)

                norm_val = value.lower()
                tag_value_docs[tag_key][norm_val].add(filename)
                if norm_val not in value_canonical[tag_key]:
                    value_canonical[tag_key][norm_val] = value

        except ET.ParseError as e:
            print(f"Warnung: Datei {filename} konnte nicht geparst werden: {e}.")

    eligible_tags = {tag for tag, docs in tag_docs.items() if len(docs) >= 2}

    filtered = {}
    removed_tags = []
    removed_values_info = []

    for tag in sorted(eligible_tags):
        kept_values = []
        for norm_val, docs in tag_value_docs[tag].items():
            if len(docs) >= 2:
                kept_values.append(value_canonical[tag][norm_val])
        if kept_values:
            filtered[tag] = set(kept_values)
            removed_count = len(tag_value_docs[tag]) - len(kept_values)
            if removed_count > 0:
                removed_values_info.append(f"{tag}: {removed_count} Wert(e) entfernt")
        else:
            removed_tags.append(tag)

    if removed_tags:
        print(f"ℹ️ {len(removed_tags)} Tag(s) entfernt, da deren Werte nur in je einem Dokument vorkamen: {', '.join(removed_tags)}")
    if removed_values_info:
        print("ℹ️ Werte-Filterung pro Tag:", "; ".join(removed_values_info))

    return filtered


def check_duplicate_values_across_tags(tag_values):
    value_to_tags = defaultdict(set)

    for tag, values in tag_values.items():
        for value in values:
            normalized = value.lower()
            value_to_tags[normalized].add(tag)

    for value, tags in value_to_tags.items():
        if len(tags) > 1:
            print(
                f'⚠️ WARNUNG: Der Wert "{value}" kommt mehrfach vor in den Spalten: {", ".join(sorted(tags))}'
            )


def write_table(tag_values, output_file_path):
    all_tags = sorted(tag_values.keys())
    max_lines = max((len(values) for values in tag_values.values()), default=0)

    lines = []
    for i in range(max_lines):
        line = []
        for tag in all_tags:
            values_list = sorted(tag_values[tag])
            line.append(values_list[i] if i < len(values_list) else "")
        lines.append(line)

    with open(output_file_path, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(all_tags)
        writer.writerows(lines)


if __name__ == "__main__":
    input_path = "../../doktorat/Diss/Sappho-Rezeption/XML"
    output_path = "../../doktorat/Diss/Sappho-Rezeption/Analysehilfen"
    output_file = os.path.join(output_path, "haeufige_elemente_und_werte.csv")

    os.makedirs(output_path, exist_ok=True)

    tag_values = find_tags(input_path)  # bereits gefiltert auf >= 2 Dokumente
    check_duplicate_values_across_tags(tag_values)
    write_table(tag_values, output_file)

    print(f"\n✅ Tabelle mit {len(tag_values)} Spalten gespeichert in:\n{output_file}")
