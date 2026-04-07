const C = {
    s: 'rgba(94,23,235,0.75)',
    sLine: '#5e17eb',
    r: 'rgba(107,114,128,0.75)',
    rLine: '#6b7280',
};

const charts = {};

// ── Zahlenformatierung: Tausenderpunkt + Dezimalkomma (de-DE) ─────────────────
function fmtN(n, decimals) {
    if (n === null || n === undefined || isNaN(n)) return String(n);
    if (decimals !== undefined) {
        return Number(n).toLocaleString('de-DE', {
            minimumFractionDigits: decimals,
            maximumFractionDigits: decimals,
        });
    }
    return Number(n).toLocaleString('de-DE');
}


// Balkenhöhe
function canvasHeight(n) {
    return Math.max(120, n * 32 + 40);
}


// Macht Label-Array für Chart.js eindeutig ohne sichtbare Änderung
function uniqueLabels(labelArr) {
    const seen = {};
    return labelArr.map(l => {
        if (seen[l] === undefined) { seen[l] = 0; return l; }
        seen[l]++;
        return l + '\u200b'.repeat(seen[l]);
    });
}

// X-Achsen-Maximum: nächste runde Zahl über dem tatsächlichen Maximum
function xMax(items) {
    const max = Math.max(
        ...items.map(i => parseFloat(i.pctSappho)),
        ...items.map(i => parseFloat(i.pctReception))
    );
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
    const labels = uniqueLabels(cat.items.map(i => i.label));
    const pctS = cat.items.map(i => parseFloat(i.pctSappho));
    const pctR = cat.items.map(i => parseFloat(i.pctReception));
    const maxX = xMax(cat.items);

    charts[cat.key] = new Chart(ctx, {
        type: 'bar',
        data: {
            labels,
            datasets: [
                {
                    label: `Sappho-Fragmente (n = ${fmtN(DATA.nSappho)})`,
                    data: pctS,
                    backgroundColor: C.s,
                    borderColor: C.sLine,
                    borderWidth: 2,
                    borderRadius: 2,
                },
                {
                    label: `Rezeptionszeugnisse (n = ${fmtN(DATA.nReception)})`,
                    data: pctR,
                    backgroundColor: C.r,
                    borderColor: C.rLine,
                    borderWidth: 2,
                    borderRadius: 2,
                },
            ],
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                mode: 'nearest', axis: 'y', intersect: true
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    callbacks: {
                        label: ctx => {
                            const d = cat.items[ctx.dataIndex];
                            const isSappho = ctx.datasetIndex === 0;
                            const count = isSappho ? d.countSappho : d.countReception;
                            const total = isSappho ? DATA.nSappho : DATA.nReception;
                            const pct = ctx.parsed.x.toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2});
                            const name = isSappho ? 'Sappho' : 'Rezeption';
                            return ` ${name}: ${pct}% (${count}/${total})`;
                        },
                    },
                },
            },
            scales: {
                x: {
                    min: 0,
                    max: maxX,
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 11 },
                        callback: v => v + '%',
                        stepSize: 5
                    },
                    grid: { color: 'rgba(0,0,0,0.06)' },
                },
                y: {
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 12 },
                        autoSkip: false,
                    },
                    grid: { display: false },
                    grid: { display: false },
                },
            },
        },
    });
}

// Überblick-Chart für Stat1 (alle Kategorien, Top-N, nach pctReception sortiert)
function renderCatOverview() {
    const topN = parseInt(document.getElementById('sel-cat-topn')?.value || '30');
    const wrap = document.getElementById('cat-overview-wrap');
    if (!wrap) return;

    const allItems = [];
    DATA.categories.forEach(cat => {
        cat.items.forEach(item => {
            allItems.push({ ...item, catKey: cat.key, catLabel: cat.label });
        });
    });

    allItems.sort((a, b) => parseFloat(b.pctReception) - parseFloat(a.pctReception));
    const items = allItems.slice(0, topN);

    const labels    = uniqueLabels(items.map(i => i.label));
    const pctS      = items.map(i => parseFloat(i.pctSappho));
    const pctR      = items.map(i => parseFloat(i.pctReception));
    const typeColors = items.map(i => (FTYPE_META[i.catKey] || {}).color || '#6b7280');
    const maxX      = xMax(items);
    const height    = canvasHeight(items.length);

    wrap.innerHTML = `<div class="chart-wrap"><canvas id="chart-cat-overview" style="height:${height}px"></canvas></div>`;
    const canvas = document.getElementById('chart-cat-overview');
    const ctx = canvas.getContext('2d');

    // Plugin: nur 3px Typfarb-Streifen links
    // Zeilenumbruch-Logik
    const FONT_SIZE = 11;
    const FONT_W    = 6.5;
    const splitLabel = (label, maxW) => {
        const maxChars1 = Math.floor((maxW - 16) / FONT_W) - 2;
        const maxChars2 = Math.floor((maxW - 16) / FONT_W);
        if (label.length <= maxChars1) return [label];
        const words = label.split(' ');
        let best = null, current = '';
        for (let i = 0; i < words.length - 1; i++) {
            current = current ? current + ' ' + words[i] : words[i];
            const rest = words.slice(i + 1).join(' ');
            if (current.length <= maxChars2 && rest.length <= maxChars2)
                best = { line1: current, line2: rest };
        }
        if (best) return [best.line1, best.line2];
        const mid = Math.floor(label.length / 2);
        const breakAt = label.lastIndexOf(' ', mid + 6);
        const split = breakAt > 4 ? breakAt : maxChars2;
        const line1 = label.slice(0, split).trimEnd();
        const line2Raw = label.slice(split).trimStart();
        const line2 = line2Raw.length > maxChars2 ? line2Raw.slice(0, maxChars2 - 1) + '…' : line2Raw;
        return [line1, line2];
    };

    const typeStripePlugin = {
        id: 'typeStripe',
        afterDraw(chart) {
            const { ctx: c, scales: { y }, chartArea } = chart;
            const labelW = chartArea.left;

            items.forEach((item, i) => {
                const color  = typeColors[i];
                const top    = y.getPixelForValue(i) - y.height / items.length / 2;
                const bottom = y.getPixelForValue(i) + y.height / items.length / 2;
                const h      = bottom - top;
                const lines  = splitLabel(labels[i], labelW);

                c.save();

                // Text
                c.fillStyle = '#1f2937';
                c.font = `${FONT_SIZE}px Geist, system-ui, sans-serif`;
                c.textAlign = 'right';
                c.textBaseline = 'middle';
                
                const x = labelW - 6;
                const gap = 6;      // Abstand zwischen Punkt und Text
                const radius = 3;
                
                // breiteste Zeile bestimmen
                const longestLine = lines.reduce((a, b) => (
                    c.measureText(a).width > c.measureText(b).width ? a : b
                ), lines[0]);
                
                const textWidth = c.measureText(longestLine).width;
                
                // linker Anfang des Textes
                const textLeft = x - textWidth;
                
                // Punkt links vor den Text
                const dotX = textLeft - gap - radius;
                const dotY = top + h / 2;
                
                c.beginPath();
                c.fillStyle = color;
                c.arc(dotX, dotY, radius, 0, Math.PI * 2);
                c.fill();
                
                // Text zeichnen
                c.fillStyle = '#1f2937';
                if (lines.length === 1) {
                    c.fillText(lines[0], x, top + h / 2);
                } else {
                    c.fillText(lines[0], x, top + h / 2 - 7);
                    c.fillText(lines[1], x, top + h / 2 + 7);
                }

                c.restore();
            });
        },
    };

    // Legende als SVG links neben dem Chart aufbauen (einmalig, nach Chart-Render)
    const buildSideLegend = () => {
        const existing = wrap.querySelector('.cat-side-legend');
        if (existing) existing.remove();

        // Einzigartige Kategorien in Reihenfolge ihres ersten Auftretens
        const seen = [];
        items.forEach(item => {
            if (!seen.find(s => s.key === item.catKey)) {
                seen.push({ key: item.catKey, label: item.catLabel, color: (FTYPE_META[item.catKey] || {}).color || '#6b7280' });
            }
        });

        const legendEl = document.createElement('div');
        legendEl.className = 'cat-side-legend';
        legendEl.style.cssText = 'display:flex;flex-direction:column;gap:6px;justify-content:center;padding:4px 6px 4px 0;flex-shrink:0;';

        seen.forEach(s => {
            const row = document.createElement('div');
            row.style.cssText = 'display:flex;align-items:center;gap:5px;white-space:nowrap;font-size:11px;font-family:Geist,system-ui,sans-serif;color:#374151;';
            row.innerHTML = `<span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:${s.color};flex-shrink:0"></span>${s.label}`;
            legendEl.appendChild(row);
        });

        const chartWrap = wrap.querySelector('.chart-wrap');
        chartWrap.style.cssText = 'display:flex;align-items:flex-start;gap:8px;overflow-x:auto;';
        chartWrap.insertBefore(legendEl, chartWrap.firstChild);
    };

    const chartInstance = new Chart(ctx, {
        type: 'bar',
        plugins: [typeStripePlugin],
        data: {
            labels,
            datasets: [
                {
                    label: `Sappho-Fragmente (n = ${fmtN(DATA.nSappho)})`,
                    data: pctS,
                    backgroundColor: C.s,
                    borderColor: C.sLine,
                    borderWidth: 2,
                    borderRadius: 2,
                },
                {
                    label: `Rezeptionszeugnisse (n = ${fmtN(DATA.nReception)})`,
                    data: pctR,
                    backgroundColor: C.r,
                    borderColor: C.rLine,
                    borderWidth: 2,
                    borderRadius: 2,
                },
            ],
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            layout: { padding: { left: 0 } },
            interaction: { mode: 'nearest', axis: 'y', intersect: true },
            plugins: {
                legend: { display: false },
                tooltip: {
                    enabled: false,
                    external: ({ chart, tooltip }) => {
                        if (tooltip.opacity === 0) { pdTipHide(); return; }
                        const idx = tooltip.dataPoints?.[0]?.dataIndex;
                        if (idx == null) return;
                        const item     = items[idx];
                        const singular = (FTYPE_META[item.catKey] || {}).singular || item.catLabel;
                        const pctS     = parseFloat(item.pctSappho).toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2});
                        const pctR     = parseFloat(item.pctReception).toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2});
                        const html =
                            `<strong>${item.label}</strong>`
                            + `<br><span style="font-size:10px;color:rgba(255,255,255,0.75)">(${singular})</span>`
                            + `<br><span style="color:rgba(255,255,255,0.85)">Sappho: ${pctS}% (${item.countSappho}/${fmtN(DATA.nSappho)})</span>`
                            + `<br><span style="color:rgba(255,255,255,0.85)">Rezeption: ${pctR}% (${item.countReception}/${fmtN(DATA.nReception)})</span>`;
                        const t   = getPdTip();
                        t.innerHTML     = html;
                        t.style.display = 'block';
                        const e = tooltip._eventPosition;
                        if (e) {
                            const pos = chart.canvas.getBoundingClientRect();
                            t.style.left = (pos.left + window.scrollX + e.x + 14) + 'px';
                            t.style.top  = (pos.top  + window.scrollY + e.y - 28) + 'px';
                        }
                    },
                },
            },
            scales: {
                x: {
                    min: 0, max: maxX,
                    ticks: { font: { family: 'Geist, system-ui', size: 11 }, callback: v => v + '%', stepSize: 5 },
                    grid: { color: 'rgba(0,0,0,0.06)' },
                },
                y: {
                    ticks: { font: { family: 'Geist, system-ui', size: 12 }, autoSkip: false, color: 'transparent' },
                    grid: { display: false },
                    afterFit(scale) { scale.width = 220; },
                },
            },
        },
    });
    buildSideLegend();
}

// Init
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('sel-cat-topn')?.addEventListener('change', renderCatOverview);
    renderCatOverview();

    // Detailkategorien
    const container = document.getElementById('cats');
    DATA.categories.forEach(cat => {
        if (cat.items.length === 0) return;
        container.appendChild(buildCategory(cat));
    });
});

// ── Sankey ────────────────────────────────────────────────────────────────────

const FTYPE_COLORS = {
    person_ref: '#f59e0b',
    character:  '#3b82f6',
    place_ref:  '#10b981',
    topos:      '#ef4444',
    motif:      '#8b5cf6',
    topic:      '#06b6d4',
    plot:       '#f97316',
};

const SANKEY_COLORS = {
    taken:   '#5e17eb',
    omitted: '#d1d5db',
    added:   '#f97316',
};

function initSankey() {
    const sel = document.getElementById('sel-sankey-fragment');
    if (!sel) return;

    (DATA.fragments || []).forEach(frag => {
        if (!frag.sapphoFeatures || !frag.sapphoFeatures.length) return;
        const opt = document.createElement('option');
        opt.value = frag.label;
        opt.textContent = frag.label;
        sel.appendChild(opt);
    });

    sel.addEventListener('change', () => renderSankey2(sel.value));

    if (sel.options.length > 1) {
        sel.selectedIndex = 1;
        renderSankey2(sel.value);
    }
}

// Tooltip (lazy init on first use)
let _tip = null;
function getTip() {
    if (!_tip) {
        _tip = document.createElement('div');
        _tip.style.cssText = 'position:fixed;background:#1f2937;color:#fff;font-size:12px;font-family:Geist,system-ui,sans-serif;padding:4px 8px;border-radius:4px;pointer-events:none;display:none;z-index:9999;white-space:nowrap';
        document.body.appendChild(_tip);
    }
    return _tip;
}
function showTip(e, txt) {
    const t = getTip();
    t.textContent = txt;
    t.style.display = 'block';
    moveTip(e);
}
function moveTip(e) {
    const t = getTip();
    t.style.left = (e.clientX + 12) + 'px';
    t.style.top  = (e.clientY - 28) + 'px';
}
function hideTip() {
    if (_tip) _tip.style.display = 'none';
}

function renderSankey2(fragLabel) {
    const placeholder = document.getElementById('sankey-placeholder2');
    const svgWrap     = document.getElementById('sankey-svg-wrap');
    const legend      = document.getElementById('sankey-legend');

    hideTip();

    if (!fragLabel) {
        placeholder.style.display = 'none';
        svgWrap.style.display     = 'none';
        svgWrap.innerHTML         = '';
        legend.style.display      = 'none';
        return;
    }

    const frag = (DATA.fragments || []).find(f => f.label === fragLabel);
    if (!frag) return;

    const sapphoFeats = {};
    (frag.sapphoFeatures || []).forEach(ft => {
        ft.items.forEach(item => {
            sapphoFeats[item.uri] = { label: item.label, ftypeKey: ft.key };
        });
    });

    const recepFeats = {};
    (frag.featureTypes || []).forEach(ft => {
        ft.items.forEach(item => {
            recepFeats[item.uri] = { label: item.label, ftypeKey: ft.key, count: item.count };
        });
    });

    if (!Object.keys(sapphoFeats).length && !Object.keys(recepFeats).length) {
        placeholder.textContent   = 'Keine Daten.';
        placeholder.style.display = '';
        svgWrap.style.display     = 'none';
        return;
    }

    placeholder.style.display = 'none';
    svgWrap.style.display     = '';
    legend.style.display      = 'none';
    svgWrap.innerHTML         = '';

    const FTYPES_ORDER = ['person_ref', 'character', 'place_ref', 'topos', 'motif', 'topic', 'plot'];
    const allUris = new Set([...Object.keys(sapphoFeats), ...Object.keys(recepFeats)]);

    const taken   = [...allUris].filter(u =>  sapphoFeats[u] &&  recepFeats[u]);
    const omitted = [...allUris].filter(u =>  sapphoFeats[u] && !recepFeats[u]);
    const added   = [...allUris].filter(u => !sapphoFeats[u] &&  recepFeats[u]);

    const ftypeLabels = {};
    (DATA.categories || []).forEach(c => { ftypeLabels[c.key] = c.label; });

    const sortByType = (uris, getInfo) => {
        const result = [];
        FTYPES_ORDER.forEach(key => {
            const group = uris.filter(u => getInfo(u)?.ftypeKey === key);
            if (group.length) result.push({ ftypeKey: key, uris: group });
        });
        return result;
    };

    const leftGroups  = sortByType([...taken, ...omitted], u => sapphoFeats[u]);
    const rightGroups = sortByType([...taken, ...added],   u => recepFeats[u]);

    const containerW = svgWrap.getBoundingClientRect().width || 800;

    const FONT    = 12;
    const ROW_H   = 18;
    const TYPE_H  = 16;
    const GRP_GAP = 8;
    const HDR_H   = 20;
    const NODE_W  = 8;
    const PAD     = 6;
    const FLOW_W  = Math.round(containerW * 0.32);
    const LABEL_W = Math.round((containerW - FLOW_W - 2 * NODE_W - 2 * PAD) / 2);
    const W       = containerW;

    const lNodeX = LABEL_W + PAD;
    const rNodeX = lNodeX + NODE_W + FLOW_W;

    const groupsH = groups =>
        groups.reduce((s, g) => s + TYPE_H + g.uris.length * ROW_H + GRP_GAP, 0);
    const H = HDR_H + Math.max(groupsH(leftGroups), groupsH(rightGroups)) + 8;

    // Knoten platzieren
    const nodeMap = {};
    const placeGroups = (groups, side, getFeats) => {
        let y = HDR_H;
        groups.forEach(({ ftypeKey, uris }) => {
            y += TYPE_H;
            uris.forEach(u => {
                const cx = side === 'left' ? lNodeX : rNodeX;
                nodeMap[u + '_' + (side === 'left' ? 'L' : 'R')] = {
                    x:       cx,
                    y0:      y + 1,
                    y1:      y + ROW_H - 3,
                    yc:      y + ROW_H / 2,
                    label:   getFeats(u).label,
                    ftypeKey,
                    category: (side === 'left' ? recepFeats[u] : sapphoFeats[u]) ? 'taken' : (side === 'left' ? 'omitted' : 'added'),
                    side,
                    uri: u,
                };
                y += ROW_H;
            });
            y += GRP_GAP;
        });
    };
    placeGroups(leftGroups,  'left',  u => sapphoFeats[u]);
    placeGroups(rightGroups, 'right', u => recepFeats[u]);

    const svg = d3.select(svgWrap)
        .append('svg')
        .attr('width', W)
        .attr('height', H)
        .style('font-family', 'Geist, system-ui, sans-serif')
        .style('font-size', FONT + 'px')
        .style('overflow', 'visible');

    // Spalten-Header
    [
        ['FRAGMENT',                              lNodeX - PAD,          'end'],
        [`REZEPTIONSZEUGNISSE (n = ${fmtN(frag.nBibl)})`, rNodeX + NODE_W + PAD, 'start'],
    ].forEach(([txt, x, anchor]) => {
        svg.append('text')
            .attr('x', x).attr('y', HDR_H - 5)
            .attr('text-anchor', anchor)
            .attr('font-size', '9px').attr('font-weight', '700')
            .attr('fill', '#9ca3af').attr('letter-spacing', '0.06em')
            .text(txt);
    });

    // Typ-Header
    const drawTypeHeaders = (groups, side) => {
        let y = HDR_H;
        groups.forEach(({ ftypeKey, uris }) => {
            const x      = side === 'left' ? lNodeX - PAD : rNodeX + NODE_W + PAD;
            const anchor = side === 'left' ? 'end' : 'start';
            svg.append('text')
                .attr('x', x).attr('y', y + TYPE_H - 4)
                .attr('text-anchor', anchor)
                .attr('font-size', '9px').attr('font-weight', '700')
                .attr('fill', FTYPE_COLORS[ftypeKey] || '#6b7280')
                .attr('letter-spacing', '0.04em')
                .text((ftypeLabels[ftypeKey] || ftypeKey).toUpperCase());
            y += TYPE_H + uris.length * ROW_H + GRP_GAP;
        });
    };
    drawTypeHeaders(leftGroups,  'left');
    drawTypeHeaders(rightGroups, 'right');

    // Flusslinien
    const maxCount = Math.max(1, ...taken.map(u => recepFeats[u]?.count || 1));

    taken.forEach(u => {
        const nL = nodeMap[u + '_L'];
        const nR = nodeMap[u + '_R'];
        if (!nL || !nR) return;

        const color = FTYPE_COLORS[nL.ftypeKey] || '#5e17eb';
        const count = recepFeats[u].count;
        const wL = 1.5;
        const wR = count <= 1
            ? 1.5
            : 1.5 + Math.pow((count - 1) / Math.max(1, maxCount - 1), 0.6) * 14;

        const x0 = lNodeX + NODE_W, y0 = nL.yc;
        const x1 = rNodeX,          y1 = nR.yc;
        const mx = (x0 + x1) / 2;
        const N  = 32;

        const upper = [];
        const lower = [];

        for (let i = 0; i <= N; i++) {
            const t   = i / N;
            const bx  = (1-t)**3 * x0 + 3*(1-t)**2 * t * mx + 3*(1-t) * t**2 * mx + t**3 * x1;
            const by  = (1-t)**3 * y0 + 3*(1-t)**2 * t * y0 + 3*(1-t) * t**2 * y1 + t**3 * y1;
            const dbx = 3 * ((1-t)**2 * (mx - x0) + t**2 * (x1 - mx));
            const dby = 3 * (2 * (1-t) * t * (y1 - y0));
            const len = Math.sqrt(dbx * dbx + dby * dby) || 1;
            const hw  = (wL + (wR - wL) * t) / 2;
            upper.push(`${bx + (-dby / len) * hw},${by + (dbx / len) * hw}`);
            lower.push(`${bx - (-dby / len) * hw},${by - (dbx / len) * hw}`);
        }

        const pct     = frag.nBibl > 0 ? Math.round(count / frag.nBibl * 100) : 0;
        const tipText = `${sapphoFeats[u].label}: ${count} Rezeptionszeugnis${count !== 1 ? 'se' : ''} (${pct}%)`;

        const poly = svg.append('polygon')
            .attr('points', [...upper, ...[...lower].reverse()].join(' '))
            .attr('fill', color)
            .attr('fill-opacity', 0.45)
            .style('cursor', 'default');

        poly
            .on('mouseenter', e => showTip(e, tipText))
            .on('mousemove',  e => moveTip(e))
            .on('mouseleave', () => hideTip());
    });

    // Knoten zeichnen
    Object.values(nodeMap).forEach(n => {
        const color = n.category === 'taken'
            ? (FTYPE_COLORS[n.ftypeKey] || '#5e17eb')
            : '#d1d5db';
        svg.append('rect')
            .attr('x', n.x)
            .attr('y', n.y0)
            .attr('width', NODE_W)
            .attr('height', Math.max(1, n.y1 - n.y0))
            .attr('fill', color)
            .attr('rx', 2);
    });

    // Labels
    const charW    = 6.5;
    const maxChars = Math.floor(LABEL_W / charW);

    Object.values(nodeMap).forEach(n => {
        if (!n.label) return;
        const isLeft  = n.side === 'left';
        const x       = isLeft ? lNodeX - PAD : rNodeX + NODE_W + PAD;
        const anchor  = isLeft ? 'end' : 'start';
        const gray    = n.category !== 'taken';
        const fill    = gray ? '#b0b8c4' : '#1f2937';
        const count   = (!gray && recepFeats[n.uri]) ? recepFeats[n.uri].count : null;
        const pctL    = (count !== null && frag.nBibl > 0) ? Math.round(count / frag.nBibl * 100) : null;
        const tipText = count !== null
            ? `${n.label}: ${count} Rezeptionszeugnis${count !== 1 ? 'se' : ''} (${pctL}%)`
            : n.label;
        const display = n.label.length > maxChars ? n.label.slice(0, maxChars - 1) + '…' : n.label;

        const el = svg.append('text')
            .attr('x', x)
            .attr('y', n.yc)
            .attr('dy', '0.35em')
            .attr('text-anchor', anchor)
            .attr('font-size', FONT + 'px')
            .attr('fill', fill)
            .text(display);

        el
            .on('mouseenter', e => showTip(e, tipText))
            .on('mousemove',  e => moveTip(e))
            .on('mouseleave', () => hideTip());
    });
}

