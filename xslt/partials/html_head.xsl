<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:i18n="urn:sappho-digital:i18n"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:include href="./params.xsl"/>
    <xsl:template match="/" name="html_head">
        <xsl:param name="html_title" select="$project_short_title"/>
        <xsl:param name="html_description" select="$project_description"/>
        <xsl:param name="current_page" select="i18n:href('index.html')"/>
        <xsl:param name="html_noindex" select="false()" as="xs:boolean"/>

        <xsl:variable name="page_title"
            select="
                if (contains($html_title, $project_short_title)) then
                    $html_title
                else
                    concat($html_title, ' – ', $project_short_title)"/>
        <xsl:variable name="canonical_url" select="concat($base_url, '/', $current_page)"/>
        <xsl:variable name="other_lang_page" select="i18n:switch-href($current_page)"/>
        <xsl:variable name="de_url"
            select="
                concat($base_url, '/', if ($lang = 'en') then
                    $other_lang_page
                else
                    $current_page)"/>
        <xsl:variable name="en_url"
            select="
                concat($base_url, '/', if ($lang = 'en') then
                    $current_page
                else
                    $other_lang_page)"/>
        <xsl:variable name="og_image" select="concat($base_url, '/images/sappho-reception-digital_logo.png')"/>

        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/>
        <meta name="mobile-web-app-capable" content="yes"/>
        <meta name="apple-mobile-web-app-capable" content="yes"/>
        <meta name="apple-mobile-web-app-title" content="{$html_title}"/>
        <meta name="msapplication-TileColor" content="#ffffff"/>
        <meta name="msapplication-TileImage" content="{$project_logo}"/>
        <meta name="description" content="{$html_description}"/>
        <xsl:if test="$html_noindex">
            <meta name="robots" content="noindex,follow"/>
        </xsl:if>
        <link rel="canonical" href="{$canonical_url}"/>
        <link rel="alternate" hreflang="de" href="{$de_url}"/>
        <link rel="alternate" hreflang="en" href="{$en_url}"/>
        <link rel="alternate" hreflang="x-default" href="{$de_url}"/>
        <!-- Open Graph / Twitter -->
        <meta property="og:site_name" content="{$project_short_title}"/>
        <meta property="og:type" content="website"/>
        <meta property="og:title" content="{$page_title}"/>
        <meta property="og:description" content="{$html_description}"/>
        <meta property="og:url" content="{$canonical_url}"/>
        <meta property="og:image" content="{$og_image}"/>
        <meta property="og:locale" content="{if ($lang = 'en') then 'en_US' else 'de_DE'}"/>
        <meta property="og:locale:alternate" content="{if ($lang = 'en') then 'de_DE' else 'en_US'}"/>
        <meta name="twitter:card" content="summary_large_image"/>
        <meta name="twitter:title" content="{$page_title}"/>
        <meta name="twitter:description" content="{$html_description}"/>
        <meta name="twitter:image" content="{$og_image}"/>
        <!-- favicon -->
        <link rel="icon" type="image/x-icon" href="images/favicons/favicon.ico"/>
        <link rel="icon" type="image/png" href="images/favicons/favicon-16x16.png"/>
        <link rel="icon" type="image/png" href="images/favicons/favicon-32x32.png"/>
        <link rel="icon" type="image/png" href="images/favicons/favicon-64x64.png"/>
        <link rel="icon" type="image/png" href="images/favicons/favicon-96x96.png"/>
        <link rel="icon" type="image/png" href="images/favicons/favicon-180x180.png"/>
        <link rel="preload" href="fonts/geist-sans-latin-200-normal.woff2" as="font"
            type="font/woff2" crossorigin="anonymous"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-57x57.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-60x60.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-72x72.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-76x76.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-114x114.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-120x120.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-144x144.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-152x152.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-167x167.png"/>
        <link rel="apple-touch-icon" type="image/png"
            href="images/favicons/apple-touch-icon-180x180.png"/>
        <link rel="shortcut icon" type="image/png" href="images/favicons/favicon-196x196.png"/>
        <!-- favicon end -->
        <link rel="icon" type="image/svg+xml" href="{$project_logo}" sizes="any"/>
        <link rel="profile" href="http://gmpg.org/xfn/11"/>
        <title>
            <xsl:value-of select="$page_title"/>
        </title>
        <link rel="stylesheet"
            href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css"
            integrity="sha512-1ycn6IcaQQ40/MKBW2W4Rhis/DbILU74C1vSrLJxCq57o941Ym01SwNsOMqvEBFlcgUa6xLiPY/NS5R+E6ztJQ=="
            crossorigin="anonymous" referrerpolicy="no-referrer"/>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css"
            rel="stylesheet"
            integrity="sha384-rbsA2VBKQhggwzxH7pPCaAqO46MgnOM80zW1RWuH61DGLwZJEdK2Kadq2F9CUG65"
            crossorigin="anonymous"/>
        <link rel="stylesheet" href="css/style.css" type="text/css"/>
        <link rel="stylesheet" type="text/css"
            href="https://cdn.datatables.net/v/bs4/jq-3.3.1/jszip-2.5.0/dt-1.11.0/b-2.0.0/b-html5-2.0.0/cr-1.5.4/r-2.2.9/sp-1.4.0/datatables.min.css"
        />
        <link rel="stylesheet" href="pagefind/pagefind-ui.css" type="text/css"/>
    </xsl:template>
</xsl:stylesheet>
