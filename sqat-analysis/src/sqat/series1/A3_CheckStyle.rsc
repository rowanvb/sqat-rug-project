module sqat::series1::A3_CheckStyle

import Java17ish;
import Message;
import ParseTree;
import util::FileSystem;
import IO;
import lang::java::jdt::m3::AST;
import util::ResourceMarkers;
import String;
import Set;

set[Message] checkStyle(loc project, int maxLineLength = 100) {
  	set[Message] result = {};
	set[Declaration] AST = createAstsFromEclipseProject(project, true);   	
  	for (loc l <- files(project), l.extension == "java") {
  		result = result + createLineMessages(l, maxLineLength);  	
  		result = result + createImportMessages(l);
  	}
	result = result + createMethodNamingMessages(AST);	
	result = result + createControlFlowMessages(AST);
  	addMessageMarkers(result);
  	return result;
}

set[Message] createControlFlowMessages(set[Declaration] declarations) {
	set[Message] result = {};
	set[loc] statements = {};
	set[loc] elseStatements = {};
	top-down visit (declarations) {    
		case \while(_, Statement body) : 			statements = statements +  body.src;
		case \for(_, _, _, Statement body) : 		statements = statements + body.src;
		case \for(_, _, Statement body) : 			statements = statements + body.src;
		case \foreach(_, _, Statement body) : 		statements = statements + body.src;
		case \try (Statement body, _) : 				statements = statements + body.src;
		case \try (Statement body, _, _) : 			statements = statements + body.src;
		case \catch (_, Statement body) : 			statements + statements + body.src;	
		case \if (_, Statement body) : 				statements = statements + body.src;
		case \if (_, Statement body, Statement e) : { 
			statements = statements + body.src;
			elseStatements = elseStatements + e.src; 
		}
	} 
	for (loc l <- statements) {
		result = result + checkControlFlow(l);
	}
	for (loc l <- elseStatements) {
		result = result + checkElseBranch(l);
	}
	return result;
}

set[Message] createMethodNamingMessages(set[Declaration] declarations) {
	set[Message] result = {};
	map[loc l, str s] methods = ();
  	top-down visit (declarations) {
   	 	case theMethod: \method(_, str name, _, _, _) : 	methods[theMethod.src] = name;
    		case theMethod: \method(_, str name, _, _) : 	methods[theMethod.src] = name;       
	}
	map[loc, str] wrong = wrongMethodNaming(methods);
	for (loc l <- wrong) {
		result = result + warningMessage("Invalid name <wrong[l]>", l);
	}
	return result;
}

map[loc, str] wrongMethodNaming(map[loc, str] methodNames){
	return (l : methodNames[l] | loc l <- methodNames, !(/^[a-z][a-zA-Z0-9]*$/ := methodNames[l]) );
}

set[Message] createLineMessages(loc file, int maxlen) {
	set[Message] result = {};
	list[str] lines = readFileLines(file);
	int pos = 0;
	for (str line <- lines){
		if (size(line) > maxlen)
			result = result + warningMessage("Line is too long <size(line)>", file(pos, size(line), <0,0>, <0,0>));
		pos += size(line) + 2;
	}
	return result;
}

set[Message] createImportMessages(loc file) {
	set[Message] result = {};
	list[str] lines = readFileLines(file);
	int pos = 0;
	for (str line <- lines){
		if (/import/ := line[0..6] && /\*/ := line) 
			result = result + warningMessage("Import * is not allowed <line> ", file(pos, size(line), <0,0>, <0,0>));
		pos += size(line) + 2;
	}
	return result;
}

set[Message] checkControlFlow(loc l) {
	list[str] lines = readFileLines(l);
	str file = listToString(lines);
	set[Message] result = {};
	if (!(/^\{[\W\w]*\}$/m := file))
		result = result + warningMessage("Control flow statement bodies should open with a curly brace on the same line", l);
	return result;
}

set[Message] checkElseBranch(loc l){
	list[str] lines = readFileLines(l);
	str file = listToString(lines);
	set[Message] result = {};
	if (!(/^\{[\W\w]*\}$/m := file || /if/m := file[1..3])) 
		result = result + warningMessage("Control flow statement bodies should open with a curly brace on the same line", l);
	return result;
}

str listToString(list[str] lines) = ( "" | it + "\n" + line | line <- lines );

Message errorMessage(str msg, loc at) {
	return error(msg, at);
}

Message warningMessage(str msg, loc at){
	return warning(msg, at);
}

Message infoMessage(str msg, loc at){
	return info(msg, at);
}

set[Declaration] fileToDeclarationSet(loc file) {
	return {} + createAstFromFile(file, true);
}

// =================== TESTS ======================

test bool correctStatement() {
	set[Declaration] s = fileToDeclarationSet(|project://sqat-analysis/src/sqat/testfiles/CheckStyleInput_1.java|);
	set[Message] messages = createControlFlowMessages(s);
	return size(messages) == 0;
}

test bool statementWithoutCurly() {
	set[Declaration] s = fileToDeclarationSet(|project://sqat-analysis/src/sqat/testfiles/CheckStyleInput_2.java|);
	set[Message] messages = createControlFlowMessages(s);
	return size(messages) == 4;
}

test bool pascalCaseMethodName() {
	set[Declaration] s = fileToDeclarationSet(|project://sqat-analysis/src/sqat/testfiles/CheckStyleInput_3.java|);
	set[Message] messages = createMethodNamingMessages(s);
	return size(messages) == 2;
}

test bool tooLongLine() {
	set[Message] messages = createLineMessages(|project://sqat-analysis/src/sqat/testfiles/CheckStyleInput_1.java|, 100);
	return size(messages) == 2;
}

test bool importStar() {
	set[Message] messages = createImportMessages(|project://sqat-analysis/src/sqat/testfiles/CheckStyleInput_1.java|);
	return size(messages) == 2;
}