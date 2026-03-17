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
