<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xsl tei xs">

    <xsl:output encoding="UTF-8" method="xhtml" indent="yes" omit-xml-declaration="yes"/>

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:template match="/">
        <xsl:variable name="tei" select="/"/>
        <xsl:variable name="doc_title" select="//tei:title[@type = 'main']"/>
        <xsl:variable name="filename" select="tokenize(base-uri(), '/')[last()]"/>
        <xsl:variable name="show_genres" select="contains($filename, 'sappho-rez_alle')"/>
        <xsl:variable name="show_timeline" select="not(contains($filename, 'sappho-rez_sonstige'))"/>

        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>
                <script src="https://code.highcharts.com/highcharts.js"/>
                <script src="https://code.highcharts.com/modules/timeline.js"/>
                <script src="https://code.highcharts.com/modules/data.js"/>
            </head>
            <body class="page">
                <xsl:attribute name="data-tei-file">
                    <xsl:value-of select="$filename"/>
                </xsl:attribute>
                <xsl:attribute name="data-show-genres">
                    <xsl:choose>
                        <xsl:when test="$show_genres">true</xsl:when>
                        <xsl:otherwise>false</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar"/>
                    <div class="container">
                        <div class="card">
                            <div class="card-header">
                                <h1>
                                    <xsl:value-of select="$doc_title"/>
                                </h1>
                            </div>
                            <div class="card-body">
                                <!-- Timeline + Genres -->
                                <xsl:if test="$show_timeline">
                                    <xsl:choose>
                                        <xsl:when test="$show_genres">
                                            <div id="container"
                                                style="display: flex; justify-content: space-between; padding-bottom: 50px">
                                                <div id="container-timeline"
                                                  style="margin: auto; width: 70%; height: 200px;"/>
                                                <div id="container-genres"
                                                  style="margin: auto; width: 30%; height: 200px;"/>
                                            </div>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <div id="container"
                                                style="padding-bottom: 50px; display: flex; justify-content: center;">
                                                <div id="container-timeline"
                                                  style="width: 60%; height: 200px; margin: auto;"/>
                                            </div>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:if>

                                <script src="./js/statistics.js"/>
                                <table class="table table-striped display" id="tocTable"
                                    style="width:100%">
                                    <thead>
                                        <tr>
                                            <th>Entstehungsjahr</th>
                                            <th>Publikations-/Aufführungsjahr</th>
                                            <th>Titel</th>
                                            <th class="export-only">Text QID</th>
                                            <th>Enthalten in</th>
                                            <th class="export-only">Werk QID</th>
                                            <th>Autor_in</th>
                                            <th class="export-only">Autor_in QID</th>
                                            <xsl:if test="$show_genres">
                                                <th>Gattung</th>
                                            </xsl:if>
                                            <th>Publikations-/Aufführungsort</th>
                                            <th class="export-only">Ort QID</th>
                                            <th>Verlag/Druckerei</th>
                                            <th class="export-only">Verlag/Druckerei QID</th>
                                            <th>Digitalisat</th>
                                            <th class="export-only">Link</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:for-each select="//tei:listBibl/tei:bibl">
                                            <tr>
                                                <td>
                                                  <xsl:value-of select="tei:date[@type = 'created']"
                                                  />
                                                </td>
                                                <td>
                                                  <xsl:value-of
                                                  select="tei:date[@type = 'published']"/>
                                                </td>
                                                <td>
                                                  <xsl:value-of select="tei:title[@type = 'text']"/>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen"
                                                  style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;"
                                                  />
                                                  </a>
                                                  </xsl:if>
                                                </td>
                                                <td class="export-only">
                                                  <xsl:if test="@ref">
                                                  <xsl:value-of select="@ref"/>
                                                  </xsl:if>
                                                </td>
                                                <td>
                                                  <xsl:for-each
                                                  select="tei:bibl[tei:title[@type = 'work']]">
                                                  <xsl:value-of select="tei:title[@type = 'work']"/>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen"
                                                  style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;"
                                                  />
                                                  </a>
                                                  </xsl:if>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <td class="export-only">
                                                  <xsl:for-each
                                                  select="tei:bibl[tei:title[@type = 'work']]">
                                                  <xsl:if test="@ref">
                                                  <xsl:value-of select="@ref"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <td>
                                                  <xsl:for-each select="tei:author">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen"
                                                  style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;"
                                                  />
                                                  </a>
                                                  </xsl:if>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <td class="export-only">
                                                  <xsl:for-each select="tei:author">
                                                  <xsl:if test="@ref">
                                                  <xsl:value-of select="@ref"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <xsl:if test="$show_genres">
                                                  <td>
                                                  <xsl:variable name="genreText"
                                                  select="normalize-space(tei:note[@type = 'genre'])"/>
                                                  <xsl:value-of
                                                  select="replace($genreText, '/', '/')"/>
                                                  </td>
                                                </xsl:if>
                                                <td>
                                                  <xsl:for-each select="tei:pubPlace">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen"
                                                  style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;"
                                                  />
                                                  </a>
                                                  </xsl:if>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <td class="export-only">
                                                  <xsl:for-each select="tei:pubPlace">
                                                  <xsl:if test="@ref">
                                                  <xsl:value-of select="@ref"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <td>
                                                  <xsl:for-each select="tei:publisher">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen"
                                                  style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;"
                                                  />
                                                  </a>
                                                  </xsl:if>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <td class="export-only">
                                                  <xsl:for-each select="tei:publisher">
                                                  <xsl:if test="@ref">
                                                  <xsl:value-of select="@ref"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <td>
                                                  <xsl:for-each select="tei:ref">
                                                  <a href="{@target}">Online</a>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                                <td class="export-only">
                                                  <xsl:for-each select="tei:ref">
                                                  <xsl:if test="@target">
                                                  <xsl:value-of select="@target"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </td>
                                            </tr>
                                        </xsl:for-each>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                    <xsl:call-template name="html_footer"/>
                    <script src="https://cdn.datatables.net/v/bs4/jszip-2.5.0/dt-1.11.0/b-2.0.0/b-html5-2.0.0/cr-1.5.4/r-2.2.9/sp-1.4.0/datatables.min.js"/>
                    <script src="js/dt.js"/>
                    <script>
                        $(document).ready(function () {
                        createDataTable('tocTable');
                        });
                    </script>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