document.addEventListener('DOMContentLoaded', initSankey);



// ── Statistik 3 ──────────────────────────────────────────────────────────────

const FTYPE_META = {
    person_ref:   { label: 'Personenreferenzen', singular: 'Personenreferenz',    color: '#f59e0b' },
    character:    { label: 'Figuren',            singular: 'Figur',               color: '#3b82f6' },
    place_ref:    { label: 'Ortsreferenzen',     singular: 'Ortsreferenz',        color: '#10b981' },
    topos:        { label: 'Rhetorische Topoi',  singular: 'Rhetorischer Topos',  color: '#ef4444' },
    motif:        { label: 'Motive',             singular: 'Motiv',               color: '#8b5cf6' },
    topic:        { label: 'Themen',             singular: 'Thema',               color: '#06b6d4' },
    plot:         { label: 'Stoffe',             singular: 'Stoff',               color: '#f97316' },
    work_ref:     { label: 'Werkreferenzen',     singular: 'Werkreferenz',        color: '#e11d48' },
    text_passage: { label: 'Zitate',             singular: 'Zitat',               color: '#84cc16' },
};

let _pdTip = null;
function getPdTip() {
    if (!_pdTip) {
        _pdTip = document.createElement('div');
        _pdTip.style.cssText =
            'position:fixed;background:#1f2937;color:#fff;font-size:12px;'
            + 'font-family:Geist,system-ui,sans-serif;padding:5px 9px;border-radius:5px;'
            + 'pointer-events:none;display:none;z-index:9999;white-space:nowrap;line-height:1.5';
        document.body.appendChild(_pdTip);
    }
    return _pdTip;
}
function pdTipShow(e, html) { const t = getPdTip(); t.innerHTML = html; t.style.display = 'block'; pdTipMove(e); }
function pdTipMove(e) { const t = getPdTip(); t.style.left = (e.clientX + 14) + 'px'; t.style.top = (e.clientY - 36) + 'px'; }
function pdTipHide() { getPdTip().style.display = 'none'; }

function buildBubbleChart(features, decades, container, showType = false) {
    container.innerHTML = '';
    if (!features.length || !decades.length) {
        container.innerHTML = '<p style="color:#9ca3af;padding:0.5rem 0">Keine Daten.</p>';
        return;
    }

    const cellN = (feat, dec) => {
        const cell = feat.cells.find(c => c.d === dec);
        return cell ? cell.n : 0;
    };

    const active = features
        .map(f => ({ feat: f, total: decades.reduce((s, d) => s + cellN(f, d), 0) }))
        .filter(x => x.total > 0)
        .sort((a, b) => b.total - a.total);

    if (!active.length) {
        container.innerHTML = '<p style="color:#9ca3af;padding:0.5rem 0">Keine Daten.</p>';
        return;
    }

    const nCols = decades.length;

    let maxN = 0;
    active.forEach(({ feat }) =>
        decades.forEach(dec => { const v = cellN(feat, dec); if (v > maxN) maxN = v; })
    );

    const ROW_H1  = 30;
    const ROW_H2  = 44;
    const COL_W   = 64;
    const LABEL_W = 200;
    const HDR_H   = 60;
    const PAD_B   = 8;
    const FONT_W  = 7.0;
    const MAX_W   = LABEL_W - 18;
    const MAX_CHARS_1 = Math.floor(MAX_W / FONT_W) - 2;
    const MAX_CHARS_2 = Math.floor(MAX_W / FONT_W);

    const rowMeta = active.map(({ feat }) => {
        const label = feat.label;
        if (label.length <= MAX_CHARS_1) return { lines: [label], h: ROW_H1 };
        const words = label.split(' ');
        let best = null, current = '';
        for (let i = 0; i < words.length - 1; i++) {
            current = current ? current + ' ' + words[i] : words[i];
            const rest = words.slice(i + 1).join(' ');
            if (current.length <= MAX_CHARS_2 && rest.length <= MAX_CHARS_2)
                best = { line1: current, line2: rest };
        }
        if (best) return { lines: [best.line1, best.line2], h: ROW_H2 };
        const mid = Math.floor(label.length / 2);
        const breakAt = label.lastIndexOf(' ', mid + 6);
        const split = breakAt > 4 ? breakAt : MAX_CHARS_2;
        const line1 = label.slice(0, split).trimEnd();
        const line2Raw = label.slice(split).trimStart();
        const line2 = line2Raw.length > MAX_CHARS_2 ? line2Raw.slice(0, MAX_CHARS_2 - 1) + '…' : line2Raw;
        return { lines: [line1, line2], h: ROW_H2 };
    });

    const rowY = [];
    let curY = HDR_H;
    rowMeta.forEach(m => { rowY.push(curY); curY += m.h; });
    const totalRowH = curY - HDR_H;

    const R_MAX  = Math.min(ROW_H1, COL_W) / 2 + 3;
    const scaleR = v => v === 0 ? 0 : 0.8 + (R_MAX - 0.8) * Math.pow(v / maxN, 0.45);

    const svgW = LABEL_W + nCols * COL_W + 8;
    const svgH = HDR_H + totalRowH + PAD_B;

    const ns  = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(ns, 'svg');
    svg.setAttribute('width', svgW);
    svg.setAttribute('height', svgH);
    svg.style.cssText = 'font-family:Geist,system-ui,sans-serif;font-size:11px;overflow:visible;display:block';

    const mk  = tag => document.createElementNS(ns, tag);
    const set = (el, attrs) => { Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, v)); return el; };
    const txt = (x, y, content, attrs = {}) => {
        const t = mk('text'); set(t, { x, y, ...attrs }); t.textContent = content; return t;
    };

    const decLabel = d => d === 'n/a' ? 'o. J.' : d.replace(/(\d+)s$/, '$1er');

    decades.forEach((dec, ci) => {
        const cx = LABEL_W + ci * COL_W + COL_W / 2;
        svg.appendChild(txt(cx, HDR_H - 6, decLabel(dec), {
            'text-anchor': 'middle',
            transform: `rotate(-40,${cx},${HDR_H - 6})`,
            'font-size': '10px', fill: '#6b7280',
        }));
        svg.appendChild(set(mk('line'), {
            x1: cx, y1: HDR_H, x2: cx, y2: HDR_H + totalRowH,
            stroke: 'rgba(0,0,0,0.06)', 'stroke-width': 1,
        }));
    });

    active.forEach(({ feat }, ri) => {
        const y0    = rowY[ri];
        const rh    = rowMeta[ri].h;
        const yc    = y0 + rh / 2;
        const color = (FTYPE_META[feat.ftype] || {}).color || '#6b7280';

        if (ri % 2 === 0) {
            svg.appendChild(set(mk('rect'), { x: 0, y: y0, width: svgW, height: rh, fill: 'rgba(0,0,0,0.022)' }));
        }
        svg.appendChild(set(mk('rect'), { x: 0, y: y0 + 1, width: 3, height: rh - 2, fill: color, rx: 1 }));

        const lines = rowMeta[ri].lines;
        if (lines.length === 1) {
            svg.appendChild(txt(LABEL_W - 8, yc, lines[0], { 'text-anchor': 'end', dy: '0.35em', fill: '#1f2937' }));
        } else {
            const lineH = 13;
            svg.appendChild(txt(LABEL_W - 8, yc - lineH / 2, lines[0], { 'text-anchor': 'end', dy: '0em',   fill: '#1f2937' }));
            svg.appendChild(txt(LABEL_W - 8, yc + lineH / 2, lines[1], { 'text-anchor': 'end', dy: '0.9em', fill: '#1f2937' }));
        }

        decades.forEach((dec, ci) => {
            const v = cellN(feat, dec);
            if (v === 0) return;

            const cx = LABEL_W + ci * COL_W + COL_W / 2;
            const r  = scaleR(v);

            const circle = set(mk('circle'), {
                cx, cy: yc, r,
                fill: color, 'fill-opacity': 0.70,
                stroke: color, 'stroke-width': 1, 'stroke-opacity': 0.9,
            });
            circle.style.cursor = 'default';
            svg.appendChild(circle);

            if (r >= 8) {
                svg.appendChild(txt(cx, yc, v, {
                    'text-anchor': 'middle', dy: '0.35em',
                    'font-size': Math.min(10, r * 1.1) + 'px',
                    fill: '#fff', 'pointer-events': 'none',
                }));
            }

            const ftypeLabel = (FTYPE_META[feat.ftype] || {}).singular || feat.ftype;
            const tipHtml = `<strong>${feat.label}</strong>`
                + (showType ? `<br><span style="font-size:10px;color:rgba(255,255,255,0.75)">(${ftypeLabel})</span>` : '')
                + `<br>${decLabel(dec)}: <strong>${fmtN(v)}</strong> Rezeptionszeugnis${v !== 1 ? 'se' : ''}`;
            circle.addEventListener('mouseenter', e => pdTipShow(e, tipHtml));
            circle.addEventListener('mousemove',  e => pdTipMove(e));
            circle.addEventListener('mouseleave', pdTipHide);
        });
    });

    const scroller = document.createElement('div');
    scroller.style.cssText = 'overflow-x:auto;overflow-y:auto;max-height:600px;padding-bottom:4px';
    scroller.appendChild(svg);
    container.appendChild(scroller);
}

function initPdist() {
    const pd = DATA.phenomenaDist;
    if (!pd || !pd.features || pd.features.length === 0) return;

    const legendWrap = document.getElementById('pdist-type-legend');
    if (legendWrap) {
        const ftypeOrder = Object.keys(FTYPE_META);
        [...new Set(pd.features.map(f => f.ftype))]
            .sort((a, b) => (ftypeOrder.indexOf(a) + 1 || 99) - (ftypeOrder.indexOf(b) + 1 || 99))
            .forEach(ft => {
                const m = FTYPE_META[ft] || { label: ft, color: '#6b7280' };
                const span = document.createElement('span');
                span.style.cssText = 'display:inline-flex;align-items:center;gap:5px';
                span.innerHTML = `<span style="display:inline-block;width:11px;height:11px;border-radius:50%;background:${m.color};opacity:0.8;flex-shrink:0"></span>${m.label}`;
                legendWrap.appendChild(span);
            });
    }

    document.getElementById('sel-pdist-topn')?.addEventListener('change', renderPdistOverview);
    renderPdistOverview();
    buildPdistTypeSections();
}

function renderPdistOverview() {
    const pd   = DATA.phenomenaDist;
    const topN = parseInt(document.getElementById('sel-pdist-topn').value) || 30;
    const wrap = document.getElementById('pdist-overview-wrap');
    if (wrap) buildBubbleChart(pd.features.slice(0, topN), pd.decades || [], wrap, true);
}

function buildPdistTypeSections() {
    const pd        = DATA.phenomenaDist;
    const container = document.getElementById('pdist-type-sections');
    if (!container) return;

    const ftypeOrder = Object.keys(FTYPE_META);
    [...new Set(pd.features.map(f => f.ftype))]
        .sort((a, b) => (ftypeOrder.indexOf(a) + 1 || 99) - (ftypeOrder.indexOf(b) + 1 || 99))
        .forEach(ft => {
            const meta    = FTYPE_META[ft] || { label: ft, color: '#6b7280' };
            const section = document.createElement('div');
            section.className = 'card cat';

            const head = document.createElement('div');
            head.className = 'card-header';
            head.innerHTML = `<span class="arrow">▶</span><h2>${meta.label}</h2>`;

            const body = document.createElement('div');
            body.className = 'card-body';

            const chartWrap = document.createElement('div');
            chartWrap.style.minHeight = '40px';
            body.appendChild(chartWrap);
            section.appendChild(head);
            section.appendChild(body);
            container.appendChild(section);

            head.addEventListener('click', () => {
                const isOpen = body.classList.contains('visible');
                body.classList.toggle('visible', !isOpen);
                head.classList.toggle('open', !isOpen);
                if (!isOpen && !chartWrap.dataset.rendered) {
                    buildBubbleChart(pd.features.filter(f => f.ftype === ft), pd.decades || [], chartWrap);
                    chartWrap.dataset.rendered = '1';
                }
            });
        });
}

document.addEventListener('DOMContentLoaded', initPdist);

// ── Statistik 4: Phänomene nach Gattung (Heatmap) ────────────────────────────

function buildHeatmap(features, genreObjs, container, showType = false, singleGenre = null) {
    container.innerHTML = '';

    // genreObjs is [{key, n}, ...]; extract key strings for internal use
    const genres     = genreObjs.map(g => (typeof g === 'string' ? g : g.key));
    const genreN     = Object.fromEntries(genreObjs.map(g =>
        typeof g === 'string' ? [g, null] : [g.key, g.n]));

    const activeCols = singleGenre ? [singleGenre] : genres;

    const cellN = (feat, genre) => {
        const cell = feat.cells.find(c => c.g === genre);
        return cell ? cell.n : 0;
    };

    let active;
    if (singleGenre) {
        active = features
            .map(f => ({ feat: f, total: cellN(f, singleGenre) }))
            .filter(x => x.total > 0)
            .sort((a, b) => b.total - a.total);
    } else {
        active = features
            .map(f => ({ feat: f, total: activeCols.reduce((s, g) => s + cellN(f, g), 0) }))
            .filter(x => x.total > 0)
            .sort((a, b) => b.total - a.total);
    }

    if (!active.length) {
        container.innerHTML = '<p style="color:#9ca3af;padding:0.5rem 0">Keine Daten.</p>';
        return;
    }

    // Per-column totals for % calculation, and per-column max for opacity
    const colMax   = {};
    activeCols.forEach(g => {
        colMax[g] = Math.max(1, ...active.map(({ feat }) => cellN(feat, g)));
    });

    const ROW_H1  = 26;
    const ROW_H2  = 40;
    const COL_W   = singleGenre ? 350 : 265;
    const LABEL_W = 240;
    const HDR_H   = singleGenre ? 0 : 46;
    const PAD_B   = 8;
    const FONT_W  = 7.0;
    const MAX_W   = LABEL_W - 18;
    const MAX_CHARS_1 = Math.floor(MAX_W / FONT_W) - 2;
    const MAX_CHARS_2 = Math.floor(MAX_W / FONT_W);

    const rowMeta = active.map(({ feat }) => {
        const label = feat.label;
        if (label.length <= MAX_CHARS_1) return { lines: [label], h: ROW_H1 };
        const words = label.split(' ');
        let best = null, current = '';
        for (let i = 0; i < words.length - 1; i++) {
            current = current ? current + ' ' + words[i] : words[i];
            const rest = words.slice(i + 1).join(' ');
            if (current.length <= MAX_CHARS_2 && rest.length <= MAX_CHARS_2)
                best = { line1: current, line2: rest };
        }
        if (best) return { lines: [best.line1, best.line2], h: ROW_H2 };
        const mid = Math.floor(label.length / 2);
        const breakAt = label.lastIndexOf(' ', mid + 6);
        const split = breakAt > 4 ? breakAt : MAX_CHARS_2;
        const line1 = label.slice(0, split).trimEnd();
        const line2Raw = label.slice(split).trimStart();
        const line2 = line2Raw.length > MAX_CHARS_2 ? line2Raw.slice(0, MAX_CHARS_2 - 1) + '…' : line2Raw;
        return { lines: [line1, line2], h: ROW_H2 };
    });

    const rowY = [];
    let curY = HDR_H;
    rowMeta.forEach(m => { rowY.push(curY); curY += m.h; });
    const totalRowH = curY - HDR_H;

    const nRows = active.length;
    const svgW  = LABEL_W + activeCols.length * COL_W + 8;
    const svgH  = HDR_H + totalRowH + PAD_B;

    const ns  = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(ns, 'svg');
    svg.setAttribute('width',  svgW);
    svg.setAttribute('height', svgH);
    svg.style.cssText = 'font-family:Geist,system-ui,sans-serif;font-size:11px;display:block';

    const mk  = tag => document.createElementNS(ns, tag);
    const set = (el, attrs) => { Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, v)); return el; };
    const txt = (x, y, content, attrs = {}) => {
        const t = mk('text'); set(t, { x, y, ...attrs }); t.textContent = content; return t;
    };

    // Column headers (overview only) – genre name + n=
    if (!singleGenre) {
        activeCols.forEach((genre, ci) => {
            const cx = LABEL_W + ci * COL_W + COL_W / 2;
            svg.appendChild(txt(cx, 16, genre, {
                'text-anchor': 'middle',
                'font-size': '11px',
                fill: '#374151',
                'font-weight': '600',
            }));
            const nVal = genreN[genre];
            if (nVal !== null && nVal !== undefined) {
                svg.appendChild(txt(cx, 32, `n = ${nVal}`, {
                    'text-anchor': 'middle',
                    'font-size': '10px',
                    fill: '#9ca3af',
                }));
            }
            svg.appendChild(set(mk('line'), {
                x1: cx, y1: HDR_H, x2: cx, y2: HDR_H + totalRowH,
                stroke: 'rgba(0,0,0,0.06)', 'stroke-width': 1,
            }));
        });
    }

    // Rows
    active.forEach(({ feat }, ri) => {
        const y0    = rowY[ri];
        const rh    = rowMeta[ri].h;
        const yc    = y0 + rh / 2;
        const color = (FTYPE_META[feat.ftype] || {}).color || '#6b7280';

        if (ri % 2 === 0) {
            svg.appendChild(set(mk('rect'), {
                x: 0, y: y0, width: svgW, height: rh,
                fill: 'rgba(0,0,0,0.018)',
            }));
        }

        svg.appendChild(set(mk('rect'), {
            x: 0, y: y0 + 2, width: 3, height: rh - 4,
            fill: color, rx: 1,
        }));

        const rawLabel = feat.label;
        const lines    = rowMeta[ri].lines;
        const ftypeLbl = (FTYPE_META[feat.ftype] || {}).singular || feat.ftype;
        if (lines.length === 1) {
            const labelEl = txt(LABEL_W - 8, yc, lines[0], {
                'text-anchor': 'end', dy: '0.35em',
                'font-size': '11px', fill: '#1f2937',
            });
            if (showType) {
                labelEl.addEventListener('mouseenter', e => pdTipShow(e,
                    `<strong>${rawLabel}</strong><br><span style="font-size:10px;color:rgba(255,255,255,0.75)">${ftypeLbl}</span>`));
                labelEl.addEventListener('mousemove',  e => pdTipMove(e));
                labelEl.addEventListener('mouseleave', pdTipHide);
                labelEl.style.cursor = 'default';
            }
            svg.appendChild(labelEl);
        } else {
            const lineH = 13;
            [
                [lines[0], yc - lineH / 2, '0em'],
                [lines[1], yc + lineH / 2, '0.9em'],
            ].forEach(([line, y, dy]) => {
                const labelEl = txt(LABEL_W - 8, y, line, {
                    'text-anchor': 'end', dy,
                    'font-size': '11px', fill: '#1f2937',
                });
                if (showType) {
                    labelEl.addEventListener('mouseenter', e => pdTipShow(e,
                        `<strong>${rawLabel}</strong><br><span style="font-size:10px;color:rgba(255,255,255,0.75)">${ftypeLbl}</span>`));
                    labelEl.addEventListener('mousemove',  e => pdTipMove(e));
                    labelEl.addEventListener('mouseleave', pdTipHide);
                    labelEl.style.cursor = 'default';
                }
                svg.appendChild(labelEl);
            });
        }

        // Cells
        activeCols.forEach((genre, ci) => {
            const v   = cellN(feat, genre);
            const nDocs = genreN[genre];
            const pct = (nDocs > 0 ? v / nDocs * 100 : 0);
            const cx  = LABEL_W + ci * COL_W;
            const cw  = COL_W - 3;

            const opacity = v === 0 ? 0 : 0.12 + 0.88 * Math.pow(v / colMax[genre], 0.6);

            svg.appendChild(set(mk('rect'), {
                x: cx + 1, y: y0 + 2, width: cw, height: rh - 4,
                fill: color, 'fill-opacity': opacity, rx: 2,
            }));

            if (v > 0) {
                const onDark    = opacity > 0.50;
                const textFill  = onDark ? '#fff' : color;
                const cellLabel = `${v} (${pct < 1 ? pct.toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1}) : Math.round(pct)}%)`;
                svg.appendChild(txt(cx + COL_W / 2, yc, cellLabel, {
                    'text-anchor': 'middle', dy: '0.35em',
                    'font-size': '10px',
                    fill: textFill,
                    'font-weight': onDark ? '600' : '400',
                    'pointer-events': 'none',
                }));
            }

            const tipTarget = set(mk('rect'), {
                x: cx + 1, y: y0 + 2, width: cw, height: rh - 4,
                fill: 'transparent',
            });
            tipTarget.style.cursor = 'default';
            const ftypeLabel = (FTYPE_META[feat.ftype] || {}).singular || feat.ftype;
            const tipHtml = `<strong>${rawLabel}</strong>`
                + (showType ? `<br><span style="font-size:10px;color:rgba(255,255,255,0.75)">(${ftypeLabel})</span>` : '')
                + `<br>${genre}: <strong>${fmtN(v)}</strong> Rezeptionszeugnis${v !== 1 ? 'se' : ''}`
                + (v > 0 ? ` (${pct < 1 ? pct.toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1}) : Math.round(pct)}%)` : '');
            tipTarget.addEventListener('mouseenter', e => pdTipShow(e, tipHtml));
            tipTarget.addEventListener('mousemove',  e => pdTipMove(e));
            tipTarget.addEventListener('mouseleave', pdTipHide);
            svg.appendChild(tipTarget);
        });
    });

    const scroller = document.createElement('div');
    scroller.style.cssText = 'overflow-x:auto;overflow-y:auto;max-height:600px;padding-bottom:4px';
    scroller.appendChild(svg);
    container.appendChild(scroller);
}

