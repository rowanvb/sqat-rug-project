module sqat::series2::A1b_DynCov_Coverage

import sqat::series2::A1b_DynCov_Instrument;
import Java17ish;
import IO;
import ParseTree;
import String;
import util::FileSystem;
import util::Math;
import lang::csv::IO;

rel[str hitString, loc class, loc method, loc line] readLinesFromCSV(loc p){
	loc lineFile = p;
	lineFile.file += "/defined_lines.csv";
	return readCSV(#rel[str hitString, loc class, loc method, loc line],  lineFile);
}

rel[str hitString, loc class, loc method] readMethodsFromCSV(loc p){
	loc metFile = p;
	metFile.file += "/defined_methods.csv";
	return readCSV(#rel[str hitString, loc class, loc method],  metFile);
}

list[str] readHitInfoFromCSV(loc p){
	loc coverageFile = p;
	coverageFile.file += "/coverage_data.csv";
	str allHits = readFile(coverageFile);
	return split(",", allHits);
}

rel[loc method, bool coverage] methodCoverage(loc p = |project://jpacman-framework|) {
	loc coverageFolder = updateAuthority(p);
	coverageFolder.path = "sqat_coverage";
  	rel[str hitString, loc class, loc method] methods = readMethodsFromCSV(coverageFolder);
  	list[str] hits = readHitInfoFromCSV(coverageFolder);
  	return { <method.m, (method.hs in hits)> | tuple[str hs, loc c, loc m] method <- methods };
}

rel[loc method, loc line, bool coverage] lineCoverage(loc p = |project://jpacman-framework|) {
  	loc coverageFolder = updateAuthority(p);
	coverageFolder.path = "sqat_coverage";
  	rel[str hitString, loc class, loc method, loc line] lines = readLinesFromCSV(coverageFolder);
  	list[str] hits = readHitInfoFromCSV(coverageFolder);
  	return { <line.m, line.l, (line.hs in hits)> | tuple[str hs, loc c, loc m, loc l] line <- lines };
}



