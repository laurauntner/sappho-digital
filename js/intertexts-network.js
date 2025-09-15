import Graph from 'https://cdn.jsdelivr.net/npm/graphology@0.25.4/+esm';
import forceAtlas2 from 'https://cdn.jsdelivr.net/npm/graphology-layout-forceatlas2@0.10.1/+esm';
import {
    Sigma
}
from 'https://cdn.jsdelivr.net/npm/sigma@3.0.0/+esm';

const dataEl = document.getElementById('itx-graph-data');
const container = document.getElementById('itx-graph');
const input = document.getElementById('graph-search');

if (! dataEl || ! container) {
} else {
    let payload;
    try {
        payload = JSON.parse(dataEl.textContent || '{}');
    }
    catch (e) {
        container.textContent = 'Daten konnten nicht geparst werden.';
        throw e;
    }
    
    const COLORS = {
        frag: '#a78bfa', recep: '#9ca3af'
    };
    
    const G = new Graph({
        type: 'undirected', allowSelfLoops: false, multi: false
    });
    
    // Nodes
    (payload.nodes ||[]).forEach(n => {
        if (! G.hasNode(n.id)) {
            G.addNode(n.id, {
                label: n.label || n.id,
                kind: n.kind || 'recep',
                href: n.href || null,
                color: COLORS[n.kind] || '#9ca3af',
                size: 1
            });
        }
    });
    
    // Edges
    (payload.edges ||[]).forEach(e => {
        if (! G.hasNode(e.source) || ! G.hasNode(e.target) || e.source === e.target) return;
        const key = e.source < e.target ? `${e.source}|${e.target}`: `${e.target}|${e.source}`;
        if (! G.hasEdge(e.source, e.target)) {
            G.addEdgeWithKey(key, e.source, e.target, {
                weight: e.weight || 1,
                size: Math.max(1, Math.log2(1 + (e.weight || 1)))
            });
        } else {
            const a = G.getEdgeAttributes(key) || {
            };
            const w = (a.weight || 0) + (e.weight || 1);
            G.setEdgeAttribute(key, 'weight', w);
            G.setEdgeAttribute(key, 'size', Math.max(1, Math.log2(1 + w)));
        }
    });
    
    // Node-Größen
    G.forEachNode(n => {
        const deg = G.degree(n);
        G.setNodeAttribute(n, 'size', 0.5 + Math.log2(0.5 + deg) * 1.2);
    });
    
    // Startpositionen
    const R = 10;
    G.forEachNode(n => {
        if (typeof G.getNodeAttribute(n, 'x') !== 'number') {
            G.setNodeAttribute(n, 'x', (Math.random() - 0.5) * R);
        }
        if (typeof G.getNodeAttribute(n, 'y') !== 'number') {
            G.setNodeAttribute(n, 'y', (Math.random() - 0.5) * R);
        }
    });
    
    // ForceAtlas2
    forceAtlas2.assign(G, {
        iterations: 400,
        settings: {
            slowDown: 10, gravity: 0.3, scalingRatio: 50, adjustSizes: true, // berücksichtigt Knotengrößen -> weniger Überlapp
            barnesHutOptimize: true,
            barnesHutTheta: 0.6
        }
    });
    
    (function normalizeToViewport(padding = 0.85) {
        if (G.order === 0) return;
        
        let minX = Infinity, minY = Infinity, maxX = - Infinity, maxY = - Infinity;
        G.forEachNode(n => {
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
        
        G.forEachNode(n => {
            const x = G.getNodeAttribute(n, 'x');
            const y = G.getNodeAttribute(n, 'y');
            G.setNodeAttribute(n, 'x', (x - cx) * inv);
            G.setNodeAttribute(n, 'y', (y - cy) * inv);
        });
    })();
    
    // Render
    const renderer = new Sigma(G, container, {
        renderLabels: true,
        labelDensity: 0.2,
        labelRenderedSizeThreshold: 3,
        defaultEdgeType: 'line',
        edgeColor: 'default',
        defaultEdgeColor: '#c7cdd4'
    });
    
    renderer.setSetting('labelFont', '"Geist", system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif');
    renderer.setSetting('defaultLabelColor', '#000');
    renderer.setSetting('labelSize', 10);
    renderer.setSetting('labelRenderedSizeThreshold', 5);
    
    // Klick → Link
    renderer.on('clickNode', ev => {
        const href = G.getNodeAttribute(ev.node, 'href');
        if (href) window.open(href, '_blank', 'noopener');
    });
    
    // Suche
    if (input) {
        input.addEventListener('input', () => {
            const q = (input.value || '').trim().toLowerCase();
            
            // Reset
            if (! q) {
                renderer.setSetting('nodeReducer', undefined);
                renderer.setSetting('edgeReducer', undefined);
                renderer.refresh();
                return;
            }
            
            // Treffer sammeln
            const keep = new Set ();
            G.forEachNode((n, a) => {
                if ((a.label || '').toLowerCase().includes(q)) keep.add(n);
            });
            
            // Relevanz = Treffer + direkte Nachbarn
            const relevant = new Set (keep);
            keep.forEach(n => G.forEachNeighbor(n, m => relevant.add(m)));
            
            // Nodes: nie ausblenden, nur dezent dimmen/verkleinern
            renderer.setSetting('nodeReducer', (n, a) => {
                const focus = relevant.has(n);
                return {...a,
                    hidden: false,
                    zIndex: focus ? 1: 0,
                    size: focus ? a.size: Math.max(1, a.size * 0.75),
                    color: focus ? a.color: 'rgba(209,213,219,0.65)'
                };
            });
            
            // Edges: wie nodes
            renderer.setSetting('edgeReducer', (e, a) => {
                const {
                    source, target
                } = G.extremities(e);
                const isRelevant = relevant.has(source) || relevant.has(target);
                const baseColor = a.color || '#c7cdd4';
                return {...a,
                    hidden: false,
                    size: isRelevant ? (a.size || 1): Math.max(0.5, (a.size || 1) * 0.7),
                    color: isRelevant ? baseColor: 'rgba(199,205,212,0.6)'
                };
            });
            
            renderer.refresh();
        });
    }
}