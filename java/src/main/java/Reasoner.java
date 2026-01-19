import java.io.File;
import java.util.*;
import java.util.stream.Collectors;

import org.semanticweb.HermiT.ReasonerFactory;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.formats.*;
import org.semanticweb.owlapi.model.*;
import org.semanticweb.owlapi.reasoner.*;
import org.semanticweb.owlapi.util.*;

public class Reasoner {

    public static void main(String[] args) throws Exception {

        // ================= FILES =================

        File tboxFile = new File("../documentation/ontology/ontology.ttl");

        File[] aboxCandidates = new File[] {
                new File("../data/rdf/sappho-reception.ttl"),
                new File("../data/rdf/sappho-reception.rdf")
        };

        File outAssertedInferredTTL = new File("../data/rdf/sappho-reception_asserted-and-inferred.ttl");
        File outAssertedInferredRDF = new File("../data/rdf/sappho-reception_asserted-and-inferred.rdf");
        File outInferredTTL         = new File("../data/rdf/sappho-reception_inferred.ttl");
        File outInferredRDF         = new File("../data/rdf/sappho-reception_inferred.rdf");

        // ================= MANAGER + IMPORT MAPPINGS =================

        OWLOntologyManager manager = OWLManager.createOWLOntologyManager();

        // INTRO
        manager.getIRIMappers().add(new SimpleIRIMapper(
                IRI.create("https://w3id.org/lso/intro/currentbeta#"),
                IRI.create(new File("imports/INTRO.owl").toURI())
        ));

        // LRMoo
        manager.getIRIMappers().add(new SimpleIRIMapper(
                IRI.create("http://www.cidoc-crm.org/lrmoo/"),
                IRI.create(new File("imports/LRMoo.owl").toURI())
        ));

        // ECRM
        manager.getIRIMappers().add(new SimpleIRIMapper(
                IRI.create("http://erlangen-crm.org/current/"),
                IRI.create(new File("imports/ECRM.owl").toURI())
        ));

        // ================= LOAD TBOX =================

        System.out.println("1) Loading TBox …");
        OWLOntology tbox = manager.loadOntologyFromOntologyDocument(tboxFile);

        // ================= LOAD ABOX =================

        File aboxFile = null;
        for (File f : aboxCandidates) {
            if (f.exists()) {
                aboxFile = f;
                break;
            }
        }
        if (aboxFile == null)
            throw new RuntimeException("ABox not found (neither TTL nor RDF)");

        System.out.println("2) Loading ABox: " + aboxFile.getPath());
        OWLOntology abox = manager.loadOntologyFromOntologyDocument(aboxFile);

        // ================= MERGE =================

        System.out.println("3) Merging ontologies …");

        OWLOntology merged = manager.createOntology(new OWLOntologyID());

        manager.addAxioms(merged, tbox.axioms().collect(Collectors.toSet()));
        manager.addAxioms(merged, abox.axioms().collect(Collectors.toSet()));

        System.out.println("   TBox axioms   : " + tbox.getAxiomCount());
        System.out.println("   ABox axioms   : " + abox.getAxiomCount());
        System.out.println("   Merged axioms : " + merged.getAxiomCount());

        // ================= REASONING =================

        System.out.println("4) Reasoning with HermiT …");

        OWLReasoner reasoner = new ReasonerFactory().createReasoner(merged);

        reasoner.isConsistent();

        reasoner.precomputeInferences(
                InferenceType.CLASS_ASSERTIONS,
                InferenceType.OBJECT_PROPERTY_ASSERTIONS,
                InferenceType.DATA_PROPERTY_ASSERTIONS
        );

        // ================= MATERIALISE INFERRED =================

        System.out.println("5) Materialising inferred axioms …");

        List<InferredAxiomGenerator<? extends OWLAxiom>> gens = List.of(
                new InferredClassAssertionAxiomGenerator(),
                new InferredPropertyAssertionGenerator()
        );

        OWLOntology inferred = manager.createOntology(new OWLOntologyID());

        InferredOntologyGenerator iog = new InferredOntologyGenerator(reasoner, gens);
        iog.fillOntology(manager.getOWLDataFactory(), inferred);

        System.out.println("   Inferred axioms: " + inferred.getAxiomCount());

        // ================= ASSERTED + INFERRED =================

        OWLOntology assertedAndInferred = manager.createOntology(new OWLOntologyID());
        manager.addAxioms(assertedAndInferred, merged.axioms().collect(Collectors.toSet()));
        manager.addAxioms(assertedAndInferred, inferred.axioms().collect(Collectors.toSet()));

        // ================= PREFIXES + ONTOLOGY HEADER =================

        PrefixDocumentFormat prefixFormat = new TurtleDocumentFormat();

        prefixFormat.setPrefix("ecrm:",  "http://erlangen-crm.org/current/");
        prefixFormat.setPrefix("intro:", "https://w3id.org/lso/intro/currentbeta#");
        prefixFormat.setPrefix("lrmoo:", "http://www.cidoc-crm.org/lrmoo/");
        prefixFormat.setPrefix("owl:",   "http://www.w3.org/2002/07/owl#");
        prefixFormat.setPrefix("prov:",  "http://www.w3.org/ns/prov#");
        prefixFormat.setPrefix("rdfs:",  "http://www.w3.org/2000/01/rdf-schema#");
        prefixFormat.setPrefix("skos:",  "http://www.w3.org/2004/02/skos/core#");
        prefixFormat.setPrefix("xsd:",   "http://www.w3.org/2001/XMLSchema#");

        OWLDataFactory df = manager.getOWLDataFactory();

        OWLAnnotation label = df.getOWLAnnotation(
                df.getRDFSLabel(),
                df.getOWLLiteral("Sappho Digital Graph", "en")
        );

        // Ontology node to both outputs
        addOntologyHeader(manager, assertedAndInferred, label);
        addOntologyHeader(manager, inferred, label);

        // ================= SAVE =================

        System.out.println("6) Writing output files …");

        // asserted + inferred
        manager.saveOntology(assertedAndInferred, prefixFormat, IRI.create(outAssertedInferredTTL));
        manager.saveOntology(assertedAndInferred, new RDFXMLDocumentFormat(), IRI.create(outAssertedInferredRDF));

        // inferred only
        manager.saveOntology(inferred, prefixFormat, IRI.create(outInferredTTL));
        manager.saveOntology(inferred, new RDFXMLDocumentFormat(), IRI.create(outInferredRDF));

        reasoner.dispose();

        System.out.println("DONE.");
        System.out.println("  " + outAssertedInferredTTL.getPath());
        System.out.println("  " + outAssertedInferredRDF.getPath());
        System.out.println("  " + outInferredTTL.getPath());
        System.out.println("  " + outInferredRDF.getPath());
    }

    // Helper: add ontology header + label
    static void addOntologyHeader(OWLOntologyManager manager,
                                  OWLOntology ont,
                                  OWLAnnotation label) {

        OWLOntologyID id = ont.getOntologyID();
        OWLOntologyManager m = manager;

        if (id.getOntologyIRI().isEmpty()) {
            try {
                m.applyChange(new SetOntologyID(
                        ont,
                        new OWLOntologyID(
                                Optional.of(IRI.create("https://w3id.org/sappho-digital/graph")),
                                Optional.empty()
                        )
                ));
            } catch (Exception ignore) {}
        }

        OWLOntology o = ont;

        m.applyChange(new AddOntologyAnnotation(o, label));
    }
}
