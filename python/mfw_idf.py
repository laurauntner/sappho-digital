import os
import xml.etree.ElementTree as ET
import csv
import spacy
from collections import Counter, defaultdict

nlp = spacy.load("de_core_news_md")

def extract_data(folder_path):
    word_counter = Counter()
    word_docs = defaultdict(set)
    pos_counter_noun = Counter()
    pos_counter_adj = Counter()
    total_docs = 0

    for filename in os.listdir(folder_path):
        if not filename.endswith(".xml"):
            continue
        file_path = os.path.join(folder_path, filename)
        total_docs += 1
        try:
            tree = ET.parse(file_path)
            root = tree.getroot()
            for elem in root.iter():
                tag = elem.tag
                if '}' in tag:
                    tag = tag.split('}', 1)[1]
                if tag != "text":
                    continue
                full_text = ''.join(elem.itertext())
                doc = nlp(full_text)
                lemmas = set()
                for token in doc:
                    if token.is_alpha and not token.is_stop and len(token.lemma_) > 1:
                        lemma = token.lemma_.lower()
                        word_counter[lemma] += 1
                        lemmas.add(lemma)
                        if token.pos_ == "NOUN":
                            pos_counter_noun[lemma] += 1
                        elif token.pos_ == "ADJ":
                            pos_counter_adj[lemma] += 1
                for lemma in lemmas:
                    word_docs[lemma].add(filename)
        except ET.ParseError as e:
            print(f"Warnung: Datei {filename} konnte nicht geparst werden: {e}.")
    return word_counter, word_docs, pos_counter_noun, pos_counter_adj, total_docs

def build_distribution_column(word_counter, word_docs, min_freq=5, min_docs=6, top_n=30):
    distribution = {}
    for lemma, docs in word_docs.items():
        freq = word_counter[lemma]
        doc_count = len(docs)
        if freq >= min_freq and doc_count >= min_docs:
            score = doc_count / freq
            distribution[lemma] = score
    top = sorted(distribution.items(), key=lambda x: -x[1])[:top_n]
    return [w for w, _ in top]

def zip_longest(*args, fillvalue=""):
    max_len = max(len(col) for col in args)
    return [
        [col[i] if i < len(col) else fillvalue for col in args]
        for i in range(max_len)
    ]

def export_combined_table(output_path, most_common, nouns, adjs, distributed):
    rows = zip_longest(most_common, nouns, adjs, distributed)
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["häufigste_lemmata", "häufigste_substantive", "häufigste_adjektive", "selten_aber_verteilt"])
        writer.writerows(rows)

if __name__ == "__main__":
    input_folder = "../../doktorat/Diss/Sappho-Rezeption/XML"
    output_file = "../../doktorat/Diss/Sappho-Rezeption/Analysehilfen/wortstatistik_gesamt.csv"

    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    word_counter, word_docs, noun_counter, adj_counter, total_docs = extract_data(input_folder)

    most_common = [w for w, _ in word_counter.most_common(50)]
    top_nouns = [w for w, _ in noun_counter.most_common(50)]
    top_adjs = [w for w, _ in adj_counter.most_common(50)]
    distributed = build_distribution_column(word_counter, word_docs, min_freq=5, min_docs=6, top_n=50)

    export_combined_table(output_file, most_common, top_nouns, top_adjs, distributed)

    print(f"\n✅ Wortstatistik gespeichert in:\n{output_file}")