module sqat::series2::A1a_StatCov_Graph_Construction

import lang::java::jdt::m3::Core;

import Set;
import String;
import IO;
import util::Math;

data Node 	= compilationUnit(loc src)
			| package(loc src)
			| class(loc src)
			| method(loc src)
			;

data Label 	= definition()
			| call()
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

rel[loc name, loc src] getAllTestMethodsInModel(M3 model){ 
	rel[loc name, loc src] methods = getAllMethodsInModel(model);
	return {m | m <- methods, contains(m.src.path, "test") };
}

rel[loc name, loc src] getAllNonTestMethodsInModel(M3 model){
	rel[loc name, loc src] methods = getAllMethodsInModel(model);
	return {m | m <- methods, !contains(m.src.path, "test") };
}

rel[loc name, loc src] getAllNonTestPackagesInModel(M3 model){
	rel[loc name, loc src] packages =  getDeclarationsByScheme(model, "java+package");
	return {p | p <- packages, !contains(p.src.path, "test") };
}

rel[loc name, loc src] getAllNonTestClassesInModel(M3 model){
	rel[loc name, loc src] classes = getDeclarationsByScheme(model, "java+class");
	return {c | c <- classes, !contains(c.src.path, "test") };
}

Graph graphTransitiveClosure(Graph gr){
	solve(gr){
		for(tuple[Node from, Label l, Node to] n <- gr){
			gr += { <n.from, n.l, reachable.to> | tuple[Node from, Label l, Node to] reachable <- gr, 
																			reachable.from.src == n.to.src, 
																			n.from != reachable.to,
																			n.l == reachable.l};
		}
	}
	return gr;
}

Graph constructContainmentGraph(M3 model){
	rel[loc from, loc to] containingRelations = model.containment;
	
	Graph relations = {};
	
	for(tuple[loc from, loc to] relation <- containingRelations){
		if(relation.from.scheme == "java+package" && relation.to.scheme == "java+package"){
			relations = relations + <package(relation.from), definition(), package(relation.to)>;
		} else if(relation.from.scheme == "java+package" && relation.to.scheme == "java+compilationUnit"){
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
		}
	}
	
	for(tuple[loc from, loc to] override <- overrides){
		tuple[Node from, Label label, Node to] new = <method(override.from), call(), method(override.to)>;
		calls = calls + new;
	}
	
	return calls;
}