function renderGdistOverview() {
    const gd      = DATA.genreDist;
    const topN    = parseInt(document.getElementById('sel-gdist-topn')?.value) || 30;
    const wrap    = document.getElementById('gdist-overview-wrap');
    const genreObjs = (gd.genres || []).filter(g => g.key !== 'Unbekannt');
    if (wrap) buildHeatmap(gd.features.slice(0, topN), genreObjs, wrap, true);
}

function buildGdistGenreSections() {
    const gd        = DATA.genreDist;
    const container = document.getElementById('gdist-genre-sections');
    if (!container) return;

    const genreOrder  = ['Lyrik', 'Prosa', 'Drama', 'Comic'];
    const genreObjs   = gd.genres || [];
    const genreKeys   = genreObjs.map(g => g.key).filter(k => k !== 'Unbekannt');
    const genreNMap   = Object.fromEntries(genreObjs.map(g => [g.key, g.n]));

    const sorted = [...genreKeys].sort((a, b) => {
        const ia = genreOrder.indexOf(a), ib = genreOrder.indexOf(b);
        return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
    });

    const allGenres = [...new Set([...sorted, ...genreOrder.filter(g => !sorted.includes(g))])];

    allGenres.forEach(genre => {
        const hasData = sorted.includes(genre);
        const nVal    = genreNMap[genre];
        const nLabel  = (hasData && nVal !== undefined) ? ` <span style="font-size:0.78rem;color:#6b7280;font-weight:400">(n = ${nVal})</span>` : '';
        const section = document.createElement('div');
        section.className = 'card cat';

        const head = document.createElement('div');
        head.className = 'card-header';
        head.innerHTML =
            `<span class="arrow${hasData ? '' : ' arrow-hidden'}">▶</span>`
            + `<h2>${genre}${nLabel}</h2>`
            + (!hasData
                ? `<span style="margin-left:0.75rem;font-size:0.78rem;color:#9ca3af;font-weight:400">– noch keine analysierten Rezeptionszeugnisse</span>`
                : '');

        if (!hasData) {
            head.style.cursor = 'default';
            head.querySelector('h2').style.color = '#9ca3af';
            section.appendChild(head);
            container.appendChild(section);
            return;
        }

        const body = document.createElement('div');
        body.className = 'card-body';

        const chartWrap = document.createElement('div');
        chartWrap.style.minHeight = '40px';
        body.appendChild(chartWrap);
        section.appendChild(head);
        section.appendChild(body);
        container.appendChild(section);

        head.addEventListener('click', () => {
            const isOpen = body.classList.contains('visible');
            body.classList.toggle('visible', !isOpen);
            head.classList.toggle('open', !isOpen);
            if (!isOpen && !chartWrap.dataset.rendered) {
                buildHeatmap(gd.features, gd.genres || [], chartWrap, true, genre);
                chartWrap.dataset.rendered = '1';
            }
        });
    });
}

function buildGdistTypeSections4() {
    const gd        = DATA.genreDist;
    const container = document.getElementById('gdist-type-sections');
    if (!container) return;

    const ftypeOrder = Object.keys(FTYPE_META);
    [...new Set(gd.features.map(f => f.ftype))]
        .sort((a, b) => (ftypeOrder.indexOf(a) + 1 || 99) - (ftypeOrder.indexOf(b) + 1 || 99))
        .forEach(ft => {
            const meta    = FTYPE_META[ft] || { label: ft, color: '#6b7280' };
            const section = document.createElement('div');
            section.className = 'card cat';

            const head = document.createElement('div');
            head.className = 'card-header';
            head.innerHTML = `<span class="arrow">▶</span><h2>${meta.label}</h2>`;

            const body = document.createElement('div');
            body.className = 'card-body';

            const chartWrap = document.createElement('div');
            chartWrap.style.minHeight = '40px';
            body.appendChild(chartWrap);
            section.appendChild(head);
            section.appendChild(body);
            container.appendChild(section);

            head.addEventListener('click', () => {
                const isOpen = body.classList.contains('visible');
                body.classList.toggle('visible', !isOpen);
                head.classList.toggle('open', !isOpen);
                if (!isOpen && !chartWrap.dataset.rendered) {
                    const genreObjs = (gd.genres || []).filter(g => g.key !== 'Unbekannt');
                    buildHeatmap(gd.features.filter(f => f.ftype === ft), genreObjs, chartWrap, false);
                    chartWrap.dataset.rendered = '1';
                }
            });
        });
}

function initGdist() {
    const gd = DATA.genreDist;
    if (!gd || !gd.features || gd.features.length === 0) return;

    const legendWrap = document.getElementById('gdist-type-legend');
    if (legendWrap) {
        const ftypeOrder = Object.keys(FTYPE_META);
        [...new Set(gd.features.map(f => f.ftype))]
            .sort((a, b) => (ftypeOrder.indexOf(a) + 1 || 99) - (ftypeOrder.indexOf(b) + 1 || 99))
            .forEach(ft => {
                const m    = FTYPE_META[ft] || { label: ft, color: '#6b7280' };
                const span = document.createElement('span');
                span.style.cssText = 'display:inline-flex;align-items:center;gap:5px';
                span.innerHTML = `<span style="display:inline-block;width:11px;height:11px;border-radius:2px;background:${m.color};opacity:0.8;flex-shrink:0"></span>${m.label}`;
                legendWrap.appendChild(span);
            });
    }

    document.getElementById('sel-gdist-topn')?.addEventListener('change', renderGdistOverview);
    renderGdistOverview();
    buildGdistGenreSections();
    buildGdistTypeSections4();
}

document.addEventListener('DOMContentLoaded', initGdist);


// ── Statistik 5: Stoff-Komponenten – Sunburst ────────────────────────────────

let _pcTip = null;
function getPcTip() {
    if (!_pcTip) {
        _pcTip = document.createElement('div');
        _pcTip.style.cssText =
            'position:fixed;background:#1f2937;color:#fff;font-size:12px;'
            + 'font-family:Geist,system-ui,sans-serif;padding:6px 10px;border-radius:5px;'
            + 'pointer-events:none;display:none;z-index:9999;white-space:nowrap;line-height:1.5';
        document.body.appendChild(_pcTip);
    }
    return _pcTip;
}
function pcTipShow(e, html) {
    const t = getPcTip(); t.innerHTML = html; t.style.display = 'block'; pcTipMove(e);
}
function pcTipMove(e) {
    const t = getPcTip();
    t.style.left = (e.clientX + 14) + 'px';
    t.style.top  = (e.clientY - 34) + 'px';
}
function pcTipHide() { if (_pcTip) _pcTip.style.display = 'none'; }

function initPlotComponents() {
    const sel    = document.getElementById('sel-pc-plot');
    const selTop = document.getElementById('sel-pc-topn');
    if (!sel) return;

    const plots = DATA.plotComponents || [];
    if (!plots.length) { document.getElementById('stat5-wrap')?.remove(); return; }

    plots.forEach(p => {
        const opt = document.createElement('option');
        opt.value = p.uri;
        opt.textContent = p.label;
        sel.appendChild(opt);
    });

    const redraw = () => renderPlotComponents(sel.value, parseInt(selTop?.value || '5'));
    sel.addEventListener('change', redraw);
    selTop?.addEventListener('change', redraw);

    if (sel.options.length > 1) {
        sel.selectedIndex = 1;
        setTimeout(redraw, 0);
    }
}

function renderPlotComponents(plotUri, topN) {
    const placeholder = document.getElementById('pc-placeholder');
    const svgWrap     = document.getElementById('pc-svg-wrap');
    const legend      = document.getElementById('pc-legend');

    pcTipHide();
    svgWrap.innerHTML    = '';
    legend.style.display = 'none';

    if (!plotUri) { placeholder.style.display = 'none'; return; }

    const plot = (DATA.plotComponents || []).find(p => p.uri === plotUri);
    if (!plot) return;

    const FTYPE_ORDER = ['person_ref','character','place_ref','topos','motif','topic','work_ref','text_passage'];

    // Daten nach Typ filtern
    const byType = {};
    FTYPE_ORDER.forEach(k => { byType[k] = []; });
    (plot.coFeatures || []).forEach(cf => { if (byType[cf.ftype]) byType[cf.ftype].push(cf); });
    if (topN > 0) FTYPE_ORDER.forEach(k => { byType[k] = byType[k].slice(0, topN); });

    const activeTypes = FTYPE_ORDER.filter(k => byType[k].length > 0);
    if (!activeTypes.length) {
        placeholder.textContent = 'Keine Co-Phänomene gefunden.';
        placeholder.style.display = '';
        return;
    }
    placeholder.style.display = 'none';

    const totalWeight = activeTypes.reduce((s, k) => s + byType[k].reduce((a, c) => a + c.n, 0), 0);

    // ── SVG-Setup ────────────────────────────────────────────────────────
    const NS = 'http://www.w3.org/2000/svg';
    const mk  = tag => document.createElementNS(NS, tag);
    const setA = (el, attrs) => { Object.entries(attrs).forEach(([k,v]) => el.setAttribute(k,v)); return el; };

    const wrapW = svgWrap.getBoundingClientRect().width || 720;
    const W     = Math.max(500, Math.min(wrapW, 860));
    const CX = W / 2, CY = W / 2, H = W;

    const R_CENTER  = 85;
    const R_INNER_S = R_CENTER + 10;
    const R_INNER_E = R_INNER_S + Math.round((W / 2 - R_CENTER - 14) * 0.25);
    const R_OUTER_S = R_INNER_E + 5;
    const R_OUTER_E = W / 2 - 2;

    const GAP_TYPE  = 0.012;   // Spalt zwischen Typen
    const GAP_FEAT  = 0.003;   // Spalt zwischen Phänomenen innerhalb eines Typs

    const svg = setA(mk('svg'), { width: W, height: H, viewBox: `0 0 ${W} ${H}` });
    svg.style.fontFamily = 'Geist, system-ui, sans-serif';
    svg.style.overflow   = 'visible';

    const polarXY = (r, a) => [CX + r * Math.cos(a), CY + r * Math.sin(a)];

    // Donut-Pfad
    function donutPath(r0, r1, a0, a1) {
        const lg = (a1 - a0 > Math.PI) ? 1 : 0;
        const [ax, ay] = polarXY(r0, a0); const [bx, by] = polarXY(r0, a1);
        const [cx, cy] = polarXY(r1, a1); const [dx, dy] = polarXY(r1, a0);
        return `M${ax},${ay} A${r0},${r0} 0 ${lg} 1 ${bx},${by} L${cx},${cy} A${r1},${r1} 0 ${lg} 0 ${dx},${dy} Z`;
    }

    // Rotiertes Label entlang des Bogens
    function rotatedLabel(text, rLabel, aMid, fontSize, fill, bold, pointerEvents) {
        const el = setA(mk('text'), {
            'text-anchor':       'middle',
            'dominant-baseline': 'middle',
            'font-size':         fontSize + 'px',
            'font-weight':       bold ? '700' : '400',
            fill,
            'pointer-events':    pointerEvents ? 'auto' : 'none',
        });
        el.textContent = text;

        // Rotationswinkel: tangential
        const deg    = aMid * 180 / Math.PI;
        const flip   = (aMid > Math.PI / 2 && aMid < 3 * Math.PI / 2);
        const rot    = flip ? deg + 90 : deg - 90;
        const [lx, ly] = polarXY(rLabel, aMid);
        el.setAttribute('transform', `translate(${lx},${ly}) rotate(${rot})`);
        return el;
    }

    // ── Winkel-Layout ────────────────────────────────────────────────────
    const START = -Math.PI / 2;
    let cursor  = START;
    const totalGapType = GAP_TYPE * activeTypes.length;
    const usable       = 2 * Math.PI - totalGapType;

    const typeSegs = [];
    activeTypes.forEach(k => {
        const items   = byType[k];
        const typeSum = items.reduce((s, c) => s + c.n, 0);
        const span    = (typeSum / totalWeight) * usable;
        const a0      = cursor + GAP_TYPE / 2;
        const a1      = a0 + span;
        cursor       += span + GAP_TYPE;

        // Phänomen-Segmente: proportional zu n, mit kleinem Spalt
        const totalFeatGap  = GAP_FEAT * Math.max(0, items.length - 1);
        const usableFeatArc = (a1 - a0) - totalFeatGap;
        let fc = a0;
        const itemSegs = items.map(cf => {
            const fs  = (cf.n / typeSum) * usableFeatArc;
            const fa0 = fc;
            const fa1 = fc + fs;
            fc        = fa1 + GAP_FEAT;
            return { cf, a0: fa0, a1: fa1 };
        });

        typeSegs.push({ k, color: (FTYPE_META[k]||{}).color||'#6b7280', a0, a1, items: itemSegs });
    });

    // ── Innerer Ring ─────────────────────────────────────────────────────
    typeSegs.forEach(({ k, color, a0, a1 }) => {
        const fullLabel = (FTYPE_META[k]||{}).label || k;
        const path = setA(mk('path'), {
            d: donutPath(R_INNER_S, R_INNER_E, a0, a1),
            fill: color, 'fill-opacity': '0.88',
            stroke: '#fff', 'stroke-width': '1.5',
        });
        path.style.cursor = 'default';
        path.addEventListener('mouseenter', e => pcTipShow(e, `<strong>${fullLabel}</strong>`));
        path.addEventListener('mousemove',  e => pcTipMove(e));
        path.addEventListener('mouseleave', pcTipHide);
        svg.appendChild(path);

        // Label: rotiert, mittig im inneren Ring
        const aMid   = (a0 + a1) / 2;
        const rMid   = (R_INNER_S + R_INNER_E) / 2;
        const arcLen = (a1 - a0) * rMid;
        const rDepth = R_INNER_E - R_INNER_S;
        const label  = fullLabel;
        const fs     = Math.min(11, Math.max(8, rDepth * 0.40));
        const maxC   = Math.floor(arcLen / (fs * 0.60));
        const short  = label.length > maxC ? label.slice(0, maxC - 1) + '…' : label;

        if (arcLen >= short.length * fs * 0.55 + 6) {
            svg.appendChild(rotatedLabel(short, rMid, aMid, fs, '#fff', true, false));
        }
    });

    // ── Äußerer Ring ─────────────────────────────────────────────────────
    typeSegs.forEach(({ k, color, items }) => {
        items.forEach(({ cf, a0, a1 }) => {
            if (a1 - a0 < 0.002) return;

            const pct     = Math.round(cf.n / plot.nDocs * 100);
            const tipHtml = `<strong>${cf.label}</strong>`
                + `<br><span style="font-size:10px;color:rgba(255,255,255,0.75)">`
                + `${(FTYPE_META[cf.ftype]||{}).singular || cf.ftype}</span>`
                + `<br>${fmtN(cf.n)} Rezeptionszeugnis${cf.n!==1?'se':''} (${pct}%)`;

            // Strichbreite skaliert mit Segmentgröße für deutlichere Kontraste
            const segFrac  = (a1 - a0) / (2 * Math.PI);
            const strokeW  = segFrac > 0.04 ? 1.8 : segFrac > 0.015 ? 1.0 : 0.4;

            const path = setA(mk('path'), {
                d: donutPath(R_OUTER_S, R_OUTER_E, a0, a1),
                fill: color, 'fill-opacity': '0.22',
                stroke: '#fff', 'stroke-width': String(strokeW),
            });
            path.style.cursor = 'default';
            path.addEventListener('mouseenter', e => {
                path.setAttribute('fill-opacity','0.50');
                pcTipShow(e, tipHtml);
            });
            path.addEventListener('mousemove',  e => pcTipMove(e));
            path.addEventListener('mouseleave', () => {
                path.setAttribute('fill-opacity','0.22');
                pcTipHide();
            });
            svg.appendChild(path);

            // Radiales Label im äußeren Segment: Text zeigt von innen nach außen
            const aMid   = (a0 + a1) / 2;
            const rDepth = R_OUTER_E - R_OUTER_S;
            const arcLen = (a1 - a0) * ((R_OUTER_S + R_OUTER_E) / 2);
            const fs     = Math.min(9.5, Math.max(7, rDepth * 0.17));

            if (arcLen >= 20) {
                const maxC  = Math.floor(rDepth * 0.88 / (fs * 0.58));
                const label = cf.label.length > maxC ? cf.label.slice(0, maxC - 1) + '…' : cf.label;

                const deg  = aMid * 180 / Math.PI;
                const flip = (aMid > Math.PI / 2 && aMid < 3 * Math.PI / 2);
                const rot  = flip ? deg + 180 : deg;

                const rLabel = (R_OUTER_S + R_OUTER_E) / 2;
                const [lx, ly] = polarXY(rLabel, aMid);

                const el = setA(mk('text'), {
                    'text-anchor':       'middle',
                    'dominant-baseline': 'middle',
                    'font-size':         fs + 'px',
                    fill:                '#374151',
                    'pointer-events':    'none',
                    transform:           `translate(${lx},${ly}) rotate(${rot})`,
                });
                el.textContent = label;
                svg.appendChild(el);
            }
        });
    });

    svg.appendChild(setA(mk('circle'), {
        cx: CX, cy: CY, r: R_CENTER,
        fill: '#5e17eb', 'fill-opacity': '0.10',
        stroke: '#5e17eb', 'stroke-width': '2',
    }));

    const CF = 12, CLH = CF * 1.3;
    const maxC = Math.floor((R_CENTER * 1.65) / (CF * 0.58));
    const cLines = [];
    let cCur = '';
    plot.label.split(' ').forEach(w => {
        const test = cCur ? cCur + ' ' + w : w;
        if (test.length > maxC && cCur) { cLines.push(cCur); cCur = w; }
        else cCur = test;
    });
    if (cCur) cLines.push(cCur);

    const totalCH = cLines.length * CLH + CF * 1.4;
    const cY0     = CY - totalCH / 2 + CLH / 2;
    cLines.forEach((line, i) => {
        svg.appendChild(setA(mk('text'), {
            x: CX, y: cY0 + i * CLH,
            'text-anchor': 'middle', 'dominant-baseline': 'middle',
            'font-size': CF + 'px', 'font-weight': '700', fill: '#5e17eb',
        })).textContent = line;
    });
    svg.appendChild(setA(mk('text'), {
        x: CX, y: cY0 + cLines.length * CLH + 2,
        'text-anchor': 'middle', 'dominant-baseline': 'middle',
        'font-size': '10px', fill: '#9ca3af',
    })).textContent = `n=${plot.nDocs}`;

    svgWrap.appendChild(svg);

    legend.style.display = 'flex';
    legend.innerHTML = '';
    activeTypes.forEach(k => {
        const m = FTYPE_META[k] || { label: k, color: '#6b7280' };
        const span = document.createElement('span');
        span.style.cssText = 'display:inline-flex;align-items:center;gap:5px';
        span.innerHTML = `<span style="display:inline-block;width:11px;height:11px;border-radius:2px;`
            + `background:${m.color};opacity:0.85;flex-shrink:0"></span>${m.label}`;
        legend.appendChild(span);
    });
}

