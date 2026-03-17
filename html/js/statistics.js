// statistics.js
// Erwartet globales DATA-Objekt aus dem inline <script> im HTML:
// {
//   nSappho:    <int>,
//   nReception: <int>,
//   categories: [
//     { key, label, n, items: [{ label, countSappho, countReception, pctSappho, pctReception }, ...] }
//   ]
// }

const C = {
  s:     'rgba(94,23,235,0.75)',
  sLine: '#5e17eb',
  r:     'rgba(107,114,128,0.75)',
  rLine: '#6b7280',
};

// Alle erzeugten Chart-Instanzen (für späteres Destroy)
const charts = {};

// ── Balkenhöhe: 32px pro Item, min 200px, kein hartes Maximum ────────────────
function canvasHeight(n) {
  return Math.max(200, n * 32 + 60);
}

// ── Eine Kategorie-Sektion aufbauen ───────────────────────────────────────────
function buildCategory(cat, index) {
  const section = document.createElement('div');
  section.className = 'card stat-cat';
  section.id = 'cat-' + cat.key;

  // Header
  const head = document.createElement('div');
  head.className = 'card-header open';
  head.innerHTML = `
    <h2>${cat.label}</h2>
    <span class="cat-meta">${cat.n} distinkte Features</span>
  `;

  // Body
  const body = document.createElement('div');
  body.className = 'card-body';
  body.id = 'body-' + cat.key;

  // Canvas
  const wrap = document.createElement('div');
  wrap.className = 'chart-wrap';
  const canvas = document.createElement('canvas');
  canvas.id = 'chart-' + cat.key;
  const h = canvasHeight(cat.items.length);
  canvas.height = h;
  wrap.appendChild(canvas);
  body.appendChild(wrap);

  section.appendChild(head);
  section.appendChild(body);

  // Toggle
  head.addEventListener('click', () => {
    const isOpen = head.classList.contains('open');
    head.classList.toggle('open', !isOpen);  // für CSS falls gewünscht
    body.classList.toggle('hidden', isOpen);
  });

  return section;
}

// ── Chart für eine Kategorie rendern ─────────────────────────────────────────
function renderChart(cat) {
  const ctx = document.getElementById('chart-' + cat.key).getContext('2d');

  // Bestehenden Chart zerstören falls vorhanden
  if (charts[cat.key]) {
    charts[cat.key].destroy();
  }

  const labels   = cat.items.map(i => i.label);
  const pctS     = cat.items.map(i => parseFloat(i.pctSappho));
  const pctR     = cat.items.map(i => parseFloat(i.pctReception));

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
      indexAxis: 'y',           // horizontale Balken
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: {
          display: false,        // globale Legende im HTML reicht
        },
        tooltip: {
          callbacks: {
            label: ctx => {
              const d = cat.items[ctx.dataIndex];
              const isSappho = ctx.datasetIndex === 0;
              const count  = isSappho ? d.countSappho   : d.countReception;
              const total  = isSappho ? DATA.nSappho     : DATA.nReception;
              const pct    = ctx.parsed.x.toFixed(2);
              const name   = isSappho ? 'Sappho' : 'Rezeption';
              return ` ${name}: ${pct}% (${count}/${total})`;
            },
          },
        },
      },
      scales: {
        x: {
          min: 0,
          max: 100,
          ticks: {
            font: { family: 'system-ui', size: 11 },
            callback: v => v + '%',
          },
          grid: { color: 'rgba(0,0,0,0.06)' },
        },
        y: {
          ticks: {
            font: { family: 'system-ui', size: 12 },
            autoSkip: false,
          },
          grid: { display: false },
        },
      },
    },
  });
}

// ── Init ──────────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('cats');

  DATA.categories.forEach((cat, i) => {
    if (cat.items.length === 0) return;  // leere Kategorien überspringen

    const section = buildCategory(cat, i);
    container.appendChild(section);

    // Canvas-Höhe setzen
    const canvas = section.querySelector('canvas');
    canvas.style.height = canvasHeight(cat.items.length) + 'px';

    renderChart(cat);
  });
});
