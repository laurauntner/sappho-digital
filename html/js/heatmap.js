(function () {
  "use strict";

  var rawData = window.heatmapData;
  if (!rawData || !rawData.length) {
    var section = document.getElementById("heatmap-section");
    if (section) section.style.display = "none";
    return;
  }

  /* year range */
  var years   = rawData.map(function (d) { return d.year; });
  var minYear = Math.min.apply(null, years);
  var maxYear = Math.max.apply(null, years);

  /* centered on DACH region */
  var map = L.map("map").setView([50, 10], 4.4);

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution:
      '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 18,
  }).addTo(map);

  var heatLayer = L.heatLayer([], {
    radius:     18,
    blur:       10,
    minOpacity: 0.5,
    maxZoom:    12,
    gradient: {
      0.2: "#ffffcc",
      0.5: "#fd8d3c",
      0.8: "#e31a1c",
      1.0: "#800026",
    },
  }).addTo(map);

  var slider  = document.getElementById("year-slider");
  var display = document.getElementById("slider-display");
  var countEl = document.getElementById("heatmap-count");
  var playBtn = document.getElementById("btn-play");

  slider.min   = minYear;
  slider.max   = maxYear;
  slider.value = minYear;

  /* cumulative: all publications UP TO year */
  function update(year) {
    display.textContent = "bis " + year;

    var filtered = rawData.filter(function (d) { return d.year <= year; });
    var points   = filtered.map(function (d) { return [d.lat, d.lng, 1]; });

    heatLayer.setLatLngs(points);

}

  update(minYear);

  slider.addEventListener("input", function () {
    update(+this.value);
  });

  /* play / stop */
  var playTimer = null;
  var STEP_MS   = 30; // milliseconds per year step

  function stopPlay() {
    clearInterval(playTimer);
    playTimer = null;
    playBtn.textContent = "▶ Abspielen";
  }

  function startPlay() {
    if (+slider.value >= maxYear) {
      slider.value = minYear;
      update(minYear);
    }
    playBtn.textContent = "⏹ Stop";
    playTimer = setInterval(function () {
      var next = +slider.value + 1;
      slider.value = next;
      update(next);
      if (next >= maxYear) { stopPlay(); }
    }, STEP_MS);
  }

  playBtn.addEventListener("click", function () {
    if (playTimer) { stopPlay(); } else { startPlay(); }
  });

  /* autoplay on load */
  startPlay();
})();