package funkin.backend.system.modules;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.AssetCache;
#if lime
import lime.utils.Assets as LimeAssets;
#end


class FunkinCache extends AssetCache {
	public static var instance:FunkinCache;
	/**
		Internal
	**/
	@:noCompletion @:dox(hide) public var bitmapData2:Map<String, BitmapData>;

	/**
		Internal
	**/
	@:noCompletion @:dox(hide) public var font2:Map<String, Font>;

	/**
		Internal
	**/
	@:noCompletion @:dox(hide) public var sound2:Map<String, Sound>;

	public function new() {
		super();
		moveToSecondLayer();
		instance = this;
	}

	public static function init() {
		openfl.utils.Assets.cache = new FunkinCache();

		FlxG.signals.preStateSwitch.add(function() {
			instance.moveToSecondLayer();
		});

		FlxG.signals.postStateSwitch.add(function() {
			instance.clearSecondLayer();
		});
	}

	public function moveToSecondLayer() {
		bitmapData2 = bitmapData;
		font2 = font;
		sound2 = sound;
		bitmapData = [];
		font = [];
		sound = [];
	}

	public function clearSecondLayer() {
		for(k=>b in bitmapData2) {
			FlxG.bitmap.removeByKey(k);
			LimeAssets.cache.image.remove(k);
		}
		for(k=>f in font2) {
			LimeAssets.cache.font.remove(k);
		}
		for(k=>s in sound2) {
			LimeAssets.cache.audio.remove(k);
		}

		bitmapData2 = [];
		font2 = [];
		sound2 = [];
	}

	/**
		Retrieves a cached BitmapData.

		@param	id	The ID of the cached BitmapData
		@return	The cached BitmapData instance
	**/
	public override function getBitmapData(id:String):BitmapData
	{
		var s = bitmapData.get(id);
		if (s != null)
			return s;
		var s2 = bitmapData2.get(id);
		if (s2 != null) {
			bitmapData2.remove(id);
			bitmapData.set(id, s2);
		}
		return s2;
	}

	/**
		Retrieves a cached Font.

		@param	id	The ID of the cached Font
		@return	The cached Font instance
	**/
	public override function getFont(id:String):Font
	{
		var s = font.get(id);
		if (s != null)
			return s;
		var s2 = font2.get(id);
		if (s2 != null) {
			font2.remove(id);
			font.set(id, s2);
		}
		return s2;
	}

	/**
		Retrieves a cached Sound.

		@param	id	The ID of the cached Sound
		@return	The cached Sound instance
	**/
	public override function getSound(id:String):Sound
	{
		var s = sound.get(id);
		if (s != null)
			return s;
		var s2 = sound2.get(id);
		if (s2 != null) {
			sound2.remove(id);
			sound.set(id, s2);
		}
		return s2;
	}

	/**
		Checks whether a BitmapData asset is cached.

		@param	id	The ID of a BitmapData asset
		@return	Whether the object has been cached
	**/
	public override function hasBitmapData(id:String):Bool
	{
		return bitmapData.exists(id) || bitmapData2.exists(id);
	}

	/**
		Checks whether a Font asset is cached.

		@param	id	The ID of a Font asset
		@return	Whether the object has been cached
	**/
	public override function hasFont(id:String):Bool
	{
		return font.exists(id) || font2.exists(id);
	}

	/**
		Checks whether a Sound asset is cached.

		@param	id	The ID of a Sound asset
		@return	Whether the object has been cached
	**/
	public override function hasSound(id:String):Bool
	{
		return sound.exists(id) || sound2.exists(id);
	}
	/**
		Removes a BitmapData from the cache.

		@param	id	The ID of a BitmapData asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public override function removeBitmapData(id:String):Bool
	{
		#if lime
		LimeAssets.cache.image.remove(id);
		#end
		return bitmapData.remove(id) || bitmapData2.remove(id);
	}

	/**
		Removes a Font from the cache.

		@param	id	The ID of a Font asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public override function removeFont(id:String):Bool
	{
		#if lime
		LimeAssets.cache.font.remove(id);
		#end
		return font.remove(id) || font2.remove(id);
	}

	/**
		Removes a Sound from the cache.

		@param	id	The ID of a Sound asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public override function removeSound(id:String):Bool
	{
		#if lime
		LimeAssets.cache.audio.remove(id);
		#end
		return sound.remove(id) || sound2.remove(id);
	}
}