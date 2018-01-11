module sqat::series1::A2_McCabe

import lang::java::jdt::m3::AST;
import sqat::series1::A1_SLOC;
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

alias CycComp = rel[loc method, int complexity];					// When a map is used only string representation of location is stored
alias CycCompDistribution = map[int complexity, int frequency];

CycComp McCabe(loc location){
	bool collectBindings = false;	//Exact naming or types of expressions not needed 
	set[Declaration] declarations = createAstsFromEclipseProject(location, collectBindings); 
	
	CycComp complexity ={};
	
	top-down visit(declarations)	{
		case statement : \method(Type \return, str n, list[Declaration] p, list[Expression] e, Statement impl) : complexity[statement.src] = computeMethodComplexity(impl);
	}
	
	return complexity;
}

CycCompDistribution McCabeDistribution(CycComp complexities) {
  	CycCompDistribution distribution = ();
  	for (complexity <- complexities){
  		int count = complexity.complexity;
  		if (count notin distribution){
  			distribution[count] = 0;
  		}
  		distribution[count] += 1;
	}
  	return distribution;
}

int computeMethodComplexity(Statement method){
	int complexity = 1;
	top-down visit(method) {
		case \if(Expression condition, Statement thenBranch) : complexity += 1;
		case \if(Expression condition, Statement thenBranch, Statement elseBranch) : complexity += 1;
		case \case(Expression expression) : complexity += 1;
		case \for(list[Expression] initializers, Expression condition, list[Expression] updaters, Statement body) : complexity += 1;
	    	case \for(list[Expression] initializers, list[Expression] updaters, Statement body) : complexity += 1;
	    	case \foreach(Declaration parameter, Expression collection, Statement body) : complexity += 1;
	    	case \while(Expression condition, Statement body) : complexity += 1;
		case \infix(Expression lhs, str operator, Expression rhs) : {
			if( operator == "||" || operator == "&&")
				complexity += 1;
		}
	}
	return complexity;
}

// EXERCISE QUESTIONS
set[loc] highestComplexityMethods(loc location){
	CycComp complexities = McCabe(location);
	set[loc] locations = {};
	int maxComplexity = 0;
	for(complexity <- complexities){
		int complexityScore = complexity.complexity;
  		if(complexityScore > maxComplexity){
  			locations = {complexity.method};
  			maxComplexity = complexityScore;
  		} else if(complexityScore == maxComplexity) {
  			locations = locations + complexity.method;
  		}
	}
	return locations;
}

map[str level,  real percentage] percentagesOfRiskLevel(loc location){
	CycComp complexities = McCabe(location);

	map[str level, real percentage] percentages = ("very high" : 0.0, "high" : 0.0, "moderate" : 0.0 , "low" : 0.0);
	real total = 0.0;
	for(complexity <- complexities){
		int complexityScore = complexity.complexity;
		SLOC s = sloc(complexity.method);
		int lines = getOneFrom( [*s.sloc]);
		if(complexityScore < 11) {
			percentages["low"] += lines;
		} else if(complexityScore < 21) {
			percentages["moderate"] += lines ;
		} else if(complexityScore < 51) {
			percentages["high"] += lines ;
		} else {
			percentages["very high"] += lines;
		}
		total += lines;
	}
	for(level <- percentages){
		percentages[level] = (percentages[level] / total) * 100;
	}
	
	return percentages;
} 


/*
* The function below is used in the testing methods to translate the body of a method into a statement
*/
Statement translateIntoStatement(str body){
	loc l = |project://sqat-analysis/src/sqat/series1/test.java|;		//Required, but not used
	str s = 	"public class test {
			'	public void testMethod() {
			'		<body>
			'	}
			'}";
	Declaration d = createAstFromString(l, s, true);
	top-down-break visit(d){
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) : return impl;
	}
	return \null() ;
}

// =================== COUNTED TESTS ======================
test bool ifCounted(){
	str body = 	"if(true) {		//	+1
				' 	int x = 0;
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 2;
}

test bool ifWithElseCounted(){
	str body = 	"if(true) {		//	+1
				' 	int x = 0;
				'} else { 
				'	int y = 0;
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 2;
}

