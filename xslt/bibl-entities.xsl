<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:ecrm="http://erlangen-crm.org/current/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="xyz" xmlns:owl="http://www.w3.org/2002/07/owl#" exclude-result-prefixes="tei">

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:variable name="works" select="doc('../data/rdf/works.rdf')"/>

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <xsl:for-each-group select="//tei:*[@xml:id]" group-by="@xml:id">
            <xsl:variable name="id" select="current-grouping-key()"/>
            <xsl:variable name="label">
                <xsl:choose>
                    <xsl:when test="self::tei:bibl">
                        <xsl:value-of select="
                                let $t := normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1])
                                return
                                    if ($t != '') then
                                        $t
                                    else
                                        '[??]'
                                "/>
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
                                            test="self::tei:bibl or self::tei:author or self::tei:pubPlace">
                                            <div class="wikidata-right">

                                                <!-- work image -->
                                                <xsl:if test="self::tei:bibl">
                                                  <xsl:variable name="expr-iri"
                                                  select="concat('https://sappho-digital.com/expression/', @xml:id)"/>
                                                  <xsl:variable name="img-url" select="
                                                            string((
                                                            $works//*[@rdf:about = $expr-iri]/rdfs:seeAlso/@rdf:resource,
                                                            $works//*[@rdf:about = $expr-iri]/rdfs:seeAlso/text()
                                                            )[1])"/>
                                                  <xsl:if test="$img-url">
                                                  <a href="{@ref}" target="_blank" rel="noopener">
                                                  <img class="wikidata-thumb" src="{$img-url}"
                                                  alt="{normalize-space(tei:title[@type='text'][1])}"
                                                  />
                                                  </a>
                                                  </xsl:if>
                                                </xsl:if>

                                                <!-- author image -->
                                                <xsl:if test="self::tei:author">
                                                  <xsl:variable name="authors"
                                                  select="doc('../data/rdf/authors.rdf')"/>
                                                  <xsl:variable name="person-iri"
                                                  select="concat('https://sappho-digital.com/person/', @xml:id)"/>
                                                  <xsl:variable name="img" select="
                                                            $authors//ecrm:E38_Image[
                                                            ecrm:P65_shows_visual_item
                                                            /ecrm:E36_Visual_Item
                                                            /ecrm:P138_represents/@rdf:resource = $person-iri
                                                            ][1]"/>
                                                  <xsl:variable name="img-url" select="
                                                            string((
                                                            $img/rdfs:seeAlso/@rdf:resource,
                                                            $img/rdfs:seeAlso/text()
                                                            )[1])"/>
                                                  <xsl:if test="$img-url">
                                                  <a href="{@ref}" target="_blank" rel="noopener">
                                                  <img class="wikidata-thumb" src="{$img-url}"
                                                  alt="{normalize-space(.)}"/>
                                                  </a>
                                                  </xsl:if>
                                                </xsl:if>

                                                <!-- place map -->
                                                <xsl:if test="self::tei:pubPlace and @ref">
                                                  <div id="wikidata-map-{@xml:id}"
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
            <p class="align-left">Publikations-/Aufführungsjahr: <xsl:value-of
                    select="tei:date[@type = 'published']"/>
            </p>
        </xsl:if>

        <xsl:if test="tei:bibl/tei:title">
            <p class="align-left">Enthalten in: <xsl:for-each select="tei:bibl">
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <a href="{@xml:id}.html">
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
            <p class="align-left">Autor_in: <xsl:for-each select="tei:author">
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <a href="{@xml:id}.html">
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
            <p class="align-left">Gattung: <xsl:for-each select="tei:note[@type = 'genre']">
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
            <p class="align-left">Publikations-/Aufführungsort: <xsl:for-each select="tei:pubPlace">
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <a href="{@xml:id}.html">
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
            <p class="align-left">Verlag/Druckerei: <xsl:for-each select="tei:publisher">
                    <xsl:choose>
                        <xsl:when test="@xml:id">
                            <a href="{@xml:id}.html">
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
            <p class="align-left">Digitalisat: <xsl:for-each select="tei:ref">
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
                <xsl:for-each select="$matches">
                    <xsl:sort select="
                            if (normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1]) != '') then
                                0
                            else
                                1" data-type="number"/>
                    <xsl:sort
                        select="lower-case(normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1]))"/>
                    <xsl:variable name="t"
                        select="normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1])"/>
                    <li>
                        <a href="{@xml:id}.html">
                            <xsl:choose>
                                <xsl:when test="$t != ''">
                                    <xsl:value-of select="$t"/>
                                </xsl:when>
                                <xsl:otherwise>[??]</xsl:otherwise>
                            </xsl:choose>
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

                <xsl:variable name="rdf" select="doc('../data/rdf/authors.rdf')"/>
                <xsl:variable name="person-iri"
                    select="concat('https://sappho-digital.com/person/', $id)"/>
                <xsl:variable name="person" select="$rdf//ecrm:E21_Person[@rdf:about = $person-iri]"/>

                <xsl:variable name="birth-iri" select="$person/ecrm:P98i_was_born/@rdf:resource"/>
                <xsl:variable name="death-iri" select="$person/ecrm:P100i_died_in/@rdf:resource"/>

                <xsl:variable name="birth" select="$rdf//ecrm:E67_Birth[@rdf:about = $birth-iri]"/>
                <xsl:variable name="death" select="$rdf//ecrm:E69_Death[@rdf:about = $death-iri]"/>

                <xsl:variable name="bdate"
                    select="$rdf//ecrm:E52_Time-Span[@rdf:about = $birth/ecrm:P4_has_time_span/@rdf:resource]/rdfs:label"/>
                <xsl:variable name="ddate"
                    select="$rdf//ecrm:E52_Time-Span[@rdf:about = $death/ecrm:P4_has_time_span/@rdf:resource]/rdfs:label"/>

                <xsl:variable name="bplace"
                    select="$rdf//ecrm:E53_Place[ecrm:P7i_witnessed/ecrm:E67_Birth[@rdf:about = $birth-iri]]"/>
                <xsl:variable name="dplace"
                    select="$rdf//ecrm:E53_Place[ecrm:P7i_witnessed/ecrm:E69_Death[@rdf:about = $death-iri]]"/>

                <xsl:if test="$bdate or $bplace">
                    <p class="align-left">
                        <xsl:text>Geboren: </xsl:text>
                        <xsl:value-of select="local:format-partial-date(string(($bdate)[1]))"/>
                        <xsl:if test="$bplace">
                            <xsl:text>, </xsl:text>
                            
                            <xsl:variable name="label"
                                select="string(($bplace/rdfs:label[@xml:lang='de'], $bplace/rdfs:label)[1])"/>
                            
                            <xsl:variable name="id"
                                select="tokenize(string(($bplace/@rdf:about)[1]), '/')[last()]"/>
                            
                            <xsl:variable name="iri" select="concat('https://sappho-digital.com/place/', $id)"/>
                            
                            <xsl:variable name="hasPlace"
                                select="exists($works//ecrm:E53_Place[@rdf:about = $iri])"/>
                            
                            <xsl:variable name="wd" select="
                                string((
                                ($bplace/owl:sameAs[@rdf:resource[contains(., 'wikidata.org')]]/@rdf:resource)[1]
                                ))"/>
                            
                            <xsl:choose>
                                <xsl:when test="$hasPlace">
                                    <a href="{$id}.html"><xsl:value-of select="$label"/></a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$label"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                            <xsl:if test="$wd">
                                <a href="{$wd}" target="_blank" rel="noopener">
                                    <img src="images/wiki.png" alt="Wikidata"
                                        title="Wikidata-Eintrag öffnen" class="icon"/>
                                </a>
                            </xsl:if>
                        </xsl:if>
                        
                    </p>
                </xsl:if>

                <xsl:if test="$ddate or $dplace">
                    <p class="align-left">
                        <xsl:text>Gestorben: </xsl:text>
                        <xsl:value-of select="local:format-partial-date(string(($ddate)[1]))"/>
                        <xsl:if test="$dplace">
                            <xsl:text>, </xsl:text>
                            
                            <xsl:variable name="label"
                                select="string(($dplace/rdfs:label[@xml:lang='de'], $dplace/rdfs:label)[1])"/>
                            <xsl:variable name="id"
                                select="tokenize(string(($dplace/@rdf:about)[1]), '/')[last()]"/>
                            <xsl:variable name="iri" select="concat('https://sappho-digital.com/place/', $id)"/>
                            <xsl:variable name="hasPlace"
                                select="exists($works//ecrm:E53_Place[@rdf:about = $iri])"/>
                            <xsl:variable name="wd" select="
                                string((
                                ($dplace/owl:sameAs[@rdf:resource[contains(., 'wikidata.org')]]/@rdf:resource)[1]
                                ))"/>
                            
                            <xsl:choose>
                                <xsl:when test="$hasPlace">
                                    <a href="{$id}.html"><xsl:value-of select="$label"/></a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$label"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                            <xsl:if test="$wd">
                                <a href="{$wd}" target="_blank" rel="noopener">
                                    <img src="images/wiki.png" alt="Wikidata"
                                        title="Wikidata-Eintrag öffnen" class="icon"/>
                                </a>
                            </xsl:if>
                        </xsl:if>
                        
                    </p>
                </xsl:if>

                <p class="align-left">
                    <xsl:choose>
                        <xsl:when test="$count = 1">Ein Werk in der Datenbank:</xsl:when>
                        <xsl:otherwise><xsl:value-of select="$count"/> Werke in der
                            Datenbank:</xsl:otherwise>
                    </xsl:choose>
                </p>
                <ul>
                    <xsl:for-each select="$matches">
                        <xsl:sort select="
                                if (normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1]) != '') then
                                    0
                                else
                                    1" data-type="number"/>
                        <xsl:sort
                            select="lower-case(normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1]))"/>
                        <xsl:variable name="t"
                            select="normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1])"/>
                        <li>
                            <a href="{@xml:id}.html">
                                <xsl:choose>
                                    <xsl:when test="$t != ''">
                                        <xsl:value-of select="$t"/>
                                    </xsl:when>
                                    <xsl:otherwise>[??]</xsl:otherwise>
                                </xsl:choose>
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
                    <xsl:for-each select="$matches">
                        <xsl:sort select="
                                if (normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1]) != '') then
                                    0
                                else
                                    1" data-type="number"/>
                        <xsl:sort
                            select="lower-case(normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1]))"/>
                        <xsl:variable name="t"
                            select="normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1])"/>

                        <li>
                            <a href="{@xml:id}.html">
                                <xsl:choose>
                                    <xsl:when test="$t != ''">
                                        <xsl:value-of select="$t"/>
                                    </xsl:when>
                                    <xsl:otherwise>[??]</xsl:otherwise>
                                </xsl:choose>
                            </a>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- superwork -->
    <xsl:template match="tei:bibl[tei:title[@type = 'work']]" priority="2">
        <xsl:variable name="currentId" select="@xml:id"/>

        <xsl:variable name="containedWorks" select="//tei:bibl[tei:bibl/@xml:id = $currentId]"/>

        <xsl:next-match/>

        <xsl:if test="count($containedWorks) &gt; 0">
            <p class="align-left"> Enthält: <xsl:for-each select="$containedWorks">
                    <xsl:sort select="
                            if (normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1]) != '') then
                                0
                            else
                                1" data-type="number"/>
                    <xsl:sort
                        select="lower-case(normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1]))"/>
                    <xsl:variable name="t"
                        select="normalize-space((tei:title[@type = 'text'][1], tei:title[1])[1])"/>
                    <a href="{@xml:id}.html">
                        <xsl:choose>
                            <xsl:when test="$t != ''"><xsl:value-of select="$t"/></xsl:when>
                            <xsl:otherwise>[??]</xsl:otherwise>
                        </xsl:choose>
                    </a>
                    <xsl:if test="tei:author">
                        <xsl:text> (</xsl:text>
                        <xsl:choose>
                            <xsl:when test="tei:author[1]/@xml:id">
                                <a href="{tei:author[1]/@xml:id}.html">
                                    <xsl:value-of select="tei:author[1]"/>
                                </a>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="tei:author[1]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>) </xsl:text>
                    </xsl:if>
                    <xsl:if test="@ref">
                        <a href="{@ref}" target="_blank">
                            <img src="images/wiki.png" alt="Wikidata"
                                title="Wikidata-Eintrag öffnen" class="icon"/>
                        </a>
                    </xsl:if>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>

            <xsl:if test="$containedWorks/tei:date[@type = 'published']">
                <p class="align-left">Publikations-/Aufführungsjahr: <xsl:for-each-group
                        select="$containedWorks/tei:date[@type = 'published']" group-by="string()">
                        <xsl:variable name="date" select="current-grouping-key()"/>
                        <xsl:value-of select="$date"/>
                        <xsl:if test="position() != last()">, </xsl:if>
                    </xsl:for-each-group>
                </p>
            </xsl:if>

            <xsl:if test="$containedWorks/tei:pubPlace">
                <p class="align-left">Publikations-/Aufführungsort: <xsl:for-each-group
                        select="$containedWorks/tei:pubPlace" group-by="
                            if (@xml:id) then
                                @xml:id
                            else
                                lower-case(normalize-space(string(.)))">
                        <xsl:sort select="
                                if (normalize-space(string(current-group()[1])) != '') then
                                    0
                                else
                                    1" data-type="number"/>
                        <xsl:sort select="lower-case(normalize-space(string(current-group()[1])))"/>
                        <xsl:variable name="id" select="string((current-group()/@xml:id)[1])"/>
                        <xsl:variable name="ref" select="string((current-group()/@ref)[1])"/>
                        <xsl:variable name="t" select="normalize-space(string(current-group()[1]))"/>
                        <xsl:choose>
                            <xsl:when test="$id">
                                <a href="{$id}.html">
                                    <xsl:choose>
                                        <xsl:when test="$t != ''"><xsl:value-of
                                                select="current-group()[1]"/></xsl:when>
                                        <xsl:otherwise>[??]</xsl:otherwise>
                                    </xsl:choose>
                                </a>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="$t != ''"><xsl:value-of
                                            select="current-group()[1]"/></xsl:when>
                                    <xsl:otherwise>[??]</xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="$ref">
                            <a href="{$ref}" target="_blank">
                                <img src="images/wiki.png" alt="Wikidata"
                                    title="Wikidata-Eintrag öffnen" class="icon"/>
                            </a>
                        </xsl:if>
                        <xsl:if test="position() != last()">, </xsl:if>
                    </xsl:for-each-group>
                </p>
            </xsl:if>

            <xsl:if test="$containedWorks/tei:publisher">
                <p class="align-left">Verlag/Druckerei: <xsl:for-each-group
                        select="$containedWorks/tei:publisher" group-by="
                            if (@xml:id) then
                                @xml:id
                            else
                                lower-case(normalize-space(string(.)))">
                        <xsl:sort select="
                                if (normalize-space(string(current-group()[1])) != '') then
                                    0
                                else
                                    1" data-type="number"/>
                        <xsl:sort select="lower-case(normalize-space(string(current-group()[1])))"/>
                        <xsl:variable name="id" select="string((current-group()/@xml:id)[1])"/>
                        <xsl:variable name="ref" select="string((current-group()/@ref)[1])"/>
                        <xsl:variable name="t" select="normalize-space(string(current-group()[1]))"/>
                        <xsl:choose>
                            <xsl:when test="$id">
                                <a href="{$id}.html">
                                    <xsl:choose>
                                        <xsl:when test="$t != ''"><xsl:value-of
                                                select="current-group()[1]"/></xsl:when>
                                        <xsl:otherwise>[??]</xsl:otherwise>
                                    </xsl:choose>
                                </a>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="$t != ''"><xsl:value-of
                                            select="current-group()[1]"/></xsl:when>
                                    <xsl:otherwise>[??]</xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="$ref">
                            <a href="{$ref}" target="_blank">
                                <img src="images/wiki.png" alt="Wikidata"
                                    title="Wikidata-Eintrag öffnen" class="icon"/>
                            </a>
                        </xsl:if>
                        <xsl:if test="position() != last()">, </xsl:if>
                    </xsl:for-each-group>
                </p>
            </xsl:if>

        </xsl:if>
    </xsl:template>

    <!-- functions for dates -->

    <xsl:function name="local:month-name-de" as="xs:string">
        <xsl:param name="m" as="xs:integer"/>
        <xsl:sequence select="
                ('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
                'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember')[$m]"/>
    </xsl:function>

    <xsl:function name="local:format-partial-date" as="xs:string?">
        <xsl:param name="lex" as="xs:string?"/>
        <xsl:variable name="s" select="normalize-space($lex)"/>

        <xsl:choose>
            <!-- YYYY-MM-DD -->
            <xsl:when test="$s castable as xs:date">
                <xsl:variable name="d" select="xs:date($s)"/>
                <xsl:sequence
                    select="concat(day-from-date($d), '. ', local:month-name-de(month-from-date($d)), ' ', year-from-date($d))"
                />
            </xsl:when>

            <!-- YYYY-MM -->
            <xsl:when test="$s castable as xs:gYearMonth">
                <xsl:variable name="d" select="xs:date(concat($s, '-01'))"/>
                <xsl:sequence
                    select="concat(local:month-name-de(month-from-date($d)), ' ', year-from-date($d))"
                />
            </xsl:when>

            <!-- YYYY -->
            <xsl:when test="$s castable as xs:gYear">
                <xsl:sequence select="string($s)"/>
            </xsl:when>

            <!-- YYYY-MM-00 or YYYY-00-.. -->
            <xsl:when test="matches($s, '^\d{4}-\d{2}-\d{2}$')">
                <xsl:variable name="y" select="substring($s, 1, 4)"/>
                <xsl:variable name="m" select="substring($s, 6, 2)"/>
                <xsl:variable name="d" select="substring($s, 9, 2)"/>
                <xsl:choose>
                    <xsl:when test="$m = '00'">
                        <xsl:sequence select="$y"/>
                    </xsl:when>
                    <xsl:when
                        test="$d = '00' and $m castable as xs:integer and xs:integer($m) ge 1 and xs:integer($m) le 12">
                        <xsl:sequence select="concat(local:month-name-de(xs:integer($m)), ' ', $y)"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$s"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- YYYY-00 -->
            <xsl:when test="matches($s, '^\d{4}-00$')">
                <xsl:sequence select="substring($s, 1, 4)"/>
            </xsl:when>

            <!-- Fallback -->
            <xsl:otherwise>
                <xsl:sequence select="$s"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

</xsl:stylesheet>
