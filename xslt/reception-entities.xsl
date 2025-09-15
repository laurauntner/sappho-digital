<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:intro="https://w3id.org/lso/intro/currentbeta#" xmlns:u="urn:util"
    exclude-result-prefixes="xs u" version="2.0">

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:variable name="receptionEntities" select="doc('../data/rdf/sappho-reception.rdf')"/>
    <xsl:variable name="vocab" select="doc('../data/rdf/vocab.rdf')"/>

    <xsl:strip-space elements="*"/>
    <xsl:key name="by-about" match="*[@rdf:about]" use="@rdf:about"/>

    <!-- vocab -->

    <xsl:template match="/">
        <xsl:variable name="cs"
            select="$vocab/rdf:RDF/*[rdf:type/@rdf:resource = 'http://www.w3.org/2004/02/skos/core#ConceptScheme']"/>
        <xsl:variable name="tops"
            select="$vocab/rdf:RDF/*[@rdf:about = $cs/skos:hasTopConcept/@rdf:resource]"/>

        <xsl:result-document href="../html/vocab.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title"
                            select="'Vokabular zur literarischen Sappho-Rezeption'"/>
                    </xsl:call-template>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>
                                        <xsl:value-of
                                            select="($cs/skos:prefLabel[@xml:lang = 'de'], $cs/skos:prefLabel[@xml:lang = 'en'], $cs/skos:prefLabel, 'Vokabular')[1]"
                                        />
                                    </h1>
                                    <p class="align-left">
                                        <xsl:value-of
                                            select="normalize-space(($cs/skos:scopeNote[@xml:lang = 'de'], $cs/skos:scopeNote)[1])"
                                        />
                                    </p>
                                </div>

                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">
                                        <xsl:for-each select="distinct-values($tops/@rdf:about)">
                                            <xsl:variable name="top"
                                                select="$vocab/rdf:RDF/*[@rdf:about = current()]"/>
                                            <xsl:call-template name="render-concept">
                                                <xsl:with-param name="node" select="$top"/>
                                                <xsl:with-param name="open" select="false()"/>
                                            </xsl:call-template>
                                        </xsl:for-each>
                                    </ul>
                                </div>
                            </div>
                        </div>
                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <xsl:apply-templates select="/" mode="intertexts"/>
        <xsl:apply-templates select="/" mode="features"/>
    </xsl:template>

    <xsl:template name="label">
        <xsl:param name="n"/>
        <xsl:variable name="rawLabel"
            select="($n/skos:prefLabel[@xml:lang = 'de'], $n/skos:prefLabel[@xml:lang = 'en'], $n/skos:prefLabel, $n/rdfs:label, $n/@rdf:about)[1]"/>
        <!-- Liebe (Motiv) -> Liebe -->
        <xsl:value-of select="normalize-space(replace($rawLabel, '\s*\([^)]*\)', ''))"/>
    </xsl:template>

    <xsl:template name="render-concept">
        <xsl:param name="node" as="element()"/>
        <xsl:param name="open" as="xs:boolean" select="false()"/>

        <xsl:variable name="narrowerUris" select="$node/skos:narrower/@rdf:resource"/>
        <xsl:variable name="children" select="$node/ancestor::rdf:RDF/*[@rdf:about = $narrowerUris]"/>

        <li>
            <xsl:choose>
                <xsl:when test="exists($children)">
                    <details>
                        <xsl:if test="$open">
                            <xsl:attribute name="open">open</xsl:attribute>
                        </xsl:if>
                        <summary class="has-children">
                            <xsl:call-template name="label">
                                <xsl:with-param name="n" select="$node"/>
                            </xsl:call-template>
                        </summary>

                        <div class="skos-children">
                            <xsl:if test="$node/skos:definition or $node/skos:scopeNote">
                                <div class="skos-note">
                                    <xsl:if test="$node/skos:definition">
                                        <p class="align-left smaller-text breakable"
                                                ><strong>Definition:</strong>
                                            <xsl:text> </xsl:text>
                                            <xsl:value-of
                                                select="normalize-space(($node/skos:definition[@xml:lang = 'de'], $node/skos:definition)[1])"
                                            />
                                        </p>
                                    </xsl:if>
                                    <xsl:if test="$node/skos:scopeNote">
                                        <p class="align-left smaller-text breakable">
                                            <xsl:value-of
                                                select="normalize-space(($node/skos:scopeNote[@xml:lang = 'de'], $node/skos:scopeNote)[1])"
                                            />
                                        </p>
                                    </xsl:if>
                                </div>
                            </xsl:if>

                            <ul class="skos-tree">
                                <xsl:for-each select="$children">
                                    <xsl:sort
                                        select="lower-case((skos:prefLabel[@xml:lang = 'de'], skos:prefLabel[@xml:lang = 'en'], skos:prefLabel, rdfs:label, @rdf:about)[1])"/>
                                    <xsl:call-template name="render-concept">
                                        <xsl:with-param name="node" select="."/>
                                    </xsl:call-template>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </details>
                </xsl:when>
                <xsl:otherwise>
                    <span class="leaf">
                        <xsl:call-template name="label">
                            <xsl:with-param name="n" select="$node"/>
                        </xsl:call-template>
                    </span>

                    <xsl:if test="$node/skos:definition or $node/skos:scopeNote">
                        <div class="skos-note">
                            <xsl:value-of
                                select="normalize-space(($node/skos:definition[@xml:lang = 'de'], $node/skos:scopeNote[@xml:lang = 'de'], $node/skos:definition, $node/skos:scopeNote)[1])"
                            />
                        </div>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>

    <!-- label helpers -->

    <xsl:template name="label-of-uri">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="$uri and normalize-space($uri) != ''">
                <xsl:value-of select="u:label($uri)"/>
            </xsl:when>
            <xsl:otherwise>–</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:function name="u:label" as="xs:string">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="n" select="key('by-about', $uri, $receptionEntities)"/>
        <xsl:variable name="raw" select="normalize-space(($n/rdfs:label, $n/@rdf:about)[1])"/>
        <xsl:variable name="t1"
            select="replace($raw, '^\s*intertextual relation(ship)? between\s+', 'Intertextuelle Beziehung zwischen ', 'i')"/>
        <xsl:variable name="t2" select="replace($t1, '\s+and\s+', ' und ')"/>
        <xsl:variable name="t3" select="replace($t2, 'Expression of\s+', '', 'i')"/>
        <xsl:variable name="t4" select="replace($t3, '»\s*(Fragment[^«»]*Voigt)\s*«', '$1', 'i')"/>
        <xsl:variable name="t5"
            select="replace($t4, '^\s*(Motif|Topic|Plot|Textpassage)\s*:\s*', '', 'i')"/>
        <xsl:variable name="t6" select="replace($t5, '\s*\((place|person|work)\)\s*', '', 'i')"/>
        <xsl:variable name="t7" select="replace($t6, 'Reference to ', '', 'i')"/>
        <xsl:sequence select="normalize-space($t7)"/>
    </xsl:function>

    <xsl:function name="u:sgpl" as="xs:string">
        <xsl:param name="n" as="xs:integer"/>
        <xsl:param name="sg" as="xs:string"/>
        <xsl:param name="pl" as="xs:string"/>
        <xsl:sequence select="
                if ($n = 1) then
                    $sg
                else
                    $pl"/>
    </xsl:function>

    <xsl:function name="u:work-id" as="xs:string?">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:sequence select="
                if (exists($uri) and matches($uri, 'bibl_[^/#?]+')) then
                    let $id := replace($uri, '.*?(bibl_[^/#?]+).*', '$1')
                    return
                        if (starts-with($id, 'bibl_sappho')) then
                            ()
                        else
                            $id
                else
                    ()"/>
    </xsl:function>

    <xsl:function name="u:work-href" as="xs:string?">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:variable name="id" select="u:work-id($uri)"/>
        <xsl:sequence select="
                if ($id) then
                    concat('https://sappho-digital.com/', $id, '.html')
                else
                    ()"/>
    </xsl:function>

    <xsl:template name="render-label-or-link">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:variable name="href" select="u:work-href($uri)"/>
        <xsl:variable name="label">
            <xsl:call-template name="label-of-uri">
                <xsl:with-param name="uri" select="$uri"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$href">
                <a href="{$href}">
                    <xsl:value-of select="normalize-space(string($label))"/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space(string($label))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="render-label-with-icon">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:variable name="label-rtf">
            <xsl:call-template name="label-of-uri">
                <xsl:with-param name="uri" select="$uri"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="label" select="normalize-space(string($label-rtf))"/>
        <xsl:variable name="href" select="u:work-href($uri)"/>

        <xsl:value-of select="$label"/>

        <xsl:if test="$href">
            <a href="{$href}" class="ext-link" target="_blank" rel="noopener"
                onclick="event.stopPropagation()" title="Öffnen"> ↗ </a>
        </xsl:if>
    </xsl:template>

    <!-- helper functions for intertexts -->

    <!-- return distinct union of all common features in a relation -->
    <xsl:function name="u:common-uris" as="xs:string*">
        <xsl:param name="rel" as="element(intro:INT31_IntertextualRelation)"/>
        <xsl:variable name="sim" select="$rel/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource"/>
        <xsl:variable name="phr" select="$rel/intro:R24_hasRelatedEntity/@rdf:resource"/>
        <xsl:sequence select="
                distinct-values((
                data($sim[matches(., '/feature/person_ref/')]),
                data($sim[matches(., '/feature/place_ref/')]),
                data($sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]),
                data($phr[matches(., '/textpassage/phrase_')]),
                data($sim[matches(., '/feature/motif/')]),
                data($sim[matches(., '/feature/topic/')]),
                data($sim[matches(., '/feature/plot/')])
                ))
                "/>
    </xsl:function>

    <!-- return number of unique common features for a relation by @about -->
    <xsl:function name="u:common-count" as="xs:integer">
        <xsl:param name="about" as="xs:string"/>
        <xsl:variable name="rel" select="key('by-about', $about, $receptionEntities)"/>
        <xsl:sequence select="count(u:common-uris($rel))"/>
    </xsl:function>

    <!-- get items of one kind for rendering (motifs/topics/plots/persons/places/works/phrases) -->
    <xsl:function name="u:commons" as="xs:string*">
        <xsl:param name="rel" as="element(intro:INT31_IntertextualRelation)"/>
        <xsl:param name="kind" as="xs:string"/>
        <xsl:variable name="sim" select="$rel/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource"/>
        <xsl:variable name="phr" select="$rel/intro:R24_hasRelatedEntity/@rdf:resource"/>
        <xsl:choose>
            <xsl:when test="$kind = 'motifs'">
                <xsl:sequence select="distinct-values(data($sim[matches(., '/feature/motif/')]))"/>
            </xsl:when>
            <xsl:when test="$kind = 'topics'">
                <xsl:sequence select="distinct-values(data($sim[matches(., '/feature/topic/')]))"/>
            </xsl:when>
            <xsl:when test="$kind = 'plots'">
                <xsl:sequence select="distinct-values(data($sim[matches(., '/feature/plot/')]))"/>
            </xsl:when>
            <xsl:when test="$kind = 'persons'">
                <xsl:sequence
                    select="distinct-values(data($sim[matches(., '/feature/person_ref/')]))"/>
            </xsl:when>
            <xsl:when test="$kind = 'places'">
                <xsl:sequence
                    select="distinct-values(data($sim[matches(., '/feature/place_ref/')]))"/>
            </xsl:when>
            <xsl:when test="$kind = 'works'">
                <xsl:sequence
                    select="distinct-values(data($sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]))"
                />
            </xsl:when>
            <xsl:when test="$kind = 'phrases'">
                <xsl:sequence
                    select="distinct-values(data($phr[matches(., '/textpassage/phrase_')]))"/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:function>

    <!-- true if any pair in a group has > 0 commonalities -->
    <xsl:function name="u:any-common" as="xs:boolean">
        <xsl:param name="pairs" as="element(pair)*"/>
        <xsl:sequence select="
                some $p in $pairs
                    satisfies u:common-count(string($p/@about)) gt 0"/>
    </xsl:function>

    <!-- emit one category line if there are items -->
    <xsl:template name="emit-kind-list">
        <xsl:param name="rel" as="element(intro:INT31_IntertextualRelation)"/>
        <xsl:param name="kind" as="xs:string"/>
        <xsl:param name="sg" as="xs:string"/>
        <xsl:param name="pl" as="xs:string"/>

        <xsl:variable name="items" select="u:commons($rel, $kind)"/>
        <xsl:variable name="n" select="count($items)"/>
        <xsl:if test="$n &gt; 0">
            <div class="smaller-text indent">
                <strong>
                    <xsl:value-of select="u:sgpl($n, $sg, $pl)"/>
                </strong>
                <xsl:text> </xsl:text>
                <xsl:for-each select="$items">
                    <xsl:sort select="lower-case(u:label(.))"/>
                    <xsl:call-template name="render-label-or-link">
                        <xsl:with-param name="uri" select="."/>
                    </xsl:call-template>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- render one partner line (li > details ...) if cnt > 0 -->
    <xsl:template name="render-pair">
        <xsl:param name="about" as="xs:string"/>
        <xsl:param name="partner" as="xs:string"/>
        <xsl:param name="partner-uri" as="xs:string"/>

        <xsl:variable name="rel" select="key('by-about', $about, $receptionEntities)"/>
        <xsl:variable name="cnt" select="u:common-count($about)"/>

        <xsl:if test="$cnt &gt; 0">
            <xsl:variable name="cmt"
                select="normalize-space(($rel/rdfs:comment[@xml:lang = 'de'], $rel/rdfs:comment)[1])"/>

            <li>
                <details>
                    <summary>
                        <span class="leaf">
                            <xsl:text>Intertextuelle Beziehung mit </xsl:text>
                            <xsl:choose>
                                <xsl:when test="matches($partner, '^Fragment\s', 'i')">
                                    <xsl:value-of select="$partner"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>»</xsl:text>
                                    <xsl:value-of select="$partner"/>
                                    <xsl:text>«</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:call-template name="link-icon">
                                <xsl:with-param name="uri" select="$partner-uri"/>
                            </xsl:call-template>
                            <xsl:text> (</xsl:text>
                            <xsl:value-of select="$cnt"/>
                            <xsl:value-of
                                select="u:sgpl($cnt, ' Gemeinsamkeit', ' Gemeinsamkeiten')"/>
                            <xsl:text>)</xsl:text>
                        </span>
                    </summary>

                    <xsl:if test="$cmt != ''">
                        <div class="skos-note smaller-text indent">
                            <xsl:value-of select="$cmt"/>
                        </div>
                    </xsl:if>

                    <xsl:call-template name="emit-kind-list">
                        <xsl:with-param name="rel" select="$rel"/>
                        <xsl:with-param name="kind" select="'motifs'"/>
                        <xsl:with-param name="sg" select="'Gemeinsames Motiv:'"/>
                        <xsl:with-param name="pl" select="'Gemeinsame Motive:'"/>
                    </xsl:call-template>

                    <xsl:call-template name="emit-kind-list">
                        <xsl:with-param name="rel" select="$rel"/>
                        <xsl:with-param name="kind" select="'topics'"/>
                        <xsl:with-param name="sg" select="'Gemeinsames Thema:'"/>
                        <xsl:with-param name="pl" select="'Gemeinsame Themen:'"/>
                    </xsl:call-template>

                    <xsl:call-template name="emit-kind-list">
                        <xsl:with-param name="rel" select="$rel"/>
                        <xsl:with-param name="kind" select="'plots'"/>
                        <xsl:with-param name="sg" select="'Gemeinsamer Stoff:'"/>
                        <xsl:with-param name="pl" select="'Gemeinsame Stoffe:'"/>
                    </xsl:call-template>

                    <xsl:call-template name="emit-kind-list">
                        <xsl:with-param name="rel" select="$rel"/>
                        <xsl:with-param name="kind" select="'persons'"/>
                        <xsl:with-param name="sg" select="'Gemeinsame Personenreferenz:'"/>
                        <xsl:with-param name="pl" select="'Gemeinsame Personenreferenzen:'"/>
                    </xsl:call-template>

                    <xsl:call-template name="emit-kind-list">
                        <xsl:with-param name="rel" select="$rel"/>
                        <xsl:with-param name="kind" select="'places'"/>
                        <xsl:with-param name="sg" select="'Gemeinsame Ortsreferenz:'"/>
                        <xsl:with-param name="pl" select="'Gemeinsame Ortsreferenzen:'"/>
                    </xsl:call-template>

                    <xsl:call-template name="emit-kind-list">
                        <xsl:with-param name="rel" select="$rel"/>
                        <xsl:with-param name="kind" select="'works'"/>
                        <xsl:with-param name="sg" select="'Gemeinsame Werkreferenz:'"/>
                        <xsl:with-param name="pl" select="'Gemeinsame Werkreferenzen:'"/>
                    </xsl:call-template>

                    <xsl:call-template name="emit-kind-list">
                        <xsl:with-param name="rel" select="$rel"/>
                        <xsl:with-param name="kind" select="'phrases'"/>
                        <xsl:with-param name="sg" select="'Gemeinsame Phrase:'"/>
                        <xsl:with-param name="pl" select="'Gemeinsame Phrasen:'"/>
                    </xsl:call-template>
                </details>
            </li>
        </xsl:if>
    </xsl:template>

    <!-- link icons for intertexts -->
    <xsl:template name="link-icon">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:variable name="href" select="u:work-href($uri)"/>
        <xsl:if test="$href">
            <a href="{$href}" class="ext-link" target="_blank" rel="noopener"
                onclick="event.stopPropagation()" title="Öffnen"> ↗ </a>
        </xsl:if>
    </xsl:template>

    <!-- counter -->
    <xsl:template name="emit-count">
        <xsl:param name="n" as="xs:integer"/>
        <xsl:text> (</xsl:text>
        <xsl:value-of select="$n"/>
        <xsl:value-of select="u:sgpl($n, ' Vorkommnis', ' Vorkommnisse')"/>
        <xsl:text>)</xsl:text>
    </xsl:template>

    <!-- statistics -->
    <xsl:template name="emit-right-barchart">
        <xsl:param name="rels" as="element(intro:INT31_IntertextualRelation)*"/>
        <xsl:param name="items" as="xs:string*"/>
        <xsl:param name="kind" as="xs:string"/>
        <xsl:param name="chart-id" as="xs:string"/>
        <xsl:param name="chart-title" as="xs:string"/>
        <xsl:param name="top" as="xs:integer" select="10"/>

        <xsl:variable name="itemsWithCounts">
            <xsl:for-each select="$items">
                <xsl:variable name="this" select="."/>
                <xsl:variable name="occRels" select="
                        if ($kind = 'phrases')
                        then
                            $rels[intro:R24_hasRelatedEntity/@rdf:resource = $this]
                        else
                            $rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                <xsl:variable name="occTexts"
                    select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                <item name="{u:label($this)}" n="{count($occTexts)}"/>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="topItems" as="element(item)*">
            <xsl:perform-sort select="$itemsWithCounts/item[@n &gt; 0]">
                <xsl:sort select="number(@n)" data-type="number" order="descending"/>
                <xsl:sort select="lower-case(@name)"/>
            </xsl:perform-sort>
        </xsl:variable>
        <xsl:variable name="limited" select="$topItems[position() &lt;= $top]"/>

        <div class="wikidata-right">
            <div id="{$chart-id}" class="skos-chart" data-chart="bar" aria-label="{$chart-title}"/>
            <script type="application/json" id="{$chart-id}-data">{
                "title": "<xsl:value-of select="u:json-escape($chart-title)"/>",
                "seriesName": "Vorkommnisse",
                "data": [
                <xsl:for-each select="$limited">
                    {
                    "name": "<xsl:value-of select="u:json-escape(string(@name))"/>",
                    "y": <xsl:value-of select="@n"/>
                    }<xsl:if test="position() != last()">,</xsl:if>
                </xsl:for-each>
                ]
                }</script>
        </div>
    </xsl:template>

    <!-- JSON escapes -->
    <xsl:function name="u:json-escape" as="xs:string">
        <xsl:param name="s" as="xs:string?"/>
        <xsl:variable name="t1" select="replace(string($s), '\\', '\\\\')"/>
        <xsl:sequence select="replace($t1, '&quot;', '\\&quot;')"/>
    </xsl:function>

    <!-- intertextual relationships -->

    <xsl:template match="/" mode="intertexts">
        <xsl:variable name="rels"
            select="$receptionEntities//intro:INT31_IntertextualRelation[intro:R22i_relationIsBasedOnSimilarity]"/>

        <xsl:variable name="rels_frag"
            select="$rels[matches(@rdf:about, 'bibl_sappho_.*bibl_sappho_')]"/>
        <xsl:variable name="rels_recep"
            select="$rels[matches(@rdf:about, 'bibl_sappho_') and not(matches(@rdf:about, 'bibl_sappho_.*bibl_sappho_'))]"/>
        <xsl:variable name="rels_none" select="$rels[not(matches(@rdf:about, 'bibl_sappho_'))]"/>

        <!-- build pair lists -->
        <!-- frag ↔ frag -->
        <xsl:variable name="pairs_frag" as="element(pair)*">
            <xsl:for-each select="$rels_frag">
                <xsl:variable name="relAbout" select="string(@rdf:about)"/>
                <xsl:variable name="allUris" as="xs:string*" select="
                        (data(intro:R13_hasReferringEntity/@rdf:resource),
                        data(intro:R12_hasReferredToEntity/@rdf:resource))"/>
                <xsl:variable name="fragUris" as="xs:string*"
                    select="$allUris[matches(., '/bibl_sappho_')]"/>

                <xsl:for-each select="distinct-values($fragUris)">
                    <xsl:variable name="guri" select="."/>
                    <xsl:for-each select="distinct-values($fragUris[. ne $guri])">
                        <xsl:variable name="puri" select="."/>
                        <pair group="{u:label($guri)}" group-uri="{$guri}"
                            partner="{u:label($puri)}" partner-uri="{$puri}" about="{$relAbout}"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <!-- recep ↔ frag -->
        <xsl:variable name="pairs_recep" as="element(pair)*">
            <xsl:for-each select="$rels_recep">
                <xsl:variable name="relAbout" select="string(@rdf:about)"/>
                <xsl:variable name="allUris" as="xs:string*" select="
                        (data(intro:R13_hasReferringEntity/@rdf:resource),
                        data(intro:R12_hasReferredToEntity/@rdf:resource))"/>
                <xsl:variable name="fragUris" as="xs:string*"
                    select="$allUris[matches(., '/bibl_sappho_')]"/>
                <xsl:variable name="nonFragUris" as="xs:string*"
                    select="$allUris[not(matches(., '/bibl_sappho_'))]"/>

                <xsl:for-each select="distinct-values($nonFragUris)">
                    <xsl:variable name="guri" select="."/>
                    <xsl:for-each select="distinct-values($fragUris)">
                        <xsl:variable name="puri" select="."/>
                        <pair group="{u:label($guri)}" group-uri="{$guri}"
                            partner="{u:label($puri)}" partner-uri="{$puri}" about="{$relAbout}"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <!-- recep ↔ recep -->
        <xsl:variable name="pairs_none" as="element(pair)*">
            <xsl:for-each select="$rels_none">
                <xsl:variable name="relAbout" select="string(@rdf:about)"/>
                <xsl:variable name="allUris" as="xs:string*" select="
                        (data(intro:R13_hasReferringEntity/@rdf:resource),
                        data(intro:R12_hasReferredToEntity/@rdf:resource))"/>
                <xsl:variable name="nonFragUris" as="xs:string*"
                    select="$allUris[not(matches(., '/bibl_sappho_'))]"/>

                <xsl:for-each select="distinct-values($nonFragUris)">
                    <xsl:variable name="guri" select="."/>
                    <xsl:for-each select="distinct-values($nonFragUris[. ne $guri])">
                        <xsl:variable name="puri" select="."/>
                        <pair group="{u:label($guri)}" group-uri="{$guri}"
                            partner="{u:label($puri)}" partner-uri="{$puri}" about="{$relAbout}"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <xsl:result-document href="../html/intertexts.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Intertextuelle Beziehungen'"/>
                    </xsl:call-template>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>

                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Intertextuelle Beziehungen</h1>
                                    <p class="align-left">Liste aller (im weitesten Sinne)
                                        intertextuellen Beziehungen zwischen den exemplarisch
                                        analysierten Texten.</p>
                                </div>

                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">

                                        <!-- frag ↔ frag -->
                                        <li>
                                            <details>
                                                <summary class="has-children">Intertexuelle
                                                  Beziehungen zwischen Sappho-Fragmenten</summary>
                                                <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="$pairs_frag"
                                                  group-by="@group">
                                                  <xsl:sort select="lower-case(@group)"/>

                                                  <xsl:if test="u:any-common(current-group())">
                                                  <li>
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri"
                                                  select="string((current-group()[1]/@group-uri)[1])"
                                                  />
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="current-group()"
                                                  group-by="@partner">
                                                  <xsl:sort data-type="number" order="descending"
                                                  select="u:common-count(string((current-group()[1]/@about)[1]))"/>
                                                  <xsl:call-template name="render-pair">
                                                  <xsl:with-param name="about"
                                                  select="string((current-group()[1]/@about)[1])"/>
                                                  <xsl:with-param name="partner" select="@partner"/>
                                                  <xsl:with-param name="partner-uri"
                                                  select="string((current-group()[1]/@partner-uri)[1])"
                                                  />
                                                  </xsl:call-template>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </li>
                                                  </xsl:if>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                </div>
                                            </details>
                                        </li>

                                        <!-- reception testimony ↔ frag -->
                                        <li>
                                            <details>
                                                <summary class="has-children">Intertexuelle
                                                  Beziehungen zwischen Rezeptionszeugnissen und
                                                  Sappho-Fragmenten</summary>
                                                <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="$pairs_recep"
                                                  group-by="@group">
                                                  <xsl:sort select="lower-case(@group)"/>

                                                  <xsl:if test="u:any-common(current-group())">
                                                  <li>
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri"
                                                  select="string((current-group()[1]/@group-uri)[1])"
                                                  />
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="current-group()"
                                                  group-by="@partner">
                                                  <xsl:sort data-type="number" order="descending"
                                                  select="u:common-count(string((current-group()[1]/@about)[1]))"/>
                                                  <xsl:call-template name="render-pair">
                                                  <xsl:with-param name="about"
                                                  select="string((current-group()[1]/@about)[1])"/>
                                                  <xsl:with-param name="partner" select="@partner"/>
                                                  <xsl:with-param name="partner-uri"
                                                  select="string((current-group()[1]/@partner-uri)[1])"
                                                  />
                                                  </xsl:call-template>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </li>
                                                  </xsl:if>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                </div>
                                            </details>
                                        </li>

                                        <!-- reception testimony ↔ reception testimony -->
                                        <li>
                                            <details>
                                                <summary class="has-children">Intertexuelle
                                                  Beziehungen zwischen
                                                  Rezeptionszeugnissen</summary>
                                                <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="$pairs_none"
                                                  group-by="@group">
                                                  <xsl:sort select="lower-case(@group)"/>

                                                  <xsl:if test="u:any-common(current-group())">
                                                  <li>
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri"
                                                  select="string((current-group()[1]/@group-uri)[1])"
                                                  />
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="current-group()"
                                                  group-by="@partner">
                                                  <xsl:sort data-type="number" order="descending"
                                                  select="u:common-count(string((current-group()[1]/@about)[1]))"/>
                                                  <xsl:call-template name="render-pair">
                                                  <xsl:with-param name="about"
                                                  select="string((current-group()[1]/@about)[1])"/>
                                                  <xsl:with-param name="partner" select="@partner"/>
                                                  <xsl:with-param name="partner-uri"
                                                  select="string((current-group()[1]/@partner-uri)[1])"
                                                  />
                                                  </xsl:call-template>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </li>
                                                  </xsl:if>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                </div>
                                            </details>
                                        </li>

                                    </ul>
                                </div>
                            </div>
                        </div>

                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>

    <!-- features -->

    <xsl:template match="/" mode="features">
        <xsl:variable name="rels" select="$receptionEntities//intro:INT31_IntertextualRelation"/>

        <xsl:variable name="u_persons"
            select="distinct-values($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/person_ref/')])"/>
        <xsl:variable name="u_places"
            select="distinct-values($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/place_ref/')])"/>
        <xsl:variable name="u_works"
            select="distinct-values(($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/work_ref/')], $rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/actualization/work_ref/')]))"/>
        <xsl:variable name="u_phrases"
            select="distinct-values($rels/intro:R24_hasRelatedEntity/@rdf:resource[matches(., '/textpassage/phrase_')])"/>
        <xsl:variable name="u_motifs"
            select="distinct-values($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/motif/')])"/>
        <xsl:variable name="u_topics"
            select="distinct-values($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/topic/')])"/>
        <xsl:variable name="u_plots"
            select="distinct-values($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/plot/')])"/>

        <!-- references to persons -->
        <xsl:result-document href="../html/pers-refs.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Personenreferenzen'"/>
                    </xsl:call-template>
                    <script src="https://code.highcharts.com/highcharts.js"/>
                    <script src="./js/feature-statistics.js"/>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Personenreferenzen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <div class="wikidata-layout has-wide-chart">
                                        <div class="wikidata-left">
                                            <ul class="skos-tree">
                                                <xsl:for-each select="$u_persons">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <xsl:variable name="this" select="."/>
                                                  <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                  <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                  <xsl:variable name="n" select="count($occTexts)"/>
                                                  <xsl:choose>
                                                  <xsl:when test="$n &gt; 0">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </li>
                                                  </xsl:for-each>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="leaf">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </li>
                                                </xsl:for-each>
                                            </ul>
                                        </div>
                                        <xsl:call-template name="emit-right-barchart">
                                            <xsl:with-param name="rels" select="$rels"/>
                                            <xsl:with-param name="items" select="$u_persons"/>
                                            <xsl:with-param name="kind" select="'persons'"/>
                                            <xsl:with-param name="chart-id" select="'chart-persons'"/>
                                            <xsl:with-param name="chart-title" select="'Top Personen'"/>
                                            <xsl:with-param name="top" select="20"/>
                                        </xsl:call-template>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <!-- references to places -->
        <xsl:result-document href="../html/place-refs.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Ortsreferenzen'"/>
                    </xsl:call-template>
                    <script src="https://code.highcharts.com/highcharts.js"/>
                    <script src="./js/feature-statistics.js"/>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Ortsreferenzen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <div class="wikidata-layout has-wide-chart">
                                        <div class="wikidata-left">
                                            <ul class="skos-tree">
                                                <xsl:for-each select="$u_places">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <xsl:variable name="this" select="."/>
                                                  <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                  <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                  <xsl:variable name="n" select="count($occTexts)"/>
                                                  <xsl:choose>
                                                  <xsl:when test="$n &gt; 0">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </li>
                                                  </xsl:for-each>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="leaf">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </li>
                                                </xsl:for-each>
                                            </ul>
                                        </div>
                                        <xsl:call-template name="emit-right-barchart">
                                            <xsl:with-param name="rels" select="$rels"/>
                                            <xsl:with-param name="items" select="$u_places"/>
                                            <xsl:with-param name="kind" select="'places'"/>
                                            <xsl:with-param name="chart-id" select="'chart-places'"/>
                                            <xsl:with-param name="chart-title" select="'Top Orte'"/>
                                            <xsl:with-param name="top" select="20"/>
                                        </xsl:call-template>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <!-- references to works -->
        <xsl:result-document href="../html/work-refs.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Werkreferenzen'"/>
                    </xsl:call-template>
                    <script src="https://code.highcharts.com/highcharts.js"/>
                    <script src="./js/feature-statistics.js"/>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Werkreferenzen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <div class="wikidata-layout has-wide-chart">
                                        <div class="wikidata-left">
                                            <ul class="skos-tree">
                                                <xsl:for-each select="$u_works">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <xsl:variable name="this" select="."/>
                                                  <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                  <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                  <xsl:variable name="n" select="count($occTexts)"/>
                                                  <xsl:choose>
                                                  <xsl:when test="$n &gt; 0">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </li>
                                                  </xsl:for-each>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="leaf">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </li>
                                                </xsl:for-each>
                                            </ul>
                                        </div>
                                        <xsl:call-template name="emit-right-barchart">
                                            <xsl:with-param name="rels" select="$rels"/>
                                            <xsl:with-param name="items" select="$u_works"/>
                                            <xsl:with-param name="kind" select="'works'"/>
                                            <xsl:with-param name="chart-id" select="'chart-works'"/>
                                            <xsl:with-param name="chart-title" select="'Top Werke'"/>
                                            <xsl:with-param name="top" select="20"/>
                                        </xsl:call-template>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <!-- text passages -->
        <xsl:result-document href="../html/text-passages.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Phrasen'"/>
                    </xsl:call-template>
                    <script src="https://code.highcharts.com/highcharts.js"/>
                    <script src="./js/feature-statistics.js"/>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Phrasen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <div class="wikidata-layout has-wide-chart">
                                        <div class="wikidata-left">
                                            <ul class="skos-tree">
                                                <xsl:for-each select="$u_phrases">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <xsl:variable name="this" select="."/>
                                                  <xsl:variable name="occRels"
                                                  select="$rels[intro:R24_hasRelatedEntity/@rdf:resource = $this]"/>
                                                  <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                  <xsl:variable name="n" select="count($occTexts)"/>
                                                  <xsl:choose>
                                                  <xsl:when test="$n &gt; 0">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </li>
                                                  </xsl:for-each>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="leaf">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </li>
                                                </xsl:for-each>
                                            </ul>
                                        </div>
                                        <xsl:call-template name="emit-right-barchart">
                                            <xsl:with-param name="rels" select="$rels"/>
                                            <xsl:with-param name="items" select="$u_phrases"/>
                                            <xsl:with-param name="kind" select="'phrases'"/> <!-- NEU: anderer Pfad -->
                                            <xsl:with-param name="chart-id" select="'chart-phrases'"/>
                                            <xsl:with-param name="chart-title" select="'Top Phrasen'"/>
                                            <xsl:with-param name="top" select="20"/>
                                        </xsl:call-template>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <!-- motifs -->
        <xsl:result-document href="../html/motifs.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Motive'"/>
                    </xsl:call-template>
                    <script src="https://code.highcharts.com/highcharts.js"/>
                    <script src="./js/feature-statistics.js"/>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Motive</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <div class="wikidata-layout has-wide-chart">
                                        <div class="wikidata-left">
                                            <ul class="skos-tree">
                                                <xsl:for-each select="$u_motifs">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <xsl:variable name="this" select="."/>
                                                  <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                  <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                  <xsl:variable name="n" select="count($occTexts)"/>
                                                  <xsl:choose>
                                                  <xsl:when test="$n &gt; 0">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </li>
                                                  </xsl:for-each>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="leaf">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </li>
                                                </xsl:for-each>
                                            </ul>
                                        </div>
                                        <xsl:call-template name="emit-right-barchart">
                                            <xsl:with-param name="rels" select="$rels"/>
                                            <xsl:with-param name="items" select="$u_motifs"/>
                                            <xsl:with-param name="kind" select="'motifs'"/>
                                            <xsl:with-param name="chart-id" select="'chart-motifs'"/>
                                            <xsl:with-param name="chart-title" select="'Top Motive'"/>
                                            <xsl:with-param name="top" select="20"/>
                                        </xsl:call-template>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <!-- topics -->
        <xsl:result-document href="../html/topics.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Themen'"/>
                    </xsl:call-template>
                    <script src="https://code.highcharts.com/highcharts.js"/>
                    <script src="./js/feature-statistics.js"/>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Themen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <div class="wikidata-layout has-wide-chart">
                                        <div class="wikidata-left">
                                            <ul class="skos-tree">
                                                <xsl:for-each select="$u_topics">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <xsl:variable name="this" select="."/>
                                                  <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                  <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                  <xsl:variable name="n" select="count($occTexts)"/>
                                                  <xsl:choose>
                                                  <xsl:when test="$n &gt; 0">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </li>
                                                  </xsl:for-each>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="leaf">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </li>
                                                </xsl:for-each>
                                            </ul>
                                        </div>
                                        <xsl:call-template name="emit-right-barchart">
                                            <xsl:with-param name="rels" select="$rels"/>
                                            <xsl:with-param name="items" select="$u_topics"/>
                                            <xsl:with-param name="kind" select="'topics'"/>
                                            <xsl:with-param name="chart-id" select="'chart-topics'"/>
                                            <xsl:with-param name="chart-title" select="'Top Themen'"/>
                                            <xsl:with-param name="top" select="20"/>
                                        </xsl:call-template>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <!-- plots -->
        <xsl:result-document href="../html/plots.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Stoffe'"/>
                    </xsl:call-template>
                    <script src="https://code.highcharts.com/highcharts.js"/>
                    <script src="./js/feature-statistics.js"/>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Stoffe</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <div class="wikidata-layout has-wide-chart">
                                        <div class="wikidata-left">
                                            <ul class="skos-tree">
                                                <xsl:for-each select="$u_plots">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <xsl:variable name="this" select="."/>
                                                  <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                  <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                  <xsl:variable name="n" select="count($occTexts)"/>
                                                  <xsl:choose>
                                                  <xsl:when test="$n &gt; 0">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </li>
                                                  </xsl:for-each>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <span class="leaf">
                                                  <xsl:call-template name="render-label-with-icon">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  <xsl:call-template name="emit-count">
                                                  <xsl:with-param name="n" select="$n"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  </li>
                                                </xsl:for-each>
                                            </ul>
                                        </div>
                                        <xsl:call-template name="emit-right-barchart">
                                            <xsl:with-param name="rels" select="$rels"/>
                                            <xsl:with-param name="items" select="$u_plots"/>
                                            <xsl:with-param name="kind" select="'plots'"/>
                                            <xsl:with-param name="chart-id" select="'chart-plots'"/>
                                            <xsl:with-param name="chart-title" select="'Top Stoffe'"/>
                                            <xsl:with-param name="top" select="20"/>
                                        </xsl:call-template>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <xsl:call-template name="html_footer"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>
