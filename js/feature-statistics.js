document.addEventListener('DOMContentLoaded', function () {
  var lang = document.documentElement.lang === 'en' ? 'en' : 'de';
  var occurrences = lang === 'en' ? 'Occurrences' : 'Vorkommnisse';

  if (typeof Highcharts !== 'undefined') {
    Highcharts.setOptions({
      chart: { style: { fontFamily: 'Geist' } }
    });
  }

  document.querySelectorAll('.skos-chart[data-chart="bar"]').forEach(function (el) {
    var chartId = el.id;
    var dataTag = document.getElementById(chartId + '-data');
    if (!dataTag) return;

    var payload = {};
    try {
      payload = JSON.parse(dataTag.textContent);
    } catch (e) {
      console.error('Chart JSON parse error for', chartId, e);
      return;
    }

    Highcharts.chart(chartId, {
      chart: { type: 'bar' },
      title: { text: null },
      xAxis: { type: 'category', title: { text: null } },
      yAxis: { title: { text: occurrences }, endOnTick: false },
      legend: { enabled: false },
      tooltip: { pointFormat: occurrences + ': <b>{point.y}</b>' },
      series: [{
        name: payload.seriesName || occurrences,
        data: payload.data || [],
        color: 'rgba(94, 23, 235, 0.7)'
      }],
      credits: { enabled: false },
      accessibility: { enabled: false }
    });
  });
});
