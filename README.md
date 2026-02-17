# Sappho Digital

Over the centuries, the ancient Greek poet Sappho has been imagined and reimagined in countless ways. More than 1,000 German-language texts from the 15th to the 21st century reference Sappho in ways that range from quotation and allusion to fictionalization and stylistic imitation. My dissertation project documents and analyzes these forms of *productive literary reception* using Linked Data. This repository stores the corresponding data.

For a detailed description of the project and the data, see the [project website](https://sappho-digital.com/about.html), which is based on the [DSE-Static-Cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter). If, for whatever reason, the website becomes unavailable, you can access an archived version via the [Wayback Machine](https://web.archive.org/).

---

This repository contains:
- [XML/TEI files](https://github.com/laurauntner/sappho-digital/tree/main/data/lists) listing testimonies of the productive literary reception of Sappho.
- [RDF/XML and RDF/Turtle files](https://github.com/laurauntner/sappho-digital/tree/main/data/rdf) with information about these productive literary reception testimonies: about the authors, the works, intertextual features in 99 exemplary texts, and their relationships to each other as well as to Sappho’s work ("sappho-reception" is the combined file).
- An [OWL-ontology](https://github.com/laurauntner/sappho-digital/tree/main/documentation/ontology), a [SKOS-vocabulary](https://github.com/laurauntner/sappho-digital/tree/main/documentation/vocab) and [ontology alignments](https://github.com/laurauntner/sappho-digital/tree/main/documentation/alignments). URIs:
  - Ontology: [https://w3id.org/sappho-digital/ontology/](https://w3id.org/sappho-digital/ontology/)
  - Vocabulary: [https://w3id.org/sappho-digital/vocab/](https://w3id.org/sappho-digital/vocab/)
  - Alignments: [https://w3id.org/sappho-digital/alignments/](https://w3id.org/sappho-digital/alignments/)
- More [files](https://github.com/laurauntner/sappho-digital/tree/main/documentation) documenting the applied data model. To get an idea of the data model, see also the companion repository [wikidata-to-cidoc-crm](https://github.com/laurauntner/wikidata-to-cidoc-crm). This repository contains Python scripts and a Python package for converting structured data from Wikidata into RDF using CIDOC CRM, LRMoo, and INTRO. 
- Scripts used for data transformation and satistics ([XSLT](https://github.com/laurauntner/sappho-digital/tree/main/xslt) and [Python](https://github.com/laurauntner/sappho-digital/tree/main/python)).
- A [Java program](https://github.com/laurauntner/sappho-digital/blob/main/java/src/main/java/Reasoner.java) for reasoning with HermiT.

⚠️ This repository is under active development.

---

For questions, suggestions, or reports of errors, feel free to reach out ([laura.untner@fu-berlin.de](mailto:laura.untner@fu-berlin.de)) or open an issue.

---

### Citation recommendation
Laura Untner: Sappho Digital. Die literarische Sappho-Rezeption im deutschsprachigen Raum. Vienna/Berlin 2024–[2027], https://sappho-digital.com.

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
