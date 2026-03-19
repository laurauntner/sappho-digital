const C = {
    s: 'rgba(94,23,235,0.75)',
    sLine: '#5e17eb',
    r: 'rgba(107,114,128,0.75)',
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
    const pctS = cat.items.map(i => parseFloat(i.pctSappho));
    const pctR = cat.items.map(i => parseFloat(i.pctReception));
    const maxX = xMax(cat.items);

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
                            const pct = ctx.parsed.x.toFixed(2);
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
                        autoSkip: false
                    },
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
        [`REZEPTIONSZEUGNISSE (n=${frag.nBibl})`, rNodeX + NODE_W + PAD, 'start'],
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
                + `<br>${decLabel(dec)}: <strong>${v}</strong> Rezeptionszeugnis${v !== 1 ? 'se' : ''}`;
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

// ── Statistik 4 ────────────────────────────

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
    const colTotal = {};
    const colMax   = {};
    activeCols.forEach(g => {
        colTotal[g] = active.reduce((s, { feat }) => s + cellN(feat, g), 0) || 1;
        colMax[g]   = Math.max(1, ...active.map(({ feat }) => cellN(feat, g)));
    });

    const ROW_H   = 26;
    const COL_W   = singleGenre ? 350 : 265;
    const LABEL_W = 240;
    // Header: two lines (name + n=) when showing multiple genres
    const HDR_H   = singleGenre ? 0 : 46;
    const PAD_B   = 8;

    const nRows = active.length;
    const svgW  = LABEL_W + activeCols.length * COL_W + 8;
    const svgH  = HDR_H + nRows * ROW_H + PAD_B;

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
                x1: cx, y1: HDR_H, x2: cx, y2: HDR_H + nRows * ROW_H,
                stroke: 'rgba(0,0,0,0.06)', 'stroke-width': 1,
            }));
        });
    }

    // Rows
    active.forEach(({ feat }, ri) => {
        const y0    = HDR_H + ri * ROW_H;
        const yc    = y0 + ROW_H / 2;
        const color = (FTYPE_META[feat.ftype] || {}).color || '#6b7280';

        if (ri % 2 === 0) {
            svg.appendChild(set(mk('rect'), {
                x: 0, y: y0, width: svgW, height: ROW_H,
                fill: 'rgba(0,0,0,0.018)',
            }));
        }

        svg.appendChild(set(mk('rect'), {
            x: 0, y: y0 + 2, width: 3, height: ROW_H - 4,
            fill: color, rx: 1,
        }));

        const MAX_CHARS = 28;
        const rawLabel  = feat.label;
        const label     = rawLabel.length > MAX_CHARS ? rawLabel.slice(0, MAX_CHARS - 1) + '…' : rawLabel;
        const labelEl   = txt(LABEL_W - 8, yc, label, {
            'text-anchor': 'end', dy: '0.35em',
            'font-size': '11px', fill: '#1f2937',
        });
        if (showType || rawLabel.length > MAX_CHARS) {
            const ftypeLbl = (FTYPE_META[feat.ftype] || {}).singular || feat.ftype;
            labelEl.addEventListener('mouseenter', e => pdTipShow(e,
                `<strong>${rawLabel}</strong><br><span style="font-size:10px;color:rgba(255,255,255,0.75)">${ftypeLbl}</span>`));
            labelEl.addEventListener('mousemove',  e => pdTipMove(e));
            labelEl.addEventListener('mouseleave', pdTipHide);
            labelEl.style.cursor = 'default';
        }
        svg.appendChild(labelEl);

        // Cells
        activeCols.forEach((genre, ci) => {
            const v   = cellN(feat, genre);
            const pct = (v / colTotal[genre] * 100);
            const cx  = LABEL_W + ci * COL_W;
            const cw  = COL_W - 3;

            // Strong contrast: power curve with exponent 0.6, min opacity 0 (empty = blank)
            const opacity = v === 0 ? 0 : 0.12 + 0.88 * Math.pow(v / colMax[genre], 0.6);

            const cellRect = set(mk('rect'), {
                x: cx + 1, y: y0 + 2, width: cw, height: ROW_H - 4,
                fill: color, 'fill-opacity': opacity, rx: 2,
            });
            svg.appendChild(cellRect);

            if (v > 0) {
                // Show count + percentage. Switch text colour based on opacity.
                const onDark   = opacity > 0.50;
                const textFill = onDark ? '#fff' : color;
                const cellLabel = `${v} (${pct < 1 ? pct.toFixed(1) : Math.round(pct)}%)`;
                svg.appendChild(txt(cx + COL_W / 2, yc, cellLabel, {
                    'text-anchor': 'middle', dy: '0.35em',
                    'font-size': '10px',
                    fill: textFill,
                    'font-weight': onDark ? '600' : '400',
                    'pointer-events': 'none',
                }));
            }

            // Invisible hit target for tooltip
            const tipTarget = set(mk('rect'), {
                x: cx + 1, y: y0 + 2, width: cw, height: ROW_H - 4,
                fill: 'transparent',
            });
            tipTarget.style.cursor = 'default';
            const ftypeLabel = (FTYPE_META[feat.ftype] || {}).singular || feat.ftype;
            const tipHtml = `<strong>${rawLabel}</strong>`
                + (showType ? `<br><span style="font-size:10px;color:rgba(255,255,255,0.75)">(${ftypeLabel})</span>` : '')
                + `<br>${genre}: <strong>${v}</strong> Rezeptionszeugnis${v !== 1 ? 'se' : ''}`
                + (v > 0 ? ` (${pct < 1 ? pct.toFixed(1) : Math.round(pct)}%)` : '');
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
    const genreObjs   = gd.genres || [];   // [{key, n}, ...]
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