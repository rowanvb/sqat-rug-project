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
loc jpacman = |project://jpacman-framework/|;

SLOC sloc(loc location) {
	SLOC result = ();
	int total = 0;
	set[loc] files = files(location);
	for (loc file <- files)
	{
		if (/\.java/ := file.path) {
			int count = countLinesOfCodeInFile(file);
			result [file] = count;
			total += count;
		}
	}	
	println(total);
  	return result;
}       

int countLinesOfCodeInFile(loc file)
{
	list[str] lines = readFileLines(file);
	return countLinesOfCode(lines);
}

int countLinesOfCode(list[str] lines){
	return size(lines) - (countNonSourcecodeLines(lines));
}

int countNonSourcecodeLines(list[str] lines)
{
  	numberOfLines = 0;
  	bool isOpened = false;
  	for(str s <- lines){
  		if (isOpened){
  			numberOfLines+=1;
  		}else if (!isOpened && /\s*\/\*.*/ := s){
  			isOpened = true;
  			numberOfLines+=1;
		} else if (!isOpened && /^[\s]*$/ := s){
			numberOfLines += 1;
		} else if (/\/\// := s){
			numberOfLines+=1;
		} if (isOpened && /\*\// := s){
			isOpened = false;
		}
	}
  	return numberOfLines;
}

test bool correctlyCountsNonSourceLinesOfCode()
{
	list[str] lines = [	"/* This method caclulates the greatest common divisor",
						"*/",
						"public int GCD(int a, int b) {",
   					  	"if (b==0)",
   					  	"	return a;",
   					  	"//Recursively call the function",
   						"return GCD(b,a%b);"];
   	return countNonSourcecodeLines(lines) == 3;
}

test bool correctlyCountsSourceLinesOfCode()
{
	list[str] lines = [	"/* This method caclulates the greatest common divisor",
						"*/",
						"public int GCD(int a, int b) {",
   					  	"if (b==0)",
   					  	"	return a;",
   					  	"//Recursively call the function",
   						"return GCD(b,a%b);"];
   	return countLinesOfCode(lines) == 4;
}

test bool singleLineCommentCountedAsNonSourceLines()
{
	list[str] lines = ["// This is a comment"];
	return countNonSourcecodeLines(lines) == 1;
}

test bool multiLineCommentCountedAsNonSourceLines()
{
	list[str] lines = [	"/* This",
						"is",
						"a",
						"multiline",
						"comment */"];
	return countNonSourcecodeLines(lines) == 5;
}

test bool multiCommentCountedAsNonSourceLinse()
{
	list[str] lines = [	"/* This is a multiline comment on one line */"];
	return countNonSourcecodeLines(lines) == 1;
}

test bool noneCommentLinesAreNotCountedAsNonSourceLines()
{
	list[str] lines = [	"This is not a comment",
						"/* This is a comment */",
						"This is also not a comment"];
	return countNonSourcecodeLines(lines) == 1;
}

test bool emptyLinesAreCountedAsNonSourceLines()
{
	list[str] lines = [""];
	return countNonSourcecodeLines(lines) == 1;
}

test bool linesOnlyContainingTabsAreNotCountedAsNonSourceLines(){
	list[str] lines = ["				"];
	return countNonSourcecodeLines(lines) == 1;
}

test bool linesOnlyContainingSpacesAreNotCountedAsNonSourceLines(){
	list[str] lines = ["     "];
	return countNonSourcecodeLines(lines) == 1;
}

test bool emptyLinesInCommentsAreOnlyCountedOnce()
{
	list[str] lines = [	"/* This is the start of a comment",
						"",
						"The previous line was an empty line in a comment",
						"This is the last line of a comment */"];
	return countNonSourcecodeLines(lines) == 4;
}
