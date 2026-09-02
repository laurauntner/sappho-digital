document.addEventListener('DOMContentLoaded', function () {
    if (typeof PagefindUI === 'undefined') {
        return;
    }

    var searchLang = document.documentElement.lang === 'en' ? 'en' : 'de';

    new PagefindUI({
        element: '#search',
        showSubResults: true,
        showImages: false,
        resetStyles: false,
        translations: searchLang === 'en' ? {
            placeholder: 'Enter search term …',
            zero_results: 'No results for [SEARCH_TERM]',
            many_results: '[COUNT] results for [SEARCH_TERM]',
            one_result: '[COUNT] result for [SEARCH_TERM]',
            alt_search: '[COUNT] results for [DIFFERENCE] instead of [SEARCH_TERM]',
            searching: 'Searching for [SEARCH_TERM] …'
        } : {
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