document.addEventListener('DOMContentLoaded', initPlotComponents);

// ── Statistik 6: Personenreferenzen und Figuren (Balkendiagramm) ─────────────

const PD6 = {
    recPr:     'rgba(107,114,128,0.75)',
    recPrLine: '#6b7280',
    recCh:     'rgba(107,114,128,0.35)',
    recChLine: '#6b7280',
    sapPr:     'rgba(94,23,235,0.75)',
    sapPrLine: '#5e17eb',
    sapCh:     'rgba(94,23,235,0.35)',
    sapChLine: '#5e17eb',
};

let pd6Chart = null;

function renderPersonDuality() {
    const pd      = DATA.personDuality;
    const wrap    = document.getElementById('pd-chart-wrap');
    const metaBar = document.getElementById('pd-meta-bar');
    if (!pd || !pd.persons || !wrap) return;

    const topN   = parseInt(document.getElementById('sel-pd-topn').value) || 0;
    const filter = document.getElementById('sel-pd-filter').value;

    if (metaBar) {
        metaBar.innerHTML =
            `<span>Rezeptionszeugnisse: <strong>${fmtN(pd.nPersonRef)}</strong> Referenzen; <strong>${fmtN(pd.nBoth)}</strong> auch als Figuren</span>`
            + `<span style="margin-left:1.2rem">Sappho-Fragmente: <strong>${pd.nSapphoPersonRef}</strong> Referenzen; <strong>${pd.nSapphoCharacter}</strong> auch als Figuren</span>`;
    }

    let persons = pd.persons.slice();
    if (filter === 'both') persons = persons.filter(p => p.charN > 0 || p.sapChN > 0);
    if (topN > 0) persons = persons.slice(0, topN);

    persons.sort((a, b) =>
        parseFloat(b.pctRecPr) - parseFloat(a.pctRecPr) ||
        parseFloat(b.pctRecCh) - parseFloat(a.pctRecCh)
    );

    wrap.innerHTML = '';
    if (!persons.length) {
        wrap.innerHTML = '<p style="color:#9ca3af;padding:0.5rem 0">Keine Daten.</p>';
        return;
    }

    const canvas = document.createElement('canvas');
    canvas.style.height = canvasHeight(persons.length) + 'px';
    wrap.appendChild(canvas);

    const labels    = uniqueLabels(persons.map(p => p.label));
    const recPrData = persons.map(p => parseFloat(p.pctRecPr));
    const recChData = persons.map(p => parseFloat(p.pctRecCh));
    const sapPrData = persons.map(p => parseFloat(p.pctSapPr));
    const sapChData = persons.map(p => parseFloat(p.pctSapCh));

    const allVals = [...recPrData, ...recChData, ...sapPrData, ...sapChData];
    const rawMax  = Math.max(...allVals);
    const padded  = rawMax * 1.05;
    const maxX    = Math.min(100, Math.ceil(padded / 5) * 5) || 10;

    if (pd6Chart) { pd6Chart.destroy(); pd6Chart = null; }

    pd6Chart = new Chart(canvas.getContext('2d'), {
        type: 'bar',
        data: {
            labels,
            datasets: [
                {
                    label: `pers_ref – Sappho (n = ${fmtN(DATA.nSappho)})`,
                    data: sapPrData,
                    backgroundColor: PD6.sapPr,
                    borderColor: PD6.sapPrLine,
                    borderWidth: 1,
                    borderRadius: 2,
                },
                {
                    label: `character – Sappho (n = ${fmtN(DATA.nSappho)})`,
                    data: sapChData,
                    backgroundColor: PD6.sapCh,
                    borderColor: PD6.sapChLine,
                    borderWidth: 1,
                    borderRadius: 2,
                },
                {
                    label: `pers_ref – Rezeption (n = ${fmtN(DATA.nReception)})`,
                    data: recPrData,
                    backgroundColor: PD6.recPr,
                    borderColor: PD6.recPrLine,
                    borderWidth: 1,
                    borderRadius: 2,
                },
                {
                    label: `character – Rezeption (n = ${fmtN(DATA.nReception)})`,
                    data: recChData,
                    backgroundColor: PD6.recCh,
                    borderColor: PD6.recChLine,
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
                            const p = persons[ctx.dataIndex];
                            const configs = [
                                { lbl: 'Referenz in Sappho-Fragmenten',    n: p.sapPrN,  total: DATA.nSappho    },
                                { lbl: 'Figur in Sappho-Fragmenten',       n: p.sapChN,  total: DATA.nSappho    },
                                { lbl: 'Referenz in Rezeptionszeugnissen', n: p.persRefN, total: DATA.nReception },
                                { lbl: 'Figur in Rezeptionszeugnissen',    n: p.charN,   total: DATA.nReception },
                            ];
                            const { lbl, n, total } = configs[ctx.datasetIndex];
                            const pct = ctx.parsed.x.toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2});
                            return ` ${lbl}: ${pct}% (${n}/${total})`;
                        },
                    },
                },
            },
            scales: {
                x: {
                    min: 0,
                    max: maxX,
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 11 },
                        callback: v => v + '%',
                        stepSize: 5,
                    },
                    grid: { color: 'rgba(0,0,0,0.06)' },
                },
                y: {
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 12 },
                        autoSkip: false,
                    },
                    grid: { display: false },
                },
            },
        },
    });
}

function initPersonDuality() {
    const pd = DATA.personDuality;
    if (!pd || !pd.persons || pd.persons.length === 0) return;
    document.getElementById('sel-pd-topn')?.addEventListener('change',   renderPersonDuality);
    document.getElementById('sel-pd-filter')?.addEventListener('change', renderPersonDuality);
    renderPersonDuality();
}

document.addEventListener('DOMContentLoaded', initPersonDuality);
// ── Statistik 7: Werkreferenzen × Zitate ─────────────────────────────────

let wc7Chart = null;

// ─── Tooltip-Instanz für Stat 7 ─────────────────────────────────────────────
let _wc7Tip = null;
function getWc7Tip() {
    if (!_wc7Tip) {
        _wc7Tip = document.createElement('div');
        _wc7Tip.style.cssText =
            'position:fixed;background:#1f2937;color:#fff;font-size:12px;'
            + 'font-family:Geist,system-ui,sans-serif;padding:5px 9px;border-radius:5px;'
            + 'pointer-events:none;display:none;z-index:9999;white-space:nowrap;line-height:1.5';
        document.body.appendChild(_wc7Tip);
    }
    return _wc7Tip;
}
function wc7TipHide() { if (_wc7Tip) _wc7Tip.style.display = 'none'; }

// Bereinigt Labels: "Reference to " am Anfang entfernen
function wc7CleanLabel(label) {
    return label.replace(/^Reference to\s+/i, '').replace(/^Expression of\s+/i, '');
}

// ─── Balkendiagramm ──────────────────────────────────────────────────────────
function renderWorkCitation() {
    const wc   = DATA.workCitation;
    const wrap = document.getElementById('wc-chart-wrap');
    if (!wc || !wc.works || !wrap) return;

    const works = wc.works
        .filter(w => w.refN > 0)
        .slice()
        .sort((a, b) => b.bothN - a.bothN || b.refN - a.refN);

    if (!works.length) {
        wrap.innerHTML = '<p style="color:#9ca3af;padding:0.5rem 0">Keine Daten.</p>';
        return;
    }

    const labels  = uniqueLabels(works.map(w => wc7CleanLabel(w.label)));
    const pctRef  = works.map(w => parseFloat(w.pctRef));
    const pctBoth = works.map(w => parseFloat(w.pctBoth));

    const rawMax = Math.max(...pctRef, 0.1);
    const maxX   = Math.min(100, Math.ceil(rawMax * 1.05 / 5) * 5) || 10;
    const height = canvasHeight(works.length);

    wrap.innerHTML = `<canvas id="wc-bar-canvas" style="width:100%;height:${height}px"/>`;
    const canvas = document.getElementById('wc-bar-canvas');

    if (wc7Chart) { wc7Chart.destroy(); wc7Chart = null; }

    wc7Chart = new Chart(canvas.getContext('2d'), {
        type: 'bar',
        data: {
            labels,
            datasets: [
                {
                    label: `Referenziert (n = ${fmtN(wc.nReception)})`,
                    data:  pctRef,
                    backgroundColor: 'rgba(107,114,128,0.75)',
                    borderColor:     '#6b7280',
                    borderWidth: 1,
                    borderRadius: 2,
                },
                {
                    label: `Referenziert und zitiert (n = ${fmtN(wc.nReception)})`,
                    data:  pctBoth,
                    backgroundColor: 'rgba(8,145,178,0.75)',
                    borderColor:     '#0891b2',
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
                    enabled: false,
                    external: ({ chart, tooltip }) => {
                        if (tooltip.opacity === 0) { wc7TipHide(); return; }
                        const idx = tooltip.dataPoints?.[0]?.dataIndex;
                        if (idx == null) return;
                        const w    = works[idx];
                        const pctR = parseFloat(w.pctRef).toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2});
                        const pctB = parseFloat(w.pctBoth).toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2});
                        const html =
                            `<strong>${wc7CleanLabel(w.label)}</strong>`
                            + `<br><span style="color:rgba(255,255,255,0.85)">Referenziert: ${pctR}% (${fmtN(w.refN)}/${fmtN(wc.nReception)})</span>`
                            + `<br><span style="color:rgba(255,255,255,0.85)">Referenziert und zitiert: ${pctB}% (${fmtN(w.bothN)}/${fmtN(wc.nReception)})</span>`;
                        const t = getWc7Tip();
                        t.innerHTML     = html;
                        t.style.display = 'block';
                        const e = tooltip._eventPosition;
                        if (e) {
                            const pos = chart.canvas.getBoundingClientRect();
                            t.style.left = (pos.left + window.scrollX + e.x + 14) + 'px';
                            t.style.top  = (pos.top  + window.scrollY + e.y - 36) + 'px';
                        }
                    },
                },
            },
            scales: {
                x: {
                    min: 0, max: maxX,
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 11 },
                        callback: v => v + '%',
                        stepSize: 5,
                    },
                    grid: { color: 'rgba(0,0,0,0.06)' },
                },
                y: {
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 12 },
                        autoSkip: false,
                    },
                    grid: { display: false },
                },
            },
        },
    });

}

// ─── Init ────────────────────────────────────────────────────────────────────
function initWorkCitation() {
    const wc = DATA.workCitation;
    if (!wc || !wc.works || wc.works.length === 0) return;
    renderWorkCitation();
}

document.addEventListener('DOMContentLoaded', initWorkCitation);

// ── Statistik 8: INT31 Co-Occurrence ─────────────────────────────────────────

let _int31Tip = null;
function getInt31Tip() {
    if (!_int31Tip) {
        _int31Tip = document.createElement('div');
        _int31Tip.style.cssText =
            'position:fixed;background:#1f2937;color:#fff;font-size:12px;'
            + 'font-family:Geist,system-ui,sans-serif;padding:5px 9px;border-radius:5px;'
            + 'pointer-events:none;display:none;z-index:9999;white-space:nowrap;line-height:1.5';
        document.body.appendChild(_int31Tip);
    }
    return _int31Tip;
}
function int31TipShow(e, html) {
    const t = getInt31Tip(); t.innerHTML = html; t.style.display = 'block'; int31TipMove(e);
}
function int31TipMove(e) {
    const t = getInt31Tip();
    t.style.left = (e.clientX + 14) + 'px';
    t.style.top  = (e.clientY - 36) + 'px';
}
function int31TipHide() { if (_int31Tip) _int31Tip.style.display = 'none'; }

// ── Meta-Bar ─────────────────────────────────────────────────────────────────
function renderInt31MetaBar() {
    const co   = DATA.int31CoOccurrence;
    const wrap = document.getElementById('int31-meta-bar');
    if (!co || !wrap) return;
    wrap.innerHTML =
        `<div style="text-align:center;margin-bottom:0.5rem">`
        + `<span style="font-size:2rem;font-weight:700;color:#1f2937">${fmtN(co.nInt31All)}</span>`
        + `<span style="font-size:0.9rem;color:#6b7280;margin-left:0.5rem">intertextuelle Relationen gesamt</span>`
        + `</div>`;
}

// ── Phänomentyp-Balken ───────────────────────────────────────────────────────
function renderInt31FtypeBar() {
    const co   = DATA.int31CoOccurrence;
    const wrap = document.getElementById('int31-ftype-bar-wrap');
    if (!co || !wrap) return;

    const typeSum = {};
    (co.featFrequencies || []).forEach(f => {
        typeSum[f.ftype] = (typeSum[f.ftype] || 0) + f.n;
    });

    const items = Object.keys(FTYPE_META)
        .filter(k => typeSum[k] > 0)
        .map(k => ({ key: k, label: (FTYPE_META[k] || {}).label || k, n: typeSum[k] }));

    if (!items.length) { wrap.innerHTML = '<p style="color:#9ca3af">Keine Daten.</p>'; return; }

    const legWrap = document.getElementById('int31-ftype-legend');
    if (legWrap) {
        legWrap.innerHTML = '';
        items.forEach(it => {
            const m = FTYPE_META[it.key] || { color: '#6b7280' };
            const span = document.createElement('span');
            span.style.cssText = 'display:inline-flex;align-items:center;gap:5px';
            span.innerHTML = `<span style="display:inline-block;width:11px;height:11px;border-radius:2px;background:${m.color};opacity:0.85;flex-shrink:0"></span>${it.label}`;
            legWrap.appendChild(span);
        });
    }

    const total  = co.nInt31WithFeats || 1;
    const labels = uniqueLabels(items.map(it => it.label));
    const pcts   = items.map(it => parseFloat((it.n / total * 100).toFixed(2)));
    const colors = items.map(it => (FTYPE_META[it.key] || {}).color || '#6b7280');
    const height = canvasHeight(items.length);
    wrap.innerHTML = `<canvas id="int31-ftype-canvas" style="height:${height}px"></canvas>`;
    const ctx = document.getElementById('int31-ftype-canvas').getContext('2d');
    const maxX = Math.min(100, Math.ceil(Math.max(...pcts, 1) * 1.05 / 5) * 5) || 10;

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels,
            datasets: [{ label: `INT31-Knoten (n=${total})`, data: pcts,
                backgroundColor: colors.map(c => c + 'bf'), borderColor: colors,
                borderWidth: 1.5, borderRadius: 3 }],
        },
        options: {
            indexAxis: 'y', responsive: true, maintainAspectRatio: false,
            plugins: { legend: { display: false },
                tooltip: { callbacks: { label: ctx2 => {
                    const it = items[ctx2.dataIndex];
                    return ` ${fmtN(it.n)} INT31-Knoten (${ctx2.parsed.x.toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2})}%)`;
                }}}},
            scales: {
                x: { min: 0, max: maxX,
                    ticks: { font: { family: 'Geist, system-ui', size: 11 }, callback: v => v + '%', stepSize: 10 },
                    grid: { color: 'rgba(0,0,0,0.06)' } },
                y: { ticks: { font: { family: 'Geist, system-ui', size: 12 }, autoSkip: false },
                    grid: { display: false } },
            },
        },
    });
}

