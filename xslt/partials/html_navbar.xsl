<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:import href="./params.xsl"/>
    <xsl:template match="/" name="nav_bar">
        <div class="sticky-top">
            <a class="skip-link screen-reader-text sr-only" href="#content">Skip to content</a>
            <nav class="navbar navbar-expand-lg">
                <div class="container-fluid">
                    <a href="index.html" class="navbar-brand custom-logo-link" rel="home"
                        itemprop="url">
                        <img src="{$project_logo}" class="img-fluid" title="{$project_short_title}"
                            alt="{$project_short_title}" itemprop="logo"/>
                    </a>
                    <!--<a class="navbar-brand site-title-with-logo" rel="home" href="index.html" title="{$project_short_title}" itemprop="url"><xsl:value-of select="$project_short_title"/></a>-->
                    <span class="badge bg-light text-dark">in development</span>
                    <button class="navbar-toggler" type="button" data-bs-toggle="collapse"
                        data-bs-target="#navbarSupportedContent"
                        aria-controls="navbarSupportedContent" aria-expanded="false"
                        aria-label="Toggle navigation">
                        <span class="navbar-toggler-icon"/>
                    </button>
                    <div class="collapse navbar-collapse justify-content-end"
                        id="navbarSupportedContent">
                        <ul class="navbar-nav mb-2 mb-lg-0">
                            <li class="nav-item dropdown">
                                <a class="nav-link dropdown-toggle custom-dropdown-link" href="#" role="button"
                                    data-bs-toggle="dropdown" aria-expanded="false">Projekt</a>
                                <ul class="dropdown-menu">
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="about.html">Über das Projekt</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="publikationen.html">Publikationen</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="bibliographie.html">Bibliographie</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="buch.html">Primärtexte</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="https://github.com/laurauntner/sappho-digital">Daten auf
                                            GitHub</a>
                                    </li>
                                </ul>
                            </li>
                            <li class="nav-item dropdown">
                                <a class="nav-link dropdown-toggle custom-dropdown-link" href="#" role="button"
                                    data-bs-toggle="dropdown" aria-expanded="false"
                                    >Rezeptionszeugnisse</a>
                                <ul class="dropdown-menu">
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="toc-alle.html">Alle Rezeptionszeugnisse</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="toc-prosa.html">Prosa</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="toc-lyrik.html">Lyrik</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="toc-drama.html">Drama</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="toc-sonstige.html">Sonstige</a>
                                    </li>
                                </ul>
                            </li>
                        </ul>
                    </div>
                </div>
            </nav>
        </div>
    </xsl:template>
</xsl:stylesheet>
