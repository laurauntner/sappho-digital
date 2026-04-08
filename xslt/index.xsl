<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0" exclude-result-prefixes="xsl">
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
                    
                    <!-- ── Hero ─────────────────────────────────────────── -->
                    <div class="container fragment-background" style="min-height:92vh;display:flex;flex-direction:column;justify-content:center;align-items:center;padding:3rem 2rem;">
                        
                        <!-- Titel + Untertitel -->
                        <div style="text-align:center;max-width:720px;margin:0 auto;">
                            <h1 style="font-size:clamp(2rem,5vw,3.2rem);letter-spacing:.12em;text-transform:uppercase;margin-bottom:.4rem;">Sappho Digital</h1>
                            <p style="font-size:clamp(1rem,2.2vw,1.3rem);color:#4b5563;margin-bottom:1.4rem;font-weight:300;line-height:1.5;">Die literarische Sappho-Rezeption im deutschsprachigen Raum</p>
                            <p style="font-size:.95rem;color:#4b5563;line-height:1.7;max-width:580px;margin:0 auto 1.5rem;text-align:justify;text-align-last:center;">
                                Auf dieser Webseite werden Informationen zur literarischen Sappho-Rezeption im deutschsprachigen Raum gesammelt &#8211; von den Anf&#228;ngen bis in die Gegenwart.
                            </p>
                            <a href="about.html" class="btn btn-secondary button" style="display:inline-block;text-decoration:none;margin-bottom:2rem;">&#220;ber das Projekt (work in progress)</a>
                        </div>
                        
                        <!-- KPI-Kacheln -->
                        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:.75rem;max-width:760px;width:100%;margin:0 auto;">
                            <div style="background:rgba(255,255,255,0.72);backdrop-filter:blur(4px);border-radius:10px;padding:1rem 1.1rem;text-align:center;border:1px solid rgba(255,255,255,0.6);">
                                <div style="font-size:1.65rem;font-weight:700;color:#1f2937;line-height:1.1;">
                                    <xsl:value-of select="format-number(homepage-counter/@nReception,'#.###','de')"/>
                                </div>
                                <div style="font-size:.72rem;color:#6b7280;margin-top:.2rem;text-transform:uppercase;letter-spacing:.05em;">Rezeptionszeugnisse</div>
                            </div>
                            <div style="background:rgba(255,255,255,0.72);backdrop-filter:blur(4px);border-radius:10px;padding:1rem 1.1rem;text-align:center;border:1px solid rgba(255,255,255,0.6);">
                                <div style="font-size:1.65rem;font-weight:700;color:#1f2937;line-height:1.1;">
                                    <xsl:value-of select="format-number(homepage-counter/@nAuthors,'#.###','de')"/>
                                </div>
                                <div style="font-size:.72rem;color:#6b7280;margin-top:.2rem;text-transform:uppercase;letter-spacing:.05em;">Autor_innen</div>
                            </div>
                            <div style="background:rgba(255,255,255,0.72);backdrop-filter:blur(4px);border-radius:10px;padding:1rem 1.1rem;text-align:center;border:1px solid rgba(255,255,255,0.6);">
                                <div style="font-size:1.65rem;font-weight:700;color:#1f2937;line-height:1.1;">
                                    <xsl:value-of select="format-number(homepage-counter/@nAnalysed,'#.###','de')"/>
                                </div>
                                <div style="font-size:.72rem;color:#6b7280;margin-top:.2rem;text-transform:uppercase;letter-spacing:.05em;">Analysierte Texte</div>
                            </div>
                            <div style="background:rgba(255,255,255,0.72);backdrop-filter:blur(4px);border-radius:10px;padding:1rem 1.1rem;text-align:center;border:1px solid rgba(255,255,255,0.6);">
                                <div style="font-size:1.65rem;font-weight:700;color:var(--s-line);line-height:1.1;">
                                    <xsl:value-of select="format-number(homepage-counter/@nInt31,'#.###','de')"/>
                                </div>
                                <div style="font-size:.72rem;color:#6b7280;margin-top:.2rem;text-transform:uppercase;letter-spacing:.05em;">Intertextuelle Beziehungen</div>
                            </div>
                            <div style="background:rgba(255,255,255,0.72);backdrop-filter:blur(4px);border-radius:10px;padding:1rem 1.1rem;text-align:center;border:1px solid rgba(255,255,255,0.6);">
                                <div style="font-size:1.65rem;font-weight:700;color:var(--s-line);line-height:1.1;">
                                    <xsl:value-of select="homepage-counter/@yearMin"/>&#8202;&#8211;&#8202;<xsl:value-of select="homepage-counter/@yearMax"/>
                                </div>
                                <div style="font-size:.72rem;color:#6b7280;margin-top:.2rem;text-transform:uppercase;letter-spacing:.05em;">Zeitspanne</div>
                            </div>
                            <div style="background:rgba(255,255,255,0.72);backdrop-filter:blur(4px);border-radius:10px;padding:1rem 1.1rem;text-align:center;border:1px solid rgba(255,255,255,0.6);">
                                <div style="font-size:1.65rem;font-weight:700;color:#1f2937;line-height:1.1;">
                                    <xsl:value-of select="format-number(homepage-counter/@nTriples,'#.###','de')"/>
                                </div>
                                <div style="font-size:.72rem;color:#6b7280;margin-top:.2rem;text-transform:uppercase;letter-spacing:.05em;">Tripel</div>
                            </div>
                        </div>
                        
                        <!-- Scroll-Hinweis -->
                        <p style="margin-top:2rem;font-size:.82rem;color:#6b7280;text-align:center;">
                            <b>Wo anfangen? Einfach scrollen &#8211; unten finden sich vier m&#246;gliche Einstiege. &#x2193;</b>
                        </p>
                        
                        <!-- Disclaimer -->
                        <p class="smaller-text disclaimer" style="margin-top:1rem;text-align:center;max-width:580px;">
                            Disclaimer: The raw data is largely annotated with English-language labels and structured for broad reuse. The website itself, however, is primarily intended for German-speaking users.
                        </p>
                    </div>
                    
                    <!-- ── Vier Einstiegs-Karten ──────────────────────────── -->
                    <div class="container-fluid">
                        <div class="row wrapper img_bottom">
                            <div class="col-md-6 col-lg-6 col-sm-12">
                                <a href="toc-alle.html" class="index-link">
                                    <div class="card index-card d-flex flex-column">
                                        <div class="card-body item-center">
                                            <img src="images/open-magazine.png"
                                                title="open-magazine.png" alt="Flaticon"
                                                class="smaller-img"/>
                                        </div>
                                        <div class="card-header">
                                            <h5>Rezeptionszeugnisse</h5>
                                            <p>Verzeichnis deutschsprachiger literarischer
                                                <br/>Rezeptionszeugnisse zu Sappho</p>
                                        </div>
                                    </div>
                                </a>
                            </div>
                            <div class="col-md-6 col-lg-6 col-sm-12">
                                <a href="statistics.html" class="index-link">
                                    <div class="card index-card d-flex flex-column">
                                        <div class="card-body item-center">
                                            <img src="images/analysis.png" title="analysis.png"
                                                alt="Flaticon" class="smaller-img"/>
                                        </div>
                                        <div class="card-header">
                                            <h5>Statistik</h5>
                                            <p>Exemplarische statistische Auswertungen <br/>zur
                                                literarischen Sappho-Rezeption</p>
                                        </div>
                                    </div>
                                </a>
                            </div>
                            <div class="col-md-6 col-lg-6 col-sm-12">
                                <a href="network.html" class="index-link">
                                    <div class="card index-card d-flex flex-column">
                                        <div class="card-body item-center">
                                            <img src="images/network.png" title="network.png"
                                                alt="Flaticon" class="smaller-img"/>
                                        </div>
                                        <div class="card-header">
                                            <h5>Netzwerkvisualisierung</h5>
                                            <p>Netzwerkvisualisierung <br/>aller Daten</p>
                                        </div>
                                    </div>
                                </a>
                            </div>
                            <div class="col-md-6 col-lg-6 col-sm-12">
                                <a href="https://github.com/laurauntner/sappho-digital"
                                    class="index-link">
                                    <div class="card index-card d-flex flex-column">
                                        <div class="card-body item-center">
                                            <img src="images/data.png" title="data.png"
                                                alt="Flaticon" class="smaller-img"/>
                                        </div>
                                        <div class="card-header">
                                            <h5>Daten</h5>
                                            <p>Frei verf&#252;gbare Daten <br/>auf GitHub</p>
                                        </div>
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
