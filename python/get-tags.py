import os
import xml.etree.ElementTree as ET
import csv
from collections import defaultdict

IGNORE_TAGS = {"XML", "title", "text", "status"}

def remove_namespace(tag):
    return tag.split('}', 1)[1] if '}' in tag else tag

def find_tags(folder_path):
    tag_values = defaultdict(set)

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
                        value += f" ({modus})"

                if value:
                    tag_values[tag].add(value)

        except ET.ParseError as e:
            print(f"Warnung: Datei {filename} konnte nicht geparst werden: {e}.")
    
    return tag_values

def check_duplicate_values_across_tags(tag_values):
    value_to_tags = defaultdict(set)

    for tag, values in tag_values.items():
        for value in values:
            normalized = value.lower()
            value_to_tags[normalized].add(tag)

    for value, tags in value_to_tags.items():
        if len(tags) > 1:
            print(f'⚠️  WARNUNG: Der Wert "{value}" kommt mehrfach vor in den Spalten: {", ".join(sorted(tags))}')

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
    output_file = os.path.join(output_path, "elemente_und_werte.csv")

    os.makedirs(output_path, exist_ok=True)

    tag_values = find_tags(input_path)
    check_duplicate_values_across_tags(tag_values)
    write_table(tag_values, output_file)

    print(f"\n✅ Tabelle mit {len(tag_values)} Elementen und ihren Werten gespeichert in:\n{output_file}")