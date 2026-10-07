package funkin.mobile;

#if android
import lime.system.JNI;
#end

class BootStatus {
	#if android
	static var setStatus:Dynamic;
	#end

	public static function set(text:String) {
		#if android
		try {
			if (setStatus == null)
				setStatus = JNI.createStaticMethod("com/yoshman29/codenameengine/MobileActivity", "setBootStatus", "(Ljava/lang/String;)V");
			setStatus(text);
		} catch (e:Dynamic) Logs.warn('Could not set boot status: $e');
		#end
	}

	public static function report(artShown:Bool) {
		#if android
		var shaderError:String = @:privateAccess openfl.display.Shader.__lastProgramError;
		if (shaderError != null)
			set("shader failed " + (shaderError.length > 400 ? shaderError.substr(0, 400) : shaderError));
		else if (!artShown)
			set("no art " + Paths.image("menus/titlescreen/logo"));
		else
			set("");
		#end
	}
}
