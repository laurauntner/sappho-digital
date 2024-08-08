document.addEventListener("DOMContentLoaded", function () {
    Highcharts.setOptions({
        chart: {
            style: {
                fontFamily: 'Geist'
            }
        }
    });

    const url = "https://raw.githubusercontent.com/laurauntner/sappho-digital/main/data/lists/sappho-rez_alle.xml";

    fetch(url)
        .then(response => response.text())
        .then(data => {
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(data, "text/xml");

            // Define the namespace resolver to handle TEI namespace
            const nsResolver = (prefix) => {
                const ns = {
                    'tei': 'http://www.tei-c.org/ns/1.0'
                };
                return ns[prefix] || null;
            };

            // Extract data for timeline focusing only on //tei:body//tei:date
            const dateCounts = {};
            const dateElements = xmlDoc.evaluate("//tei:body//tei:date", xmlDoc, nsResolver, XPathResult.ANY_TYPE, null);
            let dateElement = dateElements.iterateNext();

            while (dateElement) {
                const when = dateElement.getAttribute("when");
                const notBefore = dateElement.getAttribute("notBefore");
                const notAfter = dateElement.getAttribute("notAfter");

                let year;
                if (when) {
                    year = parseInt(when);
                } else if (notBefore && notAfter) {
                    year = Math.round((parseInt(notBefore) + parseInt(notAfter)) / 2);
                } else if (notBefore) {
                    year = parseInt(notBefore);
                } else if (notAfter) {
                    year = parseInt(notAfter);
                }

                if (year) {
                    if (!dateCounts[year]) {
                        dateCounts[year] = 0;
                    }
                    dateCounts[year]++;
                }

                dateElement = dateElements.iterateNext();
            }

            // Debugging: Print the dateCounts to the console
            console.log(dateCounts);

            const timelineData = Object.keys(dateCounts).map(year => [Date.UTC(year, 0, 1), dateCounts[year]]).sort((a, b) => a[0] - b[0]);

            // Debugging: Print the timelineData to the console
            console.log(timelineData);

            // Check the last data point specifically
            const lastDataPoint = timelineData[timelineData.length - 1];
            console.log("Last Data Point:", lastDataPoint);

            // Extract data for genres
            const genres = {};
            Array.from(xmlDoc.getElementsByTagNameNS("http://www.tei-c.org/ns/1.0", "note")).forEach(noteElement => {
                const genre = noteElement.textContent.trim();
                if (!genres[genre]) {
                    genres[genre] = 0;
                }
                genres[genre]++;
            });

            // Generate color variants
            const baseColor = 'rgba(94, 23, 235,';
            const colorVariants = [
                `${baseColor} 0.9)`,
                `${baseColor} 0.7)`,
                `${baseColor} 0.5)`,
                `${baseColor} 0.3)`,
                `${baseColor} 0.1)`
            ];

            // Define links for each genre
            const genreLinks = {
                'Prosa': 'https://sappho-digital.com/toc-prosa.html',
                'Lyrik': 'https://sappho-digital.com/toc-lyrik.html',
                'Drama': 'https://sappho-digital.com/toc-drama.html',
                'Comic': 'https://sappho-digital.com/toc-sonstige.html'
            };

            const genreData = Object.entries(genres).map(([genre, count], index) => ({
                name: genre,
                y: count,
                color: colorVariants[index % colorVariants.length],
                url: genreLinks[genre] || ''
            }));

            // Create the line chart for the timeline
            Highcharts.chart('container-timeline', {
                chart: {
                    type: 'line'
                },
                title: {
                    text: null
                },
                xAxis: {
                    type: 'datetime',
                    title: {
                        text: 'Jahre'
                    }
                },
                yAxis: {
                    title: {
                        text: 'Werke'
                    },
                    max: 75, // Set the maximum value of the y-axis
                    endOnTick: false // Prevents the axis from ending on a tick mark
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

            // Create the genre chart
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
        })
        .catch(error => console.error('Error fetching the XML:', error));
});
