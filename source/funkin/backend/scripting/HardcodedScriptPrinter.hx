/*
 * Copyright (C)2008-2017 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package funkin.backend.scripting;
#if HARDCODED_SCRIPTS

import hscript.Tools;
import hscript.Expr;
import hscript.Printer;

class HardcodedScriptPrinter {

	var script:HScript;
	var parentInstanceFields:Array<String> = [];
	var currentFuncParams:Array<Array<String>> = [];
	var currentForParams:Array<Array<String>> = [];

	var staticFields:Array<String> = [];
	var publicFields:Array<String> = [];

	var usedPublic:Array<String> = [];
	var usedPublicTypes:Array<String> = [];
	var usedStatic:Array<String> = [];
	var usedStaticTypes:Array<String> = [];
	var usedDynamic:Array<String> = [];
	var usedDynamicTypes:Array<String> = [];

	var imports:Array<String> = [];
	var usings:Array<String> = [];
	var funcStack:Int = 0;

	var funcsToForcePublicOverride = [
		"update", "draw", "destroy"
	];

	var defaultFuncArgTypes:Map<String, Array<String>> = [
		"preUpdate" => ["Float"],
		"update" => ["Float"],
		"postUpdate" => ["Float"],
		"stepHit" => ["Int"],
		"beatHit" => ["Int"],
		"measureHit" => ["Int"],
		"draw" => ["DrawEvent"],
		"postDraw" => ["DrawEvent"],
		"onResize" => ["ResizeEvent"],
		"gameResized" => ["Int", "Int"],
		"preStateCreate" => ["FlxState"],
		"onDance" => ["DanceEvent"],
		"onTryDance" => ["CancellableEvent"],
		"onPlaySingAnim" => ["DirectionAnimEvent"],
		"playSingAnimUnsafe" => ["DirectionAnimEvent"],
		"onPlayAnim" => ["PlayAnimEvent"],
		"onGetCamPos" => ["PointEvent"],
		"onPreGenerateStrums" => ["AmountEvent"],
		"onPostGenerateStrums" => ["AmountEvent"],
		"onRatingUpdate" => ["RatingUpdateEvent"],
		"onStartCountdown" => ["CancellableEvent"],
		"onCountdown" => ["CountdownEvent"],
		"onPostCountdown" => ["CountdownEvent"],
		"onSubstateOpen" => ["StateEvent"],
		"onSubstateClose" => ["StateEvent"],
		"onStateSwitch" => ["StateEvent"],
		"onGamePause" => ["CancellableEvent"],
		"onCameraMove" => ["CamMoveEvent"],
		"onEvent" => ["EventGameEvent"],
		"onPostEvent" => ["EventGameEvent"],
		"onGameOver" => ["GameOverEvent"],
		"onPostGameOver" => ["GameOverEvent"],
		"onSongEnd" => ["CancellableEvent"],
		"onPlayerMiss" => ["NoteMissEvent"],
		"onPostPlayerMiss" => ["NoteMissEvent"],
		"onNoteHit" => ["NoteHitEvent"],
		"onPlayerHit" => ["NoteHitEvent"],
		"onDadHit" => ["NoteHitEvent"],
		"onHealthIconAnimChange" => ["HealthIconChangeEvent"],
		"onNoteCreation" => ["NoteCreationEvent"],
		"onPostNoteCreation" => ["NoteCreationEvent"],
		"onSplashShown" => ["SplashShowEvent"],
		"onStageXMLParsed" => ["StageXMLEvent"],
		"onStageNodeParsed" => ["StageNodeEvent"],
		"onPostStageCreation" => ["StageXMLEvent"],
		"onStageDestroy" => ["Stage"],
		"onInputUpdate" => ["InputSystemEvent"],
		"onStrumCreation" => ["StrumCreationEvent"],
		"onPostStrumCreation" => ["StrumCreationEvent"]
	];

	var buf : StringBuf; 
	var tabs : String;

	public function new(script:HScript) {
		this.script = script;
		if (script != null && script.interp.scriptObject != null) {
			parentInstanceFields = Type.getInstanceFields(Type.getClass(script.interp.scriptObject));
		}
	}

	public function exprToString( e : Expr ):String {
		buf = new StringBuf();
		tabs = "";
		expr(e);
		return buf.toString();
	}

	public function typeToString( t : CType ):String {
		buf = new StringBuf();
		tabs = "";
		type(t);
		return buf.toString();
	}

	inline function add<T>(s:T):Void buf.add(s);

	function type( t : CType ):Void {
		switch( t ) {
		case CTOpt(t):
			add('?');
			type(t);
		case CTPath(path, params):
			add(path.join("."));
			if( params != null ) {
				add("<");
				var first = true;
				for( p in params ) {
					if( first ) first = false else add(", ");
					type(p);
				}
				add(">");
			}
		case CTNamed(name, t):
			add(name);
			add(':');
			type(t);
		case CTFun(args, ret) if (Lambda.exists(args, function (a) return a.match(CTNamed(_, _)))):
			add('(');
			for (a in args)
				switch a {
					case CTNamed(_, _): type(a);
					default: type(CTNamed('_', a));
				}
			add(')->');
			type(ret);
		case CTFun(args, ret):
			if( args.length == 0 )
				add("Void -> ");
			else {
				for( a in args ) {
					type(a);
					add(" -> ");
				}
			}
			type(ret);
		case CTAnon(fields):
			add("{");
			var first = true;
			for( f in fields ) {
				if( first ) { first = false; add(" "); } else add(", ");
				add(f.name + " : ");
				type(f.t);
			}
			add(first ? "}" : " }");
		case CTParent(t):
			add("(");
			type(t);
			add(")");
		case CTExpr(e):
			expr(e);
		}
	}

	function addType( t : CType ):Void {
		if( t != null ) {
			add(" : ");
			type(t);
		}
	}

	function expr( e : Expr ):Void {
		if( e == null ) {
			add("??NULL??");
			return;
		}
		switch(Tools.expr(e)) {
		case EPackage(n):
			/*
			add('package');
			if(n != null)
				add(' $n');
			add(';\n');
			*/
		case EImport(c, n, u):
			//var str = '${u ? 'using' : 'import'} $c';
			//if(n != null)
				//str += ' as $n';

			if (u) {
				usings.push(c + (n != null ? ' as $n' : ''));
			} else {
				imports.push(c);
			}
			
			//add('${u ? 'using' : 'import'} $c');
			//if(n != null)
				//add(' as $n');
		case EClass(name, fields, extend, interfaces, fnal):
			/*
			var isFinal = fnal != null && fnal;
			if(isFinal)
				add('final ');
			add('class $name');
			if (extend != null)
				add(' extends $extend');
			for(_interface in interfaces) {
				add(' implements $_interface');
			}
			tabs += "\t";
			add(" {\n");
			for( e in fields ) {
				add(tabs);
				expr(e);
				//add(";\n");
			}
			//for(field in fields) {
			//	expr(field);
			//}

			tabs = tabs.substr(1);
			add("}");
			*/
		case EEnum(en, _):
			/*
			add('enum ${en.name}');
			if(en.fields.length == 0) {
				add(' {}');
				return;
			}
			tabs += "\t";
			add(" {\n");

			for(e in en.fields) {
				add(tabs);
				add(e.name);
				if(e.args.length > 0) {
					add("(");
					var first = true;
					for( a in e.args ) {
						if( first ) first = false else add(", ");
						if( a.opt ) add("?");
						add(a.name);
						addType(a.t);
					}
					add(')');
				}
				add(";\n");
			}

			tabs = tabs.substr(1);
			add("}");
			*/
		case ECast(e, t):
			var safe = t != null;
			add("cast ");
			if(safe) add("(");
			expr(e);
			if(safe) {
				add(", ");
				addType(t);
				add(")");
			}
		case ERegex(e, f):
			add('~/$e/$f');
			add(';\n');
		case EConst(c):
			switch( c ) {
			case CInt(i): add(i);
			case CFloat(f): add(f);
			case CString(s): add('"'); add(s.split('"').join('\\"').split("\n").join("\\n").split("\r").join("\\r").split("\t").join("\\t")); add('"');
			}
		case EIdent(v):

			var isLocal:Bool = false;
			for (f in currentFuncParams) {
				if (f.contains(v)) {isLocal = true; break;}
			}
			for (f in currentForParams) {
				if (f.contains(v)) {isLocal = true; break;}
			}

			if (v == "this") v = "parent";

			if (isLocal) {
				add(v);
			} else if (parentInstanceFields.contains(v) || parentInstanceFields.contains("get_" + v)) {
				add("parent.");
				add(v);
			} else if (script.interp.publicVariables.exists(v)) {
				add(v);
				if (!usedPublic.contains(v)) {
					usedPublic.push(v);
					usedPublicTypes.push(getVarTypeName(script.interp.publicVariables.get(v)));
				}
			} else if (Script.staticVariables.exists(v)) {
				add(v);
				if (!usedStatic.contains(v)) {
					usedStatic.push(v);
					usedStaticTypes.push(getVarTypeName(Script.staticVariables.get(v)));
				}
			} else if (script.trackedSets.contains(v)) {
				add(v);
				if (!usedDynamic.contains(v)) {
					usedDynamic.push(v);
					usedDynamicTypes.push(getVarTypeName(script.get(v)));
				}
			} else {
				add(v);
			}
		case EVar(n, t, e, p, s, pr, isFinal, isInline, get, set, _):
			var name = n;
			if (funcStack == 0) {
				if (s) {
					add("@:staticVar ");
					staticFields.push(n);
				} else if (p) {
					add("@:publicVar ");
					publicFields.push(n);
				}

				if(p) add(""); //disable
				else if(pr) add("private ");
				if(s) add(""); //disable
				if(isInline) add("inline ");
			}
			if(isFinal) add("final " + name);
			else add("var " + name);
			
			if(get != null || set != null) {
				add("(");
				switch(get) {
					case ADefault: add("default, ");
					case ANull: add("null, ");
					case AGet: add("get, ");
					case ADynamic: add("dynamic, ");
					case ANever: add("never, ");
					default:
				}
				switch(set) {
					case ADefault: add("default");
					case ANull: add("null");
					case ASet: add("set");
					case ADynamic: add("dynamic");
					case ANever: add("never");
					default:
				}
				add(")");
			}

			addType(t);
			if( e != null ) {
				add(" = ");
				expr(e);
			}
		case EParent(e):
			add("("); expr(e); add(")");
		case EBlock(el):
			if( el.length == 0 ) {
				add("{}");
			} else {
				tabs += "\t";
				add("{\n");
				for( e in el ) {
					add(tabs);
					expr(e);
					add(";\n");
				}
				tabs = tabs.substr(1);
				add(tabs);
				add("}");
			}
		case EField(e, f, s):
			expr(e);
			add((s == true ? "?." : ".") + f);
		case EBinop(op, e1, e2):
			expr(e1);
			add(" " + op + " ");
			expr(e2);
		case EUnop(op, pre, e):
			if( pre ) {
				add(op);
				expr(e);
			} else {
				expr(e);
				add(op);
			}
		case ECall(e, args):
			if( e == null )
				expr(e);
			else switch( Tools.expr(e)) {
			case EField(_), EIdent(_), EConst(_):
				expr(e);
			default:
				add("(");
				expr(e);
				add(")");
			}
			add("(");
			var first = true;
			for( a in args ) {
				if( first ) first = false else add(", ");
				expr(a);
			}
			add(")");
		case EIf(cond,e1,e2):
			add("if( ");
			expr(cond);
			add(" ) ");
			expr(e1);
			if( e2 != null ) {
				add(" else ");
				expr(e2);
			}
		case EWhile(cond,e):
			add("while( ");
			expr(cond);
			add(" ) ");
			expr(e);
		case EDoWhile(cond,e):
			add("do ");
			expr(e);
			add(" while ( ");
			expr(cond);
			add(" )");
		case EFor(v, it, e, ithv):
			
			if(ithv != null) {
				add("for( "+ithv+" => "+v+" in ");
				currentForParams.push([ithv, v]);
			} else {
				add("for( "+v+" in ");
				currentForParams.push([v]);
			}
			expr(it);
			add(" ) ");
			expr(e);
			currentForParams.pop();
		case EBreak:
			add("break");
		case EContinue:
			add("continue");
		case EFunction(params, e, n, ret, p, s, o, pr, isFinal, isInline):
			var name = n;
			if (funcStack == 0) {
				if (s) {
					add("@:staticVar ");
					staticFields.push(n);
				} else if (p) {
					add("@:publicVar ");
					publicFields.push(n);
				}

				if (funcsToForcePublicOverride.contains(n)) {
					o = true;
					p = true;
				}

				if(o) add("override ");
				if (p) add("public ");
				else if(pr) add("private ");
				if(s) add(""); //disable
				if(isInline) add("inline ");
				if(isFinal) add("final ");
			}
			add("function");
			if( name != null )
				add(" " + name);
			add("(");
			var first = true;
			var funcParamNames:Array<String> = [];
			for( i => a in params ) {
				if( first ) first = false else add(", ");
				if( a.opt ) add("?");
				add(a.name);
				if (a.t == null) {
					if (defaultFuncArgTypes.exists(name)) {
						var arr = defaultFuncArgTypes.get(name);
						if (i < arr.length) add(" : " + arr[i]);
					}
				} else {
					addType(a.t);
				}

				funcParamNames.push(a.name);
			}
			currentFuncParams.push(funcParamNames);
			add(")");
			addType(ret);
			add(" ");
			funcStack++;
			expr(e);
			funcStack--;
			currentFuncParams.pop();
		case EReturn(e):
			add("return");
			if( e != null ) {
				add(" ");
				expr(e);
			}
		case EArray(e,index):
			expr(e);
			add("[");
			expr(index);
			add("]");
		case EArrayDecl(el, _):
			add("[");
			var first = true;
			for( e in el ) {
				if( first ) first = false else add(", ");
				expr(e);
			}
			add("]");
		case ENew(cl, args, params):
			add("new " + cl);
			if(params != null) {
				add("<");
				var first = true;
				for( p in params ) {
					if( first ) first = false else add(", ");
					type(p);
				}
				add(">");
			}
			add("(");
			var first = true;
			for( e in args ) {
				if( first ) first = false else add(", ");
				expr(e);
			}
			add(")");
		case EThrow(e):
			add("throw ");
			expr(e);
		case ETry(e, v, t, ecatch):
			add("try ");
			expr(e);
			add(" catch( " + v);
			addType(t);
			add(") ");
			expr(ecatch);
		case EObject(fl):
			if( fl.length == 0 ) {
				add("{}");
			} else {
				tabs += "\t";
				add("{\n");
				for( f in fl ) {
					add(tabs);
					add(f.name+" : ");
					expr(f.e);
					add(",\n");
				}
				tabs = tabs.substr(1);
				add(tabs);
				add("}");
			}
		case ETernary(c,e1,e2):
			expr(c);
			add(" ? ");
			expr(e1);
			add(" : ");
			expr(e2);
		case ESwitch(e, cases, def):
			add("switch( ");
			expr(e);
			add(") {\n");
			tabs += "\t";
			for( c in cases ) {
				add(tabs);
				add("case ");
				var first = true;
				for( v in c.values ) {
					if( first ) first = false else add(", ");
					expr(v);
				}
				add(": ");
				expr(c.expr);
				add(";\n");
			}
			if( def != null ) {
				add(tabs);
				add("default: ");
				expr(def);
				add(";\n");
			}
			tabs = tabs.substr(1);
			add(tabs);
			add("}");
		case EMeta(name, args, e):
			add("@");
			add(name);
			if( args != null && args.length > 0 ) {
				add("(");
				var first = true;
				for( a in args ) {
					if( first ) first = false else add(", ");
					expr(e);
				}
				add(")");
			}
			add(" ");
			expr(e);
		case ECheckType(e, t):
			add("(");
			expr(e);
			add(" : ");
			addType(t);
			add(")");
		}
	}

	public static function errorToString( e : Error ):String {
		var message = switch( #if hscriptPos e.e #else e #end ) {
			case EInvalidChar(c): "Invalid character: '"+(StringTools.isEof(c) ? "EOF (End Of File)" : String.fromCharCode(c))+"' ("+c+")";
			case EUnexpected(s): "Unexpected token: \""+s+"\"";
			case EUnterminatedString: "Unterminated string";
			case EUnterminatedComment: "Unterminated comment";
			case EInvalidPreprocessor(str): "Invalid preprocessor (" + str + ")";
			case EUnknownVariable(v): "Unknown variable: "+v;
			case EInvalidIterator(v): "Invalid iterator: "+v;
			case EInvalidOp(op): "Invalid operator: "+op;
			case EInvalidAccess(f): "Invalid access to field " + f;
			case ECustom(msg): msg;
			case EInvalidClass(cla): "Invalid class: " + cla + " was not found.";
			case EAlreadyExistingClass(cla): 'Custom Class named $cla already exists.';
		};
		#if hscriptPos
		return e.origin + ":" + e.line + ": " + message;
		#else
		return message;
		#end
	}

	private function getVarTypeName(obj:Dynamic) {
		switch(Type.typeof(obj)) {
			case TBool:
				return "Bool";
			case TInt:
				return "Int";
			case TFloat:
				return "Float";
			case TFunction:
				return "Dynamic"; //use dynamic for now
			case TObject:
				return "Dynamic";
			case TEnum(c):
				return Type.getEnumName(c);
			case TClass(c):
				return Type.getClassName(c);
			default:
				return Type.getClassName(Type.getClass(obj));
		}
		return "Dynamic";
	}

	public static function convertHscript(script:HScript) {
		var printer = new HardcodedScriptPrinter(script);
		var savePath = "scriptOutput/" + script.path.replace("assets/", "");
		var str = printer.exprToString(script.expr);

		var scriptClassName = "Script"; // + script.path.replace("assets/", "").replace("/", "_").replace(" ", "_").replace(".hx", "").replace(".", "");
		var parentClassName:String = Type.getClassName(Type.getClass(script.interp.scriptObject));
		if (parentClassName != null && parentClassName != "null" ) {
			if (!printer.imports.contains(parentClassName)) printer.imports.push(parentClassName);
			var splitPackage = parentClassName.split(".");
			parentClassName = splitPackage[splitPackage.length-1];
		} else {
			parentClassName = "Dynamic";
		}

		var scriptPackageName = script.path.replace("assets/", "").replace(".hx", "");
		scriptPackageName = scriptPackageName.substring(0, scriptPackageName.lastIndexOf("/"));
		scriptPackageName = scriptPackageName.replace("/", ".").replace(" ", "_");
		
		var redirects = Script.getDefaultImportRedirects();
		var importBlacklist:Array<String> = ["Int", "String", "Float"];
		
		var headerStr = "package scripts." + scriptPackageName + ";\n\n";
		for (imp in printer.imports) {
			var i = imp;
			if (importBlacklist.contains(imp)) continue;
			if (redirects.exists(imp)) i = redirects.get(imp);
			headerStr += "import " + i + ";\n";
		}
		for (imp in printer.usings) {
			headerStr += "using " + imp + ";\n";
		}
		headerStr += "import funkin.backend.scripting.HardcodedScript;\n";
		headerStr += "\n";
		headerStr += '@:registerScript("' + script.path.replace("assets/", "") + '")\n';
		headerStr += "class " + scriptClassName + " extends HardcodedScript<" + parentClassName + ">\n";

		var extraClassCode:String = "";

		for (i => field in printer.usedPublic) {
			if (!printer.publicFields.contains(field)) {
				if (extraClassCode == "") extraClassCode = "\n";
				extraClassCode += "\t@:publicVarRef var " + field + ":" + printer.usedPublicTypes[i] + ";\n";
			}
		}
		for (i => field in printer.usedStatic) {
			if (!printer.staticFields.contains(field)) {
				if (extraClassCode == "") extraClassCode = "\n";
				extraClassCode += "\t@:staticVarRef var " + field + ":" + printer.usedStaticTypes[i] + ";\n";
			}
		}
		for (i => field in printer.usedDynamic) {
			if (extraClassCode == "") extraClassCode = "\n";
			extraClassCode += "\t@:dynamicVarRef var " + field + ":" + printer.usedDynamicTypes[i] + ";\n";
		}

		str = str.replace("\t;\n", "");
		if (str.charAt(0) == "{") {
			str = "{" + extraClassCode + str.substring(1);
		} else {
			str = "{\n\t" + extraClassCode + str + "\n}";
		}

		CoolUtil.safeSaveFile(savePath, headerStr + str);
	}
}
#end