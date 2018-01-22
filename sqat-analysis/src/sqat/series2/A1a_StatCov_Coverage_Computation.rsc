module sqat::series2::A1a_StatCov_Coverage_Computation

import lang::java::jdt::m3::Core;
import sqat::series2::A1a_StatCov_Graph_Construction;

import Set;
import String;
import IO;
import util::Math;

alias MethodCoverage = real;
alias ClassCoverage = map[loc name, real coverage];
alias PackageCoverage = map[loc name, real coverage];
alias CoverageStatistics = tuple[MethodCoverage mc, PackageCoverage pc, ClassCoverage cc];

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
	MethodCoverage mc = (toReal(coveredMethodCount) / toReal(methodCount)) * 100.0;
	return mc;
}

real computeCoverageOfItem(tuple[loc name, loc src] item, Graph containmentGraph, map[loc method, bool covered] coveredMethods, M3 model){
		rel[loc name, loc src] allMethods = getAllNonTestMethodsInModel(model);
		set[loc] methods = { containment.to.src | tuple[Node from, Label l, Node to] containment <- containmentGraph, 
																						containment.from.src == item.name,
																						containment.to.src in allMethods.name} ;
		set[loc] covered = { m | loc m <- methods, coveredMethods[m]};
		if(size(methods) != 0) {
			real percentage = (toReal(size(covered)) / size(methods)) * 100;
			return percentage;
		} else {
			return 0.0;
		}
}

ClassCoverage computeClassCoverage(Graph containmentGraph, map[loc method, bool covered] coveredMethods, M3 model){
	ClassCoverage cov = ();
	rel[loc name, loc src] classes = getAllNonTestClassesInModel(model);
	for(tuple[loc name, loc src] class <- classes){
		cov[class.name] = computeCoverageOfItem(class, containmentGraph, coveredMethods, model);
	}
	return cov;
}

PackageCoverage computePackageCoverage(Graph containmentGraph, map[loc method, bool covered] coveredMethods, M3 model){
	PackageCoverage cov = ();
	rel[loc name, loc src] packages = getAllNonTestPackagesInModel(model);
	for(tuple[loc name, loc src] package <- packages){
		cov[package.name] = computeCoverageOfItem(package, containmentGraph, coveredMethods, model);
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
	
	CoverageStatistics stats = <mc, pc, cc>;
	return stats;
}




