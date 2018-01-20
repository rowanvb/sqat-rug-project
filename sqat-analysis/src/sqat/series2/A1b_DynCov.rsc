module sqat::series2::A1b_DynCov

import Java17ish;
import IO;
import ParseTree;
import String;
import util::FileSystem;
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
loc API_LOCATION = |project://sqat-analysis/src/sqat/series2/coverage_api/CoverageAPI.java|;
//apiImport = (ImportDec)''

loc updateAuthority(loc project){
	project.authority = project.authority + "-instrumented";
	return project;
}

/*void instrumentSourceCodeFile(loc file){
	tree = parse(#start[CompilationUnit], file, allowAmbiguity=true);
	x = visit(tree) {
		case (CompilationUnit) `<PackageDec? p> <ImportDec* i> <TypeDec* t>` => 
		case (MethodBody) `{<BlockStm* stms>}` => (MethodBody)`{<BlockStm call> <BlockStm* stms>}`
	}
	x = top-down-break visit(tree) {
		case (CompilationUnit) `<PackageDec? package> <ImportDec* imports> <TypeDec* types>` => (CompilationUnit)`<PackageDec? package> <ImportDec* imports> <ImportDec api> <TypeDec* types>`
	}
	cnt1 = 0;
	x2 = visit(tree) {
		case (MethodBody) `{<BlockStm* stms>}` => blockify(putAfterEvery(stms, callStmt, name))
	}
}*/

void handleFile(loc file){
	if(contains(file.path, "src/main/java") && contains(file.file, ".java")){ // Source code
		println(file);
	} else {
		str text = readFile(file);
		writeFile(updateAuthority(file), text);
	}
}

void handleDirectory(loc dir){
	mkDirectory(updateAuthority(dir));
	for(f <- dir.ls){
		handle(f);API_LOCATION
	}
}

void handle(loc f){
	if(isDirectory(f)){
		handleDirectory(f);
	} else if(isFile(f)){
		handleFile(f);
	}
}

void createInstrumentedProject(loc p = |project://jpacman-framework|){
	mkDirectory(updateAuthority(p));
	for(loc file <- p.ls){
		handle(file);
	}
	loc api = updateAuthority(p);;
	api.path = api.path + "src/main/java/coverage_api";
	api.file = api.file + "/CoverageAPI.java";
	mkDirectory(api);
	str text = readFile(API);
	writeFile(updateAuthority(api), text);
}

void methodCoverage(loc project) {
  // to be done
}

void lineCoverage(loc project) {
  // to be done
}



// Helper function to deal with concrete statement lists
// second arg should be a closure taking a location (of the element)
// and producing the BlockStm to-be-inserted 
BlockStm* putAfterEvery(BlockStm* stms, BlockStm(loc) f) {
  
  Block put(b:(Block)`{}`) = (Block)`{<BlockStm s>}`
    when BlockStm s := f(b@\loc);
  
  Block put((Block)`{<BlockStm s0>}`) = (Block)`{<BlockStm s0> <BlockStm s>}`
    when BlockStm s := f(s0@\loc);
  
  Block put((Block)`{<BlockStm s0> <BlockStm+ stms>}`) 
    = (Block)`{<BlockStm s0> <BlockStm s> <BlockStm* stms2>}`
    when
      BlockStm s := f(s0@\loc), 
      (Block)`{<BlockStm* stms2>}` := put((Block)`{<BlockStm+ stms>}`);

  if ((Block)`{<BlockStm* stms2>}` := put((Block)`{<BlockStm* stms>}`)) {
    return stms2;
  }
}


