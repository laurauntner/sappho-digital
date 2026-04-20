<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" exclude-result-prefixes="xsl">
    <xsl:decimal-format name="de" grouping-separator="." decimal-separator=","/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="xhtml" version="1.0" indent="yes"
        omit-xml-declaration="yes"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:template match="/">
        <xsl:variable name="doc_title">Sappho Digital</xsl:variable>

        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>
            </head>
            <body class="page">
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar"/>

                    <div class="fragment-background">
                        <div class="hero-section">
                            <div class="hero-inner">
                                <h1 class="hero-title">Sappho Digital</h1>
                                <p class="hero-subtitle">Die literarische Sappho-Rezeption im
                                    deutschsprachigen Raum</p>
                                <p class="hero-text">Auf dieser Webseite werden Informationen zur
                                    literarischen Sappho-Rezeption im deutschsprachigen Raum
                                    gesammelt &#8211; von den Anf&#228;ngen bis in die
                                    Gegenwart.</p>
                                <a href="projekt.html" class="btn btn-secondary button"
                                    style="display:inline-block;text-decoration:none;margin-bottom:3rem;"
                                    >&#220;ber das Projekt</a>
                            </div>
                            <div class="hero-kpi-grid">
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nReception, '#.###', 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl">Rezeptionszeugnisse</div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nAuthors, '#.###', 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl">Autor_innen</div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nAnalysed, '#.###', 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl">Analysierte Texte</div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nInt31, '#.###', 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl">Intertextuelle Beziehungen</div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent"><xsl:value-of
                                            select="homepage-counter/@yearMin"
                                            />&#8202;&#8211;&#8202;<xsl:value-of
                                            select="homepage-counter/@yearMax"/></div>
                                    <div class="hero-kpi-lbl">Zeitspanne</div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nTriples, '#.###', 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl">Tripel<span class="info-tooltip">
                                            <span class="info-icon">&#9432;</span>
                                            <span class="tooltip-text"> Ein Tripel ist im Grunde
                                                eine einfache maschinenlesbare Aussage, bestehend
                                                aus Subjekt, Prädikat und Objekt. Hier beziehen sich
                                                diese Aussagen auf die literarische Sappho-Rezeption
                                                – beispielsweise auf Werke und Autor_innen.
                                                <br/><br/>Siehe zur Einführung auch: <ul
                                                  class="tooltip-list">
                                                  <li>
                                                  <a
                                                  href="https://en.wikipedia.org/wiki/Semantic_triple"
                                                  target="_blank"> »Semantic triple« in der
                                                  Wikipedia </a>
                                                  </li>
                                                  <li>
                                                  <a href="https://sappho-digital.com/projekt.html"
                                                  target="_blank"> Projektbeschreibung </a>
                                                  </li>
                                                </ul>
                                            </span>
                                        </span></div>
                                </div>
                            </div>
                            <p class="hero-scroll-hint"><b>Wo anfangen? &#8594;<a
                                        href="orientierung.html">Hier</a>&#8592; findet sich eine
                                    Orientierungshilfe. <br/>Keine Lust darauf? Dann einfach
                                    scrollen &#8211; unten finden sich vier m&#246;gliche Einstiege.
                                    &#8595;</b></p>
                            <p class="smaller-text disclaimer"
                                style="text-align:center;max-width:580px;">Disclaimer: The <a
                                    href="https://github.com/laurauntner/sappho-digital">raw
                                    data</a> is fully annotated with English-language labels and
                                structured for broad reuse. The website itself, however, is
                                currently primarily intended for German-speaking users.</p>
                        </div>
                        <div class="entry-section">
                            <div class="entry-grid">
                                <a href="toc-alle.html" class="entry-card">
                                    <img src="images/open-magazine.png" alt="Rezeptionszeugnisse"/>
                                    <div>
                                        <div class="entry-card-title">Rezeptionszeugnisse</div>
                                        <div class="entry-card-desc">Verzeichnis deutschsprachiger
                                            literarischer Rezeptionszeugnisse zu Sappho</div>
                                    </div>
                                </a>
                                <a href="statistik.html" class="entry-card">
                                    <img src="images/analysis.png" alt="Statistik"/>
                                    <div>
                                        <div class="entry-card-title">Statistik</div>
                                        <div class="entry-card-desc">Exemplarische statistische
                                            Auswertungen zur literarischen Sappho-Rezeption</div>
                                    </div>
                                </a>
                                <a href="netzwerk.html" class="entry-card">
                                    <img src="images/network.png" alt="Netzwerkvisualisierung"/>
                                    <div>
                                        <div class="entry-card-title">Netzwerkvisualisierung</div>
                                        <div class="entry-card-desc">Netzwerkvisualisierung aller
                                            Daten</div>
                                    </div>
                                </a>
                                <a href="https://github.com/laurauntner/sappho-digital"
                                    class="entry-card">
                                    <img src="images/data.png" alt="Daten"/>
                                    <div>
                                        <div class="entry-card-title">Daten</div>
                                        <div class="entry-card-desc">Frei verf&#252;gbare Daten auf
                                            GitHub</div>
                                    </div>
                                </a>
                            </div>
                        </div>
                    </div>

                    <xsl:call-template name="html_footer"/>
                </div>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>
