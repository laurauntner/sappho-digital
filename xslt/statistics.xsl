<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="3.0"
  expand-text="no"
  exclude-result-prefixes="xs">
  
  <xsl:output method="html" version="5" encoding="UTF-8" indent="yes"/>
  
  <xsl:template match="/statistics">
    
    <xsl:variable name="cat-json-items" as="xs:string*">
      <xsl:for-each select="category">
        <xsl:variable name="items-json" as="xs:string*">
          <xsl:for-each select="item">
            <xsl:sequence select="concat(
              '{',
              '&quot;label&quot;:&quot;',       replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
              '&quot;countSappho&quot;:',        @countSappho,    ',',
              '&quot;countReception&quot;:',     @countReception, ',',
              '&quot;pctSappho&quot;:',          @pctSappho,      ',',
              '&quot;pctReception&quot;:',       @pctReception,
              '}'
              )"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="concat(
          '{',
          '&quot;key&quot;:&quot;',   replace(replace(@key,   '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
          '&quot;label&quot;:&quot;', replace(replace(@label, '\\', '\\\\'), '&quot;', '\\&quot;'), '&quot;,',
          '&quot;n&quot;:',           @n, ',',
          '&quot;items&quot;:[',      string-join($items-json, ','), ']',
          '}'
          )"/>
      </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="json" as="xs:string" select="concat(
      '{',
      '&quot;nSappho&quot;:',    @nSappho,    ',',
      '&quot;nReception&quot;:', @nReception, ',',
      '&quot;categories&quot;:[', string-join($cat-json-items, ','), ']',
      '}'
      )"/>
    
    <html lang="de">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>Sappho – Phänomene im Vergleich</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"/>
        <script>const DATA = <xsl:value-of select="$json"/>;</script>
        <script src="js/statistics.js"/>
        <style>
          :root {
          --s:      rgba(94,23,235,0.75);
          --s-line: #5e17eb;
          --r:      rgba(107,114,128,0.75);
          --r-line: #6b7280;
          --bg:       #fdfcf8;
          --card:     #ffffff;
          --border:   #e8e0d0;
          --head-bg:  #f5f0e8;
          --text:     #2c2c2c;
          --muted:    #777;
          --font:     'Georgia', serif;
          --ui:       system-ui, sans-serif;
          }
          * { box-sizing: border-box; margin: 0; padding: 0; }
          body { font-family: var(--font); background: var(--bg); color: var(--text); min-height: 100vh; }
          
          header {
          background: #2c2c2c; color: #fdfcf8;
          padding: 2rem 3rem; border-bottom: 4px solid var(--s-line);
          }
          header h1 { font-size: 1.6rem; font-weight: normal; letter-spacing: 0.04em; }
          header p  { margin-top: 0.4rem; font-size: 0.85rem; color: #bbb; font-family: var(--ui); }
          
          main { max-width: 1200px; margin: 2rem auto; padding: 0 2rem; }
          
          .meta-bar { display: flex; gap: 1.5rem; margin-bottom: 1.5rem; flex-wrap: wrap; }
          .meta-card {
          background: var(--card); border: 1px solid var(--border);
          border-radius: 6px; padding: 0.9rem 1.4rem; flex: 1; min-width: 160px;
          }
          .meta-card .num { font-size: 1.9rem; font-weight: bold; line-height: 1; }
          .meta-card .lbl { font-size: 0.8rem; font-family: var(--ui); color: var(--muted); margin-top: 0.25rem; }
          .meta-card.s .num { color: var(--s-line); }
          .meta-card.r .num { color: var(--r-line); }
          
          .legend {
          display: flex; gap: 1.25rem; align-items: center; flex-wrap: wrap;
          font-family: var(--ui); font-size: 0.84rem;
          background: var(--card); border: 1px solid var(--border);
          border-radius: 6px; padding: 0.7rem 1.2rem; margin-bottom: 2rem;
          }
          .dot { width: 13px; height: 13px; border-radius: 2px; display: inline-block; margin-right: 4px; vertical-align: middle; }
          .legend-note { color: var(--muted); font-size: 0.78rem; margin-left: auto; }
          
          .cat {
          background: var(--card); border: 1px solid var(--border);
          border-radius: 6px; margin-bottom: 1.75rem; overflow: hidden;
          }
          .cat-head {
          display: flex; align-items: center; justify-content: space-between;
          padding: 0.85rem 1.4rem; background: var(--head-bg);
          border-bottom: 1px solid var(--border);
          cursor: pointer; user-select: none;
          }
          .cat-head h2 { font-size: 0.95rem; font-weight: 700; font-family: var(--ui); }
          .cat-head .meta { font-size: 0.78rem; font-family: var(--ui); color: var(--muted); }
          .cat-body { padding: 1.25rem 1.5rem; }
          .cat-body.hidden { display: none; }
          
          .chart-wrap { overflow-x: auto; }
          .chart-wrap canvas { display: block; min-width: 400px; }
          
          footer {
          text-align: center; font-size: 0.76rem; font-family: var(--ui);
          color: var(--muted); padding: 2rem;
          border-top: 1px solid var(--border); margin-top: 0.5rem;
          }
        </style>
      </head>
      <body>
        <header>
          <h1>Sappho – Phänomene im Vergleich</h1>
          <p>Anteil der Textzeugen mit dem jeweiligen Feature · Sappho-Fragmente vs. Rezeptionszeugnisse</p>
        </header>
        <main>
          <div class="meta-bar">
            <div class="meta-card s">
              <div class="num"><xsl:value-of select="@nSappho"/></div>
              <div class="lbl">Sappho-Fragmente mit Aktualisierungen</div>
            </div>
            <div class="meta-card r">
              <div class="num"><xsl:value-of select="@nReception"/></div>
              <div class="lbl">Rezeptionszeugnisse mit Aktualisierungen</div>
            </div>
          </div>
          <div class="legend">
            <span><span class="dot" style="background:var(--s)"/>Sappho-Fragmente</span>
            <span><span class="dot" style="background:var(--r)"/>Rezeptionszeugnisse</span>
            <span class="legend-note">Anteil F2-Instanzen mit dem Feature (%)</span>
          </div>
          <div id="cats"/>
        </main>
        <footer>Daten: sappho-digital.com · Visualisierung generiert via XSLT 3.0</footer>
      </body>
    </html>
  </xsl:template>
  
</xsl:stylesheet>
