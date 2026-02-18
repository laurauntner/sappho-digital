<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:f="urn:func" version="2.0" exclude-result-prefixes="xsl xs rdf skos owl f">

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <!-- namespaces -->
    <xsl:variable name="nsmap" as="element(ns)*">

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'crm'"/>
            <xsl:attribute name="u" select="'http://www.cidoc-crm.org/cidoc-crm/'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'ecrm'"/>
            <xsl:attribute name="u" select="'http://erlangen-crm.org/current/'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'efrbroo'"/>
            <xsl:attribute name="u" select="'http://erlangen-crm.org/efrbroo/'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'frbroo'"/>
            <xsl:attribute name="u" select="'http://iflastandards.info/ns/fr/frbr/frbroo/'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'lrmoo'"/>
            <xsl:attribute name="u" select="'http://iflastandards.info/ns/lrm/lrmoo/'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'intro'"/>
            <xsl:attribute name="u" select="'https://w3id.org/lso/intro/currentbeta#'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'mimotext'"/>
            <xsl:attribute name="u" select="'http://data.mimotext.uni-trier.de/entity/'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'postdata-core'"/>
            <xsl:attribute name="u" select="'http://postdata.linhd.uned.es/ontology/postdata-core#'"
            />
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'postdata-poeticAnalysis'"/>
            <xsl:attribute name="u"
                select="'http://postdata.linhd.uned.es/ontology/postdata-poeticAnalysis#'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'bibo'"/>
            <xsl:attribute name="u" select="'http://purl.org/ontology/bibo/'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'cito'"/>
            <xsl:attribute name="u" select="'http://purl.org/spar/cito/'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'dcterms'"/>
            <xsl:attribute name="u" select="'http://purl.org/dc/terms/'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'doco'"/>
            <xsl:attribute name="u" select="'http://purl.org/spar/doco/'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'fabio'"/>
            <xsl:attribute name="u" select="'http://purl.org/spar/fabio/'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'foaf'"/>
            <xsl:attribute name="u" select="'http://xmlns.com/foaf/0.1/'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'dracor'"/>
            <xsl:attribute name="u" select="'http://dracor.org/ontology#'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'golem'"/>
            <xsl:attribute name="u" select="'https://ontology.golemlab.eu/'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'intertext'"/>
            <xsl:attribute name="u" select="'https://intertextuality.org/abstract#'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'intertext-artifacts'"/>
            <xsl:attribute name="u" select="'https://intertextuality.org/extensions/artifacts#'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'intertext-motifs'"/>
            <xsl:attribute name="u" select="'https://intertextuality.org/extensions/motifs#'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'intertext-text'"/>
            <xsl:attribute name="u" select="'https://intertextuality.org/extensions/text#'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'sappho'"/>
            <xsl:attribute name="u" select="'https://w3id.org/sappho-digital/ontology/'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'schema'"/>
            <xsl:attribute name="u" select="'https://schema.org/'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'urbooks'"/>
            <xsl:attribute name="u" select="'https://purl.archive.org/urbooks#'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'urwriters'"/>
            <xsl:attribute name="u" select="'https://purl.archive.org/urwriters#'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'skos'"/>
            <xsl:attribute name="u" select="'http://www.w3.org/2004/02/skos/core#'"/>
        </xsl:element>

        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'rdf'"/>
            <xsl:attribute name="u" select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'rdfs'"/>
            <xsl:attribute name="u" select="'http://www.w3.org/2000/01/rdf-schema#'"/>
        </xsl:element>
        <xsl:element name="ns" namespace="">
            <xsl:attribute name="p" select="'owl'"/>
            <xsl:attribute name="u" select="'http://www.w3.org/2002/07/owl#'"/>
        </xsl:element>

    </xsl:variable>

    <!-- qnames -->
    <xsl:function name="f:qname" as="xs:string">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:variable name="u" select="normalize-space($uri)"/>
        <xsl:variable name="candidates" select="$nsmap[starts-with($u, @u)]"/>
        <xsl:choose>
            <xsl:when test="exists($candidates)">
                <xsl:variable name="maxLen" select="max($candidates/string-length(@u))"/>
                <xsl:variable name="best" select="$candidates[string-length(@u) = $maxLen][1]"/>
                <xsl:sequence
                    select="concat($best/@p, ':', substring($u, string-length($best/@u) + 1))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$u"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="f:prefix-of" as="xs:string">
        <xsl:param name="curie-or-uri" as="xs:string"/>
        <xsl:variable name="s" select="normalize-space($curie-or-uri)"/>
        <xsl:choose>
            <xsl:when test="contains($s, ':') and not(starts-with($s, 'http'))">
                <xsl:sequence select="substring-before($s, ':')"/>
            </xsl:when>
            <xsl:when test="contains($s, '://')">
                <xsl:sequence select="substring-before(substring-after($s, '://'), '/')"/>
            </xsl:when>
            <xsl:otherwise>node</xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- colors -->
    <xsl:function name="f:color" as="xs:string">
        <xsl:param name="grp" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$grp = 'crm'">#3B82F6</xsl:when>
            <xsl:when test="$grp = 'ecrm'">#60A5FA</xsl:when>
            <xsl:when test="$grp = 'lrmoo'">#2563EB</xsl:when>
            <xsl:when test="$grp = 'frbroo'">#1D4ED8</xsl:when>
            <xsl:when test="$grp = 'efrbroo'">#93C5FD</xsl:when>
            <xsl:when test="$grp = 'intro'">#10B981</xsl:when>
            <xsl:when test="$grp = 'sappho' or $grp = 'sappho_prop'">#8B5CF6</xsl:when>
            <xsl:otherwise>#E5E7EB</xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- JSON -->
    <xsl:function name="f:jesc" as="xs:string">
        <xsl:param name="s" as="xs:string"/>
        <xsl:variable name="a" select="replace($s, '\\', '\\\\')"/>
        <xsl:variable name="b" select="replace($a, '&quot;', '\\&quot;')"/>
        <xsl:variable name="c" select="replace($b, '&#x0D;', '\\r')"/>
        <xsl:variable name="d" select="replace($c, '&#x0A;', '\\n')"/>
        <xsl:variable name="e" select="replace($d, '&#x09;', '\\t')"/>
        <xsl:sequence select="$e"/>
    </xsl:function>

    <!-- edges -->
    <xsl:variable name="edges" as="element(e)*">
        <xsl:for-each select="//*[@rdf:about]">
            <xsl:variable name="s-uri" select="string(@rdf:about)"/>
            <xsl:for-each select="
                    skos:closeMatch[@rdf:resource] |
                    skos:broadMatch[@rdf:resource] |
                    skos:narrowMatch[@rdf:resource] |
                    owl:equivalentClass[@rdf:resource] |
                    owl:equivalentProperty[@rdf:resource]
                    ">
                <xsl:variable name="o-uri" select="string(@rdf:resource)"/>
                <xsl:variable name="pred-label" select="
                        if (self::skos:closeMatch) then
                            'skos:closeMatch'
                        else
                            if (self::skos:broadMatch) then
                                'skos:broadMatch'
                            else
                                if (self::skos:narrowMatch) then
                                    'skos:narrowMatch'
                                else
                                    if (self::owl:equivalentClass) then
                                        'owl:equivalentClass'
                                    else
                                        'owl:equivalentProperty'
                        "/>

                <xsl:variable name="s" select="f:qname($s-uri)"/>
                <xsl:variable name="o" select="f:qname($o-uri)"/>

                <xsl:element name="e" namespace="">
                    <xsl:attribute name="from" select="$s"/>
                    <xsl:attribute name="to" select="$o"/>
                    <xsl:attribute name="label" select="$pred-label"/>
                </xsl:element>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:variable>

    <!-- nodes -->
    <xsl:variable name="nodes" as="xs:string*" select="distinct-values(($edges/@from, $edges/@to))"/>

    <!-- degree -->
    <xsl:function name="f:degree" as="xs:integer">
        <xsl:param name="u" as="xs:string"/>
        <xsl:sequence select="count($edges[@from = $u or @to = $u])"/>
    </xsl:function>

    <!-- html -->
    <xsl:template match="/">
        <xsl:variable name="doc_title" select="'Ontologie-Alignments'"/>

        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>

                <title>
                    <xsl:value-of select="$doc_title"/>
                </title>
                <meta charset="utf-8"/>

                <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"/>
                <script src="js/alignments.js" defer="defer"/>
            </head>

            <body class="page">
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar"/>

                    <div class="container-fluid graph-wrap">
                        <div class="card">
                            <div class="card-header">
                                <h1>
                                    <xsl:value-of select="$doc_title"/>
                                </h1>
                            </div>

                            <div class="card-body align-left">
                                <p>Verwendete Klassen und Prädikate – vor allem jene, die für die
                                    Intertextualitätsanalyse genutzt wurden – wurden mit anderen
                                    bibliographischen und literaturwissenschaftlichen Ontologien
                                    abgeglichen, darunter: die Bibliographic Ontology (<a
                                        href="http://purl.org/ontology/bibo/">BIBO</a>), die
                                    FRBR-aligned Bibliographic Ontology (<a
                                        href="http://purl.org/spar/fabio/">FaBiO</a>), die Citation
                                    Typing Ontology (<a href="http://purl.org/spar/cito/">CiTO</a>),
                                    die Drama Corpora (<a href="http://dracor.org/ontology#"
                                        >DraCor</a>) Ontology, die <a
                                        href="https://ontology.golemlab.eu/">GOLEM</a> Ontology for
                                    Narrative and Fiction, die <a
                                        href="https://data.mimotext.uni-trier.de/wiki/Main_Page"
                                        >MiMoText</a> Ontology, die OntoPoetry/POSTDATA Ontology (<a
                                        href="https://raw.githubusercontent.com/linhd-postdata/core-ontology/refs/heads/master/postdata-core.owl"
                                        >core</a>- und <a
                                        href="https://raw.githubusercontent.com/linhd-postdata/literaryAnalysis-ontology/refs/heads/master/postdata-literaryAnalysisElements.owl"
                                        >analysis</a>-Module), die <a
                                        href="https://github.com/intertextor/intertextuality-ontology"
                                        >Intertextuality Ontology</a> und die Ontologies of
                                    Under-Represented <a href="https://purl.archive.org/urwriters"
                                        >Writers</a> und <a href="https://purl.archive.org/urbooks"
                                        >Books</a>.</p>
                                <p>Weitere Alignments mit breiter gefassten Ontologien wurden ebenso
                                    durchgeführt: mit den DCMI Metadata Terms (<a
                                        href="http://purl.org/dc/terms/">DC</a>), der Document
                                    Components Ontology (<a href="http://purl.org/spar/doco/"
                                        >DoCo</a>), der Friend of a Friend (<a
                                        href="http://xmlns.com/foaf/0.1/">FOAF</a>) Ontology und <a
                                        href="https://schema.org/">Schema.org</a>. Außerdem wurden
                                        <a href="https://erlangen-crm.org/docs/ecrm/current/"
                                        >eCRM</a>, <a href="https://cidoc-crm.org/">CIDOC CRM</a>,
                                        <a href="https://erlangen-crm.org/efrbroo">eFBRoo</a>, <a
                                        href="https://www.iflastandards.info/fr/frbr/frbroo"
                                        >FRBRoo</a> und <a
                                        href="https://repository.ifla.org/handle/20.500.14598/3677"
                                        >LRMoo</a> aligniert.</p>
                                <p>Die Netzwerkdarstellung der implementierten Alignments beruht auf
                                    RDF-Daten, die <a
                                        href="https://github.com/laurauntner/sappho-digital/tree/main/documentation/alignments"
                                        >hier</a> zu finden sind. Eine tabellarische Darstellung ist
                                        <a
                                        href="https://github.com/laurauntner/wikidata-to-cidoc-crm/blob/main/docs/alignment_full.pdf"
                                        >hier</a> zu finden.</p>
                                <p>Das Netzwerk lässt sich mit der Maus (Klicken, Überfahren,
                                    Zoomen) sowie mit den Steuerelementen rechts und links unten
                                    navigieren.</p>
                                <div id="graph" class="graph-canvas"/>

                                <script id="graph-nodes" type="application/json">
                                    <xsl:text>[</xsl:text>
                                    <xsl:for-each select="$nodes">
                                        <xsl:variable name="u" select="."/>
                                        <xsl:variable name="grp" select="f:prefix-of($u)"/>
                                        <xsl:variable name="bg" select="f:color($grp)"/>
                                        <xsl:variable name="deg" select="f:degree($u)"/>
                                        
                                        <xsl:text>{</xsl:text>
                                        <xsl:text>"id":"</xsl:text><xsl:value-of select="f:jesc($u)"/><xsl:text>",</xsl:text>
                                        <xsl:text>"label":"</xsl:text><xsl:value-of select="f:jesc($u)"/><xsl:text>",</xsl:text>
                                        <xsl:text>"title":"</xsl:text><xsl:value-of select="f:jesc($u)"/><xsl:text>",</xsl:text>
                                        <xsl:text>"value":</xsl:text><xsl:value-of select="$deg"/><xsl:text>,</xsl:text>
                                        <xsl:text>"color":{</xsl:text>
                                        <xsl:text>"background":"</xsl:text><xsl:value-of select="$bg"/><xsl:text>",</xsl:text>
                                        <xsl:text>"border":"#9CA3AF",</xsl:text>
                                        <xsl:text>"highlight":{"background":"</xsl:text><xsl:value-of select="$bg"/><xsl:text>","border":"#9CA3AF"},</xsl:text>
                                        <xsl:text>"hover":{"background":"</xsl:text><xsl:value-of select="$bg"/><xsl:text>","border":"#9CA3AF"}</xsl:text>
                                        <xsl:text>}</xsl:text>
                                        <xsl:text>}</xsl:text>
                                        
                                        <xsl:if test="position() != last()">
                                            <xsl:text>,</xsl:text>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <xsl:text>]</xsl:text>
                                </script>
                                <script id="graph-edges" type="application/json">
                                    <xsl:text>[</xsl:text>
                                    <xsl:for-each select="$edges">
                                        <xsl:text>{</xsl:text>
                                        <xsl:text>"from":"</xsl:text><xsl:value-of select="f:jesc(string(@from))"/><xsl:text>",</xsl:text>
                                        <xsl:text>"to":"</xsl:text><xsl:value-of select="f:jesc(string(@to))"/><xsl:text>",</xsl:text>
                                        <xsl:text>"label":"</xsl:text><xsl:value-of select="f:jesc(string(@label))"/><xsl:text>",</xsl:text>
                                        <xsl:text>"title":"</xsl:text><xsl:value-of select="f:jesc(string(@label))"/><xsl:text>",</xsl:text>
                                        <xsl:text>"arrows":"to"</xsl:text>
                                        <xsl:text>}</xsl:text>
                                        
                                        <xsl:if test="position() != last()">
                                            <xsl:text>,</xsl:text>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <xsl:text>]</xsl:text>
                                </script>
                            </div>
                        </div>
                    </div>

                    <xsl:call-template name="html_footer"/>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
