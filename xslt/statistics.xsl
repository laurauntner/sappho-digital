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

    <xsl:variable name="json" as="xs:string" select="
        concat(
        '{',
        '&quot;nSappho&quot;:', statistics/@nSappho, ',',
        '&quot;nReception&quot;:', statistics/@nReception, ',',
        '&quot;categories&quot;:[', string-join($cat-json-items, ','), ']',
        '}'
        )"/>

    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <head>
        <xsl:call-template name="html_head">
          <xsl:with-param name="html_title" select="$doc_title"/>
        </xsl:call-template>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"/>
        <script>const DATA = <xsl:value-of select="$json"/>;</script>
        <script src="js/statistics.js"/>
        <style>
          :root {
              --s: rgba(94, 23, 235, 0.75);
              --s-line: #5e17eb;
              --r: rgba(107, 114, 128, 0.75);
              --r-line: #6b7280;
          }
          .stats-wrap {
              max-width: 80%;
              margin: 0 auto;
              border: 1px solid #dee2e6;
              border-radius: 6px;
              padding: 1.5rem;
          }
          .stats-subtitle {
              font-size: 1.1rem;
              font-weight: 600;
              margin-bottom: 1rem;
              margin-top: 0.25rem;
          }
          .meta-bar {
              display: flex;
              gap: 1rem;
              margin-bottom: 1.25rem;
              flex-wrap: wrap;
              justify-content: center;
          }
          .meta-card {
              border-radius: 6px;
              padding: 0.5rem 1rem;
              flex: 0 0 auto;
          }
          .meta-card .num {
              font-size: 1.1rem;
              font-weight: bold;
              display: inline;
          }
          .meta-card .lbl {
              font-size: 0.8rem;
              color: #6c757d;
              display: inline;
              margin-left: 0.4rem;
          }
          .meta-card.s .num {
              color: var(--s-line);
          }
          .meta-card.r .num {
              color: var(--r-line);
          }
          .legend {
              display: flex;
              gap: 1.25rem;
              align-items: center;
              flex-wrap: wrap;
              font-size: 0.84rem;
              margin-bottom: 1.25rem;
              justify-content: center;
          }
          .dot {
              width: 12px;
              height: 12px;
              border-radius: 2px;
              display: inline-block;
              margin-right: 4px;
              vertical-align: middle;
          }
          
          .cat {
              margin-bottom: 1rem;
          }
          .cat .card-header {
              display: flex;
              align-items: center;
              justify-content: flex-start;
              cursor: pointer;
              user-select: none;
          }
          .cat .card-header h2 {
              font-size: 0.95rem;
              font-weight: 600;
              margin: 0;
          }
          .cat .card-header .arrow {
              font-size: 0.75rem;
              color: #999;
              transition: transform 0.2s;
              margin-right: 0.5rem;
          }
          .cat .card-header.open .arrow {
              transform: rotate(90deg);
          }
          .cat .card-body {
              display: none;
          }
          .cat .card-body.visible {
              display: block;
          }
          .chart-wrap {
              overflow-x: auto;
          }
          .chart-wrap canvas {
              display: block;
              min-width: 300px;
          }</style>
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
              </div>
              <div class="card-body">
                <div class="stats-wrap">
                  <p class="stats-subtitle">Statistik 1: Alle Phänomene im Vergleich</p>
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
              </div>
            </div>
          </div>
          <xsl:call-template name="html_footer"/>
        </div>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
