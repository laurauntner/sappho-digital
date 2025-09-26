# Sappho Digital

Over the centuries, the ancient Greek poet Sappho has been imagined and reimagined in countless ways. More than 1,000 German-language texts from the 15th to the 21st century reference Sappho in ways that range from quotation and allusion to fictionalization and stylistic imitation. My dissertation project documents and analyzes these forms of *productive literary reception* using Linked Data. This repository stores the corresponding data.

For a detailed description of the project and the data, see the [project website](https://sappho-digital.com/about.html), which is based on the [DSE-Static-Cookiecutter](https://github.com/acdh-oeaw/dse-static-cookiecutter). If, for whatever reason, the website becomes unavailable, you can access an archived version via the [Wayback Machine](https://web.archive.org/).

---

This repository contains:
- [XML/TEI files](https://github.com/laurauntner/sappho-digital/tree/main/data/lists) listing testimonies of the productive literary reception of Sappho.
- [RDF/XML and RDF/Turtle files](https://github.com/laurauntner/sappho-digital/tree/main/data/rdf) with information about these productive literary reception testimonies: about the authors, the works, intertextual features in 99 exemplary texts, and their relationships to each other as well as to Sappho’s work ("sappho-reception" is the combined file, "vocab" stores the SKOS-vocabulary for the intertextual phenomena).
- Scripts used for data transformation and satistics ([XSLT](https://github.com/laurauntner/sappho-digital/tree/main/xslt) and [Python](https://github.com/laurauntner/sappho-digital/tree/main/python)). 
- [Files](https://github.com/laurauntner/sappho-digital/tree/main/documentation) documenting the applied RDF data models.  To get an idea of the data model, see also the companion repository [wikidata-to-cidoc-crm](https://github.com/laurauntner/wikidata-to-cidoc-crm). This repository contains Python scripts for converting structured data from Wikidata into RDF using CIDOC CRM, LRMoo, and INTRO. 

⚠️ This repository is under active development.

---

For questions, suggestions, or reports of errors, feel free to reach out ([laura.untner@fu-berlin.de](mailto:laura.untner@fu-berlin.de)) or open an issue.

---

### Citation recommendation
Laura Untner: Sappho Digital. Die literarische Sappho-Rezeption im deutschsprachigen Raum. Vienna/Berlin 2024–[2027], https://sappho-digital.com.

---

Run the app locally:
```
sh shellscripts/dl_saxon.sh
ant
```

---

**Color code**: `rgba(94, 23, 235)`  
**Font**: Geist Sans
