(function () {
  function readJsonScript(id) {
    const el = document.getElementById(id);
    if (!el) throw new Error(`Missing <script id="${id}" type="application/json">…</script>`);
    return JSON.parse(el.textContent);
  }

  function init() {
    const container = document.getElementById("graph");
    if (!container) return;

    const nodesData = readJsonScript("graph-nodes");
    const edgesData = readJsonScript("graph-edges");

    // min/max Degree bestimmen (value = degree)
    let minV = Infinity;
    let maxV = -Infinity;
    for (const n of nodesData) {
      const v = typeof n.value === "number" ? n.value : Number(n.value);
      if (!Number.isFinite(v)) continue;
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    if (!Number.isFinite(minV)) minV = 0;
    if (!Number.isFinite(maxV)) maxV = 0;

    const nodes = new vis.DataSet(nodesData);
    const edges = new vis.DataSet(edgesData);

    const data = { nodes, edges };

    const options = {
      physics: {
          enabled: true,
          solver: "forceAtlas2Based",
          stabilization: { iterations: 200 },
          forceAtlas2Based: {
            gravitationalConstant: -50,
            centralGravity: 0.01,
            springLength: 120,
            springConstant: 0.08,
            avoidOverlap: 1
          }
        },
      nodes: {
        shape: "dot",

        // Scaling über degree
        scaling: {
          min: 10,
          max: 60,

          customScalingFunction: function (min, max, total, value) {
            if (maxV === minV) return 0.5;
            return (value - minV) / (maxV - minV);
          }
        }
      },
      edges: {
        arrows: { to: { enabled: true } },
        smooth: { type: "dynamic" }
      },
      interaction: {
        hover: true,
        navigationButtons: true,
        keyboard: true
      }
    };

    new vis.Network(container, data, options);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
