module sqat::series1::A3_CheckStyle_Answers

import sqat::series1::A3_CheckStyle;
import Java17ish;
import Message;
import ParseTree;
import util::FileSystem;
import IO;
import lang::java::jdt::m3::AST;
import util::ResourceMarkers;
import String;
import Set;

/*

Assignment: detect style violations in Java source code.
Select 3 checks out of this list:  http://checkstyle.sourceforge.net/checks.html
Compute a set[Message] (see module Message) containing 
check-style-warnings + location of  the offending source fragment. 

Checks:
	- MethodNaming
	- LineLength (100)
	- StarImport
	- Controlflow statement bodies without opening curly brace
	
Plus: invent your own style violation or code smell and write a checker.

Note: since concrete matching in Rascal is "modulo Layout", you cannot
do checks of layout or comments (or, at least, this will be very hard).

JPacman has a list of enabled checks in checkstyle.xml.
If you're checking for those, introduce them first to see your implementation
finds them.

Questions
- for each violation: look at the code and describe what is going on? 
  Is it a "valid" violation, or a false positive?

Tips 

- use the grammar in lang::java::\syntax::Java15 to parse source files
  (using parse(#start[CompilationUnit], aLoc), in ParseTree)
  now you can use concrete syntax matching (as in Series 0)

- alternatively: some checks can be based on the M3 ASTs.

- use the functionality defined in util::ResourceMarkers to decorate Java 
  source editors with line decorations to indicate the smell/style violation
  (e.g., addMessageMarkers(set[Message]))

Bonus:
- write simple "refactorings" to fix one or more classes of violations 

*/
