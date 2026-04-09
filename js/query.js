(function () {
    window.currentResults =[];
    
    function ensureComunica() {
        if (! window.Comunica || ! window.Comunica.QueryEngine) {
            throw new Error(
            "Comunica wurde nicht geladen. Prüfe, ob der Comunica <script>-Tag wirklich geladen wird (nicht selbstschließend) und ob die URL stimmt.");
        }
        if (! window.myEngine) {
            window.myEngine = new window.Comunica.QueryEngine();
        }
    }
    
    function escapeHtml(str) {
        str = String(str);
        return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
    }
    
    window.setDataSource = function (url) {
        const input = document.getElementById("dataSource");
        if (!input) return;
        input.value = url;
        input.focus();
    
        document.querySelectorAll(".data-source-suggestions .example-btn").forEach(function(btn) {
            btn.style.removeProperty('background-color');
            btn.style.removeProperty('color');
            btn.style.removeProperty('border-color');
        });
    
        event.target.style.setProperty('background-color', 'rgb(94, 23, 235)', 'important');
        event.target.style.setProperty('color', 'white', 'important');
        event.target.style.setProperty('border-color', 'rgb(94, 23, 235)', 'important');
    };
    
    function setActiveDefaults() {
        // "Alle Tripel" Button aktiv setzen
        var allBtn = document.querySelector('.examples .example-btn[onclick="loadExample(\'all\')"]');
        if (allBtn) {
            allBtn.style.setProperty('background-color', 'rgb(94, 23, 235)', 'important');
            allBtn.style.setProperty('color', 'white', 'important');
            allBtn.style.setProperty('border-color', 'rgb(94, 23, 235)', 'important');
        }
    
        // "Default (alle Daten)" Button aktiv setzen
        var defaultBtn = document.querySelector('.data-source-suggestions .example-btn[onclick*="sappho-reception.ttl"]');
        if (defaultBtn) {
            defaultBtn.style.setProperty('background-color', 'rgb(94, 23, 235)', 'important');
            defaultBtn.style.setProperty('color', 'white', 'important');
            defaultBtn.style.setProperty('border-color', 'rgb(94, 23, 235)', 'important');
        }
    }
    
    document.addEventListener("DOMContentLoaded", function () {
        setActiveDefaults();
    
        var editor = document.getElementById("queryEditor");
        if (!editor) return;
        editor.addEventListener("keydown", function (e) {
            if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
                window.executeQuery();
            }
        });
    });
    
    function downloadFile(content, filename, mimeType) {
        var blob = new Blob([content], {
            type: mimeType
        });
        var url = URL.createObjectURL(blob);
        var a = document.createElement("a");
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }
    
    function isArray(x) {
        return Object.prototype.toString.call(x) === "[object Array]";
    }
    
    // Beispielqueries
    var examples = {
        all:
        "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n\n" +
        "SELECT ?subject ?predicate ?object\n" +
        "WHERE {\n" +
        "  ?subject ?predicate ?object .\n" +
        "}\n" +
        "LIMIT 100",
        
        types:
        "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n\n" +
        "SELECT DISTINCT ?type\n" +
        "WHERE {\n" +
        "  ?subject rdf:type ?type .\n" +
        "}\n" +
        "ORDER BY ?type",
        
        count:
        "SELECT (COUNT(*) AS ?count)\n" +
        "WHERE {\n" +
        "  ?s ?p ?o .\n" +
        "}",
        
        properties:
        "SELECT DISTINCT ?property\n" +
        "WHERE {\n" +
        "  ?s ?property ?o .\n" +
        "}\n" +
        "ORDER BY ?property",

        phenomTopPersonRef:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  ?feat rdf:type intro:INT18_Reference .\n" +
        "  FILTER(CONTAINS(STR(?feat), \"/person_ref/\"))\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        phenomTopCharacter:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  ?feat rdf:type intro:INT_Character .\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        phenomTopMotif:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  ?feat rdf:type intro:INT_Motif .\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        phenomTopTopos:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  ?feat rdf:type intro:INT_Topos .\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        phenomTopPlace:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  ?feat rdf:type intro:INT18_Reference .\n" +
        "  FILTER(CONTAINS(STR(?feat), \"/place_ref/\"))\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        phenomTopTopic:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  ?feat rdf:type intro:INT_Topic .\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        plotComponents:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  ?feat rdf:type intro:INT_Plot .\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        workRefs:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  ?feat rdf:type intro:INT18_Reference .\n" +
        "  FILTER(CONTAINS(STR(?feat), \"/work_ref/\"))\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        textPassages:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?tp ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R30_hasTextPassage ?tp .\n" +
        "  ?tp rdf:type intro:INT21_TextPassage .\n" +
        "  OPTIONAL { ?tp rdfs:label ?label . }\n" +
        "}\n" +
        "GROUP BY ?tp ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        phenomSappho:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?feat ?label (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 intro:R18_showsActualization ?act .\n" +
        "  ?act intro:R17_actualizesFeature ?feat .\n" +
        "  VALUES ?featType { intro:INT18_Reference intro:INT_Motif intro:INT_Character intro:INT_Topos intro:INT_Topic intro:INT_Plot }\n" +
        "  ?feat rdf:type ?featType .\n" +
        "  ?feat rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?feat ?label\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        authorTopWorks:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX ecrm:  <http://erlangen-crm.org/current/>\n\n" +
        "SELECT ?person ?authorLabel (COUNT(DISTINCT ?f2) AS ?anzahl)\n" +
        "WHERE {\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f28 lrmoo:R17_created ?f2 .\n" +
        "  ?f28 ecrm:P14_carried_out_by ?person .\n" +
        "  FILTER(CONTAINS(STR(?person), \"/author_\"))\n" +
        "  ?person rdfs:label ?authorLabel .\n" +
        "}\n" +
        "GROUP BY ?person ?authorLabel\n" +
        "ORDER BY DESC(?anzahl)\n" +
        "LIMIT 20",

        intertextDocCount:
        "PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
        "PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>\n" +
        "PREFIX lrmoo: <http://iflastandards.info/ns/lrm/lrmoo/>\n" +
        "PREFIX intro: <https://w3id.org/lso/intro/currentbeta#>\n\n" +
        "SELECT ?f2 ?label (COUNT(DISTINCT ?node) AS ?anzahlRelationen)\n" +
        "WHERE {\n" +
        "  ?node rdf:type intro:INT31_IntertextualRelation .\n" +
        "  ?node intro:R24_hasRelatedEntity ?f2 .\n" +
        "  ?f2 rdf:type lrmoo:F2_Expression .\n" +
        "  FILTER(CONTAINS(STR(?f2), \"/bibl_\") && !CONTAINS(STR(?f2), \"bibl_sappho_\"))\n" +
        "  ?f2 rdfs:label ?label .\n" +
        "}\n" +
        "GROUP BY ?f2 ?label\n" +
        "ORDER BY DESC(?anzahlRelationen)\n" +
        "LIMIT 20",
    };
        
    window.loadExample = function (type) {
        var editor = document.getElementById("queryEditor");
        if (!editor) return;
        editor.value = examples[type] || "";
    
        document.querySelectorAll(".examples .example-btn").forEach(function(btn) {
            btn.style.removeProperty('background-color');
            btn.style.removeProperty('color');
            btn.style.removeProperty('border-color');
            btn.classList.remove("active");
        });
    
        event.target.style.setProperty('background-color', 'rgb(94, 23, 235)', 'important');
        event.target.style.setProperty('color', 'white', 'important');
        event.target.style.setProperty('border-color', 'rgb(94, 23, 235)', 'important');
        event.target.classList.add("active");
    };
    
    window.executeQuery = function () {
        var queryEl = document.getElementById("queryEditor");
        var sourceEl = document.getElementById("dataSource");
        var resultsDiv = document.getElementById("results");
        var executeBtn = document.getElementById("executeBtn");
        var exportControls = document.getElementById("exportControls");
        
        if (! queryEl || ! sourceEl || ! resultsDiv || ! executeBtn || ! exportControls) {
            console.error(
            "Fehlende DOM-Elemente. Prüfe IDs: queryEditor, dataSource, results, executeBtn, exportControls");
            return;
        }
        
        var query = (queryEl.value || "").replace(/^\s+|\s+$/g, "");
        var source = (sourceEl.value || "").replace(/^\s+|\s+$/g, "");
        
        if (! query) {
            resultsDiv.innerHTML = '<div class="status error">❌ Bitte eine Query eingeben.</div>';
            return;
        }
        if (! source) {
            resultsDiv.innerHTML = '<div class="status error">❌ Bitte eine Datenquelle (URL) eingeben.</div>';
            return;
        }
        
        executeBtn.disabled = true;
        resultsDiv.innerHTML = '<div class="status loading">Query wird clientseitig ausgeführt … Bitte um etwas Geduld.</div>';
        exportControls.classList.add("hidden");
        
        try {
            ensureComunica();
        }
        catch (e) {
            resultsDiv.innerHTML = '<div class="status error">❌ Fehler: ' + escapeHtml(e.message) + "</div>";
            executeBtn.disabled = false;
            return;
        }
        
        window.myEngine.queryBindings(query, {
            sources:[ {
                type: "file", value: source, mediaType: "text/turtle"
            }],
        }).then(function (result) {
            var variables = (result && result.variables) ? result.variables:[];
            
            return result.toArray().then(function (bindings) {
                return {
                    bindings: bindings, variables: variables
                };
            });
        }).then(function (data) {
            var bindings = data.bindings;
            var variables = data.variables;
            
            if (! isArray(bindings)) bindings =[];
            
            window.currentResults = bindings;
            
            if (bindings.length === 0) {
                resultsDiv.innerHTML =
                '<div class="status success">✓ Query erfolgreich, aber keine Ergebnisse gefunden.</div>';
                return;
            }
            
            if (! variables || ! variables.length) {
                if (bindings[0] && bindings[0].variables) {
                    variables = bindings[0].variables;
                }
            }
            
            if (! variables || ! variables.length) {
                variables =[];
                try {
                    if (bindings[0] && typeof bindings[0].forEach === "function") {
                        bindings[0].forEach(function (_v, k) {
                            variables.push(k);
                        });
                    }
                }
                catch (e) {
                    variables =[];
                }
            }
            
            if (! variables || ! variables.length) {
                resultsDiv.innerHTML =
                '<div class="status error">❌ Konnte Ergebnis-Variablen nicht bestimmen (unerwartetes Ergebnisformat).</div>';
                return;
            }
            
            var html = "";
            html +=
            '<div class="status success">✓ ' +
            bindings.length +
            " Ergebnis" +
            (bindings.length !== 1 ? "se": "") +
            " gefunden</div>";
            
            html += '<div class="results-table-container">';
            html += '<table class="sparql-table">';
            html += '<thead><tr class="sparql-tr">';
            
            for (var i = 0; i < variables.length; i++) {
                var header = (variables[i] && variables[i].value) ? variables[i].value: String(variables[i]);
                html += '<th class="sparql-th">' + escapeHtml(header) + "</th>";
            }
            
            html += "</tr></thead><tbody>";
            
            for (var r = 0; r < bindings.length; r++) {
                var binding = bindings[r];
                html += '<tr class="sparql-tr">';
                
                for (var c = 0; c < variables.length; c++) {
                    var v = variables[c];
                    var term = null;
                    
                    try {
                        if (binding && typeof binding. get === "function") {
                            term = binding. get (v);
                            
                            if (! term && v && v.value) term = binding. get (v);
                        }
                    }
                    catch (e) {
                        term = null;
                    }
                    
                    if (term) {
                        var cls = term.termType === "NamedNode" ? "uri": "literal";
                        html += '<td class="sparql-td ' + cls + '">' + escapeHtml(term.value) + "</td>";
                    } else {
                        html += '<td class="sparql-td">-</td>';
                    }
                }
                
                html += "</tr>";
            }
            
            html += "</tbody></table></div>";
            
            resultsDiv.innerHTML = html;
            exportControls.classList.remove("hidden");
        }). catch (function (err) {
            var msg = err && err.message ? err.message: String(err);
            resultsDiv.innerHTML = '<div class="status error">❌ Fehler: ' + escapeHtml(msg) + "</div>";
            console.error(err);
        }). finally (function () {
            executeBtn.disabled = false;
        });
    };
    
    window.clearResults = function () {
        var resultsDiv = document.getElementById("results");
        var exportControls = document.getElementById("exportControls");
        if (resultsDiv) resultsDiv.innerHTML = "";
        if (exportControls) exportControls.classList.add("hidden");
        window.currentResults =[];
    };
    
    window.exportResults = function (format) {
        var results = window.currentResults;
        if (! results || results.length === 0) return;
        
        var variables = results[0] && results[0].variables ? results[0].variables: null;
        
        if (! variables || ! variables.length) {
            variables =[];
            try {
                results[0].forEach(function (_v, k) {
                    variables.push(k);
                });
            }
            catch (e) {
                variables =[];
            }
        }
        
        if (! variables || ! variables.length) return;
        
        if (format === "csv") {
            var csv = "";
            for (var i = 0; i < variables.length; i++) {
                var h = (variables[i] && variables[i].value) ? variables[i].value: String(variables[i]);
                csv += (i ? ",": "") + h;
            }
            csv += "\n";
            
            for (var r = 0; r < results.length; r++) {
                var binding = results[r];
                var row =[];
                
                for (var c = 0; c < variables.length; c++) {
                    var v = variables[c];
                    var term = null;
                    try {
                        term = binding. get (v);
                    }
                    catch (e) {
                        term = null;
                    }
                    var value = term ? String(term.value): "";
                    value = value.replace(/"/g, '""');
                    row.push('"' + value + '"');
                }
                
                csv += row.join(",") + "\n";
            }
            
            downloadFile(csv, "results.csv", "text/csv");
        } else if (format === "json") {
            var arr =[];
            
            for (var rr = 0; rr < results.length; rr++) {
                var b = results[rr];
                var obj = {
                };
                
                for (var cc = 0; cc < variables.length; cc++) {
                    var vv = variables[cc];
                    var key = (vv && vv.value) ? vv.value: String(vv);
                    var t = null;
                    try {
                        t = b. get (vv);
                    }
                    catch (e) {
                        t = null;
                    }
                    obj[key] = t ? t.value: null;
                }
                
                arr.push(obj);
            }
            
            downloadFile(JSON.stringify(arr, null, 2), "results.json", "application/json");
        }
    };
    
    document.addEventListener("DOMContentLoaded", function () {
        var editor = document.getElementById("queryEditor");
        if (! editor) return;
        
        editor.addEventListener("keydown", function (e) {
            if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
                window.executeQuery();
            }
        });
    });
})();