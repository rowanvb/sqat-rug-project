module sqat::series1::A2_McCabe

import lang::java::jdt::m3::AST;
import ParseTree;
import String;
import util::FileSystem;
import IO;

/*

Construct a distribution of method cylcomatic complexity. 
(that is: a map[int, int] where the key is the McCabe complexity, and the value the frequency it occurs)


Questions:
- which method has the highest complexity (use the @src annotation to get a method's location)

- how does pacman fare w.r.t. the SIG maintainability McCabe thresholds?

- is code size correlated with McCabe in this case (use functions in analysis::statistics::Correlation to find out)? 
  (Background: Davy Landman, Alexander Serebrenik, Eric Bouwers and Jurgen J. Vinju. Empirical analysis 
  of the relationship between CC and SLOC in a large corpus of Java methods 
  and C functions Journal of Software: Evolution and Process. 2016. 
  http://homepages.cwi.nl/~jurgenv/papers/JSEP-2015.pdf)
  
- what if you separate out the test sources?

Tips: 
- the AST data type can be found in module lang::java::m3::AST
- use visit to quickly find methods in Declaration ASTs
- compute McCabe by matching on AST nodes

Sanity checks
- write tests to check your implementation of McCabe

Bonus
- write visualization using vis::Figure and vis::Render to render a histogram.

*/

set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman|, true); 

alias CC = rel[loc method, int cc];

void main(){
	set[Declaration] decs = jpacmanASTs();
	CC cc = {};
	visit(decs) {
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions) :
			println(name);		
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) :
		{	print(name); print(" has "); println(countStatements(impl)); }
	}
}

int countStatements(Statement s){
	int n = 1;
	top-down visit(s) {
		case \if(Expression condition, Statement thenBranch) : n += 1;
		case \if(Expression condition, Statement thenBranch, Statement elseBranch) : n += 1;
		case \case(Expression expression) : n += 1; 
		case \defaultCase() : n += 1; 
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body) : n += 1;
	    	case \for(list[Expression] initializers, list[Expression] updaters, Statement body) : n += 1;
	    	case \while(Expression condition, Statement body) : n += 1;
	    	case \do(Statement body, Expression condition) : n += 1;
	    	case Expression : println("Expression");
	    /*	case \break() : n += 1;
	    	case \break(str label) : n += 1;
	    	case \continue() : n += 1;
	    	case \continue(str label) : n += 1;  */  	
	}
	// returned 1 als ie niets matched?..
	return n;
}

CC cc(set[Declaration] decls) {
  CC result = {};
  
  // to be done
  
  return result;
}

alias CCDist = map[int cc, int freq];

CCDist ccDist(CC cc) {
  // to be done
}


// =================== NOT COUNTED TESTS ======================
/*
while(true){		+1
	if(true) {	+1
		break;
	}
}
*/
test bool breakNotCounted(){
	Statement s = \while(\booleanLiteral(true), \if(\booleanLiteral(true), \break()));
	return countStatements(s) == 3;
}

/*
while(true){		+1
	if(true) {	+1
		continue;
	}
}
*/
test bool continueNotCounted(){
	Statement s = \while(\booleanLiteral(true), \if(\booleanLiteral(true), \continue()));
	return countStatements(s) == 3;
}

/*
while(true){		+1
	if(true) {	+1
		return;
	}
}
*/
test bool returnNotCounted(){
	Statement s = \while(\booleanLiteral(true), \if(\booleanLiteral(true), \return()));
	return countStatements(s) == 3;
}

/*
if(true) { +1
	//BLANK
} else {
	//BLANK
}
*/
test bool ElseNotCounted(){
	Statement s = \if(\booleanLiteral(true), \empty(), \empty());
	return countStatements(s) == 2;
}

// =================== COUNTED TESTS ======================

/*
if(true){	+1
	//BLANK
}
*/
test bool IfCounted(){
	Statement s = \if(\booleanLiteral(true), \empty());
	return countStatements(s) == 2;
}

/*
if(true){	+1
	//BLANK
} else {		
	//BLANK
}
*/
test bool IfWithElseCounted(){
	Statement s = \if(\booleanLiteral(true), \empty(), \empty());
	return countStatements(s) == 2;
}

/*
switch(x){
	case 1: //BLANK		+1
	case 2: //BLANK		+1
	case 3: //BLANK		+1
}
*/
test bool casesInSwitchCounted(){
	Statement s = \switch(\simpleName("x"), [\case(\number("1")), \case(\number("2")), \case(\number("3"))]);
	return countStatements(s) == 4;
}

/*
switch(x){
	case 1: //BLANK		+1
	case 2: //BLANK		+1
	case 3: //BLANK		+1
	default : //BLANK	+1
}
*/
test bool defaultCaseInSwitchCounted(){
	Statement s = \switch(\number("x"), [\case(\number("1")), \case(\number("2")), \case(\number("3")), \defaultCase()]);
	return countStatements(s) == 5;
}

/*
switch(x){
	case 1: //BLANK		+1
	case 2: //BLANK		+1
	case 3: //BLANK		+1
	default : //BLANK	+1
}
test defaultCaseInSwitchCounted(){
	Statement s = \switch(\number("x"), [\case(\number("1")), \case(\number("2")), \case(\number("3")), \defaultCase()]);
	return countStatements(s) == 5;
}*/

/*
bool x = y == 2 && t == 3;
test defaultCaseInSwitchCounted(){
	Statement s = \switch(\number("x"), [\case(\number("1")), \case(\number("2")), \case(\number("3")), \defaultCase()]);
	return countStatements(s) == 5;
}*/



// =================== SPECIAL CASE TESTS ======================

/*
if(true){			+1
	//BLANK
} else {				
	if(true){		+1
		// BLANK
	}				
}

if(true){			+1
	//BLANK
} else if (true) {	+1
	//BLANK
}
*/
test bool If_ElseIf(){
	Statement s = \if(\booleanLiteral(true), \empty(), \if(\booleanLiteral(true), \empty()));
	return countStatements(s) == 3;
}

/*
if(true){			+1
	//BLANK
} else { 
	if(true){		+1
		// BLANK
	} else {	
		// BLANK
	}
}

if(true){			+1
	//BLANK
} else if (true) {	+1
	//BLANK
} else {	
	//BLANK
}
*/
test bool If_ElseIf_Else(){
	Statement s = \if(\booleanLiteral(true), \empty(), \if(\booleanLiteral(true), \empty(), \empty()));
	return countStatements(s) == 3;
}

/*
switch(x){
	case 1 : if(true) { 		+1 	+1
				//BLANK 
			}
	default: //BLANK 		+1
				
}
*/
test bool IfInCase(){
	Statement s = \switch(\simpleName("x"), [\case(\number("1")), \if(\booleanLiteral(true), \empty()), \defaultCase()]);
	return countStatements(s) == 4;
}
