<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:i18n="urn:sappho-digital:i18n" exclude-result-prefixes="#all" version="2.0">
    <xsl:import href="./params.xsl"/>
    <xsl:template match="/" name="html_footer">
        <xsl:variable name="run-start" as="xs:dateTime" select="current-dateTime()"/>
        <xsl:variable name="build-stamp" as="xs:string"
            select="
                if ($lang = 'en') then
                    format-date(xs:date($run-start), '[D1] [MNn] [Y0001]', 'en', (), ())
                    || ', '
                    || format-time(xs:time($run-start), '[H]:[m01]')
                else
                    format-date(xs:date($run-start), '[D].[M].[Y0001]')
                    || ', '
                    || format-time(xs:time($run-start), '[H]:[m01]')"/>
        <div class="modal fade" id="searchModal" tabindex="-1" aria-labelledby="searchModalLabel"
            aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content search-modal-content">
                    <div class="modal-header">
                        <h2 class="modal-title visually-hidden" id="searchModalLabel"><xsl:value-of select="i18n:t('Suche')"/></h2>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"
                            aria-label="{i18n:t('Schließen')}"/>
                    </div>
                    <div class="modal-body">
                        <div id="search"/>
                    </div>
                </div>
            </div>
        </div>
        <div id="wrapper-footer-full" data-pagefind-ignore="all">
            <a href="{i18n:href('imprint.html')}">© Laura Untner 2026 (<xsl:value-of
                    select="i18n:t('zuletzt aktualisiert am ')"/><xsl:value-of
                    select="$build-stamp"/>)</a>
        </div>
        <script src="https://code.jquery.com/jquery-3.6.3.min.js" integrity="sha256-pvPw+upLPUjgMXY0G+8O0xUf+/Im1MZjXxxgOcBQBXU=" crossorigin="anonymous"/>
        <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.6/dist/umd/popper.min.js" integrity="sha384-oBqDVmMz9ATKxIep9tiCxS/Z9fNfEXiDAYTujMAeBAsjFuCZSmKbSSUnQlmh/jp3" crossorigin="anonymous"/>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.min.js" integrity="sha384-cuYeSxntonz0PPNlHhBs68uyIAVpIIOZZ5JqeqvYYIcEL727kskC66kF92t6Xl2V" crossorigin="anonymous"/>
        <script src="js/listStopProp.js"/>
        <script src="js/navScroll.js"/>
        <script src="pagefind/pagefind-ui.js"/>
        <script src="js/search.js"/>
    </xsl:template>

</xsl:stylesheet>
