<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="2.0">

    <xsl:output method="xhtml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:template match="/">
        <xsl:variable name="doc_title" select="'Netzwerkvisualisierung'"/>
        <xsl:variable name="total_fmt"
            select="format-number(xs:integer(/network/meta/totalTriples), '#,##0')"/>

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

                            <div class="card-body align-left" id="network-app">

                                <div id="layout">

                                    <!-- Left sidebar -->
                                    <aside>
                                        <div id="sidebar-inner">
                                            <div class="section-title">Klassen</div>
                                            <input type="text" id="class-search"
                                                placeholder="Klasse suchen …"/>
                                            <div id="class-toolbar">
                                                <button id="btn-default">Default</button>
                                                <button id="btn-all">Alle an</button>
                                                <button id="btn-none">Alle aus</button>
                                            </div>
                                            <div id="class-filter"/>
                                        </div>
                                        <div id="stats">
                                            <span>Gesamt: <b><xsl:value-of select="$total_fmt"/>
                                                  Tripel</b></span>
                                        </div>
                                    </aside>

                                    <!-- Graph canvas -->
                                    <div id="graph"/>

                                    <!-- Export bar -->
                                    <div id="export-bar">
                                        <button id="btn-exp-png">PNG exportieren</button>
                                    </div>

                                    <!-- Hint overlay -->
                                    <div id="graph-hint">
                                        <span class="hint-close">&#x2715;</span>
                                        <b>Hinweis:</b> Startpunkt ist »Von den plejaden her
                                        vierzehn gedichte im hinblick auf Lesbos« von Johannes
                                        Poethen. <b>Klick</b> auf einen Knoten klappt seine
                                        Verbindungen auf. <b>Doppelklick</b> klappt sie wieder zu.
                                        Klick auf <b>Plus</b>-Knoten öffnet fünf weitere
                                        Verbindungen. <b>Klassen</b> links filtern, was sichtbar
                                        ist. Rechts sind <b>Instanzen</b> wählbar.</div>

                                    <!-- Tooltip -->
                                    <div id="node-tooltip">
                                        <button id="node-tooltip-close" title="Schließen"
                                            >&#x2715;</button>
                                        <div id="node-tooltip-body"/>
                                    </div>

                                    <!-- Right sidebar -->
                                    <div id="right-sidebar">
                                        <div id="right-inner">
                                            <div class="section-title" style="margin-top:4px"
                                                >Instanzen</div>
                                            <div class="inst-tabs">
                                                <div class="inst-tab active" data-cls="F2"
                                                  >Texte</div>
                                                <div class="inst-tab" data-cls="ALL">Alle</div>
                                            </div>
                                            <div id="inst-toolbar">
                                                <button id="btn-inst-default">Default</button>
                                                <button id="btn-inst-none">Alle
                                                  abw&#xe4;hlen</button>
                                            </div>
                                            <input type="text" id="instance-search"
                                                placeholder="Instanz suchen …"/>
                                            <div id="instance-list"/>
                                        </div>
                                    </div>

                                </div>

                                <!-- Inline-Styles für den Tooltip -->
                                <style type="text/css">
                                    #node-tooltip {
                                        display: none;
                                        position: fixed;
                                        z-index: 9999;
                                        background: #fff;
                                        border: 1px solid #e2e8f0;
                                        border-radius: 8px;
                                        padding: 10px 28px 10px 14px;
                                        box-shadow: 0 4px 20px rgba(0, 0, 0, .15);
                                        max-width: 280px;
                                        font-size: 12px;
                                        line-height: 1.6;
                                        pointer-events: auto;
                                        word-break: break-word;
                                        overflow-wrap: break-word;
                                    }
                                    #node-tooltip-close {
                                        position: absolute;
                                        top: 5px;
                                        right: 8px;
                                        background: none;
                                        border: none;
                                        cursor: pointer;
                                        font-size: 14px;
                                        color: #94a3b8;
                                        line-height: 1;
                                        padding: 0;
                                    }
                                    #node-tooltip-close:hover {
                                        color: #475569;
                                    }
                                    #node-tooltip a {
                                        color: #8B5CF6;
                                        font-size: 10px;
                                        word-break: break-all;
                                        text-decoration: underline;
                                    }
                                    #node-tooltip a:hover {
                                        color: #6d28d9;
                                    }</style>

                                <!-- JSON -->

                                <script id="network-nodes" type="application/json">
                                    <xsl:call-template name="nodes-json"/>
                                </script>

                                <script id="network-edges" type="application/json">
                                    <xsl:call-template name="edges-json"/>
                                </script>

                                <script id="network-class-stats" type="application/json">
                                    <xsl:call-template name="class-stats-json"/>
                                </script>

                                <script id="network-ns-colors" type="application/json">
                                    <xsl:call-template name="ns-colors-json"/>
                                </script>

                                <script id="network-known-ns" type="application/json">
                                    <xsl:call-template name="known-ns-json"/>
                                </script>

                                <script id="network-meta" type="application/json">
                                    <xsl:call-template name="meta-json"/>
                                </script>

                                <script src="js/network.js" defer="defer"/>

                            </div>
                        </div>
                    </div>

                    <xsl:call-template name="html_footer"/>

                </div>
            </body>
        </html>
    </xsl:template>

    <!-- nodes -->
    <xsl:template name="nodes-json">
        <xsl:text>[</xsl:text>
        <xsl:for-each select="/network/nodes/node">
            <xsl:text>{</xsl:text>
            <xsl:text>"id":</xsl:text>
            <xsl:value-of select="@id"/>
            <xsl:text>,"label":</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@label"/>
            </xsl:call-template>
            <xsl:text>,"uri":</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@uri"/>
            </xsl:call-template>
            <xsl:text>,"group":</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@group"/>
            </xsl:call-template>
            <xsl:text>,"degree":</xsl:text>
            <xsl:value-of select="@degree"/>
            <xsl:text>,"pageUrl":</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@pageUrl"/>
            </xsl:call-template>
            <xsl:text>,"classes":[</xsl:text>
            <xsl:for-each select="class">
                <xsl:call-template name="jstr">
                    <xsl:with-param name="s" select="."/>
                </xsl:call-template>
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>]}</xsl:text>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <!-- edges -->
    <xsl:template name="edges-json">
        <xsl:text>[</xsl:text>
        <xsl:for-each select="/network/edges/edge">
            <xsl:text>{</xsl:text>
            <xsl:text>"from":</xsl:text>
            <xsl:value-of select="@from"/>
            <xsl:text>,"to":</xsl:text>
            <xsl:value-of select="@to"/>
            <xsl:text>,"label":</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@label"/>
            </xsl:call-template>
            <xsl:text>,"title":</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@predicate"/>
            </xsl:call-template>
            <xsl:text>,"predicate":</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@predicate"/>
            </xsl:call-template>
            <xsl:text>,"arrows":"to"}</xsl:text>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <!-- classStats -->
    <xsl:template name="class-stats-json">
        <xsl:text>{</xsl:text>
        <xsl:for-each select="/network/classStats/classStat">
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@uri"/>
            </xsl:call-template>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="@count"/>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <!-- NS_COLORS -->
    <xsl:template name="ns-colors-json">
        <xsl:text>{</xsl:text>
        <xsl:for-each select="/network/meta/colors/color">
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@prefix"/>
            </xsl:call-template>
            <xsl:text>:</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@value"/>
            </xsl:call-template>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <!-- KNOWN_NS -->
    <xsl:template name="known-ns-json">
        <xsl:text>{</xsl:text>
        <xsl:for-each select="/network/meta/namespaces/ns">
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@uri"/>
            </xsl:call-template>
            <xsl:text>:</xsl:text>
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="@prefix"/>
            </xsl:call-template>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <!-- meta -->
    <xsl:template name="meta-json">
        <xsl:text>{</xsl:text>
        <xsl:text>"totalTriples":</xsl:text>
        <xsl:value-of select="/network/meta/totalTriples"/>
        <xsl:text>,"defaultTopN":</xsl:text>
        <xsl:value-of select="/network/meta/defaultTopN"/>
        <xsl:text>,"defaultMaxEdges":</xsl:text>
        <xsl:value-of select="/network/meta/defaultMaxEdges"/>
        <xsl:text>,"defaultNeighbors":</xsl:text>
        <xsl:value-of select="/network/meta/defaultNeighbors"/>
        <xsl:text>,"maxNeighbors":</xsl:text>
        <xsl:value-of select="/network/meta/maxNeighbors"/>
        <xsl:text>,"startUri":</xsl:text>
        <xsl:call-template name="jstr">
            <xsl:with-param name="s" select="/network/meta/startUri"/>
        </xsl:call-template>
        <xsl:text>,"hiddenByDefault":[</xsl:text>
        <xsl:for-each select="/network/meta/hiddenByDefault/class">
            <xsl:call-template name="jstr">
                <xsl:with-param name="s" select="."/>
            </xsl:call-template>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>],"int31NeighborIds":[</xsl:text>
        <xsl:for-each select="/network/int31Neighbors/id">
            <xsl:value-of select="."/>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>]}</xsl:text>
    </xsl:template>

    <xsl:template name="jstr">
        <xsl:param name="s" select="''"/>
        <xsl:variable name="a" select="replace($s, '\\', '\\\\')"/>
        <xsl:variable name="b" select="replace($a, '&quot;', '\\&quot;')"/>
        <xsl:variable name="c" select="replace($b, '&#x0D;', '\\r')"/>
        <xsl:variable name="d" select="replace($c, '&#x0A;', '\\n')"/>
        <xsl:variable name="e" select="replace($d, '&#x09;', '\\t')"/>
        <xsl:text>"</xsl:text>
        <xsl:value-of select="$e"/>
        <xsl:text>"</xsl:text>
    </xsl:template>

</xsl:stylesheet>
