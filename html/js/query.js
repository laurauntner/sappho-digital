const QueryEngine = window.Comunica.QueryEngine;
const myEngine = new QueryEngine();
let currentResults =[];

const examples = {
    all: `PREFIX rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt;
    PREFIX rdfs: &lt; http://www.w3.org/2000/01/rdf-schema#&gt;
    
    SELECT ? subject ? predicate ? object
    WHERE { ? subject ? predicate ? object.
    }
    LIMIT 100 `,
    types: `PREFIX rdf: &lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#&gt;
    
    SELECT DISTINCT ? type
    WHERE { ? subject rdf: type ? type.
    }
    `,
    count: `SELECT (COUNT(*) as ?count)
    WHERE { ? s ? p ? o.
    }
    `,
    properties: `SELECT DISTINCT ?property
    WHERE { ? s ? property ? o.
    }
    ORDER BY ? property `
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
            sources:[source],
        });
        
        const bindings = await bindingsStream.toArray();
        currentResults = bindings;
        
        if (bindings.length === 0) {
            resultsDiv.innerHTML = '&lt;div class="status success"&gt;✓ Query erfolgreich, aber keine Ergebnisse gefunden.&lt;/div&gt;';
            executeBtn.disabled = false;
            return;
        }
        
        const variables = bindings[0].variables;
        
        let tableHTML = ` &lt; div class = "status success" &gt; ✓ $ {
            bindings.length
        }
        Ergebnis$ {
            bindings.length !== 1 ? 'se': ''
        }
        gefunden &lt; / div &gt; &lt; div class = "results-table-container" &gt; &lt; table class = "sparql-table" &gt; &lt; thead &gt; &lt; tr class = "sparql-tr" &gt;
        $ {
            variables.map(v = &gt; `&lt;th class="sparql-th"&gt;${v.value}&lt;/th&gt;`).join('')
        } &lt; / tr &gt; &lt; / thead &gt; &lt; tbody &gt;
        `;
        
        bindings.forEach(binding = &gt; {
            tableHTML += '&lt;tr class="sparql-tr"&gt;';
            variables.forEach(variable = &gt; {
                const term = binding. get (variable);
                if (term) {
                    const className = term.termType === 'NamedNode' ? 'uri': 'literal';
                    const value = term.value;
                    tableHTML += `&lt;td class="sparql-td ${className}"&gt;${value}&lt;/td&gt;`;
                } else {
                    tableHTML += '&lt;td class="sparql-td"&gt;-&lt;/td&gt;';
                }
            });
            tableHTML += '&lt;/tr&gt;';
        });
        
        tableHTML += ` &lt; / tbody &gt; &lt; / table &gt; &lt; / div &gt;
        `;
        
        resultsDiv.innerHTML = tableHTML;
        document.getElementById('exportControls').classList.remove('hidden');
    }
    catch (error) {
        resultsDiv.innerHTML = `&lt;div class="status error"&gt;❌ Fehler: ${error.message}&lt;/div&gt;`;
    }
    
    executeBtn.disabled = false;
}

function clearResults() {
    document.getElementById('results').innerHTML = '';
    document.getElementById('exportControls').classList.add('hidden');
    currentResults =[];
}

function exportResults(format) {
    if (currentResults.length === 0) return;
    
    const variables = currentResults[0].variables;
    
    if (format === 'csv') {
        let csv = variables.map(v = &gt; v.value).join(',') + '\n';
        
        currentResults.forEach(binding = &gt; {
            const row = variables.map(variable = &gt; {
                const term = binding. get (variable);
                const value = term ? term.value: '';
                return `"${value.replace(/"/g, '""')}"`;
            }).join(',');
            csv += row + '\n';
        });
        
        downloadFile(csv, 'results.csv', 'text/csv');
    } else if (format === 'json') {
        const json = currentResults.map(binding = &gt; {
            const obj = {
            };
            variables.forEach(variable = &gt; {
                const term = binding. get (variable);
                obj[variable.value] = term ? term.value: null;
            });
            return obj;
        });
        
        downloadFile(JSON.stringify(json, null, 2), 'results.json', 'application/json');
    }
}

function downloadFile(content, filename, mimeType) {
    const blob = new Blob([content], {
        type: mimeType
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

document.getElementById('queryEditor').addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) &amp;&amp; e.key === 'Enter') {
        executeQuery();
    }
});