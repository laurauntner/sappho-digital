<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="tei">

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <xsl:for-each-group select="//tei:*[@xml:id]" group-by="@xml:id">
            <xsl:variable name="id" select="current-grouping-key()"/>
            <xsl:variable name="label">
                <xsl:choose>
                    <xsl:when test="self::tei:bibl">
                        <xsl:value-of select="normalize-space(tei:title[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(current-group()[1])"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:result-document href="../html/{$id}.html">
                <html>
                    <head>
                        <xsl:call-template name="html_head">
                            <xsl:with-param name="html_title" select="$label"/>
                        </xsl:call-template>
                        <xsl:if
                            test="(@ref and (self::tei:author or self::tei:bibl or self::tei:pubPlace))">
                            <script src="js/bibl-entities.js" defer="defer"/>
                        </xsl:if>
                    </head>
                    <body class="page">

                        <!-- wikidata ids -->
                        <xsl:attribute name="data-wikidata">
                            <xsl:value-of select="substring-after(@ref, 'entity/')"/>
                        </xsl:attribute>

                        <div class="hfeed site" id="page">
                            <xsl:call-template name="nav_bar"/>
                            <div class="container-fluid">
                                <div class="card">
                                    <div class="card-header">
                                        <h1>
                                            <xsl:value-of select="$label"/>
                                        </h1>
                                    </div>

                                    <div class="card-body wikidata-layout">

                                        <xsl:if
                                            test="@ref and (self::tei:bibl or self::tei:author or self::tei:pubPlace)">
                                            <div class="wikidata-right">
                                                <xsl:if
                                                  test="@ref and (self::tei:bibl or self::tei:author)">
                                                  <a href="{@ref}" target="_blank">
                                                  <div id="wikidata-image-{$id}"
                                                  class="wikidata-thumb-container"
                                                  data-wikidata="{substring-after(@ref, 'entity/')}"
                                                  data-type="image"/>
                                                  </a>
                                                </xsl:if>

                                                <xsl:if test="@ref and self::tei:pubPlace">
                                                  <div id="wikidata-map-{$id}"
                                                  class="wikidata-map-container"
                                                  data-wikidata="{substring-after(@ref, 'entity/')}"
                                                  data-type="map"/>
                                                </xsl:if>
                                            </div>
                                        </xsl:if>

                                        <div class="wikidata-left">
                                            <p class="align-left">Interne ID: <xsl:value-of
                                                  select="$id"/></p>
                                            <xsl:if test="@ref">
                                                <p class="align-left">Wikidata: <a href="{@ref}"
                                                  target="_blank">
                                                  <xsl:value-of select="@ref"/>
                                                  </a>
                                                </p>
                                            </xsl:if>
                                            <xsl:apply-templates select="."/>
                                        </div>

                                    </div>

                                </div>
                            </div>
                            <xsl:call-template name="html_footer"/>
                        </div>
                    </body>
                </html>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>

    <!-- main work -->
    <xsl:template match="self::tei:bibl">
        <p class="align-left">Typ: Werk</p>
        <xsl:if test="tei:date[@type = 'created']">
            <p class="align-left"> Entstehungsjahr: <xsl:value-of
                    select="tei:date[@type = 'created']"/>
            </p>
        </xsl:if>

        <xsl:if test="tei:date[@type = 'published']">
            <p class="align-left"> Publikations-/Aufführungsjahr: <xsl:value-of
                    select="tei:date[@type = 'published']"/>
            </p>
        </xsl:if>

        <xsl:if test="tei:bibl/tei:title">
            <p class="align-left"> Enthalten in: <xsl:for-each select="tei:bibl">
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <a href="../html/{@xml:id}.html">
                                <xsl:value-of select="tei:title"/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="tei:title"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@ref">
                        <a href="{@ref}" target="_blank">
                            <img src="images/wiki.png" alt="Wikidata"
                                title="Wikidata-Eintrag öffnen" class="icon"/>
                        </a>
                    </xsl:if>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="tei:author">
            <p class="align-left"> Autor_in: <xsl:for-each select="tei:author">
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <a href="../html/{@xml:id}.html">
                                <xsl:value-of select="."/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@ref">
                        <a href="{@ref}" target="_blank">
                            <img src="images/wiki.png" alt="Wikidata"
                                title="Wikidata-Eintrag öffnen" class="icon"/>
                        </a>
                    </xsl:if>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="tei:note[@type = 'genre']">
            <p class="align-left"> Gattung: <xsl:for-each select="tei:note[@type = 'genre']">
                    <xsl:variable name="genreText" select="normalize-space(.)"/>
                    <xsl:variable name="genreLower" select="lower-case($genreText)"/>
                    <xsl:choose>
                        <xsl:when test="contains($genreLower, 'lyrik')">
                            <a href="toc-lyrik.html">Lyrik</a>
                        </xsl:when>
                        <xsl:when test="contains($genreLower, 'prosa')">
                            <a href="toc-prosa.html">Prosa</a>
                        </xsl:when>
                        <xsl:when test="contains($genreLower, 'drama')">
                            <a href="toc-drama.html">Drama</a>
                        </xsl:when>
                        <xsl:otherwise>
                            <a href="toc-sonstige.html">Sonstige</a>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="tei:pubPlace">
            <p class="align-left"> Publikations-/Aufführungsort: <xsl:for-each select="tei:pubPlace">
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <a href="../html/{@xml:id}.html">
                                <xsl:value-of select="."/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@ref">
                        <a href="{@ref}" target="_blank">
                            <img src="images/wiki.png" alt="Wikidata"
                                title="Wikidata-Eintrag öffnen" class="icon"/>
                        </a>
                    </xsl:if>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="tei:publisher">
            <p class="align-left"> Verlag/Druckerei: <xsl:for-each select="tei:publisher">
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <a href="../html/{@xml:id}.html">
                                <xsl:value-of select="."/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@ref">
                        <a href="{@ref}" target="_blank">
                            <img src="images/wiki.png" alt="Wikidata"
                                title="Wikidata-Eintrag öffnen" class="icon"/>
                        </a>
                    </xsl:if>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="tei:ref">
            <p class="align-left"> Digitalisat: <xsl:for-each select="tei:ref">
                    <a href="{@target}" target="_blank">
                        <xsl:value-of select="text()"/>
                    </a>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>
    </xsl:template>

    <!-- publisher -->
    <xsl:template match="self::tei:publisher">
        <xsl:variable name="id" select="@xml:id"/>
        <p class="align-left">Typ: Verlag/Druckerei</p>
        <xsl:variable name="matches" select="//tei:bibl[tei:publisher/@xml:id = $id]"/>
        <xsl:variable name="count" select="count($matches)"/>
        <xsl:if test="$count &gt; 0">
            <p class="align-left">
                <xsl:choose>
                    <xsl:when test="$count = 1">Ein Werk in der Datenbank:</xsl:when>
                    <xsl:otherwise><xsl:value-of select="$count"/> Werke in der
                        Datenbank:</xsl:otherwise>
                </xsl:choose>
            </p>
            <ul>
                <xsl:for-each select="$matches[tei:title[@type = 'text']]">
                    <xsl:sort select="tei:title[@type = 'text']" data-type="text" order="ascending"/>
                    <li>
                        <a href="../html/{@xml:id}.html">
                            <xsl:value-of select="tei:title[@type = 'text']"/>
                        </a>
                    </li>
                </xsl:for-each>
            </ul>
        </xsl:if>
    </xsl:template>

    <!-- author -->
    <xsl:template match="self::tei:author">
        <div>
            <p class="align-left">Typ: Autor_in</p>
            <xsl:variable name="id" select="@xml:id"/>
            <xsl:variable name="matches" select="//tei:bibl[tei:author/@xml:id = $id]"/>
            <xsl:variable name="count" select="count($matches)"/>
            <xsl:if test="$count &gt; 0">
                <p class="align-left">
                    <xsl:choose>
                        <xsl:when test="$count = 1">Ein Werk in der Datenbank:</xsl:when>
                        <xsl:otherwise><xsl:value-of select="$count"/> Werke in der
                            Datenbank:</xsl:otherwise>
                    </xsl:choose>
                </p>
                <ul>
                    <xsl:for-each select="$matches[tei:title[@type = 'text']]">
                        <xsl:sort select="tei:title[@type = 'text']" data-type="text"
                            order="ascending"/>
                        <li>
                            <a href="../html/{@xml:id}.html">
                                <xsl:value-of select="tei:title[@type = 'text']"/>
                            </a>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- place -->
    <xsl:template match="self::tei:pubPlace">
        <div>
            <p class="align-left">Typ: Publikations-/Aufführungsort</p>
            <xsl:variable name="id" select="@xml:id"/>
            <xsl:variable name="matches" select="//tei:bibl[tei:pubPlace/@xml:id = $id]"/>
            <xsl:variable name="count" select="count($matches)"/>
            <xsl:if test="$count &gt; 0">
                <p class="align-left">
                    <xsl:choose>
                        <xsl:when test="$count = 1">Ein Werk in der Datenbank:</xsl:when>
                        <xsl:otherwise><xsl:value-of select="$count"/> Werke in der
                            Datenbank:</xsl:otherwise>
                    </xsl:choose>
                </p>
                <ul>
                    <xsl:for-each select="$matches[tei:title[@type = 'text']]">
                        <xsl:sort select="tei:title[@type = 'text']" data-type="text"
                            order="ascending"/>
                        <li>
                            <a href="../html/{@xml:id}.html">
                                <xsl:value-of select="tei:title[@type = 'text']"/>
                            </a>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- superwork -->
    <xsl:template match="self::tei:bibl//tei:title[@type = 'work']">
        <div>
            <p class="align-left">Typ: Werk</p>
            <xsl:variable name="currentId" select="@xml:id"/>
            <xsl:variable name="containedWorks"
                select="//tei:bibl[tei:bibl/@xml:id = $currentId and tei:title[@type = 'text']]"/>

            <xsl:if test="count($containedWorks) &gt; 0">
                <p class="align-left"> Enthält: <xsl:for-each select="$containedWorks">
                        <xsl:sort select="tei:title[@type = 'text']" data-type="text"
                            order="ascending"/>
                        <a href="../html/{@xml:id}.html">
                            <xsl:value-of select="tei:title[@type = 'text']"/>
                        </a>
                        <xsl:if test="tei:author"> (<xsl:choose>
                                <xsl:when test="tei:author[1]/@xml:id">
                                    <a href="../html/{tei:author[1]/@xml:id}.html">
                                        <xsl:value-of select="tei:author[1]"/>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="tei:author[1]"/>
                                </xsl:otherwise>
                            </xsl:choose>) </xsl:if>
                        <xsl:if test="@ref">
                            <a href="{@ref}" target="_blank">
                                <img src="images/wiki.png" alt="Wikidata"
                                    title="Wikidata-Eintrag öffnen" class="icon"/>
                            </a>
                        </xsl:if>
                        <xsl:if test="position() != last()">, </xsl:if>
                    </xsl:for-each>
                </p>

                <xsl:if test="$containedWorks/tei:pubPlace">
                    <p class="align-left"> Publikations-/Aufführungsort: <xsl:for-each
                            select="$containedWorks/tei:pubPlace">
                            <xsl:choose>
                                <xsl:when test="@xml:id">
                                    <a href="../html/{@xml:id}.html">
                                        <xsl:value-of select="."/>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="@ref">
                                <a href="{@ref}" target="_blank">
                                    <img src="images/wiki.png" alt="Wikidata"
                                        title="Wikidata-Eintrag öffnen" class="icon"/>
                                </a>
                            </xsl:if>
                            <xsl:if test="position() != last()">, </xsl:if>
                        </xsl:for-each>
                    </p>
                </xsl:if>

                <xsl:if test="$containedWorks/tei:publisher">
                    <p class="align-left"> Verlag/Druckerei: <xsl:for-each
                            select="$containedWorks/tei:publisher">
                            <xsl:choose>
                                <xsl:when test="@xml:id">
                                    <a href="../html/{@xml:id}.html">
                                        <xsl:value-of select="."/>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="@ref">
                                <a href="{@ref}" target="_blank">
                                    <img src="images/wiki.png" alt="Wikidata"
                                        title="Wikidata-Eintrag öffnen" class="icon"/>
                                </a>
                            </xsl:if>
                            <xsl:if test="position() != last()">, </xsl:if>
                        </xsl:for-each>
                    </p>
                </xsl:if>
            </xsl:if>
        </div>
    </xsl:template>

</xsl:stylesheet>
