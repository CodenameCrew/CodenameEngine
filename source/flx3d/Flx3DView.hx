package flx3d;

#if THREE_D_SUPPORT
import away3d.cameras.Camera3D;
import away3d.containers.ObjectContainer3D;
import away3d.entities.Mesh;
import away3d.entities.SegmentSet;
import away3d.entities.TextureProjector;
import away3d.events.Asset3DEvent;
import away3d.events.LoaderEvent;
import away3d.library.Asset3DLibrary;
import away3d.library.Asset3DLibraryBundle;
import away3d.library.assets.Asset3DType;
import away3d.lights.LightBase;
import away3d.loaders.misc.AssetLoaderContext;
import away3d.loaders.misc.AssetLoaderToken;
import away3d.loaders.parsers.*;
import away3d.materials.TextureMaterial;
import away3d.primitives.SkyBox;
import away3d.utils.Cast;
import flx3d.Flx3DUtil;
import haxe.io.Path;
import openfl.Assets;
import away3d.utils.Utils.expect;
#end

// FlxView3D with helpers for easier updating
class Flx3DView extends FlxView3D {
	#if THREE_D_SUPPORT
	private static var __3DIDS:Int = 0;

	var meshes:Array<Mesh> = [];
	public function new(x:Float = 0, y:Float = 0, width:Int = -1, height:Int = -1) {
		if (!Flx3DUtil.is3DAvailable())
			throw "[Flx3DView] 3D is not available on this platform. Stages in use: " + Flx3DUtil.getUsed3D() + ", Max stages allowed: " + Flx3DUtil.getTotal3D() + ".";
		super(x, y, width, height);
		__cur3DStageID = __3DIDS++;
	}

	public function addModel(assetPath:String, callback:Asset3DEvent->Void, ?texturePath:String, smoothTexture:Bool = true) {

		var model = Assets.getBytes(assetPath);
		if (model == null)
			throw 'Model at ${assetPath} was not found.';

		var context = new AssetLoaderContext();
		var noExt = Path.withoutExtension(assetPath);
		trace(noExt);
		context.mapUrlToData(Path.withoutDirectory(noExt) + '.mtl', noExt + '.mtl');

		var material:TextureMaterial = null;
		if (texturePath != null)
			material = new TextureMaterial(Cast.bitmapTexture(Assets.getBitmapData(texturePath, true, false)), smoothTexture);

		return loadData(model, context, switch(Path.extension(assetPath).toLowerCase()) {
			case "dae": new DAEParser();
			case "md2": new MD2Parser();
			case "md5": new MD5MeshParser();
			case "awd": new AWDParser();
			default:	new OBJParser();
		}, (event:Asset3DEvent) -> {
			if (event.asset != null && event.asset.assetType == Asset3DType.MESH) {
				var mesh:Mesh = cast event.asset;
				if (material != null)
					mesh.material = material;
				meshes.push(mesh);
			}
			callback(event);
		});
	}

	private var __cur3DStageID:Int;
	private var _loaders:Map<Asset3DLibraryBundle, AssetLoaderToken> = [];

	private function loadData(data:Dynamic, context:AssetLoaderContext, parser:ParserBase, onAssetCallback:Asset3DEvent->Void):AssetLoaderToken {
		var token:AssetLoaderToken;

		var lib:Asset3DLibraryBundle;
		lib = Asset3DLibraryBundle.getInstance('Flx3DView-${__cur3DStageID}');
		token = lib.loadData(data, context, null, parser);

		token.addEventListener(Asset3DEvent.ASSET_COMPLETE, (event:Asset3DEvent) -> {
			// ! Taken from Loader3D https://github.com/openfl/away3d/blob/master/away3d/loaders/Loader3D.hx#L207-L232
			if (event.type == Asset3DEvent.ASSET_COMPLETE) {
				var obj:ObjectContainer3D = switch (event.asset.assetType) {
					case Asset3DType.LIGHT: expect(event.asset, LightBase);
					case Asset3DType.CONTAINER: expect(event.asset, ObjectContainer3D);
					case Asset3DType.MESH: expect(event.asset, Mesh);
					case Asset3DType.SKYBOX: expect(event.asset, SkyBox);
					case Asset3DType.TEXTURE_PROJECTOR: expect(event.asset, TextureProjector);
					case Asset3DType.CAMERA: expect(event.asset, Camera3D);
					case Asset3DType.SEGMENT_SET: expect(event.asset, SegmentSet);
					default: null;
				}
				if (obj != null && obj.parent == null)
					view.scene.addChild(obj);
			}

			if (onAssetCallback != null)
				onAssetCallback(event);
		});

		token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, (_) -> {
			trace("Loader Finished...");

		});

		_loaders.set(lib,token);

		return token;
	}

	override function destroy() {
		if (meshes != null)
			for(mesh in meshes)
				mesh.dispose();

		var bundle = Asset3DLibraryBundle.getInstance('Flx3DView-${__cur3DStageID}');
		bundle.stopAllLoadingSessions();
		@:privateAccess {
			if (bundle._loadingSessions != null) {
				for(load in bundle._loadingSessions) {
					load.dispose();
				}
			}
			Asset3DLibrary._instances.remove('Flx3DView-${__cur3DStageID}');
		}

		super.destroy();
	}

	public function addChild(c)
		view.scene.addChild(c);
	#end
}