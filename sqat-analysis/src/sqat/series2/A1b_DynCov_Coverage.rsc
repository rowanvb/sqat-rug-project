module sqat::series2::A1b_DynCov_Coverage

import sqat::series2::A1b_DynCov_Instrument;
import Java17ish;
import IO;
import ParseTree;
import String;
import util::FileSystem;
import util::Math;
import lang::csv::IO;

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



