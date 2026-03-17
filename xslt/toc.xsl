<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:ecrm="http://erlangen-crm.org/current/"
    exclude-result-prefixes="xsl tei xs rdf rdfs ecrm">

    <xsl:output encoding="UTF-8" method="xhtml" indent="yes" omit-xml-declaration="yes"/>

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:variable name="rdf_doc" select="document('../data/rdf/sappho-reception.rdf')"/>

    <xsl:template match="/">
        <xsl:variable name="doc_title" select="//tei:title[@type = 'main']"/>
        <xsl:variable name="filename" select="tokenize(base-uri(), '/')[last()]"/>
        <xsl:variable name="show_genres" select="contains($filename, 'sappho-rez_alle')"/>
        <xsl:variable name="show_timeline" select="not(contains($filename, 'sappho-rez_sonstige'))"/>
        <xsl:variable name="show_heatmap" select="not(contains($filename, 'sappho-rez_sonstige'))"/>

        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>
                <script src="https://code.highcharts.com/highcharts.js"/>
                <script src="https://code.highcharts.com/modules/timeline.js"/>
                <script src="https://code.highcharts.com/modules/data.js"/>

                <xsl:if test="$show_heatmap">
                    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
                </xsl:if>
            </head>
            <body class="page" data-tei-file="{$filename}" data-show-genres="{$show_genres}">
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

                                <xsl:if test="$show_heatmap">
                                    <xsl:choose>
                                        <xsl:when test="$show_genres">
                                            <div
                                                style="display:flex; gap:1.5rem; align-items:flex-start; padding-bottom:.5rem;">
                                                <div id="heatmap-section" style="flex:0 0 65%;">
                                                  <div id="map"/>
                                                  <div id="slider-wrapper">
                                                  <label for="year-slider">Jahr:</label>
                                                  <input type="range" id="year-slider" min="1"
                                                  max="1" value="1" step="1"/>
                                                  <span id="slider-display">–</span>
                                                  <button id="btn-play"
                                                  class="btn btn-sm btn-outline-secondary"> &#9654;
                                                  Abspielen </button>

                                                  </div>
                                                </div>
                                                <div id="container-genres"
                                                  style="flex:0 0 35%; height:190px; margin-top:0;"
                                                />
                                            </div>
                                            <div id="container-timeline"
                                                style="width:100%; height:220px; padding-bottom:20px;"
                                            />
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <div
                                                style="display:flex; gap:1.5rem; align-items:flex-start; padding-bottom:.5rem;">
                                                <div id="heatmap-section" style="flex:0 0 45%;">
                                                  <div id="map"/>
                                                  <div id="slider-wrapper">
                                                  <label for="year-slider">Jahr:</label>
                                                  <input type="range" id="year-slider" min="1"
                                                  max="1" value="1" step="1"/>
                                                  <span id="slider-display">–</span>
                                                  <button id="btn-play"
                                                  class="btn btn-sm btn-outline-secondary"> &#9654;
                                                  Abspielen </button>

                                                  </div>
                                                </div>
                                                <div id="container-timeline"
                                                  style="flex:1; height:190px; margin-top:0; align-self:center;"
                                                />
                                            </div>
                                        </xsl:otherwise>
                                    </xsl:choose>

                                    <script>
                                        <xsl:text>window.heatmapData = [&#10;</xsl:text>
                                        <xsl:for-each select="//tei:listBibl/tei:bibl">
                                            <xsl:variable name="year_raw" select="normalize-space(tei:date[@type = 'published']/@when)"/>
                                            <xsl:variable name="year" select="
                                                    if (matches($year_raw, '\d{4}'))
                                                    then
                                                        number(substring($year_raw, 1, 4))
                                                    else
                                                        0"/>
                                            <xsl:if test="$year &gt; 0">
                                                <xsl:for-each select="tei:pubPlace">
                                                    <xsl:variable name="place_id" select="@xml:id"/>
                                                    <xsl:variable name="place_name" select="normalize-space(.)"/>
                                                    <xsl:variable name="rdf_place" select="
                                                            $rdf_doc//ecrm:E53_Place[
                                                            ends-with(@rdf:about, $place_id)
                                                            ]"/>
                                                    <xsl:variable name="coords_raw" select="normalize-space($rdf_place/rdfs:comment[1])"/>
                                                    <xsl:if test="matches($coords_raw, '^-?\d')">
                                                        <xsl:variable name="lat" select="normalize-space(tokenize($coords_raw, ',')[1])"/>
                                                        <xsl:variable name="lng" select="normalize-space(tokenize($coords_raw, ',')[2])"/>
                                                        <xsl:text>  {lat:</xsl:text>
                                                        <xsl:value-of select="$lat"/>
                                                        <xsl:text>,lng:</xsl:text>
                                                        <xsl:value-of select="$lng"/>
                                                        <xsl:text>,year:</xsl:text>
                                                        <xsl:value-of select="$year"/>
                                                        <xsl:text>,place:"</xsl:text>
                                                        <xsl:value-of select="replace($place_name, '&quot;', '\\&quot;')"/>
                                                        <xsl:text>"},&#10;</xsl:text>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <xsl:text>];&#10;</xsl:text>
                                    </script>

                                    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"/>
                                    <script src="https://unpkg.com/leaflet.heat@0.2.0/dist/leaflet-heat.js"/>
                                    <script src="js/heatmap.js"/>

                                </xsl:if>

                                <script src="./js/toc-statistics.js"/>
                                <div id="screen-too-small">Das Fenster ist zu klein, um die Tabelle
                                    darstellen zu können.</div>

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
                                                  <a href="{@xml:id}.html" class="link-plain">
                                                  <xsl:value-of select="tei:title[@type = 'text']"/>
                                                  </a>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen" class="icon"/>
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
                                                  <a href="{@xml:id}.html" class="link-plain">
                                                  <xsl:value-of select="tei:title"/>
                                                  </a>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen" class="icon"/>
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
                                                  <a href="{@xml:id}.html" class="link-plain">
                                                  <xsl:value-of select="."/>
                                                  </a>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen" class="icon"/>
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
                                                  <xsl:for-each select="tei:note[@type = 'genre']">
                                                  <xsl:variable name="genreText"
                                                  select="normalize-space(.)"/>
                                                  <xsl:variable name="genreLower"
                                                  select="lower-case($genreText)"/>
                                                  <xsl:choose>
                                                  <xsl:when test="contains($genreLower, 'lyrik')">
                                                  <a href="toc-lyrik.html" class="link-plain"
                                                  >Lyrik</a>
                                                  </xsl:when>
                                                  <xsl:when test="contains($genreLower, 'prosa')">
                                                  <a href="toc-prosa.html" class="link-plain"
                                                  >Prosa</a>
                                                  </xsl:when>
                                                  <xsl:when test="contains($genreLower, 'drama')">
                                                  <a href="toc-drama.html" class="link-plain"
                                                  >Drama</a>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <a href="toc-sonstige.html" class="link-plain"
                                                  >Sonstige</a>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </td>
                                                </xsl:if>
                                                <td>
                                                  <xsl:for-each select="tei:pubPlace">
                                                  <a href="{@xml:id}.html" class="link-plain">
                                                  <xsl:value-of select="."/>
                                                  </a>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen" class="icon"/>
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
                                                  <a href="{@xml:id}.html" class="link-plain">
                                                  <xsl:value-of select="."/>
                                                  </a>
                                                  <xsl:if test="@ref">
                                                  <a href="{@ref}" target="_blank">
                                                  <img src="images/wiki.png" alt="Wikidata"
                                                  title="Wikidata-Eintrag öffnen" class="icon"/>
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
                                                  <a href="{@target}" target="_blank"
                                                  class="link-plain"> Online </a>
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
