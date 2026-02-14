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
        if (! input) return;
        input.value = url;
        input.focus();
    };
    
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
    };
    
    // ---- Globale Funktionen für onclick ----
    
    window.loadExample = function (type) {
        var editor = document.getElementById("queryEditor");
        if (! editor) return;
        editor.value = examples[type] || "";
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
        
        // queryBindings liefert ein Result-Objekt (mit .variables und .toArray()).
        window.myEngine.queryBindings(query, {
            sources:[ {
                type: "file", value: source, mediaType: "text/turtle"
            }],
        }).then(function (result) {
            var variables = (result && result.variables) ? result.variables:[];
            
            // result.toArray() sollte ein Array von Bindings liefern
            return result.toArray().then(function (bindings) {
                return {
                    bindings: bindings, variables: variables
                };
            });
        }).then(function (data) {
            var bindings = data.bindings;
            var variables = data.variables;
            
            // Robustheit: bindings MUSS ein Array sein
            if (! isArray(bindings)) bindings =[];
            
            window.currentResults = bindings;
            
            if (bindings.length === 0) {
                resultsDiv.innerHTML =
                '<div class="status success">✓ Query erfolgreich, aber keine Ergebnisse gefunden.</div>';
                return;
            }
            
            // Robustheit: variables holen
            if (! variables || ! variables.length) {
                if (bindings[0] && bindings[0].variables) {
                    variables = bindings[0].variables;
                }
            }
            
            // Letzter Fallback: Keys aus dem Binding (Map)
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
            
            // Wenn immer noch keine Variablen gefunden: Abbruch mit Hinweis
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
                            // v ist i.d.R. ein RDFJS Variable-Objekt
                            term = binding. get (v);
                            
                            // Fallback, falls v.value gebraucht wird
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
        
        // Fallback: Variablen aus Keys ziehen, wenn nicht vorhanden
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
    
    // Ctrl/Cmd+Enter nur, wenn DOM bereit ist
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