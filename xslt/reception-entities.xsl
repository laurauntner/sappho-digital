<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#" exclude-result-prefixes="xs" version="2.0">

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:variable name="receptionEntities" select="doc('../data/rdf/sappho-reception.rdf')"/>
    <xsl:variable name="vocab" select="doc('../data/rdf/vocab.rdf')"/>

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
                                    <!-- Hierarchische, ausklappbare Liste -->
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
    </xsl:template>

    <xsl:template name="label">
        <xsl:param name="n"/>
        <xsl:variable name="rawLabel"
            select="($n/skos:prefLabel[@xml:lang='de'],
            $n/skos:prefLabel[@xml:lang='en'],
            $n/skos:prefLabel,
            $n/rdfs:label,
            $n/@rdf:about)[1]"/>
        <!-- alles in Klammern (inkl. der Klammern und evtl. folgendem Leerzeichen) entfernen -->
        <xsl:value-of select="normalize-space(replace($rawLabel, '\s*\([^)]*\)', ''))"/>
    </xsl:template>

    <xsl:template name="render-concept">
        <xsl:param name="node" as="element()"/>
        <xsl:param name="open" as="xs:boolean" select="false()"/>

        <xsl:variable name="narrowerUris" select="$node/skos:narrower/@rdf:resource"/>
        <xsl:variable name="children" select="$node/ancestor::rdf:RDF/*[@rdf:about = $narrowerUris]"/>

        <li>
            <xsl:choose>
                <!-- Hat Kinder: nutze <details>/<summary> -->
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

                        <!-- Definition/ScopeNote -->
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

                            <!-- Kinder -->
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

                <!-- Keine Kinder: nur Text -->
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

    <!-- intertextual relationships (with page numbers) -->

    <!-- references to persons -->

    <!-- references to places -->

    <!-- references to works -->

    <!-- text passages -->

    <!-- motifs -->

    <!-- topics -->

    <!-- plots -->

</xsl:stylesheet>
