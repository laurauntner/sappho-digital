<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="xsl tei xs">
    <xsl:output encoding="UTF-8" media-type="text/html" method="xhtml" version="1.0" indent="yes"
        omit-xml-declaration="yes"/>

    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:template match="/">
        <xsl:variable name="doc_title" select="'Alle Rezeptionszeugnisse'"/>
        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>
                <script src="https://code.highcharts.com/highcharts.js"/>
                <script src="https://code.highcharts.com/modules/timeline.js"/>
                <script src="https://code.highcharts.com/modules/data.js"/>
            </head>
            <body class="page">
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar"/>
                    <div class="container">
                        <div class="card">
                            <div class="card-header">
                                <h1>Alle Rezeptionszeugnisse</h1>
                            </div>
                            <div class="card-body">
                                <div id="container"
                                    style="display: flex; justify-content: space-between; padding-bottom: 50px">
                                    <div id="container-timeline"
                                        style="margin: auto; width: 70%; height: 200px;"/>
                                    <div id="container-genres"
                                        style="margin: auto; width: 30%; height: 200px;"/>
                                </div>
                                <script src="./js/statistics.js"/>
                                <table class="table table-striped display" id="tocTable"
                                    style="width:100%">
                                    <thead>
                                        <tr>
                                            <th scope="col">Jahr</th>
                                            <th scope="col">Titel</th>
                                            <th scope="col">Autor_in</th>
                                            <th scope="col">Gattung</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:for-each
                                            select="document('../data/lists/sappho-rez_alle.xml')//*:listBibl/*:bibl">
                                            <tr>
                                                <td>
                                                  <xsl:value-of select="child::*:date"/>
                                                </td>
                                                <td>
                                                  <xsl:value-of select="child::*:title"/>
                                                </td>
                                                <td>
                                                  <xsl:value-of select="child::*:author"/>
                                                </td>
                                                <td>
                                                  <xsl:value-of select="child::*:note"/>
                                                </td>
                                            </tr>
                                        </xsl:for-each>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                    <xsl:call-template name="html_footer"/>
                    <script type="text/javascript" src="https://cdn.datatables.net/v/bs4/jszip-2.5.0/dt-1.11.0/b-2.0.0/b-html5-2.0.0/cr-1.5.4/r-2.2.9/sp-1.4.0/datatables.min.js"/>
                    <script type="text/javascript" src="js/dt.js"/>
                    <script>
                        $(document).ready(function () {
                        createDataTable('tocTable');
                        });
                    </script>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
