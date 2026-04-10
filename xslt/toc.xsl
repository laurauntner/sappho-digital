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

    <xsl:key name="place-by-id" match="ecrm:E53_Place" use="tokenize(@rdf:about, '/')[last()]"/>

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
                                                    <xsl:variable name="rdf_place" select="key('place-by-id', $place_id, $rdf_doc)"/>
                                                    <xsl:variable name="coords_raw" select="normalize-space($rdf_place/rdfs:comment[1])"/>
                                                    <xsl:if test="matches($coords_raw, '^-?\d')">
                                                        <xsl:variable name="coords" select="tokenize($coords_raw, ',')"/>
                                                        <xsl:variable name="lat" select="normalize-space($coords[1])"/>
                                                        <xsl:variable name="lng" select="normalize-space($coords[2])"/>
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
                                        <xsl:text>window.timelineData = [&#10;</xsl:text>
                                        <xsl:for-each select="//tei:listBibl/tei:bibl">
                                            <xsl:variable name="dateEl" select="(tei:date[@type = 'created'], tei:date[@type = 'published'])[1]"/>
                                            <xsl:variable name="year">
                                                <xsl:choose>
                                                    <xsl:when test="$dateEl/@when">
                                                        <xsl:value-of select="substring(normalize-space($dateEl/@when), 1, 4)"/>
                                                    </xsl:when>
                                                    <xsl:when test="$dateEl/@notBefore and $dateEl/@notAfter">
                                                        <xsl:value-of select="round((number(substring($dateEl/@notBefore, 1, 4)) + number(substring($dateEl/@notAfter, 1, 4))) div 2)"/>
                                                    </xsl:when>
                                                    <xsl:when test="$dateEl/@notBefore">
                                                        <xsl:value-of select="substring(normalize-space($dateEl/@notBefore), 1, 4)"/>
                                                    </xsl:when>
                                                    <xsl:when test="$dateEl/@notAfter">
                                                        <xsl:value-of select="substring(normalize-space($dateEl/@notAfter), 1, 4)"/>
                                                    </xsl:when>
                                                </xsl:choose>
                                            </xsl:variable>
                                            <xsl:if test="matches($year, '^\d{4}$')">
                                                <xsl:value-of select="$year"/><xsl:text>,&#10;</xsl:text>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <xsl:text>];&#10;</xsl:text>
                                    </script>


                                </xsl:if>

                                <xsl:if test="not($show_heatmap)">
                                    <script>
                                        <xsl:text>window.timelineData = [&#10;</xsl:text>
                                        <xsl:for-each select="//tei:listBibl/tei:bibl">
                                            <xsl:variable name="dateEl" select="(tei:date[@type = 'created'], tei:date[@type = 'published'])[1]"/>
                                            <xsl:variable name="year">
                                                <xsl:choose>
                                                    <xsl:when test="$dateEl/@when">
                                                        <xsl:value-of select="substring(normalize-space($dateEl/@when), 1, 4)"/>
                                                    </xsl:when>
                                                    <xsl:when test="$dateEl/@notBefore and $dateEl/@notAfter">
                                                        <xsl:value-of select="round((number(substring($dateEl/@notBefore, 1, 4)) + number(substring($dateEl/@notAfter, 1, 4))) div 2)"/>
                                                    </xsl:when>
                                                    <xsl:when test="$dateEl/@notBefore">
                                                        <xsl:value-of select="substring(normalize-space($dateEl/@notBefore), 1, 4)"/>
                                                    </xsl:when>
                                                    <xsl:when test="$dateEl/@notAfter">
                                                        <xsl:value-of select="substring(normalize-space($dateEl/@notAfter), 1, 4)"/>
                                                    </xsl:when>
                                                </xsl:choose>
                                            </xsl:variable>
                                            <xsl:if test="matches($year, '^\d{4}$')">
                                                <xsl:value-of select="$year"/><xsl:text>,&#10;</xsl:text>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <xsl:text>];&#10;</xsl:text>
                                    </script>
                                </xsl:if>

                                <div id="screen-too-small">Das Fenster ist zu klein, um die Tabelle
                                    darstellen zu können.</div>

                                <script>
                                <xsl:text>window.tocData = [&#10;</xsl:text>
                                <xsl:for-each select="//tei:listBibl/tei:bibl">

                                    <xsl:variable name="createdEl" select="tei:date[@type = 'created']"/>
                                    <xsl:variable name="publishedEl" select="tei:date[@type = 'published']"/>
                                    <xsl:variable name="created">
                                        <xsl:choose>
                                            <xsl:when test="$createdEl/@when"><xsl:value-of select="$createdEl/@when"/></xsl:when>
                                            <xsl:when test="$createdEl/@notBefore and $createdEl/@notAfter"><xsl:value-of select="concat($createdEl/@notBefore, '–', $createdEl/@notAfter)"/></xsl:when>
                                            <xsl:when test="$createdEl/@notBefore"><xsl:value-of select="$createdEl/@notBefore"/></xsl:when>
                                            <xsl:when test="$createdEl/@notAfter"><xsl:value-of select="$createdEl/@notAfter"/></xsl:when>
                                            <xsl:otherwise><xsl:value-of select="normalize-space($createdEl)"/></xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    <xsl:variable name="published">
                                        <xsl:choose>
                                            <xsl:when test="$publishedEl/@when"><xsl:value-of select="$publishedEl/@when"/></xsl:when>
                                            <xsl:when test="$publishedEl/@notBefore and $publishedEl/@notAfter"><xsl:value-of select="concat($publishedEl/@notBefore, '–', $publishedEl/@notAfter)"/></xsl:when>
                                            <xsl:when test="$publishedEl/@notBefore"><xsl:value-of select="$publishedEl/@notBefore"/></xsl:when>
                                            <xsl:when test="$publishedEl/@notAfter"><xsl:value-of select="$publishedEl/@notAfter"/></xsl:when>
                                            <xsl:otherwise><xsl:value-of select="normalize-space($publishedEl)"/></xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>

                                    <xsl:variable name="titleText" select="replace(normalize-space(tei:title[@type = 'text']), '\\', '\\\\')"/>
                                    <xsl:variable name="titleHtml">
                                        <xsl:value-of select="concat('&lt;a href=&quot;', @xml:id, '.html&quot; class=&quot;link-plain&quot;&gt;', replace($titleText, '&quot;', '&amp;quot;'), '&lt;/a&gt;')"/>
                                        <xsl:if test="@ref">
                                            <xsl:value-of select="concat(' &lt;a href=&quot;', @ref, '&quot; target=&quot;_blank&quot;&gt;&lt;img src=&quot;images/wiki.png&quot; alt=&quot;Wikidata&quot; class=&quot;icon&quot;/&gt;&lt;/a&gt;')"/>
                                        </xsl:if>
                                    </xsl:variable>

                                    <xsl:variable name="workHtml">
                                        <xsl:for-each select="tei:bibl[tei:title[@type = 'work']]">
                                            <xsl:value-of select="concat('&lt;a href=&quot;', @xml:id, '.html&quot; class=&quot;link-plain&quot;&gt;', replace(normalize-space(tei:title), '&quot;', '&amp;quot;'), '&lt;/a&gt;')"/>
                                            <xsl:if test="@ref">
                                                <xsl:value-of select="concat(' &lt;a href=&quot;', @ref, '&quot; target=&quot;_blank&quot;&gt;&lt;img src=&quot;images/wiki.png&quot; alt=&quot;Wikidata&quot; class=&quot;icon&quot;/&gt;&lt;/a&gt;')"/>
                                            </xsl:if>
                                            <xsl:if test="position() != last()">, </xsl:if>
                                        </xsl:for-each>
                                    </xsl:variable>

                                    <xsl:variable name="workQid" select="string-join(tei:bibl[tei:title[@type = 'work']][@ref]/@ref, ', ')"/>

                                    <xsl:variable name="authorHtml">
                                        <xsl:for-each select="tei:author">
                                            <xsl:value-of select="concat('&lt;a href=&quot;', @xml:id, '.html&quot; class=&quot;link-plain&quot;&gt;', replace(normalize-space(.), '&quot;', '&amp;quot;'), '&lt;/a&gt;')"/>
                                            <xsl:if test="@ref">
                                                <xsl:value-of select="concat(' &lt;a href=&quot;', @ref, '&quot; target=&quot;_blank&quot;&gt;&lt;img src=&quot;images/wiki.png&quot; alt=&quot;Wikidata&quot; class=&quot;icon&quot;/&gt;&lt;/a&gt;')"/>
                                            </xsl:if>
                                            <xsl:if test="position() != last()">, </xsl:if>
                                        </xsl:for-each>
                                    </xsl:variable>
                                    <xsl:variable name="authorQid" select="string-join(tei:author[@ref]/@ref, ', ')"/>

                                    <xsl:variable name="genreHtml">
                                        <xsl:for-each select="tei:note[@type = 'genre']">
                                            <xsl:variable name="gl" select="lower-case(normalize-space(.))"/>
                                            <xsl:variable name="label">
                                                <xsl:choose>
                                                    <xsl:when test="contains($gl, 'lyrik')">Lyrik</xsl:when>
                                                    <xsl:when test="contains($gl, 'prosa')">Prosa</xsl:when>
                                                    <xsl:when test="contains($gl, 'drama')">Drama</xsl:when>
                                                    <xsl:otherwise>Sonstige</xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:variable>
                                            <xsl:value-of select="concat('&lt;a href=&quot;toc-', lower-case($label), '.html&quot; class=&quot;link-plain&quot;&gt;', $label, '&lt;/a&gt;')"/>
                                            <xsl:if test="position() != last()">, </xsl:if>
                                        </xsl:for-each>
                                    </xsl:variable>
                                    <xsl:variable name="genreText">
                                        <xsl:for-each select="tei:note[@type = 'genre']">
                                            <xsl:variable name="gl" select="lower-case(normalize-space(.))"/>
                                            <xsl:choose>
                                                <xsl:when test="contains($gl, 'lyrik')">Lyrik</xsl:when>
                                                <xsl:when test="contains($gl, 'prosa')">Prosa</xsl:when>
                                                <xsl:when test="contains($gl, 'drama')">Drama</xsl:when>
                                                <xsl:otherwise>Sonstige</xsl:otherwise>
                                            </xsl:choose>
                                            <xsl:if test="position() != last()">, </xsl:if>
                                        </xsl:for-each>
                                    </xsl:variable>

                                    <xsl:variable name="placeHtml">
                                        <xsl:for-each select="tei:pubPlace">
                                            <xsl:value-of select="concat('&lt;a href=&quot;', @xml:id, '.html&quot; class=&quot;link-plain&quot;&gt;', replace(normalize-space(.), '&quot;', '&amp;quot;'), '&lt;/a&gt;')"/>
                                            <xsl:if test="@ref">
                                                <xsl:value-of select="concat(' &lt;a href=&quot;', @ref, '&quot; target=&quot;_blank&quot;&gt;&lt;img src=&quot;images/wiki.png&quot; alt=&quot;Wikidata&quot; class=&quot;icon&quot;/&gt;&lt;/a&gt;')"/>
                                            </xsl:if>
                                            <xsl:if test="position() != last()">, </xsl:if>
                                        </xsl:for-each>
                                    </xsl:variable>
                                    <xsl:variable name="placeQid" select="string-join(tei:pubPlace[@ref]/@ref, ', ')"/>

                                    <xsl:variable name="publisherHtml">
                                        <xsl:for-each select="tei:publisher">
                                            <xsl:value-of select="concat('&lt;a href=&quot;', @xml:id, '.html&quot; class=&quot;link-plain&quot;&gt;', replace(normalize-space(.), '&quot;', '&amp;quot;'), '&lt;/a&gt;')"/>
                                            <xsl:if test="@ref">
                                                <xsl:value-of select="concat(' &lt;a href=&quot;', @ref, '&quot; target=&quot;_blank&quot;&gt;&lt;img src=&quot;images/wiki.png&quot; alt=&quot;Wikidata&quot; class=&quot;icon&quot;/&gt;&lt;/a&gt;')"/>
                                            </xsl:if>
                                            <xsl:if test="position() != last()">, </xsl:if>
                                        </xsl:for-each>
                                    </xsl:variable>
                                    <xsl:variable name="publisherQid" select="string-join(tei:publisher[@ref]/@ref, ', ')"/>

                                    <xsl:variable name="refHtml">
                                        <xsl:for-each select="tei:ref">
                                            <xsl:value-of select="concat('&lt;a href=&quot;', @target, '&quot; target=&quot;_blank&quot; class=&quot;link-plain&quot;&gt;Online&lt;/a&gt;')"/>
                                            <xsl:if test="position() != last()">, </xsl:if>
                                        </xsl:for-each>
                                    </xsl:variable>
                                    <xsl:variable name="refUrl" select="string-join(tei:ref[@target]/@target, ', ')"/>

                                    <xsl:text>[</xsl:text>
                                    <xsl:value-of select="concat('&quot;', replace($created, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($published, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($titleHtml, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace(normalize-space(@ref), '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($workHtml, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($workQid, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($authorHtml, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($authorQid, '&quot;', '\\&quot;'), '&quot;')"/>
                                    <xsl:if test="$show_genres">
                                        <xsl:value-of select="concat(',&quot;', replace($genreHtml, '&quot;', '\\&quot;'), '&quot;')"/>
                                    </xsl:if>
                                    <xsl:value-of select="concat(',&quot;', replace($placeHtml, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($placeQid, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($publisherHtml, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($publisherQid, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($refHtml, '&quot;', '\\&quot;'), '&quot;,')"/>
                                    <xsl:value-of select="concat('&quot;', replace($refUrl, '&quot;', '\\&quot;'), '&quot;')"/>
                                    <xsl:text>],&#10;</xsl:text>
                                </xsl:for-each>
                                <xsl:text>];&#10;</xsl:text>
                                <xsl:if test="$show_genres">
                                    <xsl:text>window.tocShowGenres = true;&#10;</xsl:text>
                                    <xsl:text>window.genreData = {Prosa:0,Lyrik:0,Drama:0,Sonstige:0};&#10;</xsl:text>
                                    <xsl:for-each select="//tei:listBibl/tei:bibl/tei:note[@type = 'genre']">
                                        <xsl:variable name="gl" select="lower-case(normalize-space(.))"/>
                                        <xsl:choose>
                                            <xsl:when test="contains($gl, 'lyrik')"><xsl:text>window.genreData.Lyrik++;&#10;</xsl:text></xsl:when>
                                            <xsl:when test="contains($gl, 'prosa')"><xsl:text>window.genreData.Prosa++;&#10;</xsl:text></xsl:when>
                                            <xsl:when test="contains($gl, 'drama')"><xsl:text>window.genreData.Drama++;&#10;</xsl:text></xsl:when>
                                            <xsl:otherwise><xsl:text>window.genreData.Sonstige++;&#10;</xsl:text></xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                </xsl:if>
                                </script>

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
                                    <tbody/>
                                </table>

                            </div>
                        </div>
                    </div>
                    <xsl:call-template name="html_footer"/>

                    <script src="https://code.highcharts.com/highcharts.js" defer="defer"/>
                    <script src="https://code.highcharts.com/modules/timeline.js" defer="defer"/>
                    <script src="https://code.highcharts.com/modules/data.js" defer="defer"/>
                    <xsl:if test="$show_heatmap">
                        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" defer="defer"/>
                        <script src="https://unpkg.com/leaflet.heat@0.2.0/dist/leaflet-heat.js" defer="defer"/>
                        <script src="js/heatmap.js" defer="defer"/>
                    </xsl:if>
                    <script src="https://cdn.datatables.net/v/bs4/jszip-2.5.0/dt-1.11.0/b-2.0.0/b-html5-2.0.0/cr-1.5.4/r-2.2.9/sp-1.4.0/datatables.min.js" defer="defer"/>
                    <script src="js/dt.js" defer="defer"/>
                    <script src="./js/toc-statistics.js" defer="defer"/>
                    <script defer="defer">
                        document.addEventListener('DOMContentLoaded', function () {
                            createDataTable('tocTable');
                        });
                    </script>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
