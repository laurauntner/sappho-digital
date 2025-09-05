document.addEventListener('DOMContentLoaded', () => {
  const elements = document.querySelectorAll('[data-wikidata][data-type]');

  elements.forEach(el => {
    const id = el.dataset.wikidata;
    const type = el.dataset.type;

    if (!id) return;

    fetch(`https://www.wikidata.org/wiki/Special:EntityData/${id}.json`)
      .then(res => res.json())
      .then(data => {
        const entity = data.entities[id];

        if (!entity) return;

        if (type === 'map') {
          const coord = entity.claims?.P625?.[0]?.mainsnak?.datavalue?.value;
          if (coord) {
            const lat = coord.latitude;
            const lon = coord.longitude;
            const iframe = document.createElement('iframe');
            iframe.className = 'wikidata-map';
            iframe.src = `https://www.openstreetmap.org/export/embed.html?bbox=${lon - 0.01},${lat - 0.01},${lon + 0.01},${lat + 0.01}&layer=mapnik&marker=${lat},${lon}`;
            iframe.loading = "lazy";
            el.appendChild(iframe);
          }
        }
      });
  });
});