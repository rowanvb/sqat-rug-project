module sqat::series1::A1_SLOC_Answers

import sqat::series1::A1_SLOC;
import IO;
import ParseTree;
import String;
import util::FileSystem;
import util::Math;
/* 

Count Source Lines of Code (SLOC) per file:
- ignore comments
- ignore empty lines

Tips
- use locations with the project scheme: e.g. |project:///jpacman/...|
- functions to crawl directories can be found in util::FileSystem
- use the functions in IO to read source files

Answer the following questions:
- what is the biggest file in JPacman?
- what is the total size of JPacman?
- is JPacman large according to SIG maintainability?
- what is the ratio between actual code and test code size?

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

JPacman is considered very small according to the SIG maintainability. ~2500 lines of code is within the interval of 0 - 66k LOC
Java systems with a code size within that interval are considered very small (++)


*/
loc jpac = |project://jpacman-framework|;
loc code = |project://jpacman-framework/src/main|;
loc tests = |project://jpacman-framework/src/test|;

loc getLargestFile(loc location){
	SLOC sloc = sloc(location);
	loc max; int size = 0;
	for (s <- sloc){
		if (sloc[s] > size){
			max = s;
			size = sloc[s];
		}
	}
	return max;
}	  

void compareLocationSizes(loc loc1, loc loc2){
	int size1 = countTotalSize(loc1);
	int size2 = countTotalSize(loc2);
	println("<loc1> has <size1> lines");
	println("<loc2> has <size2> lines");
	real percentage = toReal(size1) / toReal(size1+size2);
	println("<loc1> <percentage*100>%");
	println("<loc1> <(1-percentage)*100>%");
	real ratio  = toReal(size1) / toReal(size2);
	println("ratio = <ratio>:1");
}