test bool casesInSwitchCounted(){
	str body = 	"int x = 0;
				'int y;
				'switch(x){
				'	case 0 : y = 0;		// +1
				'	case 1 : y = 1;		// +1
				'	case 2 : y = 2;		// +1
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 4;
}

test bool forLoopCounted(){
	str body = 	"for( int i = 0 ; i \< 10 ; i++) {	// +1
				'	int x = 0;
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 2;
}

test bool forLoopWithoutConditionCounted(){
	str body = 	"for( int i = 0 ; ; i++) {	// +1
				'	int y = 0;
				' 	break;
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 2;
}

test bool foreachCounted(){
	str body = 	"List\<String\> someList = new ArrayList\<String\>();
				'for (String item : someList) {			//+1
		    		'	int y = 0;
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 2;
}

test bool whileCounted(){
	str body = 	"while(true) {			//+1
		    		'	int y = 0;
				'}";	
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 2;
}

test bool booleanAndCounted(){
	str body = 	"bool z = false && false;		//+1
		    		'bool z = false && true;			//+1
		    		'bool z = true && false;			//+1
				'bool z = true && true;			//+1";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 5;
}

test bool booleanOrCounted(){
	str body = 	"bool z = false || false;		//+1
		    		'bool z = false || true;			//+1
		    		'bool z = true || false;			//+1
				'bool z = true || true;			//+1";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 5;
}

// =================== SPECIAL CASE TESTS ======================

test bool booleanCumutativeCounted(){
	str body = 	"bool z = false || true && false; ";		//+1 +1
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 3;
}

test bool breakNotCounted(){
	str body = 	"while(true){		//	+1
				'	if(true) {		//	+1
				'		break;
				'	}
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 3;
}

test bool continueNotCounted(){
	str body = 	"while(true){		//	+1
				'	if(true) {		//	+1
				'		continue;
				'	}
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 3;
}

test bool returnNotCounted(){
	str body = 	"while(true){		//	+1
				'	if(true) {		//	+1
				'		return;
				'	}
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 3;
}

test bool elseNotCounted(){
	str body = 	"if(true) {		//	+1
				' 	int x = 0;
				'} else {
				'	int y = 0;
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 2;
}

test bool doWhileNotCounted(){
	str body = 	"do {
				'	int x = 0;
				'} while(true);";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 1;
}

test bool defaultCaseInSwitchNotCounted(){
	str body = 	"int x = 0;
				'int y;
				'switch(x){
				'	case 0 : y = 0;		// +1
				'	case 1 : y = 1;		// +1
				'	case 2 : y = 2;		// +1
				'	default : y = 3;
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 4;
}

test bool If_ElseIf(){
	str ifInElseBody = 	"if(true) {				// +1
						'	int x = 0;
						'} else{
						'	if(true){			//+1
						'		int y =1;
						'	}
						'}";
	Statement ifInElse = translateIntoStatement(ifInElseBody);
	str elseIfBody = 	"if(true) {				// +1
						'	int x = 0;
						'} else if(true){		//+1
						'	int y =1;
						'}";
	Statement elseIf = translateIntoStatement(elseIfBody);
	return computeMethodComplexity(ifInElse) == computeMethodComplexity(elseIf);
}

test bool If_ElseIf_Else(){
	str ifInElseBody = 	"if(true) {				// +1
						'	int x = 0;
						'} else{
						'	if(true){			//+1
						'		int y = 1;
						'	} else {
						'		int z = 1;	
						'	}
						'}";
	Statement ifInElse = translateIntoStatement(ifInElseBody);
	str elseIfBody = 	"if(true) {				// +1
						'	int x = 0;
						'} else if(true){		//+1
						'	int y = 1;
						'} else {
						'	int z = 1;
						'}";
	Statement elseIf = translateIntoStatement(elseIfBody);
	return computeMethodComplexity(ifInElse) == computeMethodComplexity(elseIf);
}

test bool IfInCase(){
	str body = 	"int x = 0;
				'int y;
				'switch(x){
				'	case 0 : { 			// +1
				'		if(true){		// +1
				'			y = 3;
				'		}
				'	}
				'	default : y = 3;
				'}";
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 3;
}
