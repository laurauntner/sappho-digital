# Sappho Digital

A digital humanities dissertation project documenting and analyzing the productive literary reception of the ancient Greek poet Sappho across more than 1,000 German-language texts from the 15th to the 21st century — using Linked Data and formal ontologies.

For a full project description, see the **[project website](https://sappho-digital.com/index.html)** (built with [DSE-Static-Cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter)). If the website is unavailable, an archived version can be accessed via the [Wayback Machine](https://web.archive.org/).

> ⚠️ **This repository is under active development.**

---

## Citation

> Laura Untner: *Sappho Digital. Die literarische Sappho-Rezeption im deutschsprachigen Raum.* Berlin/Vienna 2024–[2027], https://sappho-digital.com.

<details>
<summary>BibTeX</summary>

```bibtex
@dataset{untner_sappho_digital_2024,
  author    = {Untner, Laura},
  title     = {Sappho Digital. Die literarische Sappho-Rezeption im deutschsprachigen Raum},
  year      = {2024},
  url       = {https://sappho-digital.com},
  note      = {Berlin/Vienna, 2024--[2027]}
}
```

A machine-readable citation is also available in [CITATION.cff](https://raw.githubusercontent.com/laurauntner/sappho-digital/refs/heads/main/CITATION.cff).
</details>

---

## Repository Contents

### Data

- **[XML/TEI files](https://github.com/laurauntner/sappho-digital/tree/main/data/lists)** – Lists of German-language testimonies of the productive literary reception of Sappho.
- **[RDF/XML, Turtle, and JSON-LD files](https://github.com/laurauntner/sappho-digital/tree/main/data/rdf)** — Structured information about reception testimonies: authors, works, intertextual features in exemplary texts, and their relationships to each other and to Sappho’s own work. The `sappho-reception` file combines all of these.

### Ontology & Vocabulary

| Resource | URI | Website |
|---|---|---|
| Ontology (OWL) | [w3id.org/sappho-digital/ontology/](https://w3id.org/sappho-digital/ontology/) | [sappho-digital.com/ontology.html](https://sappho-digital.com/ontology.html) |
| Vocabulary (SKOS) | [w3id.org/sappho-digital/vocab/](https://w3id.org/sappho-digital/vocab/) | [sappho-digital.com/vocab.html](https://sappho-digital.com/vokabular.html) |
| Alignments | [w3id.org/sappho-digital/alignments/](https://w3id.org/sappho-digital/alignments/) | [sappho-digital.com/alignments.html](https://sappho-digital.com/alignments.html) |

Ontology versions used in developing the [Sappho Digital Ontology](https://sappho-digital.com/ontology.html):

- Erlangen CRM 240307 (based on CIDOC CRM 7.1.3)
- LRMoo 1.1.1
- INTRO beta202506

Additional documentation of the applied data model is in the [`/documentation`](https://github.com/laurauntner/sappho-digital/tree/main/documentation) folder.

For the data model in action, see also the companion repository [wikidata-to-cidoc-crm](https://github.com/laurauntner/wikidata-to-cidoc-crm), which contains Python scripts and a package for converting Wikidata into RDF using CIDOC CRM, LRMoo, and INTRO. See also the associated publication:

> Laura Untner: From Wikidata to CIDOC CRM: A Use Case Scenario for Digital Comparative Literary Studies. In: *Journal of Open Humanities Data* 11 (2025), pp. 1–15. DOI: [10.5334/johd.421](https://doi.org/10.5334/johd.421)

### Code & Scripts

- **[XSLT](https://github.com/laurauntner/sappho-digital/tree/main/xslt)**, **[JavaScript](https://github.com/laurauntner/sappho-digital/tree/main/html/js)**, and **[Python](https://github.com/laurauntner/sappho-digital/tree/main/python)** — Scripts for data transformation and statistics.
- **[Java](https://github.com/laurauntner/sappho-digital/blob/main/java/src/main/java/Reasoner.java)** — Reasoner program using HermiT.
- Code for the **[project website](https://sappho-digital.com/)**.

---

## Running Locally

Clone the repository and run the following from the project root:

```
ant
```

---

## License

This project is licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

This repository also includes **Saxon-HE**, licensed separately under the [Mozilla Public License, Version 2.0 (MPL 2.0)](https://github.com/laurauntner/sappho-digital/tree/main/saxon/notices/LICENSE.txt).

---

## Contact

For questions, suggestions, or error reports, feel free to reach out at [laura.untner@fu-berlin.de](mailto:laura.untner@fu-berlin.de) or [open an issue](https://github.com/laurauntner/sappho-digital/issues).

---

**Color**: `rgba(94, 23, 235)` · **Font**: Geist Sans
