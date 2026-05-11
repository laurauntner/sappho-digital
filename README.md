# Sappho Digital

Over the centuries, the ancient Greek poet Sappho has been imagined and reimagined in countless ways. More than 1,000 German-language texts from the 15th to the 21st century reference Sappho in ways that range from quotation and allusion to fictionalization and stylistic imitation. My dissertation project documents and analyzes these forms of *productive literary reception* using Linked Data and formal ontologies. This repository stores the corresponding data.

For a detailed description of the project and the data, see the [project website](https://sappho-digital.com/index.html), which is based on the [DSE-Static-Cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter). If, for whatever reason, the website becomes unavailable, you can access an archived version via the [Wayback Machine](https://web.archive.org/).

---

This repository contains:
- [XML/TEI files](https://github.com/laurauntner/sappho-digital/tree/main/data/lists) listing German-language testimonies of the productive literary reception of Sappho.
- [RDF/XML, Turtle and JSON-LD files](https://github.com/laurauntner/sappho-digital/tree/main/data/rdf) with information about these productive literary reception testimonies: about the authors, the works, intertextual features in exemplary texts, and their relationships to each other as well as to Sappho’s work ("sappho-reception" is the combined file).
- An [OWL-ontology](https://github.com/laurauntner/sappho-digital/tree/main/documentation/ontology), a [SKOS-vocabulary](https://github.com/laurauntner/sappho-digital/tree/main/documentation/vocab) and [ontology alignments](https://github.com/laurauntner/sappho-digital/tree/main/documentation/alignments). URIs:
  - Ontology: [https://w3id.org/sappho-digital/ontology/](https://w3id.org/sappho-digital/ontology/), see also [https://sappho-digital.com/ontology.html](https://sappho-digital.com/ontology.html)
  - Vocabulary: [https://w3id.org/sappho-digital/vocab/](https://w3id.org/sappho-digital/vocab/), see also [https://sappho-digital.com/vocab.html](https://sappho-digital.com/vokabular.html)
  - Alignments: [https://w3id.org/sappho-digital/alignments/](https://w3id.org/sappho-digital/alignments/), see also [https://sappho-digital.com/alignments.html](https://sappho-digital.com/alignments.html)
- More [files](https://github.com/laurauntner/sappho-digital/tree/main/documentation) documenting the applied data model. To get an idea of the data model, see also the companion repository [wikidata-to-cidoc-crm](https://github.com/laurauntner/wikidata-to-cidoc-crm). This repository contains Python scripts and a Python package for converting structured data from Wikidata into RDF using CIDOC CRM, LRMoo, and INTRO. Cf. Laura Untner: From Wikidata to CIDOC CRM: A Use Case Scenario for Digital Comparative Literary Studies. In: Journal of Open Humanities Data 11 (2025), pp. 1–15, DOI: [10.5334/johd.421](https://doi.org/10.5334/johd.421).
- Scripts used for data transformation and satistics ([XSLT](https://github.com/laurauntner/sappho-digital/tree/main/xslt), [JavaScript](https://github.com/laurauntner/sappho-digital/tree/main/html/js) and [Python](https://github.com/laurauntner/sappho-digital/tree/main/python)).
- A [Java program](https://github.com/laurauntner/sappho-digital/blob/main/java/src/main/java/Reasoner.java) for reasoning with HermiT.
- The [website](https://sappho-digital.com/) code.

⚠️ This repository is under active development.

---

Ontology versions used for developing the [Sappho Digital Ontology](https://sappho-digital.com/ontology.html):
- Erlangen CRM 240307 (based on CIDOC CRM 7.1.3)
- LRMoo 1.1.1
- INTRO beta202506

---

For questions, suggestions, or reports of errors, feel free to reach out ([laura.untner@fu-berlin.de](mailto:laura.untner@fu-berlin.de)) or open an issue.

---

### Citation recommendation

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

Run the app locally with:
```
ant
```

---

**Color code**: `rgba(94, 23, 235)`  
**Font**: Geist Sans

---

### SAXON-HE
The projects includes Saxon-HE, which is licensed separately under the Mozilla Public License, Version 2.0 (MPL 2.0). See the dedicated [LICENSE.txt](https://github.com/laurauntner/sappho-digital/tree/main/saxon/notices/LICENSE.txt).
