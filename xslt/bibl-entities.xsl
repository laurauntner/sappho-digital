<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="tei">

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <xsl:for-each-group select="//tei:*[@xml:id]" group-by="@xml:id">
            <xsl:variable name="id" select="current-grouping-key()"/>
            <xsl:variable name="label">
                <xsl:choose>
                    <xsl:when test="self::tei:bibl">
                        <xsl:value-of select="normalize-space(tei:title[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(current-group()[1])"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:result-document href="../html/{$id}.html">
                <html>
                    <head>
                        <xsl:call-template name="html_head">
                            <xsl:with-param name="html_title" select="$label"/>
                        </xsl:call-template>
                    </head>
                    <body class="page">
                        <div class="hfeed site" id="page">
                            <xsl:call-template name="nav_bar"/>
                            <div class="container-fluid">
                                <div class="card">
                                    <div class="card-header">
                                        <h1><xsl:value-of select="$label"/></h1>
                                    </div>
                                    <div class="card-body">
                                        <p class="align-left">Interne ID: <xsl:value-of select="$id"/></p>
                                        <xsl:if test="@ref">
                                            <p class="align-left">Wikidata: 
                                                <a href="{@ref}" target="_blank">
                                                    <xsl:value-of select="@ref"/>
                                                </a>
                                            </p>
                                        </xsl:if>

                                        <xsl:if test="self::tei:bibl">
                                            <xsl:if test="tei:date[@type='created']">
                                                <p class="align-left">
                                                    Entstehungsjahr: 
                                                    <xsl:value-of select="tei:date[@type='created']/text()"/>
                                                </p>
                                            </xsl:if>

                                            <xsl:if test="tei:date[@type='published']">
                                                <p class="align-left">
                                                    Publikations-/Aufführungsjahr: 
                                                    <xsl:value-of select="tei:date[@type='published']/text()"/>
                                                </p>
                                            </xsl:if>

                                            <xsl:if test="tei:bibl/tei:title">
                                                <p class="align-left">
                                                    Enthalten in: 
                                                    <xsl:value-of select="tei:bibl/tei:title"/>
                                                    <xsl:if test="tei:bibl/@ref">
                                                        <a href="{tei:bibl/@ref}" target="_blank">
                                                            <img src="images/wiki.png" alt="Wikidata" title="Wikidata-Eintrag öffnen"
                                                                style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;" />
                                                        </a>
                                                    </xsl:if>
                                                </p>
                                            </xsl:if>

                                            <xsl:if test="tei:author">
                                                <p class="align-left">
                                                    Autor_in: 
                                                    <xsl:for-each select="tei:author">
                                                        <xsl:value-of select="."/>
                                                        <xsl:if test="@ref">
                                                            <a href="{@ref}" target="_blank">
                                                                <img src="images/wiki.png" alt="Wikidata" title="Wikidata-Eintrag öffnen"
                                                                    style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;" />
                                                            </a>
                                                        </xsl:if>
                                                        <xsl:if test="position() != last()">, </xsl:if>
                                                    </xsl:for-each>
                                                </p>
                                            </xsl:if>

                                            <xsl:if test="tei:note[@type='genre']">
                                                <p class="align-left">
                                                    Gattung: 
                                                    <xsl:for-each select="tei:note[@type='genre']">
                                                        <xsl:value-of select="."/>
                                                        <xsl:if test="position() != last()">, </xsl:if>
                                                    </xsl:for-each>
                                                </p>
                                            </xsl:if>

                                            <xsl:if test="tei:pubPlace">
                                                <p class="align-left">
                                                    Publikations-/Aufführungsort: 
                                                    <xsl:for-each select="tei:pubPlace">
                                                        <xsl:value-of select="."/>
                                                        <xsl:if test="@ref">
                                                            <a href="{@ref}" target="_blank">
                                                                <img src="images/wiki.png" alt="Wikidata" title="Wikidata-Eintrag öffnen"
                                                                    style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;" />
                                                            </a>
                                                        </xsl:if>
                                                        <xsl:if test="position() != last()">, </xsl:if>
                                                    </xsl:for-each>
                                                </p>
                                            </xsl:if>

                                            <xsl:if test="tei:publisher">
                                                <p class="align-left">
                                                    Verlag/Druckerei: 
                                                    <xsl:for-each select="tei:publisher">
                                                        <xsl:value-of select="."/>
                                                        <xsl:if test="@ref">
                                                            <a href="{@ref}" target="_blank">
                                                                <img src="images/wiki.png" alt="Wikidata" title="Wikidata-Eintrag öffnen"
                                                                    style="height: 0.5em; margin-left: 0.2em; vertical-align: middle; display: inline; border-radius: 0;" />
                                                            </a>
                                                        </xsl:if>
                                                        <xsl:if test="position() != last()">, </xsl:if>
                                                    </xsl:for-each>
                                                </p>
                                            </xsl:if>

                                            <xsl:if test="tei:ref">
                                                <p class="align-left">
                                                    Digitalisat: 
                                                    <a href="{tei:ref/@target}" target="_blank">
                                                        <xsl:value-of select="tei:ref/text()"/>
                                                    </a>
                                                </p>
                                            </xsl:if>
                                        </xsl:if>
                                    </div>
                                </div>
                            </div>
                            <xsl:call-template name="html_footer"/>
                        </div>
                    </body>
                </html>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>

</xsl:stylesheet>