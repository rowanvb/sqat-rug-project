module sqat::series2::A2_CheckArch

import sqat::series2::Dicto;
import lang::java::jdt::m3::Core;
import util::FileSystem;
import Message;
import ParseTree;
import IO;
import String;
import Set;


/*

This assignment has two parts:
- write a dicto file (see example.dicto for an example)
  containing 3 or more architectural rules for Pacman
  
- write an evaluator for the Dicto language that checks for
  violations of these rules. 

Part 1  

An example is: ensure that the game logic component does not 
depend on the GUI subsystem. Another example could relate to
the proper use of factories.   

Make sure that at least one of them is violated (perhaps by
first introducing the violation).

Explain why your rule encodes "good" design.

Rules: 
nl.tudelft.jpacman.game.Game cannot depend nl.tudelft.jpacman.game.SinglePlayerGame
nl.tudelft.jpacman.game.SinglePlayerGame must inherit nl.tudelft.jpacman.game.Game

- no circular dependencies

nl.tudelft.jpacman.game.GameFactory must instantiate nl.tudelft.jpacman.game.SinglePlayerGame
nl.tudelft.jpacman.level.LevelFactory must instantiate nl.tudelft.jpacman.level.Level
nl.tudelft.jpacman.board.BoardFactory canonly instantiate nl.tudelft.jpacman.board.Board

- Factories instantiating their corresponding model classes, also not instantiating other models. (which fails)

nl.tudelft.jpacman.game cannot depend nl.tudelft.jpacman.ui
nl.tudelft.jpacman.board cannot depend nl.tudelft.jpacman.ui
nl.tudelft.jpacman.level cannot depend nl.tudelft.jpacman.ui
nl.tudelft.jpacman.npc cannot depend nl.tudelft.jpacman.ui

- model packages not depending on the ui
  
Part 2:  
 
Complete the body of this function to check a Dicto rule
against the information on the M3 model (which will come
from the pacman project). 

A simple way to get started is to pattern match on variants
of the rules, like so:

switch (rule) {
  case (Rule)`<Entity e1> cannot depend <Entity e2>`: ...
  case (Rule)`<Entity e1> must invoke <Entity e2>`: ...
  ....
}

Implement each specific check for each case in a separate function.
If there's a violation, produce an error in the `msgs` set.  
Later on you can factor out commonality between rules if needed.

The messages you produce will be automatically marked in the Java
file editors of Eclipse (see Plugin.rsc for how it works).

Tip:
- for info on M3 see series2/A1a_StatCov.rsc.

Questions
- how would you test your evaluator of Dicto rules? (sketch a design)
    - In general, 'must' and 'cannot' are their exact opposites. This means that either must or cannot should result in true. 
        therefore, every test that evaluates a 'must' rule, should also evaluate 'cannot'.
    - A small design should be setup with classes that satisfy a test rule and classes that don't satisfy a rule.
        - i.e. a MVC design where a package with models does not depend on the view
        - a factory class where objects of its corresponding model are instantiated
    - for imports: a class importing 1 class, a class importing multiple classes.
    - for method invocations, a method invoking multiple methods, and one invoking a single method.
    - for invocations, same story


- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 
  
  Additional Rules: 
    - 'inherit', useful for enforcing 'impl' classes to inherit their corresponding interface
    - 'catch/throw' very useful to ensure that all exceptions that are thrown are caught correctly
    - rules in the form of 'Entity Modality Property'
        - i.e. fields of x must be private, enforcing encapsulation
    - not a Rule, but an option to only select interfaces/classes in packages
    - adding logic constructs 
    
- package -> all java files in package 
*/
M3 m3() = createM3FromEclipseProject(|project://jpacman/src|);
 
set[Message] main() {
	loc dicto = |project://sqat-analysis/src/sqat/series2/example.dicto|;
	return eval(parse(#start[Dicto], dicto), createM3FromEclipseProject(|project://jpacman/src|));
}

set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);

set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) = ( {} | it + eval(r, m3) | r <- rules );
  
set[Message] eval(Rule rule, M3 m3) {
    bool isValid = false;
    if ((Rule)`<Entity e1> <Modality m> <Relation r> <Entity e2>` := rule) {
		switch(r) {
			case (Relation)`import` 		: isValid = validateImports(e1, m, e2, m3);
			case (Relation)`depend` 		: isValid = validateDepends(e1, m, e2, m3);
			case (Relation)`invoke` 		: isValid = validateInvoke(e1, m, e2, m3);
			case (Relation)`instantiate` 	: isValid = validateInstantiation(e1, m, e2, m3);	
			case (Relation)`inherit` 		: isValid = validateExtends(e1, m, e2, m3);
		}
		return ( {} | it + warning("<rule> is invalid!", location) | location <- entityToLocs(e1, m3), !isValid );
	}
	return { warning("<rule> is of a wrong format", rule@\loc) };
}

bool validateDepends(Entity e1, Modality m, Entity e2, M3 m3) 
	= all(l <- entityToLocs(e1, m3), validate(entityToLocs(e2, m3), m, getDepends(l, m3)));
	
bool validateExtends(Entity e1, Modality m, Entity e2, M3 m3) 
	= all(l <- entityToLocs(e1, m3), validate(entityToLocs(e2, m3), m, getExtends(l, m3)));

bool validateImports(Entity e1, Modality m, Entity e2, M3 m3) 
	= all(l <- entityToLocs(e1, m3), validate(entityToLocs(e2, m3), m, getImports(l, m3)));
	
bool validateInvoke(Entity e1, Modality m, Entity e2, M3 m3)
	= all(l <- entityToLocs(e1, m3), validate(entityToLocs(e2, m3), m, getInvocations(l, m3)));
	
bool validateInstantiation(Entity e1, Modality m, Entity e2, M3 m3)
	= all(l <- entityToLocs(e1, m3), validateConstructorsFromSet(entityToLocs(e2, m3), m, getInstantiations(l, m3), m3));

bool validateConstructorsFromSet(set[loc] locations, Modality m, set[loc] instantiations, M3 m3) 
    = all(location <- locations, validateConstructors(getConstructors(location, m3), m, instantiations));

bool validateConstructors(set[loc] constructors, Modality m, set[loc] instantiations) {
    switch (m) {
        // there must be a instantiation in the set of constructors
        case (Modality)`must`: return any(instantiation <- instantiations, validate(instantiation, (Modality)`must`, constructors));
        case (Modality)`may`: return true; // may implies nothing?
        // no instantiation can be in the set of constructors
        case (Modality)`cannot`: return all(instantiation <- instantiations, validate(instantiation, (Modality)`cannot`, constructors));
        // all instantiations must be in the set of constructors
        case (Modality)`canonly`: return all(instantiation <- instantiations, validate(instantiation, (Modality)`must`, constructors));
    }
}
    
bool validate(set[loc] locations1, Modality modality, set[loc] locations2) 
    = all(l <- locations1, validate(l, modality, locations2));

bool validate(loc location, Modality modality, set[loc] locations) {
	switch (modality) {
		case (Modality)`must`: return location in locations;
		case (Modality)`may`: return true; // may implies nothing?
		case (Modality)`cannot`: return location notin locations;
		case (Modality)`canonly`: return size(locations) == 1 && validate(location, (Modality)`must`, locations);
	}
}

set[loc] getExtends(loc l, M3 m3) = m3.extends[l];

set[loc] getDepends(loc l, M3 m3) = m3.typeDependency[l];

set[loc] getImports(loc l, M3 m3) = getFileImports(getUriFromLoc(l, m3), m3);

set[loc] getInvocations(loc l, M3 m3){
	if (isClass(l)) {
		return ( {} | it + theMethod | loc theMethod <- m3.methodInvocation[methods(m3, l)] ); 
	}
	return m3.methodInvocation[l];
}

set[loc] getInstantiations(loc l, M3 m3) = ( {} | it + constructor | constructor <- getInvocations(l, m3), isConstructor(constructor));

set[loc] getConstructors(loc l, M3 m3) = constructors(m3, l);

set[loc] getFileImports(loc l, M3 m3) {
	list[str] lines;
	try 
		lines = readFileLines(l);
	catch PathNotFound(loc e) : {
		println(error("Couldn\'t find <e>", e));
		return {};
	}
	catch IO(str msg) : {
		println(error(msg, l));
		return {};
	}
	return ({} | it + (|java+class:///| + replaceAll(name, ".", "/")) | line <- lines, /import \s*<name:[\w|(\.w)]*>/ := line);
}

loc getUriFromLoc(loc l, M3 m3) {
	set[loc] locs = m3.declarations[l];
	if (size(locs) == 1) {
		loc l = getOneFrom(locs);
 		return |<l.scheme>://<l.authority>| + l.path; 
	}
	return l;
}

set[loc] entityToLocs(Entity e, M3 m3) {
    if (e is methodWithParams) {
        if (/<package:[^(\:\:)]*>/ := toString(e) && /<method:\:\:.*>/m := toString(e)) {
            return {|java+method:///| + replaceAll(package, ".", "/") + replaceAll(method, "::", "/") };
        } else {
            return {|java+method:///| + replaceAll(replaceAll(toString(e), ".", "/"), "::", "/") };
        }
    }
	str location = replaceAll(toString(e), ".", "/");
	if (e is method)
		return {|java+method:///| + replaceAll(location, "::", "/") + "()"};
    if (e is classOrPackage) {
		if (|java+package:///| + location in packages(m3))
			return packageElementsToLocs(elements(m3,|java+package:///| + location), m3);
		return {(|java+interface:///| + location in interfaces(m3) ? |java+interface:///| + location : |java+class:///| + location)};
	}
}

set[loc] packageElementsToLocs(set[loc] elems, M3 m3) 
	= ( {} | it + (|java+interface:///| + elem.path in interfaces(m3) ? |java+interface:///| + replaceAll(replaceAll(elem.path, ".java", ""), "src/main/java/", "") : 
	|java+class:///| + replaceAll(replaceAll(elem.path, ".java", ""), "src/main/java/", "") )| loc elem <- elems);

str toString( &T t) = "<t>";