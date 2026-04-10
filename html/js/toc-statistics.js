document.addEventListener("DOMContentLoaded", function () {
    Highcharts.setOptions({
        chart: {
            style: {
                fontFamily: 'Geist'
            }
        }
    });

    const showGenres = document.body.getAttribute("data-show-genres") === "true";

    // Fix 2: window.timelineData wird vom XSL inline als Jahreszahlen-Array eingebettet –
    // kein erneuter fetch() der gesamten XML-Datei nötig.
    // Format: [1800, 1800, 1801, 1803, ...] – Duplikate werden unten gezählt.
    buildCharts(window.timelineData || []);

    function buildCharts(years) {

        // Häufigkeiten pro Jahr zählen
        const dateCounts = {};
        for (const year of years) {
            dateCounts[year] = (dateCounts[year] || 0) + 1;
        }

        const timelineData = Object.keys(dateCounts)
            .map(year => [Date.UTC(parseInt(year), 0, 1), dateCounts[year]])
            .sort((a, b) => a[0] - b[0]);

        // Timeline-Liniendiagramm
        Highcharts.chart('container-timeline', {
            chart: { type: 'line' },
            title: { text: null },
            xAxis: {
                type: 'datetime',
                title: { text: 'Jahre' }
            },
            yAxis: {
                title: { text: 'Werke' },
                endOnTick: false
            },
            legend: { enabled: false },
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

        // Genre-Pie-Chart (nur bei "alle")
        if (showGenres) {
            // Fix 2b: Genre-Daten aus dem bereits gerenderten DOM lesen –
            // kein XML-Fetch nötig.
            const genres = { 'Prosa': 0, 'Lyrik': 0, 'Drama': 0, 'Sonstige': 0 };

            document.querySelectorAll('#tocTable tbody tr').forEach(row => {
                // Gattungsspalte ist die 9. <td> (Index 8, 0-basiert)
                const genreCell = row.cells[8];
                if (!genreCell) return;
                const text = genreCell.textContent.toLowerCase();
                if (text.includes('lyrik'))       genres['Lyrik']++;
                else if (text.includes('prosa'))  genres['Prosa']++;
                else if (text.includes('drama'))  genres['Drama']++;
                else                              genres['Sonstige']++;
            });

            const baseColor = 'rgba(94, 23, 235,';
            const colorVariants = [
                `${baseColor} 0.9)`,
                `${baseColor} 0.7)`,
                `${baseColor} 0.5)`,
                `${baseColor} 0.3)`
            ];
            const genreLinks = {
                'Prosa':    'https://sappho-digital.com/toc-prosa.html',
                'Lyrik':    'https://sappho-digital.com/toc-lyrik.html',
                'Drama':    'https://sappho-digital.com/toc-drama.html',
                'Sonstige': 'https://sappho-digital.com/toc-sonstige.html'
            };
            const genreData = Object.entries(genres).map(([genre, count], index) => ({
                name: genre,
                y: count,
                color: colorVariants[index % colorVariants.length],
                url: genreLinks[genre] || ''
            }));

            Highcharts.chart('container-genres', {
                chart: { type: 'pie' },
                title: { text: null },
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
    }
});