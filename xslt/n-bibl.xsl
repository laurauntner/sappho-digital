<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0">
    <xsl:output method="xml" indent="yes"/>

    <xsl:mode on-no-match="shallow-copy"/>

    <!-- add @n to bibl -->
    <xsl:template match="tei:bibl">
        <xsl:element name="bibl" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="n">
                <xsl:number/>
            </xsl:attribute>
            <xsl:copy-of select="./*"/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