// ── Sunburst + Sehnen ────────────────────────────────────────────────────────
function renderInt31Sunburst() {
    const co      = DATA.int31CoOccurrence;
    const wrap    = document.getElementById('int31-sunburst-wrap');
    const legWrap = document.getElementById('int31-sunburst-legend');
    if (!co || !wrap) return;

    const topN = parseInt(document.getElementById('sel-int31-topn')?.value || '10');

    const feats = topN > 0 ? co.featFrequencies.slice(0, topN) : co.featFrequencies;
    if (!feats.length) {
        wrap.innerHTML = '<p style="color:#9ca3af;text-align:center">Keine Daten.</p>';
        return;
    }

    const featUris = new Set(feats.map(f => f.uri));
    const total    = co.nInt31WithFeats || 1;

    const pairIndex = {};
    (co.featPairs || []).forEach(p => {
        if (!featUris.has(p.uriA) || !featUris.has(p.uriB)) return;
        pairIndex[p.uriA + '|||' + p.uriB] = p.n;
        pairIndex[p.uriB + '|||' + p.uriA] = p.n;
    });
    const maxPair = Math.max(1, ...Object.values(pairIndex));

    const typeOrder = Object.keys(FTYPE_META);
    const byType = {};
    typeOrder.forEach(k => { byType[k] = []; });
    feats.forEach(f => { if (byType[f.ftype]) byType[f.ftype].push(f); });
    const activeTypes = typeOrder.filter(k => byType[k] && byType[k].length > 0);

    const NS   = 'http://www.w3.org/2000/svg';
    const mk   = tag => document.createElementNS(NS, tag);
    const setA = (el, attrs) => { Object.entries(attrs).forEach(([k,v]) => el.setAttribute(k,v)); return el; };

    const wrapW = wrap.getBoundingClientRect().width || 720;
    const W     = Math.max(520, Math.min(wrapW - 20, 860));
    const CX = W / 2, CY = W / 2;

    const R_CHORD_IN  = W * 0.22;
    const R_INNER_S   = R_CHORD_IN + W * 0.005;
    const R_INNER_E   = R_INNER_S  + W * 0.055;
    const R_OUTER_S   = R_INNER_E  + W * 0.010;
    const R_OUTER_E   = W * 0.43;

    const GAP_TYPE = 0.014;
    const GAP_FEAT = 0.004;

    const svg = setA(mk('svg'), { width: W, height: W, viewBox: `0 0 ${W} ${W}` });
    svg.style.cssText = 'font-family:Geist,system-ui,sans-serif;overflow:visible';

    const polar = (r, a) => [CX + r * Math.cos(a), CY + r * Math.sin(a)];

    function donutPath(r0, r1, a0, a1) {
        const lg = (a1 - a0) > Math.PI ? 1 : 0;
        const [ax,ay] = polar(r0,a0); const [bx,by] = polar(r0,a1);
        const [cx2,cy2] = polar(r1,a1); const [dx,dy] = polar(r1,a0);
        return `M${ax},${ay} A${r0},${r0} 0 ${lg} 1 ${bx},${by} L${cx2},${cy2} A${r1},${r1} 0 ${lg} 0 ${dx},${dy} Z`;
    }

    const logN      = f => Math.log1p(f.n);
    const START     = -Math.PI / 2;
    const totalGapT = GAP_TYPE * activeTypes.length;
    const usableT   = 2 * Math.PI - totalGapT;
    const typeSums  = activeTypes.map(k => byType[k].reduce((s, f) => s + logN(f), 0));
    const typeGrand = typeSums.reduce((a, b) => a + b, 0) || 1;

    const featAngle = {};
    const typeSegs  = [];
    let cursor = START;

    activeTypes.forEach((k, ti) => {
        const typeSpan = (typeSums[ti] / typeGrand) * usableT;
        const ta0 = cursor + GAP_TYPE / 2;
        const ta1 = ta0 + typeSpan;
        cursor += typeSpan + GAP_TYPE;

        const items        = byType[k];
        const typeSum      = typeSums[ti] || 1;
        const totalFeatGap = GAP_FEAT * Math.max(0, items.length - 1);
        const usableFeat   = (ta1 - ta0) - totalFeatGap;

        let fc = ta0;
        const itemSegs = items.map(f => {
            const span = (logN(f) / typeSum) * usableFeat;
            const fa0  = fc;
            const fa1  = fc + span;
            fc = fa1 + GAP_FEAT;
            const aMid = (fa0 + fa1) / 2;
            featAngle[f.uri] = { a0: fa0, a1: fa1, aMid };
            return { f, a0: fa0, a1: fa1, aMid };
        });

        typeSegs.push({ k, color: (FTYPE_META[k]||{}).color||'#6b7280', ta0, ta1, itemSegs });
    });

    // Sehnen
    const chordGroup = mk('g');
    feats.forEach((fA, iA) => {
        feats.forEach((fB, iB) => {
            if (iB <= iA) return;
            const n = pairIndex[fA.uri + '|||' + fB.uri];
            if (!n) return;
            const angA = featAngle[fA.uri];
            const angB = featAngle[fB.uri];
            if (!angA || !angB) return;

            const colorA  = (FTYPE_META[fA.ftype]||{}).color || '#6b7280';
            const [ax,ay] = polar(R_INNER_S, angA.aMid);
            const [bx,by] = polar(R_INNER_S, angB.aMid);
            const strokeW = 1.5 + Math.pow(n / maxPair, 0.55) * 7;
            const opacity = 0.20 + 0.60 * Math.pow(n / maxPair, 0.5);

            const path = setA(mk('path'), {
                d: `M${ax},${ay} Q${CX},${CY} ${bx},${by}`,
                fill: 'none', stroke: colorA,
                'stroke-width':   strokeW.toFixed(1),
                'stroke-opacity': opacity.toFixed(2),
                'stroke-linecap': 'round',
            });
            path.style.cursor = 'default';

            const ftA = (FTYPE_META[fA.ftype]||{}).singular || fA.ftype;
            const ftB = (FTYPE_META[fB.ftype]||{}).singular || fB.ftype;
            const pct = (n / total * 100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1});
            const tipHtml =
                `<strong>${fA.label}</strong> <span style="color:rgba(255,255,255,0.6)">(${ftA})</span>`
                + `<br>× <strong>${fB.label}</strong> <span style="color:rgba(255,255,255,0.6)">(${ftB})</span>`
                + `<br><strong>${fmtN(n)}</strong> gemeinsame INT31-Knoten (${pct}%)`;

            path.addEventListener('mouseenter', e => { path.setAttribute('stroke-opacity','0.92'); int31TipShow(e,tipHtml); });
            path.addEventListener('mousemove',  e => int31TipMove(e));
            path.addEventListener('mouseleave', () => { path.setAttribute('stroke-opacity',opacity.toFixed(2)); int31TipHide(); });
            chordGroup.appendChild(path);
        });
    });
    svg.appendChild(chordGroup);

    // Innerer Ring (Typen)
    typeSegs.forEach(({ k, color, ta0, ta1 }) => {
        const label = (FTYPE_META[k]||{}).label || k;
        const arcEl = setA(mk('path'), {
            d: donutPath(R_INNER_S, R_INNER_E, ta0, ta1),
            fill: color, 'fill-opacity': '0.88',
            stroke: '#fff', 'stroke-width': '1.0',
        });
        arcEl.style.cursor = 'default';
        arcEl.addEventListener('mouseenter', e => int31TipShow(e, `<strong>${label}</strong>`));
        arcEl.addEventListener('mousemove',  e => int31TipMove(e));
        arcEl.addEventListener('mouseleave', int31TipHide);
        svg.appendChild(arcEl);

        const aMid   = (ta0 + ta1) / 2;
        const rMid   = (R_INNER_S + R_INNER_E) / 2;
        const arcLen = (ta1 - ta0) * rMid;
        const rDepth = R_INNER_E - R_INNER_S;
        const fs     = Math.min(10, Math.max(7, rDepth * 0.38));
        const maxC   = Math.floor(arcLen / (fs * 0.58));
        const short  = label.length > maxC ? label.slice(0, maxC - 1) + '…' : label;
        if (arcLen >= short.length * fs * 0.52 + 4) {
            const [lx, ly] = polar(rMid, aMid);
            const deg  = aMid * 180 / Math.PI;
            const flip = aMid > Math.PI / 2 && aMid < 3 * Math.PI / 2;
            svg.appendChild(setA(mk('text'), {
                'text-anchor': 'middle', 'dominant-baseline': 'middle',
                'font-size': fs + 'px', 'font-weight': '700',
                fill: '#fff', 'pointer-events': 'none',
                transform: `translate(${lx},${ly}) rotate(${flip ? deg+90 : deg-90})`,
            })).textContent = short;
        }
    });

    // Äußerer Ring (Phänomene)
    typeSegs.forEach(({ k, color, itemSegs }) => {
        itemSegs.forEach(({ f, a0, a1, aMid }) => {
            if (a1 - a0 < 0.002) return;
            const pct    = (f.n / total * 100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1});
            const ft     = (FTYPE_META[f.ftype]||{}).singular || f.ftype;
            const tipHtml =
                `<strong>${f.label}</strong>`
                + `<br><span style="font-size:10px;color:rgba(255,255,255,0.7)">(${ft})</span>`
                + `<br><strong>${fmtN(f.n)}</strong> INT31-Knoten (${pct}%)`;

            const segFrac = (a1 - a0) / (2 * Math.PI);
            const strokeW = segFrac > 0.04 ? 1.8 : segFrac > 0.015 ? 1.0 : 0.4;

            const pathEl = setA(mk('path'), {
                d: donutPath(R_OUTER_S, R_OUTER_E, a0, a1),
                fill: color, 'fill-opacity': '0.22',
                stroke: '#fff', 'stroke-width': String(strokeW),
            });
            pathEl.style.cursor = 'default';
            pathEl.addEventListener('mouseenter', e => { pathEl.setAttribute('fill-opacity','0.55'); int31TipShow(e,tipHtml); });
            pathEl.addEventListener('mousemove',  e => int31TipMove(e));
            pathEl.addEventListener('mouseleave', () => { pathEl.setAttribute('fill-opacity','0.22'); int31TipHide(); });
            svg.appendChild(pathEl);

            const rDepth = R_OUTER_E - R_OUTER_S;
            const arcLen = (a1 - a0) * ((R_OUTER_S + R_OUTER_E) / 2);
            const fs     = Math.min(9, Math.max(6.5, rDepth * 0.16));
            if (arcLen >= 18) {
                const maxC = Math.floor(rDepth * 0.88 / (fs * 0.58));
                const lbl  = f.label.length > maxC ? f.label.slice(0, maxC - 1) + '…' : f.label;
                const deg  = aMid * 180 / Math.PI;
                const flip = aMid > Math.PI / 2 && aMid < 3 * Math.PI / 2;
                const [lx, ly] = polar((R_OUTER_S + R_OUTER_E) / 2, aMid);
                svg.appendChild(setA(mk('text'), {
                    'text-anchor': 'middle', 'dominant-baseline': 'middle',
                    'font-size': fs + 'px', fill: '#374151', 'pointer-events': 'none',
                    transform: `translate(${lx},${ly}) rotate(${flip ? deg+180 : deg})`,
                })).textContent = lbl;
            }
        });
    });

    // Zentraler Kreis
    const R_CENTRE_VIS = R_CHORD_IN * 0.55;
    svg.appendChild(setA(mk('circle'), {
        cx: CX, cy: CY, r: R_CENTRE_VIS,
        fill: '#5e17eb', 'fill-opacity': '0.07',
        stroke: '#5e17eb', 'stroke-width': '1.5',
    }));

    wrap.innerHTML = '';
    wrap.appendChild(svg);

    // Legende
    if (legWrap) {
        legWrap.style.cssText = 'display:flex;flex-wrap:wrap;justify-content:center;gap:8px 16px;margin-top:0.75rem';
        legWrap.innerHTML = '';
        activeTypes.forEach(k => {
            const m = FTYPE_META[k] || { label: k, color: '#6b7280' };
            const span = document.createElement('span');
            span.style.cssText = 'display:inline-flex;align-items:center;gap:5px;font-size:11px';
            span.innerHTML = `<span style="display:inline-block;width:11px;height:11px;border-radius:2px;`
                + `background:${m.color};opacity:0.85;flex-shrink:0"></span>${m.label}`;
            legWrap.appendChild(span);
        });
    }
}

// ── Kombinationsliste ────────────────────────────────────────────────────────
function renderInt31Pairs() {
    const co   = DATA.int31CoOccurrence;
    const wrap = document.getElementById('int31-pairs-wrap');
    if (!co || !wrap) return;

    const topN  = Math.min(50, parseInt(document.getElementById('sel-int31-pairs-topn')?.value || '30'));
    const pairs = co.featPairs.slice(0, topN);
    if (!pairs.length) { wrap.innerHTML = '<p style="color:#9ca3af">Keine Paare gefunden.</p>'; return; }

    const total  = co.nInt31WithFeats || 1;
    const maxN   = pairs[0]?.n || 1;

    const NS   = 'http://www.w3.org/2000/svg';
    const mkE  = tag => document.createElementNS(NS, tag);
    const setA = (el, attrs) => { Object.entries(attrs).forEach(([k,v]) => el.setAttribute(k,v)); return el; };

    const BAR_H    = 18;
    const GAP_Y    = 4;
    const LABEL_W  = 520;
    const BAR_MAX  = 320;
    const COUNT_W  = 80;
    const FONT_W   = 6.2;
    const MAX_HALF = Math.floor((LABEL_W / 2 - 10) / FONT_W);
    const PAD_B    = 8;

    const svgW = LABEL_W + BAR_MAX + COUNT_W;
    const svgH = pairs.length * (BAR_H + GAP_Y) + PAD_B;

    const svg = setA(mkE('svg'), { width: svgW, height: svgH,
        viewBox: `0 0 ${svgW} ${svgH}`, preserveAspectRatio: 'xMinYMin meet' });
    svg.style.cssText = 'font-family:Geist,system-ui,sans-serif;display:block;overflow:visible;width:100%';

    pairs.forEach((pair, ri) => {
        const y0     = ri * (BAR_H + GAP_Y);
        const yc     = y0 + BAR_H / 2;
        const colorA = (FTYPE_META[pair.ftypeA]||{}).color || '#6b7280';
        const colorB = (FTYPE_META[pair.ftypeB]||{}).color || '#6b7280';

        if (ri % 2 === 0)
            svg.appendChild(setA(mkE('rect'), { x:0, y:y0, width:svgW, height:BAR_H, fill:'rgba(0,0,0,0.018)' }));

        const shortA = pair.labelA.length > MAX_HALF ? pair.labelA.slice(0, MAX_HALF-1) + '…' : pair.labelA;
        svg.appendChild(setA(mkE('text'), { x: LABEL_W/2-6, y: yc,
            'text-anchor':'end', 'dominant-baseline':'middle', 'font-size':'10.5px', fill:colorA,
        })).textContent = shortA;

        svg.appendChild(setA(mkE('text'), { x: LABEL_W/2, y: yc,
            'text-anchor':'middle', 'dominant-baseline':'middle', 'font-size':'10px', fill:'#9ca3af',
        })).textContent = '×';

        const shortB = pair.labelB.length > MAX_HALF ? pair.labelB.slice(0, MAX_HALF-1) + '…' : pair.labelB;
        svg.appendChild(setA(mkE('text'), { x: LABEL_W/2+6, y: yc,
            'text-anchor':'start', 'dominant-baseline':'middle', 'font-size':'10.5px', fill:colorB,
        })).textContent = shortB;

        const barW  = Math.max(2, Math.round((pair.n / maxN) * BAR_MAX));
        const halfW = Math.round(barW / 2);
        svg.appendChild(setA(mkE('rect'), { x:LABEL_W, y:y0+2, width:halfW, height:BAR_H-4, fill:colorA, 'fill-opacity':'0.65', rx:2 }));
        svg.appendChild(setA(mkE('rect'), { x:LABEL_W+halfW, y:y0+2, width:barW-halfW, height:BAR_H-4, fill:colorB, 'fill-opacity':'0.65' }));

        const pct = (pair.n / total * 100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1});
        svg.appendChild(setA(mkE('text'), { x:LABEL_W+barW+5, y:yc,
            'dominant-baseline':'middle', 'font-size':'10px', fill:'#6b7280' }))
            .textContent = `${pair.n} (${pct}%)`;

        const overlay = setA(mkE('rect'), { x:0, y:y0, width:svgW, height:BAR_H, fill:'transparent' });
        overlay.style.cursor = 'default';
        const ftA = (FTYPE_META[pair.ftypeA]||{}).singular || pair.ftypeA;
        const ftB = (FTYPE_META[pair.ftypeB]||{}).singular || pair.ftypeB;
        const tipHtml = `<strong>${pair.labelA}</strong> <span style="color:rgba(255,255,255,0.6)">(${ftA})</span>`
            + `<br>× <strong>${pair.labelB}</strong> <span style="color:rgba(255,255,255,0.6)">(${ftB})</span>`
            + `<br><strong>${fmtN(pair.n)}</strong> gemeinsame INT31-Knoten (${pct}%)`;
        overlay.addEventListener('mouseenter', e => int31TipShow(e, tipHtml));
        overlay.addEventListener('mousemove',  e => int31TipMove(e));
        overlay.addEventListener('mouseleave', int31TipHide);
        svg.appendChild(overlay);
    });

    const scroller = document.createElement('div');
    scroller.style.cssText = 'overflow-x:auto;overflow-y:auto;max-height:700px;padding-bottom:4px';
    scroller.appendChild(svg);
    wrap.innerHTML = '';
    wrap.appendChild(scroller);
}

// ── Statistik 9: Top-N INT31-Knoten ───────────────

function renderInt31TopNodes() {
    const tn   = DATA.int31TopNodes;
    const wrap = document.getElementById('stat9-cards-wrap');
    if (!tn || !wrap) return;

    const topN    = parseInt(document.getElementById('sel-stat9-topn')?.value || '5');
    const relType = document.getElementById('sel-stat9-reltype')?.value || 'all';

    const filtered = relType === 'all'
        ? (tn.nodes || [])
        : (tn.nodes || []).filter(n => n.relType === relType);
    const nodes = filtered.slice(0, topN);

    wrap.innerHTML = '';

    nodes.forEach((node, rank) => {
        const texts = node.texts || [];
        const basis = node.basis || [];

        // ── Karte ─────────────────────────────────────────────────────────
        const card = document.createElement('div');
        card.style.cssText =
            'background:#fff;border:1.5px solid #e5e7eb;border-radius:10px;'
            + 'padding:16px 18px 14px;margin-bottom:18px;'
            + 'box-shadow:0 1px 4px rgba(0,0,0,0.06)';

        // ── Kopfzeile ─────
        const header = document.createElement('div');
        header.style.cssText =
            'display:flex;align-items:center;justify-content:space-between;'
            + 'gap:8px;margin-bottom:8px';

        const badge = document.createElement('span');
        badge.style.cssText =
            'display:inline-flex;align-items:center;justify-content:center;flex-shrink:0;'
            + 'width:22px;height:22px;border-radius:50%;background:#5e17eb;'
            + 'color:#fff;font-size:11px;font-weight:700;line-height:1';
        badge.textContent = String(rank + 1);

        const pillFeat = document.createElement('span');
        pillFeat.style.cssText =
            'flex-shrink:0;font-size:11px;padding:2px 9px;border-radius:99px;'
            + 'background:rgba(94,23,235,0.08);color:#5e17eb;font-weight:600;white-space:nowrap';
        pillFeat.textContent = `${node.nFeats} gemeinsame Phänomene`;

        header.appendChild(badge);
        header.appendChild(pillFeat);
        card.appendChild(header);

        // ── Titel ───────────────────────────────
        const title = document.createElement('p');
        title.style.cssText =
            'text-align:center;font-size:13px;font-weight:600;color:#1f2937;'
            + 'margin:0 0 12px;line-height:1.45;word-break:break-word';
        title.textContent = node.cardLabel;
        card.appendChild(title);

        // ── Verbundene Texte ──────────────────────────────
        const textHead = document.createElement('p');
        textHead.style.cssText =
            'font-size:11px;font-weight:700;color:#9ca3af;margin:0 0 5px;'
            + 'text-transform:uppercase;letter-spacing:0.05em;text-align:center';
        textHead.textContent = 'Verbundene Texte';
        card.appendChild(textHead);

        const textList = document.createElement('div');
        textList.style.cssText =
            'display:flex;flex-wrap:wrap;gap:4px;margin-bottom:14px;justify-content:center';

        texts.forEach(t => {
            const isSap = t.isSappho;
            const chip  = document.createElement('a');
            chip.href   = t.pageUrl || '#';
            chip.target = '_blank';
            chip.rel    = 'noopener noreferrer';
            chip.style.cssText =
                'display:inline-flex;align-items:center;gap:4px;font-size:11px;padding:2px 8px;'
                + 'border-radius:99px;max-width:260px;text-decoration:none;'
                + (isSap
                    ? 'background:rgba(94,23,235,0.08);color:#5e17eb;border:1px solid rgba(94,23,235,0.2)'
                    : 'background:#f3f4f6;color:#374151;border:1px solid #e5e7eb');
            const dot = document.createElement('span');
            dot.style.cssText =
                'display:inline-block;width:6px;height:6px;border-radius:50%;flex-shrink:0;'
                + `background:${isSap ? '#5e17eb' : '#6b7280'}`;
            const lbl = document.createElement('span');
            lbl.style.cssText = 'overflow:hidden;text-overflow:ellipsis;white-space:nowrap';
            lbl.textContent   = t.label;
            lbl.title         = t.label;
            chip.appendChild(dot);
            chip.appendChild(lbl);
            textList.appendChild(chip);
        });
        card.appendChild(textList);

        // ── Trennlinie ────────────────────────────────────────────────────
        const hr = document.createElement('div');
        hr.style.cssText = 'border-top:1px solid #f3f4f6;margin-bottom:10px';
        card.appendChild(hr);

        // ── Grundlage der Ähnlichkeit ───────────────────────
        if (basis.length) {
            const bHead = document.createElement('p');
            bHead.style.cssText =
                'font-size:11px;font-weight:700;color:#9ca3af;margin:0 0 6px;'
                + 'text-transform:uppercase;letter-spacing:0.05em';
            bHead.textContent = 'Grundlage der Ähnlichkeit';
            card.appendChild(bHead);

            const ftypeOrder = [
                'person_ref','character','place_ref','topos','motif',
                'topic','plot','text_passage','work_ref','other',
            ];
            const ftypeLabels = {
                person_ref:   'Personenreferenzen',
                character:    'Figuren',
                place_ref:    'Ortsreferenzen',
                topos:        'Rhetorische Topoi',
                motif:        'Motive',
                topic:        'Themen',
                plot:         'Stoffe',
                text_passage: 'Textpassagen',
                work_ref:     'Werkreferenzen',
                other:        'Sonstige',
            };

            const byType = {};
            basis.forEach(b => {
                const ft = b.ftype || 'other';
                if (!byType[ft]) byType[ft] = [];
                byType[ft].push(b.label.replace(/\s+/g, ' ').trim());
            });

            const basisWrap = document.createElement('div');
            basisWrap.style.cssText = 'display:flex;flex-direction:column;gap:3px';

            ftypeOrder.forEach(ft => {
                const items = byType[ft];
                if (!items || !items.length) return;
                const color = (FTYPE_META[ft] || {}).color || '#6b7280';

                const row = document.createElement('div');
                row.style.cssText = 'display:flex;align-items:flex-start;gap:6px;text-align:left';

                const typeLbl = document.createElement('span');
                typeLbl.style.cssText =
                    `font-size:10.5px;font-weight:700;color:${color};`
                    + 'white-space:nowrap;padding-top:1px;min-width:110px;flex-shrink:0';
                typeLbl.textContent = (ftypeLabels[ft] || ft) + ':';

                const itemsSpan = document.createElement('span');
                itemsSpan.style.cssText = 'font-size:10.5px;color:#4b5563;line-height:1.5;text-align:left';
                itemsSpan.textContent   = items.join(', ');

                row.appendChild(typeLbl);
                row.appendChild(itemsSpan);
                basisWrap.appendChild(row);
            });

            card.appendChild(basisWrap);
        }

        wrap.appendChild(card);
    });
}

// ── Init ─────────────────────────────────────────────────────────────────────
function initInt31CoOccurrence() {
    const co = DATA.int31CoOccurrence;
    if (!co || !co.featFrequencies.length) return;

    renderInt31MetaBar();
    renderInt31FtypeBar();

    document.getElementById('sel-int31-topn')?.addEventListener('change', renderInt31Sunburst);
    document.getElementById('sel-int31-pairs-topn')?.addEventListener('change', renderInt31Pairs);
    document.getElementById('sel-stat9-topn')?.addEventListener('change', renderInt31TopNodes);
    document.getElementById('sel-stat9-reltype')?.addEventListener('change', renderInt31TopNodes);

    renderInt31Sunburst();
    renderInt31Pairs();
    renderInt31TopNodes();
}

document.addEventListener('DOMContentLoaded', initInt31CoOccurrence);

// ── Statistik 10: Ø Intertextuelle Relationen & gemeinsame Phänomene ─────────

let _stat10Charts = {};

