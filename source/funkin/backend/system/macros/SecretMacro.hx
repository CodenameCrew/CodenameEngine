package funkin.backend.system.macros;

#if macro
import sys.io.File;
import sys.FileSystem;
import Sys;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import haxe.macro.Context;
#end

@:dox(hide) class SecretMacro {
	static var envPath:String = '.env';
	// A little bit taken from Funkin's base code. Not too much though.
	public static macro function build():Array<Field>
	{
		var contents:Null<String> = !FileSystem.exists(envPath) ? buildEnv() : File.getContent(envPath);

		if (contents == null)
			contents = buildEnv();

		final indivVars:Array<String> = contents.split('\n');

		final envMap:Map<String, String> = [];

		for (varE in indivVars) {
			// If there's no equal sign, or multiple equal signs, we don't process this variable due to errors.
			if (varE.indexOf('=') == -1 || varE.indexOf('=') != varE.lastIndexOf('='))
				continue;

			var titAndVal:Array<String> = varE.split('=');
			envMap.set(titAndVal[0], titAndVal[1]);
		}

		// Now we look at the actual fields to try and match things up.
		final buildFields:Array<Field> = Context.getBuildFields();

		for (fld in buildFields) {
			if (fld.access.contains(AStatic)) switch(fld.kind) {
				case FVar(t, e):
					for (meta in fld.meta) {
						if (meta.name != ':envField')
							continue;

						// Not gonna do the 'mandatoryIfDefined' stuff because that's not necessary!
						// But because we're not fixing what isn't broken, time for null string checks.
						var isNullString:Bool = false;
						switch (t) {
							case TPath(tp):
								if (tp.name == 'Null' && tp.params != null && tp.params.length == 1)
									switch (tp.params[0]) {
										case TPType(TPath(tptp)):
											if (tptp.name == 'String')
											{
												isNullString = true;
											}
										case _:
									}
							case _:
						}

						if (!isNullString)
							Context.fatalError('Field ${fld.name} must be of type Null<String> to use :envField', fld.pos)
						else {
							if (envMap.exists(fld.name))
								buildFields[buildFields.indexOf(fld)].kind = FVar(t, macro $v{envMap.get(fld.name)});
							else
								Sys.println('WARNING: Value for environment variable "${fld.name}" not found.');
						}
					}
				case _:
					// nothing lol
			}
		}
		return buildFields;
	}

	private static function buildEnv():Null<String>
	{
		if (sys.FileSystem.exists(envPath))
			return sys.io.File.getContent(envPath);

		// For future peoples: to append an item to .env, just add it as a new item in this array.
		// Use the format 'NAME_ALL_CAPS=value' - like an ini file!
		var items:Array<String> = ['CODENAME_AES_KEY=${generateKey()}'];
		var finalProd:String = items.join('\n');

		sys.io.File.saveContent(Sys.getCwd() + '\\.env', finalProd);

		return finalProd;
	}

	private static function generateKey():String
	{
		var validChars:String = "0123456789ABCDEF";
		var outputStr:String = '';

		for (i in 0...64)
		{
			outputStr += validChars.charAt(Math.round(Math.random() * 15));
		}
		return outputStr;
	}
}