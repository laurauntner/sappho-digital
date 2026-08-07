document.addEventListener('DOMContentLoaded', function () {
    if (typeof PagefindUI === 'undefined') {
        return;
    }

    new PagefindUI({
        element: '#search',
        showSubResults: true,
        showImages: false,
        resetStyles: false,
        translations: {
            placeholder: 'Suchbegriff eingeben …',
            zero_results: 'Keine Ergebnisse für [SEARCH_TERM]',
            many_results: '[COUNT] Ergebnisse für [SEARCH_TERM]',
            one_result: '[COUNT] Ergebnis für [SEARCH_TERM]',
            alt_search: '[COUNT] Ergebnisse für [DIFFERENCE] statt [SEARCH_TERM]',
            searching: 'Suche nach [SEARCH_TERM] …'
        }
    });

    var searchModal = document.getElementById('searchModal');
    if (searchModal) {
        searchModal.addEventListener('shown.bs.modal', function () {
            var input = searchModal.querySelector('input[type="text"]');
            if (input) {
                input.focus();
            }
        });
    }

    document.addEventListener('keydown', function (event) {
        var isShortcut = (event.key === 'k' || event.key === 'K') && (event.metaKey || event.ctrlKey);
        if (!isShortcut) {
            return;
        }
        event.preventDefault();
        if (searchModal && window.bootstrap) {
            bootstrap.Modal.getOrCreateInstance(searchModal).show();
        }
    });
});
