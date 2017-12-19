module sqat::series1::A1_SLOC

import IO;
import ParseTree;
import String;
import util::FileSystem;

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

*/

alias SLOC = map[loc file, int sloc];
loc jpacman = |project://jpacman/|;

SLOC sloc() {
	SLOC result = ();
	int total = 0;
	set[loc] files = files(jpacman);
	for (loc l <- files)
	{
		if (/\.java/ := l.path) {
			int cnt = countLinesOfCode(l);
			result [l] = cnt;
			total += cnt;
		}
	}	
	println(total);
  	return result;
}       

int countLinesOfCode(loc file)
{
	list[str] fileLines = readFileLines(file);
	return size(fileLines) - (countNonSourcecodeLines(fileLines));
}      

int countNonSourcecodeLines(list[str] file)
{
  	n = 0;
  	bool isOpened = false;
  	for(str s <- file){
  		if (isOpened)
  			n+=1;
  		else if (!isOpened && /\s*\/\*.*/ := s){
  			isOpened = true;
  			n+=1;
		} else if (!isOpened && /^[\r\t\n]*$/ := s)
			n += 1;
		else if (/\/\// := s)
			n+=1;
		if (isOpened && /\*\// := s){
			isOpened = false;
		}
	}
  	return n;
}

test bool countCommentLines()
{
	loc testInput = |project://sqat-analysis/src/sqat/series1/SLOCTestInput.java|;
	testList = readFileLines(testInput);
	//list[str] testList = ["/* xx ", "this is a comment", "this is another line", "this is a closing line */"];
	println(countCommentLines(testList));
	return countCommentLines(testList) == 12;	
}
		

             