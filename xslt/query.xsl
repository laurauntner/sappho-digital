<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:i18n="urn:sappho-digital:i18n" version="2.0"
    exclude-result-prefixes="#all">
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
        <html xmlns="http://www.w3.org/1999/xhtml" lang="{$lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>
                <link rel="stylesheet"
                    href="https://cdn.jsdelivr.net/npm/sparnatural@12.2.1/dist/browser/sparnatural.css"/>
                <link rel="stylesheet" href="sparnatural/theme.css" type="text/css"/>
            </head>
            <body class="page">
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar">
                        <xsl:with-param name="current_page" select="i18n:href('query.html')"/>
                    </xsl:call-template>

                    <div class="sparql-container container-fluid">
                        <div class="card-header">
                            <h1>
                                <xsl:value-of select="$doc_title"/>
                            </h1>
                        </div>
                        <div class="sparql-content">
                            <div class="section">
                                <div class="section-title"><xsl:value-of select="i18n:t('Datenquelle')"/></div>
                                <div class="data-source">
                                    <input type="text" id="dataSource"
                                        value="https://sappho-digital.com/sappho-reception.ttl"/>
                                    <div class="data-source-suggestions smaller-text">
                                        <div class="hint"><xsl:value-of select="i18n:t('Andere Quellen:')"/></div>
                                        <div>
                                            <button class="example-btn" type="button"
                                                onclick="setDataSource('https://sappho-digital.com/authors.ttl')"
                                                ><xsl:value-of select="i18n:t('Nur Autor_innendaten')"/></button>
                                        </div>
                                        <div>
                                            <button class="example-btn" type="button"
                                                onclick="setDataSource('https://sappho-digital.com/works.ttl')"
                                                ><xsl:value-of
                                                  select="i18n:t('Nur bibliographische Daten zu Rezeptionszeugnissen')"
                                                /></button>
                                        </div>
                                        <div>
                                            <button class="example-btn" type="button"
                                                onclick="setDataSource('https://sappho-digital.com/fragments.ttl')"
                                                ><xsl:value-of
                                                  select="i18n:t('Nur bibliographische Daten zu Sappho-Fragmenten')"
                                                /></button>
                                        </div>
                                        <div>
                                            <button class="example-btn" type="button"
                                                onclick="setDataSource('https://sappho-digital.com/sappho-reception.ttl')"
                                                ><xsl:value-of select="i18n:t('Default (alle Daten)')"/></button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="section" id="sparnaturalSection">
                                <div class="section-title"><xsl:value-of select="i18n:t('Visueller Query-Builder')"/></div>
                                <p class="smaller-text"><xsl:value-of
                                        select="i18n:t('Der visuelle Query-Builder wird durch ')"/><a
                                        href="https://github.com/sparna-git/Sparnatural"
                                        target="_blank">Sparnatural</a><xsl:value-of
                                        select="i18n:t(' bereitgestellt. Seine Nutzung ist optional – die SPARQL-Query lässt sich auch direkt im Editor unten eingeben.')"
                                    /></p>
                                <p class="smaller-text"><xsl:value-of
                                        select="i18n:t('Eine Query entsteht durch Verbinden von Elementen: Zunächst werden die Klassen ausgewählt, erst danach lässt sich – sofern mehrere Möglichkeiten bestehen – das verbindende Prädikat festlegen. Suchbegriffe werden textbasiert abgeglichen (Groß-/Kleinschreibung wird ignoriert), eine Live-Vorschlagsliste beim Tippen gibt es nicht. Mit dem ')"
                                    /><strong>Play-Button</strong><xsl:value-of
                                        select="i18n:t(' wird die erzeugte Query in den SPARQL-Editor übernommen; ausgeführt wird sie erst über ›Query ausführen‹.')"
                                    /></p>
                                <p class="smaller-text"><xsl:value-of
                                        select="i18n:t('Die Auswahlliste öffnet sich bei Klick auf ›Search for resources‹ und lässt sich nur durch Auswahl einer Klasse schließen; erst danach werden die übrigen Bedienelemente wieder vollständig zugänglich.')"
                                    /></p>
                                <spar-natural id="sparnatural" src="shapes.ttl"
                                    endpoint="./no-sparql-endpoint" lang="en" defaultLang="en"
                                    distinct="true" limit="100"><xsl:comment> sparnatural mount point </xsl:comment></spar-natural>
                            </div>

                            <div class="section">
                                <div class="section-title">SPARQL Query</div>
                                <div class="query-container">
                                    <textarea id="queryEditor"
                                        placeholder="{i18n:t('Gib hier eine SPARQL-Query ein …')}">
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
                                        ><xsl:value-of select="i18n:t('Beispiel-Queries:')"/></div>
                                    <button class="example-btn" onclick="loadExample('all')"><xsl:value-of
                                            select="i18n:t('Alle Tripel')"/></button>
                                    <button class="example-btn" onclick="loadExample('count')"
                                        ><xsl:value-of select="i18n:t('Anzahl Tripel')"/></button>
                                    <button class="example-btn" onclick="loadExample('types')"><xsl:value-of
                                            select="i18n:t('Alle Klassen')"/></button>
                                    <button class="example-btn" onclick="loadExample('properties')"
                                        ><xsl:value-of select="i18n:t('Alle Properties')"/></button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopPersonRef')"
                                        ><xsl:value-of
                                            select="i18n:t('Personenreferenzen in Rezeptionszeugnissen')"
                                        /></button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopCharacter')"><xsl:value-of
                                            select="i18n:t('Figuren in Rezeptionszeugnissen')"/></button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopMotif')"><xsl:value-of
                                            select="i18n:t('Motive in Rezeptionszeugnissen')"/></button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopTopos')"><xsl:value-of
                                            select="i18n:t('Rhetorische Topoi in Rezeptionszeugnissen')"
                                        /></button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopPlace')"><xsl:value-of
                                            select="i18n:t('Ortsreferenzen in Rezeptionszeugnissen')"/></button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomTopTopic')"><xsl:value-of
                                            select="i18n:t('Themen in Rezeptionszeugnissen')"/></button>
                                    <button class="example-btn"
                                        onclick="loadExample('plotComponents')"><xsl:value-of
                                            select="i18n:t('Stoffe in Rezeptionszeugnissen')"/></button>
                                    <button class="example-btn" onclick="loadExample('workRefs')"
                                        ><xsl:value-of select="i18n:t('Werkreferenzen in Rezeptionszeugnissen')"
                                        /></button>
                                    <button class="example-btn"
                                        onclick="loadExample('textPassages')"><xsl:value-of
                                            select="i18n:t('Zitate in Rezeptionszeugnissen')"/></button>
                                    <button class="example-btn"
                                        onclick="loadExample('phenomSappho')"><xsl:value-of
                                            select="i18n:t('Phänomene in Sappho-Fragmenten')"/></button>
                                    <button class="example-btn"
                                        onclick="loadExample('authorTopWorks')"><xsl:value-of
                                            select="i18n:t('Top Autor_innen nach Korpuspräsenz')"/></button>
                                    <button class="example-btn"
                                        onclick="loadExample('intertextDocCount')"
                                        ><xsl:value-of
                                            select="i18n:t('Rezeptionszeugnisse mit meisten Relationen')"
                                        /></button>
                                </div>
                                <div class="section">
                                    <div class="section-title"
                                        style="width: 100%; margin-top: 20px !important"><xsl:value-of
                                            select="i18n:t('Hilfreiche Ressourcen:')"/></div>
                                    <ul class="tooltip-list smaller-text">
                                        <li>
                                            <a
                                                href="https://www.wikidata.org/wiki/Wikidata:SPARQL_tutorial"
                                                target="_blank">SPARQL-Tutorial</a>
                                        </li>
                                        <li>
                                            <a href="https://sappho-digital.com/ontology.html"
                                                target="_blank"><xsl:value-of select="i18n:t('Datenmodell')"/></a>
                                        </li>
                                        <li>
                                            <a href="https://sappho-digital.com/alignments.html"
                                                target="_blank">Alignments</a>
                                        </li>
                                        <li>
                                            <a href="https://sappho-digital.com/vokabular.html"
                                                target="_blank"><xsl:value-of select="i18n:t('Vokabular')"/></a>
                                        </li>
                                        <li>
                                            <a href="https://sappho-digital.com/statistik.html"
                                                target="_blank"><xsl:value-of select="i18n:t('Statistische Auswertungen')"/></a>
                                        </li>
                                    </ul>
                                    <details class="ns-list smaller-text">
                                        <summary><xsl:value-of select="i18n:t('Namespace-Präfixe')"/></summary>
                                        <ul class="tooltip-list ns-list__items">
                                            <li><code>rdf:</code>
                                                http://www.w3.org/1999/02/22-rdf-syntax-ns#</li>
                                            <li><code>rdfs:</code>
                                                http://www.w3.org/2000/01/rdf-schema#</li>
                                            <li><code>owl:</code>
                                                http://www.w3.org/2002/07/owl#</li>
                                            <li><code>skos:</code>
                                                http://www.w3.org/2004/02/skos/core#</li>
                                            <li><code>prov:</code> http://www.w3.org/ns/prov#</li>
                                            <li><code>ecrm:</code>
                                                http://erlangen-crm.org/current/</li>
                                            <li><code>lrmoo:</code>
                                                http://iflastandards.info/ns/lrm/lrmoo/</li>
                                            <li><code>intro:</code>
                                                https://w3id.org/lso/intro/currentbeta#</li>
                                        </ul>
                                    </details>
                                </div>
                            </div>

                            <div class="controls">
                                <button id="executeBtn" class="sparql-btn" onclick="executeQuery()"
                                    >▶ <xsl:value-of select="i18n:t('Query ausführen')"/></button>
                                <button id="clearBtn" class="sparql-btn" onclick="clearResults()"
                                    ><xsl:value-of select="i18n:t('Ergebnisse löschen')"/></button>
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
                <script src="https://cdn.jsdelivr.net/npm/sparnatural@12.2.1/dist/browser/sparnatural.js" defer="defer"/>
                <script src="js/sparnatural-integration.js" defer="defer"/>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>
