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
	visit(decs) {
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions) :
			println(name);		
		case \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) :
		{	print(name); print(" has "); println(countStatements(impl)); }
	}
}

int countStatements(Statement s){
	int n = 1;
	visit(s) {
		case \if(Expression condition, Statement thenBranch) : {
			n += countStatements(thenBranch);
		}
		case \if(Expression condition, Statement thenBranch, Statement elseBranch) : {
			n += countStatements(thenBranch);
			n += countStatements(elseBranch);
		}

		//case \case(Expression expression) : {
		//	println(expression);
		//}
	}
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

test bool breakNotCounted(){
	Statement s = \break();
	return countStatements(s) == 1;
}

test bool nestedIfStatementsCounted(){
	Statement s = \if(\booleanLiteral(true), \if(\booleanLiteral(true), \empty()));
	return countStatements(s) == 3;
}
