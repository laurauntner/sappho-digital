import java.io.File;
import java.io.FileNotFoundException;
import java.util.List;
import java.util.stream.Collectors;

import org.semanticweb.HermiT.ReasonerFactory;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.formats.RDFXMLDocumentFormat;
import org.semanticweb.owlapi.formats.TurtleDocumentFormat;
import org.semanticweb.owlapi.model.*;
import org.semanticweb.owlapi.reasoner.*;
import org.semanticweb.owlapi.util.InferredAxiomGenerator;
import org.semanticweb.owlapi.util.InferredClassAssertionAxiomGenerator;
import org.semanticweb.owlapi.util.InferredOntologyGenerator;
import org.semanticweb.owlapi.util.InferredPropertyAssertionGenerator;
import org.semanticweb.owlapi.util.SimpleIRIMapper;

public class Reasoner {

    public static void main(String[] args) throws Exception {

        // =========================================================
        // INPUTS
        // =========================================================

        File[] tboxCandidates = new File[] {
                new File("../documentation/ontology/ontology.ttl"),
                new File("../documentation/ontology/ontology.rdf")
        };

        File[] aboxCandidates = new File[] {
                new File("../data/rdf/sappho-reception.ttl"),
                new File("../data/rdf/sappho-reception.rdf")
        };

        File tboxFile = pickFirstExisting("TBox", tboxCandidates);
        File aboxFile = pickFirstExisting("ABox", aboxCandidates);

        // =========================================================
        // OUTPUTS
        // =========================================================

        File outAssertedInferredTTL = new File("../data/rdf/sappho-reception_asserted-and-inferred.ttl");
        File outAssertedInferredRDF = new File("../data/rdf/sappho-reception_asserted-and-inferred.rdf");
        File outInferredTTL         = new File("../data/rdf/sappho-reception_inferred.ttl");
        File outInferredRDF         = new File("../data/rdf/sappho-reception_inferred.rdf");

        ensureParentDir(outAssertedInferredTTL);
        ensureParentDir(outAssertedInferredRDF);
        ensureParentDir(outInferredTTL);
        ensureParentDir(outInferredRDF);

        long t0 = System.currentTimeMillis();

        // =========================================================
        // MAIN MANAGER: TBox + imports + merged + inferred + outputs
        // =========================================================
        OWLOntologyManager manager = OWLManager.createOWLOntologyManager();
        addImportMappings(manager);

        // =========================================================
        // LOAD TBOX
        // =========================================================
        System.out.println("1) Loading TBox: " + tboxFile.getPath());
        long t1 = System.currentTimeMillis();
        OWLOntology tbox = manager.loadOntologyFromOntologyDocument(tboxFile);
        long t2 = System.currentTimeMillis();
        System.out.println("   TBox axioms: " + tbox.getAxiomCount() + " (ms=" + (t2 - t1) + ")");

        // =========================================================
        // LOAD ABOX (separate manager to avoid ontology IRI collisions)
        // =========================================================
        System.out.println("2) Loading ABox: " + aboxFile.getPath());
        OWLOntologyManager aboxManager = OWLManager.createOWLOntologyManager();
        addImportMappings(aboxManager);

        long t3 = System.currentTimeMillis();
        OWLOntology abox = aboxManager.loadOntologyFromOntologyDocument(aboxFile);
        long t4 = System.currentTimeMillis();
        System.out.println("   ABox axioms: " + abox.getAxiomCount() + " (ms=" + (t4 - t3) + ")");

        // =========================================================
        // MERGE
        // =========================================================
        System.out.println("3) Merging TBox + ABox axioms …");
        long t5 = System.currentTimeMillis();

        OWLOntology merged = manager.createOntology(new OWLOntologyID());
        manager.addAxioms(merged, tbox.axioms().collect(Collectors.toSet()));
        manager.addAxioms(merged, abox.axioms().collect(Collectors.toSet()));

        long t6 = System.currentTimeMillis();
        System.out.println("   Merged axioms: " + merged.getAxiomCount() + " (ms=" + (t6 - t5) + ")");

        // =========================================================
        // REASONING
        // =========================================================
        System.out.println("4) Reasoning with HermiT …");
        long t7 = System.currentTimeMillis();

        OWLReasoner reasoner = new ReasonerFactory().createReasoner(merged);

        boolean consistent = reasoner.isConsistent();
        System.out.println("   Consistent: " + consistent);
        if (!consistent) {
            System.out.println("   WARNING: Ontology is inconsistent. Materialization may be unreliable.");
        }

        reasoner.precomputeInferences(
                InferenceType.CLASS_ASSERTIONS,
                InferenceType.OBJECT_PROPERTY_ASSERTIONS,
                InferenceType.DATA_PROPERTY_ASSERTIONS
        );

        long t8 = System.currentTimeMillis();
        System.out.println("   -> reasoning ms=" + (t8 - t7));

        // =========================================================
        // MATERIALIZE (INFERRED ONLY)
        // =========================================================
        System.out.println("5) Materializing inferred axioms …");
        long t9 = System.currentTimeMillis();

        List<InferredAxiomGenerator<? extends OWLAxiom>> gens = List.of(
                new InferredClassAssertionAxiomGenerator(),
                new InferredPropertyAssertionGenerator()
        );

        OWLOntology inferred = manager.createOntology(new OWLOntologyID());
        InferredOntologyGenerator iog = new InferredOntologyGenerator(reasoner, gens);
        iog.fillOntology(manager.getOWLDataFactory(), inferred);

        long t10 = System.currentTimeMillis();
        System.out.println("   Inferred axioms: " + inferred.getAxiomCount() + " (ms=" + (t10 - t9) + ")");

        // =========================================================
        // BUILD "ASSERTED + INFERRED"
        // =========================================================
        System.out.println("6) Building asserted+inferred ontology …");
        long t11 = System.currentTimeMillis();

        OWLOntology assertedAndInferred = manager.createOntology(new OWLOntologyID());
        manager.addAxioms(assertedAndInferred, merged.axioms().collect(Collectors.toSet()));
        manager.addAxioms(assertedAndInferred, inferred.axioms().collect(Collectors.toSet()));

        long t12 = System.currentTimeMillis();
        System.out.println("   Asserted+Inferred axioms: " + assertedAndInferred.getAxiomCount() + " (ms=" + (t12 - t11) + ")");

        // =========================================================
        // PREFIXES + GRAPH LABELS
        // =========================================================

        TurtleDocumentFormat ttlFormat = new TurtleDocumentFormat();
        ttlFormat.setPrefix("ecrm:",  "http://erlangen-crm.org/current/");
        ttlFormat.setPrefix("intro:", "https://w3id.org/lso/intro/v1.0#");
        ttlFormat.setPrefix("lrmoo:", "http://iflastandards.info/ns/lrm/lrmoo/");
        ttlFormat.setPrefix("owl:",   "http://www.w3.org/2002/07/owl#");
        ttlFormat.setPrefix("prov:",  "http://www.w3.org/ns/prov#");
        ttlFormat.setPrefix("rdfs:",  "http://www.w3.org/2000/01/rdf-schema#");
        ttlFormat.setPrefix("skos:",  "http://www.w3.org/2004/02/skos/core#");
        ttlFormat.setPrefix("xsd:",   "http://www.w3.org/2001/XMLSchema#");
        ttlFormat.setPrefix("rdf:",   "http://www.w3.org/1999/02/22-rdf-syntax-ns#");

        RDFXMLDocumentFormat rdfxmlFormat = new RDFXMLDocumentFormat();
        rdfxmlFormat.setPrefix("ecrm:",  "http://erlangen-crm.org/current/");
        rdfxmlFormat.setPrefix("intro:", "https://w3id.org/lso/intro/v1.0#");
        rdfxmlFormat.setPrefix("lrmoo:", "http://iflastandards.info/ns/lrm/lrmoo/");
        rdfxmlFormat.setPrefix("owl:",   "http://www.w3.org/2002/07/owl#");
        rdfxmlFormat.setPrefix("prov:",  "http://www.w3.org/ns/prov#");
        rdfxmlFormat.setPrefix("rdfs:",  "http://www.w3.org/2000/01/rdf-schema#");
        rdfxmlFormat.setPrefix("skos:",  "http://www.w3.org/2004/02/skos/core#");
        rdfxmlFormat.setPrefix("xsd:",   "http://www.w3.org/2001/XMLSchema#");
        rdfxmlFormat.setPrefix("rdf:",   "http://www.w3.org/1999/02/22-rdf-syntax-ns#");

        OWLDataFactory df = manager.getOWLDataFactory();

        OWLAnnotation labelInferred = df.getOWLAnnotation(
                df.getRDFSLabel(),
                df.getOWLLiteral("Sappho Digital Graph – Inferred Triples", "en")
        );

        OWLAnnotation labelAssertedAndInferred = df.getOWLAnnotation(
                df.getRDFSLabel(),
                df.getOWLLiteral("Sappho Digital Graph – Asserted and Inferred Triples", "en")
        );

        // add labels as ontology annotations (anonymous ontology ID stays unchanged)
        manager.applyChange(new AddOntologyAnnotation(inferred, labelInferred));
        manager.applyChange(new AddOntologyAnnotation(assertedAndInferred, labelAssertedAndInferred));

        // =========================================================
        // SAVE FILES
        // =========================================================
        System.out.println("7) Saving outputs …");

        // inferred only
        manager.saveOntology(inferred, ttlFormat, IRI.create(outInferredTTL));
        manager.saveOntology(inferred, rdfxmlFormat, IRI.create(outInferredRDF));

        // asserted + inferred
        manager.saveOntology(assertedAndInferred, ttlFormat, IRI.create(outAssertedInferredTTL));
        manager.saveOntology(assertedAndInferred, rdfxmlFormat, IRI.create(outAssertedInferredRDF));

        long t13 = System.currentTimeMillis();

        System.out.println("   Wrote:");
        System.out.println("   - " + outAssertedInferredTTL.getPath());
        System.out.println("   - " + outAssertedInferredRDF.getPath());
        System.out.println("   - " + outInferredTTL.getPath());
        System.out.println("   - " + outInferredRDF.getPath());
        System.out.println("   -> save ms=" + (t13 - t12));

        reasoner.dispose();

        long tEnd = System.currentTimeMillis();
        System.out.println("DONE. Total ms=" + (tEnd - t0));
    }

