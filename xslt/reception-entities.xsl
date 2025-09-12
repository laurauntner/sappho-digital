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
        <xsl:apply-templates select="/" mode="features"/>
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
                                                  <!--<xsl:if test="position() le 10">-->
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

                                                  <xsl:variable name="cnt"
                                                  select="count(distinct-values(($u_persons, $u_places, $u_works, $u_phrases, $u_motifs, $u_topics, $u_plots)))"/>

                                                  <xsl:variable name="cmt"
                                                  select="normalize-space(($rel/rdfs:comment[@xml:lang = 'de'], $rel/rdfs:comment)[1])"/>

                                                  <li>
                                                  <details>
                                                  <summary>
                                                  <span class="leaf"> Intertextuelle Beziehung mit
                                                  »<xsl:value-of select="@partner"/>« (<xsl:value-of
                                                  select="$cnt"/>
                                                  <xsl:value-of
                                                  select="u:sgpl($cnt, ' Gemeinsamkeit', ' Gemeinsamkeiten')"
                                                  />)</span>
                                                  </summary>

                                                  <xsl:if test="$cmt != ''">
                                                  <div class="skos-note smaller-text indent">
                                                  <xsl:value-of select="$cmt"/>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_motifs"
                                                  select="count($u_motifs)"/>
                                                  <xsl:if test="$n_motifs &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_motifs, 'Gemeinsames Motiv:', 'Gemeinsame Motive:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_motifs">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_topics"
                                                  select="count($u_topics)"/>
                                                  <xsl:if test="$n_topics &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_topics, 'Gemeinsames Thema:', 'Gemeinsame Themen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_topics">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_plots"
                                                  select="count($u_plots)"/>
                                                  <xsl:if test="$n_plots &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_plots, 'Gemeinsamer Stoff:', 'Gemeinsame Stoffe:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_plots">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_pers"
                                                  select="count($u_persons)"/>
                                                  <xsl:if test="$n_pers &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_pers, 'Gemeinsame Personenreferenz:', 'Gemeinsame Personenreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_persons">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_places"
                                                  select="count($u_places)"/>
                                                  <xsl:if test="$n_places &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_places, 'Gemeinsame Ortsreferenz:', 'Gemeinsame Ortsreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_places">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_works"
                                                  select="count($u_works)"/>
                                                  <xsl:if test="$n_works &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_works, 'Gemeinsame Werkreferenz:', 'Gemeinsame Werkreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_works">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_phr"
                                                  select="count($u_phrases)"/>
                                                  <xsl:if test="$n_phr &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_phr, 'Gemeinsame Phrase:', 'Gemeinsame Phrasen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_phrases">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  </details>
                                                  </li>
                                                  <!--</xsl:if>-->
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
                                                  <!--<xsl:if test="position() le 10">-->
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

                                                  <xsl:variable name="cnt"
                                                  select="count(distinct-values(($u_persons, $u_places, $u_works, $u_phrases, $u_motifs, $u_topics, $u_plots)))"/>

                                                  <xsl:variable name="cmt"
                                                  select="normalize-space(($rel/rdfs:comment[@xml:lang = 'de'], $rel/rdfs:comment)[1])"/>

                                                  <li>
                                                  <details>
                                                  <summary>
                                                  <span class="leaf"> Intertextuelle Beziehung mit
                                                  »<xsl:value-of select="@partner"/>« (<xsl:value-of
                                                  select="$cnt"/>
                                                  <xsl:value-of
                                                  select="u:sgpl($cnt, ' Gemeinsamkeit', ' Gemeinsamkeiten')"
                                                  />)</span>
                                                  </summary>

                                                  <xsl:if test="$cmt != ''">
                                                  <div class="skos-note smaller-text indent">
                                                  <xsl:value-of select="$cmt"/>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_motifs"
                                                  select="count($u_motifs)"/>
                                                  <xsl:if test="$n_motifs &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_motifs, 'Gemeinsames Motiv:', 'Gemeinsame Motive:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_motifs">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_topics"
                                                  select="count($u_topics)"/>
                                                  <xsl:if test="$n_topics &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_topics, 'Gemeinsames Thema:', 'Gemeinsame Themen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_topics">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_plots"
                                                  select="count($u_plots)"/>
                                                  <xsl:if test="$n_plots &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_plots, 'Gemeinsamer Stoff:', 'Gemeinsame Stoffe:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_plots">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_pers"
                                                  select="count($u_persons)"/>
                                                  <xsl:if test="$n_pers &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_pers, 'Gemeinsame Personenreferenz:', 'Gemeinsame Personenreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_persons">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_places"
                                                  select="count($u_places)"/>
                                                  <xsl:if test="$n_places &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_places, 'Gemeinsame Ortsreferenz:', 'Gemeinsame Ortsreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_places">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_works"
                                                  select="count($u_works)"/>
                                                  <xsl:if test="$n_works &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_works, 'Gemeinsame Werkreferenz:', 'Gemeinsame Werkreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_works">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_phr"
                                                  select="count($u_phrases)"/>
                                                  <xsl:if test="$n_phr &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_phr, 'Gemeinsame Phrase:', 'Gemeinsame Phrasen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_phrases">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  </details>
                                                  </li>
                                                  <!--</xsl:if>-->
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
                                                  <!--<xsl:if test="position() le 10">-->
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

                                                  <xsl:variable name="cnt"
                                                  select="count(distinct-values(($u_persons, $u_places, $u_works, $u_phrases, $u_motifs, $u_topics, $u_plots)))"/>

                                                  <xsl:variable name="cmt"
                                                  select="normalize-space(($rel/rdfs:comment[@xml:lang = 'de'], $rel/rdfs:comment)[1])"/>

                                                  <li>
                                                  <details>
                                                  <summary>
                                                  <span class="leaf"> Intertextuelle Beziehung mit
                                                  »<xsl:value-of select="@partner"/>« (<xsl:value-of
                                                  select="$cnt"/>
                                                  <xsl:value-of
                                                  select="u:sgpl($cnt, ' Gemeinsamkeit', ' Gemeinsamkeiten')"
                                                  />)</span>
                                                  </summary>

                                                  <xsl:if test="$cmt != ''">
                                                  <div class="skos-note smaller-text indent">
                                                  <xsl:value-of select="$cmt"/>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_motifs"
                                                  select="count($u_motifs)"/>
                                                  <xsl:if test="$n_motifs &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_motifs, 'Gemeinsames Motiv:', 'Gemeinsame Motive:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_motifs">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_topics"
                                                  select="count($u_topics)"/>
                                                  <xsl:if test="$n_topics &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_topics, 'Gemeinsames Thema:', 'Gemeinsame Themen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_topics">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_plots"
                                                  select="count($u_plots)"/>
                                                  <xsl:if test="$n_plots &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_plots, 'Gemeinsamer Stoff:', 'Gemeinsame Stoffe:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_plots">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_pers"
                                                  select="count($u_persons)"/>
                                                  <xsl:if test="$n_pers &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_pers, 'Gemeinsame Personenreferenz:', 'Gemeinsame Personenreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_persons">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_places"
                                                  select="count($u_places)"/>
                                                  <xsl:if test="$n_places &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_places, 'Gemeinsame Ortsreferenz:', 'Gemeinsame Ortsreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_places">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_works"
                                                  select="count($u_works)"/>
                                                  <xsl:if test="$n_works &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_works, 'Gemeinsame Werkreferenz:', 'Gemeinsame Werkreferenzen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_works">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  <xsl:variable name="n_phr"
                                                  select="count($u_phrases)"/>
                                                  <xsl:if test="$n_phr &gt; 0">
                                                  <div class="smaller-text indent">
                                                  <strong>
                                                  <xsl:value-of
                                                  select="u:sgpl($n_phr, 'Gemeinsame Phrase:', 'Gemeinsame Phrasen:')"
                                                  />
                                                  </strong>
                                                  <xsl:text> </xsl:text>
                                                  <xsl:for-each select="$u_phrases">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <xsl:value-of select="u:label(.)"/>
                                                  <xsl:if test="position() != last()">, </xsl:if>
                                                  </xsl:for-each>
                                                  </div>
                                                  </xsl:if>

                                                  </details>
                                                  </li>
                                                  <!--</xsl:if>-->
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
                <!-- remove "reference to" -->
                <xsl:variable name="t7" select="replace($t6, 'Reference to ', '', 'i')"/>
                <xsl:value-of select="normalize-space($t7)"/>
            </xsl:when>
            <xsl:otherwise>–</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- function to later sort labels alphabetically -->
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

    <!-- features -->

    <xsl:template match="/" mode="features">
        <xsl:variable name="rels" select="$receptionEntities//intro:INT31_IntertextualRelation"/>

        <xsl:variable name="u_persons"
            select="distinct-values($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/person_ref/')])"/>
        <xsl:variable name="u_places"
            select="distinct-values($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/place_ref/')])"/>
        <xsl:variable name="u_works" select="
                distinct-values(($rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/work_ref/')],
                $rels/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/actualization/work_ref/')]))"/>
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
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Personenreferenzen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="../html/vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">
                                        <xsl:for-each select="$u_persons">
                                            <xsl:sort select="lower-case(u:label(.))"/>
                                            <li>
                                                <xsl:variable name="this" select="."/>
                                                <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                <xsl:choose>
                                                  <xsl:when test="exists($occTexts)">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="label-of-uri">
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
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                </xsl:choose>
                                            </li>
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

        <!-- references to places -->
        <xsl:result-document href="../html/place-refs.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Ortsreferenzen'"/>
                    </xsl:call-template>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Ortsreferenzen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="../html/vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">
                                        <xsl:for-each select="$u_places">
                                            <xsl:sort select="lower-case(u:label(.))"/>
                                            <li>
                                                <xsl:variable name="this" select="."/>
                                                <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                <xsl:choose>
                                                  <xsl:when test="exists($occTexts)">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="label-of-uri">
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
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                </xsl:choose>
                                            </li>
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

        <!-- references to works -->
        <xsl:result-document href="../html/work-refs.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Werkreferenzen'"/>
                    </xsl:call-template>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Werkreferenzen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="../html/vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">
                                        <xsl:for-each select="$u_works">
                                            <xsl:sort select="lower-case(u:label(.))"/>
                                            <li>
                                                <xsl:variable name="this" select="."/>
                                                <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                <xsl:choose>
                                                  <xsl:when test="exists($occTexts)">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="label-of-uri">
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
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                </xsl:choose>
                                            </li>
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

        <!-- text passages -->
        <xsl:result-document href="../html/text-passages.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Phrasen'"/>
                    </xsl:call-template>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Phrasen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="../html/vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">
                                        <xsl:for-each select="$u_phrases">
                                            <xsl:sort select="lower-case(u:label(.))"/>
                                            <li>
                                                <xsl:variable name="this" select="."/>
                                                <xsl:variable name="occRels"
                                                  select="$rels[intro:R24_hasRelatedEntity/@rdf:resource = $this]"/>
                                                <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                <xsl:choose>
                                                  <xsl:when test="exists($occTexts)">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="label-of-uri">
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
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                </xsl:choose>
                                            </li>
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

        <!-- motifs -->
        <xsl:result-document href="../html/motifs.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Motive'"/>
                    </xsl:call-template>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Motive</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="../html/vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">
                                        <xsl:for-each select="$u_motifs">
                                            <xsl:sort select="lower-case(u:label(.))"/>
                                            <li>
                                                <xsl:variable name="this" select="."/>
                                                <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                <xsl:choose>
                                                  <xsl:when test="exists($occTexts)">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="label-of-uri">
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
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                </xsl:choose>
                                            </li>
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

        <!-- topics -->
        <xsl:result-document href="../html/topics.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Themen'"/>
                    </xsl:call-template>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Themen</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="../html/vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">
                                        <xsl:for-each select="$u_topics">
                                            <xsl:sort select="lower-case(u:label(.))"/>
                                            <li>
                                                <xsl:variable name="this" select="."/>
                                                <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                <xsl:choose>
                                                  <xsl:when test="exists($occTexts)">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="label-of-uri">
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
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                </xsl:choose>
                                            </li>
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

        <!-- plots -->
        <xsl:result-document href="../html/plots.html">
            <html lang="de">
                <head>
                    <xsl:call-template name="html_head">
                        <xsl:with-param name="html_title" select="'Stoffe'"/>
                    </xsl:call-template>
                </head>
                <body class="page">
                    <div class="hfeed site" id="page">
                        <xsl:call-template name="nav_bar"/>
                        <div class="container-fluid">
                            <div class="card">
                                <div class="card-header">
                                    <h1>Stoffe</h1>
                                    <p class="align-left">Für eine hierarchische Ansicht siehe das
                                            <a href="../html/vocab.html">Vokabular</a>.</p>
                                </div>
                                <div class="card-body skos-wrap">
                                    <ul class="skos-tree">
                                        <xsl:for-each select="$u_plots">
                                            <xsl:sort select="lower-case(u:label(.))"/>
                                            <li>
                                                <xsl:variable name="this" select="."/>
                                                <xsl:variable name="occRels"
                                                  select="$rels[intro:R22i_relationIsBasedOnSimilarity/@rdf:resource = $this]"/>
                                                <xsl:variable name="occTexts"
                                                  select="distinct-values(data($occRels/(intro:R13_hasReferringEntity | intro:R12_hasReferredToEntity)/@rdf:resource))"/>
                                                <xsl:choose>
                                                  <xsl:when test="exists($occTexts)">
                                                  <details>
                                                  <summary class="has-children">
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </summary>
                                                  <div class="skos-children">
                                                  <ul class="skos-tree">
                                                  <xsl:for-each select="$occTexts">
                                                  <xsl:sort select="lower-case(u:label(.))"/>
                                                  <li>
                                                  <span class="leaf indent">
                                                  <xsl:call-template name="label-of-uri">
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
                                                  <xsl:call-template name="label-of-uri">
                                                  <xsl:with-param name="uri" select="$this"/>
                                                  </xsl:call-template>
                                                  </span>
                                                  </xsl:otherwise>
                                                </xsl:choose>
                                            </li>
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
    </xsl:template>

</xsl:stylesheet>
