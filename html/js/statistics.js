const C = {
  s:     'rgba(94,23,235,0.75)',
  sLine: '#5e17eb',
  r:     'rgba(107,114,128,0.75)',
  rLine: '#6b7280',
};

const charts = {};

// Balkenhöhe
function canvasHeight(n) {
  return Math.max(120, n * 32 + 40);
}

// X-Achsen-Maximum: nächste runde Zahl über dem tatsächlichen Maximum
function xMax(items) {
  const max = Math.max(
    ...items.map(i => parseFloat(i.pctSappho)),
    ...items.map(i => parseFloat(i.pctReception))
  );
  // nächste 5er-Stufe über dem Maximum + 5% Puffer
  const padded = max * 1.05;
  return Math.min(100, Math.ceil(padded / 5) * 5);
}

// Eine Kategorie-Sektion aufbauen (standardmäßig zugeklappt)
function buildCategory(cat) {
  const section = document.createElement('div');
  section.className = 'card cat';
  section.id = 'cat-' + cat.key;

  const head = document.createElement('div');
  head.className = 'card-header';
  head.innerHTML = `<span class="arrow">▶</span><h2>${cat.label}</h2>`;

  const body = document.createElement('div');
  body.className = 'card-body';
  body.id = 'body-' + cat.key;

  const wrap = document.createElement('div');
  wrap.className = 'chart-wrap';
  const canvas = document.createElement('canvas');
  canvas.id = 'chart-' + cat.key;
  canvas.style.height = canvasHeight(cat.items.length) + 'px';
  wrap.appendChild(canvas);
  body.appendChild(wrap);

  section.appendChild(head);
  section.appendChild(body);

  head.addEventListener('click', () => {
    const isOpen = body.classList.contains('visible');
    body.classList.toggle('visible', !isOpen);
    head.classList.toggle('open', !isOpen);
    if (!isOpen && !charts[cat.key]) {
      renderChart(cat);
    }
  });

  return section;
}

// Chart rendern
function renderChart(cat) {
  const ctx = document.getElementById('chart-' + cat.key).getContext('2d');
  const labels = cat.items.map(i => i.label);
  const pctS   = cat.items.map(i => parseFloat(i.pctSappho));
  const pctR   = cat.items.map(i => parseFloat(i.pctReception));
  const maxX   = xMax(cat.items);

  charts[cat.key] = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [
        {
          label: `Sappho-Fragmente (n=${DATA.nSappho})`,
          data: pctS,
          backgroundColor: C.s,
          borderColor: C.sLine,
          borderWidth: 1,
          borderRadius: 2,
        },
        {
          label: `Rezeptionszeugnisse (n=${DATA.nReception})`,
          data: pctR,
          backgroundColor: C.r,
          borderColor: C.rLine,
          borderWidth: 1,
          borderRadius: 2,
        },
      ],
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'nearest', axis: 'y', intersect: true },
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: ctx => {
              const d = cat.items[ctx.dataIndex];
              const isSappho = ctx.datasetIndex === 0;
              const count = isSappho ? d.countSappho   : d.countReception;
              const total = isSappho ? DATA.nSappho     : DATA.nReception;
              const pct   = ctx.parsed.x.toFixed(2);
              const name  = isSappho ? 'Sappho' : 'Rezeption';
              return ` ${name}: ${pct}% (${count}/${total})`;
            },
          },
        },
      },
      scales: {
        x: {
          min: 0,
          max: maxX,
          ticks: { font: { family: 'Geist, system-ui', size: 11 }, callback: v => v + '%', stepSize: 5 },
          grid: { color: 'rgba(0,0,0,0.06)' },
        },
        y: {
          ticks: { font: { family: 'Geist, system-ui', size: 12 }, autoSkip: false },
          grid: { display: false },
        },
      },
    },
  });
}

// Init
document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('cats');
  DATA.categories.forEach(cat => {
    if (cat.items.length === 0) return;
    container.appendChild(buildCategory(cat));
  });
});

// ─── Statistik 2: Sankey ────────────────────────────────────────────────────

// Google Charts laden
google.charts.load('current', { packages: ['sankey'] });
google.charts.setOnLoadCallback(initStat2);

const FTYPE_COLORS = {
  person_ref: '#f59e0b',
  place_ref:  '#10b981',
  character:  '#3b82f6',
  topos:      '#ef4444',
  motif:      '#8b5cf6',
  topic:      '#06b6d4',
  plot:       '#f97316',
};

function initStat2() {
  const selFrag = document.getElementById('sel-fragment');
  if (!selFrag) return;

  (DATA.fragments || []).forEach(frag => {
    const opt = document.createElement('option');
    opt.value = frag.label;
    opt.textContent = frag.label;
    selFrag.appendChild(opt);
  });

  selFrag.addEventListener('change', renderSankey);
}

