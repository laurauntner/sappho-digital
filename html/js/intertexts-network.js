// intertexts-network-v3.js
import Graph from 'https://cdn.jsdelivr.net/npm/graphology@0.25.4/+esm';
import forceAtlas2 from 'https://cdn.jsdelivr.net/npm/graphology-layout-forceatlas2@0.10.1/+esm';
import noverlap from 'https://cdn.jsdelivr.net/npm/graphology-layout-noverlap@0.4.2/+esm';
import { Sigma } from 'https://cdn.jsdelivr.net/npm/sigma@3.0.0/+esm';

// ---------- DOM ----------
const dataEl = document.getElementById('itx-graph-data');
const container = document.getElementById('itx-graph');
const edgeSlider = document.getElementById('edge-threshold');

if (!container) {
    // Seite ohne Graph – nichts zu tun
} else {
    (async () => {
        // ---------- Daten laden ----------
        let payload = {};
        try {
            const dataSrc = container.dataset.src;

            if (dataSrc) {
                const res = await fetch(dataSrc, { cache: 'force-cache' });
                if (!res.ok) throw new Error(`HTTP ${res.status} beim Laden von ${dataSrc}`);
                payload = await res.json();
            } else if (dataEl) {
                payload = JSON.parse(dataEl.textContent || '{}');
            } else {
                container.textContent = 'Keine Graphdaten gefunden.';
                return;
            }
        } catch (e) {
            console.error(e);
            container.textContent = 'Daten konnten nicht geladen oder geparst werden.';
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
        const COLORS = {
            frag: '#a78bfa',
            recep: '#9ca3af'
        };

        // ---------- Graph aufbauen ----------
        const G = new Graph({
            type: 'undirected',
            allowSelfLoops: false,
            multi: false
        });

        (payload.nodes || []).forEach((n) => {
            if (!n || !n.id) return;
            if (!G.hasNode(n.id)) {
                G.addNode(n.id, {
                    label: n.label || n.id,
                    kind: n.kind || 'recep',
                    href: n.href || null,
                    color: COLORS[n.kind] || '#9ca3af',
                    size: 1
                });
            }
        });

        (payload.edges || []).forEach((e) => {
            if (!e || !e.source || !e.target) return;
            if (!G.hasNode(e.source) || !G.hasNode(e.target) || e.source === e.target) return;

            const key = e.source < e.target ? `${e.source}|${e.target}` : `${e.target}|${e.source}`;

            if (!G.hasEdge(e.source, e.target)) {
                G.addEdgeWithKey(key, e.source, e.target, {
                    weight: e.weight || 1,
                    size: Math.max(0.1, 0.4 * Math.log2(1 + (e.weight || 1)))
                });
            } else {
                const a = G.getEdgeAttributes(key) || {};
                const w = (a.weight || 0) + (e.weight || 1);
                G.setEdgeAttribute(key, 'weight', w);
                G.setEdgeAttribute(key, 'size', Math.max(0.1, 0.4 * Math.log2(1 + w)));
            }
        });

        if (G.order === 0) {
            container.textContent = 'Keine darstellbaren Knoten vorhanden.';
            return;
        }

        // ---------- Knotengrößen ----------
        G.forEachNode((n) => {
            const deg = G.degree(n);
            const size = Math.max(0.8, 0.3 + Math.log2(1 + deg) * 0.75);
            G.setNodeAttribute(n, 'size', Math.min(size, 4));
        });

        // ---------- Startpositionen ----------
        const R = 10;
        G.forEachNode((n) => {
            if (typeof G.getNodeAttribute(n, 'x') !== 'number') {
                G.setNodeAttribute(n, 'x', (Math.random() - 0.5) * R);
            }
            if (typeof G.getNodeAttribute(n, 'y') !== 'number') {
                G.setNodeAttribute(n, 'y', (Math.random() - 0.5) * R);
            }
        });

        // ---------- Hilfsfunktionen ----------
        function edgeKey(a, b) {
            return a < b ? `${a}|${b}` : `${b}|${a}`;
        }

        function weightOfKey(key) {
            return G.getEdgeAttribute(key, 'weight') || 1;
        }

        // ---------- Strukturfilter ----------
        function keepTopKEdges(k = 2) {
            const keep = new Set();
            G.forEachNode((n) => {
                const nbrs = [];
                G.forEachNeighbor(n, (m) => {
                    const key = edgeKey(n, m);
                    nbrs.push({ key, w: weightOfKey(key) });
                });
                nbrs.sort((a, b) => b.w - a.w);
                nbrs.slice(0, k).forEach(({ key }) => keep.add(key));
            });
            return keep;
        }

        function maximumSpanningTree() {
            const edges = G.edges()
                .map((key) => ({
                    key,
                    s: G.source(key),
                    t: G.target(key),
                    w: weightOfKey(key)
                }))
                .sort((a, b) => b.w - a.w);

            const parent = new Map();
            G.forEachNode((n) => parent.set(n, n));

            const find = (x) => {
                while (parent.get(x) !== x) {
                    parent.set(x, parent.get(parent.get(x)));
                    x = parent.get(x);
                }
                return x;
            };

            const unite = (a, b) => {
                const ra = find(a);
                const rb = find(b);
                if (ra !== rb) parent.set(ra, rb);
            };

            const tree = new Set();
            for (const { key, s, t } of edges) {
                const rs = find(s);
                const rt = find(t);
                if (rs !== rt) {
                    tree.add(key);
                    unite(rs, rt);
                }
            }
            return tree;
        }

        function applyStructuralFiltering(k = 2) {
            const knn = keepTopKEdges(k);
            const mst = maximumSpanningTree();
            const keep = new Set([...knn, ...mst]);

            G.forEachEdge((e) => {
                const s = G.source(e);
                const t = G.target(e);
                const kstr = edgeKey(s, t);
                G.setEdgeAttribute(e, 'keep_structural', keep.has(kstr));
            });
        }

        applyStructuralFiltering(K_STRUCT);

        // ---------- Layout ----------
        forceAtlas2.assign(G, {
            iterations: Math.max(300, Math.min(800, G.order * 2)),
            settings: {
                linLogMode: true,
                gravity: 0.00000000001,
                scalingRatio: 800,
                edgeWeightInfluence: 0.12,
                outboundAttractionDistribution: true,
                adjustSizes: true,
                barnesHutOptimize: true,
                barnesHutTheta: 0.7,
                slowDown: 14
            }
        });

        noverlap.assign(G, {
            margin: 3,
            ratio: 1.15,
            maxIterations: 120
        });

        // ---------- Viewport-Normalisierung ----------
        function normalizeToViewport(padding = 0.85) {
            if (G.order === 0) return;

            let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;

            G.forEachNode((n) => {
                const x = G.getNodeAttribute(n, 'x');
                const y = G.getNodeAttribute(n, 'y');
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
                if (y < minY) minY = y;
                if (y > maxY) maxY = y;
            });

            const dx = Math.max(1e-6, maxX - minX);
            const dy = Math.max(1e-6, maxY - minY);
            const cx = (minX + maxX) / 2;
            const cy = (minY + maxY) / 2;

            const w = container.clientWidth || 1;
            const h = container.clientHeight || 1;
            const sx = dx / (w * padding);
            const sy = dy / (h * padding);
            const scale = Math.max(sx, sy);
            const inv = 1 / scale;

            G.forEachNode((n) => {
                const x = G.getNodeAttribute(n, 'x');
                const y = G.getNodeAttribute(n, 'y');
                G.setNodeAttribute(n, 'x', (x - cx) * inv);
                G.setNodeAttribute(n, 'y', (y - cy) * inv);
            });
        }

        normalizeToViewport(0.85);

        // ---------- Renderer ----------
        const renderer = new Sigma(G, container, {
            renderLabels: true,
            labelDensity: 0.1,
            labelRenderedSizeThreshold: 3,
            defaultEdgeType: 'line',
            edgeColor: 'default',
            defaultEdgeColor: '#e5ebe5'
        });

        renderer.setSetting('labelFont', '"Geist", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif');
        renderer.setSetting('defaultLabelColor', '#000');
        renderer.setSetting('labelSize', 10);

        // ---------- Interaktion ----------
        renderer.on('clickNode', (ev) => {
            const href = G.getNodeAttribute(ev.node, 'href');
            if (href) window.open(href, '_blank', 'noopener');
        });

        // ---------- Kantenschwellwert ----------
        let minWeight = edgeSlider ? Number(edgeSlider.value) || 1 : 1;

        renderer.setSetting('edgeReducer', (e, a) => {
            const keepStruct = a.keep_structural !== false;
            const w = typeof a.weight === 'number' ? a.weight : 1;
            if (!keepStruct || w < minWeight) {
                return { ...a, hidden: true };
            }
            return { ...a, hidden: false };
        });

        if (edgeSlider) {
            if (!edgeSlider.hasAttribute('min')) edgeSlider.min = '1';
            if (!edgeSlider.hasAttribute('max')) edgeSlider.max = '20';
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
            resizeTimer = setTimeout(() => {
                normalizeToViewport(0.85);
                renderer.refresh();
            }, 150);
        });

    })();
}