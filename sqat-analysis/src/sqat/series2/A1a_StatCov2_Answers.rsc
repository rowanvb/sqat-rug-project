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


data Node 	= compilationUnit(loc src)
			| package(loc src)
			| class(loc src)
			| method(loc src)
			;

data Label 	= definition()
			| call()
			| virtual_call()
			| overloading_call()
			;

alias Graph = rel[Node from, Label label, Node to];

M3 jpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework|);

rel[loc name, loc src] getDeclarationsByScheme(M3 model, str scheme){
	rel[loc name, loc src] declarations = {};
	for(tuple[loc name, loc src] declaration <- model.declarations)
	{
		if(declaration.name.scheme == scheme){
			declarations = declarations + declaration;	
		}
	}
	return declarations;
}

rel[loc name, loc src] getAllMethodsInModel(M3 model){
	return getDeclarationsByScheme(model, "java+method") + getDeclarationsByScheme(model, "java+constructor");
}

rel[loc name, loc src] getAllPackagesInModel(M3 model){
	return getDeclarationsByScheme(model, "java+package");
}

rel[loc name, loc src] getAllClassesInModel(M3 model){
	return getDeclarationsByScheme(model, "java+class");
}

rel[loc name, loc src] getAllInterfacesInModel(M3 model){
	return getDeclarationsByScheme(model, "java+interface");
}

// Bases decision on the src path containing the word test
rel[loc name, loc src] getAllTestMethodsInModel(M3 model){ 
	rel[loc name, loc src] methods = getAllMethodsInModel(model);
	return {m | m <- methods, contains(m.src.path, "test") };
}

rel[loc name, loc src] getAllNonTestMethodsInModel(M3 model){
	rel[loc name, loc src] methods = getAllMethodsInModel(model);
	return {m | m <- methods, !contains(m.src.path, "test") };
}

Graph graphTransitiveClosure(Graph gr){
	println("<size(gr)>");
	solve(gr){
		for(tuple[Node from, Label l, Node to] n <- gr){
			gr += { <n.from, n.l, reachable.to> | tuple[Node from, Label l, Node to] reachable <- gr, 
																			reachable.from.src == n.to.src, 
																			n.from != reachable.to,
																			n.l == reachable.l};
		}
		println("<size(gr)>");
	}
	return gr;
}

Graph constructContainmentGraph(M3 model){
	rel[loc from, loc to] containingRelations = model.containment;
	
	Graph relations = {};
	
	for(tuple[loc from, loc to] relation <- containingRelations){
		if(relation.from.scheme == "java+package" && relation.to.scheme == "java+compilationUnit"){
			relations = relations + <package(relation.from), definition(), compilationUnit(relation.to)>;
		} else if (relation.from.scheme == "java+compilationUnit" && relation.to.scheme == "java+class") {
			relations = relations + <class(relation.from), definition(), method(relation.to)>;;
		} else if (relation.from.scheme == "java+class" && relation.to.scheme == "java+method") {
			relations = relations + <class(relation.from), definition(), method(relation.to)>;;
		}
	}
	
	return relations;
}

Graph constructCallGraph(M3 model){
	rel[loc from, loc to] callRelations = model.methodInvocation;
	rel[loc from, loc to] overrides = model.methodOverrides;
	
	Graph calls = {};
	
	for(tuple[loc from, loc to] callRelation <- callRelations){
		tuple[Node from, Label label, Node to] new = <method(callRelation.from), call(), method(callRelation.to)>;
		if(callRelation.from != callRelation.to){		// Recursive calls are ignored
			calls = calls + new;
		} else {
			println(new);
		}
	}
	
	for(tuple[loc from, loc to] override <- overrides){
		tuple[Node from, Label label, Node to] new = <method(override.from), call(), method(override.to)>;
		calls = calls + new;
	}
	
	 // Overloading is unclear
	
	return calls;
}


rel[loc method, bool covered] determineCoveredMethodsOfProject(M3 model){
	rel[loc name, loc src] testMethods = getAllTestMethodsInModel(model);
	rel[loc name, loc src] methods = getAllNonTestMethodsInModel(model);
	
	Graph callGraph = graphTransitiveClosure(constructCallGraph(model));
	
	set[loc name] testedMethods = { item.to.src | tuple[Node from, Label l, Node to] item <- callGraph, 
																						item.from.src in testMethods.name,
																						item.l == call()};
																						
	return { <name, (name in testedMethods)> | loc name <- methods.name };
}

real calculateMethodCoverageOfProject(M3 model, map[loc name, bool covered] methodCoverage){ // TODO: Add project
	Graph containmentGraph = graphTransitiveClosure(constructContainmentGraph(model));
							
	return toReal((toReal(size(testedMethods) - size(testMethods)) / toReal(size(methods))) * 100.0);
}




