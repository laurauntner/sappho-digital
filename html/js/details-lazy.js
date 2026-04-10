document.addEventListener('toggle', (ev) => {
    const details = ev.target;
    if (details.tagName !== 'DETAILS' || !details.open) return;
    if (details.dataset.lazyDone) return;

    details.querySelectorAll(':scope > template[data-lazy]').forEach((tpl) => {
        details.insertBefore(tpl.content, tpl);
        tpl.remove();
    });

    details.dataset.lazyDone = '1';
}, true);
