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

    <xsl:variable name="json" as="xs:string" select="
        concat(
        '{',
        '&quot;nSappho&quot;:', statistics/@nSappho, ',',
        '&quot;nReception&quot;:', statistics/@nReception, ',',
        '&quot;categories&quot;:[', string-join($cat-json-items, ','), '],',
        '&quot;fragments&quot;:[', string-join($frag-json-items, ','), ']',
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
              </div>
              <div class="card-body">
                <div class="stats-wrap">
                  <p class="stats-subtitle">Statistik 1: Alle Phänomene im Vergleich</p>
                  <p class="stats-desc">Welche Phänomene werden in den Sappho-Fragmenten und in
                    ihren Rezeptionszeugnissen aktualisiert – und wo liegen die auffälligsten
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
                    <span><span class="dot" style="background:var(--s)"/>Sappho-Fragmente</span>
                    <span><span class="dot" style="background:var(--r)"/>Rezeptionszeugnisse</span>
                  </div>
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
                    <div id="sankey-placeholder2" class="sankey-placeholder" style="display:none"/>
                    <div id="sankey-svg-wrap" style="display:none"/>
                    <div id="sankey-legend" style="display:none" class="sankey-legend"/>
                  </div>
                </div>
                <div class="stats-wrap">
                  <p class="stats-subtitle">## more coming soon ##</p>
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
