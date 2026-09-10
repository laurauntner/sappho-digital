<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:i18n="urn:sappho-digital:i18n" version="2.0"
    exclude-result-prefixes="xsl tei xs i18n">
    <xsl:output encoding="UTF-8" media-type="text/html" method="xhtml" version="1.0" indent="yes"
        omit-xml-declaration="yes"/>

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <!-- Ant passes the output filename of this particular meta.xsl invocation (e.g. "orientierung.html"),
         since a single meta.xsl instance is reused for several distinct output pages. -->
    <xsl:param name="current_page" select="'index.html'"/>

    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:value-of select=".//tei:title[@type = 'main'][1]/text()"/>
        </xsl:variable>
        <xsl:variable name="doc_description" as="xs:string">
            <xsl:choose>
                <xsl:when test="$current_page = ('projekt.html', 'project.html')">
                    <xsl:value-of select="i18n:t('Projektbeschreibung von Sappho Digital: Dissertationsprojekt zur literarischen Sappho-Rezeption im deutschsprachigen Raum mittels Linked Data und Ontologien.')"/>
                </xsl:when>
                <xsl:when test="$current_page = ('orientierung.html', 'guidance.html')">
                    <xsl:value-of select="i18n:t('Orientierungshilfe für den Einstieg in Sappho Digital: Wie sich die Webseite und ihre Daten am besten erkunden lassen.')"/>
                </xsl:when>
                <xsl:when test="$current_page = ('analyse.html', 'analysis.html')">
                    <xsl:value-of select="i18n:t('Erläuterungen zur exemplarischen Analyse der Sappho-Fragmente und Rezeptionszeugnisse: Datenmodell, Annotation und Methodik.')"/>
                </xsl:when>
                <xsl:when test="$current_page = ('publikationen.html', 'publications.html')">
                    <xsl:value-of select="i18n:t('Publikationen zum Projekt Sappho Digital.')"/>
                </xsl:when>
                <xsl:when test="$current_page = ('bibliographie.html', 'bibliography.html')">
                    <xsl:value-of select="i18n:t('Bibliographie und Quellenverzeichnis des Projekts Sappho Digital.')"/>
                </xsl:when>
                <xsl:when test="$current_page = ('texte.html', 'texts.html')">
                    <xsl:value-of select="i18n:t('Primärtexte: Sappho-Fragmente und deutschsprachige Rezeptionszeugnisse im Projekt Sappho Digital.')"/>
                </xsl:when>
                <xsl:when test="$current_page = ('404.html', 'not-found.html')">
                    <xsl:value-of select="i18n:t('Seite nicht gefunden – Sappho Digital.')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$project_description"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html lang="{$lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                    <xsl:with-param name="html_description" select="$doc_description"/>
                    <xsl:with-param name="current_page" select="$current_page"/>
                    <xsl:with-param name="html_noindex" select="$current_page = ('404.html', 'not-found.html')"/>
                </xsl:call-template>
            </head>

            <body class="page">
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar">
                        <xsl:with-param name="current_page" select="$current_page"/>
                    </xsl:call-template>

                    <div class="container-fluid">
                        <div class="card">
                            <div class="card-header">
                                <h1>
                                    <xsl:value-of select="$doc_title"/>
                                </h1>
                            </div>
                            <div class="card-body">
                                <xsl:apply-templates select=".//tei:body"/>
                            </div>
                        </div>
                    </div>
                    <xsl:call-template name="html_footer"/>
                </div>
                <xsl:if test=".//tei:graphic[@type = 'chart']">
                    <script src="https://code.highcharts.com/highcharts.js"/>
                    <script src="./js/analysis-statistics.js"/>
                </xsl:if>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="tei:p">
        <p class="align-left" id="{generate-id()}"><xsl:apply-templates/></p>
    </xsl:template>

    <xsl:template match="tei:title[@type = 'main']">
        <h1 class="align-left">
            <xsl:apply-templates/>
        </h1>
    </xsl:template>

    <xsl:template match="tei:head">
        <h3 class="align-left">
            <xsl:apply-templates/>
        </h3>
    </xsl:template>

    <xsl:template match="tei:div">
        <div id="{generate-id()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="tei:ref">
        <a>
            <xsl:attribute name="href">
                <xsl:value-of select="i18n:href(@target)"/>
            </xsl:attribute>
            <xsl:value-of select="."/>
        </a>
    </xsl:template>

    <xsl:template match="tei:hi[@rend = 'italics']">
        <i>
            <xsl:apply-templates/>
        </i>
    </xsl:template>

    <xsl:template match="tei:hi[@rend = 'bold']">
        <b>
            <xsl:apply-templates/>
        </b>
    </xsl:template>

    <xsl:template match="tei:list">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>

    <xsl:template match="tei:item">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>

    <xsl:template match="tei:graphic[@type = 'cover']">
        <img>
            <xsl:attribute name="src">
                <xsl:value-of select="@url"/>
            </xsl:attribute>
            <xsl:attribute name="class">
                <xsl:text>cover</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates/>
        </img>
    </xsl:template>

    <xsl:template match="tei:graphic[@type = 'funding']">
        <img>
            <xsl:attribute name="src">
                <xsl:value-of select="@url"/>
            </xsl:attribute>
            <xsl:attribute name="class">
                <xsl:text>funding</xsl:text>
            </xsl:attribute>
            <xsl:apply-templates/>
        </img>
    </xsl:template>

    <xsl:template match="tei:graphic[@type = 'chart']">
        <div class="skos-chart" id="{@n}" data-chart="{@subtype}" data-csv="{@url}"/>
    </xsl:template>

    <xsl:template match="tei:div[@rend = 'charts']">
        <section class="charts-grid">
            <xsl:apply-templates/>
        </section>
    </xsl:template>

    <xsl:template match="tei:code">
        <code>
            <xsl:apply-templates/>
        </code>
    </xsl:template>

</xsl:stylesheet>
