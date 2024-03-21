<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0">
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <!-- sort bibl elements by date -->
    <xsl:template match="tei:listBibl">
        <xsl:copy>
            <xsl:apply-templates select="tei:bibl">
                <xsl:sort select="
                    if (tei:date/@when) then tei:date/@when
                    else if (tei:date/@notBefore and not(tei:date/@notAfter)) then tei:date/@notBefore
                    else if (tei:date/@notAfter and not(tei:date/@notBefore)) then tei:date/@notAfter
                    else tei:date/@notBefore"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