function initStat10() {
    const d = DATA.stat10AvgRelations;
    if (!d) return;

    const wrap = document.getElementById('stat10-wrap-inner');
    if (!wrap) return;

    // ── Kennzahlen-Karten ────────────────────────────────────────────────────
    const kpiGrid = document.createElement('div');
    kpiGrid.style.cssText =
        'display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));' +
        'gap:1rem;margin-bottom:1.5rem';

    const kpiData = [
        {
            label:  'Ø Intertextuelle Relationen',
            sublbl: 'pro Sappho-Fragment',
            value:  d.avgSapphoInt31,
            color:  '#5e17eb',
            n:      d.nSappho,
        },
        {
            label:  'Ø Intertextuelle Relationen',
            sublbl: 'pro Rezeptionszeugnis',
            value:  d.avgReceptionInt31,
            color:  '#6b7280',
            n:      d.nReception,
        },
        {
            label:  'Ø gemeinsame Phänomene',
            sublbl: 'pro Sappho-Fragment',
            value:  d.avgSapphoShared,
            color:  '#5e17eb',
            n:      d.nSappho,
        },
        {
            label:  'Ø gemeinsame Phänomene',
            sublbl: 'pro Rezeptionszeugnis',
            value:  d.avgReceptionShared,
            color:  '#6b7280',
            n:      d.nReception,
        },
    ];

    kpiData.forEach(k => {
        const card = document.createElement('div');
        card.style.cssText =
            'border:1px solid #e5e7eb;border-radius:8px;padding:1rem 1.25rem;' +
            'text-align:center;background:#fff';
        card.innerHTML =
            `<div style="font-size:.78rem;font-weight:700;color:#6b7280;` +
            `text-transform:uppercase;letter-spacing:.06em;margin-bottom:.3rem">${k.label}</div>` +
            `<div style="font-size:2rem;font-weight:700;color:${k.color};line-height:1.1">${fmtN(k.value)}</div>` +
            `<div style="font-size:.78rem;color:#9ca3af;margin-top:.25rem">${k.sublbl}</div>` +
            `<div style="font-size:.72rem;color:#d1d5db;margin-top:.1rem">n = ${fmtN(k.n)}</div>`;
        kpiGrid.appendChild(card);
    });
    wrap.appendChild(kpiGrid);

    // ── Legende ───────────────────────────────────────────────────────────────
    const legend = document.createElement('div');
    legend.className = 'legend';
    legend.innerHTML =
        `<span><span class="dot dot-s"></span>Sappho-Fragmente (n = ${fmtN(d.nSappho)})</span>` +
        `<span><span class="dot dot-r"></span>Rezeptionszeugnisse (n = ${fmtN(d.nReception)})</span>`;
    wrap.appendChild(legend);

    // ── Hilfsfunktion: grouped bar chart ─────────────────────────────────────
    function renderGroupedBar(canvasId, histData, title, xLabel) {
        const labels = histData.map(b => b.label);
        const sapData = histData.map(b => b.sappho);
        const recData = histData.map(b => b.reception);
        const maxVal  = Math.max(...sapData, ...recData, 1);
        const maxY    = Math.ceil(maxVal * 1.1 / 5) * 5 || 10;

        const ctx = document.getElementById(canvasId).getContext('2d');
        _stat10Charts[canvasId] = new Chart(ctx, {
            type: 'bar',
            data: {
                labels,
                datasets: [
                    {
                        label: `Sappho-Fragmente (n = ${fmtN(d.nSappho)})`,
                        data:  sapData,
                        backgroundColor: C.s,
                        borderColor:     C.sLine,
                        borderWidth: 1.5,
                        borderRadius: 3,
                    },
                    {
                        label: `Rezeptionszeugnisse (n = ${fmtN(d.nReception)})`,
                        data:  recData,
                        backgroundColor: C.r,
                        borderColor:     C.rLine,
                        borderWidth: 1.5,
                        borderRadius: 3,
                    },
                ],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    title: {
                        display: !!title,
                        text: title,
                        font: { family: 'Geist, system-ui', size: 13, weight: '600' },
                        color: '#374151',
                        padding: { bottom: 8 },
                    },
                    tooltip: {
                        callbacks: {
                            label: ctx2 => {
                                const isSap  = ctx2.datasetIndex === 0;
                                const total  = isSap ? d.nSappho : d.nReception;
                                const name   = isSap ? 'Sappho-Fragmente' : 'Rezeptionszeugnisse';
                                const count  = ctx2.parsed.y;
                                const pct    = total > 0 ? (count / total * 100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1}) : '0.0';
                                return ` ${name}: ${count} ${count === 1 ? 'Text' : 'Texte'} (${pct}%)`;
                            },
                        },
                    },
                },
                scales: {
                    x: {
                        title: {
                            display: !!xLabel,
                            text: xLabel,
                            font: { family: 'Geist, system-ui', size: 11 },
                            color: '#6b7280',
                        },
                        ticks: { font: { family: 'Geist, system-ui', size: 11 } },
                        grid:  { display: false },
                    },
                    y: {
                        min: 0,
                        max: maxY,
                        title: {
                            display: true,
                            text: 'Anzahl Texte',
                            font: { family: 'Geist, system-ui', size: 11 },
                            color: '#6b7280',
                        },
                        ticks: { font: { family: 'Geist, system-ui', size: 11 }, stepSize: 5 },
                        grid:  { color: 'rgba(0,0,0,0.06)' },
                    },
                },
            },
        });
    }

    // INT31-Histogramm
    const int31Section = document.createElement('div');
    int31Section.style.marginBottom = '2rem';
    int31Section.innerHTML =
        `<p class="stats-subtitle stats-subtitle-sm">` +
        `Anzahl intertextueller Relationen pro Text</p>` +
        `<div class="chart-wrap"><canvas id="stat10-int31-hist" style="height:260px"></canvas></div>`;
    wrap.appendChild(int31Section);
    renderGroupedBar('stat10-int31-hist', d.int31Hist,  '', 'Anzahl intertextueller Relationen');

    // Shared-Phänomene-Histogramm
    const sharedSection = document.createElement('div');
    sharedSection.innerHTML =
        `<p class="stats-subtitle stats-subtitle-sm">` +
        `Durchschnittliche Anzahl gemeinsamer Phänomene pro Text</p>` +
        `<div class="chart-wrap"><canvas id="stat10-shared-hist" style="height:260px"></canvas></div>`;
    wrap.appendChild(sharedSection);
    renderGroupedBar('stat10-shared-hist', d.sharedHist, '', 'Ø gemeinsame Phänomene');
}

document.addEventListener('DOMContentLoaded', initStat10);

// ── Statistik 11: Gender (Überblick · Zeitverlauf · Phänomene) ──────────────

const GENDER_META = {
    male:    { label: 'Autoren',      color: 'rgba(234,88,12,0.75)',   line: '#ea580c' },
    female:  { label: 'Autorinnen',   color: 'rgba(22,163,74,0.75)',   line: '#16a34a' },
    unknown: { label: 'Kein Eintrag', color: 'rgba(156,163,175,0.55)', line: '#9ca3af' },
};

// ── Tab-Steuerung ─────────────────────────────────────────────────────────────
const GENDER_TABS = [
    { id: 'overview', label: 'Überblick'   },
    { id: 'time',     label: 'Zeitverlauf' },
    { id: 'genre',    label: 'Gattungen'   },
    { id: 'phenom',   label: 'Phänomene'   },
];
let _genderActiveTab   = 'overview';
let _genderChartInited = { overview: false, time: false, genre: false, phenom: false };

function buildGenderTabs() {
    const bar = document.getElementById('gender-tab-bar');
    if (!bar) return;
    GENDER_TABS.forEach(tab => {
        const btn = document.createElement('button');
        btn.id = 'gender-tab-btn-' + tab.id;
        btn.textContent = tab.label;
        btn.style.cssText =
            'padding:.4rem 1.1rem;border-radius:.375rem;font-size:.875rem;' +
            'font-family:Geist,system-ui,sans-serif;cursor:pointer;transition:all .15s;' +
            'border:1px solid #d1d5db;background:#fff;color:#374151;';
        btn.addEventListener('click', () => switchGenderTab(tab.id));
        bar.appendChild(btn);
    });
    highlightGenderTab(_genderActiveTab);
}

function highlightGenderTab(activeId) {
    GENDER_TABS.forEach(tab => {
        const btn = document.getElementById('gender-tab-btn-' + tab.id);
        if (!btn) return;
        if (tab.id === activeId) {
            btn.style.background  = '#5e17eb';
            btn.style.color       = '#fff';
            btn.style.borderColor = '#5e17eb';
        } else {
            btn.style.background  = '#fff';
            btn.style.color       = '#374151';
            btn.style.borderColor = '#d1d5db';
        }
    });
}

function switchGenderTab(tabId) {
    _genderActiveTab = tabId;
    highlightGenderTab(tabId);
    GENDER_TABS.forEach(tab => {
        const pane = document.getElementById('gender-pane-' + tab.id);
        if (pane) pane.style.display = tab.id === tabId ? '' : 'none';
    });
    if (tabId === 'overview' && !_genderChartInited.overview) {
        renderGenderOverview();
        _genderChartInited.overview = true;
    }
    if (tabId === 'time' && !_genderChartInited.time) {
        renderGenderTimeChart();
        _genderChartInited.time = true;
    }
    if (tabId === 'genre' && !_genderChartInited.genre) {
        renderGenderGenreChart();
        _genderChartInited.genre = true;
    }
    if (tabId === 'phenom' && !_genderChartInited.phenom) {
        renderGenderPhenomSections();
        _genderChartInited.phenom = true;
    }
}

// ── Pane 1: Überblick (alle Autor_innen) ─────────────────────────────────────
function renderGenderOverview() {
    const d = DATA.genderStats;
    if (!d) return;

    const kpiWrap = document.getElementById('stat11-kpi-wrap');
    if (kpiWrap && !kpiWrap.hasChildNodes()) {
        const kpiGrid = document.createElement('div');
        kpiGrid.style.cssText =
            'display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));' +
            'gap:1rem;margin-bottom:1.5rem';
        [
            { label: 'Autoren',               val: d.nMale,    color: GENDER_META.male.line   },
            { label: 'Autorinnen',             val: d.nFemale,  color: GENDER_META.female.line },
            { label: 'Kein Gender-Eintrag',     val: d.nUnknown, color: GENDER_META.unknown.line },
        ].forEach(k => {
            const card = document.createElement('div');
            card.style.cssText =
                'border:1px solid #e5e7eb;border-radius:8px;padding:1rem 1.25rem;' +
                'text-align:center;background:#fff';
            card.innerHTML =
                `<div style="font-size:.78rem;font-weight:700;color:#6b7280;text-transform:uppercase;` +
                `letter-spacing:.06em;margin-bottom:.3rem">${k.label}</div>` +
                `<div style="font-size:2rem;font-weight:700;color:${k.color};line-height:1.1">${k.val}</div>` +
                `<div style="font-size:.78rem;color:#9ca3af;margin-top:.25rem">gesamt</div>`;
            kpiGrid.appendChild(card);
        });
        kpiWrap.appendChild(kpiGrid);
    }

    const donutCanvas = document.getElementById('chart-gender-donut');
    if (!donutCanvas || donutCanvas._chartInited) return;
    donutCanvas._chartInited = true;

    const total = d.nMale + d.nFemale + d.nUnknown;
    new Chart(donutCanvas.getContext('2d'), {
        type: 'doughnut',
        data: {
            labels: [
                `Autoren – ${fmtN(d.nMale)} (${(d.nMale/total*100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1})}%)`,
                `Autorinnen – ${fmtN(d.nFemale)} (${(d.nFemale/total*100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1})}%)`,
                `Kein Eintrag – ${fmtN(d.nUnknown)} (${(d.nUnknown/total*100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1})}%)`,
            ],
            datasets: [{
                data: [d.nMale, d.nFemale, d.nUnknown],
                backgroundColor: [GENDER_META.male.color, GENDER_META.female.color, GENDER_META.unknown.color],
                borderColor:     [GENDER_META.male.line,  GENDER_META.female.line,  GENDER_META.unknown.line],
                borderWidth: 2,
            }],
        },
        options: {
            responsive: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { font: { family: 'Geist, system-ui', size: 12 }, padding: 14 },
                },
                tooltip: {
                    callbacks: {
                        label: ctx => {
                            const v = ctx.parsed;
                            const pct = total > 0 ? (v / total * 100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1}) : '0.0';
                            return ` ${v} (${pct}%)`;
                        },
                    },
                },
            },
        },
    });
}

// ── Pane 2: Zeitverlauf (alle Autor_innen) ────────────────────────────────────
let _genderTimeChart = null;

function renderGenderTimeChart() {
    const d = DATA.genderStats;
    if (!d || !d.timeDist || !d.timeDist.length) return;
    const ctx = document.getElementById('chart-gender-time')?.getContext('2d');
    if (!ctx) return;

    const mode      = document.getElementById('sel-gender-time-mode')?.value || 'stacked';
    const isPercent = mode === 'percent';

    const decLabels = d.timeDist.map(b => b.key === 'n/a' ? 'o. J.' : b.key.replace(/(\d+)s$/, '$1er'));
    const maleRaw   = d.timeDist.map(b => b.male);
    const femRaw    = d.timeDist.map(b => b.female);
    const unkRaw    = d.timeDist.map(b => b.unknown);

    const toPct = arr => arr.map((v, i) => {
        const t = maleRaw[i] + femRaw[i] + unkRaw[i];
        return t > 0 ? parseFloat((v / t * 100).toFixed(1)) : 0;
    });

    const datasets = [
        { label: 'Autoren',      data: isPercent ? toPct(maleRaw) : maleRaw,
          backgroundColor: GENDER_META.male.color,    borderColor: GENDER_META.male.line,    borderWidth: 1.5, borderRadius: 2 },
        { label: 'Autorinnen',   data: isPercent ? toPct(femRaw)  : femRaw,
          backgroundColor: GENDER_META.female.color,  borderColor: GENDER_META.female.line,  borderWidth: 1.5, borderRadius: 2 },
        { label: 'Kein Eintrag', data: isPercent ? toPct(unkRaw)  : unkRaw,
          backgroundColor: GENDER_META.unknown.color, borderColor: GENDER_META.unknown.line, borderWidth: 1.5, borderRadius: 2 },
    ];

    if (_genderTimeChart) {
        _genderTimeChart.data.labels   = decLabels;
        _genderTimeChart.data.datasets = datasets;
        _genderTimeChart.options.scales.y.max = isPercent ? 100 : undefined;
        _genderTimeChart.options.scales.y.ticks.callback = isPercent ? v => v + '%' : v => v;
        _genderTimeChart.update();
        return;
    }

    _genderTimeChart = new Chart(ctx, {
        type: 'bar',
        data: { labels: decLabels, datasets },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { font: { family: 'Geist, system-ui', size: 12 }, padding: 12 },
                },
                tooltip: {
                    mode: 'index',
                    callbacks: {
                        label: c => {
                            const v = c.parsed.y;
                            return isPercent
                                ? ` ${c.dataset.label}: ${v.toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1})}%`
                                : ` ${c.dataset.label}: ${v}`;
                        },
                    },
                },
            },
            scales: {
                x: {
                    stacked: true,
                    ticks: { font: { family: 'Geist, system-ui', size: 11 } },
                    grid: { display: false },
                },
                y: {
                    stacked: true,
                    max: isPercent ? 100 : undefined,
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 11 },
                        callback: isPercent ? v => v + '%' : v => v,
                    },
                    grid: { color: 'rgba(0,0,0,0.06)' },
                },
            },
        },
    });
}

// ── Pane 3: Gattungen × Geschlecht ──────────────────────────────────────────
let _genderGenreChart = null;

function renderGenderGenreChart() {
    const d = DATA.genderStats;
    if (!d || !d.genreGender || !d.genreGender.length) return;
    const ctx = document.getElementById('chart-gender-genre')?.getContext('2d');
    if (!ctx) return;

    const mode      = document.getElementById('sel-gender-genre-mode')?.value || 'stacked';
    const isPercent = mode === 'percent';

    const genres   = d.genreGender;
    const labels   = genres.map(g => g.key);
    const maleRaw  = genres.map(g => g.male);
    const femRaw   = genres.map(g => g.female);
    const unkRaw   = genres.map(g => g.unknown);

    const toPct = arr => arr.map((v, i) => {
        const t = maleRaw[i] + femRaw[i] + unkRaw[i];
        return t > 0 ? parseFloat((v / t * 100).toFixed(1)) : 0;
    });
    // 0 → null damit kein Stummel erscheint; minBarLength gilt nur für > 0
    const nullZero = arr => arr.map(v => v === 0 ? null : v);
    const nullZeroPct = arr => arr.map(v => v === 0 ? null : v);

    const datasets = [
        { label: 'Autoren',      data: isPercent ? nullZeroPct(toPct(maleRaw)) : nullZero(maleRaw),
          backgroundColor: GENDER_META.male.color,    borderColor: GENDER_META.male.line,    borderWidth: 1.5, borderRadius: 3, minBarLength: 3 },
        { label: 'Autorinnen',   data: isPercent ? nullZeroPct(toPct(femRaw))  : nullZero(femRaw),
          backgroundColor: GENDER_META.female.color,  borderColor: GENDER_META.female.line,  borderWidth: 1.5, borderRadius: 3, minBarLength: 3 },
        { label: 'Kein Eintrag', data: isPercent ? nullZeroPct(toPct(unkRaw))  : nullZero(unkRaw),
          backgroundColor: GENDER_META.unknown.color, borderColor: GENDER_META.unknown.line, borderWidth: 1.5, borderRadius: 3, minBarLength: 3 },
    ];

    if (_genderGenreChart) {
        _genderGenreChart.data.datasets = datasets;
        _genderGenreChart.options.scales.y.max = isPercent ? 100 : undefined;
        _genderGenreChart.options.scales.y.min = 0;
        _genderGenreChart.options.scales.y.ticks.precision = 0;
        _genderGenreChart.options.scales.y.ticks.callback = isPercent ? v => v + '%' : v => v;
        _genderGenreChart.options.scales.y.title.text =
            isPercent ? 'Prozentualer Anteil' : 'Anzahl Texte';
        _genderGenreChart.update();
        return;
    }

    _genderGenreChart = new Chart(ctx, {
        type: 'bar',
        data: { labels, datasets },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { font: { family: 'Geist, system-ui', size: 12 }, padding: 12 },
                },
                tooltip: {
                    mode: 'index',
                    callbacks: {
                        label: c => {
                            const g   = genres[c.dataIndex];
                            const tot = g.male + g.female + g.unknown;
                            const v   = c.parsed.y;
                            if (isPercent) return ` ${c.dataset.label}: ${v.toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1})}%`;
                            const pct = tot > 0 ? (v / tot * 100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1}) : '0.0';
                            return ` ${c.dataset.label}: ${v} (${pct}% der Gattung)`;
                        },
                    },
                },
            },
            scales: {
                x: {
                    stacked: true,
                    ticks: { font: { family: 'Geist, system-ui', size: 12 } },
                    grid: { display: false },
                },
                y: {
                    stacked: true,
                    min: 0,
                    max: isPercent ? 100 : undefined,
                    title: {
                        display: true,
                        text: isPercent ? 'Prozentualer Anteil' : 'Anzahl Texte',
                        font: { family: 'Geist, system-ui', size: 11 },
                        color: '#6b7280',
                    },
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 11 },
                        precision: 0,
                        callback: isPercent ? v => v + '%' : v => v,
                    },
                    grid: { color: 'rgba(0,0,0,0.06)' },
                },
            },
        },
    });
}

// ── Pane 3: Phänomene – aufklappbare Sektionen pro Phänomentyp (wie Stat 1) ──

const _genderPhenomCharts = {};

