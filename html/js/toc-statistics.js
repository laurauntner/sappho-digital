document.addEventListener("DOMContentLoaded", function () {
    Highcharts.setOptions({
        chart: {
            style: {
                fontFamily: 'Geist'
            }
        }
    });

    const showGenres = document.body.getAttribute("data-show-genres") === "true";
    const lang = document.documentElement.lang === 'en' ? 'en' : 'de';
    const t = lang === 'en'
        ? { years: 'Years', works: 'Works', year: 'Year: ', reception: 'Reception Testimonies',
            genreLabels: { Prosa: 'Prose', Lyrik: 'Poetry', Drama: 'Drama', Sonstige: 'Other' } }
        : { years: 'Jahre', works: 'Werke', year: 'Jahr: ', reception: 'Rezeptionszeugnisse',
            genreLabels: { Prosa: 'Prosa', Lyrik: 'Lyrik', Drama: 'Drama', Sonstige: 'Sonstige' } };

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
                title: { text: t.years }
            },
            yAxis: {
                title: { text: t.works },
                endOnTick: false
            },
            legend: { enabled: false },
            tooltip: {
                formatter: function () {
                    return t.year + Highcharts.dateFormat('%Y', this.x) + '<br/>' + t.works + ': ' + this.y;
                }
            },
            series: [{
                name: t.works,
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
            const genreLinks = lang === 'en' ? {
                'Prosa':    'https://sappho-digital.com/toc-prose.html',
                'Lyrik':    'https://sappho-digital.com/toc-poetry.html',
                'Drama':    'https://sappho-digital.com/toc-plays.html',
                'Sonstige': 'https://sappho-digital.com/toc-other.html'
            } : {
                'Prosa':    'https://sappho-digital.com/toc-prosa.html',
                'Lyrik':    'https://sappho-digital.com/toc-lyrik.html',
                'Drama':    'https://sappho-digital.com/toc-drama.html',
                'Sonstige': 'https://sappho-digital.com/toc-sonstige.html'
            };
            const genreData = Object.entries(window.genreData).map(([genre, count], index) => ({
                name: t.genreLabels[genre] || genre,
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
                    name: t.reception,
                    colorByPoint: true,
                    data: genreData
                }]
            });
        }
    }
});