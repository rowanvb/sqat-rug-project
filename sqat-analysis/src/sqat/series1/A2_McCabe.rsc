module sqat::series1::A2_McCabe

import lang::java::jdt::m3::AST;
import ParseTree;
import String;
import util::FileSystem;
import IO;

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
		case \if(_, _) : 			complexity += 1;
		case \if(_, _, _) : 			complexity += 1;
		case \case(_) : 				complexity += 1;
		case \for(_, _, _, _) : 		complexity += 1;
	    	case \for(_, _, _) : 		complexity += 1;
	    	case \foreach(_, _, _) : 	complexity += 1;
	    	case \while(_, _) : 			complexity += 1;
		case \catch(_, _) : 			complexity += 1;
		case \infix(_, "&&", _) : 	complexity += 1;
		case \infix(_, "||", _) : 	complexity += 1;
	}
	return complexity;
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

test bool catchCounted(){
	str body = 	"try {			
		    		'	int y = 0;
				'} catch(IOException e) {	// +1
				'	int x = 0;
				'} catch(Exception e) {		// +1
				'	int x = 0;
				'}";	
	Statement s = translateIntoStatement(body);
	return computeMethodComplexity(s) == 3;
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
