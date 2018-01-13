module sqat::series1::A2_McCabe_Answers

import sqat::series1::A2_McCabe;
import sqat::series1::A1_SLOC;
import lang::java::jdt::m3::AST;
import analysis::statistics::Correlation;
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
loc jpac = |project://jpacman-framework|;
loc jpac_notests = |project://jpacman-no-tests|;

set[loc] highestComplexityMethods(loc location){
	CycComp complexities = McCabe(|project://jpacman-framework|);
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

void correlationMcCabeSloc(loc location){
	CycComp complexities = McCabe(location);
	
	lrel[num, num] comparison = [];
	for(complexity <- complexities){
		int complexityScore = complexity.complexity;
		SLOC s = sloc(complexity.method);
		int lines = getOneFrom( [*s.sloc]);
		comparison = <complexityScore, lines> + comparison;
	}
	num pearson = PearsonsCorrelation(comparison);
	num spearman = SpearmansCorrelation(comparison);
	println("Pearsons Correlation : <pearson>");
	println("Spearmans Correlation : <spearman>");
}