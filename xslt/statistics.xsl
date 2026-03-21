<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="2.0" exclude-result-prefixes="xsl xs">

  <xsl:output encoding="UTF-8" media-type="text/html" method="xhtml" version="1.0" indent="yes"
    omit-xml-declaration="yes"/>

  <xsl:import href="./partials/html_navbar.xsl"/>
  <xsl:import href="./partials/html_head.xsl"/>
  <xsl:import href="./partials/html_footer.xsl"/>

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
          <div class="container">
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
              </div>
              <div class="card-body">
                <div class="stats-wrap">
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
                      <label for="sel-pd-filter">   Filter:</label>
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
              </div>
            </div>
          </div>
          <xsl:call-template name="html_footer"/>
        </div>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
