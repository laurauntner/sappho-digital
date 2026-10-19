"""Ein Name pro Person als rdfs:label, weitere Namensformen als skos:altLabel."""
from collections import Counter
from rdflib import Literal
from rdflib.namespace import RDFS, SKOS

XML_ID = "{http://www.w3.org/XML/1998/namespace}id"
TEI_AUTHOR = "{http://www.tei-c.org/ns/1.0}author"


def preferred_person_names(bibls):
    """Liefert {xml_id: (bevorzugter Name, [weitere Namen])}.

    Bevorzugt wird die häufigste Namensform ohne eckige Klammern und Fragezeichen
    (also ohne Pseudonym-Auflösung oder unsichere Zuschreibung), bei Gleichstand
    die zuerst vorkommende.
    """
    forms = {}
    for bibl in bibls:
        for el in bibl.iter(TEI_AUTHOR):
            aid = el.get(XML_ID)
            name = (el.text or "").strip()
            if aid and name:
                forms.setdefault(aid, Counter())[name] += 1
    result = {}
    for aid, counter in forms.items():
        order = list(counter)  # Reihenfolge des ersten Vorkommens
        clean = [n for n in order if "[" not in n and "?" not in n] or order
        pref = max(clean, key=lambda n: (counter[n], -order.index(n)))
        result[aid] = (pref, [n for n in order if n != pref])
    return result


def add_person_names(g, person_uri, names):
    if not names:
        return
    pref, alts = names
    g.add((person_uri, RDFS.label, Literal(pref, lang="de")))
    for alt in alts:
        g.add((person_uri, SKOS.altLabel, Literal(alt, lang="de")))
