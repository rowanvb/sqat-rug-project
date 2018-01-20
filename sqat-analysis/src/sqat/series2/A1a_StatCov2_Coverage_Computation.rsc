module sqat::series2::A1a_StatCov

import lang::java::jdt::m3::Core;

import Set;
import String;
import IO;
import util::Math;
/*

Implement static code coverage metrics by Alves & Visser 
(https://www.sig.eu/en/about-sig/publications/static-estimation-test-coverage)


The relevant base data types provided by M3 can be found here:

- module analysis::m3::Core:

rel[loc name, loc src]        M3.declarations;            // maps declarations to where they are declared. contains any kind of data or type or code declaration (classes, fields, methods, variables, etc. etc.)
rel[loc name, TypeSymbol typ] M3.types;                   // assigns types to declared source code artifacts
rel[loc src, loc name]        M3.uses;                    // maps source locations of usages to the respective declarations
rel[loc from, loc to]         M3.containment;             // what is logically contained in what else (not necessarily physically, but usually also)
list[Message]                 M3.messages;                // error messages and warnings produced while constructing a single m3 model
rel[str simpleName, loc qualifiedName]  M3.names;         // convenience mapping from logical names to end-user readable (GUI) names, and vice versa
rel[loc definition, loc comments]       M3.documentation; // comments and javadoc attached to declared things
rel[loc definition, Modifier modifier] M3.modifiers;      // modifiers associated with declared things

- module  lang::java::m3::Core:

rel[loc from, loc to] M3.extends;            // classes extending classes and interfaces extending interfaces
rel[loc from, loc to] M3.implements;         // classes implementing interfaces
rel[loc from, loc to] M3.methodInvocation;   // methods calling each other (including constructors)
rel[loc from, loc to] M3.fieldAccess;        // code using data (like fields)
rel[loc from, loc to] M3.typeDependency;     // using a type literal in some code (types of variables, annotations)
rel[loc from, loc to] M3.methodOverrides;    // which method override which other methods
rel[loc declaration, loc annotation] M3.annotations;

Tips
- encode (labeled) graphs as ternary relations: rel[Node,Label,Node]
- define a data type for node types and edge types (labels) 
- use the solve statement to implement your own (custom) transitive closure for reachability.

Questions:
- what methods are not covered at all?
- how do your results compare to the jpacman results in the paper? Has jpacman improved?
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)

Notes:
- Currently it doesn't look at anonymous classes

*/

alias MethodCoverage = real;
alias ClassCoverage = map[loc name, real coverage];
alias PackageCoverage = map[loc name, real coverage];
alias CoverageStatistics = tuple[PackageCoverage, ClassCoverage, MethodCoverage];

map[loc method, bool covered] determineCoveredMethods(M3 model){
	rel[loc name, loc src] testMethods = getAllTestMethodsInModel(model);
	rel[loc name, loc src] methods = getAllNonTestMethodsInModel(model);
	
	Graph callGraph = graphTransitiveClosure(constructCallGraph(model));
	
	set[loc name] testedMethods = { item.to.src | tuple[Node from, Label l, Node to] item <- callGraph, 
																						item.from.src in testMethods.name,
																						item.to.src notin testMethods.name};
																						
	map[loc, bool] coverage = ();
	for(loc name <- methods.name){
		coverage[name] = (name in testedMethods);
	}
	return coverage;
}

MethodCoverage computeMethodCoverage(Graph containmentGraph, map[loc method, bool covered] coveredMethods){
	int methodCount = size(coveredMethods.method);
	int coveredMethodCount = size({ m | loc m <- coveredMethods, coveredMethods[m] } );
	
	return (toReal(coveredMethodCount) / toReal(methodCount)) * 100.0;
}

ClassCoverage computeClassCoverage(Graph containmentGraph, map[loc method, bool covered] coveredMethods, M3 model){
	ClassCoverage cov = ();
	rel[loc name, loc src] classes = getAllNonTestClassesInModel(model);
	rel[loc name, loc src] allMethods = getAllNonTestMethodsInModel(model);
	for(tuple[loc name, loc src] class <- classes){
		set[loc] methods = { item.to.src | tuple[Node from, Label l, Node to] item <- containmentGraph, 
																						item.from.src == class.name,
																						item.to.src in allMethods.name} ;
		set[loc] covered = { m | loc m <- methods, coveredMethods[m]};
		println("<class.name> -\> <size(covered)> / <size(methods)>");
		if(size(methods) != 0) {
			real percentage = (toReal(size(covered)) / size(methods)) * 100;
			cov[class.name] = percentage;
		} else {
			cov[class.name] = 0.0;
		}
	}
	return cov;
}

PackageCoverage computePackageCoverage(Graph containmentGraph, map[loc method, bool covered] coveredMethods, M3 model){
	PackageCoverage cov = ();
	rel[loc name, loc src] packages = getAllNonTestPackagesInModel(model);
	rel[loc name, loc src] allMethods = getAllNonTestMethodsInModel(model);
	for(tuple[loc name, loc src] package <- packages){
		set[loc] methods = { item.to.src | tuple[Node from, Label l, Node to] item <- containmentGraph, 
																						item.from.src == package.name,
																						item.to.src in allMethods.name};
		set[loc] covered = { m | loc m <- methods, coveredMethods[m] };
		
		if(size(methods) != 0) {
			real percentage = (toReal(size(covered)) / size(methods)) * 100;
			cov[package.name] = percentage;
		} else {
			cov[package.name] = 0.0;
		}
	}
	return cov;
}

CoverageStatistics computeCoverageStatisticsForProject(loc project = |project://jpacman-framework|){
	M3 model = createM3FromEclipseProject(project);
	println("Constructing containment graph...");
	Graph containmentGraph = graphTransitiveClosure(constructContainmentGraph(model));
	println("Determining covered methods...");
	map[loc method, bool covered] coveredMethods = determineCoveredMethods(model);
	
	MethodCoverage mc = computeMethodCoverage(containmentGraph, coveredMethods);
	ClassCoverage cc = computeClassCoverage(containmentGraph, coveredMethods, model);
	PackageCoverage pc = computePackageCoverage(containmentGraph, coveredMethods, model);
	
	CoverageStatistics stats = <pc, cc, mc>;
	return stats;
}




