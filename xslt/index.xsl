<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:i18n="urn:sappho-digital:i18n" version="2.0"
    exclude-result-prefixes="xsl i18n">
    <xsl:decimal-format name="de" grouping-separator="." decimal-separator=","/>
    <xsl:decimal-format name="en" grouping-separator="," decimal-separator="."/>
    <xsl:output encoding="UTF-8" media-type="text/html" method="xhtml" version="1.0" indent="yes"
        omit-xml-declaration="yes"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:template match="/">
        <xsl:variable name="doc_title">Sappho Digital</xsl:variable>

        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html xmlns="http://www.w3.org/1999/xhtml" lang="{$lang}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>
            </head>
            <body class="page">
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar">
                        <xsl:with-param name="current_page" select="i18n:href('index.html')"/>
                    </xsl:call-template>

                    <div class="fragment-background">
                        <div class="hero-section">
                            <div class="hero-inner">
                                <h1 class="hero-title">Sappho Digital</h1>
                                <p class="hero-subtitle"><xsl:value-of
                                        select="i18n:t('Die literarische Sappho-Rezeption im deutschsprachigen Raum')"
                                    /></p>
                                <p class="hero-text"><xsl:value-of
                                        select="i18n:t('Auf dieser Webseite werden Informationen zur literarischen Sappho-Rezeption im deutschsprachigen Raum gesammelt – von den Anfängen bis in die Gegenwart.')"
                                    /></p>
                                <a href="{i18n:href('projekt.html')}" class="btn btn-secondary button"
                                    style="display:inline-block;text-decoration:none;margin-bottom:3rem;"
                                    ><xsl:value-of select="i18n:t('Über das Projekt')"/></a>
                            </div>
                            <div class="hero-kpi-grid">
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nReception, if ($lang = 'en') then '#,###' else '#.###', if ($lang = 'en') then 'en' else 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl"><xsl:value-of
                                            select="i18n:t('Rezeptionszeugnisse')"/></div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nAuthors, if ($lang = 'en') then '#,###' else '#.###', if ($lang = 'en') then 'en' else 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl"><xsl:value-of select="i18n:t('Autor_innen')"/></div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nAnalysed, if ($lang = 'en') then '#,###' else '#.###', if ($lang = 'en') then 'en' else 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl"><xsl:value-of select="i18n:t('Analysierte Texte')"/></div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nInt31, if ($lang = 'en') then '#,###' else '#.###', if ($lang = 'en') then 'en' else 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl"><xsl:value-of
                                            select="i18n:t('Intertextuelle Beziehungen')"/></div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent"><xsl:value-of
                                            select="homepage-counter/@yearMin"
                                            />&#8202;&#8211;&#8202;<xsl:value-of
                                            select="homepage-counter/@yearMax"/></div>
                                    <div class="hero-kpi-lbl"><xsl:value-of select="i18n:t('Zeitspanne')"/></div>
                                </div>
                                <div class="hero-kpi-card">
                                    <div class="hero-kpi-num accent">
                                        <xsl:value-of
                                            select="format-number(homepage-counter/@nTriples, if ($lang = 'en') then '#,###' else '#.###', if ($lang = 'en') then 'en' else 'de')"
                                        />
                                    </div>
                                    <div class="hero-kpi-lbl"><xsl:value-of select="i18n:t('Tripel')"/><span class="info-tooltip">
                                            <span class="info-icon">&#9432;</span>
                                            <span class="tooltip-text"> <xsl:value-of
                                                  select="i18n:t('Ein Tripel ist im Grunde eine einfache maschinenlesbare Aussage, bestehend aus Subjekt, Prädikat und Objekt. Hier beziehen sich diese Aussagen auf die literarische Sappho-Rezeption – beispielsweise auf Werke und Autor_innen.')"
                                                />
                                                <br/><br/><xsl:value-of select="i18n:t('Siehe zur Einführung auch:')"/> <ul
                                                  class="tooltip-list">
                                                  <li>
                                                  <a
                                                  href="https://en.wikipedia.org/wiki/Semantic_triple"
                                                  target="_blank"> <xsl:value-of
                                                  select="i18n:t('»Semantic triple« in der Wikipedia')"
                                                  /> </a>
                                                  </li>
                                                  <li>
                                                  <a href="https://sappho-digital.com/{i18n:href('projekt.html')}"
                                                  target="_blank"> <xsl:value-of
                                                  select="i18n:t('Projektbeschreibung')"/> </a>
                                                  </li>
                                                </ul>
                                            </span>
                                        </span></div>
                                </div>
                            </div>
                            <p class="hero-scroll-hint"><b><xsl:value-of select="i18n:t('Wo anfangen? ')"/>&#8594;<a
                                        href="{i18n:href('orientierung.html')}"><xsl:value-of select="i18n:t('Hier')"/></a>&#8592; <xsl:value-of
                                        select="i18n:t('findet sich eine Orientierungshilfe. ')"/><br/><xsl:value-of
                                        select="i18n:t('Keine Lust darauf? Dann einfach scrollen ')"
                                    />&#8211;<xsl:value-of
                                        select="i18n:t(' unten finden sich vier mögliche Einstiege. ')"
                                    />&#8595;</b></p>
                            <p class="smaller-text disclaimer"
                                style="text-align:center;max-width:580px;"><xsl:value-of
                                    select="i18n:t('Disclaimer: The ')"/><a
                                    href="https://github.com/laurauntner/sappho-digital">raw
                                    data</a><xsl:value-of
                                    select="i18n:t(' is fully annotated with English-language labels and structured for broad reuse. The website was originally intended primarily for German-speaking users; an experimental AI-translated English version is now also available.')"
                                /></p>
                        </div>
                        <div class="entry-section">
                            <div class="entry-grid">
                                <a href="{i18n:href('toc-alle.html')}" class="entry-card">
                                    <img src="images/open-magazine.png" alt="{i18n:t('Rezeptionszeugnisse')}"/>
                                    <div>
                                        <div class="entry-card-title"><xsl:value-of
                                                select="i18n:t('Rezeptionszeugnisse')"/></div>
                                        <div class="entry-card-desc"><xsl:value-of
                                                select="i18n:t('Verzeichnis deutschsprachiger literarischer Rezeptionszeugnisse zu Sappho')"
                                            /></div>
                                    </div>
                                </a>
                                <a href="{i18n:href('statistik.html')}" class="entry-card">
                                    <img src="images/analysis.png" alt="{i18n:t('Statistik')}"/>
                                    <div>
                                        <div class="entry-card-title"><xsl:value-of select="i18n:t('Statistik')"/></div>
                                        <div class="entry-card-desc"><xsl:value-of
                                                select="i18n:t('Exemplarische statistische Auswertungen zur literarischen Sappho-Rezeption')"
                                            /></div>
                                    </div>
                                </a>
                                <a href="{i18n:href('netzwerk.html')}" class="entry-card">
                                    <img src="images/network.png" alt="{i18n:t('Netzwerkvisualisierung')}"/>
                                    <div>
                                        <div class="entry-card-title"><xsl:value-of
                                                select="i18n:t('Netzwerkvisualisierung')"/></div>
                                        <div class="entry-card-desc"><xsl:value-of
                                                select="i18n:t('Netzwerkvisualisierung aller Daten')"/></div>
                                    </div>
                                </a>
                                <a href="https://github.com/laurauntner/sappho-digital"
                                    class="entry-card">
                                    <img src="images/data.png" alt="{i18n:t('Daten')}"/>
                                    <div>
                                        <div class="entry-card-title"><xsl:value-of select="i18n:t('Daten')"/></div>
                                        <div class="entry-card-desc"><xsl:value-of
                                                select="i18n:t('Frei verfügbare Daten auf GitHub')"/></div>
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
