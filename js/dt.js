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

  const columnDefs = showGenres
    ? [
        { type: "num", targets: 0 },
        { type: "num", targets: 1 },
        { type: "string", targets: 2 },
        { type: "string", targets: 3 },
        { type: "string", targets: 4 },
        { type: "string", targets: 5 },
        { type: "string", targets: 6 },
        { type: "string", targets: 7 },
        { orderable: "string", targets: 8 },
        { type: "string", targets: 9 },
        { type: "string", targets: 10 },
        { type: "string", targets: 11 },
        { type: "string", targets: 12 },
        { type: "string", targets: 13 }
      ]
    : [
        { type: "num", targets: 0 },
        { type: "num", targets: 1 },
        { type: "string", targets: 2 },
        { type: "string", targets: 3 },
        { type: "string", targets: 4 },
        { type: "string", targets: 5 },
        { type: "string", targets: 6 },
        { orderable: "string", targets: 7 },
        { type: "string", targets: 8 },
        { type: "string", targets: 9 },
        { type: "string", targets: 10 },
        { type: "string", targets: 11 }
      ];

  $(`#${containerElement} thead tr`)
    .clone(true)
    .addClass("filters")
    .appendTo(`#${containerElement} thead`);

  const table = $(`#${containerElement}`).DataTable({
    autoWidth: false,
    columnDefs: columnDefs,
    dom:
      "'<'row controlwrapper'<'col-sm-4'f><'col-sm-4'i><'col-sm-4 exportbuttons'B>>'" +
      "'<'row'<'col-sm-12't>>'" +
      "'<'row'<'col-sm-6 offset-sm-6'p>>'",
    responsive: true,
    pageLength: pageLength,
    buttons: [
      {
        extend: "copyHtml5",
        text: '<i class="far fa-copy"></i>',
        titleAttr: "Tabelle kopieren",
        className: "btn-link",
        exportOptions: {
          columns: function (idx, data, node) {
              return idx !== 13;
            },
          format: {
            body: function (data, row, column, node) {
              const $cell = $(node).clone();
              $cell.find("a, img, svg").remove();
            return $cell
              .text()
              .replace(/[\r\n\t]+/g, " ")
              .replace(/\s+/g, " ")
              .trim();
            }
          }
        },
        init: function (api, node) {
          $(node).removeClass("btn-secondary");
        }
      },
      {
        extend: "excelHtml5",
        text: '<i class="far fa-file-excel"></i>',
        titleAttr: "Excel-Tabelle herunterladen",
        className: "btn-link",
        exportOptions: {
          columns: function (idx, data, node) {
              return idx !== 13;
            },
          format: {
            body: function (data, row, column, node) {
              const $cell = $(node).clone();
              $cell.find("a, img, svg").remove();
                return $cell
                  .text()
                  .replace(/[\r\n\t]+/g, " ")
                  .replace(/\s+/g, " ")
                  .trim();
            }
          }
        },
        init: function (api, node) {
          $(node).removeClass("btn-secondary");
        }
      }
    ],
    order: order,
    orderCellsTop: true,
    fixedHeader: true,
    language: {
      sEmptyTable: "Keine Daten verfügbar",
      sInfo: "_START_ bis _END_ von _TOTAL_ Einträgen",
      sInfoEmpty: "Keine Einträge",
      sInfoFiltered: "(gefiltert von _MAX_ Einträgen)",
      sLengthMenu: "_MENU_ Einträge anzeigen",
      sLoadingRecords: "Wird geladen...",
      sProcessing: "Verarbeiten...",
      sSearch: "Suchen:",
      sZeroRecords: "Keine Einträge gefunden",
      oPaginate: {
        sFirst: "Erste",
        sLast: "Letzte",
        sNext: "Nächste",
        sPrevious: "Vorherige"
      }
    },
    initComplete: function () {
      const api = this.api();

      api.columns().eq(0).each(function (colIdx) {
        const cell = $(`#${containerElement} .filters th`).eq(
          $(api.column(colIdx).header()).index()
        );
        $(cell).html('<input type="text"/>');

        $("input", cell)
          .off("keyup change")
          .on("keyup change", function (e) {
            e.stopPropagation();
            $(this).attr("title", $(this).val());
            const regexr = "({search})";
            const cursorPosition = this.selectionStart;

            api
              .column(colIdx)
              .search(
                this.value !== ""
                  ? regexr.replace("{search}", "(((" + this.value + ")))")
                  : "",
                this.value !== "",
                this.value === ""
              )
              .draw();

            $(this)[0].setSelectionRange(cursorPosition, cursorPosition);
          });
      });

      hideSearchInputs(containerElement, api.columns().responsiveHidden().toArray());
    }
  });

  table.responsive.recalc();

  table.on("draw.dt", function () {
    $(".paginate_button.current").removeClass("current");
  });

    table.on("responsive-resize", function (e, datatable, columns) {
      hideSearchInputs(containerElement, columns);
    
      const shouldHide = columns.some(col => col === false);
      const warning = document.getElementById("screen-too-small");
      const tableEl = document.getElementById(containerElement);
    
      if (shouldHide) {
        if (warning) warning.style.display = "block";
        if (tableEl) tableEl.style.display = "none";
      } else {
        if (warning) warning.style.display = "none";
        if (tableEl) tableEl.style.display = "table";
      }
    });
}