const C = {
    s: 'rgba(94,23,235,0.75)',
    sLine: '#5e17eb',
    r: 'rgba(107,114,128,0.75)',
    rLine: '#6b7280',
};

const charts = {
};

// Balkenhöhe
function canvasHeight(n) {
    return Math.max(120, n * 32 + 40);
}

// X-Achsen-Maximum: nächste runde Zahl über dem tatsächlichen Maximum
function xMax(items) {
    const max = Math.max(...items.map(i => parseFloat(i.pctSappho)),...items.map(i => parseFloat(i.pctReception)));
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
        body.classList.toggle('visible', ! isOpen);
        head.classList.toggle('open', ! isOpen);
        if (! isOpen && ! charts[cat.key]) {
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
            datasets:[ {
                label: `Sappho-Fragmente (n=${DATA.nSappho})`,
                data: pctS,
                backgroundColor: C.s,
                borderColor: C.sLine,
                borderWidth: 1,
                borderRadius: 2,
            }, {
                label: `Rezeptionszeugnisse (n=${DATA.nReception})`,
                data: pctR,
                backgroundColor: C.r,
                borderColor: C.rLine,
                borderWidth: 1,
                borderRadius: 2,
            },],
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
                            const count = isSappho ? d.countSappho: d.countReception;
                            const total = isSappho ? DATA.nSappho: DATA.nReception;
                            const pct = ctx.parsed.x.toFixed(2);
                            const name = isSappho ? 'Sappho': 'Rezeption';
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
                        font: {
                            family: 'Geist, system-ui', size: 11
                        },
                        callback: v => v + '%', stepSize: 5
                    },
                    grid: {
                        color: 'rgba(0,0,0,0.06)'
                    },
                },
                y: {
                    ticks: {
                        font: {
                            family: 'Geist, system-ui', size: 12
                        },
                        autoSkip: false
                    },
                    grid: {
                        display: false
                    },
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

// Sankey

const FTYPE_COLORS = {
    person_ref: '#f59e0b',
    character: '#3b82f6',
    place_ref: '#10b981',
    topos: '#ef4444',
    motif: '#8b5cf6',
    topic: '#06b6d4',
    plot: '#f97316',
};

const SANKEY_COLORS = {
    taken: '#5e17eb',
    omitted: '#d1d5db',
    added: '#f97316',
};

function initSankey() {
    const sel = document.getElementById('sel-sankey-fragment');
    if (! sel) return;
    
    (DATA.fragments ||[]).forEach(frag => {
        if (! frag.sapphoFeatures || ! frag.sapphoFeatures.length) return;
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
    if (! _tip) {
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
    t.style.top = (e.clientY - 28) + 'px';
}
function hideTip() {
    if (_tip) _tip.style.display = 'none';
}

function renderSankey2(fragLabel) {
    const placeholder = document.getElementById('sankey-placeholder2');
    const svgWrap = document.getElementById('sankey-svg-wrap');
    const legend = document.getElementById('sankey-legend');
    
    hideTip();
    
    if (! fragLabel) {
        placeholder.style.display = '';
        svgWrap.style.display = 'none';
        legend.style.display = 'none';
        return;
    }
    
    const frag = (DATA.fragments ||[]).find(f => f.label === fragLabel);
    if (! frag) return;
    
    const sapphoFeats = {
    };
    (frag.sapphoFeatures ||[]).forEach(ft => {
        ft.items.forEach(item => {
            sapphoFeats[item.uri] = {
                label: item.label, ftypeKey: ft.key
            };
        });
    });
    const recepFeats = {
    };
    (frag.featureTypes ||[]).forEach(ft => {
        ft.items.forEach(item => {
            recepFeats[item.uri] = {
                label: item.label, ftypeKey: ft.key, count: item.count
            };
        });
    });
    
    if (! Object.keys(sapphoFeats).length && ! Object.keys(recepFeats).length) {
        placeholder.textContent = 'Keine Daten.';
        placeholder.style.display = '';
        svgWrap.style.display = 'none';
        return;
    }
    
    placeholder.style.display = 'none';
    svgWrap.style.display = '';
    legend.style.display = 'none';
    svgWrap.innerHTML = '';
    
    const FTYPES_ORDER =[ 'person_ref', 'character', 'place_ref', 'topos', 'motif', 'topic', 'plot'];
    const allUris = new Set ([...Object.keys(sapphoFeats),...Object.keys(recepFeats)]);
    const taken =[...allUris].filter(u => sapphoFeats[u] && recepFeats[u]);
    const omitted =[...allUris].filter(u => sapphoFeats[u] && ! recepFeats[u]);
    const added =[...allUris].filter(u => ! sapphoFeats[u] && recepFeats[u]);
    
    const ftypeLabels = {
    };
    (DATA.categories ||[]).forEach(c => {
        ftypeLabels[c.key] = c.label;
    });
    
    const sortByType = (uris, getInfo) => {
        const result =[];
        FTYPES_ORDER.forEach(key => {
            const group = uris.filter(u => getInfo(u) ?.ftypeKey === key);
            if (group.length) result.push({
                ftypeKey: key, uris: group
            });
        });
        return result;
    };
    
    const leftGroups = sortByType([...taken,...omitted], u => sapphoFeats[u]);
    const rightGroups = sortByType([...taken,...added], u => recepFeats[u]);
    
    const containerW = svgWrap.getBoundingClientRect().width || 800;
    
    const FONT = 12;
    const ROW_H = 18;
    const TYPE_H = 16;
    const GRP_GAP = 8;
    const HDR_H = 20;
    const NODE_W = 8;
    const PAD = 6;
    const FLOW_W = Math.round(containerW * 0.32);
    const LABEL_W = Math.round((containerW - FLOW_W - 2 * NODE_W - 2 * PAD) / 2);
    const W = containerW;
    
    const lNodeX = LABEL_W + PAD;
    const rNodeX = lNodeX + NODE_W + FLOW_W;
    
    const groupsH = (groups) =>
    groups.reduce((s, g) => s + TYPE_H + g.uris.length * ROW_H + GRP_GAP, 0);
    const H = HDR_H + Math.max(groupsH(leftGroups), groupsH(rightGroups)) + 8;
    
    // Knoten
    const nodeMap = {
    };
    const placeGroups = (groups, side, getFeats) => {
        let y = HDR_H;
        groups.forEach(({ ftypeKey, uris
        }) => {
            y += TYPE_H;
            uris.forEach(u => {
                const cx = side === 'left' ? lNodeX: rNodeX;
                nodeMap[u + '_' + (side === 'left' ? 'L': 'R')] = {
                    x: cx, y0: y + 1, y1: y + ROW_H -3, yc: y + ROW_H / 2,
                    label: getFeats(u).label, ftypeKey,
                    category: (side === 'left' ? recepFeats[u]: sapphoFeats[u]) ? 'taken': (side === 'left' ? 'omitted': 'added'),
                    side, uri: u,
                };
                y += ROW_H;
            });
            y += GRP_GAP;
        });
    };
    placeGroups(leftGroups, 'left', u => sapphoFeats[u]);
    placeGroups(rightGroups, 'right', u => recepFeats[u]);
    
    const svg = d3.select(svgWrap).append('svg').attr('width', W).attr('height', H).style('font-family', 'Geist, system-ui, sans-serif').style('font-size', FONT + 'px').style('overflow', 'visible');
    
    // Spalten-Header
    [[ 'FRAGMENT', lNodeX - PAD, 'end'],[ `REZEPTIONSZEUGNISSE (n=${frag.nBibl})`, rNodeX + NODE_W + PAD, 'start']].forEach(([txt, x, anchor]) => {
        svg.append('text').attr('x', x).attr('y', HDR_H - 5).attr('text-anchor', anchor).attr('font-size', '9px').attr('font-weight', '700').attr('fill', '#9ca3af').attr('letter-spacing', '0.06em').text(txt);
    });
    
    // Typ-Header
    const drawTypeHeaders = (groups, side) => {
        let y = HDR_H;
        groups.forEach(({ ftypeKey, uris
        }) => {
            const x = side === 'left' ? lNodeX - PAD: rNodeX + NODE_W + PAD;
            const anchor = side === 'left' ? 'end': 'start';
            svg.append('text').attr('x', x).attr('y', y + TYPE_H - 4).attr('text-anchor', anchor).attr('font-size', '9px').attr('font-weight', '700').attr('fill', FTYPE_COLORS[ftypeKey] || '#6b7280').attr('letter-spacing', '0.04em').text((ftypeLabels[ftypeKey] || ftypeKey).toUpperCase());
            y += TYPE_H + uris.length * ROW_H + GRP_GAP;
        });
    };
    drawTypeHeaders(leftGroups, 'left');
    drawTypeHeaders(rightGroups, 'right');
    
    // Flusslinien
    const maxCount = Math.max(1,...taken.map(u => recepFeats[u] ?.count || 1));
    taken.forEach(u => {
        const nL = nodeMap[u + '_L'], nR = nodeMap[u + '_R'];
        if (! nL || ! nR) return;
        const color = FTYPE_COLORS[nL.ftypeKey] || '#5e17eb';
        const count = recepFeats[u].count;
        const wL = 1.5;
        const wR = count <= 1 ? 1.5: 1.5 + Math.pow((count - 1) / Math.max(1, maxCount - 1), 0.6) * 14;
        const x0 = lNodeX + NODE_W, y0 = nL.yc;
        const x1 = rNodeX, y1 = nR.yc;
        const mx = (x0 + x1) / 2;
        const N = 32;
        const upper =[], lower =[];
        for (let i = 0; i <= N; i++) {
            const t = i / N;
            const bx = (1 - t) * * 3 * x0 + 3 *(1 - t) * * 2 * t * mx + 3 *(1 - t) * t * * 2 * mx + t * * 3 * x1;
            const by = (1 - t) * * 3 * y0 + 3 *(1 - t) * * 2 * t * y0 + 3 *(1 - t) * t * * 2 * y1 + t * * 3 * y1;
            const dbx = 3 *((1 - t) * * 2 *(mx - x0) + t * * 2 *(x1 - mx));
            const dby = 3 *(2 *(1 - t) * t *(y1 - y0));
            const len = Math.sqrt(dbx * dbx + dby * dby) || 1;
            const hw = (wL + (wR - wL) * t) / 2;
            upper.push(`${bx + (-dby/len)*hw},${by + (dbx/len)*hw}`);
            lower.push(`${bx - (-dby/len)*hw},${by - (dbx/len)*hw}`);
        }
        const pct = frag.nBibl > 0 ? Math.round(count / frag.nBibl * 100): 0;
        const tipText = `${sapphoFeats[u].label}: ${count} Rezeptionszeugnis${count !== 1 ? 'se' : ''} (${pct}%)`;
        const poly = svg.append('polygon').attr('points',[...upper,...[...lower].reverse()].join(' ')).attr('fill', color).attr('fill-opacity', 0.45).style('cursor', 'default');
        poly.on('mouseenter', (e) => showTip(e, tipText)).on('mousemove', (e) => moveTip(e)).on('mouseleave', () => hideTip());
    });
    
    // Knoten
    Object.values(nodeMap).forEach(n => {
        const color = n.category === 'taken' ? (FTYPE_COLORS[n.ftypeKey] || '#5e17eb'): '#d1d5db';
        svg.append('rect').attr('x', n.x).attr('y', n.y0).attr('width', NODE_W).attr('height', Math.max(1, n.y1 - n.y0)).attr('fill', color).attr('rx', 2);
    });
    
    // Labels
    const charW = 6.5;
    const maxChars = Math.floor(LABEL_W / charW);
    
    Object.values(nodeMap).forEach(n => {
        if (! n.label) return;
        const isLeft = n.side === 'left';
        const x = isLeft ? lNodeX - PAD: rNodeX + NODE_W + PAD;
        const anchor = isLeft ? 'end': 'start';
        const gray = n.category !== 'taken';
        const fill = gray ? '#b0b8c4': '#1f2937';
        const count = (! gray && recepFeats[n.uri]) ? recepFeats[n.uri].count: null;
        const pctL = (count !== null && frag.nBibl > 0) ? Math.round(count / frag.nBibl * 100): null;
        const tipText = count !== null ? `${n.label}: ${count} Rezeptionszeugnis${count !== 1 ? 'se' : ''} (${pctL}%)`: n.label;
        const display = n.label.length > maxChars ? n.label.slice(0, maxChars - 1) + '…': n.label;
        
        const el = svg.append('text').attr('x', x).attr('y', n.yc).attr('dy', '0.35em').attr('text-anchor', anchor).attr('font-size', FONT + 'px').attr('fill', fill).text(display);
        
        el.on('mouseenter', (e) => showTip(e, tipText)).on('mousemove', (e) => moveTip(e)).on('mouseleave', () => hideTip());
    });
}

document.addEventListener('DOMContentLoaded', initSankey);