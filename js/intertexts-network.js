// intertexts-network-v4.js
import Graph from 'https://cdn.jsdelivr.net/npm/graphology@0.25.4/+esm';
import forceAtlas2 from 'https://cdn.jsdelivr.net/npm/graphology-layout-forceatlas2@0.10.1/+esm';
import { Sigma } from 'https://cdn.jsdelivr.net/npm/sigma@3.0.0/+esm';

// ---------- DOM ----------
const dataEl     = document.getElementById('itx-graph-data');
const container  = document.getElementById('itx-graph');
const edgeSlider = document.getElementById('edge-threshold');

if (container) {
    (async () => {

        // ---------- Ladeindikator ----------
        const loader = document.createElement('div');
        loader.style.cssText =
            'position:absolute;inset:0;display:flex;align-items:center;' +
            'justify-content:center;font-size:0.85rem;color:#6b7280;pointer-events:none;';
        loader.textContent = 'Graph wird geladen …';
        container.style.position = 'relative';
        container.appendChild(loader);
        const setStatus = (msg) => { loader.textContent = msg; };
        const hideLoader = () => { loader.remove(); };

        // ---------- Daten laden ----------
        let payload = {};
        try {
            const dataSrc = container.dataset.src;
            if (dataSrc) {
                setStatus('Daten werden geladen …');
                const res = await fetch(dataSrc, { cache: 'force-cache' });
                if (!res.ok) throw new Error(`HTTP ${res.status}`);
                payload = await res.json();
            } else if (dataEl) {
                payload = JSON.parse(dataEl.textContent || '{}');
            } else {
                container.textContent = 'Keine Graphdaten gefunden.';
                return;
            }
        } catch (e) {
            console.error(e);
            container.textContent = 'Daten konnten nicht geladen werden.';
            return;
        }

        // ---------- Guards ----------
        if (!payload || !Array.isArray(payload.nodes) || !Array.isArray(payload.edges)) {
            container.textContent = 'Ungültige Graphdaten.';
            return;
        }
        if (payload.nodes.length === 0) {
            container.textContent = 'Keine Graphdaten vorhanden.';
            return;
        }

        // ---------- Parameter ----------
        const K_STRUCT = 2;
        const COLORS   = { frag: '#a78bfa', recep: '#9ca3af' };

        // ---------- Graph aufbauen ----------
        setStatus('Graph wird aufgebaut …');
        await tick();

        const G = new Graph({ type: 'undirected', allowSelfLoops: false, multi: false });

        for (const n of payload.nodes) {
            if (!n?.id || G.hasNode(n.id)) continue;
            G.addNode(n.id, {
                label: n.label || n.id,
                kind:  n.kind  || 'recep',
                href:  n.href  || null,
                color: COLORS[n.kind] || '#9ca3af',
                size:  1,
                x: typeof n.x === 'number' ? n.x : (Math.random() - 0.5) * 10,
                y: typeof n.y === 'number' ? n.y : (Math.random() - 0.5) * 10,
            });
        }

        for (const e of payload.edges) {
            if (!e?.source || !e?.target) continue;
            if (!G.hasNode(e.source) || !G.hasNode(e.target) || e.source === e.target) continue;
            const key = e.source < e.target ? `${e.source}|${e.target}` : `${e.target}|${e.source}`;
            const w   = e.weight || 1;
            if (!G.hasEdge(e.source, e.target)) {
                G.addEdgeWithKey(key, e.source, e.target, {
                    weight: w,
                    size: Math.max(0.1, 0.4 * Math.log2(1 + w))
                });
            } else {
                const prev = (G.getEdgeAttribute(key, 'weight') || 0) + w;
                G.setEdgeAttribute(key, 'weight', prev);
                G.setEdgeAttribute(key, 'size', Math.max(0.1, 0.4 * Math.log2(1 + prev)));
            }
        }

        if (G.order === 0) { container.textContent = 'Keine darstellbaren Knoten vorhanden.'; return; }

        // ---------- Knotengrößen ----------
        G.forEachNode((n) => {
            const deg = G.degree(n);
            G.setNodeAttribute(n, 'size', Math.min(Math.max(0.8, 0.3 + Math.log2(1 + deg) * 0.75), 4));
        });

        // ---------- Strukturfilter ----------
        setStatus('Struktur wird gefiltert …');
        await tick();

        const keepSet = new Set();

        // kNN: Top-K Nachbarn pro Knoten
        G.forEachNode((n) => {
            const nbrs = [];
            G.forEachNeighbor(n, (m) => {
                const key = n < m ? `${n}|${m}` : `${m}|${n}`;
                nbrs.push({ key, w: G.getEdgeAttribute(key, 'weight') || 1 });
            });
            nbrs.sort((a, b) => b.w - a.w);
            nbrs.slice(0, K_STRUCT).forEach(({ key }) => keepSet.add(key));
        });

        // MST (Kruskal)
        {
            const edges = [];
            G.forEachEdge((key) => edges.push({
                key, s: G.source(key), t: G.target(key),
                w: G.getEdgeAttribute(key, 'weight') || 1
            }));
            edges.sort((a, b) => b.w - a.w);

            const parent = new Map();
            G.forEachNode((n) => parent.set(n, n));
            const find = (x) => {
                while (parent.get(x) !== x) { parent.set(x, parent.get(parent.get(x))); x = parent.get(x); }
                return x;
            };
            for (const { key, s, t } of edges) {
                const rs = find(s), rt = find(t);
                if (rs !== rt) { keepSet.add(key); parent.set(rs, rt); }
            }
        }

        G.forEachEdge((e) => {
            const s = G.source(e), t = G.target(e);
            const k = s < t ? `${s}|${t}` : `${t}|${s}`;
            G.setEdgeAttribute(e, 'keep_structural', keepSet.has(k));
        });

        // ---------- Layout in Chunks (kein UI-Freeze) ----------
        // ForceAtlas2 wird in kleinen Häppchen ausgeführt; zwischen jedem
        // Chunk gibt setTimeout(0) dem Browser Zeit zum Atmen.
        const CHUNK = 50;
        const TOTAL = Math.min(300, Math.round(G.order * 0.5));
        const FA2_SETTINGS = {
            linLogMode:                     true,
            gravity:                        0.05,
            scalingRatio:                   400,
            edgeWeightInfluence:            0.12,
            outboundAttractionDistribution: true,
            adjustSizes:                    false,  // teuer bei 10k Knoten
            barnesHutOptimize:              true,
            barnesHutTheta:                 0.8,
            slowDown:                       8,
        };

        let done = 0;
        while (done < TOTAL) {
            const iter = Math.min(CHUNK, TOTAL - done);
            forceAtlas2.assign(G, { iterations: iter, settings: FA2_SETTINGS });
            done += iter;
            setStatus(`Layout … ${Math.round((done / TOTAL) * 100)} %`);
            await tick();
        }

        // ---------- Viewport-Normalisierung ----------
        {
            let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
            G.forEachNode((n) => {
                const x = G.getNodeAttribute(n, 'x'), y = G.getNodeAttribute(n, 'y');
                if (x < minX) minX = x; if (x > maxX) maxX = x;
                if (y < minY) minY = y; if (y > maxY) maxY = y;
            });
            const cx  = (minX + maxX) / 2, cy = (minY + maxY) / 2;
            const w   = container.clientWidth || 1, h = container.clientHeight || 1;
            const inv = 1 / Math.max(
                Math.max(1e-6, maxX - minX) / (w * 0.85),
                Math.max(1e-6, maxY - minY) / (h * 0.85)
            );
            G.forEachNode((n) => {
                G.setNodeAttribute(n, 'x', (G.getNodeAttribute(n, 'x') - cx) * inv);
                G.setNodeAttribute(n, 'y', (G.getNodeAttribute(n, 'y') - cy) * inv);
            });
        }

        // ---------- Renderer ----------
        setStatus('Renderer wird initialisiert …');
        await tick();

        const renderer = new Sigma(G, container, {
            renderLabels:               true,
            labelDensity:               0.05,   // weniger Labels bei 10k Knoten
            labelRenderedSizeThreshold: 6,      // Labels erst ab höherem Zoom sichtbar
            defaultEdgeType:            'line',
            edgeColor:                  'default',
            defaultEdgeColor:           '#e5ebe5',
            hideEdgesOnMove:            true,   // Kanten beim Pan/Zoom ausblenden → flüssiger
            hideLabelsOnMove:           true,
        });

        renderer.setSetting('labelFont', '"Geist", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif');
        renderer.setSetting('defaultLabelColor', '#000');
        renderer.setSetting('labelSize', 10);

        hideLoader();

        // ---------- Interaktion ----------
        renderer.on('clickNode', (ev) => {
            const href = G.getNodeAttribute(ev.node, 'href');
            if (href) window.open(href, '_blank', 'noopener');
        });

        // ---------- Kantenschwellwert ----------
        let minWeight = edgeSlider ? Number(edgeSlider.value) || 1 : 1;

        renderer.setSetting('edgeReducer', (e, a) => {
            a.hidden = !a.keep_structural || a.weight < minWeight;
            return a;
        });

        if (edgeSlider) {
            if (!edgeSlider.hasAttribute('min'))  edgeSlider.min  = '1';
            if (!edgeSlider.hasAttribute('max'))  edgeSlider.max  = '20';
            if (!edgeSlider.hasAttribute('step')) edgeSlider.step = '1';
            edgeSlider.addEventListener('input', () => {
                minWeight = Number(edgeSlider.value) || 1;
                renderer.refresh();
            });
        }

        // ---------- Resize ----------
        let resizeTimer = 0;
        window.addEventListener('resize', () => {
            clearTimeout(resizeTimer);
            resizeTimer = setTimeout(() => renderer.refresh(), 150);
        });

    })();
}

// Gibt dem Browser einen Frame Zeit zum Rendern/Atmen
function tick() {
    return new Promise(r => setTimeout(r, 0));
}