function renderGenderPhenomSections() {
    const pd   = DATA.genderStats?.phenomDist;
    if (!pd || !pd.features || !pd.features.length) return;

    // Typenlegende aufbauen
    const legendWrap = document.getElementById('gender-phenom-type-legend');
    if (legendWrap) {
        legendWrap.innerHTML = '';
        const ftypes = [...new Set(pd.features.map(f => f.ftype))];
        ftypes.forEach(ft => {
            const m = FTYPE_META[ft] || { label: ft, color: '#6b7280' };
            const span = document.createElement('span');
            span.style.cssText = 'display:inline-flex;align-items:center;gap:5px';
            span.innerHTML = `<span style="display:inline-block;width:11px;height:11px;border-radius:2px;background:${m.color};flex-shrink:0"></span>${m.label}`;
            legendWrap.appendChild(span);
        });
    }

    // Phänomene nach Typ gruppieren (Reihenfolge wie FTYPE_META)
    const ftypeOrder = Object.keys(FTYPE_META);
    const byType = {};
    pd.features.forEach(f => {
        if (!byType[f.ftype]) byType[f.ftype] = [];
        byType[f.ftype].push(f);
    });

    const wrap = document.getElementById('gender-phenom-overview-wrap');
    if (!wrap) return;
    wrap.innerHTML = '';

    // ── Überblicks-Chart Top-N ────────────────────────────────────────────────
    const topN   = parseInt(document.getElementById('sel-gender-phenom-topn')?.value || '30');
    const topItems = pd.features.slice(0, topN > 0 ? topN : pd.features.length);

    if (topItems.length) {
        const overviewTitle = document.createElement('p');
        overviewTitle.className = 'stats-subtitle stats-subtitle-sm';
        overviewTitle.textContent = 'Überblick (Top-N)';
        wrap.appendChild(overviewTitle);

        const ovLegend = document.createElement('div');
        ovLegend.className = 'legend';
        ovLegend.style.marginBottom = '.75rem';
        ovLegend.innerHTML =
            `<span><span class="dot" style="background:${GENDER_META.male.color};border:1.5px solid ${GENDER_META.male.line}"></span>` +
            `Autoren (n = ${fmtN(pd.nMale)})</span>` +
            `<span><span class="dot" style="background:${GENDER_META.female.color};border:1.5px solid ${GENDER_META.female.line}"></span>` +
            `Autorinnen (n = ${fmtN(pd.nFemale)})</span>`;
        wrap.appendChild(ovLegend);

        const controlRow = document.createElement('div');
        controlRow.className = 'control-col-wrap';
        controlRow.style.marginBottom = '.75rem';
        controlRow.innerHTML =
            `<div class="stat3-control-group">` +
            `<label>Anzahl:</label>` +
            `<select id="sel-gender-phenom-topn" class="stat2-select">` +
            `<option value="20"${topN===20?' selected':''}>Top 20</option>` +
            `<option value="30"${topN===30?' selected':''}>Top 30</option>` +
            `<option value="50"${topN===50?' selected':''}>Top 50</option>` +
            `<option value="100"${topN===100?' selected':''}>Top 100</option>` +
            `</select></div>`;
        wrap.appendChild(controlRow);

        document.getElementById('sel-gender-phenom-topn')
            ?.addEventListener('change', () => {
                Object.keys(_genderPhenomCharts).forEach(k => {
                    const c = _genderPhenomCharts[k]; if (c) c.destroy();
                    delete _genderPhenomCharts[k];
                });
                renderGenderPhenomSections();
            });

        const overviewLabels   = uniqueLabels(topItems.map(f => f.label));
        const overviewTypeCols = topItems.map(f => (FTYPE_META[f.ftype] || {}).color || '#6b7280');
        const pctOf = (n, tot) => tot > 0 ? parseFloat((n / tot * 100).toFixed(2)) : 0;
        const ovMale  = topItems.map(f => { const c = f.cells.find(x => x.g === 'male');   return pctOf(c ? c.n : 0, pd.nMale);   });
        const ovFem   = topItems.map(f => { const c = f.cells.find(x => x.g === 'female'); return pctOf(c ? c.n : 0, pd.nFemale); });
        const ovMaxX  = Math.min(100, Math.ceil(Math.max(...ovMale, ...ovFem) * 1.05 / 5) * 5) || 10;
        const ovH     = canvasHeight(topItems.length);

        const ovWrap  = document.createElement('div');
        ovWrap.className = 'chart-wrap';
        ovWrap.style.marginBottom = '1.5rem';
        const ovCanvas = document.createElement('canvas');
        ovCanvas.id = 'chart-gender-phenom-overview';
        ovCanvas.style.height = ovH + 'px';
        ovWrap.appendChild(ovCanvas);
        wrap.appendChild(ovWrap);

        // Typ-Streifen-Plugin (analog Stat 1)
        const FS = 11, FW = 6.5;
        const splitLov = (lbl, maxW) => {
            const c1 = Math.floor((maxW - 16) / FW) - 2;
            const c2 = Math.floor((maxW - 16) / FW);
            if (lbl.length <= c1) return [lbl];
            const words = lbl.split(' ');
            let best = null, cur = '';
            for (let i = 0; i < words.length - 1; i++) {
                cur = cur ? cur + ' ' + words[i] : words[i];
                const rest = words.slice(i + 1).join(' ');
                if (cur.length <= c2 && rest.length <= c2) best = { line1: cur, line2: rest };
            }
            if (best) return [best.line1, best.line2];
            const mid = Math.floor(lbl.length / 2);
            const brk = lbl.lastIndexOf(' ', mid + 6);
            const sp  = brk > 4 ? brk : c2;
            const l2r = lbl.slice(sp).trimStart();
            return [lbl.slice(0, sp).trimEnd(), l2r.length > c2 ? l2r.slice(0, c2 - 1) + '…' : l2r];
        };
        const ovStripe = {
            id: 'genderOvStripe',
            afterDraw(chart) {
                const { ctx: c, scales: { y }, chartArea } = chart;
                const lw = chartArea.left;
                topItems.forEach((item, i) => {
                    const color = overviewTypeCols[i];
                    const top   = y.getPixelForValue(i) - y.height / topItems.length / 2;
                    const bot   = y.getPixelForValue(i) + y.height / topItems.length / 2;
                    const h     = bot - top;
                    const lines = splitLov(overviewLabels[i], lw);
                    c.save();
                    c.font = `${FS}px Geist, system-ui, sans-serif`;
                    c.textAlign = 'right'; c.textBaseline = 'middle';
                    const x = lw - 6, gap = 6, r = 3;
                    const tw = c.measureText(lines.reduce((a, b) => c.measureText(a).width > c.measureText(b).width ? a : b, lines[0])).width;
                    c.beginPath(); c.fillStyle = color;
                    c.arc(x - tw - gap - r, top + h / 2, r, 0, Math.PI * 2); c.fill();
                    c.fillStyle = '#1f2937';
                    if (lines.length === 1) c.fillText(lines[0], x, top + h / 2);
                    else { c.fillText(lines[0], x, top + h / 2 - 7); c.fillText(lines[1], x, top + h / 2 + 7); }
                    c.restore();
                });
            },
        };

        new Chart(ovCanvas.getContext('2d'), {
            type: 'bar',
            plugins: [ovStripe],
            data: {
                labels: overviewLabels,
                datasets: [
                    { label: `Autoren (n = ${fmtN(pd.nMale)})`,   data: ovMale, backgroundColor: GENDER_META.male.color,   borderColor: GENDER_META.male.line,   borderWidth: 2, borderRadius: 2 },
                    { label: `Autorinnen (n = ${fmtN(pd.nFemale)})`, data: ovFem,  backgroundColor: GENDER_META.female.color, borderColor: GENDER_META.female.line, borderWidth: 2, borderRadius: 2 },
                ],
            },
            options: {
                indexAxis: 'y',
                responsive: true,
                maintainAspectRatio: false,
                layout: { padding: { left: 0 } },
                interaction: { mode: 'nearest', axis: 'y', intersect: true },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: c => {
                                const f    = topItems[c.dataIndex];
                                const isMale = c.datasetIndex === 0;
                                const gk   = isMale ? 'male' : 'female';
                                const tot  = isMale ? pd.nMale : pd.nFemale;
                                const cell = f.cells.find(x => x.g === gk);
                                const cnt  = cell ? cell.n : 0;
                                const name = isMale ? 'Autoren' : 'Autorinnen';
                                return ` ${name}: ${c.parsed.x.toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2})}% (${cnt}/${tot})`;
                            },
                        },
                    },
                },
                scales: {
                    x: {
                        min: 0, max: ovMaxX,
                        ticks: { font: { family: 'Geist, system-ui', size: 11 }, callback: v => v + '%', stepSize: 5 },
                        grid: { color: 'rgba(0,0,0,0.06)' },
                    },
                    y: {
                        ticks: { font: { family: 'Geist, system-ui', size: 12 }, autoSkip: false, color: 'transparent' },
                        grid: { display: false },
                        afterFit(scale) { scale.width = 220; },
                    },
                },
            },
        });

    }

    // ── Top-N pro Geschlecht: zwei Spalten nebeneinander ───────────────────────
    const genderTopTitle = document.createElement('p');
    genderTopTitle.className = 'stats-subtitle stats-subtitle-sm-top';
    genderTopTitle.textContent = 'Top-Phänomene nach Geschlecht';
    wrap.appendChild(genderTopTitle);

    // Top-N Dropdown
    const gTopControls = document.createElement('div');
    gTopControls.className = 'control-col-wrap';
    gTopControls.style.marginBottom = '.75rem';
    gTopControls.innerHTML =
        `<div class="stat3-control-group"><label for="sel-gender-top-n">Anzahl:</label>` +
        `<select id="sel-gender-top-n" class="stat2-select">` +
        `<option value="10">Top 10</option>` +
        `<option value="20" selected>Top 20</option>` +
        `<option value="30">Top 30</option>` +
        `<option value="50">Top 50</option>` +
        `</select></div>`;
    wrap.appendChild(gTopControls);

    // Zwei-Spalten-Container
    const gTopCols = document.createElement('div');
    gTopCols.style.cssText = 'display:grid;grid-template-columns:1fr 1fr;gap:1rem;align-items:start;min-width:0';
    wrap.appendChild(gTopCols);

    const gTopWrapM = document.createElement('div');
    gTopWrapM.id = 'gender-top-wrap-male';
    gTopCols.appendChild(gTopWrapM);

    const gTopWrapF = document.createElement('div');
    gTopWrapF.id = 'gender-top-wrap-female';
    gTopCols.appendChild(gTopWrapF);

    let _gTopChartM = null;
    let _gTopChartF = null;

    // Typ-Streifen-Plugin — kompaktere Labels für halbe Breite
    const FS2 = 10, FW2 = 6.0;
    const splitG = (lbl, maxW) => {
        const c1 = Math.floor((maxW - 12) / FW2) - 2;
        const c2 = Math.floor((maxW - 12) / FW2);
        if (lbl.length <= c1) return [lbl];
        const words = lbl.split(' ');
        let best = null, cur = '';
        for (let i = 0; i < words.length - 1; i++) {
            cur = cur ? cur + ' ' + words[i] : words[i];
            const rest = words.slice(i + 1).join(' ');
            if (cur.length <= c2 && rest.length <= c2) best = { line1: cur, line2: rest };
        }
        if (best) return [best.line1, best.line2];
        const mid = Math.floor(lbl.length / 2);
        const brk = lbl.lastIndexOf(' ', mid + 6);
        const sp  = brk > 4 ? brk : c2;
        const l2r = lbl.slice(sp).trimStart();
        return [lbl.slice(0, sp).trimEnd(), l2r.length > c2 ? l2r.slice(0, c2 - 1) + '…' : l2r];
    };

    function makeGenderColStripe(sortedItems, id) {
        return {
            id,
            afterDraw(chart) {
                const { ctx: c, scales: { y }, chartArea } = chart;
                const lw = chartArea.left;
                sortedItems.forEach((item, i) => {
                    const color = (FTYPE_META[item.ftype] || {}).color || '#6b7280';
                    const top   = y.getPixelForValue(i) - y.height / sortedItems.length / 2;
                    const bot   = y.getPixelForValue(i) + y.height / sortedItems.length / 2;
                    const h     = bot - top;
                    const lines = splitG(item.label, lw);
                    c.save();
                    c.font = `${FS2}px Geist, system-ui, sans-serif`;
                    c.textAlign = 'right'; c.textBaseline = 'middle';
                    const x = lw - 5, gap = 5, r = 3;
                    const tw = c.measureText(lines.reduce((a, b) => c.measureText(a).width > c.measureText(b).width ? a : b, lines[0])).width;
                    c.beginPath(); c.fillStyle = color;
                    c.arc(x - tw - gap - r, top + h / 2, r, 0, Math.PI * 2); c.fill();
                    c.fillStyle = '#1f2937';
                    if (lines.length === 1) c.fillText(lines[0], x, top + h / 2);
                    else { c.fillText(lines[0], x, top + h / 2 - 6); c.fillText(lines[1], x, top + h / 2 + 6); }
                    c.restore();
                });
            },
        };
    }

    function renderGenderColChart(gk, wrapEl, existingChart) {
        const n      = parseInt(document.getElementById('sel-gender-top-n')?.value || '20');
        const isMale = gk === 'male';
        const tot    = isMale ? pd.nMale : pd.nFemale;
        const color  = isMale ? GENDER_META.male.color  : GENDER_META.female.color;
        const line   = isMale ? GENDER_META.male.line   : GENDER_META.female.line;
        const title  = isMale ? 'Autoren' : 'Autorinnen';

        const sorted = [...pd.features]
            .map(f => { const cell = f.cells.find(x => x.g === gk); return { ...f, gCount: cell ? cell.n : 0 }; })
            .sort((a, b) => b.gCount - a.gCount)
            .slice(0, n > 0 ? n : pd.features.length);

        const labels = uniqueLabels(sorted.map(f => f.label));
        const data   = sorted.map(f => tot > 0 ? parseFloat((f.gCount / tot * 100).toFixed(2)) : 0);
        const maxX   = Math.min(100, Math.ceil(Math.max(...data) * 1.05 / 5) * 5) || 10;
        // Kompaktere Zeilenhöhe für halbe Breite
        const chartH = Math.max(120, sorted.length * 26 + 40);

        if (existingChart) { existingChart.destroy(); }
        wrapEl.innerHTML = '';
        const colTitle = document.createElement('p');
        colTitle.style.cssText = `font-size:.85rem;font-weight:700;color:${line};text-align:center;` +
            `margin-bottom:.4rem;text-transform:uppercase;letter-spacing:.04em`;
        colTitle.textContent = title;
        wrapEl.appendChild(colTitle);
        const colChartWrap = document.createElement('div');
        colChartWrap.style.cssText = `overflow-x:auto;width:100%`;
        const colCanvas = document.createElement('canvas');
        colCanvas.width  = 400;
        colCanvas.height = chartH;
        colCanvas.style.cssText = `display:block;width:100%;height:${chartH}px`;
        colChartWrap.appendChild(colCanvas);
        wrapEl.appendChild(colChartWrap);

        const stripe = makeGenderColStripe(sorted, 'genderColStripe-' + gk);
        const chart = new Chart(colCanvas.getContext('2d'), {
            type: 'bar',
            plugins: [stripe],
            data: {
                labels,
                datasets: [{ label: title, data, backgroundColor: color, borderColor: line, borderWidth: 1.5, borderRadius: 2 }],
            },
            options: {
                indexAxis: 'y',
                responsive: true,
                maintainAspectRatio: false,
                layout: { padding: { left: 0 } },
                interaction: { mode: 'nearest', axis: 'y', intersect: true },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: c => {
                                const f    = sorted[c.dataIndex];
                                const cell = f.cells.find(x => x.g === gk);
                                const cnt  = cell ? cell.n : 0;
                                return ` ${isMale ? 'Autoren' : 'Autorinnen'}: ${c.parsed.x.toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2})}% (${cnt}/${tot})`;
                            },
                        },
                    },
                },
                scales: {
                    x: {
                        min: 0, max: maxX,
                        ticks: { font: { family: 'Geist, system-ui', size: 10 }, callback: v => v + '%', stepSize: 5 },
                        grid: { color: 'rgba(0,0,0,0.06)' },
                    },
                    y: {
                        ticks: { font: { family: 'Geist, system-ui', size: 10 }, autoSkip: false, color: 'transparent' },
                        grid: { display: false },
                        afterFit(scale) {
                            // Breite dynamisch aus dem längsten Label berechnen
                            const maxLen = labels.reduce((m, l) => Math.max(m, l.length), 0);
                            scale.width = Math.min(200, Math.max(100, maxLen * 6 + 28));
                        },
                    },
                },
            },
        });
        return chart;
    }

    function renderGenderTopCharts() {
        _gTopChartM = renderGenderColChart('male',   gTopWrapM, _gTopChartM);
        _gTopChartF = renderGenderColChart('female', gTopWrapF, _gTopChartF);
    }

    renderGenderTopCharts();
    document.getElementById('sel-gender-top-n')?.addEventListener('change', renderGenderTopCharts);

    const phenomTypTitle = document.createElement('p');
    phenomTypTitle.className = 'stats-subtitle stats-subtitle-sm-top';
    phenomTypTitle.textContent = 'Nach Phänomentyp';
    wrap.appendChild(phenomTypTitle);

    const orderedTypes = ftypeOrder.filter(ft => byType[ft]);

    orderedTypes.forEach(ft => {
        const items    = byType[ft];
        const ftMeta   = FTYPE_META[ft] || { label: ft, color: '#6b7280' };
        const sectionId = 'gender-phenom-cat-' + ft;

        const section = document.createElement('div');
        section.className = 'card cat';
        section.id = sectionId;

        const head = document.createElement('div');
        head.className = 'card-header';
        head.innerHTML = `<span class="arrow">&#9658;</span><h2>${ftMeta.label}</h2>`;

        const body = document.createElement('div');
        body.className = 'card-body';
        body.id = 'gender-phenom-body-' + ft;

        const chartWrap = document.createElement('div');
        chartWrap.className = 'chart-wrap';
        const canvas = document.createElement('canvas');
        canvas.id = 'chart-gender-phenom-' + ft;
        canvas.style.height = canvasHeight(items.length) + 'px';
        chartWrap.appendChild(canvas);
        body.appendChild(chartWrap);

        section.appendChild(head);
        section.appendChild(body);

        head.addEventListener('click', () => {
            const isOpen = body.classList.contains('visible');
            body.classList.toggle('visible', !isOpen);
            head.classList.toggle('open', !isOpen);
            if (!isOpen && !_genderPhenomCharts[ft]) {
                renderGenderPhenomChart(ft, items, pd, canvas);
            }
        });

        wrap.appendChild(section);
    });
}

function renderGenderPhenomChart(ft, items, pd, canvas) {
    const labels   = uniqueLabels(items.map(f => f.label));
    const pctOf    = (n, tot) => tot > 0 ? parseFloat((n / tot * 100).toFixed(2)) : 0;
    const maleData = items.map(f => { const c = f.cells.find(x => x.g === 'male');   return pctOf(c ? c.n : 0, pd.nMale);   });
    const femData  = items.map(f => { const c = f.cells.find(x => x.g === 'female'); return pctOf(c ? c.n : 0, pd.nFemale); });

    const maxX = Math.min(100,
        Math.ceil(Math.max(...maleData, ...femData) * 1.05 / 5) * 5
    ) || 10;

    const FS = 11, FW = 6.5;
    const typeColors = items.map(f => (FTYPE_META[f.ftype] || {}).color || '#6b7280');
    const stripePlugin = {
        id: 'genderPhenomStripe_' + ft,
        afterDraw(chart) {
            const { ctx: c, scales: { y }, chartArea } = chart;
            const lw = chartArea.left;
            items.forEach((item, i) => {
                const color = typeColors[i];
                const top   = y.getPixelForValue(i) - y.height / items.length / 2;
                const bot   = y.getPixelForValue(i) + y.height / items.length / 2;
                const h     = bot - top;
                const lbl   = item.label;
                const maxC  = Math.floor((lw - 16) / FW);
                const disp  = lbl.length > maxC ? lbl.slice(0, maxC - 1) + '…' : lbl;
                c.save();
                c.font = `${FS}px Geist, system-ui, sans-serif`;
                c.textAlign = 'right'; c.textBaseline = 'middle';
                const x = lw - 6, gap = 6, r = 3;
                const tw = c.measureText(disp).width;
                c.beginPath(); c.fillStyle = color;
                c.arc(x - tw - gap - r, top + h / 2, r, 0, Math.PI * 2); c.fill();
                c.fillStyle = '#1f2937';
                c.fillText(disp, x, top + h / 2);
                c.restore();
            });
        },
    };

    _genderPhenomCharts[ft] = new Chart(canvas.getContext('2d'), {
        type: 'bar',
        plugins: [stripePlugin],
        data: {
            labels,
            datasets: [
                {
                    label: `Autoren (n = ${fmtN(pd.nMale)})`,
                    data: maleData,
                    backgroundColor: GENDER_META.male.color,
                    borderColor:     GENDER_META.male.line,
                    borderWidth: 2,
                    borderRadius: 2,
                },
                {
                    label: `Autorinnen (n = ${fmtN(pd.nFemale)})`,
                    data: femData,
                    backgroundColor: GENDER_META.female.color,
                    borderColor:     GENDER_META.female.line,
                    borderWidth: 2,
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
                            const f    = items[ctx.dataIndex];
                            const isMale = ctx.datasetIndex === 0;
                            const gk   = isMale ? 'male' : 'female';
                            const tot  = isMale ? pd.nMale : pd.nFemale;
                            const cell = f.cells.find(x => x.g === gk);
                            const cnt  = cell ? cell.n : 0;
                            const pct  = ctx.parsed.x.toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2});
                            const name = isMale ? 'Autoren' : 'Autorinnen';
                            const uCell = f.cells.find(x => x.g === 'unknown');
                            const uCnt  = uCell ? uCell.n : 0;
                            const uPct  = pd.nUnknown > 0 ? (uCnt / pd.nUnknown * 100).toLocaleString('de-DE', {minimumFractionDigits:2, maximumFractionDigits:2}) : '0.00';
                            const lines = [` ${name}: ${pct}% (${cnt}/${tot})`];
                            if (ctx.datasetIndex === 1) {
                                lines.push(` Kein Eintrag: ${uPct}% (${uCnt}/${fmtN(pd.nUnknown)})`);
                            }
                            return lines;
                        },
                    },
                },
            },
            scales: {
                x: {
                    min: 0,
                    max: maxX,
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 11 },
                        callback: v => v + '%',
                        stepSize: 5,
                    },
                    grid: { color: 'rgba(0,0,0,0.06)' },
                },
                y: {
                    ticks: {
                        font: { family: 'Geist, system-ui', size: 12 },
                        autoSkip: false,
                        color: 'transparent',
                    },
                    grid: { display: false },
                    afterFit(scale) { scale.width = 220; },
                },
            },
        },
    });
}

