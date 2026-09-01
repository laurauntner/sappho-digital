(function () {
    var latestQueryString = null;

    function getSparnatural() {
        return document.getElementById("sparnatural");
    }

    function applyToEditor(rawQueryString) {
        var sparnatural = getSparnatural();
        var editor = document.getElementById("queryEditor");
        if (!sparnatural || !editor || !rawQueryString) return;

        var expanded;
        try {
            expanded = sparnatural.expandSparql(rawQueryString);
        } catch (e) {
            expanded = rawQueryString;
        }

        editor.value = expanded;

        document.querySelectorAll(".examples .example-btn").forEach(function (btn) {
            btn.style.removeProperty("background-color");
            btn.style.removeProperty("color");
            btn.style.removeProperty("border-color");
            btn.classList.remove("active");
        });

        editor.scrollIntoView({ behavior: "smooth", block: "center" });
        editor.focus();
    }

    document.addEventListener("DOMContentLoaded", function () {
        var sparnatural = getSparnatural();
        if (!sparnatural) return;

        sparnatural.addEventListener("queryUpdated", function (event) {
            latestQueryString = event.detail && event.detail.queryString;
        });

        sparnatural.addEventListener("submit", function () {
            applyToEditor(latestQueryString);
        });

        sparnatural.addEventListener("reset", function () {
            latestQueryString = null;
        });

        // Lift the CSS mask on the root class selector (see
        // sparnatural/theme.css) only once the user actually clicks
        // "Search for resources" -- never on a click elsewhere, and never
        // by touching Sparnatural's own "open" class. Capture phase, and
        // composedPath() rather than event.target.closest(): Sparnatural
        // mutates this row's DOM synchronously on click (replacing nodes),
        // so a bubble-phase listener can see event.target already detached
        // from the tree by the time it runs, and closest() on a detached
        // node never finds an ancestor -- composedPath() is the path at
        // dispatch time, before any of that mutation.
        document.addEventListener(
            "click",
            function (event) {
                var path = event.composedPath ? event.composedPath() : [event.target];
                var inStartClassGroup = path.some(function (el) {
                    return el.classList && el.classList.contains("StartClassGroup");
                });
                if (inStartClassGroup) {
                    document.body.classList.add("sparnatural-start-opened");
                }
            },
            true
        );

        // Sparnatural draws its "Where"/"And" connector lines with
        // position:absolute against <body>, computed from
        // getBoundingClientRect() + window.scrollY on the assumption that
        // the document itself scrolls natively. This site instead scrolls
        // #page (see html/css/style.css, "body.page #page") while <body>
        // stays pinned at the viewport origin, so window.scrollY is always
        // 0 and a line, once drawn, never moves again -- it visually
        // detaches from its chips and drifts into whatever now sits at
        // that fixed screen position as the user scrolls #page. Sparnatural
        // already recomputes every line correctly whenever a
        // "redrawBackgroundAndLinks" event reaches the widget root (it
        // dispatches this itself on every relevant state change); re-firing
        // that same event on #page's scroll keeps the lines in sync
        // without touching Sparnatural's internal state or CSS overflow.
        var page = document.getElementById("page");
        var sparnaturalRoot = document.querySelector("#sparnaturalSection .Sparnatural");
        if (page && sparnaturalRoot) {
            var redrawScheduled = false;
            page.addEventListener("scroll", function () {
                if (redrawScheduled) return;
                redrawScheduled = true;
                requestAnimationFrame(function () {
                    redrawScheduled = false;
                    sparnaturalRoot.dispatchEvent(
                        new CustomEvent("redrawBackgroundAndLinks", { bubbles: true })
                    );
                });
            });
        }
    });
})();
