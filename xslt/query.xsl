<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="#all">
    <xsl:output encoding="UTF-8" media-type="text/html" method="xhtml" version="1.0" indent="yes"
        omit-xml-declaration="yes"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:value-of select='"Sappho Digital Query Service"'/>
        </xsl:variable>

        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>
            </head>
            <body class="page">
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar"/>

                    <div class="sparql-container container-fluid">
                        <div class="card-header">
                            <h1>
                                <xsl:value-of select="$doc_title"/>
                            </h1>
                        </div>
                        <div class="sparql-content">
                            <div class="section">
                                <div class="section-title">Datenquelle</div>
                                <div class="data-source">
                                    <input type="text" id="dataSource"
                                        value="https://sappho-digital.com/sappho-reception.ttl"/>
                                    <div class="data-source-suggestions smaller-text">
                                        <div class="hint">Andere Quellen:</div>
                                        <div>
                                            <button class="example-btn" type="button"
                                                onclick="setDataSource('https://sappho-digital.com/authors.ttl')"
                                                >Nur Autor_innendaten</button>
                                        </div>
                                        <div>
                                            <button class="example-btn" type="button"
                                                onclick="setDataSource('https://sappho-digital.com/works.ttl')"
                                                >Nur bibliographische Daten zu
                                                Rezeptionszeugnissen</button>
                                        </div>
                                        <div>
                                            <button class="example-btn" type="button"
                                                onclick="setDataSource('https://sappho-digital.com/fragments.ttl')"
                                                >Nur bibliographische Daten zu
                                                Sappho-Fragmenten</button>
                                        </div>
                                        <div>
                                            <button class="example-btn" type="button"
                                                onclick="setDataSource('https://sappho-digital.com/sappho-reception.ttl')"
                                                >Default (alle Daten)</button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="section">
                                <div class="section-title">SPARQL Query</div>
                                <div class="query-container">
                                    <textarea id="queryEditor"
                                        placeholder="Gib hier eine SPARQL-Query ein …">
                                        <xsl:text>
PREFIX rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt;
PREFIX rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;

SELECT ?subject ?predicate ?object
WHERE {
  ?subject ?predicate ?object .
}
LIMIT 100
</xsl:text>
                                    </textarea>
                                </div>

                                <div class="examples">
                                    <div class="section-title"
                                        style="width: 100%; margin-bottom: 0px !important"
                                        >Beispiel-Queries:</div>
                                    <button class="example-btn" onclick="loadExample('all')">Alle
                                        Tripel</button>
                                    <button class="example-btn" onclick="loadExample('count')"
                                        >Anzahl Tripel</button>
                                    <button class="example-btn" onclick="loadExample('types')">Alle
                                        Klassen</button>
                                    <button class="example-btn" onclick="loadExample('properties')"
                                        >Alle Properties</button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopPersonRef')"
                                        >Personenreferenzen in Rezeptionszeugnissen</button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopCharacter')">Figuren in
                                        Rezeptionszeugnissen</button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopMotif')">Motive in
                                        Rezeptionszeugnissen</button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopTopos')">Rhetorische Topoi in
                                        Rezeptionszeugnissen</button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopPlace')">Ortsreferenzen in
                                        Rezeptionszeugnissen</button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopTopic')">Themen in
                                        Rezeptionszeugnissen</button>
                                    <button class="example-btn"
                                        onclick="loadExample('plotComponents')">Stoffe in
                                        Rezeptionszeugnissen</button>
                                    <button class="example-btn" onclick="loadExample('workRefs')"
                                        >Werkreferenzen in Rezeptionszeugnissen</button>
                                    <button class="example-btn"
                                        onclick="loadExample('textPassages')">Zitate in
                                        Rezeptionszeugnissen</button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomSappho')">Phänomene in
                                        Sappho-Fragmenten</button>
                                    <button class="example-btn"
                                        onclick="loadExample('authorTopWorks')">Top Autor_innen nach
                                        Korpuspräsenz</button>
                                    <button class="example-btn"
                                        onclick="loadExample('intertextDocCount')"
                                        >Rezeptionszeugnisse mit meisten Relationen</button>
                                </div>
                                <div class="section">
                                    <div class="section-title"
                                        style="width: 100%; margin-top: 20px !important">Hilfreiche
                                        Ressourcen:</div>
                                    <ul class="tooltip-list smaller-text">
                                        <li>
                                            <a
                                                href="https://www.wikidata.org/wiki/Wikidata:SPARQL_tutorial"
                                                target="_blank">SPARQL-Tutorial</a>
                                        </li>
                                        <li>
                                            <a href="https://sappho-digital.com/ontology.html"
                                                target="_blank">Datenmodell</a>
                                        </li>
                                        <li>
                                            <a href="https://sappho-digital.com/alignments.html"
                                                target="_blank">Alignments</a>
                                        </li>
                                        <li>
                                            <a href="https://sappho-digital.com/vokabular.html"
                                                target="_blank">Vokabular</a>
                                        </li>
                                        <li>
                                            <a href="https://sappho-digital.com/statistik.html"
                                                target="_blank">Statistische Auswertungen</a>
                                        </li>
                                    </ul>
                                </div>
                            </div>

                            <div class="controls">
                                <button id="executeBtn" class="sparql-btn" onclick="executeQuery()"
                                    >▶ Query ausführen</button>
                                <button id="clearBtn" class="sparql-btn" onclick="clearResults()"
                                    >Ergebnisse löschen</button>
                                <div class="export-controls hidden" id="exportControls">
                                    <button class="export-btn" onclick="exportResults('csv')">CSV
                                        Export</button>
                                    <button class="export-btn" onclick="exportResults('json')">JSON
                                        Export</button>
                                </div>
                            </div>

                            <div id="results"/>
                        </div>
                    </div>

                    <xsl:call-template name="html_footer"/>
                </div>

                <script src="https://rdf.js.org/comunica-browser/versions/v4/engines/query-sparql/comunica-browser.js" defer="defer"/>
                <script src="js/query.js" defer="defer"/>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>
