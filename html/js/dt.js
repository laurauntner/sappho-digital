function hideSearchInputs(containerElement, columns) {
    for (let i = 0; i < columns.length; i++) {
        if (columns[i]) {
            $(`#${containerElement} .filters th`).eq(i).show();
        } else {
            $(`#${containerElement} .filters th`).eq(i).hide();
        }
    }
}

function createDataTable(containerElement, order, pageLength) {
    order = order || [];
    pageLength = pageLength || 50;
    
    const showGenres = document.body.getAttribute("data-show-genres") === "true";

    // Definiere sortierbare Spalten je nach Tabellenstruktur
    const columnDefs = showGenres ? [
        { type: 'num', targets: 0 },           // Entstehungsjahr
        { type: 'num', targets: 1 },           // Publikationsjahr
        { type: 'string', targets: 2 },        // Titel
        { type: 'string', targets: 3 },        // Enthalten in
        { type: 'string', targets: 4 },        // Autor_in
        { type: 'string', targets: 5 },        // Gattung
        { type: 'string', targets: 6 },        // Publikationsort
        { type: 'string', targets: 7 },        // Verlag
        { orderable: false, targets: 8 }       // Digitalisat
    ] : [
        { type: 'num', targets: 0 },
        { type: 'num', targets: 1 },
        { type: 'string', targets: 2 },
        { type: 'string', targets: 3 },
        { type: 'string', targets: 4 },
        { type: 'string', targets: 5 },
        { type: 'string', targets: 6 },
        { orderable: false, targets: 7 }
    ];

    $(`#${containerElement} thead tr`).clone(true).addClass('filters').appendTo(`#${containerElement} thead`);

    const table = $(`#${containerElement}`).DataTable({
        autoWidth: false,
        columnDefs: columnDefs,
        dom: "'<'row controlwrapper'<'col-sm-4'f><'col-sm-4'i><'col-sm-4 exportbuttons'Br>>'" +
             "'<'row'<'col-sm-12't>>'" +
             "'<'row'<'col-sm-6 offset-sm-6'p>>'",
        responsive: true,
        pageLength: pageLength,
        buttons: [
            {
                extend: 'copyHtml5',
                text: '<i class="far fa-copy"/>',
                titleAttr: 'Tabelle kopieren',
                className: 'btn-link',
                exportOptions: {
                    columns: function (idx, data, node) {
                        return true;
                    },
                    format: {
                        body: function (data, row, column, node) {
                            const $link = $('a', node);
                            if ($link.length && $link.attr('href')) {
                                return $link.attr('href');
                            }
                            return $(node).clone().find('img, svg').remove().end().text().trim();
                        }
                    }
                },
                init: function (api, node) {
                    $(node).removeClass('btn-secondary');
                }
            },
            {
                extend: 'excelHtml5',
                text: '<i class="far fa-file-excel"/>',
                titleAttr: 'Excel-Tabelle herunterladen',
                className: 'btn-link',
                exportOptions: {
                    columns: function (idx, data, node) {
                        return true;
                    },
                    format: {
                        body: function (data, row, column, node) {
                            const $link = $('a', node);
                            if ($link.length && $link.attr('href')) {
                                return $link.attr('href');
                            }
                            return $(node).clone().find('img, svg').remove().end().text().trim();
                        }
                    }
                },
                init: function (api, node) {
                    $(node).removeClass('btn-secondary');
                }
            },
            {
                extend: 'pdfHtml5',
                text: '<i class="far fa-file-pdf"/>',
                titleAttr: 'PDF',
                className: 'btn-link',
                exportOptions: {
                    columns: function (idx, data, node) {
                        return true;
                    },
                    format: {
                        body: function (data, row, column, node) {
                            const $link = $('a', node);
                            if ($link.length && $link.attr('href')) {
                                return $link.attr('href');
                            }
                            return $(node).clone().find('img, svg').remove().end().text().trim();
                        }
                    }
                },
                init: function (api, node) {
                    $(node).removeClass('btn-secondary');
                }
            }
        ],
        order: order,
        orderCellsTop: true,
        fixedHeader: true,
        language: {
            "sEmptyTable": "Keine Daten verfügbar",
            "sInfo": "_START_ bis _END_ von _TOTAL_ Einträgen",
            "sInfoEmpty": "Keine Einträge",
            "sInfoFiltered": "(gefiltert von _MAX_ Einträgen)",
            "sLengthMenu": "_MENU_ Einträge anzeigen",
            "sLoadingRecords": "Wird geladen...",
            "sProcessing": "Verarbeiten...",
            "sSearch": "Suchen:",
            "sZeroRecords": "Keine Einträge gefunden",
            "oPaginate": {
                "sFirst": "Erste",
                "sLast": "Letzte",
                "sNext": "Nächste",
                "sPrevious": "Vorherige"
            }
        },
        initComplete: function () {
            const api = this.api();

            api.columns().eq(0).each(function (colIdx) {
                const cell = $(`#${containerElement} .filters th`).eq($(api.column(colIdx).header()).index());
                $(cell).html('<input type="text"/>');

                $('input', cell).off('keyup change').on('keyup change', function (e) {
                    e.stopPropagation();
                    $(this).attr('title', $(this).val());
                    const regexr = '({search})';
                    const cursorPosition = this.selectionStart;

                    api.column(colIdx).search(
                        this.value !== '' ? regexr.replace('{search}', '(((' + this.value + ')))') : '',
                        this.value !== '',
                        this.value === ''
                    ).draw();

                    $(this).focus()[0].setSelectionRange(cursorPosition, cursorPosition);
                });
            });

            hideSearchInputs(containerElement, api.columns().responsiveHidden().toArray());
        }
    });

    table.responsive.recalc();

    table.on('draw.dt', function () {
        $('.paginate_button.current').removeClass('current');
    });

    table.on('responsive-resize', function (e, datatable, columns) {
        hideSearchInputs(containerElement, columns);
    });
}