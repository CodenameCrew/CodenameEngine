package funkin.backend.system.framerate;

#if TRANSLATIONS_SUPPORT
import funkin.backend.assets.TranslatedAssetLibrary;
#end
import funkin.backend.assets.AssetsLibraryList;
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.ScriptedAssetLibrary;

class AssetTreeInfo extends FramerateCategory {
	private var lastUpdateTime:Float = 1;

	public function new() {
		super("Asset Libraries Tree Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		if ((lastUpdateTime += FlxG.rawElapsed) < 1)
			return;

		lastUpdateTime = 0;

		var text = "Not initialized yet\n";
		if (Paths.assetsTree != null){
			text = "";
			var buf = new StringBuf();
			for(l in Paths.assetsTree.libraries) {
				var l = AssetsLibraryList.getCleanLibrary(l);

				var tag = l.tag.toString().toUpperCase();

				buf.add("[");
				buf.add(tag);
				buf.add("] ");

				var className = Type.getClassName(Type.getClass(l));
				className = className.substr(className.lastIndexOf(".") + 1);

				#if TRANSLATIONS_SUPPORT
				if (l is TranslatedAssetLibrary) {
					buf.add(className);
					buf.add(" - ");
					buf.add(cast(l, TranslatedAssetLibrary).langFolder);
					buf.add(" for (");
					buf.add(cast(l, TranslatedAssetLibrary).forLibrary.modName);
					buf.add(")\n");
				}
				else #end if (l is ScriptedAssetLibrary) {
					buf.add(className);
					buf.add(" - ");
					buf.add(cast(l, ScriptedAssetLibrary).scriptName);
					buf.add(" (");
					buf.add(cast(l, ScriptedAssetLibrary).modName);
					buf.add(" | ");
					buf.add(cast(l, ScriptedAssetLibrary).libName);
					buf.add(" | ");
					buf.add(cast(l, ScriptedAssetLibrary).prefix);
					buf.add(")\n");
				}
				else if (l is IModsAssetLibrary) {
					buf.add(className);
					buf.add(" - ");
					buf.add(cast(l, IModsAssetLibrary).modName);
					buf.add(" - ");
					buf.add(cast(l, IModsAssetLibrary).libName);
					buf.add(" (");
					buf.add(cast(l, IModsAssetLibrary).prefix);
					buf.add(")\n");
				}
				else {
					buf.add(Std.string(l));
					buf.add("\n");
				}
			}
			text = buf.toString();
			if (text != "")
				text = text.substr(0, text.length-1);
		}

		this.text.text = text;
		super.__enterFrame(t);
	}
}