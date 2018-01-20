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
- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 
*/
M3 m3() = createM3FromEclipseProject(|project://jpacman/src|);
 
void main() {
	loc dicto = |project://sqat-analysis/src/sqat/series2/example.dicto|;
	eval(parse(#start[Dicto], dicto), createM3FromEclipseProject(|project://jpacman/src|));
}

set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);

set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) 
  = ( {} | it + eval(r, m3) | r <- rules );
  
set[Message] eval(Rule rule, M3 m3) {
  	set[Message] msgs = {};
  	switch(rule) {
	 	case (Rule) `<Entity e1> <Modality m> import <Entity e2>` : (validateImports(e1, m, e2, m3));
	 	//case (Rule) `<Entity e1> <Modality m> depend <Entity e2>` : println(getDepends(e1, m3));
	 	//case (Rule) `<Entity e1> <Modality m> invoke <Entity e2>` : println("invoke");
	 	//case (Rule) `<Entity e1> <Modality m> instantiate <Entity e2>` : println(validateDepends(e1, m, e2, m3));	
	  	//case (Rule) `<Entity e1> <Modality m> inherit <Entity e2>` : println(validateExtends(e1, m, e2, m3));
	}
 	
  // to be done
  
  return msgs;
}

bool validateDepends(Entity e1, Modality m, Entity e2, M3 m3) 
	= all(l <- entityToLoc(e1, m3), validate(entityToLoc(e2, m3), m, getDepends(l, m3)));
	
bool validateExtends(Entity e1, Modality m, Entity e2, M3 m3) 
	= all(l <- entityToLoc(e1, m3), validate(entityToLoc(e2, m3), m, getExtends(l, m3)));

bool validateImports(Entity e1, Modality m, Entity e2, M3 m3) 
	= all(l <- entityToLoc(e1, m3), validate(entityToLoc(e2, m3), m, getImports(l, m3)));

bool validate(set[loc] locations1, Modality modality, set[loc] locations2) 
	= all(l <- locations1, validate(l, modality, locations2));

bool validate(loc location, Modality modality, set[loc] locations) {
	bool valid = false;
	switch (modality) {
		case (Modality)`must`: return location in locations;
		case (Modality)`may`: return true;
		case (Modality)`cannot`: return location notin locations;
		case (Modality)`canonly`: return size(locations) == 1 && validate(location, (Modality)`must`, locations);
	}
}

set[loc] getExtends(loc l, M3 m3) = m3.extends[l];
set[loc] getDepends(loc l, M3 m3) = m3.typeDependency[l];
set[loc] getImports(loc l, M3 m3) = getFileImports(getUriFromLoc(l, m3), m3);

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

set[loc] entityToLoc(Entity e, M3 m3) {
	str location = replaceAll(toString(e), ".", "/");
	if (e is method) {
		str m = replaceAll(location, "::", "/") + "()";
		return {|java+method:///| + m};
	} else if (e is classOrPackage) {
		if (|java+package:///| + location in packages(m3))
			return packageElementsToLoc(elements(m3,|java+package:///| + location), m3);
		return {(|java+interface:///| + location in interfaces(m3) ? |java+interface:///| + location : |java+class:///| + location)};
	} else if (e is methodWithParams) {
		str m = replaceAll(location, "::", "/");
		return {|java+method:///| + m};
	}
}

set[loc] packageElementsToLoc(set[loc] elems, M3 m3) 
	= ( {} | it + (|java+interface:///| + elem.path in interfaces(m3) ? |java+interface:///| + replaceAll(replaceAll(elem.path, ".java", ""), "src/main/java/", "") : 
	|java+class:///| + replaceAll(replaceAll(elem.path, ".java", ""), "src/main/java/", "") )| loc elem <- elems);

str toString( &T t) = "<t>";