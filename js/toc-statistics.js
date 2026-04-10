document.addEventListener("DOMContentLoaded", function () {
    Highcharts.setOptions({
        chart: {
            style: {
                fontFamily: 'Geist'
            }
        }
    });

    const showGenres = document.body.getAttribute("data-show-genres") === "true";

    buildCharts(window.timelineData || []);

    function buildCharts(years) {
        const dateCounts = {};
        for (const year of years) {
            dateCounts[year] = (dateCounts[year] || 0) + 1;
        }

        const timelineData = Object.keys(dateCounts)
            .map(year => [Date.UTC(parseInt(year), 0, 1), dateCounts[year]])
            .sort((a, b) => a[0] - b[0]);

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

        if (showGenres && window.genreData) {
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
            const genreData = Object.entries(window.genreData).map(([genre, count], index) => ({
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
                                if (event.point.options.url) {
                                    window.open(event.point.options.url, '_blank');
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