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

The reception testimonies listed were compiled over several years of research in national bibliographies, newspaper and periodical databases, digital text corpora, fanfiction platforms, and scholarly secondary literature, and recorded in a spreadsheet with core bibliographic data. sing [OpenRefine](https://openrefine.org/), entries were semi-automatically linked to [Wikidata](https://www.wikidata.org/), and a Python script then converted the spreadsheet into [TEI/XML files](https://github.com/laurauntner/sappho-digital/tree/main/data/lists).

The [RDF data](https://github.com/laurauntner/sappho-digital/tree/main/data/rdf) adds a further, more granular layer for an exemplary subcorpus: 197 Sappho fragments and 99 reception testimonies. Intertextual phenomena — motifs, topics, plots, rhetorical topoi, characters, and references to persons, places, and works — were manually annotated in XML through repeated close-reading passes, using a custom tagset. Six successive Python scripts then convert this annotated XML, together with the bibliographic lists, into RDF triples — covering author data, work data, fragment data, analysis data, and intertextual-relation data, followed by a final merge and a reasoning pass with the Java-based reasoner [HermiT](http://www.hermit-reasoner.com/) — yielding 600,000+ triples. The data model is documented as an [ontology](https://sappho-digital.com/ontology.html) built on [CIDOC CRM](https://cidoc-crm.org/), [LRMoo](https://repository.ifla.org/items/729b094a-92d6-4317-9dee-a300053ffdb4), and [INTRO](https://github.com/BOberreither/INTRO) (see below and [alignments](https://sappho-digital.com/alignments.html) to further ontologies); recurring phenomena are defined in a [SKOS vocabulary](https://sappho-digital.com/vokabular.html) of 400+ concepts, developed inductively from the annotations in the LOD editor [VocBench](https://vocbench.uniroma2.it/).

- **[XML/TEI files](https://github.com/laurauntner/sappho-digital/tree/main/data/lists)** – Lists of German-language testimonies of the productive literary reception of Sappho.
- **[RDF/XML, Turtle, and JSON-LD files](https://github.com/laurauntner/sappho-digital/tree/main/data/rdf)** — Structured information about reception testimonies: authors, works, intertextual features in exemplary texts, and their relationships to each other and to Sappho’s own work. The `sappho-reception` file combines all of these.

### Ontology & Vocabulary

| Resource | URI | Website |
|---|---|---|
| Ontology (OWL) | [w3id.org/sappho-digital/ontology/](https://w3id.org/sappho-digital/ontology/) | [sappho-digital.com/ontology.html](https://sappho-digital.com/ontology.html) |
| Vocabulary (SKOS) | [w3id.org/sappho-digital/vocab/](https://w3id.org/sappho-digital/vocab/) | [sappho-digital.com/vocab.html](https://sappho-digital.com/vokabular.html) |
| Alignments | [w3id.org/sappho-digital/alignments/](https://w3id.org/sappho-digital/alignments/) | [sappho-digital.com/alignments.html](https://sappho-digital.com/alignments.html) |

Ontology versions used in developing the [Sappho Digital Ontology](https://sappho-digital.com/ontology.html):

- Erlangen CRM 240307 (based on [CIDOC CRM](https://cidoc-crm.org/) 7.1.3)
- [LRMoo](https://repository.ifla.org/items/729b094a-92d6-4317-9dee-a300053ffdb4) 1.1.1
- [INTRO](https://github.com/BOberreither/INTRO) beta202506

Additional documentation of the applied data model is in the [`/documentation`](https://github.com/laurauntner/sappho-digital/tree/main/documentation) folder, including [SHACL shapes](https://github.com/laurauntner/sappho-digital/blob/main/documentation/ontology/shapes.ttl) configuring the visual query builder ([Sparnatural](https://github.com/sparna-git/Sparnatural)) on the [query page](https://sappho-digital.com/query.html).

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

To also build the site search index (Pagefind), run this afterwards (requires [Node.js](https://nodejs.org/)):

```
npx pagefind --site html
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