<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:intro="https://w3id.org/lso/intro/currentbeta#" exclude-result-prefixes="xs" version="2.0">

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
                                        <xsl:value-of select="
                                                ($cs/skos:prefLabel[@xml:lang = 'de'],
                                                $cs/skos:prefLabel[@xml:lang = 'en'],
                                                $cs/skos:prefLabel,
                                                'Vokabular')[1]"
                                        />
                                    </h1>
                                    <p class="align-left">
                                        <xsl:value-of select="
                                                normalize-space(($cs/skos:scopeNote[@xml:lang = 'de'],
                                                $cs/skos:scopeNote)[1])"
                                        />
                                    </p>
                                </div>

                                <div class="card-body skos-wrap">
                                    <!-- list/tree -->
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
    </xsl:template>

    <xsl:template name="label">
        <xsl:param name="n"/>
        <xsl:variable name="rawLabel" select="
                ($n/skos:prefLabel[@xml:lang = 'de'],
                $n/skos:prefLabel[@xml:lang = 'en'],
                $n/skos:prefLabel,
                $n/rdfs:label,
                $n/@rdf:about)[1]"/>
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
                <!-- children -->
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

                        <!-- definition/scopeNote -->
                        <div class="skos-children">
                            <xsl:if test="$node/skos:definition or $node/skos:scopeNote">
                                <div class="skos-note">
                                    <xsl:if test="$node/skos:definition">
                                        <p class="align-left smaller-text breakable"
                                                ><strong>Definition:</strong>
                                            <xsl:text> </xsl:text>
                                            <xsl:value-of select="
                                                    normalize-space(($node/skos:definition[@xml:lang = 'de'],
                                                    $node/skos:definition)[1])"
                                            />
                                        </p>
                                    </xsl:if>
                                    <xsl:if test="$node/skos:scopeNote">
                                        <p class="align-left smaller-text breakable">
                                            <xsl:value-of select="
                                                    normalize-space(($node/skos:scopeNote[@xml:lang = 'de'],
                                                    $node/skos:scopeNote)[1])"
                                            />
                                        </p>
                                    </xsl:if>
                                </div>
                            </xsl:if>

                            <!-- children -->
                            <ul class="skos-tree">
                                <xsl:for-each select="$children">
                                    <xsl:sort select="
                                            lower-case((skos:prefLabel[@xml:lang = 'de'],
                                            skos:prefLabel[@xml:lang = 'en'],
                                            skos:prefLabel, rdfs:label, @rdf:about)[1])"/>
                                    <xsl:call-template name="render-concept">
                                        <xsl:with-param name="node" select="."/>
                                    </xsl:call-template>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </details>
                </xsl:when>

                <!-- no children -->
                <xsl:otherwise>
                    <span class="leaf">
                        <xsl:call-template name="label">
                            <xsl:with-param name="n" select="$node"/>
                        </xsl:call-template>
                    </span>

                    <xsl:if test="$node/skos:definition or $node/skos:scopeNote">
                        <div class="skos-note">
                            <xsl:value-of select="
                                    normalize-space(($node/skos:definition[@xml:lang = 'de'],
                                    $node/skos:scopeNote[@xml:lang = 'de'],
                                    $node/skos:definition,
                                    $node/skos:scopeNote)[1])"/>
                        </div>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>

    <!-- intertextual relationships -->

    <xsl:template match="/" mode="intertexts">
        <xsl:variable name="rels"
            select="$receptionEntities//intro:INT31_IntertextualRelation[intro:R22i_relationIsBasedOnSimilarity]"/>

        <xsl:variable name="rels_frag"
            select="$rels[matches(@rdf:about, 'bibl_sappho_.*bibl_sappho_')]"/>
        <xsl:variable name="rels_recep"
            select="$rels[matches(@rdf:about, 'bibl_sappho_') and not(matches(@rdf:about, 'bibl_sappho_.*bibl_sappho_'))]"/>

        <xsl:variable name="pairs_frag" as="element(pair)*">
            <xsl:for-each select="$rels_frag">
                <xsl:variable name="relAbout" select="string(@rdf:about)"/>
                <xsl:variable name="allLabels" as="xs:string*">
                    <xsl:for-each
                        select="(intro:R13_hasReferringEntity/@rdf:resource, intro:R12_hasReferredToEntity/@rdf:resource)">
                        <xsl:variable name="rtf">
                            <xsl:call-template name="label-of-uri">
                                <xsl:with-param name="uri" select="string(.)"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:sequence select="normalize-space(string($rtf))"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="fragLabels" select="
                        for $l in $allLabels
                        return
                            if (matches($l, '^Fragment\s', 'i')) then
                                $l
                            else
                                ()" as="xs:string*"/>
                <xsl:for-each select="distinct-values($fragLabels)">
                    <xsl:variable name="g" select="."/>
                    <xsl:for-each select="distinct-values($fragLabels[. ne $g])">
                        <pair group="{$g}" partner="{.}" about="{$relAbout}"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="pairs_recep" as="element(pair)*">
            <xsl:for-each select="$rels_recep">
                <xsl:variable name="relAbout" select="string(@rdf:about)"/>
                <xsl:variable name="allLabels" as="xs:string*">
                    <xsl:for-each
                        select="(intro:R13_hasReferringEntity/@rdf:resource, intro:R12_hasReferredToEntity/@rdf:resource)">
                        <xsl:variable name="rtf">
                            <xsl:call-template name="label-of-uri">
                                <xsl:with-param name="uri" select="string(.)"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:sequence select="normalize-space(string($rtf))"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="fragLabels" select="
                        for $l in $allLabels
                        return
                            if (matches($l, '^Fragment\s', 'i')) then
                                $l
                            else
                                ()" as="xs:string*"/>
                <xsl:variable name="nonFragLabels" select="
                        for $l in $allLabels
                        return
                            if (not(matches($l, '^Fragment\s', 'i'))) then
                                $l
                            else
                                ()" as="xs:string*"/>
                <xsl:for-each select="distinct-values($nonFragLabels)">
                    <xsl:variable name="g" select="."/>
                    <xsl:for-each select="distinct-values($fragLabels)">
                        <pair group="{$g}" partner="{.}" about="{$relAbout}"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="rels_none" select="$rels[not(matches(@rdf:about, 'bibl_sappho_'))]"/>

        <xsl:variable name="pairs_none" as="element(pair)*">
            <xsl:for-each select="$rels_none">
                <xsl:variable name="relAbout" select="string(@rdf:about)"/>
                <xsl:variable name="labels" as="xs:string*">
                    <xsl:for-each
                        select="(intro:R13_hasReferringEntity/@rdf:resource, intro:R12_hasReferredToEntity/@rdf:resource)">
                        <xsl:variable name="rtf">
                            <xsl:call-template name="label-of-uri">
                                <xsl:with-param name="uri" select="string(.)"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:sequence select="normalize-space(string($rtf))"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="nonFragLabels" select="
                        for $l in $labels
                        return
                            if (not(matches($l, '^Fragment\s', 'i'))) then
                                $l
                            else
                                ()" as="xs:string*"/>
                <xsl:for-each select="distinct-values($nonFragLabels)">
                    <xsl:variable name="g" select="."/>
                    <xsl:for-each select="distinct-values($nonFragLabels[. ne $g])">
                        <pair group="{$g}" partner="{.}" about="{$relAbout}"/>
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

                                        <li>
                                            <details>
                                                <summary class="has-children">Intertexuelle
                                                  Beziehungen zwischen Sappho-Fragmenten</summary>
                                                <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="$pairs_frag"
                                                  group-by="@group">
                                                  <xsl:sort select="lower-case(@group)"/>
                                                  <li>
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:value-of select="@group"/>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="current-group()"
                                                  group-by="@partner">
                                                  <xsl:sort select="
                                                                                        count(
                                                                                        distinct-values((
                                                                                        data(key('by-about', (current-group()[1]/@about)[1], $receptionEntities)
                                                                                        /intro:R22i_relationIsBasedOnSimilarity/@rdf:resource
                                                                                        [matches(., '/feature/(person_ref|place_ref|work_ref|motif|topic|plot)/')
                                                                                        or matches(., '/actualization/work_ref/')]),
                                                                                        data(key('by-about', (current-group()[1]/@about)[1], $receptionEntities)
                                                                                        /intro:R24_hasRelatedEntity/@rdf:resource
                                                                                        [matches(., '/textpassage/phrase_')])
                                                                                        ))
                                                                                        )"
                                                  order="descending" data-type="number"/>
                                                  <xsl:if test="position() le 10">
                                                  <xsl:variable name="rel"
                                                  select="key('by-about', (current-group()[1]/@about)[1], $receptionEntities)"/>
                                                  <xsl:variable name="sim"
                                                  select="$rel/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource"/>
                                                  <xsl:variable name="phr"
                                                  select="$rel/intro:R24_hasRelatedEntity/@rdf:resource"/>

                                                  <xsl:variable name="u_persons"
                                                  select="distinct-values(data($sim[matches(., '/feature/person_ref/')]))"/>
                                                  <xsl:variable name="u_places"
                                                  select="distinct-values(data($sim[matches(., '/feature/place_ref/')]))"/>
                                                  <xsl:variable name="u_works"
                                                  select="distinct-values(data($sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]))"/>
                                                  <xsl:variable name="u_phrases"
                                                  select="distinct-values(data($phr[matches(., '/textpassage/phrase_')]))"/>
                                                  <xsl:variable name="u_motifs"
                                                  select="distinct-values(data($sim[matches(., '/feature/motif/')]))"/>
                                                  <xsl:variable name="u_topics"
                                                  select="distinct-values(data($sim[matches(., '/feature/topic/')]))"/>
                                                  <xsl:variable name="u_plots"
                                                  select="distinct-values(data($sim[matches(., '/feature/plot/')]))"/>

                                                  <xsl:variable name="cnt" select="
                                                                                            count(distinct-values((
                                                                                            $u_persons, $u_places, $u_works, $u_phrases, $u_motifs, $u_topics, $u_plots
                                                                                            )))"/>
                                                  <li>
                                                  <span class="leaf">Intertextuelle Beziehung mit
                                                  <xsl:value-of select="@partner"/> (<xsl:value-of
                                                  select="$cnt"/> Gemeinsamkeiten)</span>
                                                  <xsl:variable name="cmt"
                                                  select="normalize-space(($rel/rdfs:comment[@xml:lang = 'de'], $rel/rdfs:comment)[1])"/>
                                                  <xsl:if test="$cmt != ''">
                                                  <div class="skos-note smaller-text">
                                                  <xsl:value-of select="$cmt"/>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/person_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Personenreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/person_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/place_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Ortsreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/place_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Werkreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$phr[matches(., '/textpassage/phrase_')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Phrasen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($phr[matches(., '/textpassage/phrase_')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/motif/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Motive: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/motif/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/topic/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Themen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/topic/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/plot/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Stoffe: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/plot/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  </li>
                                                  </xsl:if>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </li>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                </div>
                                            </details>
                                        </li>

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
                                                  <li>
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:value-of select="@group"/>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="current-group()"
                                                  group-by="@partner">
                                                  <xsl:sort select="
                                                                                        count(
                                                                                        distinct-values((
                                                                                        data(key('by-about', (current-group()[1]/@about)[1], $receptionEntities)
                                                                                        /intro:R22i_relationIsBasedOnSimilarity/@rdf:resource
                                                                                        [matches(., '/feature/(person_ref|place_ref|work_ref|motif|topic|plot)/')
                                                                                        or matches(., '/actualization/work_ref/')]),
                                                                                        data(key('by-about', (current-group()[1]/@about)[1], $receptionEntities)
                                                                                        /intro:R24_hasRelatedEntity/@rdf:resource
                                                                                        [matches(., '/textpassage/phrase_')])
                                                                                        ))
                                                                                        )"
                                                  order="descending" data-type="number"/>
                                                  <xsl:if test="position() le 10">
                                                  <xsl:variable name="rel"
                                                  select="key('by-about', (current-group()[1]/@about)[1], $receptionEntities)"/>
                                                  <xsl:variable name="sim"
                                                  select="$rel/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource"/>
                                                  <xsl:variable name="phr"
                                                  select="$rel/intro:R24_hasRelatedEntity/@rdf:resource"/>

                                                  <xsl:variable name="u_persons"
                                                  select="distinct-values(data($sim[matches(., '/feature/person_ref/')]))"/>
                                                  <xsl:variable name="u_places"
                                                  select="distinct-values(data($sim[matches(., '/feature/place_ref/')]))"/>
                                                  <xsl:variable name="u_works"
                                                  select="distinct-values(data($sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]))"/>
                                                  <xsl:variable name="u_phrases"
                                                  select="distinct-values(data($phr[matches(., '/textpassage/phrase_')]))"/>
                                                  <xsl:variable name="u_motifs"
                                                  select="distinct-values(data($sim[matches(., '/feature/motif/')]))"/>
                                                  <xsl:variable name="u_topics"
                                                  select="distinct-values(data($sim[matches(., '/feature/topic/')]))"/>
                                                  <xsl:variable name="u_plots"
                                                  select="distinct-values(data($sim[matches(., '/feature/plot/')]))"/>

                                                  <xsl:variable name="cnt" select="
                                                                                            count(distinct-values((
                                                                                            $u_persons, $u_places, $u_works, $u_phrases, $u_motifs, $u_topics, $u_plots
                                                                                            )))"/>
                                                  <li>
                                                  <span class="leaf">Intertextuelle Beziehung mit
                                                  <xsl:value-of select="@partner"/> (<xsl:value-of
                                                  select="$cnt"/> Gemeinsamkeiten)</span>
                                                  <xsl:variable name="cmt"
                                                  select="normalize-space(($rel/rdfs:comment[@xml:lang = 'de'], $rel/rdfs:comment)[1])"/>
                                                  <xsl:if test="$cmt != ''">
                                                  <div class="skos-note smaller-text">
                                                  <xsl:value-of select="$cmt"/>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/person_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Personenreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/person_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/place_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Ortsreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/place_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Werkreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$phr[matches(., '/textpassage/phrase_')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Phrasen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($phr[matches(., '/textpassage/phrase_')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/motif/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Motive: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/motif/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/topic/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Themen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/topic/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/plot/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Stoffe: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/plot/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  </li>
                                                  </xsl:if>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </li>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                </div>
                                            </details>
                                        </li>

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
                                                  <li>
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:value-of select="@group"/>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each-group select="current-group()"
                                                  group-by="@partner">
                                                  <xsl:sort select="
                                                                                        count(
                                                                                        distinct-values((
                                                                                        data(key('by-about', (current-group()[1]/@about)[1], $receptionEntities)
                                                                                        /intro:R22i_relationIsBasedOnSimilarity/@rdf:resource
                                                                                        [matches(., '/feature/(person_ref|place_ref|work_ref|motif|topic|plot)/')
                                                                                        or matches(., '/actualization/work_ref/')]),
                                                                                        data(key('by-about', (current-group()[1]/@about)[1], $receptionEntities)
                                                                                        /intro:R24_hasRelatedEntity/@rdf:resource
                                                                                        [matches(., '/textpassage/phrase_')])
                                                                                        ))
                                                                                        )"
                                                  order="descending" data-type="number"/>
                                                  <xsl:if test="position() le 10">
                                                  <xsl:variable name="rel"
                                                  select="key('by-about', (current-group()[1]/@about)[1], $receptionEntities)"/>
                                                  <xsl:variable name="sim"
                                                  select="$rel/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource"/>
                                                  <xsl:variable name="phr"
                                                  select="$rel/intro:R24_hasRelatedEntity/@rdf:resource"/>

                                                  <xsl:variable name="u_persons"
                                                  select="distinct-values(data($sim[matches(., '/feature/person_ref/')]))"/>
                                                  <xsl:variable name="u_places"
                                                  select="distinct-values(data($sim[matches(., '/feature/place_ref/')]))"/>
                                                  <xsl:variable name="u_works"
                                                  select="distinct-values(data($sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]))"/>
                                                  <xsl:variable name="u_phrases"
                                                  select="distinct-values(data($phr[matches(., '/textpassage/phrase_')]))"/>
                                                  <xsl:variable name="u_motifs"
                                                  select="distinct-values(data($sim[matches(., '/feature/motif/')]))"/>
                                                  <xsl:variable name="u_topics"
                                                  select="distinct-values(data($sim[matches(., '/feature/topic/')]))"/>
                                                  <xsl:variable name="u_plots"
                                                  select="distinct-values(data($sim[matches(., '/feature/plot/')]))"/>

                                                  <xsl:variable name="cnt" select="
                                                                                            count(distinct-values((
                                                                                            $u_persons, $u_places, $u_works, $u_phrases, $u_motifs, $u_topics, $u_plots
                                                                                            )))"/>
                                                  <li>
                                                  <span class="leaf">Intertextuelle Beziehung mit
                                                  <xsl:value-of select="@partner"/> (<xsl:value-of
                                                  select="$cnt"/> Gemeinsamkeiten)</span>
                                                  <xsl:variable name="cmt"
                                                  select="normalize-space(($rel/rdfs:comment[@xml:lang = 'de'], $rel/rdfs:comment)[1])"/>
                                                  <xsl:if test="$cmt != ''">
                                                  <div class="skos-note smaller-text">
                                                  <xsl:value-of select="$cmt"/>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/person_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Personenreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/person_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/place_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Ortsreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/place_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Werkreferenzen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if
                                                  test="$phr[matches(., '/textpassage/phrase_')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Phrasen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($phr[matches(., '/textpassage/phrase_')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/motif/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Motive: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/motif/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/topic/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Themen: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/topic/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  <xsl:if test="$sim[matches(., '/feature/plot/')]">
                                                  <div class="smaller-text">
                                                  <strong>Gemeinsame Stoffe: </strong>
                                                  <xsl:for-each
                                                  select="distinct-values(data($sim[matches(., '/feature/plot/')]))">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="."/>
                                                  </xsl:call-template>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>
                                                  </li>
                                                  </xsl:if>
                                                  </xsl:for-each-group>
                                                  </ul>
                                                  </div>
                                                  </details>
                                                  </li>
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

    <xsl:template name="label-of-uri">
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="exists($uri) and normalize-space($uri) != ''">
                <xsl:variable name="n" select="key('by-about', $uri, $receptionEntities)"/>

                <xsl:variable name="raw" select="
                        normalize-space((
                        $n/rdfs:label,
                        $n/@rdf:about
                        )[1])"/>

                <!-- translate and manipulate labels -->
                <xsl:variable name="t1" select="
                        replace($raw, '^\s*intertextual relation(ship)? between\s+',
                        'Intertextuelle Beziehung zwischen ', 'i')"/>
                <xsl:variable name="t2" select="replace($t1, '\s+and\s+', ' und ')"/>
                <xsl:variable name="t3" select="replace($t2, 'Expression of\s+', '', 'i')"/>
                <!-- »Fragment … Voigt« -> Fragment … Voigt -->
                <xsl:variable name="t4"
                    select="replace($t3, '»\s*(Fragment[^«»]*Voigt)\s*«', '$1', 'i')"/>
                <!-- remove e. g. Motif: -->
                <xsl:variable name="t5"
                    select="replace($t4, '^\s*(Motif|Topic|Plot|Textpassage)\s*:\s*', '', 'i')"/>
                <!-- remove e. g. (place) -->
                <xsl:variable name="t6"
                    select="replace($t5, '\s*\((place|person|work)\)\s*', '', 'i')"/>
                <xsl:value-of select="normalize-space($t6)"/>
            </xsl:when>
            <xsl:otherwise>–</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- references to persons -->

    <!-- references to places -->

    <!-- references to works -->

    <!-- text passages -->

    <!-- motifs -->

    <!-- topics -->

    <!-- plots -->

</xsl:stylesheet>
