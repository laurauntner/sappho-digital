document.fonts.ready.then(function () {

(function () {
  if (window._networkInitialized) return;
  window._networkInitialized = true;

  // ── Daten aus DOM lesen ──────────────────────────────────────
  function readJSON(id) {
    var el = document.getElementById(id);
    if (!el) { console.error("Datenelement nicht gefunden: #" + id); return null; }
    return JSON.parse(el.textContent);
  }

  var ALL_NODES   = readJSON("network-nodes");
  var ALL_EDGES   = readJSON("network-edges");
  var CLASS_STATS = readJSON("network-class-stats");
  var NS_COLORS   = readJSON("network-ns-colors");
  var KNOWN_NS    = readJSON("network-known-ns");
  var META        = readJSON("network-meta");

  if (!ALL_NODES || !ALL_EDGES || !CLASS_STATS || !NS_COLORS || !KNOWN_NS || !META) return;

  // ── Aus Meta extrahieren ─────────────────────────────────────
  var DEFAULT_MAX_EDGES      = META.defaultMaxEdges;
  var DEFAULT_NEIGHBORS      = META.defaultNeighbors;
  var START_URI              = META.startUri;
  var HIDDEN_BY_DEFAULT      = new Set(META.hiddenByDefault);
  var INT31_NEIGHBOR_IDS     = new Set(META.int31NeighborIds);
  var FOCUS_CLASS            = "https://w3id.org/lso/intro/currentbeta#INT31_IntertextualRelation";

  // ── State ────────────────────────────────────────────────────
  var maxEdges       = DEFAULT_MAX_EDGES;
  var instModeActive = false;

  var activeClasses = new Set(Object.keys(CLASS_STATS).filter(function (c) {
    return !HIDDEN_BY_DEFAULT.has(c);
  }));

  // ── Farbzuordnung ────────────────────────────────────────────
  var CLASS_COLOR_MAP = {};
  Object.keys(CLASS_STATS).forEach(function (cls) {
    var prefix = "_unknown", bestLen = 0;
    Object.entries(KNOWN_NS).forEach(function (e) {
      var ns = e[0], px = e[1];
      if (cls.startsWith(ns) && ns.length > bestLen) { prefix = px; bestLen = ns.length; }
    });
    CLASS_COLOR_MAP[cls] = NS_COLORS[prefix] || NS_COLORS["_unknown"];
  });

  function nodeColor(n) {
    var c = null;
    for (var i = 0; i < n.classes.length; i++) {
      if (activeClasses.has(n.classes[i])) { c = CLASS_COLOR_MAP[n.classes[i]]; break; }
    }
    if (!c) c = NS_COLORS[n.group] || NS_COLORS["_unknown"];
    return {
      background: c, border: c,
      highlight: { background: c, border: "#8B5CF6" },
      hover:     { background: c, border: "#8B5CF6" },
    };
  }

  var VIS_GROUPS = {};
  Object.entries(NS_COLORS).forEach(function (e) {
    var px = e[0], c = e[1];
    VIS_GROUPS[px] = { color: {
      background: c, border: c,
      highlight: { background: c, border: "#8B5CF6" },
      hover:     { background: c, border: "#8B5CF6" },
    }};
  });

  // ── vis.js ───────────────────────────────────────────────────
  var nodesDS = new vis.DataSet([]);
  var edgesDS = new vis.DataSet([]);

  var network = new vis.Network(
    document.getElementById("graph"),
    { nodes: nodesDS, edges: edgesDS },
    {
      groups: VIS_GROUPS,
      nodes: {
        shape: "dot",
        scaling: { min: 4, max: 40, label: { enabled: true, min: 9, max: 18 } },
        font: { size: 11, color: "#222", face: "Geist" },
      },
      edges: {
        smooth: { type: "continuous" },
        font: { size: 9, color: "#999", align: "middle", face: "Geist" },
        color: { color: "#ccc", highlight: "#ccc", hover: "#aaa" },
        width: 1,
      },
      physics: {
        solver: "forceAtlas2Based",
        forceAtlas2Based: {
          gravitationalConstant: -400,
          springLength: 300,
          springConstant: 0.03,
          damping: 0.98,
          avoidOverlap: 1.0,
        },
        minVelocity: 1.0,
        stabilization: { enabled: true, iterations: 500, onlyDynamicEdges: false },
        adaptiveTimestep: true,
      },
      interaction: { tooltipDelay: 99999, hover: true },
    }
  );

  network.once("stabilized", function () {
    network.setOptions({ physics: { enabled: false } });
  });

  var _physicsTimer = null;
  nodesDS.on("add", function () {
    if (_physicsTimer) clearTimeout(_physicsTimer);
    network.setOptions({ physics: {
      enabled: true,
      forceAtlas2Based: {
        gravitationalConstant: -400, springLength: 300,
        springConstant: 0.03, damping: 0.98, avoidOverlap: 1.0,
      },
    }});
    _physicsTimer = setTimeout(function () {
      network.setOptions({ physics: { enabled: false } });
    }, 1500);
  });

  window.addEventListener("resize", function () { network.fit(); });

  // ── Lookups ──────────────────────────────────────────────────
  var EDGE_INDEX = {};
  ALL_EDGES.forEach(function (e) {
    if (!EDGE_INDEX[e.from]) EDGE_INDEX[e.from] = [];
    if (!EDGE_INDEX[e.to])   EDGE_INDEX[e.to]   = [];
    EDGE_INDEX[e.from].push(e.to);
    EDGE_INDEX[e.to].push(e.from);
  });

  var NODE_BY_ID = {};
  ALL_NODES.forEach(function (n) { NODE_BY_ID[n.id] = n; });

  // ── Label-Hilfsfunktionen ────────────────────────────────────
  function truncateLabel(s, max) {
    max = max || 28;
    return s.length > max ? s.slice(0, max).trimEnd() + " …" : s;
  }

  function escHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }
  function escAttr(s) { return String(s).replace(/'/g, "&#39;"); }

  function buildTooltipHtml(label, cls, uri, pageUrl) {
    var html = "<b>" + escHtml(label) + "</b>";
    if (cls) {
      html += "<br><span style='color:#888;font-size:11px'>" + escHtml(cls) + "</span>";
    }
    if (uri) {
      html += "<br><span style='color:#888;font-size:10px'>URI: </span>"
            + "<span style='color:#aaa;font-size:10px;word-break:break-all'>" + escHtml(uri) + "</span>";
    }
    if (pageUrl) {
      var urls = pageUrl.split(",");
      html += "<br><span style='color:#888;font-size:10px'>More Info: </span>";
      urls.forEach(function(u, i) {
        u = u.trim();
        if (i > 0) html += "<span style='color:#888'>, </span>";
        html += "<a href='" + escAttr(u) + "' target='_blank' rel='noopener'>" + escHtml(u) + "</a>";
      });
    }
    return html;
  }

  // ── Gepinnter Tooltip ────────────────────────────────────────
  var tooltip      = document.getElementById("node-tooltip");
  var tooltipBody  = document.getElementById("node-tooltip-body");
  var pinnedNodeId = null;

  document.getElementById("node-tooltip-close").onclick = function (e) {
    e.stopPropagation();
    hideTooltip();
  };

  function hideTooltip() {
    tooltip.style.display = "none";
    pinnedNodeId = null;
  }

  function positionTooltip(clientX, clientY) {
    var TW = tooltip.offsetWidth  || 280;
    var TH = tooltip.offsetHeight || 120;
    var left = clientX + 14;
    var top  = clientY + 14;
    if (left + TW > window.innerWidth  - 8) left = clientX - TW - 14;
    if (top  + TH > window.innerHeight - 8) top  = clientY - TH - 14;
    tooltip.style.left = Math.max(4, left) + "px";
    tooltip.style.top  = Math.max(4, top)  + "px";
  }

  function showTooltip(nodeId, clientX, clientY, pin) {
    var n = NODE_BY_ID[nodeId];
    if (!n) return;
    var cls = n.classes.length > 0 ? n.classes[0].split(/[#\/]/).pop() : "";
    tooltipBody.innerHTML = buildTooltipHtml(n.label, cls, n.uri, n.pageUrl);
    tooltip.style.display = "block";
    positionTooltip(clientX, clientY);
    if (pin) pinnedNodeId = nodeId;
  }

  // Hover: nur anzeigen wenn kein Tooltip gepinnt
  network.on("hoverNode", function (params) {
    if (pinnedNodeId !== null) return;
    var id = params.node;
    if (typeof id === "string") return;
    var ev = params.event;
    var cx = ev.center ? ev.center.x : (ev.clientX || 0);
    var cy = ev.center ? ev.center.y : (ev.clientY || 0);
    showTooltip(id, cx, cy, false);
  });

  // Blur: Tooltip nach kurzem Delay ausblenden (auch gepinnte)
  var _tooltipHideTimer = null;
  network.on("blurNode", function () {
    clearTimeout(_tooltipHideTimer);
    _tooltipHideTimer = setTimeout(function () {
      hideTooltip();
    }, 4000);
  });

  // Maus über Tooltip → Timer stoppen (damit man den Link anklicken kann)
  tooltip.addEventListener("mouseenter", function () {
    clearTimeout(_tooltipHideTimer);
  });
  tooltip.addEventListener("mouseleave", function () {
    _tooltipHideTimer = setTimeout(function () {
      hideTooltip();
    }, 2000);
  });

  // Klick ins Leere → gepinnten Tooltip schließen
  network.on("click", function (params) {
    if (params.nodes.length === 0) {
      hideTooltip();
      return;
    }

    var id = params.nodes[0];

    // Plus-Knoten: mehr laden, kein Tooltip
    if (typeof id === "string" && id.indexOf(PLUS_PREFIX) === 0) {
      expandNode(+id.slice(PLUS_PREFIX.length), false);
      return;
    }

    // Tooltip pinnen
    var ev = params.event;
    var cx = ev.center ? ev.center.x : (ev.clientX || 0);
    var cy = ev.center ? ev.center.y : (ev.clientY || 0);
    showTooltip(id, cx, cy, true);

    // Knoten immer expandieren
    expandNode(id, !exploredIds.has(id));
  });

  // ── Explorations-State ───────────────────────────────────────
  var startNode      = null;
  var exploredIds    = new Set();
  var pinnedIds      = new Set();
  var visibleIds     = new Set();
  var nodeLoadOffset = {};
  var EXPAND_STEP    = 5;
  var _spawnPos      = null;
  var PLUS_PREFIX    = "plus_";

  function getNeighborsSortedByDegree(id) {
    return (EDGE_INDEX[id] || [])
      .map(function (nid) { return NODE_BY_ID[nid]; })
      .filter(function (n) {
        return n && n.classes.some(function (c) { return activeClasses.has(c); });
      })
      .sort(function (a, b) { return b.degree - a.degree; });
  }

  // ── Kern-Render ──────────────────────────────────────────────
  function renderGraph() {
    var ed = ALL_EDGES.filter(function (e) {
      if (!visibleIds.has(e.from) || !visibleIds.has(e.to)) return false;
      var nf = NODE_BY_ID[e.from], nt = NODE_BY_ID[e.to];
      if (!nf || !nt) return false;
      return nf.classes.some(function (c) { return activeClasses.has(c); }) &&
             nt.classes.some(function (c) { return activeClasses.has(c); });
    }).slice(0, maxEdges);

    var connectedIds = new Set();
    ed.forEach(function (e) { connectedIds.add(e.from); connectedIds.add(e.to); });

    var shownNodes = [];
    visibleIds.forEach(function (id) {
      var n = NODE_BY_ID[id];
      if (!n) return;
      if (!n.classes.some(function (c) { return activeClasses.has(c); })) return;
      if (!connectedIds.has(id) && !exploredIds.has(id) && !pinnedIds.has(id)) return;
      shownNodes.push(Object.assign({}, n, {
        label: truncateLabel(n.label),
        color: nodeColor(n),
        value: Math.log1p(n.degree) * 10,
        title: undefined,
        borderWidth: exploredIds.has(id) ? 3 : 1,
      }));
    });

    // "+" Platzhalter-Knoten
    var plusEdges = [];
    exploredIds.forEach(function (id) {
      var neighbors = getNeighborsSortedByDegree(id);
      var loaded    = nodeLoadOffset[id] || 0;
      var remaining = neighbors.length - loaded;
      if (remaining <= 0) return;
      var plusId = PLUS_PREFIX + id;
      shownNodes.push({
        id: plusId, label: "+" + remaining,
        title: undefined,
        shape: "dot", size: 14,
        color: { background: "#f3f0ff", border: "#8B5CF6",
                 highlight: { background: "#ede9fe", border: "#6d28d9" },
                 hover:     { background: "#ede9fe", border: "#6d28d9" } },
        font: { color: "#6d28d9", size: 11, bold: true },
        value: 1, borderWidth: 2, _isPlus: true, _parentId: id,
      });
      plusEdges.push({ from: id, to: plusId,
        color: { color: "#c4b5fd", highlight: "#8B5CF6" },
        dashes: true, width: 1 });
    });

    // Inkrementelles Update (Positionen bleiben erhalten)
    var existingIds = new Set(nodesDS.getIds());
    var toAdd = [], toUpdate = [], toRemove = [];
    var newIdSet = new Set();
    shownNodes.forEach(function (n) { newIdSet.add(n.id); });

    shownNodes.forEach(function (n) {
      if (existingIds.has(n.id)) {
        toUpdate.push(n);
      } else {
        if (_spawnPos) {
          toAdd.push(Object.assign({}, n, { x: _spawnPos.x + (toAdd.length * 60), y: _spawnPos.y }));
        } else {
          toAdd.push(n);
        }
      }
    });
    _spawnPos = null;
    existingIds.forEach(function (id) { if (!newIdSet.has(id)) toRemove.push(id); });

    if (toRemove.length) nodesDS.remove(toRemove);
    if (toUpdate.length) nodesDS.update(toUpdate);
    if (toAdd.length)    nodesDS.add(toAdd);

    edgesDS.clear();
    edgesDS.add(ed.concat(plusEdges));

    if (typeof updateInstanceListGraying === "function") updateInstanceListGraying();
  }

  function expandNode(id, reset, noFocus) {
    if (reset) nodeLoadOffset[id] = 0;
    var offset    = nodeLoadOffset[id] || 0;
    var neighbors = getNeighborsSortedByDegree(id);
    var batch     = neighbors.slice(offset, offset + EXPAND_STEP);

    exploredIds.add(id);
    visibleIds.add(id);
    batch.forEach(function (n) { visibleIds.add(n.id); });
    nodeLoadOffset[id] = offset + batch.length;

    if (noFocus) {
      var realIds = nodesDS.getIds().filter(function (i) {
        return typeof i !== "string" || i.indexOf(PLUS_PREFIX) !== 0;
      });
      var positions = network.getPositions(realIds);
      var keys = Object.keys(positions);
      if (keys.length > 0) {
        var maxX = -Infinity, sumY = 0;
        keys.forEach(function (k) {
          if (positions[k].x > maxX) maxX = positions[k].x;
          sumY += positions[k].y;
        });
        _spawnPos = { x: maxX + 300, y: sumY / keys.length };
      }
    }

    renderGraph();

    if (!noFocus) {
      var focusIds = [id].concat(batch.map(function (n) { return n.id; }));
      setTimeout(function () {
        network.fit({ nodes: focusIds, animation: { duration: 500, easingFunction: "easeInOutQuad" } });
      }, 50);
    }
  }

  function rebuild() {
    Array.from(activeClasses).forEach(function (cls) {
      var hasVisible = Array.from(visibleIds).some(function (id) {
        var n = NODE_BY_ID[id];
        return n && n.classes.indexOf(cls) !== -1;
      });
      if (hasVisible) return;

      var connected = ALL_NODES.filter(function (n) {
        if (n.classes.indexOf(cls) === -1) return false;
        return (EDGE_INDEX[n.id] || []).some(function (nid) { return visibleIds.has(nid); });
      }).sort(function (a, b) { return b.degree - a.degree; });

      var toSeed = connected.length > 0
        ? connected.slice(0, EXPAND_STEP)
        : ALL_NODES.filter(function (n) { return n.classes.indexOf(cls) !== -1; })
                   .sort(function (a, b) { return b.degree - a.degree; })
                   .slice(0, EXPAND_STEP);

      toSeed.forEach(function (n) { visibleIds.add(n.id); pinnedIds.add(n.id); });
    });

    visibleIds.forEach(function (id) {
      var n = NODE_BY_ID[id];
      if (!n) { visibleIds.delete(id); pinnedIds.delete(id); return; }
      if (!n.classes.some(function (c) { return activeClasses.has(c); })) {
        visibleIds.delete(id); pinnedIds.delete(id);
        exploredIds.delete(id); delete nodeLoadOffset[id];
      }
    });

    renderGraph();
  }

  // ── Klassen-Suche ────────────────────────────────────────────
  document.getElementById("class-search").oninput = function () {
    var q = this.value.trim().toLowerCase();
    document.querySelectorAll(".cls-item[data-cls]").forEach(function (el) {
      var short = el.dataset.cls.split(/[#\/]/).pop().toLowerCase();
      el.style.display = (!q || short.includes(q)) ? "" : "none";
    });
    document.querySelectorAll(".ns-header").forEach(function (header) {
      var next = header.nextElementSibling, hasVisible = false;
      while (next && next.classList.contains("cls-item")) {
        if (next.style.display !== "none") hasVisible = true;
        next = next.nextElementSibling;
      }
      header.style.display = hasVisible ? "" : "none";
    });
  };

  // ── Klassen-Filter aufbauen ──────────────────────────────────
  function buildClassFilter() {
    var box = document.getElementById("class-filter");

    var edgeNodeIds = new Set();
    ALL_EDGES.forEach(function (e) { edgeNodeIds.add(e.from); edgeNodeIds.add(e.to); });
    var linkedClasses = new Set();
    ALL_NODES.forEach(function (n) {
      if (edgeNodeIds.has(n.id)) n.classes.forEach(function (c) { linkedClasses.add(c); });
    });

    var groups = {};
    Object.entries(CLASS_STATS).forEach(function (entry) {
      var cls = entry[0], count = entry[1];
      if (!linkedClasses.has(cls)) return;
      var short = cls.split(/[\/\#]/).pop();
      var prefix = "_unknown", bestLen = 0;
      Object.entries(KNOWN_NS).forEach(function (e) {
        var ns = e[0], px = e[1];
        if (cls.startsWith(ns) && ns.length > bestLen) { prefix = px; bestLen = ns.length; }
      });
      if (!groups[prefix]) groups[prefix] = [];
      groups[prefix].push({ cls: cls, count: count, short: short });
    });

    Object.keys(groups).forEach(function (px) {
      groups[px].sort(function (a, b) { return a.short.localeCompare(b.short); });
    });

    var sortedPrefixes = Object.keys(groups).sort(function (a, b) {
      if (a === "_unknown") return 1;
      if (b === "_unknown") return -1;
      return a.localeCompare(b);
    });

    sortedPrefixes.forEach(function (prefix) {
      var header = document.createElement("div");
      header.className = "ns-header";
      header.style.color = NS_COLORS[prefix] || "#94A3B8";
      header.textContent = prefix;
      box.appendChild(header);

      groups[prefix].forEach(function (item) {
        var cls   = item.cls;
        var color = CLASS_COLOR_MAP[cls] || NS_COLORS[prefix] || "#94A3B8";
        var isActive = activeClasses.has(cls);

        var el = document.createElement("div");
        el.className = "cls-item" + (isActive ? "" : " inactive");
        el.title = cls;
        el.dataset.cls = cls;
        el.innerHTML =
          '<div class="cls-check" style="background:' + (isActive ? color : "transparent") +
            ';border:1.5px solid ' + color + '">' + (isActive ? "✓" : "") + '</div>' +
          '<span class="cls-dot" style="background:' + color + '"></span>' +
          '<span class="cls-name">' + item.short + '</span>' +
          '<span class="cls-count">' + item.count.toLocaleString() + '</span>';

        el.onclick = function () {
          var check = el.querySelector(".cls-check");
          if (activeClasses.has(cls)) {
            activeClasses.delete(cls);
            el.classList.add("inactive");
            check.style.background = "transparent"; check.textContent = "";
          } else {
            activeClasses.add(cls);
            el.classList.remove("inactive");
            check.style.background = color; check.textContent = "✓";
          }
          if (!instModeActive) rebuild();
        };
        box.appendChild(el);
      });
    });
  }

  function syncClassCheckboxes() {
    document.querySelectorAll(".cls-item[data-cls]").forEach(function (el) {
      var cls   = el.dataset.cls;
      var check = el.querySelector(".cls-check");
      var color = check ? check.style.borderColor : "";
      var active = activeClasses.has(cls);
      el.classList.toggle("inactive", !active);
      if (check) { check.style.background = active ? color : "transparent"; check.textContent = active ? "✓" : ""; }
    });
  }

  document.getElementById("btn-default").onclick = function () {
    activeClasses = new Set(Object.keys(CLASS_STATS).filter(function (c) {
      return !HIDDEN_BY_DEFAULT.has(c);
    }));
    syncClassCheckboxes();
    maxEdges = DEFAULT_MAX_EDGES;
    instModeActive = false;
    exploredIds = new Set(); pinnedIds = new Set(); visibleIds = new Set();
    hideTooltip();
    if (startNode) expandNode(startNode.id);
    else renderGraph();
  };

  document.getElementById("btn-all").onclick = function () {
    Object.keys(CLASS_STATS).forEach(function (c) { activeClasses.add(c); });
    syncClassCheckboxes();
    instModeActive = false;
    rebuild();
  };

  document.getElementById("btn-none").onclick = function () {
    activeClasses.clear();
    syncClassCheckboxes();
    instModeActive = false;
    exploredIds.clear();
    pinnedIds.clear();
    visibleIds.clear();
    checkedNodeIds.clear();
    nodeLoadOffset = {};
    hideTooltip();
    if (_physicsTimer) clearTimeout(_physicsTimer);
    network.setOptions({ physics: { enabled: false } });
    edgesDS.clear();
    nodesDS.clear();
    setTimeout(function () {
      var canvas = document.querySelector("#graph canvas");
      if (canvas) {
        var ctx = canvas.getContext("2d");
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      }
    }, 50);
  };

  // ── Rechte Sidebar ───────────────────────────────────────────
  var INSTANCE_CLASSES = {
    "INT2":  "https://w3id.org/lso/intro/currentbeta#INT2_ActualizationOfFeature",
    "INT21": "https://w3id.org/lso/intro/currentbeta#INT21_TextPassage",
    "F2":    "http://iflastandards.info/ns/lrm/lrmoo/F2_Expression",
  };
  var activeTab      = "F2";
  var checkedNodeIds = new Set();

  // ── Vorberechneter, vorsortierter Cache pro Tab ───────
  var INSTANCE_CACHE = {};

  function buildInstanceCache(tabKey) {
    if (INSTANCE_CACHE[tabKey]) return INSTANCE_CACHE[tabKey];

    var nodes;
    if (tabKey === "ALL") {
      nodes = ALL_NODES.filter(function (n) { return n.classes.length > 0; });
    } else {
      var cls = INSTANCE_CLASSES[tabKey];
      nodes = ALL_NODES.filter(function (n) { return n.classes.indexOf(cls) !== -1; });
    }

    nodes.sort(function (a, b) { return a.label.localeCompare(b.label); });

    // Lowercase-Felder vorberechnen – einmalig
    nodes.forEach(function (n) {
      n._labelLower = n.label.toLowerCase();
      n._uriLower   = n.uri   ? n.uri.toLowerCase()   : "";
      n._clsLower   = n.classes.length > 0
        ? n.classes[0].split(/[#\/]/).pop().toLowerCase()
        : "";
    });

    INSTANCE_CACHE[tabKey] = nodes;
    return nodes;
  }

  // ── Binäre Suche für Prefix-Matching ─────────────────
  function binarySearchPrefix(nodes, prefix) {
    var lo = 0, hi = nodes.length;
    // Untergrenze: erstes Element >= prefix
    while (lo < hi) {
      var mid = (lo + hi) >>> 1;
      nodes[mid]._labelLower < prefix ? (lo = mid + 1) : (hi = mid);
    }
    var start = lo;
    // Obergrenze: erstes Element, das nicht mehr mit prefix beginnt
    hi = nodes.length;
    while (lo < hi) {
      var mid2 = (lo + hi) >>> 1;
      nodes[mid2]._labelLower.startsWith(prefix) ? (lo = mid2 + 1) : (hi = mid2);
    }
    return nodes.slice(start, lo);
  }

  // ── Kombinierte Suche mit Prefix-Optimierung ─────────
  function searchInstanceNodes(tabKey, q) {
    var all = buildInstanceCache(tabKey);

    if (!q) {
      // Checked nodes nach oben sortieren, Rest bleibt wie er ist
      if (checkedNodeIds.size === 0) return all;
      var checked   = all.filter(function (n) { return checkedNodeIds.has(n.id); });
      var unchecked = all.filter(function (n) { return !checkedNodeIds.has(n.id); });
      return checked.concat(unchecked);
    }

    var results;

    if (/^[a-z0-9äöüß\s\-_]+$/i.test(q)) {
      // Schritt 1: schnelle Prefix-Suche via binärer Suche
      var prefixMatches = binarySearchPrefix(all, q);

      // Schritt 2: zusätzlich Substring-Treffer (die nicht schon Prefix-Treffer sind)
      // Nur durchsuchen wenn Prefix-Ergebnis nicht bereits groß genug
      var prefixSet = new Set(prefixMatches.map(function (n) { return n.id; }));
      var substringMatches = all.filter(function (n) {
        if (prefixSet.has(n.id)) return false;
        return n._labelLower.includes(q)
          || n._uriLower.includes(q)
          || n._clsLower.includes(q);
      });

      results = prefixMatches.concat(substringMatches);
    } else {
      // Fallback: reine Substring-Suche (z.B. bei URI-Fragmenten mit Sonderzeichen)
      results = all.filter(function (n) {
        return n._labelLower.includes(q)
          || n._uriLower.includes(q)
          || n._clsLower.includes(q);
      });
    }

    // Checked nodes immer oben anzeigen, auch wenn sie zum Suchbegriff passen
    if (checkedNodeIds.size > 0) {
      var checkedResults   = results.filter(function (n) { return checkedNodeIds.has(n.id); });
      var uncheckedResults = results.filter(function (n) { return !checkedNodeIds.has(n.id); });
      results = checkedResults.concat(uncheckedResults);
    }

    return results;
  }

  // ── Instanzliste: graying via data-Attribut ──────────────────
  function updateInstanceListGraying() {
    _vScroll.renderedIds = new Set(nodesDS.getIds());
    _vScrollPaint();
  }

  function collapseNode(id) {
    checkedNodeIds.delete(id); exploredIds.delete(id);
    pinnedIds.delete(id); delete nodeLoadOffset[id];
    visibleIds = new Set();
    exploredIds.forEach(function (eid) {
      visibleIds.add(eid);
      getNeighborsSortedByDegree(eid).slice(0, nodeLoadOffset[eid] || EXPAND_STEP)
        .forEach(function (nb) { visibleIds.add(nb.id); });
    });
    pinnedIds.forEach(function (pid) { visibleIds.add(pid); });
    if (pinnedNodeId === id) hideTooltip();
    if (visibleIds.size === 0 && startNode) { expandNode(startNode.id, true); return; }
    renderGraph();
  }

  // ── Instanzliste: Virtual Scrolling ─────────────────────────
  var _vScroll = {
    nodes:       [],
    showClass:   false,
    itemH:       26,
    overscan:    5,
    scrollEl:    null,
    renderedIds: null,
  };

  // Scroll-Container einmalig ermitteln und cachen
  function _vScrollGetScrollParent() {
    if (_vScroll.scrollEl) return _vScroll.scrollEl;
    var el = document.getElementById("instance-list").parentElement;
    while (el) {
      var overflow = getComputedStyle(el).overflowY;
      if (overflow === "auto" || overflow === "scroll") { _vScroll.scrollEl = el; return el; }
      el = el.parentElement;
    }
    _vScroll.scrollEl = document.getElementById("instance-list").parentElement;
    return _vScroll.scrollEl;
  }

  function _vScrollPaint() {
    var list      = document.getElementById("instance-list");
    var scrollEl  = _vScrollGetScrollParent();
    var nodes     = _vScroll.nodes;
    var itemH     = _vScroll.itemH;
    var total     = nodes.length;
    var viewH     = scrollEl.clientHeight;
    var scrollTop = scrollEl.scrollTop;
    var overscan  = _vScroll.overscan;

    var startIdx = Math.max(0, Math.floor(scrollTop / itemH) - overscan);
    var endIdx   = Math.min(total, Math.ceil((scrollTop + viewH) / itemH) + overscan);

    var renderedIds = _vScroll.renderedIds || new Set(nodesDS.getIds());
    var showClass   = _vScroll.showClass;

    var parts = ['<div style="height:' + (startIdx * itemH) + 'px"></div>'];

    for (var i = startIdx; i < endIdx; i++) {
      var n          = nodes[i];
      var isChecked  = checkedNodeIds.has(n.id);
      var isInactive = !renderedIds.has(n.id) && !isChecked;
      var clsShort   = n._clsLower
        ? n.classes[0].split(/[#\/]/).pop()
        : (n.classes.length > 0 ? n.classes[0].split(/[#\/]/).pop() : "");
      var labelText  = showClass && clsShort ? n.label + " (" + clsShort + ")" : n.label;
      var title      = n.label + (clsShort ? " (" + clsShort + ")" : "");

      parts.push(
        '<div class="inst-item' +
          (isChecked  ? " checked"  : "") +
          (isInactive ? " inactive" : "") +
          '" data-nid="' + n.id + '" title="' + escHtml(title) + '">' +
        '<div class="inst-check">' + (isChecked ? "✓" : "") + '</div>' +
        '<span class="inst-label">' + escHtml(labelText) + '</span>' +
        '</div>'
      );
    }

    parts.push('<div style="height:' + ((total - endIdx) * itemH) + 'px"></div>');
    list.innerHTML = parts.join("");
  }

  // onscroll nur einmal setzen (nicht bei jedem renderInstanceList-Aufruf)
  (function initScroll() {
    var scrollEl = _vScrollGetScrollParent();
    scrollEl.addEventListener("scroll", _vScrollPaint, { passive: true });
  })();

  function renderInstanceList(q) {
    var nodes = searchInstanceNodes(activeTab, q);

    _vScroll.nodes       = nodes;
    _vScroll.showClass   = (activeTab === "ALL");
    _vScroll.renderedIds = new Set(nodesDS.getIds());

    var scrollEl = _vScrollGetScrollParent();
    scrollEl.scrollTop = 0;

    var list = document.getElementById("instance-list");
    list.style.position = "relative";
    // Gesamthöhe explizit setzen, damit der Scrollcontainer die richtige Höhe hat
    list.style.height = (nodes.length * _vScroll.itemH) + "px";

    _vScrollPaint();

    // Event-Delegation nur einmal registrieren
    if (!list._clickInitialized) {
      list._clickInitialized = true;
      list.addEventListener("click", function (e) {
        var el = e.target.closest(".inst-item[data-nid]");
        if (!el) return;
        var id    = +el.dataset.nid;
        var n     = NODE_BY_ID[id];
        if (!n) return;
        var check = el.querySelector(".inst-check");
        if (checkedNodeIds.has(id)) {
          el.classList.remove("checked"); check.textContent = "";
          collapseNode(id);
        } else {
          checkedNodeIds.add(id); el.classList.add("checked"); check.textContent = "✓";
          expandNode(id, true, true);
        }
        _vScroll.renderedIds = new Set(nodesDS.getIds());
        _vScrollPaint();
      });
    }
  }

  // ── Debounce für Instanz-Suche ───────────────────────
  var _instSearchTimer = null;
  document.getElementById("instance-search").oninput = function () {
    var q = this.value.trim().toLowerCase();

    // Sofortiges visuelles Feedback: Suchfeld leicht abdunkeln
    this.style.opacity = "0.6";
    var inputEl = this;

    clearTimeout(_instSearchTimer);
    _instSearchTimer = setTimeout(function () {
      inputEl.style.opacity = "1";
      renderInstanceList(q);
    }, 200);
  };

  document.querySelectorAll(".inst-tab").forEach(function (tab) {
    tab.onclick = function () {
      document.querySelectorAll(".inst-tab").forEach(function (t) { t.classList.remove("active"); });
      tab.classList.add("active");
      activeTab = tab.dataset.cls;
      document.getElementById("instance-search").value = "";
      // Cache für neuen Tab vorwärmen (läuft einmalig beim Tab-Wechsel)
      buildInstanceCache(activeTab);
      renderInstanceList("");
    };
  });

  document.getElementById("btn-inst-default").onclick = function () {
    instModeActive = false; checkedNodeIds.clear();
    exploredIds = new Set(); pinnedIds = new Set();
    visibleIds = new Set(); nodeLoadOffset = {};
    hideTooltip();
    if (startNode) expandNode(startNode.id, true);
    else renderGraph();
    renderInstanceList(document.getElementById("instance-search").value.trim().toLowerCase());
  };

  document.getElementById("btn-inst-none").onclick = function () {
    document.querySelectorAll(".inst-item.checked").forEach(function (el) {
      el.classList.remove("checked");
      var check = el.querySelector(".inst-check");
      if (check) check.textContent = "";
    });
    checkedNodeIds.clear();
    exploredIds.clear();
    pinnedIds.clear();
    visibleIds.clear();
    nodeLoadOffset = {};
    hideTooltip();
    edgesDS.clear();
    nodesDS.clear();
    updateInstanceListGraying();
  };

  // ── Hinweis-Overlay ──────────────────────────────────────────
  var hint = document.getElementById("graph-hint");
  if (hint) {
    hint.onclick = function () {
      hint.style.transition = "opacity .3s";
      hint.style.opacity = "0";
      setTimeout(function () { hint.style.display = "none"; }, 300);
    };
    setTimeout(function () {
      hint.style.transition = "opacity 2s";
      hint.style.opacity = "0";
      setTimeout(function () { hint.style.display = "none"; }, 2000);
    }, 20000);
  }

  // ── Start ────────────────────────────────────────────────────
  buildClassFilter();

  // Instanz-Caches für alle Tabs vorwärmen (im Hintergrund, nach dem ersten Paint)
  setTimeout(function () {
    Object.keys(INSTANCE_CLASSES).forEach(function (key) { buildInstanceCache(key); });
    buildInstanceCache("ALL");
  }, 500);

  startNode = ALL_NODES.filter(function (n) { return n.uri === START_URI; })[0] || null;
  if (!startNode) {
    startNode = ALL_NODES.filter(function (n) {
      return n.label && n.label.toLowerCase().includes("plejaden");
    })[0] || null;
  }
  if (startNode) {
    expandNode(startNode.id);
    setTimeout(function () {
      network.fit({ nodes: [startNode.id], animation: { duration: 800, easingFunction: "easeInOutQuad" } });
    }, 400);
  } else {
    renderGraph();
  }

  renderInstanceList("");

  // ── Doppelklick → zuklappen ──────────────────────────────────
  network.on("doubleClick", function (params) {
    if (params.nodes.length === 0) return;
    var id = params.nodes[0];
    if (typeof id === "string") return;

    exploredIds.delete(id); delete nodeLoadOffset[id];
    if (pinnedNodeId === id) hideTooltip();
    visibleIds = new Set();
    exploredIds.forEach(function (eid) {
      visibleIds.add(eid);
      getNeighborsSortedByDegree(eid).slice(0, nodeLoadOffset[eid] || EXPAND_STEP)
        .forEach(function (n) { visibleIds.add(n.id); });
    });
    renderGraph();
  });

  // ── PNG-Export ───────────────────────────────────────────────
  document.getElementById("btn-exp-png").onclick = function () {
    var canvas = document.querySelector("#graph canvas");
    if (!canvas) { alert("Kein Canvas gefunden."); return; }
    var out = document.createElement("canvas");
    out.width = canvas.width; out.height = canvas.height;
    var ctx = out.getContext("2d");
    ctx.fillStyle = "#ffffff";
    ctx.fillRect(0, 0, out.width, out.height);
    ctx.drawImage(canvas, 0, 0);
    out.toBlob(function (blob) {
      var a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = "graph.png";
      a.click();
      URL.revokeObjectURL(a.href);
    }, "image/png");
  };

})();

});