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
                                <a class="nav-link dropdown-toggle custom-dropdown-link" href="#"
                                    role="button" data-bs-toggle="dropdown" aria-expanded="false"
                                    >Projekt</a>
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
                                            href="https://github.com/laurauntner/sappho-digital"
                                            >Daten auf GitHub</a>
                                    </li>
                                </ul>
                            </li>
                            <li class="nav-item dropdown">
                                <a class="nav-link dropdown-toggle custom-dropdown-link" href="#"
                                    role="button" data-bs-toggle="dropdown" aria-expanded="false"
                                    >Texte</a>
                                <ul class="dropdown-menu">
                                    <li class="dropdown-submenu">
                                        <a
                                            class="dropdown-item dropdown-toggle custom-dropdown-link"
                                            href="#">Sappho-Fragmente</a>
                                        <ul class="dropdown-menu dropdown-menu-scroll">
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_1.html">Fragment 1 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_2.html">Fragment 2 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_3.html">Fragment 3 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_4.html">Fragment 4 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_5.html">Fragment 5 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_6.html">Fragment 6 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_7.html">Fragment 7 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_8.html">Fragment 8 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_9.html">Fragment 9 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_12.html">Fragment 12 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_15.html">Fragment 15 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_16.html">Fragment 16 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_17.html">Fragment 17 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_18.html">Fragment 18 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_19.html">Fragment 19 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_20.html">Fragment 20 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_21.html">Fragment 21 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_22.html">Fragment 22 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_23.html">Fragment 23 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_24.html">Fragment 24 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_25.html">Fragment 25 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_26.html">Fragment 26 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_27.html">Fragment 27 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_28.html">Fragment 28 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_29.html">Fragment 29 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_30.html">Fragment 30 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_31.html">Fragment 31 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_32.html">Fragment 32 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_33.html">Fragment 33 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_34.html">Fragment 34 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_35.html">Fragment 35 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_36.html">Fragment 36 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_37.html">Fragment 37 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_38.html">Fragment 38 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_39.html">Fragment 39 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_40.html">Fragment 40 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_41.html">Fragment 41 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_42.html">Fragment 42 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_43.html">Fragment 43 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_44.html">Fragment 44 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_44a.html">Fragment 44a Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_45.html">Fragment 45 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_46.html">Fragment 46 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_47.html">Fragment 47 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_48.html">Fragment 48 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_49.html">Fragment 49 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_50.html">Fragment 50 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_51.html">Fragment 51 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_52.html">Fragment 52 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_53.html">Fragment 53 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_54.html">Fragment 54 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_55.html">Fragment 55 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_56.html">Fragment 56 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_57.html">Fragment 57 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_58.html">Fragment 58 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_59.html">Fragment 59 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_60.html">Fragment 60 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_61.html">Fragment 61 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_62.html">Fragment 62 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_63.html">Fragment 63 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_64.html">Fragment 64 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_65.html">Fragment 65 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_66.html">Fragment 66 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_67.html">Fragment 67 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_68.html">Fragment 68 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_69.html">Fragment 69 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_70.html">Fragment 70 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_71.html">Fragment 71 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_72.html">Fragment 72 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_73.html">Fragment 73 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_74.html">Fragment 74 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_75.html">Fragment 75 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_76.html">Fragment 76 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_77.html">Fragment 77 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_78.html">Fragment 78 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_79.html">Fragment 79 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_80.html">Fragment 80 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_81.html">Fragment 81 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_82.html">Fragment 82 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_83.html">Fragment 83 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_84.html">Fragment 84 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_85.html">Fragment 85 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_86.html">Fragment 86 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_87.html">Fragment 87 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_88.html">Fragment 88 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_90.html">Fragment 90 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_91.html">Fragment 91 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_92.html">Fragment 92 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_93.html">Fragment 93 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_94.html">Fragment 94 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_95.html">Fragment 95 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_96.html">Fragment 96 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_97.html">Fragment 97 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_98.html">Fragment 98 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_100.html">Fragment 100 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_101.html">Fragment 101 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_101a.html">Fragment 101a
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_102.html">Fragment 102 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_103.html">Fragment 103 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_103a.html">Fragment 103a
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_103b.html">Fragment 103b
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_103c.html">Fragment 103c
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_104.html">Fragment 104 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_105.html">Fragment 105 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_106.html">Fragment 106 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_107.html">Fragment 107 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_108.html">Fragment 108 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_109.html">Fragment 109 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_110.html">Fragment 110 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_111.html">Fragment 111 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_112.html">Fragment 112 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_113.html">Fragment 113 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_114.html">Fragment 114 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_115.html">Fragment 115 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_116.html">Fragment 116 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_117.html">Fragment 117 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_117a.html">Fragment 117a
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_117b.html">Fragment 117b
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_118.html">Fragment 118 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_119.html">Fragment 119 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_120.html">Fragment 120 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_121.html">Fragment 121 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_122.html">Fragment 122 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_123.html">Fragment 123 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_124.html">Fragment 124 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_125.html">Fragment 125 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_126.html">Fragment 126 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_127.html">Fragment 127 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_128.html">Fragment 128 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_129.html">Fragment 129 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_130.html">Fragment 130 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_132.html">Fragment 132 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_133.html">Fragment 133 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_134.html">Fragment 134 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_135.html">Fragment 135 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_136.html">Fragment 136 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_137.html">Fragment 137 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_138.html">Fragment 138 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_139.html">Fragment 139 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_140.html">Fragment 140 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_141.html">Fragment 141 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_142.html">Fragment 142 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_143.html">Fragment 143 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_144.html">Fragment 144 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_145.html">Fragment 145 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_146.html">Fragment 146 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_147.html">Fragment 147 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_148.html">Fragment 148 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_149.html">Fragment 149 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_150.html">Fragment 150 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_151.html">Fragment 151 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_152.html">Fragment 152 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_153.html">Fragment 153 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_154.html">Fragment 154 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_155.html">Fragment 155 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_156.html">Fragment 156 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_157.html">Fragment 157 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_158.html">Fragment 158 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_159.html">Fragment 159 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_160.html">Fragment 160 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_161.html">Fragment 161 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_162.html">Fragment 162 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_163.html">Fragment 163 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_164.html">Fragment 164 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_165.html">Fragment 165 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_166.html">Fragment 166 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_167.html">Fragment 167 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_168.html">Fragment 168 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_168a.html">Fragment 168a
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_168b.html">Fragment 168b
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_168c.html">Fragment 168c
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_169.html">Fragment 169 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_169a.html">Fragment 169a
                                                  Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_170.html">Fragment 170 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_171.html">Fragment 171 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_172.html">Fragment 172 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_173.html">Fragment 173 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_174.html">Fragment 174 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_175.html">Fragment 175 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_176.html">Fragment 176 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_177.html">Fragment 177 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_179.html">Fragment 179 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_180.html">Fragment 180 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_181.html">Fragment 181 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_182.html">Fragment 182 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_183.html">Fragment 183 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_184.html">Fragment 184 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_185.html">Fragment 185 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_186.html">Fragment 186 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_187.html">Fragment 187 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_188.html">Fragment 188 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_189.html">Fragment 189 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_190.html">Fragment 190 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_191.html">Fragment 191 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_192.html">Fragment 192 Voigt</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_21351_1-8.html">PKöln inv.
                                                  21351,1–8 (Jenseitsgedicht)</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="bibl_sappho_21351_9-12_21376r_1-8.html"
                                                  >PKöln inv. 21351,9–12+21376r,1–8 (Altersgedicht,
                                                  ~Fr. 58 Voigt)</a>
                                            </li>
                                        </ul>
                                    </li>
                                    <li class="dropdown-submenu">
                                        <a
                                            class="dropdown-item dropdown-toggle custom-dropdown-link"
                                            href="#">Rezeptionszeugnisse</a>
                                        <ul class="dropdown-menu">
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="toc-alle.html">Alle Rezeptionszeugnisse</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="toc-prosa.html">Prosaische
                                                  Rezeptionszeugnisse</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="toc-lyrik.html">Lyrische
                                                  Rezeptionszeugnisse</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="toc-drama.html">Dramatische
                                                  Rezeptionszeugnisse</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="toc-sonstige.html">Sonstige
                                                  Rezeptionszeugnisse</a>
                                            </li>
                                        </ul>
                                    </li>
                                </ul>
                            </li>
                            <li class="nav-item dropdown">
                                <a class="nav-link dropdown-toggle custom-dropdown-link" href="#"
                                    role="button" data-bs-toggle="dropdown" aria-expanded="false"
                                    >Analyse</a>
                                <ul class="dropdown-menu">
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="analyse.html">Erläuterungen zur Analyse</a>
                                    </li>
                                    <li>
                                        <a class="dropdown-item custom-dropdown-link"
                                            href="vocab.html">Vokabular</a>
                                    </li>
                                    <li class="dropdown-submenu">
                                        <a
                                            class="dropdown-item dropdown-toggle custom-dropdown-link"
                                            href="#">Rezeptionsphänomene</a>
                                        <ul class="dropdown-menu">
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="intertexts.html">Intertextuelle
                                                  Beziehungen</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="pers-refs.html">Personenreferenzen</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="place-refs.html">Ortsreferenzen</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="work-refs.html">Werkreferenzen</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="text-passages.html">Phrasen</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="motifs.html">Motive</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="topics.html">Themen</a>
                                            </li>
                                            <li>
                                                <a class="dropdown-item custom-dropdown-link"
                                                  href="plots.html">Stoffe</a>
                                            </li>
                                        </ul>
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
