module sqat::series2::A1b_DynCov_Instrument

import Java17ish;
import IO;
import ParseTree;
import String;
import util::FileSystem;
import util::Math;
import lang::csv::IO;

loc API_LOCATION = |project://sqat-analysis/src/sqat/series2/coverage_api/CoverageAPI.java|;
ImportDec apiImport = (ImportDec)`import coverage_api.CoverageAPI;`;

loc classLocation;
loc methodLocation;
int methodIndex = 0;
int lineIndex = 0;
rel[str hitString, loc class, loc method] methods = { };
rel[str hitString, loc class, loc method, loc line] lines = { };


// Helper function to deal with concrete statement lists
// second arg should be a closure taking a location (of the element)
// and producing the BlockStm to-be-inserted 
BlockStm* putBeforeEvery(BlockStm* stms, BlockStm(loc) f) {
  
  Block put(b:(Block)`{}`) = (Block)`{<BlockStm s>}`
    when BlockStm s := f(b@\loc);
  
  Block put((Block)`{<BlockStm s0>}`) = (Block)`{<BlockStm s> <BlockStm s0>}`
    when BlockStm s := f(s0@\loc);
  
  Block put((Block)`{<BlockStm s0> <BlockStm+ stms>}`) 
    = (Block)`{<BlockStm s> <BlockStm s0> <BlockStm* stms2>}`
    when
      BlockStm s := f(s0@\loc), 
      (Block)`{<BlockStm* stms2>}` := put((Block)`{<BlockStm+ stms>}`);

  if ((Block)`{<BlockStm* stms2>}` := put((Block)`{<BlockStm* stms>}`)) {
    return stms2;
  }
}

loc updateAuthority(loc project) {
	return project.authority += "-instrumented";
}

loc coverageFolder(loc project){
	loc updated = updateAuthority(project);
	return updated.path += "sqat_coverage";
}

loc methodInfoFile(loc project){
	loc updated = coverageFolder(project);
	return updated.file += "/defined_methods.csv";
}

loc lineInfoFile(loc project){
	loc updated = coverageFolder(project);
	return updated.file += "/defined_lines.csv";
}

loc hitInfoFile(loc project){
	loc updated = coverageFolder(project);
	return updated.file += "/coverage_data.csv";
}

BlockStm apiCallMethodStatement(){
	str hitString  = "m<methodIndex>";
	StringLiteral methodHit = parse(#StringLiteral, "\"m<methodIndex>,\"");
	methods += {<hitString, classLocation, methodLocation>};
	methodIndex += 1;
	return (BlockStm)`CoverageAPI.hit(<StringLiteral methodHit>);`;
}

BlockStm apiCallStatement(loc l) {
	str hitString = "l<lineIndex>";
	StringLiteral lineHit = parse(#StringLiteral, "\"l<lineIndex>,\"");
	lines += {<hitString, classLocation, methodLocation, l>};
	lineIndex += 1;
	BlockStm s = (BlockStm)`CoverageAPI.hit(<StringLiteral lineHit>);`;
	return s;
}

Tree instrumentMethodBodies(Tree tree){
	updated = top-down visit(tree){
		case (ClassDec) `<ClassDecHead head> <ClassBody body>` : { 
			classLocation = head@\loc; 
			insert (ClassDec) `<ClassDecHead head> <ClassBody body>`;
		}
		case (ConstrDec) `<ConstrHead head> <ConstrBody body>` : {
			methodLocation = head@\loc;
			insert (ConstrDec) `<ConstrHead head> <ConstrBody body>`;
		}
		case (MethodDec) `<MethodDecHead head> <MethodBody body>` : {
			methodLocation = head@\loc;
			insert (MethodDec) `<MethodDecHead head> <MethodBody body>`;
		}
		case (ConstrBody) `{ <ConstrInv? i> <BlockStm* stms>}` : {
			BlockStm* s1 = putBeforeEvery(stms, apiCallStatement);
		 	insert (ConstrBody)`{ <ConstrInv? i> <BlockStm* s1>}`;		// NOTE : Not possible to call anything before super()
		}
		case (Block) `{ <BlockStm* s> }` : {
			BlockStm* s1 = putBeforeEvery(s, apiCallStatement);
			insert (Block) `{ <BlockStm* s1> }`;
		}
	}
	return updated;
}

Tree instrumentMethodHeads(Tree tree){
	updated = top-down visit(tree) {
		case (CompilationUnit) `<PackageDec? p> <ImportDec* i> <TypeDec* t>` => (CompilationUnit)`<PackageDec? p> <ImportDec apiImport> <ImportDec* i> <TypeDec* t>`
		case (ClassDec) `<ClassDecHead head> <ClassBody body>` : { 
			classLocation = head@\loc; 
			insert (ClassDec) `<ClassDecHead head> <ClassBody body>`;
		}
		case (ConstrDec) `<ConstrHead head> <ConstrBody body>` : {
			methodLocation = head@\loc;
			insert (ConstrDec) `<ConstrHead head> <ConstrBody body>`;
		}
		case (MethodDec) `<MethodDecHead head> <MethodBody body>` : {
			methodLocation = head@\loc;
			insert (MethodDec) `<MethodDecHead head> <MethodBody body>`;
		}
		case (MethodBody) `{<BlockStm* stms>}` : {
			BlockStm methodApiCall = apiCallMethodStatement();
		 	insert (MethodBody)`{<BlockStm methodApiCall> <BlockStm* stms>}`;
		}
	}
	return updated;
}

void instrumentSourceCodeFile(loc file){
	tree = parse(#start[CompilationUnit], file, allowAmbiguity=true);
	updated = instrumentMethodBodies(tree);
	updated = instrumentMethodHeads(updated);
	writeFile(updateAuthority(file), updated);
}

void handleFile(loc file){
	if(contains(file.path, "src/main/java") && contains(file.file, ".java")){ // Source code
		instrumentSourceCodeFile(file);
	} else {
		list[int] text = readFileBytes(file);
		writeFileBytes(updateAuthority(file), text);
	}
}

void handleDirectory(loc dir){
	mkDirectory(updateAuthority(dir));
	for(f <- dir.ls){
		handle(f);
	}
}

void handle(loc f){
	if(isDirectory(f)){
		handleDirectory(f);
	} else if(isFile(f)){
		handleFile(f);
	}
}

void importAPI(loc p){
	loc api = updateAuthority(p);
	api.path = api.path + "src/main/java/coverage_api";
	mkDirectory(api);
	api.file = api.file + "/CoverageAPI.java";
	str text = readFile(API_LOCATION);
	writeFile(api, text);
}

void writeMethodsToCSV(loc p){
	writeCSV(methods, methodInfoFile(p));
}

void writeLinesToCSV(loc p){
	writeCSV(lines, lineInfoFile(p));
}

void instrumentProject(loc p = |project://jpacman-framework|){
	mkDirectory(updateAuthority(p));
	println("Test");
	mkDirectory(coverageFolder(p));
	println("Test");
	for(loc file <- p.ls){
		handle(file);
	}
	importAPI(p);
	writeMethodsToCSV(p);
	writeLinesToCSV(p);
}
rel[str hitString, loc class, loc method, loc line] readLinesFromCSV(loc p){
	return readCSV(#rel[str hitString, loc class, loc method, loc line],  lineInfoFile(p));
}

rel[str hitString, loc class, loc method] readMethodsFromCSV(loc p){
	return readCSV(#rel[str hitString, loc class, loc method],  methodInfoFile(p));
}

list[str] readHitInfoFromCSV(loc p){
	str allHits = readFile(hitInfoFile(p));
	return split(",", allHits);
}


