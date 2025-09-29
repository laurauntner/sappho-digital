(function () {

  if (!location.protocol.startsWith('http')) {
    console.warn(
      'Hinweis: Diese Seite läuft nicht über HTTP. fetch() auf lokale Dateien wird von Browsern blockiert (CORS). Bitte lokal per http://localhost:… serven.'
    );
  }

  function parseCSV(text, delimiter = ';') {
    const rows = [];
    let i = 0, cur = '', inQuotes = false, row = [];
    while (i < text.length) {
      const ch = text[i];
      if (ch === '"') {
        if (inQuotes && text[i + 1] === '"') {
          cur += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch === delimiter && !inQuotes) {
        row.push(cur); cur = '';
      } else if ((ch === '\n' || ch === '\r') && !inQuotes) {
        if (cur.length || row.length) {
          row.push(cur); rows.push(row); row = []; cur = '';
        }
        if (ch === '\r' && text[i + 1] === '\n') i++;
      } else {
        cur += ch;
      }
      i++;
    }
    if (cur.length || row.length) {
      row.push(cur); rows.push(row);
    }
    while (rows.length && rows[rows.length - 1].every(c => c === '')) rows.pop();
    return rows;
  }

  function toInt(x) {
    const n = parseInt(x, 10);
    return Number.isFinite(n) ? n : NaN;
  }

  const pairKey = (...parts) => parts.map(p => String(p ?? '')).join('||');

  const base = 'rgba(94, 23, 235,';
  const variants = [
    `${base} 0.9)`,
    `${base} 0.7)`,
    `${base} 0.5)`,
    `${base} 0.3)`,
    `${base} 0.15)`,
    `${base} 0.08)`
  ];
  const seriesColor = `${base} 0.7)`;

  function setHighchartsDefaults() {
    if (typeof Highcharts === 'undefined') return;
    Highcharts.setOptions({
      chart: { style: { fontFamily: 'Geist' }, height: 240, spacing: [8, 8, 8, 8] },
      colors: variants,
      title: { text: null },
      legend: { itemStyle: { fontSize: '11px' } },
      xAxis: { labels: { style: { fontSize: '11px' } }, title: { style: { fontSize: '12px' } } },
      yAxis: { labels: { style: { fontSize: '11px' } }, title: { style: { fontSize: '12px' } }, endOnTick: false },
      tooltip: { style: { fontSize: '11px' } },
      credits: { enabled: false },
      accessibility: { enabled: false }
    });
  }

  const dataCache = new Map();

  async function loadAndPrepare(csvUrl) {
    if (dataCache.has(csvUrl)) return dataCache.get(csvUrl);

    const res = await fetch(csvUrl);
    if (!res.ok) throw new Error(`CSV nicht ladbar (${res.status})`);
    const text = await res.text();

    const table = parseCSV(text, ';');
    if (!table.length) throw new Error('CSV leer');

    const header = table[0];
    const rowsRaw = table.slice(1);
    const idx = (name) => header.findIndex(h => String(h).trim() === name);

    const col = {
      ID: idx('ID'),
      Gender: idx('Gender'),
      Jahr: idx('Jahr'),
      Gattung: idx('Gattung'),
      Stadt: idx('Publikationsort (Stadt)'),
      Land: idx('Publikationsort (Land)')
    };

    Object.entries(col).forEach(([k, i]) => {
      if (i === -1) console.warn(`charts.js: Spalte "${k}" fehlt in CSV.`);
    });

    const rows = rowsRaw.map(cols => ({
      ID: col.ID >= 0 ? String(cols[col.ID]).trim() : '',
      Gender: col.Gender >= 0 ? String(cols[col.Gender] || '').trim() : '',
      Jahr: col.Jahr >= 0 ? toInt(cols[col.Jahr]) : NaN,
      Gattung: col.Gattung >= 0 ? String(cols[col.Gattung] || '').trim() : '',
      Stadt: col.Stadt >= 0 ? String(cols[col.Stadt] || '').trim() : '',
      Land: col.Land >= 0 ? String(cols[col.Land] || '').trim() : ''
    }));

    const ids = rows.map(r => r.ID).filter(Boolean);
    const uniqueIDs = Array.from(new Set(ids));
    const totalWorks = uniqueIDs.length;

    const genreByID = new Map();
    for (const r of rows) {
      if (!r.ID) continue;
      if (!genreByID.has(r.ID) && r.Gattung) genreByID.set(r.ID, r.Gattung);
    }

    const yearByID = new Map();
    for (const r of rows) {
      if (!r.ID || !Number.isFinite(r.Jahr)) continue;
      if (!yearByID.has(r.ID)) yearByID.set(r.ID, r.Jahr);
      else yearByID.set(r.ID, Math.min(yearByID.get(r.ID), r.Jahr));
    }

    const genderPairs = new Set();
    for (const r of rows) {
      if (r.ID && r.Gender) genderPairs.add(pairKey(r.ID, r.Gender));
    }

    const cityPairs = new Set();
    const countryPairs = new Set();
    for (const r of rows) {
      if (r.ID && r.Stadt) cityPairs.add(pairKey(r.ID, r.Stadt));
      if (r.ID && r.Land) countryPairs.add(pairKey(r.ID, r.Land));
    }

    const prepared = { rows, uniqueIDs, totalWorks, genreByID, yearByID, genderPairs, cityPairs, countryPairs };
    dataCache.set(csvUrl, prepared);
    return prepared;
  }

  async function renderFromElement(el) {
    const kind = el.getAttribute('data-chart');
    const csvUrl = el.getAttribute('data-csv');
    if (!csvUrl) {
      console.error('charts.js: data-csv fehlt am Element', el);
      return;
    }

    let data;
    try {
      data = await loadAndPrepare(csvUrl);
    } catch (e) {
      console.error('charts.js:', e);
      return;
    }

    switch (kind) {
      case 'gattungen':       return chartGattungen(el, data);
      case 'zeitverteilung':  return chartZeitverteilung(el, data);
      case 'geschlecht':      return chartGeschlecht(el, data);
      case 'staedte':         return chartTop(el, data, 'cityPairs', 'Top Publikationsorte (Städte)', 30);
      case 'laender':         return chartTop(el, data, 'countryPairs', 'Top Publikationsorte (Länder)', 50);
      default:
        console.warn('charts.js: unbekannter data-chart Typ:', kind);
    }
  }

  function chartGattungen(el, data) {
    const counts = {};
    for (const g of data.genreByID.values()) {
      if (!g) continue;
      counts[g] = (counts[g] || 0) + 1;
    }
    const entries = Object.entries(counts);
    const series = entries.map(([name, y], i) => ({ name, y, color: variants[i % variants.length] }));

    Highcharts.chart(el.id, {
      chart: { type: 'pie' },
      title: { text: 'Gattungsverteilung' },
      subtitle: { text: 'gezählt pro Text' },
      series: [{ name: 'Texte', colorByPoint: false, data: series }]
    });

    ensureNote(el, data);
  }

  function chartZeitverteilung(el, data) {
    const byYear = {};
    for (const y of data.yearByID.values()) {
      if (!Number.isFinite(y)) continue;
      byYear[y] = (byYear[y] || 0) + 1;
    }

    if (!Object.keys(byYear).length) return;

    const minYear = Math.min(...Object.keys(byYear).map(Number));
    const maxYear = Math.max(...Object.keys(byYear).map(Number));

    const seriesData = [];
    for (let y = minYear; y <= maxYear; y++) {
      const count = byYear[y] || 0;
      seriesData.push([Date.UTC(y, 0, 1), count]);
    }

    Highcharts.chart(el.id, {
      chart: { type: 'line' },
      title: { text: 'Zeitlicher Verlauf' },
      subtitle: { text: 'gezählt pro Text' },
      xAxis: { type: 'datetime', title: { text: 'Jahre' } },
      yAxis: {
        title: { text: 'Texte' },
        min: 0
      },
      tooltip: {
        formatter() {
          return 'Jahr: ' + Highcharts.dateFormat('%Y', this.x) + '<br/>Texte: ' + this.y;
        }
      },
      series: [{ name: 'Texte', data: seriesData, color: seriesColor }]
    });

    ensureNote(el, data);
  }

  function chartGeschlecht(el, data) {
    const counts = {};
    for (const pg of data.genderPairs) {
      const [, gender] = pg.split('||');
      if (!gender) continue;
      counts[gender] = (counts[gender] || 0) + 1;
    }

    const seriesData = Object.entries(counts)
      .map(([k, v]) => [k, v])
      .sort((a, b) => b[1] - a[1]);

    Highcharts.chart(el.id, {
      chart: { type: 'bar' },
      title: { text: 'Genderverteilung' },
      subtitle: { text: 'Mehrfachnennungen aufgrund von Ko-Autor_innenschaft möglich' },
      xAxis: { type: 'category', title: { text: null } },
      yAxis: { title: { text: 'Texte' } },
      tooltip: { pointFormat: 'Texte: <b>{point.y}</b>' },
      series: [{ name: 'Texte', data: seriesData, color: seriesColor }]
    });

    ensureNote(el, data);
  }

  function chartTop(el, data, pairSetName, title, topN) {
    const pairSet = data[pairSetName]; // Set von "ID||Wert"
    const counts = {};
    for (const p of pairSet) {
      const [, value] = p.split('||');
      if (!value) continue;
      counts[value] = (counts[value] || 0) + 1;
    }

    let entries = Object.entries(counts);

    if (pairSetName === 'cityPairs') {
      entries = entries.filter(([, v]) => v >= 2);
    }

    const seriesData = entries
      .map(([k, v]) => [k, v])
      .sort((a, b) => b[1] - a[1])
      .slice(0, topN);

    const dynamicHeight = Math.max(240, 22 * seriesData.length + 200);

    Highcharts.chart(el.id, {
      chart: { type: 'bar', height: dynamicHeight, marginLeft: 120 },
      title: { text: title },
      subtitle: { text: 'Mehrfachnennungen aufgrund mehrerer Publikationsorte möglich' },
      xAxis: {
        type: 'category',
        title: { text: null },
        labels: {
          step: 1,
          useHTML: true,
          style: { whiteSpace: 'normal', width: 110 }
        },
        tickInterval: 1
      },
      yAxis: { title: { text: 'Texte' } },
      tooltip: { pointFormat: 'Texte: <b>{point.y}</b>' },
      series: [{ name: 'Texte', data: seriesData, color: seriesColor }]
    });

    ensureNote(el, data);
  }

  document.addEventListener('DOMContentLoaded', function () {
    if (typeof Highcharts === 'undefined') {
      console.error('charts.js: Highcharts ist nicht geladen. Bitte <script src="https://code.highcharts.com/highcharts.js"></script> vor charts.js einbinden.');
      return;
    }
    setHighchartsDefaults();

    const nodes = Array.from(document.querySelectorAll('.skos-chart[data-csv][data-chart]'));
    if (!nodes.length) return;

    nodes.forEach(renderFromElement);
  });

})();