function renderSankey() {
  const fragLabel   = document.getElementById('sel-fragment').value;
  const placeholder = document.getElementById('sankey-placeholder');
  const chartDiv    = document.getElementById('sankey-chart');
  const infoDiv     = document.getElementById('sankey-info');

  if (!fragLabel) {
    placeholder.textContent = 'Bitte Fragment auswählen.';
    placeholder.style.display = '';
    chartDiv.style.display = 'none';
    infoDiv.style.display = 'none';
    return;
  }

  const frag = (DATA.fragments || []).find(f => f.label === fragLabel);
  if (!frag || !frag.featureTypes.length) {
    placeholder.textContent = 'Keine Daten für dieses Fragment vorhanden.';
    placeholder.style.display = '';
    chartDiv.style.display = 'none';
    infoDiv.style.display = 'none';
    return;
  }

  placeholder.style.display = 'none';
  chartDiv.style.display = '';

  // Gesamtzahlen für Info-Zeile
  const totalAct  = frag.featureTypes.reduce((s, ft) => s + ft.total, 0);
  const totalFeat = frag.featureTypes.reduce((s, ft) => s + ft.items.length, 0);
  infoDiv.style.display = '';
  infoDiv.textContent =
    `Fragment ${fragLabel} · ${frag.featureTypes.length} Phänomentypen · ${totalFeat} distinkte Phänomene · ${totalAct} Aktualisierungen gesamt`;

  // Sankey-Daten: Fragment → FeatureTyp → Feature
  // Google Sankey erlaubt keine doppelten Kanten zwischen denselben Knoten,
  // daher bekommt jeder Feature-Typ-Knoten ein unsichtbares Suffix (​ pro Typ).
  const dataTable = new google.visualization.DataTable();
  dataTable.addColumn('string', 'Von');
  dataTable.addColumn('string', 'Nach');
  dataTable.addColumn('number', 'Gewicht');
  dataTable.addColumn({type: 'string', role: 'tooltip'});

  const fragNode = `Fragment ${fragLabel}`;

  // Farblisten für Knoten und Links aufbauen
  // Reihenfolge: erst Fragment-Knoten, dann FeatureTyp-Knoten, dann Feature-Knoten
  const nodeColorMap = {};   // nodeName → color
  nodeColorMap[fragNode] = '#5e17eb';

  // Feature-Namen können in mehreren Typen vorkommen → eindeutig machen
  const featureNodeNames = {};  // ftypeKey+featLabel → eindeutiger Knotenname

  let totalRows = 0;
  frag.featureTypes.forEach(ft => {
    const ftColor  = FTYPE_COLORS[ft.key] || '#6b7280';
    // Eindeutiger Typ-Knoten (zero-width space pro Typ)
    const ftNode = ft.label;
    nodeColorMap[ftNode] = ftColor;

    ft.items.forEach(item => {
      // Feature-Knoten: falls Label in mehreren Typen vorkommt, Suffix anhängen
      const rawName = item.label;
      const nodeKey = ft.key + '|' + rawName;
      if (!featureNodeNames[nodeKey]) {
        featureNodeNames[nodeKey] = rawName;
      }
      const featNode = featureNodeNames[nodeKey];
      if (!nodeColorMap[featNode]) nodeColorMap[featNode] = ftColor;

      const tooltip1 = `${fragNode} → ${ft.label}: ${ft.total} Aktualisierungen`;
      const tooltip2 = `${ft.label} → ${item.label}: ${item.count} Aktualisierungen`;

      dataTable.addRow([fragNode, ftNode,   ft.total,   tooltip1]);
      dataTable.addRow([ftNode,   featNode, item.count, tooltip2]);
      totalRows++;
    });
  });

  // Dedupliziere Fragment→FeatureTyp-Kanten (Google Sankey summiert automatisch)
  // → bereits korrekt, da wir ft.total als Gewicht der ersten Kante setzen
  // aber: jedes item erzeugt eine Fragment→ftNode Kante → zu viel!
  // Lösung: DataTable neu aufbauen, erste Ebene nur einmal pro FeatureTyp
  const dataTable2 = new google.visualization.DataTable();
  dataTable2.addColumn('string', 'Von');
  dataTable2.addColumn('string', 'Nach');
  dataTable2.addColumn('number', 'Gewicht');

  frag.featureTypes.forEach(ft => {
    const ftNode = ft.label;
    // Ebene 1: Fragment → FeatureTyp (einmal, Gewicht = Summe aller Features)
    dataTable2.addRow([fragNode, ftNode, ft.total]);
    // Ebene 2: FeatureTyp → Feature
    ft.items.forEach(item => {
      const nodeKey  = ft.key + '|' + item.label;
      const featNode = featureNodeNames[nodeKey];
      dataTable2.addRow([ftNode, featNode, item.count]);
    });
  });

  // Dynamische Höhe: Anzahl Feature-Knoten bestimmt die Höhe
  const nFeats = Object.keys(featureNodeNames).length;
  const height = Math.max(300, nFeats * 24 + frag.featureTypes.length * 20 + 80);
  chartDiv.style.height = height + 'px';

  // Farbarrays in Reihenfolge der Knoten-Erscheinung aufbauen
  // Google Charts Sankey weist Farben in der Reihenfolge zu, in der Knoten
  // erstmals in der DataTable auftauchen.
  const nodeOrder = [];
  const seen = new Set();
  for (let i = 0; i < dataTable2.getNumberOfRows(); i++) {
    const from = dataTable2.getValue(i, 0);
    const to   = dataTable2.getValue(i, 1);
    if (!seen.has(from)) { seen.add(from); nodeOrder.push(from); }
    if (!seen.has(to))   { seen.add(to);   nodeOrder.push(to);   }
  }
  const nodeColors = nodeOrder.map(n => nodeColorMap[n] || '#9ca3af');
  const linkColors = frag.featureTypes.flatMap(ft => {
    const c = FTYPE_COLORS[ft.key] || '#9ca3af';
    // eine Farbe für Fragment→FeatureTyp-Link, eine pro Feature→FeatureTyp-Link
    return [c, ...ft.items.map(() => c)];
  });

  const chart = new google.visualization.Sankey(chartDiv);
  chart.draw(dataTable2, {
    sankey: {
      node: {
        colors: nodeColors,
        label: {
          fontName: 'Geist, system-ui, sans-serif',
          fontSize: 12,
          color: '#1f2937',
          bold: false,
        },
        nodePadding: 10,
        width: 16,
      },
      link: {
        colorMode: 'source',
        colors: linkColors,
      },
      iterations: 128,
    },
    tooltip: { isHtml: false },
  });
}
