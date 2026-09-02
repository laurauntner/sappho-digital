<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:i18n="urn:sappho-digital:i18n"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <xsl:param name="project_title">Sappho Digital. Die literarische Sappho-Rezeption im deutschsprachigen Raum</xsl:param>
    <xsl:param name="project_short_title">Sappho Digital</xsl:param>
    <xsl:param name="github_url">https://github.com/laurauntner/sappho-digital</xsl:param>
    <xsl:param name="html_title">Sappho Digital</xsl:param>
    <xsl:param name="project_logo">images/sappho-reception-digital_logo.png</xsl:param>
    <xsl:param name="base_url">https://sappho-digital.com</xsl:param>

    <!-- Language of the current build: 'de' (default) or 'en'. Ant passes lang=en for the English build. -->
    <xsl:param name="lang" select="'de'"/>

    <!-- Rewrites an internal page href to its English-language variant when $lang = 'en'.
         External links, mailto:, anchors and hrefs without an .html target pass through unchanged.
         Absolute links to our own $base_url are treated as internal. -->
    <!-- pages that exist only once and are shared by both languages (e.g. auto-generated,
         already-English documentation) - never gets an "-en" variant -->
    <xsl:variable name="i18n:lang-independent-pages" select="('ontology.html')"/>

    <!-- Explicit English-language slugs for pages whose German filename doesn't double as a
         valid English word, so the English site doesn't need a bare "-en" marker in the URL
         (e.g. "orte.html" -> "places.html", not "orte-en.html"). A handful of German filenames
         are already English words themselves (query, imprint, alignments, 404) or identical in
         both languages (topoi, toc-drama) - those get a distinct real English slug too, to avoid
         colliding with the German filename. Anything NOT listed here (opaque per-entity IDs like
         bibl_xxx.html, author_xxx.html, place_xxx.html, int31_xxx.html, ...) falls back to
         appending "-en" before ".html". -->
    <xsl:variable name="i18n:en-page-slugs">
        <slug de="index.html" en="home.html"/>
        <slug de="projekt.html" en="project.html"/>
        <slug de="orientierung.html" en="guidance.html"/>
        <slug de="analyse.html" en="analysis.html"/>
        <slug de="publikationen.html" en="publications.html"/>
        <slug de="bibliographie.html" en="bibliography.html"/>
        <slug de="texte.html" en="texts.html"/>
        <slug de="404.html" en="not-found.html"/>
        <slug de="imprint.html" en="legal-notice.html"/>
        <slug de="toc-alle.html" en="toc-all.html"/>
        <slug de="toc-drama.html" en="toc-plays.html"/>
        <slug de="toc-lyrik.html" en="toc-poetry.html"/>
        <slug de="toc-prosa.html" en="toc-prose.html"/>
        <slug de="toc-sonstige.html" en="toc-other.html"/>
        <slug de="alignments.html" en="ontology-alignments.html"/>
        <slug de="netzwerk.html" en="network.html"/>
        <slug de="statistik.html" en="statistics.html"/>
        <slug de="vokabular.html" en="vocabulary.html"/>
        <slug de="intertexte.html" en="intertexts.html"/>
        <slug de="personen.html" en="persons.html"/>
        <slug de="orte.html" en="places.html"/>
        <slug de="werke.html" en="works.html"/>
        <slug de="topoi.html" en="rhetorical-topoi.html"/>
        <slug de="motive.html" en="motifs.html"/>
        <slug de="themen.html" en="topics.html"/>
        <slug de="stoffe.html" en="plots.html"/>
        <slug de="query.html" en="query-builder.html"/>
    </xsl:variable>
    <xsl:key name="i18n-en-slug-by-de" match="slug" use="@de"/>
    <xsl:key name="i18n-de-by-en-slug" match="slug" use="@en"/>

    <xsl:function name="i18n:href" as="xs:string">
        <xsl:param name="href" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$lang != 'en'">
                <xsl:sequence select="$href"/>
            </xsl:when>
            <xsl:when
                test="matches($href, '^[a-zA-Z][a-zA-Z0-9+.-]*:') and not(starts-with($href, $base_url))">
                <xsl:sequence select="$href"/>
            </xsl:when>
            <xsl:when test="not(contains($href, '.html'))">
                <xsl:sequence select="$href"/>
            </xsl:when>
            <xsl:when test="tokenize($href, '/')[last()] = $i18n:lang-independent-pages">
                <xsl:sequence select="$href"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="fname" select="tokenize($href, '/')[last()]"/>
                <xsl:variable name="prefix" select="substring-before($href, $fname)"/>
                <xsl:variable name="bareName" select="substring-before($fname, '.html')"/>
                <xsl:variable name="afterHtml" select="substring-after($fname, '.html')"/>
                <xsl:variable name="mapped"
                    select="key('i18n-en-slug-by-de', concat($bareName, '.html'), $i18n:en-page-slugs)/@en"/>
                <xsl:choose>
                    <xsl:when test="$mapped">
                        <xsl:sequence select="concat($prefix, $mapped, $afterHtml)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="replace($href, '\.html(#|\?|$)', '-en.html$1')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Returns the counterpart of the current page's own filename in the other language,
         e.g. "orientierung.html" -> "guidance.html" and vice versa. Used by the DE/EN switcher.
         Callers always pass the CURRENT page's own filename as actually built (i.e. already run
         through i18n:href in the current language), so this only needs to invert that. -->
    <xsl:function name="i18n:switch-href" as="xs:string">
        <xsl:param name="filename" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$lang = 'en'">
                <xsl:variable name="deMapped"
                    select="key('i18n-de-by-en-slug', $filename, $i18n:en-page-slugs)/@de"/>
                <xsl:choose>
                    <xsl:when test="$deMapped">
                        <xsl:sequence select="$deMapped"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="replace($filename, '-en\.html$', '.html')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="enMapped"
                    select="key('i18n-en-slug-by-de', $filename, $i18n:en-page-slugs)/@en"/>
                <xsl:choose>
                    <xsl:when test="$enMapped">
                        <xsl:sequence select="$enMapped"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="replace($filename, '\.html$', '-en.html')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- UI string dictionary: German source string -> English translation.
         i18n:t() returns the German source unchanged when $lang != 'en' or no entry exists,
         so call sites can always pass the German text as the key. -->
    <xsl:variable name="i18n:strings">
        <entry de="Projekt" en="Project"/>
        <entry de="Zur Orientierung " en="Guidance "/>
        <entry de="Zur Orientierung" en="Guidance"/>
        <entry de="Über das Projekt" en="About the Project"/>
        <entry de="Publikationen" en="Publications"/>
        <entry de="Bibliographie" en="Bibliography"/>
        <entry de="Primärtexte" en="Primary Texts"/>
        <entry de="Texte" en="Texts"/>
        <entry de="Sappho-Fragmente" en="Sappho Fragments"/>
        <entry de="Rezeptionszeugnisse" en="Reception Testimonies"/>
        <entry de="Alle Rezeptionszeugnisse" en="All Reception Testimonies"/>
        <entry de="Prosaische Rezeptionszeugnisse" en="Prose Reception Testimonies"/>
        <entry de="Lyrische Rezeptionszeugnisse" en="Poetic Reception Testimonies"/>
        <entry de="Dramatische Rezeptionszeugnisse" en="Dramatic Reception Testimonies"/>
        <entry de="Sonstige Rezeptionszeugnisse" en="Other Reception Testimonies"/>
        <entry de="Analyse" en="Analysis"/>
        <entry de="Datenmodell" en="Data Model"/>
        <entry de="Ontologie" en="Ontology"/>
        <entry de="Ontologie-Alignments" en="Ontology Alignments"/>
        <entry de="Vokabular" en="Vocabulary"/>
        <entry de="Erläuterungen zur Analyse" en="Notes on the Analysis"/>
        <entry de="Rezeptionsphänomene" en="Reception Phenomena"/>
        <entry de="Intertextuelle Beziehungen" en="Intertextual Relations"/>
        <entry de="Personenreferenzen und Figuren" en="References to Persons and Characters"/>
        <entry de="Ortsreferenzen" en="References to Places"/>
        <entry de="Werkreferenzen und Zitate" en="References to Works and Quotations"/>
        <entry de="Rhetorische Topoi" en="Rhetorical Topoi"/>
        <entry de="Motive" en="Motifs"/>
        <entry de="Themen" en="Topics"/>
        <entry de="Stoffe" en="Plots"/>
        <entry de="Statistik" en="Statistics"/>
        <entry de="Daten" en="Data"/>
        <entry de="Netzwerkvisualisierung" en="Network Visualization"/>
        <entry de="Suche" en="Search"/>
        <entry de="Suche (⌘K / Strg+K)" en="Search (⌘K / Ctrl+K)"/>
        <entry de="Orientierungshilfe" en="Guidance"/>
        <entry de="Schließen" en="Close"/>
        <entry de="Die literarische Sappho-Rezeption im deutschsprachigen Raum"
            en="The Literary Reception of Sappho in the German-Speaking World"/>
        <entry
            de="Auf dieser Webseite werden Informationen zur literarischen Sappho-Rezeption im deutschsprachigen Raum gesammelt – von den Anfängen bis in die Gegenwart."
            en="This website gathers information on the literary reception of Sappho in the German-speaking world – from its beginnings to the present."/>
        <entry de="Autor_innen" en="Authors"/>
        <entry de="Analysierte Texte" en="Analysed Texts"/>
        <entry de="Zeitspanne" en="Time Span"/>
        <entry de="Tripel" en="Triples"/>
        <entry
            de="Ein Tripel ist im Grunde eine einfache maschinenlesbare Aussage, bestehend aus Subjekt, Prädikat und Objekt. Hier beziehen sich diese Aussagen auf die literarische Sappho-Rezeption – beispielsweise auf Werke und Autor_innen."
            en="A triple is essentially a simple machine-readable statement consisting of subject, predicate, and object. Here, these statements refer to the literary reception of Sappho – for example, to works and authors."/>
        <entry de="Siehe zur Einführung auch:" en="For an introduction, see also:"/>
        <entry de="»Semantic triple« in der Wikipedia" en="»Semantic triple« on Wikipedia"/>
        <entry de="Projektbeschreibung" en="Project Description"/>
        <entry de="Wo anfangen? " en="Where to start? "/>
        <entry de="Hier" en="Here"/>
        <entry de="findet sich eine Orientierungshilfe. " en="you’ll find some guidance. "/>
        <entry de="Keine Lust darauf? Dann einfach scrollen "
            en="Not in the mood for that? Then just scroll "/>
        <entry de=" unten finden sich vier mögliche Einstiege. "
            en=" below are four possible starting points. "/>
        <entry de="Verzeichnis deutschsprachiger literarischer Rezeptionszeugnisse zu Sappho"
            en="Catalogue of German-language literary reception testimonies about Sappho"/>
        <entry de="Exemplarische statistische Auswertungen zur literarischen Sappho-Rezeption"
            en="Sample statistical analyses of the literary reception of Sappho"/>
        <entry de="Netzwerkvisualisierung aller Daten" en="Network visualization of all data"/>
        <entry de="Frei verfügbare Daten auf GitHub" en="Freely available data on GitHub"/>
        <entry de="PKöln inv. 21351,1–8 (Jenseitsgedicht)"
            en="PKöln inv. 21351,1–8 (Poem on the Afterlife)"/>
        <entry de="PKöln inv. 21351,9–12+21376r,1–8 (Altersgedicht, ~Fr. 58 Voigt)"
            en="PKöln inv. 21351,9–12+21376r,1–8 (Poem on Old Age, ~Fr. 58 Voigt)"/>
        <entry
            de=" is fully annotated with English-language labels and structured for broad reuse. The website was originally intended primarily for German-speaking users; an experimental AI-translated English version is now also available."
            en=" is fully annotated with English-language labels and structured for broad reuse. The website was originally intended primarily for German-speaking users; this is an experimental AI-translated English version."/>

        <!-- query.xsl -->
        <entry de="Datenquelle" en="Data Source"/>
        <entry de="Andere Quellen:" en="Other Sources:"/>
        <entry de="Nur Autor_innendaten" en="Authors’ Data Only"/>
        <entry de="Nur bibliographische Daten zu Rezeptionszeugnissen"
            en="Bibliographic Data on Reception Testimonies Only"/>
        <entry de="Nur bibliographische Daten zu Sappho-Fragmenten"
            en="Bibliographic Data on Sappho Fragments Only"/>
        <entry de="Default (alle Daten)" en="Default (All Data)"/>
        <entry de="Visueller Query-Builder" en="Visual Query Builder"/>
        <entry de="Der visuelle Query-Builder wird durch "
            en="The visual query builder is provided by "/>
        <entry
            de=" bereitgestellt. Seine Nutzung ist optional – die SPARQL-Query lässt sich auch direkt im Editor unten eingeben."
            en=". Its use is optional – the SPARQL query can also be entered directly in the editor below."/>
        <entry
            de="Eine Query entsteht durch Verbinden von Elementen: Zunächst werden die Klassen ausgewählt, erst danach lässt sich – sofern mehrere Möglichkeiten bestehen – das verbindende Prädikat festlegen. Suchbegriffe werden textbasiert abgeglichen (Groß-/Kleinschreibung wird ignoriert), eine Live-Vorschlagsliste beim Tippen gibt es nicht. Mit dem "
            en="A query is built by connecting elements: first the classes are selected, and only then – where several options exist – can the connecting predicate be set. Search terms are matched as text (case is ignored); there is no live suggestion list while typing. The "/>
        <entry
            de=" wird die erzeugte Query in den SPARQL-Editor übernommen; ausgeführt wird sie erst über ›Query ausführen‹."
            en=" transfers the generated query into the SPARQL editor; it is only executed via ›Run Query‹."/>
        <entry
            de="Die Auswahlliste öffnet sich bei Klick auf ›Search for resources‹ und lässt sich nur durch Auswahl einer Klasse schließen; erst danach werden die übrigen Bedienelemente wieder vollständig zugänglich."
            en="The selection list opens when you click ›Search for resources‹ and can only be closed by choosing a class; only then do the other controls become fully accessible again."/>
        <entry de="Gib hier eine SPARQL-Query ein …" en="Enter a SPARQL query here …"/>
        <entry de="Beispiel-Queries:" en="Example Queries:"/>
        <entry de="Alle Tripel" en="All Triples"/>
        <entry de="Anzahl Tripel" en="Number of Triples"/>
        <entry de="Alle Klassen" en="All Classes"/>
        <entry de="Alle Properties" en="All Properties"/>
        <entry de="Personenreferenzen in Rezeptionszeugnissen"
            en="References to Persons in Reception Testimonies"/>
        <entry de="Figuren in Rezeptionszeugnissen" en="Characters in Reception Testimonies"/>
        <entry de="Motive in Rezeptionszeugnissen" en="Motifs in Reception Testimonies"/>
        <entry de="Rhetorische Topoi in Rezeptionszeugnissen"
            en="Rhetorical Topoi in Reception Testimonies"/>
        <entry de="Ortsreferenzen in Rezeptionszeugnissen"
            en="References to Places in Reception Testimonies"/>
        <entry de="Themen in Rezeptionszeugnissen" en="Topics in Reception Testimonies"/>
        <entry de="Stoffe in Rezeptionszeugnissen" en="Plots in Reception Testimonies"/>
        <entry de="Werkreferenzen in Rezeptionszeugnissen"
            en="References to Works in Reception Testimonies"/>
        <entry de="Zitate in Rezeptionszeugnissen" en="Quotations in Reception Testimonies"/>
        <entry de="Phänomene in Sappho-Fragmenten" en="Phenomena in Sappho Fragments"/>
        <entry de="Top Autor_innen nach Korpuspräsenz" en="Top Authors by Corpus Presence"/>
        <entry de="Rezeptionszeugnisse mit meisten Relationen"
            en="Reception Testimonies with the Most Relations"/>
        <entry de="Hilfreiche Ressourcen:" en="Helpful Resources:"/>
        <entry de="Statistische Auswertungen" en="Statistical Analyses"/>
        <entry de="Namespace-Präfixe" en="Namespace Prefixes"/>
        <entry de="Query ausführen" en="Run Query"/>
        <entry de="Ergebnisse löschen" en="Clear Results"/>

        <!-- network.xsl -->
        <entry de="Das Fenster ist zu klein, um die Netzwerkvisualisierung darstellen zu können."
            en="The window is too small to display the network visualization."/>
        <entry de="Klassen" en="Classes"/>
        <entry de="Klasse suchen …" en="Search classes …"/>
        <entry de="Alle an" en="All On"/>
        <entry de="Alle aus" en="All Off"/>
        <entry de="Gesamt: " en="Total: "/>
        <entry de="PNG exportieren" en="Export PNG"/>
        <entry de="Hinweis:" en="Note:"/>
        <entry de="Startpunkt ist »Von den plejaden her vierzehn gedichte im hinblick auf Lesbos« von Johannes Poethen. "
            en="The starting point is »Von den plejaden her vierzehn gedichte im hinblick auf Lesbos« by Johannes Poethen. "/>
        <entry de="Klick" en="Click"/>
        <entry de=" auf einen Knoten klappt seine Verbindungen auf. "
            en=" on a node expands its connections. "/>
        <entry de="Doppelklick" en="Double-click"/>
        <entry de=" klappt sie wieder zu. Klick auf " en=" collapses them again. Clicking a "/>
        <entry de="-Knoten öffnet fünf weitere Verbindungen. " en=" node opens five more connections. "/>
        <entry de=" links filtern, was sichtbar ist. Rechts sind "
            en=" on the left filter what is visible. On the right, "/>
        <entry de="Instanzen" en="Instances"/>
        <entry de=" wählbar." en=" can be selected."/>
        <entry de="Alle" en="All"/>
        <entry de="Alle abwählen" en="Deselect All"/>
        <entry de="Instanz suchen …" en="Search instances …"/>

        <!-- alignments.xsl -->
        <entry
            de="Verwendete Klassen und Prädikate – vor allem jene, die für die Intertextualitätsanalyse genutzt wurden – wurden mit anderen bibliographischen und literaturwissenschaftlichen Ontologien abgeglichen, darunter: die Bibliographic Ontology ("
            en="The classes and predicates used – especially those used for the intertextuality analysis – were aligned with other bibliographic and literary-studies ontologies, including: the Bibliographic Ontology ("/>
        <entry de="), die FRBR-aligned Bibliographic Ontology ("
            en="), the FRBR-aligned Bibliographic Ontology ("/>
        <entry de="), die Citation Typing Ontology (" en="), the Citation Typing Ontology ("/>
        <entry de="), die Drama Corpora (" en="), the Drama Corpora ("/>
        <entry de=") Ontology, die " en=") Ontology, the "/>
        <entry de=" Ontology for Narrative and Fiction, die "
            en=" Ontology for Narrative and Fiction, the "/>
        <entry de=" Ontology, die OntoPoetry/POSTDATA Ontology ("
            en=" Ontology, the OntoPoetry/POSTDATA Ontology ("/>
        <entry de=" und " en=" and "/>
        <entry de="-Module), die " en=" modules), the "/>
        <entry de=" und die Ontologies of Under-Represented "
            en=" and the Ontologies of Under-Represented "/>
        <entry
            de="Weitere Alignments mit breiter gefassten Ontologien wurden ebenso durchgeführt: mit den DCMI Metadata Terms ("
            en="Further alignments were also carried out with more broadly scoped ontologies: the DCMI Metadata Terms ("/>
        <entry de="), der Document Components Ontology (" en="), the Document Components Ontology ("/>
        <entry de="), der Friend of a Friend (" en="), the Friend of a Friend ("/>
        <entry de=") Ontology und " en=") Ontology, and "/>
        <entry de=". Außerdem wurden " en=". In addition, "/>
        <entry de=", " en=", "/>
        <entry de=" aligniert." en=" were aligned."/>
        <entry
            de="Die Netzwerkdarstellung der implementierten Alignments beruht auf RDF-Daten, die "
            en="The network representation of the implemented alignments is based on RDF data, which can be found "/>
        <entry de=" zu finden sind. Eine tabellarische Darstellung ist "
            en=". A tabular overview can be found "/>
        <entry de=" zu finden." en="."/>
        <entry de="hier" en="here"/>
        <entry
            de="Das Netzwerk lässt sich mit der Maus (Klicken, Überfahren, Zoomen) sowie mit den Steuerelementen rechts und links unten navigieren."
            en="The network can be navigated using the mouse (clicking, hovering, zooming) as well as the controls at the bottom right and left."/>

        <!-- statistics.xsl -->
        <entry
            de="Diese Seite bietet exemplarische statistische Auswertungen der annotierten Sappho-Fragmente und der analysierten Rezeptionszeugnisse. Den Auftakt bilden die Rezeptionsindizes, ein zusammengesetzter Wert zur Messung der Rezeptionsstärke einzelner Texte. Darauf folgen durchschnittliche intertextuelle Relationen und gemeinsame Phänomene, besonders dichte intertextuelle Beziehungen sowie Phänomene als Grundlage intertextueller Relationen. Die weiteren Abschnitte zeigen alle Phänomene im Vergleich, ihre Verteilung nach Fragment-Referenz, im Laufe der Zeit und nach Gattung sowie Zusammenhänge von Komponenten von Stoffvarianten, Personenreferenzen, Werkreferenzen und Zitaten. Abschließend widmen sich zwei Abschnitte genderspezifischen Analysen sowie einer Popularitätsanalyse mittels Wiki-Metriken."
            en="This page offers sample statistical analyses of the annotated Sappho fragments and the analysed reception testimonies. It opens with the reception indices, a composite value measuring the reception strength of individual texts. This is followed by average intertextual relations and shared phenomena, particularly dense intertextual relationships, and phenomena as the basis of intertextual relations. The further sections show all phenomena compared, their distribution by fragment reference, over time and by genre, as well as connections between components of plot variants, references to persons, references to works, and quotations. Finally, two sections are devoted to gender-specific analyses and to a popularity analysis using wiki metrics."/>
        <entry de="Nähere Informationen zur exemplarischen Analyse sind "
            en="More information on the exemplary analysis can be found "/>
        <entry de=" zu finden." en="."/>
        <entry de="Eine Netzwerkvisualisierung aller Daten ist "
            en="A network visualization of all data is available "/>
        <entry de=" verfügbar." en="."/>
        <entry
            de="Einfache Häufigkeitsverteilungen einzelner Phänomene und Auflistungen aller intertextuellen Beziehungen können über den Reiter »Rezeptionsphänomene« (in »Analyse«) angesteuert werden. Häufigkeitsverteilungen zu zeitlichen und räumlichen Schwerpunkten finden sich in den einzelnen Verzeichnissen über den Reiter »Rezeptionszeugnisse« (in »Texte«)."
            en="Simple frequency distributions of individual phenomena and listings of all intertextual relationships can be accessed via the »Reception Phenomena« tab (under »Analysis«). Frequency distributions of temporal and geographical focal points can be found in the individual catalogues via the »Reception Testimonies« tab (under »Texts«)."/>
        <entry de="Inhaltsverzeichnis" en="Table of Contents"/>
        <entry de="Rezeptionsindizes" en="Reception Indices"/>
        <entry de="Durchschnittliche Relationen und gemeinsame Phänomene"
            en="Average Relations and Shared Phenomena"/>
        <entry de="Intertextuelle Beziehungen und Textähnlichkeiten"
            en="Intertextual Relationships and Text Similarities"/>
        <entry de="Phänomene als Grundlage intertextueller Relationen"
            en="Phenomena as the Basis of Intertextual Relations"/>
        <entry de="Alle Phänomene im Vergleich" en="All Phenomena Compared"/>
        <entry de="Phänomene nach Fragment-Referenz" en="Phenomena by Fragment Reference"/>
        <entry de="Phänomene im Laufe der Zeit" en="Phenomena Over Time"/>
        <entry de="Phänomene nach Gattung" en="Phenomena by Genre"/>
        <entry de="Stoff-Komponenten" en="Plot Components"/>
        <entry de="Genderspezifische Analysen" en="Gender-Specific Analyses"/>
        <entry de="Popularitätsanalysen mit Wiki-Metriken" en="Popularity Analyses Using Wiki Metrics"/>
        <entry de="Statistik 1: Rezeptionsindizes" en="Statistics 1: Reception Indices"/>
        <entry de="Der Rezeptionsindex " en="The reception index "/>
        <entry
            de=" ist ein zusammengesetzter Wert auf einer Skala von 0 (schwach) bis 1 (stark), der angibt, wie intensiv die gemessene Rezeption ist. Der Index vereint zwei Dimensionen: die Phänomendichte "
            en=" is a composite value on a scale from 0 (weak) to 1 (strong) indicating how intense the measured reception is. The index combines two dimensions: phenomenon density "/>
        <entry
            de=" – die Gesamtzahl aller einem Text zugeordneten analytischen Einheiten (Personen-, Orts- und Werkreferenzen, Figuren, rhetorische Topoi, Motive, Themen, Stoffe bzw. Stoffvarianten und Zitate) – und die intertextuelle Vernetzung "
            en=" – the total number of analytical units assigned to a text (references to persons, places, and works, characters, rhetorical topoi, motifs, topics, plots or their variants, and quotations) – and intertextual connectivity "/>
        <entry
            de=", gemessen an der Anzahl der Intertext-Knoten, in denen der Text als Objekt auftritt. Da die Phänomendichte einer ausgeprägten rechtsschiefen Verteilung folgt und die intertextuelle Vernetzung eine schwächere, aber gleichgerichtete Tendenz zeigt, werden beide Rohwerte logarithmisch transformiert ("
            en=", measured by the number of intertext nodes in which the text appears as the object. Since phenomenon density follows a pronounced right-skewed distribution and intertextual connectivity shows a weaker but similarly directed tendency, both raw values are log-transformed ("/>
        <entry
            de="); zugleich bildet diese Skalierung die Annahme ab, dass der Erkenntniswert jeder zusätzlichen Einheit mit wachsender Belegdichte abnimmt. Als Normalisierungsankerpunkt dient der Median der exemplarisch analysierten Texte; durch Division durch das Doppelte des log-transformierten Medians wird dieser Ankerpunkt auf 0,5 gesetzt."
            en="); this scaling also reflects the assumption that the informational value of each additional unit decreases as attestation density grows. The median of the texts analysed as examples serves as the normalization anchor point; dividing by twice the log-transformed median sets this anchor point to 0.5."/>
        <entry
            de="Die Phänomendichte wird mit drei Vierteln gewichtet, da sie das inhaltliche Analysevolumen unmittelbar abbildet; die intertextuelle Vernetzung fließt ergänzend zu einem Viertel ein."
            en="Phenomenon density is weighted at three-quarters, since it directly reflects the volume of content analysed; intertextual connectivity contributes the remaining quarter."/>
        <entry
            de="Statistik 2: Durchschnittliche intertextuelle Beziehungen und gemeinsame Phänomene"
            en="Statistics 2: Average Intertextual Relations and Shared Phenomena"/>
        <entry
            de="Wie viele intertextuelle Relationen verbinden einen Text im Durchschnitt mit anderen? Und wie viele Phänomene teilt ein Text im Schnitt mit seinen intertextuell verbundenen Texten?"
            en="On average, how many intertextual relations connect a text to others? And on average, how many phenomena does a text share with the texts it is intertextually connected to?"/>
        <entry de="Statistik 3: Intertextuelle Beziehungen und Textähnlichkeiten"
            en="Statistics 3: Intertextual Relationships and Text Similarities"/>
        <entry
            de="Welche intertextuellen Relationen verbinden die meisten Phänomene? Sichtbar wird, zwischen welchen Texten die reichhaltigsten impliziten Ähnlichkeiten bestehen – unabhängig von expliziten Referenzen."
            en="Which intertextual relations connect the most phenomena? This reveals which texts have the richest implicit similarities – independent of explicit references."/>
        <entry de="Anzahl:" en="Number:"/>
        <entry de="Top 5" en="Top 5"/>
        <entry de="Top 10" en="Top 10"/>
        <entry de="Top 15" en="Top 15"/>
        <entry de="Top 20" en="Top 20"/>
        <entry de="Top 30" en="Top 30"/>
        <entry de="Top 50" en="Top 50"/>
        <entry de="Top 100" en="Top 100"/>
        <entry de="Top 3 pro Typ" en="Top 3 per Type"/>
        <entry de="Top 5 pro Typ" en="Top 5 per Type"/>
        <entry de="Top 10 pro Typ" en="Top 10 per Type"/>
        <entry de="Beziehungstyp:" en="Relation Type:"/>
        <entry de="Nur zwischen Rezeptionszeugnissen" en="Only Between Reception Testimonies"/>
        <entry de="Nur zwischen Rezeptionszeugnissen und Fragmenten"
            en="Only Between Reception Testimonies and Fragments"/>
        <entry de="Statistik 4: Phänomene als Grundlage intertextueller Relationen"
            en="Statistics 4: Phenomena as the Basis of Intertextual Relations"/>
        <entry
            de="Welche Phänomene sind am häufigsten ausschlaggebend für intertextuelle Relationen zwischen Sappho-Fragmenten und Rezeptionszeugnissen sowie zwischen Fragmenten und Rezeptionszeugnissen untereinander?"
            en="Which phenomena are most often decisive for intertextual relations between Sappho fragments and reception testimonies, as well as between fragments and reception testimonies among themselves?"/>
        <entry de="Phänomentypen als Basis für intertextuelle Beziehungen"
            en="Phenomenon Types as a Basis for Intertextual Relationships"/>
        <entry de="Kookkurrenzen von Einzelphänomenen" en="Co-occurrences of Individual Phenomena"/>
        <entry
            de="Im inneren Ring sind die Phänomentypen, im äußeren die einzelnen Phänomene. Die Segmentbreite gibt deren Häufigkeit an. Die Sehnen in der Mitte verbinden Phänomene, die besonders häufig gemeinsam in intertextuellen Relationen auftreten – Breite und Deckkraft skalieren mit der Kookkurrenzstärke."
            en="The inner ring shows the phenomenon types, the outer ring the individual phenomena. Segment width indicates their frequency. The chords in the middle connect phenomena that particularly often occur together in intertextual relations – width and opacity scale with co-occurrence strength."/>
        <entry de="Phänomene im Diagramm:" en="Phenomena in the Chart:"/>
        <entry de="Häufigste Phänomen-Kombinationen" en="Most Frequent Phenomenon Combinations"/>
        <entry de="Statistik 5: Alle Phänomene im Vergleich" en="Statistics 5: All Phenomena Compared"/>
        <entry
            de="Welche Phänomene werden in Sappho-Fragmenten sowie in Rezeptionszeugnissen aktualisiert – und wo liegen die auffälligsten Übereinstimmungen oder Verschiebungen?"
            en="Which phenomena are actualized in Sappho fragments as well as in reception testimonies – and where are the most striking correspondences or shifts?"/>
        <entry de="Sappho-Fragmente mit Annotationen" en="Sappho Fragments with Annotations"/>
        <entry de="Analysierte Rezeptionszeugnisse" en="Analysed Reception Testimonies"/>
        <entry de="Sappho-Fragmente" en="Sappho Fragments"/>
        <entry de="Überblick (Top-N)" en="Overview (Top N)"/>
        <entry de="Nach Phänomentyp" en="By Phenomenon Type"/>
        <entry de="Statistik 6: Phänomene nach Fragment-Referenz"
            en="Statistics 6: Phenomena by Fragment Reference"/>
        <entry
            de="Welche Phänomene werden in Rezeptionszeugnissen, die auf bestimmte Fragmente Bezug nehmen, übernommen, welche ausgelassen – und welche kommen neu hinzu?"
            en="Which phenomena are adopted in reception testimonies that refer to specific fragments, which are omitted – and which are newly added?"/>
        <entry de="Referenziertes Fragment:" en="Referenced Fragment:"/>
        <entry de="— Fragment wählen —" en="— Select Fragment —"/>
        <entry de="Statistik 7: Phänomene im Laufe der Zeit" en="Statistics 7: Phenomena Over Time"/>
        <entry
            de="Wie verteilen sich konkrete Phänomene über die Zeit? Die Blasengröße zeigt, in wie vielen Rezeptionszeugnissen eines Jahrzehnts ein Phänomen annotiert ist; die Farbe kennzeichnet den Phänomentyp."
            en="How are specific phenomena distributed over time? Bubble size shows in how many reception testimonies of a decade a phenomenon is annotated; colour indicates the phenomenon type."/>
        <entry de="Statistik 8: Phänomene nach Gattung" en="Statistics 8: Phenomena by Genre"/>
        <entry
            de="Welche Phänomene dominieren in welcher Gattung? Die Farbintensität der Zellen zeigt die Häufigkeit innerhalb jeder Gattung; die Farbe kennzeichnet den Phänomentyp."
            en="Which phenomena dominate in which genre? The colour intensity of the cells shows the frequency within each genre; colour indicates the phenomenon type."/>
        <entry de="Nach Gattung" en="By Genre"/>
        <entry de="Statistik 9: Stoff-Komponenten" en="Statistics 9: Plot Components"/>
        <entry
            de="Welche Phänomene treten gemeinsam mit einer bestimmten Stoffvariante auf? Der innere Ring zeigt die Phänomentypen, der äußere Ring die einzelnen Phänomene; die Segmentbreite entspricht der relativen Häufigkeit."
            en="Which phenomena occur together with a particular plot variant? The inner ring shows the phenomenon types, the outer ring the individual phenomena; segment width corresponds to relative frequency."/>
        <entry de="Stoffvariante:" en="Plot Variant:"/>
        <entry de="— Stoffvariante wählen —" en="— Select Plot Variant —"/>
        <entry de="Anzeigen:" en="Display:"/>
        <entry de="Statistik 10: Personenreferenzen und Figuren"
            en="Statistics 10: References to Persons and Characters"/>
        <entry
            de="Welche Personen und Personentypen werden in Sappho-Fragmenten sowie in Rezeptionszeugnissen besonders häufig nicht nur referenziert, sondern treten auch als Figuren auf? Der Vergleich zeigt pro Person bzw. Personentyp die Referenz- und Figurenhäufigkeit."
            en="Which persons and person types are, in Sappho fragments as well as in reception testimonies, particularly often not only referenced but also appear as characters? The comparison shows, per person or person type, the frequency of reference and of appearance as a character."/>
        <entry de="Filter:" en="Filter:"/>
        <entry de="Alle Personenreferenzen" en="All References to Persons"/>
        <entry de="Nur auch als Figur" en="Only Also as a Character"/>
        <entry de="Referenzen in Sappho-Fragmenten" en="References in Sappho Fragments"/>
        <entry de="Figuren in Sappho-Fragmenten" en="Characters in Sappho Fragments"/>
        <entry de="Referenzen in Rezeptionszeugnissen" en="References in Reception Testimonies"/>
        <entry de="Figuren in Rezeptionszeugnissen" en="Characters in Reception Testimonies"/>
        <entry de="Statistik 11: Werkreferenzen und Zitate"
            en="Statistics 11: References to Works and Quotations"/>
        <entry de="Welche Werke werden in den " en="Which works are, among the "/>
        <entry de=" analysierten Rezeptionszeugnissen nicht nur referenziert, sondern auch zitiert?"
            en=" analysed reception testimonies, not only referenced but also quoted?"/>
        <entry de="Nur referenziert" en="Only Referenced"/>
        <entry de="Referenziert und zitiert" en="Referenced and Quoted"/>
        <entry de="Statistik 12: Genderspezifische Analysen" en="Statistics 12: Gender-Specific Analyses"/>
        <entry
            de="Wie sieht die Geschlechterverteilung aus – insgesamt, im Zeitverlauf, nach Gattungen und nach Phänomenen? Die Gender-Angaben stammen von Wikidata, sind binär und zumeist keine Selbstidentifikationen. Für die Phänomene wurden außerdem nur die Autor_innen der exemplarisch analysierten Rezeptionszeugnisse berücksichtigt."
            en="What does the gender distribution look like – overall, over time, by genre, and by phenomenon? The gender data comes from Wikidata, is binary, and is mostly not self-identification. For the phenomena, only the authors of the reception testimonies analysed as examples were also taken into account."/>
        <entry de="Anzeige:" en="Display:"/>
        <entry de="Gestapelt (absolut)" en="Stacked (absolute)"/>
        <entry de="Prozentualer Anteil" en="Percentage Share"/>
        <entry de="Statistik 13: Popularitätsanalysen mit Wiki-Metriken"
            en="Statistics 13: Popularity Analyses Using Wiki Metrics"/>
        <entry
            de="Wie populär sind Autor_innen von deutschsprachigen Sappho-Rezeptionszeugnissen im Wikiversum – und wie präsent sind sie im Korpus? QRank erstellt eine Rangliste von Wikidata-Einträgen, indem es die Seitenaufrufe aus Wikipedia, Wikispecies, Wikibooks, Wikiquote und weiteren Wikimedia-Projekten zusammenführt. Sitelinks sind die Wikipedia-Sprachversionen von Artikeln. Die Korpuspräsenz gibt an, mit wie vielen Rezeptionszeugnissen eine Person im Korpus vertreten ist."
            en="How popular are authors of German-language Sappho reception testimonies across the wiki universe – and how present are they in the corpus? QRank ranks Wikidata entries by combining page views from Wikipedia, Wikispecies, Wikibooks, Wikiquote, and other Wikimedia projects. Sitelinks are the Wikipedia language versions of articles. Corpus presence indicates how many reception testimonies a person is represented by in the corpus."/>
        <entry de="QRank vs. Korpuspräsenz" en="QRank vs. Corpus Presence"/>
        <entry
            de="Jeder Punkt ist ein_e Autor_in. Die X-Achse zeigt die Korpuspräsenz (Anzahl der Rezeptionszeugnisse im Korpus), die Y-Achse den QRank (Wiki-Popularität)."
            en="Each point is an author. The X-axis shows corpus presence (number of reception testimonies in the corpus), the Y-axis shows QRank (wiki popularity)."/>
        <entry de="Top-Autor_innen nach QRank" en="Top Authors by QRank"/>
        <entry de="QRank (normalisiert)" en="QRank (normalized)"/>
        <entry de="Korpuspräsenz (normalisiert)" en="Corpus presence (normalized)"/>
        <entry de="Sitelinks vs. Korpuspräsenz" en="Sitelinks vs. Corpus Presence"/>
        <entry
            de="Jeder Punkt ist ein_e Autor_in. Die X-Achse zeigt die Korpuspräsenz, die Y-Achse die Anzahl der Sitelinks (Wikipedia-Sprachversionen)."
            en="Each point is an author. The X-axis shows corpus presence, the Y-axis shows the number of sitelinks (Wikipedia language versions)."/>
        <entry de="Sitelinks-Verteilung" en="Sitelinks Distribution"/>
        <entry de="Sitelinks (normalisiert)" en="Sitelinks (normalized)"/>
        <entry de="Top-Autor_innen nach Sitelinks" en="Top Authors by Sitelinks"/>

        <!-- toc.xsl -->
        <entry de="Jahr:" en="Year:"/>
        <entry de="Abspielen" en="Play"/>
        <entry de="Das Fenster ist zu klein, um die Tabelle darstellen zu können."
            en="The window is too small to display the table."/>
        <entry de="Lyrik" en="Poetry"/>
        <entry de="Prosa" en="Prose"/>
        <entry de="Drama" en="Drama"/>
        <entry de="Sonstige" en="Other"/>
        <entry de="Online" en="Online"/>
        <entry de="Entstehungsjahr" en="Year of Creation"/>
        <entry de="Publikations-/Aufführungsjahr" en="Year of Publication/Performance"/>
        <entry de="Titel" en="Title"/>
        <entry de="Enthalten in" en="Contained In"/>
        <entry de="Autor_in" en="Author"/>
        <entry de="Gattung" en="Genre"/>
        <entry de="Publikations-/Aufführungsort" en="Place of Publication/Performance"/>
        <entry de="Verlag/Druckerei" en="Publisher/Printer"/>
        <entry de="Digitalisat" en="Digitized Copy"/>
        <entry de="Link" en="Link"/>

        <!-- sappho-fragments.xsl / bibl-entities.xsl / reception-entities.xsl -->
        <entry de="Ergebnisse der exemplarischen Analyse" en="Results of the Exemplary Analysis"/>
        <entry de="Zur Erläuterung der Analyse" en="On the Analysis Notes"/>
        <entry de="Personenreferenzen" en="References to Persons"/>
        <entry de="Figuren" en="Characters"/>
        <entry de="Werkreferenzen" en="References to Works"/>
        <entry de="Zitate" en="Quotations"/>
        <entry de="Textpassagen" en="Text Passages"/>
        <entry de="Phrasen" en="Phrases"/>
        <entry de="Intertextuelle" en="Intertextual"/>
        <entry de="Beziehungen mit …" en="Relationships with …"/>
        <entry de="Interne ID" en="Internal ID"/>
        <entry de="Typ" en="Type"/>
        <entry de="Werk" en="Work"/>
        <entry de="Autorin" en="Author"/>
        <entry de="Publ.-/Aufführungsjahr" en="Year of Publ./Performance"/>
        <entry de="Publ.-/Aufführungsort" en="Place of Publ./Performance"/>
        <entry de="Ein Werk in der Datenbank:" en="One work in the database:"/>
        <entry de=" Werke in der Datenbank:" en=" works in the database:"/>
        <entry de="Geboren" en="Born"/>
        <entry de="Gestorben" en="Died"/>
        <entry de="Enthält" en="Contains"/>
        <entry de="Wikidata-Eintrag öffnen" en="Open Wikidata Entry"/>
        <entry de="zuletzt aktualisiert am " en="last updated on "/>

        <!-- reception-entities.xsl -->
        <entry de="Vokabular zur literarischen Sappho-Rezeption"
            en="Vocabulary on the Literary Reception of Sappho"/>
        <entry de="Vorkommnis in:" en="Occurs in:"/>
        <entry de="Namensvarianten:" en="Name Variants:"/>
        <entry de="Gewicht" en="Weight"/>
        <entry
            de="Alle (im weitesten Sinne) intertextuellen Beziehungen zwischen Sappho-Fragmenten und den exemplarisch analysierten Rezeptionszeugnissen sowie zwischen Fragmenten und Rezeptionszeugnissen untereinander."
            en="All intertextual relationships (in the broadest sense) between Sappho fragments and the reception testimonies analysed as examples, as well as among the reception testimonies themselves."/>
        <entry de="Mehr Informationen zur exemplarischen Analyse sind "
            en="More information on the exemplary analysis can be found "/>
        <entry de=" zu finden. Statistische Auswertungen werden "
            en=". Statistical analyses are compiled "/>
        <entry de=" aufbereitet; eine Netzwerkvisualisierung aller Daten ist "
            en="; a network visualization of all data is available "/>
        <entry de=" verfügbar." en="."/>
        <entry de="… in den exemplarisch analysierten Rezeptionszeugnissen und Sappho-Fragmenten."
            en="… in the reception testimonies and Sappho fragments analysed as examples."/>
        <entry de="Für eine hierarchische Ansicht siehe das "
            en="For a hierarchical view, see the "/>
        <entry de=". Mehr Informationen zur exemplarischen Analyse sind "
            en=". More information on the exemplary analysis can be found "/>
        <entry de="Fragment (Sappho)" en="Fragment (Sappho)"/>
        <entry de="Rezeptionszeugnis" en="Reception Testimony"/>
        <entry
            de="Hier werden nur die k stärksten Verbindungen pro Knoten sowie ein verbindender Maximum-Spanning-Tree visualisiert (Standard: k = 2)."
            en="Here, only the k strongest connections per node are visualized, along with a connecting maximum spanning tree (default: k = 2)."/>
        <entry
            de="Die Definitionen und Anmerkungen zu den einzelnen Konzepten sind maschinell aus dem Deutschen übersetzt."
            en="The definitions and notes on the individual concepts are machine-translated from German."/>
        <entry de="Öffnen" en="Open"/>
        <entry de=" Vorkommnis" en=" Occurrence"/>
        <entry de=" Vorkommnisse" en=" Occurrences"/>
        <entry de="Top Vorkommnisse" en="Top Occurrences"/>
        <entry de="Gemeinsame Werkreferenz:" en="Shared Reference to a Work:"/>
        <entry de="Gemeinsame Werkreferenzen:" en="Shared References to Works:"/>
        <entry de="Werkreferenz:" en="Reference to a Work:"/>
        <entry de="Werkreferenzen:" en="References to Works:"/>
        <entry de=" Gemeinsamkeit" en=" Commonality"/>
        <entry de=" Gemeinsamkeiten" en=" Commonalities"/>
        <entry de="Gemeinsames Motiv:" en="Shared Motif:"/>
        <entry de="Gemeinsame Motive:" en="Shared Motifs:"/>
        <entry de="Gemeinsames Thema:" en="Shared Topic:"/>
        <entry de="Gemeinsame Themen:" en="Shared Topics:"/>
        <entry de="Gemeinsamer Stoff:" en="Shared Plot Variant:"/>
        <entry de="Gemeinsame Stoffe:" en="Shared Plot Variants:"/>
        <entry de="Gemeinsame Personenreferenz:" en="Shared Reference to a Person:"/>
        <entry de="Gemeinsame Personenreferenzen:" en="Shared References to Persons:"/>
        <entry de="Gemeinsame Figur:" en="Shared Character:"/>
        <entry de="Gemeinsame Figuren:" en="Shared Characters:"/>
        <entry de="Gemeinsame Ortsreferenz:" en="Shared Reference to a Place:"/>
        <entry de="Gemeinsame Ortsreferenzen:" en="Shared References to Places:"/>
        <entry de="Gemeinsames Zitat:" en="Shared Quotation:"/>
        <entry de="Gemeinsame Zitate:" en="Shared Quotations:"/>
        <entry de="Gemeinsamer Topos:" en="Shared Topos:"/>
        <entry de="Gemeinsame Topoi:" en="Shared Topoi:"/>

        <!-- imprint.xsl -->
        <entry de="Impressum" en="Imprint"/>
        <entry de="Intertextuelle Beziehung mit " en="Intertextual relation with "/>
        <entry de="Intertextuelle Beziehungen zwischen Sappho-Fragmenten" en="Intertextual Relations between Sappho Fragments"/>
        <entry de="Intertextuelle Beziehungen zwischen Rezeptionszeugnissen und Sappho-Fragmenten" en="Intertextual Relations between Reception Testimonies and Sappho Fragments"/>
        <entry de="Intertextuelle Beziehungen zwischen Rezeptionszeugnissen" en="Intertextual Relations between Reception Testimonies"/>
    </xsl:variable>

    <xsl:key name="i18n-key" match="entry" use="@de"/>

    <xsl:function name="i18n:t" as="xs:string">
        <xsl:param name="de" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$lang != 'en'">
                <xsl:sequence select="$de"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="hit" select="key('i18n-key', $de, $i18n:strings)"/>
                <xsl:sequence select="
                        if (exists($hit))
                        then
                            string($hit[1]/@en)
                        else
                            $de"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>