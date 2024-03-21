/* http://live.datatables.net/nugeyewe/7/edit */
 /* script provided by https://github.com/babslgam */

function hideSearchInputs(containerElement, columns) {
    for (i = 0; i < columns.length; i++) {
        if (columns[i]) {
            $(`#${containerElement} .filters th`).eq(i).show();
        } else {
            $(`#${containerElement} .filters th`).eq(i).hide();
        }
    }
}

function createDataTable(containerElement, order, pageLength) {
    $(`#${containerElement} thead tr`).clone(true).addClass('filters').appendTo(`#${containerElement} thead`);
    
    var table = $(`#${containerElement}`).DataTable({
        columnDefs:[ {
            orderable: false, targets: '_all'
        }, {
            type: 'num', targets: 0
        }
        // sort according to bibl/@n
        ],
        dom: "'<'row controlwrapper'<'col-sm-4'f><'col-sm-4'i><'col-sm-4 exportbuttons'Br>>'" +
        "'<'row'<'col-sm-12't>>'" +
        "'<'row'<'col-sm-6 offset-sm-6'p>>'",
        responsive: true,
        pageLength: 50,
        buttons:[ {
            extend: 'copyHtml5',
            text: '<i class="far fa-copy"/>',
            titleAttr: 'Copy',
            className: 'btn-link',
            init: function (api, node, config) {
                $(node).removeClass('btn-secondary');
            }
        }, {
            extend: 'excelHtml5',
            text: '<i class="far fa-file-excel"/>',
            titleAttr: 'Excel',
            className: 'btn-link',
            init: function (api, node, config) {
                $(node).removeClass('btn-secondary');
            }
        }, {
            extend: 'pdfHtml5',
            text: '<i class="far fa-file-pdf"/>',
            titleAttr: 'PDF',
            className: 'btn-link',
            init: function (api, node, config) {
                $(node).removeClass('btn-secondary');
            }
        }],
        order: order,
        orderCellsTop: true,
        fixedHeader: true,
        language: {
            "sEmptyTable": "Keine Daten verfügbar",
            "sInfo": "_START_ bis _END_ von _TOTAL_ Einträgen",
            "sInfoEmpty": "Keine Einträge",
            "sInfoFiltered": "(gefiltert von _MAX_ Einträgen)",
            "sInfoPostFix": "",
            "sInfoThousands": ".",
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
            /*,
             "oAria": {
             "sSortAscending": ": aktivieren, um Spalte aufsteigend zu sortieren",
             "sSortDescending": ": aktivieren, um Spalte absteigend zu sortieren"
             }*/
        },
        initComplete: function () {
            var api = this.api();
            
            api.columns().eq(0).each(function (colIdx) {
                var cell = $(`#${containerElement} .filters th`).eq($(api.column(colIdx).header()).index());
                $(cell).html('<input type="text"/>');
                
                $('input', $(`#${containerElement} .filters th`).eq($(api.column(colIdx).header()).index())).off('keyup change').on('keyup change', function (e) {
                    e.stopPropagation();
                    $(this).attr('title', $(this).val());
                    var regexr = '({search})';
                    var cursorPosition = this.selectionStart;
                    
                    api.column(colIdx).search(this.value != '' ? regexr.replace('{search}', '(((' + this.value + ')))'): '', this.value != '', this.value == '').draw();
                    
                    $(this).focus()[0].setSelectionRange(cursorPosition, cursorPosition);
                });
            });
            hideSearchInputs(containerElement, api.columns().responsiveHidden().toArray());
        }
    });
    
    $(`#${containerElement} thead th:first-child`).removeClass('sorting sorting_asc sorting_desc');
    
    table.responsive.recalc();
    
    table.on('draw.dt', function () {
        $('.paginate_button.current').removeClass('current');
    });
    
    table.on('responsive-resize', function (e, datatable, columns) {
        hideSearchInputs(containerElement, columns);
    });
}