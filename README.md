# Sappho Digital

Over the centuries, the ancient Greek poet Sappho has been imagined and reimagined in countless ways. More than 1,000 German-language texts from the 15th to the 21st century reference Sappho in ways that range from quotation and allusion to fictionalization and stylistic imitation. Laura Untner’s dissertation project documents and analyzes these forms of *productive literary reception* using Linked Data. This repository stores the corresponding data.

For a detailed description of the project, see the [project website](https://sappho-digital.com/about.html) based on the [DSE-Static-Cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter). If, for whatever reason, the website becomes unavailable, see the archived version via the [Wayback Machine](https://web.archive.org/).

This repository contains:
- [XML/TEI files](https://github.com/laurauntner/sappho-digital/tree/main/data/lists) listing testimonies of the productive literary reception of Sappho. 
- XXXX Scripts used for data transformation and sorting. The lists are generated locally with Python scripts from an Excel file and are then sorted with `xslt/sort.xsl` and `xslt/n-bibl.xsl`.

⚠️ This repository is under active development. Soon, there will also be an OWL ontology for modeling biographical, bibliographical, and intertextual information; a SKOS vocabulary for the literary reception of Sappho; and sample analyses of around 100 literary reception testimonies. To get an idea of the data model, see the companion repository [wikidata-to-cidoc-crm](https://github.com/laurauntner/wikidata-to-cidoc-crm). This repository contains Python scripts for converting structured data from Wikidata into RDF using CIDOC CRM, LRMoo, and INTRO. 

For questions, suggestions, or reports of errors, feel free to reach out ([laura.untner@fu-berlin.de](mailto:laura.untner@fu-berlin.de)) or open an issue.

---

### Citation recommendation
Laura Untner: Sappho Digital. Die literarische Sappho-Rezeption im deutschsprachigen Raum. Wien/Berlin 2024f., https://sappho-digital.com.

---

**Color code**: `rgba(94, 23, 235)`  
**Font**: Geist Sans
