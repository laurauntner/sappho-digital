document.addEventListener("DOMContentLoaded", function () {
    Highcharts.setOptions({
        chart: {
            style: {
                fontFamily: 'Geist'
            }
        }
    });

    const fileName = document.body.getAttribute("data-tei-file");
    const showGenres = document.body.getAttribute("data-show-genres") === "true";
    const url = "https://raw.githubusercontent.com/laurauntner/sappho-digital/main/data/lists/" + fileName;

    fetch(url)
        .then(response => response.text())
        .then(data => {
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(data, "text/xml");

            // TEI-Namespace
            const nsResolver = (prefix) => {
                const ns = { 'tei': 'http://www.tei-c.org/ns/1.0' };
                return ns[prefix] || null;
            };

            // === Timeline aus <bibl>/<date> ===
            const dateCounts = {};
            const biblElements = xmlDoc.evaluate("//tei:bibl", xmlDoc, nsResolver, XPathResult.ANY_TYPE, null);
            let bibl = biblElements.iterateNext();

            while (bibl) {
                // Erst date[@type="created"], sonst date[@type="published"]
                let dateElement = xmlDoc.evaluate(".//tei:date[@type='created']", bibl, nsResolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
                if (!dateElement) {
                    dateElement = xmlDoc.evaluate(".//tei:date[@type='published']", bibl, nsResolver, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
                }

                if (dateElement) {
                    const when = dateElement.getAttribute("when");
                    const notBefore = dateElement.getAttribute("notBefore");
                    const notAfter = dateElement.getAttribute("notAfter");

                    let year = null;
                    if (when) {
                        year = parseInt(when);
                    } else if (notBefore && notAfter) {
                        year = Math.round((parseInt(notBefore) + parseInt(notAfter)) / 2);
                    } else if (notBefore) {
                        year = parseInt(notBefore);
                    } else if (notAfter) {
                        year = parseInt(notAfter);
                    }

                    if (year && !isNaN(year)) {
                        dateCounts[year] = (dateCounts[year] || 0) + 1;
                    }
                }

                bibl = biblElements.iterateNext();
            }

            const timelineData = Object.keys(dateCounts)
                .map(year => [Date.UTC(parseInt(year), 0, 1), dateCounts[year]])
                .sort((a, b) => a[0] - b[0]);

            // === Genre-Zählung (nur bei "alle") ===
            let genreData = [];
            if (showGenres) {
                const genres = {
                    'Prosa': 0,
                    'Lyrik': 0,
                    'Drama': 0,
                    'Sonstige': 0
                };

                Array.from(xmlDoc.getElementsByTagNameNS("http://www.tei-c.org/ns/1.0", "note")).forEach(note => {
                    const text = note.textContent.toLowerCase();
                    if (text.includes("lyrik")) {
                        genres["Lyrik"]++;
                    } else if (text.includes("prosa")) {
                        genres["Prosa"]++;
                    } else if (text.includes("drama")) {
                        genres["Drama"]++;
                    } else {
                        genres["Sonstige"]++;
                    }
                });

                const baseColor = 'rgba(94, 23, 235,';
                const colorVariants = [
                    `${baseColor} 0.9)`,
                    `${baseColor} 0.7)`,
                    `${baseColor} 0.5)`,
                    `${baseColor} 0.3)`,
                    `${baseColor} 0.1)`
                ];

                const genreLinks = {
                    'Prosa': 'https://sappho-digital.com/toc-prosa.html',
                    'Lyrik': 'https://sappho-digital.com/toc-lyrik.html',
                    'Drama': 'https://sappho-digital.com/toc-drama.html',
                    'Sonstige': 'https://sappho-digital.com/toc-sonstige.html'
                };

                genreData = Object.entries(genres).map(([genre, count], index) => ({
                    name: genre,
                    y: count,
                    color: colorVariants[index % colorVariants.length],
                    url: genreLinks[genre] || ''
                }));
            }

            // === Timeline anzeigen ===
            Highcharts.chart('container-timeline', {
                chart: {
                    type: 'line'
                },
                title: {
                    text: null
                },
                xAxis: {
                    type: 'datetime',
                    title: { text: 'Jahre' }
                },
                yAxis: {
                    title: { text: 'Werke' },
                    endOnTick: false
                },
                legend: {
                    enabled: false
                },
                tooltip: {
                    formatter: function () {
                        return 'Jahr: ' + Highcharts.dateFormat('%Y', this.x) + '<br/>Werke: ' + this.y;
                    }
                },
                series: [{
                    name: 'Werke',
                    data: timelineData,
                    color: 'rgba(94, 23, 235, 0.7)'
                }]
            });

            // === Genre-Pie-Chart (nur bei "alle") ===
            if (showGenres) {
                Highcharts.chart('container-genres', {
                    chart: {
                        type: 'pie'
                    },
                    title: {
                        text: null
                    },
                    plotOptions: {
                        pie: {
                            allowPointSelect: true,
                            cursor: 'pointer',
                            events: {
                                click: function (event) {
                                    const point = event.point;
                                    if (point.options.url) {
                                        window.open(point.options.url, '_blank');
                                    }
                                }
                            }
                        }
                    },
                    series: [{
                        name: 'Rezeptionszeugnisse',
                        colorByPoint: true,
                        data: genreData
                    }]
                });
            }
        })
        .catch(error => console.error('Error fetching the XML:', error));
});
