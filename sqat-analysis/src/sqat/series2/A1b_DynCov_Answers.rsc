module sqat::series2::A1b_DynCov_Answers

import sqat::series2::A1b_DynCov_Coverage;
import Set;
import String;
import IO;
import util::Math;

/*

Assignment: instrument (non-test) code to collect dynamic coverage data.

- Write a little Java class that contains an API for collecting coverage information
  and writing it to a file. NB: if you write out CSV, it will be easy to read into Rascal
  for further processing and analysis (see here: lang::csv::IO)

- Write two transformations:
  1. to obtain method coverage statistics
     (at the beginning of each method M in class C, insert statement `hit("C", "M")`
  2. to obtain line-coverage statistics
     (insert hit("C", "M", "<line>"); after every statement.)

The idea is that running the test-suite on the transformed program will produce dynamic
coverage information through the insert calls to your little API.

Questions
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)
		- Very close
		- Overrides not completely working
- which methods have full line coverage?
- which methods are not covered at all, and why does it matter (if so)?
- what are the drawbacks of source-based instrumentation?
		- Running source-base instrumentation requires a working installation of the software. 

Tips:
- create a shadow JPacman project (e.g. jpacman-instrumented) to write out the transformed source files.
  Then run the tests there. You can update source locations l = |project://jpacman/....| to point to the 
  same location in a different project by updating its authority: l.authority = "jpacman-instrumented"; 

- to insert statements in a list, you have to match the list itself in its context, e.g. in visit:
     case (Block)`{<BlockStm* stms>}` => (Block)`{<BlockStm insertedStm> <BlockStm* stms>}` 
  
- or (easier) use the helper function provide below to insert stuff after every
  statement in a statement list.

- to parse ordinary values (int/str etc.) into Java15 syntax trees, use the notation
   [NT]"...", where NT represents the desired non-terminal (e.g. Expr, IntLiteral etc.).  

*/

void printCoverage(){
	rel[loc method, loc line, bool covered] lines = lineCoverage();
	int lineCount = size(lines);
	rel[loc method, loc line, bool covered] coveredLines = { l | l <- lines, l.covered };
	int coveredLineCount = size(coveredLines);
	real lineCoverage = toReal(coveredLineCount) / lineCount * 100.0;
	println("Line coverage : <lineCoverage>");
	
	rel[loc method, bool covered] methods = methodCoverage();
	int methodCount = size(methods);
	rel[loc method, bool covered] coveredMethods = { m | m <- methods, m.covered };
	int coveredMethodCount = size(coveredMethods);
	real methodCoverage = toReal(coveredMethodCount) / methodCount * 100.0;
	println("Method coverage : <methodCoverage>");
}

set[loc method] notCoveredMethods(){
 	rel[loc method, bool covered] methods = methodCoverage();
 	set[loc method] notCoveredMethods = { m.method | m <- methods, !m.covered };
 	return notCoveredMethods;
}

set[loc method] fullyCoveredMethods(){
 	rel[loc method, loc line, bool covered] lines = lineCoverage();
 	set[loc] methods = lines.method;
 	set[loc] fullyCoveredMethods = {}; 
 	for(loc method <- methods){
 		rel[loc method, loc line, bool covered] allLinesOfMethod = { line | tuple[loc m, loc l, bool c] line <- lines, line.m == method};
 		rel[loc method, loc line, bool covered] allCoveredLinesOfMethod = { line | tuple[loc m, loc l, bool covered] line <- allLinesOfMethod, line.covered};
 		if(size(allLinesOfMethod) == size(allCoveredLinesOfMethod)){
 			fullyCoveredMethods += method;
 		}
 	}
 	return fullyCoveredMethods;
}

