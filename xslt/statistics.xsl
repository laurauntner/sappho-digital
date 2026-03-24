<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ecrm="http://erlangen-crm.org/current/"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:owl="http://www.w3.org/2002/07/owl#"
  xmlns:intro="https://w3id.org/lso/intro/currentbeta#"
  xmlns:lrmoo="http://iflastandards.info/ns/lrm/lrmoo/" xmlns:local="xyz" version="2.0"
  exclude-result-prefixes="xsl xs ecrm rdf rdfs owl intro lrmoo local">

  <xsl:output encoding="UTF-8" media-type="text/html" method="xhtml" version="1.0" indent="yes"
    omit-xml-declaration="yes"/>

  <xsl:import href="./partials/html_navbar.xsl"/>
  <xsl:import href="./partials/html_head.xsl"/>
  <xsl:import href="./partials/html_footer.xsl"/>

  <!-- helper function for labels – mirrors bibl-entities.xsl -->
  <xsl:variable name="works" select="doc('../data/rdf/works.rdf')"/>
  <xsl:variable name="receptionEntities" select="doc('../data/rdf/sappho-reception.rdf')"/>

  <xsl:key name="by-about" match="*[@rdf:about]" use="@rdf:about"/>

  <xsl:function name="local:get-label" as="xs:string">
    <xsl:param name="uri" as="xs:string"/>
    <xsl:variable name="entity" select="key('by-about', $uri, $receptionEntities)"/>
    <xsl:variable name="raw" select="normalize-space(($entity/rdfs:label, $entity/@rdf:about)[1])"/>
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

  <!-- Jahrzehnt-Hilfsfunktion für ALK (Top-Level, XSLT-2.0-kompatibel) -->
  <xsl:function name="local:alk-decade-key" as="xs:string">
    <xsl:param name="expr-id" as="xs:string"/>
    <xsl:variable name="uri" select="concat('https://sappho-digital.com/expression/', $expr-id)"/>
    <xsl:variable name="yr" select="
        string(($works//*[@rdf:about = $uri]//ecrm:P82a_begin_of_the_begin,
        $works//*[@rdf:about = $uri]//rdfs:label[@xml:lang = 'de'])[1])"/>
    <xsl:variable name="y4" select="
        if (matches($yr, '^\d{4}')) then
          xs:integer(substring($yr, 1, 4))
        else
          0"/>
    <xsl:sequence select="
        if ($y4 gt 0) then
          string(($y4 idiv 10) * 10)
        else
          'unbekannt'"/>
  </xsl:function>

  <xsl:template match="/">

    <xsl:variable name="doc_title">Statistik</xsl:variable>

    <xsl:variable name="cat-json-items" as="xs:string*">
      <xsl:for-each select="statistics/category">
        <xsl:variable name="items-json" as="xs:string*">
          <xsl:for-each select="item">
            <xsl:sequence select="
                concat(
                '{',
                '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
                '&quot;countSappho&quot;:', @countSappho, ',',
                '&quot;countReception&quot;:', @countReception, ',',
                '&quot;pctSappho&quot;:', @pctSappho, ',',
                '&quot;pctReception&quot;:', @pctReception,
                '}'
                )"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="
            concat(
            '{',
            '&quot;key&quot;:&quot;', replace(replace(@key, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;n&quot;:', @n, ',',
            '&quot;items&quot;:[', string-join($items-json, ','), ']',
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="frag-json-items" as="xs:string*">
      <xsl:for-each select="statistics/fragments/fragment">
        <xsl:variable name="ftype-json-items" as="xs:string*">
          <xsl:for-each select="featureType">
            <xsl:variable name="feat-json-items" as="xs:string*">
              <xsl:for-each select="item">
                <xsl:sequence select="
                    concat(
                    '{',
                    '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
                    '&quot;uri&quot;:&quot;', replace(replace(@uri, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
                    '&quot;count&quot;:', @count,
                    '}'
                    )"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="
                concat(
                '{',
                '&quot;key&quot;:&quot;', @key, '&quot;,',
                '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
                '&quot;total&quot;:', @total, ',',
                '&quot;items&quot;:[', string-join($feat-json-items, ','), ']',
                '}'
                )"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="sf-json-items" as="xs:string*">
          <xsl:for-each select="sapphoFeatures/featureType">
            <xsl:variable name="sf-feat-items" as="xs:string*">
              <xsl:for-each select="item">
                <xsl:sequence select="
                    concat(
                    '{',
                    '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
                    '&quot;uri&quot;:&quot;', replace(replace(@uri, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;',
                    '}'
                    )"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="
                concat(
                '{',
                '&quot;key&quot;:&quot;', @key, '&quot;,',
                '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
                '&quot;items&quot;:[', string-join($sf-feat-items, ','), ']',
                '}'
                )"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="
            concat(
            '{',
            '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;nBibl&quot;:', @nBibl, ',',
            '&quot;sapphoFeatures&quot;:[', string-join($sf-json-items, ','), '],',
            '&quot;featureTypes&quot;:[', string-join($ftype-json-items, ','), ']',
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="gdist-genre-json" as="xs:string*">
      <xsl:for-each select="statistics/genreDist/meta/genre">
        <xsl:sequence
          select="concat('{&quot;key&quot;:&quot;', replace(@key, '&quot;', '\\&quot;'), '&quot;,&quot;n&quot;:', @n, '}')"
        />
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="gdist-feat-json" as="xs:string*">
      <xsl:for-each select="statistics/genreDist/features/feature">
        <xsl:variable name="gcells-json" as="xs:string*">
          <xsl:for-each select="genreCell">
            <xsl:sequence
              select="concat('{&quot;g&quot;:&quot;', replace(@genre, '&quot;', '\\&quot;'), '&quot;,&quot;n&quot;:', @n, '}')"
            />
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="
            concat(
            '{',
            '&quot;uri&quot;:&quot;', replace(@uri, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;label&quot;:&quot;', replace(@label, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;ftype&quot;:&quot;', @ftype, '&quot;,',
            '&quot;total&quot;:', @total, ',',
            '&quot;cells&quot;:[', string-join($gcells-json, ','), ']',
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="pdist-decade-json" as="xs:string*">
      <xsl:for-each select="statistics/phenomenaDist/meta/decade">
        <xsl:sequence select="concat('&quot;', @key, '&quot;')"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="pdist-genre-json" as="xs:string*">
      <xsl:for-each select="statistics/phenomenaDist/meta/genre">
        <xsl:sequence select="concat('&quot;', replace(@key, '&quot;', '\\&quot;'), '&quot;')"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="pdist-feat-json" as="xs:string*">
      <xsl:for-each select="statistics/phenomenaDist/features/feature">
        <xsl:variable name="cells-json" as="xs:string*">
          <xsl:for-each select="cell">
            <xsl:sequence
              select="concat('{&quot;d&quot;:&quot;', @decade, '&quot;,&quot;n&quot;:', @n, '}')"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="
            concat(
            '{',
            '&quot;uri&quot;:&quot;', replace(@uri, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;label&quot;:&quot;', replace(@label, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;ftype&quot;:&quot;', @ftype, '&quot;,',
            '&quot;total&quot;:', @total, ',',
            '&quot;cells&quot;:[', string-join($cells-json, ','), ']',
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="plotcomp-plot-json" as="xs:string*">
      <xsl:for-each select="statistics/plotComponents/plot">
        <xsl:variable name="cofeat-json" as="xs:string*">
          <xsl:for-each select="coFeature">
            <xsl:sequence select="
                concat(
                '{',
                '&quot;uri&quot;:&quot;', replace(@uri, '&quot;', '\\&quot;'), '&quot;,',
                '&quot;label&quot;:&quot;', replace(@label, '&quot;', '\\&quot;'), '&quot;,',
                '&quot;ftype&quot;:&quot;', @ftype, '&quot;,',
                '&quot;n&quot;:', @n,
                '}'
                )"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="
            concat(
            '{',
            '&quot;uri&quot;:&quot;', replace(@uri, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;label&quot;:&quot;', replace(@label, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;nDocs&quot;:', @nDocs, ',',
            '&quot;coFeatures&quot;:[', string-join($cofeat-json, ','), ']',
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="personduality-json" as="xs:string*">
      <xsl:for-each select="statistics/personDuality/person">
        <xsl:sequence select="
            concat(
            '{',
            '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;persRefN&quot;:', @persRefN, ',',
            '&quot;charN&quot;:', @charN, ',',
            '&quot;sapPrN&quot;:', @sapPrN, ',',
            '&quot;sapChN&quot;:', @sapChN, ',',
            '&quot;pctRecPr&quot;:', @pctRecPr, ',',
            '&quot;pctRecCh&quot;:', @pctRecCh, ',',
            '&quot;pctSapPr&quot;:', @pctSapPr, ',',
            '&quot;pctSapCh&quot;:', @pctSapCh,
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="int31-feat-freq-json" as="xs:string*">
      <xsl:for-each select="statistics/int31CoOccurrence/featFrequencies/feat">
        <xsl:sequence select="
            concat(
            '{',
            '&quot;uri&quot;:&quot;', replace(@uri, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;ftype&quot;:&quot;', @ftype, '&quot;,',
            '&quot;n&quot;:', @n,
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="int31-pair-json" as="xs:string*">
      <xsl:for-each select="statistics/int31CoOccurrence/featPairs/featPair">
        <xsl:sequence select="
            concat(
            '{',
            '&quot;uriA&quot;:&quot;', replace(@uriA, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;labelA&quot;:&quot;', replace(replace(@labelA, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;ftypeA&quot;:&quot;', @ftypeA, '&quot;,',
            '&quot;uriB&quot;:&quot;', replace(@uriB, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;labelB&quot;:&quot;', replace(replace(@labelB, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;ftypeB&quot;:&quot;', @ftypeB, '&quot;,',
            '&quot;n&quot;:', @n,
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="wc-works-json" as="xs:string*">
      <xsl:for-each select="statistics/workCitation/work">
        <xsl:sequence select="
            concat(
            '{',
            '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;uri&quot;:&quot;', replace(replace(@uri, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;refN&quot;:', @refN, ',',
            '&quot;citeN&quot;:', @citeN, ',',
            '&quot;bothN&quot;:', @bothN, ',',
            '&quot;pctRef&quot;:', @pctRef, ',',
            '&quot;pctCite&quot;:', @pctCite, ',',
            '&quot;pctBoth&quot;:', @pctBoth,
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="int31-topnodes-json" as="xs:string*">
      <xsl:for-each select="statistics/int31TopNodes/node">
        <xsl:variable name="texts-json" as="xs:string*">
          <xsl:for-each select="connectedTexts/text">
            <xsl:sequence select="
                concat(
                '{',
                '&quot;uri&quot;:&quot;', replace(@uri, '&quot;', '\\&quot;'), '&quot;,',
                '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
                '&quot;pageUrl&quot;:&quot;', replace(@pageUrl, '&quot;', '\\&quot;'), '&quot;,',
                '&quot;isSappho&quot;:', if (@isSappho = 'true') then
                  'true'
                else
                  'false',
                '}'
                )"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="basis-json" as="xs:string*">
          <xsl:for-each select="basisFeatures/feat">
            <xsl:sequence select="
                concat(
                '{',
                '&quot;uri&quot;:&quot;', replace(@uri, '&quot;', '\\&quot;'), '&quot;,',
                '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
                '&quot;ftype&quot;:&quot;', @ftype, '&quot;',
                '}'
                )"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="
            concat(
            '{',
            '&quot;uri&quot;:&quot;', replace(@uri, '&quot;', '\\&quot;'), '&quot;,',
            '&quot;cardLabel&quot;:&quot;', replace(replace(@cardLabel, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
            '&quot;nFeats&quot;:', @nFeats, ',',
            '&quot;relType&quot;:&quot;', @relType, '&quot;,',
            '&quot;texts&quot;:[', string-join($texts-json, ','), '],',
            '&quot;basis&quot;:[', string-join($basis-json, ','), ']',
            '}'
            )"/>
      </xsl:for-each>
    </xsl:variable>


    <xsl:variable name="stat10-int31hist-json" as="xs:string*">
      <xsl:for-each select="statistics/stat10AvgRelations/int31Hist/bucket">
        <xsl:sequence
          select="concat('{&quot;label&quot;:&quot;', @label, '&quot;,&quot;sappho&quot;:', @sappho, ',&quot;reception&quot;:', @reception, '}')"
        />
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="stat10-sharedhist-json" as="xs:string*">
      <xsl:for-each select="statistics/stat10AvgRelations/sharedHist/bucket">
        <xsl:sequence
          select="concat('{&quot;label&quot;:&quot;', @label, '&quot;,&quot;sappho&quot;:', @sappho, ',&quot;reception&quot;:', @reception, '}')"
        />
      </xsl:for-each>
    </xsl:variable>


    <!-- ══════════════════════════════════════════════════════════════════
         Statistik 11: Anna Louisa Karsch – Variablen
         ══════════════════════════════════════════════════════════════ -->
    <xsl:variable name="alk-authors" select="doc('../data/rdf/authors.rdf')"/>
    <xsl:variable name="alk-person-uri" select="'https://sappho-digital.com/person/author_7240c9e7'"/>

    <!-- Bild-URL aus E36_Visual_Item -->
    <xsl:variable name="alk-img-url" as="xs:string" select="
        string((
        $alk-authors//ecrm:E36_Visual_Item[
        ecrm:P138_represents/@rdf:resource = $alk-person-uri
        ][1]/rdfs:seeAlso/@rdf:resource,
        $alk-authors//ecrm:E36_Visual_Item[
        ecrm:P138_represents/@rdf:resource = $alk-person-uri
        ][1]/rdfs:seeAlso/text()
        )[1])"/>

    <!-- ALK expression-IDs via lrmoo:F28_Expression_Creation -->
    <!-- Schritt 1: alle expression_creation-URIs die die Person ausgeführt hat -->
    <xsl:variable name="alk-expr-creation-uris" as="xs:string*">
      <xsl:for-each select="
          $alk-authors//ecrm:E21_Person[@rdf:about = $alk-person-uri]
          /ecrm:P14i_performed/@rdf:resource[contains(., '/expression_creation/')]">
        <xsl:sequence select="string(.)"/>
      </xsl:for-each>
    </xsl:variable>
    <!-- Schritt 2: aus works.rdf die F28-Knoten auflösen → expression-IDs -->
    <xsl:variable name="alk-expr-ids" as="xs:string*">
      <xsl:for-each select="$alk-expr-creation-uris">
        <xsl:variable name="ec-uri" select="."/>
        <xsl:variable name="expr-uri" select="
            string((
            $works//lrmoo:F28_Expression_Creation[@rdf:about = $ec-uri]/lrmoo:R17_created/@rdf:resource,
            $receptionEntities//lrmoo:F28_Expression_Creation[@rdf:about = $ec-uri]/lrmoo:R17_created/@rdf:resource
            )[1])"/>
        <xsl:if test="$expr-uri != ''">
          <xsl:sequence select="tokenize($expr-uri, '/')[last()]"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="alk-n-works" select="count($alk-expr-ids)"/>

    <!-- Werke pro Jahrzehnt -->
    <xsl:variable name="alk-decade-json" as="xs:string*">
      <xsl:for-each-group select="$alk-expr-ids" group-by="local:alk-decade-key(.)">
        <xsl:sort select="current-grouping-key()"/>
        <xsl:sequence select="
            concat(
            '{&quot;decade&quot;:&quot;', current-grouping-key(), '&quot;,',
            '&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <!-- Themen für alle ALK-Texte -->
    <xsl:variable name="alk-topics-raw" as="xs:string*">
      <xsl:for-each select="$alk-expr-ids">
        <xsl:variable name="expr-uri" select="concat('https://sappho-digital.com/expression/', .)"/>
        <xsl:for-each select="
            $receptionEntities//intro:INT31_IntertextualRelation[
            intro:R13_hasReferringEntity/@rdf:resource = $expr-uri or
            intro:R12_hasReferredToEntity/@rdf:resource = $expr-uri
            ]/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[
            matches(., '/feature/topic/')
            ]">
          <xsl:sequence select="string(.)"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>

    <!-- Motive für alle ALK-Texte -->
    <xsl:variable name="alk-motifs-raw" as="xs:string*">
      <xsl:for-each select="$alk-expr-ids">
        <xsl:variable name="expr-uri" select="concat('https://sappho-digital.com/expression/', .)"/>
        <xsl:for-each select="
            $receptionEntities//intro:INT31_IntertextualRelation[
            intro:R13_hasReferringEntity/@rdf:resource = $expr-uri or
            intro:R12_hasReferredToEntity/@rdf:resource = $expr-uri
            ]/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[
            matches(., '/feature/motif/')
            ]">
          <xsl:sequence select="string(.)"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>

    <!-- Stoffe für alle ALK-Texte -->
    <xsl:variable name="alk-plots-raw" as="xs:string*">
      <xsl:for-each select="$alk-expr-ids">
        <xsl:variable name="expr-uri" select="concat('https://sappho-digital.com/expression/', .)"/>
        <xsl:for-each select="
            $receptionEntities//intro:INT31_IntertextualRelation[
            intro:R13_hasReferringEntity/@rdf:resource = $expr-uri or
            intro:R12_hasReferredToEntity/@rdf:resource = $expr-uri
            ]/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[
            matches(., '/feature/plot/')
            ]">
          <xsl:sequence select="string(.)"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>

    <!-- Aggregierte Themen: distinct URI → Label + Häufigkeit -->
    <xsl:variable name="alk-topics-json" as="xs:string*">
      <xsl:for-each-group select="$alk-topics-raw" group-by=".">
        <xsl:sort select="count(current-group())" order="descending"/>
        <xsl:sequence select="
            concat(
            '{&quot;label&quot;:&quot;',
            replace(local:get-label(current-grouping-key()), '&quot;', ''),
            '&quot;,&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <!-- Aggregierte Motive -->
    <xsl:variable name="alk-motifs-json" as="xs:string*">
      <xsl:for-each-group select="$alk-motifs-raw" group-by=".">
        <xsl:sort select="count(current-group())" order="descending"/>
        <xsl:sequence select="
            concat(
            '{&quot;label&quot;:&quot;',
            replace(local:get-label(current-grouping-key()), '&quot;', ''),
            '&quot;,&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <!-- Aggregierte Stoffe -->
    <xsl:variable name="alk-plots-json" as="xs:string*">
      <xsl:for-each-group select="$alk-plots-raw" group-by=".">
        <xsl:sort select="count(current-group())" order="descending"/>
        <xsl:sequence select="
            concat(
            '{&quot;label&quot;:&quot;',
            replace(local:get-label(current-grouping-key()), '&quot;', ''),
            '&quot;,&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <!-- Personenreferenzen -->
    <xsl:variable name="alk-persons-raw" as="xs:string*">
      <xsl:for-each select="$alk-expr-ids">
        <xsl:variable name="expr-uri" select="concat('https://sappho-digital.com/expression/', .)"/>
        <xsl:for-each select="
            $receptionEntities//intro:INT31_IntertextualRelation[
            intro:R13_hasReferringEntity/@rdf:resource = $expr-uri or
            intro:R12_hasReferredToEntity/@rdf:resource = $expr-uri
            ]/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[
            matches(., '/feature/person_ref/') or matches(., '/feature/character/')
            ]">
          <xsl:sequence select="string(.)"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="alk-persons-json" as="xs:string*">
      <xsl:for-each-group select="$alk-persons-raw" group-by=".">
        <xsl:sort select="count(current-group())" order="descending"/>
        <xsl:sequence select="
            concat(
            '{&quot;label&quot;:&quot;',
            replace(local:get-label(current-grouping-key()), '&quot;', ''),
            '&quot;,&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <!-- Ortsreferenzen -->
    <xsl:variable name="alk-places-raw" as="xs:string*">
      <xsl:for-each select="$alk-expr-ids">
        <xsl:variable name="expr-uri" select="concat('https://sappho-digital.com/expression/', .)"/>
        <xsl:for-each select="
            $receptionEntities//intro:INT31_IntertextualRelation[
            intro:R13_hasReferringEntity/@rdf:resource = $expr-uri or
            intro:R12_hasReferredToEntity/@rdf:resource = $expr-uri
            ]/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[
            matches(., '/feature/place_ref/')
            ]">
          <xsl:sequence select="string(.)"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="alk-places-json" as="xs:string*">
      <xsl:for-each-group select="$alk-places-raw" group-by=".">
        <xsl:sort select="count(current-group())" order="descending"/>
        <xsl:sequence select="
            concat(
            '{&quot;label&quot;:&quot;',
            replace(local:get-label(current-grouping-key()), '&quot;', ''),
            '&quot;,&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <!-- Rhetorische Topoi -->
    <xsl:variable name="alk-topoi-raw" as="xs:string*">
      <xsl:for-each select="$alk-expr-ids">
        <xsl:variable name="expr-uri" select="concat('https://sappho-digital.com/expression/', .)"/>
        <xsl:for-each select="
            $receptionEntities//intro:INT31_IntertextualRelation[
            intro:R13_hasReferringEntity/@rdf:resource = $expr-uri or
            intro:R12_hasReferredToEntity/@rdf:resource = $expr-uri
            ]/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[
            matches(., '/feature/topos/')
            ]">
          <xsl:sequence select="string(.)"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="alk-topoi-json" as="xs:string*">
      <xsl:for-each-group select="$alk-topoi-raw" group-by=".">
        <xsl:sort select="count(current-group())" order="descending"/>
        <xsl:sequence select="
            concat(
            '{&quot;label&quot;:&quot;',
            replace(local:get-label(current-grouping-key()), '&quot;', ''),
            '&quot;,&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <!-- Werkreferenzen und Zitate -->
    <xsl:variable name="alk-workrfs-raw" as="xs:string*">
      <xsl:for-each select="$alk-expr-ids">
        <xsl:variable name="expr-uri" select="concat('https://sappho-digital.com/expression/', .)"/>
        <xsl:for-each select="
            $receptionEntities//intro:INT31_IntertextualRelation[
            intro:R13_hasReferringEntity/@rdf:resource = $expr-uri or
            intro:R12_hasReferredToEntity/@rdf:resource = $expr-uri
            ]/intro:R22i_relationIsBasedOnSimilarity/@rdf:resource[
            matches(., '/feature/work_ref/') or matches(., '/actualization/work_ref/')
            ]">
          <xsl:sequence select="string(.)"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="alk-workrfs-json" as="xs:string*">
      <xsl:for-each-group select="$alk-workrfs-raw" group-by=".">
        <xsl:sort select="count(current-group())" order="descending"/>
        <xsl:sequence select="
            concat(
            '{&quot;label&quot;:&quot;',
            replace(local:get-label(current-grouping-key()), '&quot;', ''),
            '&quot;,&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <!-- Zitate (Textpassagen) -->
    <xsl:variable name="alk-phrases-raw" as="xs:string*">
      <xsl:for-each select="$alk-expr-ids">
        <xsl:variable name="expr-uri" select="concat('https://sappho-digital.com/expression/', .)"/>
        <xsl:for-each select="
            $receptionEntities//intro:INT31_IntertextualRelation[
            intro:R13_hasReferringEntity/@rdf:resource = $expr-uri or
            intro:R12_hasReferredToEntity/@rdf:resource = $expr-uri
            ]/intro:R24_hasRelatedEntity/@rdf:resource[
            matches(., '/textpassage/')
            ]">
          <xsl:sequence select="string(.)"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="alk-phrases-json" as="xs:string*">
      <xsl:for-each-group select="$alk-phrases-raw" group-by=".">
        <xsl:sort select="count(current-group())" order="descending"/>
        <xsl:sequence select="
            concat(
            '{&quot;label&quot;:&quot;',
            replace(local:get-label(current-grouping-key()), '&quot;', ''),
            '&quot;,&quot;n&quot;:', count(current-group()), '}'
            )"/>
      </xsl:for-each-group>
    </xsl:variable>

    <xsl:variable name="json" as="xs:string" select="
        concat(
        '{',
        '&quot;nSappho&quot;:', statistics/@nSappho, ',',
        '&quot;nReception&quot;:', statistics/@nReception, ',',
        '&quot;categories&quot;:[', string-join($cat-json-items, ','), '],',
        '&quot;fragments&quot;:[', string-join($frag-json-items, ','), '],',
        '&quot;phenomenaDist&quot;:{',
        '&quot;nRecords&quot;:', (statistics/phenomenaDist/@nRecords, '0')[1], ',',
        '&quot;nFeatures&quot;:', (statistics/phenomenaDist/@nFeatures, '0')[1], ',',
        '&quot;decades&quot;:[', string-join($pdist-decade-json, ','), '],',
        '&quot;genres&quot;:[', string-join($pdist-genre-json, ','), '],',
        '&quot;features&quot;:[', string-join($pdist-feat-json, ','), ']',
        '},',
        '&quot;genreDist&quot;:{',
        '&quot;nRecords&quot;:', (statistics/genreDist/@nRecords, '0')[1], ',',
        '&quot;nFeatures&quot;:', (statistics/genreDist/@nFeatures, '0')[1], ',',
        '&quot;genres&quot;:[', string-join($gdist-genre-json, ','), '],',
        '&quot;features&quot;:[', string-join($gdist-feat-json, ','), ']',
        '},',
        '&quot;plotComponents&quot;:[', string-join($plotcomp-plot-json, ','), '],',
        '&quot;personDuality&quot;:{',
        '&quot;nPersonRef&quot;:', (statistics/personDuality/@nPersonRef, '0')[1], ',',
        '&quot;nCharacter&quot;:', (statistics/personDuality/@nCharacter, '0')[1], ',',
        '&quot;nBoth&quot;:', (statistics/personDuality/@nBoth, '0')[1], ',',
        '&quot;nSapphoPersonRef&quot;:', (statistics/personDuality/@nSapphoPersonRef, '0')[1], ',',
        '&quot;nSapphoCharacter&quot;:', (statistics/personDuality/@nSapphoCharacter, '0')[1], ',',
        '&quot;persons&quot;:[', string-join($personduality-json, ','), ']',
        '},',
        '&quot;workCitation&quot;:{',
        '&quot;nWorks&quot;:', (statistics/workCitation/@nWorks, '0')[1], ',',
        '&quot;nReception&quot;:', (statistics/workCitation/@nReception, '0')[1], ',',
        '&quot;nTP&quot;:', (statistics/workCitation/@nTP, '0')[1], ',',
        '&quot;works&quot;:[', string-join($wc-works-json, ','), ']',
        '},',
        '&quot;int31CoOccurrence&quot;:{',
        '&quot;nInt31All&quot;:', (statistics/int31CoOccurrence/@nInt31All, '0')[1], ',',
        '&quot;nInt31Relevant&quot;:', (statistics/int31CoOccurrence/@nInt31Relevant, '0')[1], ',',
        '&quot;nInt31WithFeats&quot;:', (statistics/int31CoOccurrence/@nInt31WithFeats, '0')[1], ',',
        '&quot;featFrequencies&quot;:[', string-join($int31-feat-freq-json, ','), '],',
        '&quot;featPairs&quot;:[', string-join($int31-pair-json, ','), ']',
        '},',
        '&quot;int31TopNodes&quot;:{',
        '&quot;nTotal&quot;:', (statistics/int31TopNodes/@nTotal, '0')[1], ',',
        '&quot;nodes&quot;:[', string-join($int31-topnodes-json, ','), ']',
        '},',
        '&quot;stat10AvgRelations&quot;:{',
        '&quot;avgSapphoInt31&quot;:', (statistics/stat10AvgRelations/@avgSapphoInt31, '0')[1], ',',
        '&quot;avgReceptionInt31&quot;:', (statistics/stat10AvgRelations/@avgReceptionInt31, '0')[1], ',',
        '&quot;avgSapphoShared&quot;:', (statistics/stat10AvgRelations/@avgSapphoShared, '0')[1], ',',
        '&quot;avgReceptionShared&quot;:', (statistics/stat10AvgRelations/@avgReceptionShared, '0')[1], ',',
        '&quot;nSappho&quot;:', (statistics/stat10AvgRelations/@nSappho, '0')[1], ',',
        '&quot;nReception&quot;:', (statistics/stat10AvgRelations/@nReception, '0')[1], ',',
        '&quot;int31Hist&quot;:[', string-join($stat10-int31hist-json, ','), '],',
        '&quot;sharedHist&quot;:[', string-join($stat10-sharedhist-json, ','), ']',
        '},',
        '&quot;alk&quot;:{',
        '&quot;name&quot;:&quot;Anna Louisa Karsch&quot;,',
        '&quot;imgUrl&quot;:&quot;', $alk-img-url, '&quot;,',
        '&quot;wikidata&quot;:&quot;https://www.wikidata.org/entity/Q469571&quot;,',
        '&quot;gnd&quot;:&quot;https://d-nb.info/gnd/118560328&quot;,',
        '&quot;nWorks&quot;:', $alk-n-works, ',',
        '&quot;nReceptionTotal&quot;:', statistics/@nReception, ',',
        '&quot;decadesDist&quot;:[', string-join($alk-decade-json, ','), '],',
        '&quot;topics&quot;:[', string-join($alk-topics-json, ','), '],',
        '&quot;motifs&quot;:[', string-join($alk-motifs-json, ','), '],',
        '&quot;plots&quot;:[', string-join($alk-plots-json, ','), '],',
        '&quot;persons&quot;:[', string-join($alk-persons-json, ','), '],',
        '&quot;places&quot;:[', string-join($alk-places-json, ','), '],',
        '&quot;topoi&quot;:[', string-join($alk-topoi-json, ','), '],',
        '&quot;workRefs&quot;:[', string-join($alk-workrfs-json, ','), '],',
        '&quot;phrases&quot;:[', string-join($alk-phrases-json, ','), ']',
        '}',
        '}'
        )"/>

    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <head>
        <xsl:call-template name="html_head">
          <xsl:with-param name="html_title" select="$doc_title"/>
        </xsl:call-template>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"/>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/d3/7.8.5/d3.min.js"/>
        <script src="https://cdn.jsdelivr.net/npm/d3-sankey@0.12.3/dist/d3-sankey.min.js"/>
        <script>const DATA = <xsl:value-of select="$json"/>;</script>
        <script src="js/statistics.js"/>
      </head>
      <body class="page">
        <div class="hfeed site" id="page">
          <xsl:call-template name="nav_bar"/>
          <div class="container-fluid">
            <div class="card">
              <div class="card-header">
                <h1>
                  <xsl:value-of select="$doc_title"/>
                </h1>
                <p>Nähere Informationen zur exemplarischen Analyse sind <a href="analyse.html"
                    >hier</a> zu finden.</p>
                <p>Eine Netzwerkvisualisierung aller Daten ist <a href="network.html">hier</a>
                  verfügbar.</p>
                <p>Häufigkeitsverteilungen einzelner Phänomene und Auflistungen aller
                  intertextuellen Beziehungen können über den Reiter »Rezeptionsphänomene« (in
                  »Analyse«) angesteuert werden.</p>

                <nav class="stats-toc smaller-text" aria-label="Inhaltsverzeichnis">
                  <p class="stats-toc-title">Inhaltsverzeichnis</p>
                  <ol class="stats-toc-list">
                    <li>
                      <a href="#stat1-wrap">Alle Phänomene im Vergleich</a>
                    </li>
                    <li>
                      <a href="#stat2-wrap">Phänomene nach Fragment-Referenz</a>
                    </li>
                    <li>
                      <a href="#stat3-wrap">Phänomene im Laufe der Zeit</a>
                    </li>
                    <li>
                      <a href="#stat4-wrap">Phänomene nach Gattung</a>
                    </li>
                    <li>
                      <a href="#stat5-wrap">Stoff-Komponenten</a>
                    </li>
                    <li>
                      <a href="#stat6-wrap">Personenreferenzen und Figuren</a>
                    </li>
                    <li>
                      <a href="#stat7-wrap">Werkreferenzen und Zitate</a>
                    </li>
                    <li>
                      <a href="#stat8-wrap">Phänomene als Grundlage intertextueller Relationen</a>
                    </li>
                    <li>
                      <a href="#stat9-wrap">Intertextuelle Beziehungen und Textähnlichkeiten</a>
                    </li>
                    <li>
                      <a href="#stat10-wrap">Durchschnittliche Relationen und gemeinsame
                        Phänomene</a>
                    </li>
                    <li>
                      <a href="#stat11-wrap">Fallbeispiel Anna Louisa Karsch – ›die größte deutsche
                        Sappho‹</a>
                    </li>
                  </ol>
                </nav>

              </div>
              <div class="card-body">
                <div class="stats-wrap" id="stat1-wrap">
                  <p class="stats-subtitle">Statistik 1: Alle Phänomene im Vergleich</p>
                  <p class="stats-desc">Welche Phänomene werden in Sappho-Fragmenten sowie in
                    Rezeptionszeugnissen aktualisiert – und wo liegen die auffälligsten
                    Übereinstimmungen oder Verschiebungen?</p>
                  <div class="meta-bar">
                    <div class="meta-card s">
                      <span class="num">
                        <xsl:value-of select="statistics/@nSappho"/>
                      </span>
                      <span class="lbl">Sappho-Fragmente mit Annotationen</span>
                    </div>
                    <div class="meta-card r">
                      <span class="num">
                        <xsl:value-of select="statistics/@nReception"/>
                      </span>
                      <span class="lbl">Analysierte Rezeptionszeugnisse</span>
                    </div>
                  </div>
                  <div class="legend">
                    <span><span class="dot dot-s"/>Sappho-Fragmente</span>
                    <span><span class="dot dot-r"/>Rezeptionszeugnisse</span>
                  </div>
                  <p class="stats-subtitle stats-subtitle-sm">Überblick (Top-N)</p>
                  <div class="control-col-wrap">
                    <div class="stat3-control-group">
                      <label>Anzahl:</label>
                      <select id="sel-cat-topn" class="stat2-select">
                        <option value="20">Top 20</option>
                        <option value="30" selected="selected">Top 30</option>
                        <option value="50">Top 50</option>
                        <option value="100">Top 100</option>
                      </select>
                    </div>
                  </div>
                  <div id="cat-overview-wrap"/>
                  <p class="stats-subtitle stats-subtitle-sm-top">Nach Phänomentyp</p>
                  <div id="cats"/>
                </div>
                <div class="stats-wrap" id="stat2-wrap">
                  <p class="stats-subtitle">Statistik 2: Phänomene nach Fragment-Referenz</p>
                  <p class="stats-desc">Welche Phänomene werden in Rezeptionszeugnissen, die auf
                    bestimmte Fragmente Bezug nehmen, übernommen, welche ausgelassen – und welche
                    kommen neu hinzu?</p>
                  <div class="stat2-controls stat2-controls-center">
                    <label for="sel-sankey-fragment">Referenziertes Fragment:</label>
                    <select id="sel-sankey-fragment" class="stat2-select">
                      <option value="">&#8212; Fragment wählen &#8212;</option>
                    </select>
                  </div>
                  <div id="sankey-wrap2">
                    <div id="sankey-placeholder2" class="sankey-placeholder"/>
                    <div id="sankey-svg-wrap"/>
                    <div id="sankey-legend" class="sankey-legend"/>
                  </div>
                </div>
                <div class="stats-wrap" id="stat3-wrap">
                  <p class="stats-subtitle">Statistik 3: Phänomene im Laufe der Zeit</p>
                  <p class="stats-desc">Wie verteilen sich konkrete Phänomene über die Zeit? Die
                    Blasengröße zeigt, in wie vielen Rezeptionszeugnissen eines Jahrzehnts ein
                    Phänomen annotiert ist; die Farbe kennzeichnet den Phänomentyp.</p>
                  <p class="stats-subtitle stats-subtitle-sm">Überblick (Top-N)</p>
                  <div class="control-col-wrap">
                    <div class="stat3-control-group">
                      <label>Anzahl:</label>
                      <select id="sel-pdist-topn" class="stat2-select">
                        <option value="20">Top 20</option>
                        <option value="30" selected="selected">Top 30</option>
                        <option value="50">Top 50</option>
                        <option value="100">Top 100</option>
                      </select>
                    </div>
                    <div id="pdist-type-legend" class="type-legend"/>
                  </div>
                  <div id="pdist-overview-wrap"/>
                  <p class="stats-subtitle stats-subtitle-sm-top">Nach Phänomentyp</p>
                  <div id="pdist-type-sections"/>
                </div>
                <div class="stats-wrap" id="stat4-wrap">
                  <p class="stats-subtitle">Statistik 4: Phänomene nach Gattung</p>
                  <p class="stats-desc">Welche Phänomene dominieren in welcher Gattung? Die
                    Farbintensität der Zellen zeigt die Häufigkeit innerhalb jeder Gattung; die
                    Farbe kennzeichnet den Phänomentyp.</p>
                  <p class="stats-subtitle stats-subtitle-sm">Überblick (Top-N)</p>
                  <div class="control-col-wrap">
                    <div class="stat3-control-group">
                      <label>Anzahl:</label>
                      <select id="sel-gdist-topn" class="stat2-select">
                        <option value="20">Top 20</option>
                        <option value="30" selected="selected">Top 30</option>
                        <option value="50">Top 50</option>
                        <option value="100">Top 100</option>
                      </select>
                    </div>
                    <div id="gdist-type-legend" class="type-legend"/>
                  </div>
                  <div id="gdist-overview-wrap"/>
                  <p class="stats-subtitle stats-subtitle-sm-top">Nach Gattung</p>
                  <div id="gdist-genre-sections"/>
                  <p class="stats-subtitle stats-subtitle-sm-top">Nach Phänomentyp</p>
                  <div id="gdist-type-sections"/>
                </div>
                <div class="stats-wrap" id="stat5-wrap">
                  <p class="stats-subtitle">Statistik 5: Stoff-Komponenten</p>
                  <p class="stats-desc">Welche Phänomene treten gemeinsam mit einem bestimmten Stoff
                    auf? Der innere Ring zeigt die Phänomentypen, der äußere Ring die einzelnen
                    Phänomene; die Segmentbreite entspricht der relativen Häufigkeit.</p>
                  <div class="control-col-wrap">
                    <div class="stat3-control-group">
                      <label for="sel-pc-plot">Stoff:</label>
                      <select id="sel-pc-plot" class="stat2-select">
                        <option value="">&#8212; Stoff wählen &#8212;</option>
                      </select>
                    </div>
                    <div class="stat3-control-group">
                      <label for="sel-pc-topn">Anzeigen:</label>
                      <select id="sel-pc-topn" class="stat2-select">
                        <option value="3">Top 3 pro Typ</option>
                        <option value="5" selected="selected">Top 5 pro Typ</option>
                        <option value="10">Top 10 pro Typ</option>
                        <option value="0">Alle</option>
                      </select>
                    </div>
                  </div>
                  <div id="pc-placeholder" class="sankey-placeholder"/>
                  <div id="pc-svg-wrap"/>
                  <div id="pc-legend"/>
                </div>
                <div class="stats-wrap" id="stat6-wrap">
                  <p class="stats-subtitle">Statistik 6: Personenreferenzen und Figuren</p>
                  <p class="stats-desc">Welche Personen und Personentypen werden in
                    Sappho-Fragmenten sowie in Rezeptionszeugnissen besonders häufig nicht nur
                    referenziert, sondern treten auch als Figuren auf? Der Vergleich zeigt pro
                    Person bzw. Personentyp die Referenz- und Figurenhäufigkeit.</p>
                  <div class="meta-bar">
                    <div class="meta-card s">
                      <span class="num">
                        <xsl:value-of select="statistics/@nSappho"/>
                      </span>
                      <span class="lbl">Sappho-Fragmente mit Annotationen</span>
                    </div>
                    <div class="meta-card r">
                      <span class="num">
                        <xsl:value-of select="statistics/@nReception"/>
                      </span>
                      <span class="lbl">Analysierte Rezeptionszeugnisse</span>
                    </div>
                  </div>
                  <div class="control-col-wrap">
                    <div class="stat3-control-group">
                      <label for="sel-pd-topn">Anzahl:</label>
                      <select id="sel-pd-topn" class="stat2-select">
                        <option value="20">Top 20</option>
                        <option value="30" selected="selected">Top 30</option>
                        <option value="50">Top 50</option>
                        <option value="0">Alle</option>
                      </select>
                    </div>
                    <div class="stat3-control-group">
                      <label for="sel-pd-filter"> Filter:</label>
                      <select id="sel-pd-filter" class="stat2-select">
                        <option value="all">Alle Personenreferenzen</option>
                        <option value="both">Nur auch als Figur</option>
                      </select>
                    </div>
                  </div>
                  <div id="pd-meta-bar"/>
                  <div class="legend">
                    <span><span class="dot dot-s-ref"/>Referenzen in Sappho-Fragmenten</span>
                    <span><span class="dot dot-s-char"/>Figuren in Sappho-Fragmenten</span>
                    <span><span class="dot dot-r-ref"/>Referenzen in Rezeptionszeugnissen</span>
                    <span><span class="dot dot-r-char"/>Figuren in Rezeptionszeugnissen</span>
                  </div>
                  <div class="chart-wrap">
                    <div id="pd-chart-wrap"/>
                  </div>
                </div>
                <div class="stats-wrap" id="stat7-wrap">
                  <p class="stats-subtitle" style="text-align:center">Statistik 7: Werkreferenzen
                    und Zitate</p>
                  <p class="stats-desc" style="text-align:center">Welche Werke werden in den
                      <xsl:value-of select="statistics/workCitation/@nReception"/> analysierten
                    Rezeptionszeugnissen nicht nur referenziert, sondern auch zitiert?</p>
                  <div id="wc-meta-bar"/>
                  <div class="legend">
                    <span><span class="dot dot-wc-ref"/>Nur referenziert</span>
                    <span><span class="dot dot-wc-both"/>Referenziert und zitiert</span>
                  </div>
                  <div id="wc-chart-wrap" class="chart-wrap"/>
                </div>
                <div class="stats-wrap" id="stat8-wrap">
                  <p class="stats-subtitle">Statistik 8: Phänomene als Grundlage intertextueller
                    Relationen</p>
                  <p class="stats-desc">Welche Phänomene sind am häufigsten ausschlaggebend für
                    intertextuelle Relationen zwischen Sappho-Fragmenten und Rezeptionszeugnissen
                    sowie zwischen Fragmenten und Rezeptionszeugnissen untereinander?</p>
                  <div id="int31-meta-bar" style="text-align:center"/>

                  <p class="stats-subtitle stats-subtitle-sm">Phänomentypen als Basis für
                    intertextuelle Beziehungen</p>
                  <div class="control-col-wrap">
                    <div id="int31-ftype-legend" class="type-legend"/>
                  </div>
                  <div id="int31-ftype-bar-wrap" class="chart-wrap"/>

                  <p class="stats-subtitle stats-subtitle-sm-top">Kookkurrenzen von
                    Einzelphänomenen</p>
                  <p class="stats-desc"
                    style="text-align:center;max-width:640px;margin:0 auto 0.75rem"> Im inneren Ring
                    sind die Phänomentypen, im äußeren die einzelnen Phänomene. Die Segmentbreite
                    gibt deren Häufigkeit an. Die Sehnen in der Mitte verbinden Phänomene, die
                    besonders häufig gemeinsam in intertextuellen Relationen auftreten – Breite und
                    Deckkraft skalieren mit der Kookkurrenzstärke.</p>
                  <div class="control-col-wrap">
                    <div class="stat3-control-group">
                      <label for="sel-int31-topn">Phänomene im Diagramm:</label>
                      <select id="sel-int31-topn" class="stat2-select">
                        <option value="5">Top 5</option>
                        <option value="10" selected="selected">Top 10</option>
                        <option value="15">Top 15</option>
                        <option value="20">Top 20</option>
                        <option value="0">Alle</option>
                      </select>
                    </div>
                  </div>
                  <div id="int31-sunburst-wrap"
                    style="display:flex;justify-content:center;margin-top:0.5rem"/>
                  <div id="int31-sunburst-legend" class="sankey-legend" style="margin-top:0.5rem"/>

                  <p class="stats-subtitle stats-subtitle-sm-top">Häufigste
                    Phänomen-Kombinationen</p>
                  <div class="control-col-wrap">
                    <div class="stat3-control-group">
                      <label for="sel-int31-pairs-topn">Anzahl:</label>
                      <select id="sel-int31-pairs-topn" class="stat2-select">
                        <option value="20">Top 20</option>
                        <option value="30" selected="selected">Top 30</option>
                        <option value="50">Top 50</option>
                      </select>
                    </div>
                  </div>
                  <div id="int31-pairs-wrap" style="display:flex;justify-content:center"/>

                </div>
                <div class="stats-wrap" id="stat9-wrap">
                  <p class="stats-subtitle">Statistik 9: Intertextuelle Beziehungen und
                    Textähnlichkeiten</p>
                  <p class="stats-desc">Welche intertextuellen Relationen verbinden die meisten
                    Phänomene? Sichtbar wird, zwischen welchen Texten die reichhaltigsten impliziten
                    Ähnlichkeiten bestehen – unabhängig von expliziten Referenzen.</p>
                  <div class="control-col-wrap">
                    <div class="stat3-control-group">
                      <label for="sel-stat9-topn">Anzahl:</label>
                      <select id="sel-stat9-topn" class="stat2-select">
                        <option value="5" selected="selected">Top 5</option>
                        <option value="10">Top 10</option>
                        <option value="20">Top 20</option>
                      </select>
                    </div>
                    <div class="stat3-control-group">
                      <label for="sel-stat9-reltype">Beziehungstyp:</label>
                      <select id="sel-stat9-reltype" class="stat2-select">
                        <option value="all">Alle</option>
                        <option value="reception">Nur zwischen Rezeptionszeugnissen</option>
                        <option value="mixed">Nur zwischen Rezeptionszeugnissen und
                          Fragmenten</option>
                      </select>
                    </div>
                  </div>
                  <div id="stat9-cards-wrap"/>
                </div>
                <div class="stats-wrap" id="stat10-wrap">
                  <p class="stats-subtitle">Statistik 10: Durchschnittliche intertextuelle
                    Beziehungen und gemeinsame Phänomene</p>
                  <p class="stats-desc">Wie viele intertextuelle Relationen verbinden einen Text im
                    Durchschnitt mit anderen? Und wie viele Phänomene teilt ein Text im Schnitt mit
                    seinen intertextuell verbundenen Texten?</p>
                  <div id="stat10-wrap-inner"/>
                </div>
                <div class="stats-wrap" id="stat11-wrap">
                  <p class="stats-subtitle">Statistik 11: Fallbeispiel Anna Louisa Karsch – ›die
                    größte deutsche Sappho‹</p>
                  <div id="stat11-wrap-inner"/>
                </div>
              </div>
            </div>
          </div>
          <xsl:call-template name="html_footer"/>
        </div>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
