<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:ecrm="http://erlangen-crm.org/current/" xmlns:lrmoo="http://www.cidoc-crm.org/lrmoo/"
    xmlns:intro="https://w3id.org/lso/intro/currentbeta#" xmlns:local="xyz"
    exclude-result-prefixes="xs rdf rdfs owl ecrm lrmoo intro local">

    <!-- partials -->
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <!-- paths -->
    <xsl:variable name="works" select="doc('../data/rdf/fragments.rdf')"/>
    <xsl:variable name="receptionEntities" select="doc('../data/rdf/sappho-reception.rdf')"/>

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes"/>

    <xsl:key name="by-about" match="*[@rdf:about]" use="@rdf:about"/>

    <!-- helper for labels -->
    <xsl:function name="local:get-label" as="xs:string">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="entity" select="key('by-about', $uri, $receptionEntities)"/>
        <xsl:variable name="raw"
            select="normalize-space(($entity/rdfs:label, $entity/@rdf:about)[1])"/>
        <xsl:variable name="t1"
            select="replace($raw, '^\s*intertextual relation(ship)? between\s+', 'Intertextuelle Beziehung zwischen ', 'i')"/>
        <xsl:variable name="t2" select="replace($t1, '\s+and\s+', ' und ')"/>
        <xsl:variable name="t3" select="replace($t2, 'Expression of\s+', '', 'i')"/>
        <xsl:variable name="t4" select="replace($t3, '»\s*(Fragment[^«»]*Voigt)\s*«', '$1', 'i')"/>
        <xsl:variable name="t5"
            select="replace($t4, '^\s*(Motif|Topic|Plot|Textpassage|Character)\s*:\s*', '', 'i')"/>
        <xsl:variable name="t6"
            select="replace($t5, '\s*\((place|person|work|character)\)\s*', '', 'i')"/>
        <xsl:variable name="t7" select="replace($t6, 'Reference to ', '', 'i')"/>
        <xsl:sequence select="normalize-space($t7)"/>
    </xsl:function>

    <!-- helper for features -->
    <xsl:function name="local:get-connected-features" as="element()*">
        <xsl:param name="work-id" as="xs:string"/>
        <xsl:param name="feature-type" as="xs:string"/>

        <xsl:variable name="work-uri"
            select="concat('https://sappho-digital.com/expression/', $work-id)"/>

        <xsl:variable name="relations" select="
                $receptionEntities//intro:INT31_IntertextualRelation[
                intro:R13_hasReferringEntity/@rdf:resource = $work-uri or
                intro:R12_hasReferredToEntity/@rdf:resource = $work-uri
                ]"/>

        <xsl:variable name="feature-uris" select="
                if ($feature-type = 'motif') then
                    distinct-values($relations/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/motif/')])
                else
                    if ($feature-type = 'topic') then
                        distinct-values($relations/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/topic/')])
                    else
                        if ($feature-type = 'plot') then
                            distinct-values($relations/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/plot/')])
                        else
                            if ($feature-type = 'person') then
                                distinct-values(
                                $relations/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[
                                matches(., '/feature/person_ref/') or matches(., '/feature/character/')
                                ]
                                )
                            else
                                if ($feature-type = 'place') then
                                    distinct-values($relations/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/place_ref/')])
                                else
                                    if ($feature-type = 'work') then
                                        distinct-values($relations/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')])
                                    else
                                        if ($feature-type = 'workpassage') then
                                            distinct-values(
                                            $relations/intro:R24_hasRelatedEntity/@rdf:resource[
                                            matches(., '/textpassage/') and not(matches(., '/textpassage/phrase_'))
                                            ]
                                            )
                                        else
                                            if ($feature-type = 'phrase') then
                                                distinct-values($relations/intro:R24_hasRelatedEntity/@rdf:resource[matches(., '/textpassage/phrase_')])
                                            else
                                                ()
                "/>

        <xsl:for-each select="$feature-uris">
            <feature xmlns="" uri="{.}" label="{local:get-label(.)}"/>
        </xsl:for-each>
    </xsl:function>

    <!-- helper for titles -->
    <xsl:function name="local:get-work-label" as="xs:string">
        <xsl:param name="expr-uri" as="xs:string"/>
        <xsl:variable name="id" select="tokenize($expr-uri, '/')[last()]"/>
        <xsl:variable name="ts-uri"
            select="concat('https://sappho-digital.com/title_string/expression/', $id)"/>
        <xsl:variable name="label" select="
                string((
                key('by-about', $ts-uri, $works)/rdfs:label[@xml:lang = 'de'],
                key('by-about', $ts-uri, $works)/rdfs:label,
                key('by-about', $expr-uri, $works)//rdfs:label[@xml:lang = 'de'],
                key('by-about', $expr-uri, $works)//rdfs:label,
                key('by-about', $ts-uri, $receptionEntities)/rdfs:label[@xml:lang = 'de'],
                key('by-about', $ts-uri, $receptionEntities)/rdfs:label,
                key('by-about', $expr-uri, $receptionEntities)//rdfs:label[@xml:lang = 'de'],
                key('by-about', $expr-uri, $receptionEntities)//rdfs:label,
                $expr-uri
                )[1])
                "/>
        <xsl:sequence select="normalize-space($label)"/>
    </xsl:function>

    <!-- helper for ids -->
    <xsl:function name="local:iri-id" as="xs:string">
        <xsl:param name="iri" as="xs:string?"/>
        <xsl:variable name="s" select="string($iri)"/>
        <xsl:variable name="base" select="substring-before(concat($s, '#'), '#')"/>
        <xsl:sequence select="string(tokenize($base, '/')[last()])"/>
    </xsl:function>

    <!-- intertexts -->
    <xsl:template name="render-connected-features">
        <xsl:param name="work-id" as="xs:string"/>

        <xsl:variable name="motifs" select="local:get-connected-features($work-id, 'motif')"/>
        <xsl:variable name="topics" select="local:get-connected-features($work-id, 'topic')"/>
        <xsl:variable name="plots" select="local:get-connected-features($work-id, 'plot')"/>
        <xsl:variable name="personsRaw" select="local:get-connected-features($work-id, 'person')"/>
        
        <xsl:variable name="persons" as="element(feature)*">
            <xsl:for-each-group select="$personsRaw" group-by="local:norm-label(@label)">
                <xsl:sort select="current-grouping-key()"/>
                <xsl:sequence select="
                    ( current-group()[matches(@uri, '/feature/person_ref/')],
                    current-group()[1]
                    )[1]
                    "/>
            </xsl:for-each-group>
        </xsl:variable>
        
        <xsl:variable name="places" select="local:get-connected-features($work-id, 'place')"/>
        <xsl:variable name="workrefs" select="local:get-connected-features($work-id, 'work')"/>
        <xsl:variable name="workpassages" select="local:get-connected-features($work-id, 'workpassage')"/>
        <xsl:variable name="phrases" select="local:get-connected-features($work-id, 'phrase')"/>

        <xsl:variable name="this-expr-uri"
            select="concat('https://sappho-digital.com/expression/', $work-id)"/>

        <xsl:variable name="int31" select="
                $receptionEntities//intro:INT31_IntertextualRelation[
                local:iri-id(string(intro:R13_hasReferringEntity/@rdf:resource)) = $work-id or
                local:iri-id(string(intro:R12_hasReferredToEntity/@rdf:resource)) = $work-id
                ]"/>

        <xsl:variable name="targets" as="xs:string*" select="
                for $rel in $int31
                return
                    if (local:iri-id(string($rel/intro:R13_hasReferringEntity/@rdf:resource)) = $work-id)
                    then
                        string($rel/intro:R12_hasReferredToEntity/@rdf:resource)
                    else
                        if (local:iri-id(string($rel/intro:R12_hasReferredToEntity/@rdf:resource)) = $work-id)
                        then
                            string($rel/intro:R13_hasReferringEntity/@rdf:resource)
                        else
                            ()
                "/>

        <xsl:variable name="intertexts" as="xs:string*" select="distinct-values($targets)"/>

        <xsl:if
            test="exists(($motifs, $topics, $plots, $persons, $places, $workrefs, $phrases, $intertexts))">
            <h5 class="align-left">Ergebnisse der exemplarischen <a href="analyse.html"
                >Analyse</a>:</h5>
        </xsl:if>

        <xsl:if test="exists($motifs)">
            <p class="align-left">Motive: <xsl:for-each select="$motifs">
                    <xsl:sort select="lower-case(@label)"/>
                    <xsl:value-of select="@label"/><xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="exists($topics)">
            <p class="align-left">Themen: <xsl:for-each select="$topics">
                    <xsl:sort select="lower-case(@label)"/>
                    <xsl:value-of select="@label"/><xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="exists($plots)">
            <p class="align-left">Stoffe: <xsl:for-each select="$plots">
                    <xsl:sort select="lower-case(@label)"/>
                    <xsl:value-of select="@label"/><xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="exists($persons)">
            <p class="align-left">Personenreferenzen und Figuren: <xsl:for-each select="$persons">
                    <xsl:sort select="lower-case(@label)"/>
                    <xsl:value-of select="@label"/><xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="exists($places)">
            <p class="align-left">Ortsreferenzen: <xsl:for-each select="$places">
                    <xsl:sort select="lower-case(@label)"/>
                    <xsl:value-of select="@label"/><xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="exists($workrefs)">
            <p class="align-left">Werkreferenzen und Zitate: <xsl:for-each select="$workrefs">
                    <xsl:sort select="lower-case(@label)"/>
                    <xsl:value-of select="normalize-space(@label)"/><xsl:if
                        test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>
        
        <xsl:if test="exists($workpassages)">
            <p class="align-left">Zitate: 
                <xsl:for-each select="$workpassages">
                    <xsl:sort select="lower-case(@label)"/>
                    <xsl:value-of select="@label"/>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>
        
        <xsl:if test="exists($phrases)">
            <p class="align-left">Phrasen: <xsl:for-each select="$phrases">
                    <xsl:sort select="lower-case(@label)"/>
                    <xsl:value-of select="@label"/><xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>

        <xsl:if test="exists($intertexts)">
            <p class="align-left">Intertextuelle Beziehungen mit: <xsl:for-each select="$intertexts">
                    <xsl:sort select="lower-case(local:get-work-label(.))"/>
                    <a href="{local:iri-id(.)}.html"><xsl:value-of select="local:get-work-label(.)"
                        /></a>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>
    </xsl:template>

    <!-- subsites -->
    <xsl:template match="/">
        <xsl:for-each select="$works//lrmoo:F2_Expression">
            <xsl:variable name="expr" select="."/>
            <xsl:variable name="expr-uri" select="string(@rdf:about)"/>
            <xsl:variable name="id" select="local:iri-id($expr-uri)"/>
            <xsl:variable name="label" select="local:get-work-label($expr-uri)"/>

            <!-- Wikidata -->
            <xsl:variable name="wd"
                select="string(($expr/owl:sameAs[@rdf:resource[contains(., 'wikidata.org')]]/@rdf:resource)[1])"/>

            <xsl:result-document href="../html/{$id}.html">
                <html>
                    <head>
                        <xsl:call-template name="html_head">
                            <xsl:with-param name="html_title" select="$label"/>
                        </xsl:call-template>
                    </head>
                    <body class="page">
                        <xsl:if test="$wd">
                            <xsl:attribute name="data-wikidata">
                                <xsl:value-of select="substring-after($wd, 'entity/')"/>
                            </xsl:attribute>
                        </xsl:if>

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
                                        <div class="wikidata-left">
                                            <p class="align-left">Interne ID: <xsl:value-of
                                                  select="$id"/></p>

                                            <xsl:if test="$wd">
                                                <p class="align-left">Wikidata: <a href="{$wd}"
                                                  target="_blank" rel="noopener"><xsl:value-of
                                                  select="$wd"/></a>
                                                </p>
                                            </xsl:if>

                                            <p class="align-left">Typ: Werk</p>

                                            <p class="align-left">Autorin: Sappho</p>

                                            <!-- analysis -->
                                            <xsl:call-template name="render-connected-features">
                                                <xsl:with-param name="work-id" select="$id"/>
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
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="local:norm-label" as="xs:string">
        <xsl:param name="s" as="xs:string?"/>
        <xsl:variable name="t0" select="normalize-space(string($s))"/>
        <xsl:variable name="t1" select="lower-case(normalize-unicode($t0, 'NFKC'))"/>
        <xsl:sequence select="replace($t1, '\s+', ' ')"/>
    </xsl:function>

</xsl:stylesheet>
