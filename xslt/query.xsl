<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="#all">
    <xsl:output encoding="UTF-8" media-type="text/html" method="xhtml" version="1.0" indent="yes"
        omit-xml-declaration="yes"/>
    <xsl:import href="./partials/html_navbar.xsl"/>
    <xsl:import href="./partials/html_head.xsl"/>
    <xsl:import href="./partials/html_footer.xsl"/>

    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:value-of select='"Sappho Digital Query Service"'/>
        </xsl:variable>

        <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"/>
                </xsl:call-template>
            </head>
            <body class="page">
                <div class="hfeed site" id="page">
                    <xsl:call-template name="nav_bar"/>

                    <div class="sparql-container">
                        <div class="card-header">
                            <h1>
                                <xsl:value-of select="$doc_title"/>
                            </h1>
                        </div>
                        <div class="sparql-content">
                            <div class="section">
                                <div class="section-title">Datenquelle</div>
                                <div class="data-source">
                                    <input type="text" id="dataSource"
                                        value="https://github.com/laurauntner/sappho-digital/blob/main/data/rdf/sappho-reception_asserted-and-inferred.ttl"
                                    />
                                </div>
                            </div>

                            <div class="section">
                                <div class="section-title">SPARQL Query</div>
                                <div class="query-container">
                                    <textarea id="queryEditor"
                                        placeholder="Gib hier deine SPARQL-Query ein...">PREFIX rdf:
                                        &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt; PREFIX
                                        rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt; SELECT
                                        ?subject ?predicate ?object WHERE { ?subject ?predicate
                                        ?object . } LIMIT 100</textarea>
                                </div>

                                <div class="examples">
                                    <div class="section-title"
                                        style="width: 100%; margin-bottom: 5px;"
                                        >Beispiel-Queries:</div>
                                    <button class="example-btn" onclick="loadExample('all')">Alle
                                        Tripel</button>
                                    <button class="example-btn" onclick="loadExample('types')">Alle
                                        Typen</button>
                                    <button class="example-btn" onclick="loadExample('count')"
                                        >Anzahl Tripel</button>
                                    <button class="example-btn" onclick="loadExample('properties')"
                                        >Verwendete Properties</button>
                                </div>
                            </div>

                            <div class="controls">
                                <button id="executeBtn" class="sparql-btn" onclick="executeQuery()"
                                    >▶ Query ausführen</button>
                                <button id="clearBtn" class="sparql-btn" onclick="clearResults()"
                                    >Ergebnisse löschen</button>
                                <div class="export-controls hidden" id="exportControls">
                                    <button class="export-btn" onclick="exportResults('csv')">📥 CSV
                                        Export</button>
                                    <button class="export-btn" onclick="exportResults('json')">📥
                                        JSON Export</button>
                                </div>
                            </div>

                            <!-- XHTML-sicher: nicht selbstschließend -->
                            <div id="results"/>
                        </div>
                    </div>

                    <xsl:call-template name="html_footer"/>
                </div>

                <!-- XHTML-sicher: nicht selbstschließend -->
                <script src="https://cdn.jsdelivr.net/npm/@comunica/query-sparql/dist/comunica-browser.js"/>
                <script>
                    const QueryEngine = window.Comunica.QueryEngine;
                    const myEngine = new QueryEngine();
                    let currentResults = [];

                    const examples = {
                        all: `PREFIX rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt;
PREFIX rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt;

SELECT ?subject ?predicate ?object
WHERE {
  ?subject ?predicate ?object .
}
LIMIT 100`,
                        types: `PREFIX rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt;

SELECT DISTINCT ?type
WHERE {
  ?subject rdf:type ?type .
}`,
                        count: `SELECT (COUNT(*) as ?count)
WHERE {
  ?s ?p ?o .
}`,
                        properties: `SELECT DISTINCT ?property
WHERE {
  ?s ?property ?o .
}
ORDER BY ?property`
                    };

                    function loadExample(type) {
                        document.getElementById('queryEditor').value = examples[type];
                    }

                    async function executeQuery() {
                        const query = document.getElementById('queryEditor').value;
                        const source = document.getElementById('dataSource').value;
                        const resultsDiv = document.getElementById('results');
                        const executeBtn = document.getElementById('executeBtn');

                        executeBtn.disabled = true;
                        resultsDiv.innerHTML = '&lt;div class="status loading"&gt;⏳ Query wird ausgeführt...&lt;/div&gt;';
                        document.getElementById('exportControls').classList.add('hidden');

                        try {
                            const bindingsStream = await myEngine.queryBindings(query, {
                                sources: [source],
                            });

                            const bindings = await bindingsStream.toArray();
                            currentResults = bindings;

                            if (bindings.length === 0) {
                                resultsDiv.innerHTML = '&lt;div class="status success"&gt;✓ Query erfolgreich, aber keine Ergebnisse gefunden.&lt;/div&gt;';
                                executeBtn.disabled = false;
                                return;
                            }

                            const variables = bindings[0].variables;

                            let tableHTML = `
                                &lt;div class="status success"&gt;✓ ${bindings.length} Ergebnis${bindings.length !== 1 ? 'se' : ''} gefunden&lt;/div&gt;
                                &lt;div class="results-table-container"&gt;
                                    &lt;table class="sparql-table"&gt;
                                        &lt;thead&gt;
                                            &lt;tr class="sparql-tr"&gt;
                                                ${variables.map(v =&gt; `&lt;th class="sparql-th"&gt;${v.value}&lt;/th&gt;`).join('')}
                                            &lt;/tr&gt;
                                        &lt;/thead&gt;
                                        &lt;tbody&gt;
                            `;

                            bindings.forEach(binding =&gt; {
                                tableHTML += '&lt;tr class="sparql-tr"&gt;';
                                variables.forEach(variable =&gt; {
                                    const term = binding.get(variable);
                                    if (term) {
                                        const className = term.termType === 'NamedNode' ? 'uri' : 'literal';
                                        const value = term.value;
                                        tableHTML += `&lt;td class="sparql-td ${className}"&gt;${value}&lt;/td&gt;`;
                                    } else {
                                        tableHTML += '&lt;td class="sparql-td"&gt;-&lt;/td&gt;';
                                    }
                                });
                                tableHTML += '&lt;/tr&gt;';
                            });

                            tableHTML += `
                                        &lt;/tbody&gt;
                                    &lt;/table&gt;
                                &lt;/div&gt;
                            `;

                            resultsDiv.innerHTML = tableHTML;
                            document.getElementById('exportControls').classList.remove('hidden');

                        } catch (error) {
                            resultsDiv.innerHTML = `&lt;div class="status error"&gt;❌ Fehler: ${error.message}&lt;/div&gt;`;
                        }

                        executeBtn.disabled = false;
                    }

                    function clearResults() {
                        document.getElementById('results').innerHTML = '';
                        document.getElementById('exportControls').classList.add('hidden');
                        currentResults = [];
                    }

                    function exportResults(format) {
                        if (currentResults.length === 0) return;

                        const variables = currentResults[0].variables;

                        if (format === 'csv') {
                            let csv = variables.map(v =&gt; v.value).join(',') + '\n';

                            currentResults.forEach(binding =&gt; {
                                const row = variables.map(variable =&gt; {
                                    const term = binding.get(variable);
                                    const value = term ? term.value : '';
                                    return `"${value.replace(/"/g, '""')}"`;
                                }).join(',');
                                csv += row + '\n';
                            });

                            downloadFile(csv, 'results.csv', 'text/csv');

                        } else if (format === 'json') {
                            const json = currentResults.map(binding =&gt; {
                                const obj = {};
                                variables.forEach(variable =&gt; {
                                    const term = binding.get(variable);
                                    obj[variable.value] = term ? term.value : null;
                                });
                                return obj;
                            });

                            downloadFile(JSON.stringify(json, null, 2), 'results.json', 'application/json');
                        }
                    }

                    function downloadFile(content, filename, mimeType) {
                        const blob = new Blob([content], { type: mimeType });
                        const url = URL.createObjectURL(blob);
                        const a = document.createElement('a');
                        a.href = url;
                        a.download = filename;
                        document.body.appendChild(a);
                        a.click();
                        document.body.removeChild(a);
                        URL.revokeObjectURL(url);
                    }

                    document.getElementById('queryEditor').addEventListener('keydown', function(e) {
                        if ((e.ctrlKey || e.metaKey) &amp;&amp; e.key === 'Enter') {
                            executeQuery();
                        }
                    });
                </script>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>