// ── Init ──────────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    if (!DATA.genderStats) return;
    buildGenderTabs();
    renderGenderOverview();
    _genderChartInited.overview = true;
    document.getElementById('sel-gender-time-mode')
        ?.addEventListener('change', renderGenderTimeChart);
    document.getElementById('sel-gender-genre-mode')
        ?.addEventListener('change', renderGenderGenreChart);
    document.getElementById('sel-gender-phenom-topn')
        ?.addEventListener('change', () => {
            _genderChartInited.phenom = false;
            Object.keys(_genderPhenomCharts).forEach(k => {
                const c = _genderPhenomCharts[k];
                if (c) c.destroy();
                delete _genderPhenomCharts[k];
            });
            renderGenderPhenomSections();
            _genderChartInited.phenom = true;
        });
});

// ── Statistik 12: Wiki-Metriken ───────────────────────────────────────────────

(function () {
    'use strict';

    // ── CSV-Parser ─────────────────────────────────────────────────────────────
    function parseCsv(text) {
        const lines   = text.trim().split('\n');
        const headers = lines[0].split(',').map(h => h.trim());
        return lines.slice(1).map(line => {
            const vals = line.split(',');
            const obj  = {};
            headers.forEach((h, i) => { obj[h] = (vals[i] || '').trim(); });
            return obj;
        });
    }

    function toEntry(r) {
        return {
            name:       r['Autor_in']           || '',
            wikidataId: r['Author Wikidata ID']  || '',
            sitelinks:  parseInt(r['Author Sitelinks']) || 0,
            qrank:      r['Author QRank'] !== '' ? (parseInt(r['Author QRank']) || null) : null,
            workCount:  parseInt(r['Work Count']) || 0,
        };
    }

    function dedup(entries) {
        const map = new Map();
        entries.forEach(e => {
            if (!map.has(e.wikidataId)) {
                map.set(e.wikidataId, Object.assign({}, e));
            } else {
                const ex = map.get(e.wikidataId);
                ex.workCount += e.workCount;
                ex.sitelinks  = Math.max(ex.sitelinks, e.sitelinks);
                if (e.qrank !== null) ex.qrank = Math.max(ex.qrank || 0, e.qrank);
            }
        });
        return Array.from(map.values());
    }

    // ── Farben ─────────────────────────────────────────────────────────────────
    const WM_C = {
        primary:     'rgba(94,23,235,0.75)',
        primaryLine: '#5e17eb',
        gray:        'rgba(107,114,128,0.75)',
        grayLine:    '#6b7280',
    };

    // ── Tabs ───────────────────────────────────────────────────────────────────
    const WM_TABS = [
        { key: 'qrank',     label: 'QRank' },
        { key: 'sitelinks', label: 'Sitelinks' },
    ];

    // Lila-Farbe passend zum restlichen System
    const BTN_ACTIVE_BG    = '#5e17eb';
    const BTN_ACTIVE_COLOR = '#fff';
    const BTN_INACTIVE_BG  = 'transparent';
    const BTN_INACTIVE_COLOR = '#5e17eb';
    const BTN_INACTIVE_BORDER = '#5e17eb';

    function buildWmTabs(state) {
        const bar = document.getElementById('wm-tab-bar');
        if (!bar) return;
        WM_TABS.forEach((t, i) => {
            const btn = document.createElement('button');
            btn.dataset.pane = t.key;
            btn.textContent  = t.label;
            styleWmBtn(btn, i === 0);
            btn.addEventListener('click', () => switchWmPane(t.key, state));
            bar.appendChild(btn);
        });
    }

    function styleWmBtn(btn, active) {
        btn.style.cssText =
            `font-family:Geist,system-ui,sans-serif;font-size:.83rem;` +
            `padding:.3rem .85rem;border-radius:.375rem;cursor:pointer;` +
            `border:1px solid ${BTN_INACTIVE_BORDER};` +
            `background:${active ? BTN_ACTIVE_BG    : BTN_INACTIVE_BG};` +
            `color:${active      ? BTN_ACTIVE_COLOR : BTN_INACTIVE_COLOR};` +
            `transition:background .15s,color .15s;`;
    }

    function switchWmPane(key, state) {
        WM_TABS.forEach(t => {
            const pane = document.getElementById('wm-pane-' + t.key);
            const btn  = document.querySelector(`#wm-tab-bar [data-pane="${t.key}"]`);
            if (pane) pane.style.display = t.key === key ? '' : 'none';
            if (btn)  styleWmBtn(btn, t.key === key);
        });
        const metaEl = document.getElementById('wm-scatter-meta');
        if (metaEl) metaEl.style.display = key === 'qrank' ? '' : 'none';
        if (key === 'qrank') {
            if (!state.charts.scatter)      renderWmScatter(state);
            if (!state.charts.topqrank)     renderWmTopQrank(state);
        }
        if (key === 'sitelinks') {
            if (!state.charts.slscatter)    renderWmSlScatter(state);
            renderWmSitelinksPie(state);
            if (!state.charts.topsitelinks) renderWmTopSitelinks(state);
        }
    }

    // ── KPI-Leiste ─────────────────────────────────────────────────────────────
    function buildWmKpi(WM_DATA, WM_WITH_QRANK, medianQRank, avgSitelinks) {
        const wrap = document.getElementById('wm-kpi-wrap');
        if (!wrap) return;
        const WM_TOTAL   = WM_DATA.length;
        const WM_NO_WIKI = WM_DATA.filter(d => d.sitelinks === 0).length;

        // Grid wie Stat10
        wrap.style.cssText =
            'display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));' +
            'gap:1rem;margin-bottom:1.5rem';

        function kpiCard(id, label, value, color) {
            const card = document.createElement('div');
            if (id) card.id = id;
            card.style.cssText =
                'border:1px solid #e5e7eb;border-radius:8px;padding:.9rem 1.1rem;' +
                'text-align:center;background:#fff;';
            card.innerHTML =
                `<div style="font-size:.75rem;font-weight:700;color:#6b7280;` +
                `text-transform:uppercase;letter-spacing:.06em;margin-bottom:.3rem">${label}</div>` +
                `<div style="font-size:1.7rem;font-weight:700;color:${color};line-height:1.1">${value}</div>`;
            return card;
        }

        wrap.appendChild(kpiCard(null, 'Autor_innen gesamt',    WM_TOTAL.toLocaleString('de-DE'),                       '#1f2937'));
        wrap.appendChild(kpiCard(null, 'Mit Wikipedia-Artikel', (WM_TOTAL - WM_NO_WIKI).toLocaleString('de-DE'),       '#5e17eb'));
        wrap.appendChild(kpiCard(null, 'Median QRank',          medianQRank.toLocaleString('de-DE'),                                   '#5e17eb'));
        wrap.appendChild(kpiCard(null, 'Ø Sitelinks',           avgSitelinks.toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1}), '#6b7280'));
    }

    // ── Scatter-Hilfsfunktion: Bubble-Chart ───────────────────────────────────
    function makeScatterChart(canvasId, points, xLabel, yLabel, yLog, labelSet, getLabel, nameField) {
        const canvas = document.getElementById(canvasId);
        if (!canvas) return null;

        const labelPlugin = {
            id: 'wmLabels_' + canvasId,
            afterDatasetsDraw(chart) {
                if (!labelSet || labelSet.size === 0) return;
                const { ctx, scales: { x, y } } = chart;
                ctx.save();
                ctx.font      = '10px Geist, system-ui, sans-serif';
                ctx.fillStyle = '#374151';
                ctx.textAlign = 'left';
                points.forEach(d => {
                    if (!labelSet.has(d.wikidataId)) return;
                    const px = x.getPixelForValue(d.x);
                    const py = y.getPixelForValue(d.y);
                    const nm = d.name.length > 22 ? d.name.slice(0, 20) + '…' : d.name;
                    ctx.fillText(nm, px + d.r + 3, py + 3);
                });
                ctx.restore();
            }
        };

        const yScaleCfg = yLog
            ? {
                type: 'logarithmic',
                title: { display: true, text: yLabel, font: { family: 'Geist, system-ui', size: 11 }, color: '#6b7280' },
                ticks: {
                    font: { family: 'Geist, system-ui', size: 10 },
                    callback: v => { const l = Math.log10(v); return Number.isInteger(l) ? (v >= 1000 ? (v/1000)+'k' : v) : null; }
                },
                grid: { color: 'rgba(0,0,0,0.06)' },
              }
            : {
                title: { display: true, text: yLabel, font: { family: 'Geist, system-ui', size: 11 }, color: '#6b7280' },
                ticks: { font: { family: 'Geist, system-ui', size: 11 } },
                grid:  { color: 'rgba(0,0,0,0.06)' },
                min: 0,
              };

        return new Chart(canvas.getContext('2d'), {
            type: 'scatter',
            plugins: [labelPlugin],
            data: {
                datasets: [{
                    label: 'Autor_in',
                    data: points,
                    backgroundColor: WM_C.primary,
                    borderColor:     WM_C.primaryLine,
                    borderWidth: 1,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: { callbacks: { label: ctx => getLabel(ctx.raw) } }
                },
                scales: {
                    x: {
                        title: { display: true, text: xLabel, font: { family: 'Geist, system-ui', size: 11 }, color: '#6b7280' },
                        ticks: { font: { family: 'Geist, system-ui', size: 11 }, stepSize: 1 },
                        grid:  { color: 'rgba(0,0,0,0.06)' },
                        min: 0,
                    },
                    y: yScaleCfg,
                }
            }
        });
    }

    // ── QRank vs. Korpuspräsenz ──────────────────────────────────────
    function renderWmScatter(state) {
        if (state.charts.scatter) { state.charts.scatter.destroy(); }
        const { WM_WITH_QRANK } = state;
        const metaEl = document.getElementById('wm-scatter-meta');
        if (metaEl) metaEl.textContent = `${WM_WITH_QRANK.length} Autor_innen mit QRank`;
        const points = WM_WITH_QRANK.map(d => ({
            x: d.workCount, y: d.qrank,
            r: 4,
            name: d.name, qrank: d.qrank,
            workCount: d.workCount, wikidataId: d.wikidataId,
        }));
        state.charts.scatter = makeScatterChart(
            'chart-wm-scatter', points,
            'Korpuspräsenz', 'QRank', true,
            null,
            d => [` ${d.name}`, ` QRank: ${d.qrank.toLocaleString('de-DE')}`, ` Korpuspräsenz: ${d.workCount}`]
        );
    }

    // ── Sitelinks vs. Korpuspräsenz ──────────────────────────────────
    function renderWmSlScatter(state) {
        if (state.charts.slscatter) { state.charts.slscatter.destroy(); }
        const data = state.WM_DATA.filter(d => d.sitelinks > 0);
        const points = data.map(d => ({
            x: d.workCount, y: d.sitelinks,
            r: 4,
            name: d.name, sitelinks: d.sitelinks,
            workCount: d.workCount, wikidataId: d.wikidataId,
        }));
        state.charts.slscatter = makeScatterChart(
            'chart-wm-slscatter', points,
            'Korpuspräsenz', 'Sitelinks', false,
            null,
            d => [` ${d.name}`, ` Sitelinks: ${d.sitelinks}`, ` Korpuspräsenz: ${d.workCount}`]
        );
    }

    // ── Gemeinsame Balken-Render-Funktion für Top-QRank und Top-Sitelinks ─────
    function renderWmTopBar(state, chartKey, canvasId, wrapId, selId, dataFn, ds0Fn, ds1Fn, xTitle0, xTitle1) {
        const topN = parseInt(document.getElementById(selId)?.value || '0') || Infinity;
        const wrap = document.getElementById(wrapId);
        if (!wrap) return;

        const items  = dataFn(topN);
        const labels = uniqueLabels(items.map(d => d.name));
        const d0     = items.map(ds0Fn);
        const d1     = items.map(ds1Fn);
        const height = canvasHeight(items.length);

        wrap.innerHTML = `<canvas id="${canvasId}" style="height:${height}px"/>`;
        const canvas   = document.getElementById(canvasId);
        if (!canvas) return;

        if (state.charts[chartKey]) { state.charts[chartKey].destroy(); }
        state.charts[chartKey] = new Chart(canvas.getContext('2d'), {
            type: 'bar',
            data: {
                labels,
                datasets: [
                    {
                        label: xTitle0,
                        data: d0,
                        backgroundColor: WM_C.primary,
                        borderColor:     WM_C.primaryLine,
                        borderWidth: 2, borderRadius: 2,
                        xAxisID: 'x',
                    },
                    {
                        label: xTitle1,
                        data: d1,
                        backgroundColor: WM_C.gray,
                        borderColor:     WM_C.grayLine,
                        borderWidth: 2, borderRadius: 2,
                        xAxisID: 'x2',
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
                                const d = items[ctx.dataIndex];
                                if (ctx.datasetIndex === 0) {
                                    return ` ${xTitle0}: ${typeof d0[ctx.dataIndex] === 'number' && d0[ctx.dataIndex] % 1 !== 0
                                        ? d0[ctx.dataIndex].toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1}) + '%'
                                        : Number(d0[ctx.dataIndex]).toLocaleString('de-DE')}`;
                                }
                                return ` Korpuspräsenz: ${d.workCount}`;
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        position: 'bottom', min: 0,
                        ticks: { font: { family: 'Geist, system-ui', size: 11 } },
                        grid:  { color: 'rgba(0,0,0,0.06)' },
                        title: { display: true, text: xTitle0, font: { family: 'Geist, system-ui', size: 10 }, color: '#6b7280' },
                    },
                    x2: {
                        position: 'top', min: 0,
                        ticks: { font: { family: 'Geist, system-ui', size: 11 }, stepSize: 5 },
                        grid:  { display: false },
                        title: { display: true, text: 'Korpuspräsenz', font: { family: 'Geist, system-ui', size: 10 }, color: '#6b7280' },
                    },
                    y: {
                        ticks: { font: { family: 'Geist, system-ui', size: 11 }, autoSkip: false },
                        grid:  { display: false },
                        afterFit(scale) {
                            const maxLen = labels.reduce((m, l) => Math.max(m, l.length), 0);
                            scale.width  = Math.min(220, Math.max(120, maxLen * 6 + 16));
                        },
                    },
                },
            },
        });
    }

    // ── Top QRank ────────────────────────────────────────────────────
    function renderWmTopQrank(state) {
        const selVal = document.getElementById('sel-wm-qrank-topn')?.value || '50';
        const topN   = selVal === '0' ? Infinity : parseInt(selVal);
        const sorted = [...state.WM_WITH_QRANK].sort((a, b) => b.qrank - a.qrank);
        const items  = isFinite(topN) ? sorted.slice(0, topN) : sorted;
        const metaEl = document.getElementById('wm-scatter-meta');
        if (metaEl) metaEl.textContent = `${state.WM_WITH_QRANK.length} Autor_innen mit QRank`;
        const maxQ   = items[0].qrank;
        renderWmTopBar(
            state, 'topqrank', 'chart-wm-topqrank-inner', 'wm-topqrank-wrap', 'sel-wm-qrank-topn',
            () => items,
            d => parseFloat((d.qrank / maxQ * 100).toFixed(2)),
            d => d.workCount,
            'QRank (normalisiert, %)', 'Korpuspräsenz'
        );
    }

    // ── Top Sitelinks ────────────────────────────────────────────────
    function renderWmTopSitelinks(state) {
        const selVal = document.getElementById('sel-wm-sl-topn')?.value || '50';
        const topN   = selVal === '0' ? Infinity : parseInt(selVal);
        const sorted = [...state.WM_DATA].sort((a, b) => b.sitelinks - a.sitelinks);
        const items  = isFinite(topN) ? sorted.slice(0, topN) : sorted;
        renderWmTopBar(
            state, 'topsitelinks', 'chart-wm-topsitelinks-inner', 'wm-topsitelinks-bar-wrap', 'sel-wm-sl-topn',
            () => items,
            d => d.sitelinks,
            d => d.workCount,
            'Sitelinks', 'Korpuspräsenz'
        );
    }

    // ── Donut Sitelinks-Verteilung ──────────────────
    function renderWmSitelinksPie(state) {
        const wrap = document.getElementById('wm-sitelinks-donut-wrap');
        if (!wrap || state.charts.sitelinksPie) return;
        state.charts.sitelinksPie = true;

        const { WM_DATA }  = state;
        const WM_TOTAL     = WM_DATA.length;
        const buckets = [
            { label: 'Kein Artikel (0)',  min: 0,  max: 0,    color: 'rgba(107,114,128,0.7)', line: '#6b7280' },
            { label: '1–5 Sprachen',      min: 1,  max: 5,    color: 'rgba(94,23,235,0.45)',  line: '#5e17eb' },
            { label: '6–20 Sprachen',     min: 6,  max: 20,   color: 'rgba(94,23,235,0.75)',  line: '#5e17eb' },
            { label: '21–50 Sprachen',    min: 21, max: 50,   color: 'rgba(8,145,178,0.75)',  line: '#0891b2' },
            { label: '> 50 Sprachen',     min: 51, max: 9999, color: 'rgba(220,85,38,0.75)',  line: '#dc5526' },
        ];
        const counts = buckets.map(b => WM_DATA.filter(d => d.sitelinks >= b.min && d.sitelinks <= b.max).length);
        const pcts   = counts.map(c => (c / WM_TOTAL * 100).toLocaleString('de-DE', {minimumFractionDigits:1, maximumFractionDigits:1}));

        const donutWrap = document.createElement('div');
        donutWrap.style.cssText = 'display:flex;flex-direction:column;align-items:center;gap:0.5rem;';
        const donutCanvas = document.createElement('canvas');
        donutCanvas.style.cssText = 'width:220px;height:220px;max-width:220px;max-height:220px;';
        donutWrap.appendChild(donutCanvas);

        const legendDiv = document.createElement('div');
        legendDiv.style.cssText = 'display:flex;flex-direction:column;gap:.3rem;font-size:.8rem;color:#374151;margin-top:.25rem;';
        buckets.forEach((b, i) => {
            legendDiv.innerHTML +=
                `<span><span style="display:inline-block;width:12px;height:12px;border-radius:2px;` +
                `background:${b.color};margin-right:5px;vertical-align:middle;"></span>` +
                `${b.label}: ${counts[i]} (${pcts[i]}%)</span>`;
        });
        donutWrap.appendChild(legendDiv);
        wrap.appendChild(donutWrap);

        new Chart(donutCanvas.getContext('2d'), {
            type: 'doughnut',
            data: {
                labels: buckets.map(b => b.label),
                datasets: [{ data: counts, backgroundColor: buckets.map(b => b.color), borderColor: buckets.map(b => b.line), borderWidth: 2 }]
            },
            options: {
                responsive: false,
                plugins: {
                    legend: { display: false },
                    tooltip: { callbacks: { label: ctx => ` ${ctx.label}: ${ctx.parsed} (${pcts[ctx.dataIndex]}%)` } }
                }
            }
        });
    }

    // ── Init ──────────────────────────────────────────────────────────────────
    document.addEventListener('DOMContentLoaded', () => {
        fetch('https://raw.githubusercontent.com/laurauntner/sappho-digital/refs/heads/main/data/wikimetrix.csv')
            .then(r => { if (!r.ok) throw new Error('HTTP ' + r.status); return r.text(); })
            .then(text => {
                const raw         = parseCsv(text).map(toEntry).filter(e => e.wikidataId);
                const WM_DATA     = dedup(raw);
                const WM_WITH_QRANK = WM_DATA.filter(d => d.qrank !== null && d.qrank > 0);
                const qranks      = [...WM_WITH_QRANK].map(d => d.qrank).sort((a, b) => a - b);
                const medianQRank = qranks[Math.floor(qranks.length / 2)];
                const avgSitelinks = parseFloat((WM_DATA.reduce((s, d) => s + d.sitelinks, 0) / WM_DATA.length).toFixed(1));

                const state = { WM_DATA, WM_WITH_QRANK, charts: {} };

                buildWmKpi(WM_DATA, WM_WITH_QRANK, medianQRank, avgSitelinks);
                buildWmTabs(state);
                renderWmScatter(state);
                renderWmScatter(state);
                renderWmTopQrank(state);

                document.getElementById('sel-wm-qrank-topn')?.addEventListener('change', () => {
                    if (state.charts.topqrank) { state.charts.topqrank.destroy(); state.charts.topqrank = null; }
                    renderWmTopQrank(state);
                });
                document.getElementById('sel-wm-sl-topn')?.addEventListener('change', () => {
                    if (state.charts.topsitelinks) { state.charts.topsitelinks.destroy(); state.charts.topsitelinks = null; }
                    renderWmTopSitelinks(state);
                    renderWmSitelinksPie(state);
                });
            })
            .catch(err => {
                console.error('wikimetrix.csv konnte nicht geladen werden:', err);
                const kpi = document.getElementById('wm-kpi-wrap');
                if (kpi) kpi.innerHTML = `<p style="color:#dc2626;font-size:.85rem;">Fehler beim Laden der Wiki-Daten: ${err.message}</p>`;
            });
    });

})();