    // ---------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------

    private static File pickFirstExisting(String label, File[] candidates) throws FileNotFoundException {
        for (File f : candidates) {
            if (f.exists() && f.isFile()) return f;
        }
        String options = java.util.Arrays.stream(candidates)
                .map(File::getPath)
                .collect(Collectors.joining(", "));
        throw new FileNotFoundException(label + " not found. Tried: " + options);
    }

    private static void ensureParentDir(File f) {
        File p = f.getParentFile();
        if (p != null) p.mkdirs();
    }

    /*
     * Offline import mapping for:
     * - INTRO  -> imports/INTRO.owl
     * - LRMoo  -> imports/LRMoo.owl
     * - ECRM   -> imports/ECRM.owl
     *
     * Each local file is mapped from the import IRI used in ontology.ttl
     * (owl:imports) as well as from its ontology IRI, so that the local copy
     * is used no matter which of the two is requested.
     */
    private static void addImportMappings(OWLOntologyManager manager) {

        // INTRO v1.0
        mapLocal(manager, "imports/INTRO.owl",
                "https://w3id.org/lso/intro/v1.0",
                "https://w3id.org/lso/intro/v1.0#");

        // LRMoo 1.1.1 (imports CIDOC CRM 7.1.3, which is still resolved online)
        mapLocal(manager, "imports/LRMoo.owl",
                "https://cidoc-crm.org/extensions/lrmoo/owl/1.1.1/LRMoo_v1.1.1.owl",
                "http://iflastandards.info/ns/lrm/lrmoo/");

        // ECRM 240307
        mapLocal(manager, "imports/ECRM.owl",
                "http://erlangen-crm.org/current/");
    }

    private static void mapLocal(OWLOntologyManager manager, String path, String... iris) {
        File local = new File(path);
        if (!local.exists()) {
            System.out.println("   WARNING: local import not found, will resolve online: " + path);
            return;
        }
        IRI target = IRI.create(local.toURI());
        for (String iri : iris) {
            manager.getIRIMappers().add(new SimpleIRIMapper(IRI.create(iri), target));
        }
    }
}
