package funkin.game.stage;

import funkin.backend.system.interfaces.IBeatReceiver;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxStringUtil; 
import flixel.util.FlxStringUtil.LabelValuePair;
import flixel.util.FlxDestroyUtil;
import flixel.FlxSprite;

import hscript.IHScriptCustomBehaviour;

/**
 * This is an organizational class that can update and render a bunch of `FlxSprite`s and `Layer`s.
 * @author Jamextreme140 & ItsLJcool
 */
class Layer extends FlxTypedSpriteGroup<FlxSprite> implements IBeatReceiver implements IHScriptCustomBehaviour {
	private static final __instanceFields:Array<String> = Type.getInstanceFields(Layer);

	/**
	 * The Layer Name
	 */
	public var name(default, null):String;

	/**
	 * Signal that triggers whenever a sprite is added. Similar to `group.memberAdded`, except sprite specific.
	 */
	public final onAddSprite:FlxTypedSignal<FlxSprite -> Void> = new FlxTypedSignal<FlxSprite -> Void>();

	/**
	 * Signal that triggers whenever a layer is added. Similar to `group.memberAdded`, except layer specific.
	 */
	public final onAddLayer:FlxTypedSignal<Layer -> Void> = new FlxTypedSignal<Layer -> Void>();

	/**
	 * Returns the parent layer in the Stage hierarchy.
	 * WARNING: can be `null`, normally indicating this is the main layer (i.e. the Stage itself).
	 */
	public var parent:Layer = null;

	/**
	 * Internal. Used for hitbox reference and rendering (soon...)
	 */
	private var _bounds(default, null):FlxRect = FlxRect.get(); // TODO: draw debug for bounding box

	public function new(name:String = 'stage_layer', ?parent:Layer) {
		super();
		this.name = name;
		this.parent = parent;
		group.memberAdded.add((spr) -> {
			if(spr is Layer)
				onAddLayer.dispatch(cast spr);
			else
				onAddSprite.dispatch(spr);

			updateHitbox();
		});
		group.memberRemoved.add((_) -> {
			updateHitbox();
		});
	}

	//region IBeatReceiver implementation
	public function beatHit(curBeat:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) (cast m:IBeatReceiver).beatHit(curBeat);
	}
	public function stepHit(curStep:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) (cast m:IBeatReceiver).stepHit(curStep);
	}
	public function measureHit(curMeasure:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) (cast m:IBeatReceiver).measureHit(curMeasure);
	}
	//endregion
	
	private final stageSprites:Map<String, FlxSprite> = [];
	private final stageLayers:Map<String, Layer> = [];

	//region Stage Layer Management
	override function preAdd(Sprite:FlxSprite) {
		if(Sprite == null) return; 
		Sprite.x += x;
		Sprite.y += y;
		Sprite.alpha *= alpha;
		Sprite.cameras = _cameras; // _cameras instead of cameras because get_cameras() will not return null

		if (clipRect != null) clipRectTransform(Sprite, clipRect);
	}

	public override function add(obj:FlxSprite):FlxSprite {
		if(!(obj is Layer)) return super.add(obj);

		var layer:Layer = cast obj;
		if (stageLayers.exists(layer.name)) 
			return stageLayers.get(layer.name);

		stageLayers.set(layer.name, layer);
		return super.add(layer);
	}

	public override function insert(position:Int, obj:FlxSprite):FlxSprite {
		if(!(obj is Layer)) return super.insert(position, obj);

		var layer:Layer = cast obj;
		if (stageLayers.exists(layer.name)) 
			return stageLayers.get(layer.name);

		stageLayers.set(layer.name, layer);
		return super.insert(position, layer);
	}

	public override function remove(obj:FlxSprite, splice:Bool = false):FlxSprite {
		if(!(obj is Layer)) return super.remove(obj, splice);

		var layer:Layer = cast obj;
		stageLayers.remove(layer.name);
		return super.remove(layer, splice);
	}
	//endregion

	//region Stage Sprite Management
	public function addSprite(name:String, spr:FlxSprite):FlxSprite {
		if (stageSprites.exists(name)) return spr;

		this.add(spr);
		stageSprites.set(name, spr);

		return spr;
	}

	public function insertSprite(index:Int, name:String, spr:FlxSprite):FlxSprite {
		if (stageSprites.exists(name)) return spr;

		this.insert(index, spr);
		stageSprites.set(name, spr);

		return spr;
	}

	public function removeSprite(name:String, splice:Bool = false):Bool {
		if (!stageSprites.exists(name)) return false;

		var spr:FlxSprite = stageSprites.get(name);
		
		this.remove(spr, splice);
		stageSprites.remove(name);
		
		return true;
	}

	public inline function getSprite(name:String):Null<FlxSprite> {
		return stageSprites.exists(name) ? stageSprites[name] : null;
	}

	public inline function getLayer(name:String):Null<Layer> {
		return stageLayers.exists(name) ? stageLayers[name] : null;
	}
	//endregion

	//region IHScriptCustomBehaviour implementation
	public function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_$name'))
			return Reflect.getProperty(this, name);
		if (stageSprites.exists(name)) return stageSprites[name];
		if (stageLayers.exists(name)) return stageLayers[name];
		return null;
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_$name')) {
			Reflect.setProperty(this, name, val);
			return val;
		}
		if (stageSprites.exists(name)) return stageSprites[name] = val;
		if (stageLayers.exists(name)) return stageLayers[name] = val;
		return null;
	}
	//endregion

	override function draw() {
		// re-implementing the `onDraw` functionality from `FlxSprite` since `FlxSpriteGroup` didn't have this (it doesn't call `super.draw()`), so we have to add it back in ourselves
		if (__drawOverrided) {
			__drawOverrided = false;
			onDraw(this);
			__drawOverrided = true;
			return;
		}

		if (!visible || group.length == 0 || alpha <= 0.0)
			return;

		super.draw();
	}

	/**
	 * If false, it will check values of `x`, `y`, `width` and `height` of the members directly
	 * instead of checking recursively. This is faster but under some circumstances, 
	 * it might not be 100% accurate.
	 */
	public var updateHitboxDirty:Bool = false;

	override function updateHitbox() {
		if(group.length == 0) return;

		var x:Float = 0;
		var y:Float = 0;
		var width:Float = 0;
		var height:Float = 0;

		if (updateHitboxDirty) {
			x = findMinX();
			y = findMinY();
			width = findMaxX() - x;
			height = findMaxY() - y;
		}
		else {
			var minX:Float = Math.POSITIVE_INFINITY;
			var minY:Float = Math.POSITIVE_INFINITY;

			var maxX:Float = Math.NEGATIVE_INFINITY;
			var maxY:Float = Math.NEGATIVE_INFINITY;

			for (obj in group.members) {
				if (!__shouldUpdateBounds(obj)) continue;
				if (obj.x < minX) minX = obj.x;
				if (obj.y < minY) minY = obj.y;
				if (obj.x + obj.width > maxX) maxX = obj.x + obj.width;
				if (obj.y + obj.height > maxY) maxY = obj.y + obj.height;
			}
			x = minX;
			y = minY;
			width = maxX - minX;
			height = maxY - minY;
		}

		_bounds.set(x, y, width, height);

		frameWidth = Std.int(_bounds.width);
		frameHeight = Std.int(_bounds.height);

		centerOrigin();
	}

	override function getHitbox(?rect:FlxRect):FlxRect {
		rect ??= FlxRect.get();
		return rect.copyFrom(_bounds);
	}

	//region Methods From FlxSpriteGroup
	override function set_x(Value:Float):Float {
		if(exists && x != Value) _bounds.x += Value;
		return super.set_x(Value);
	}
	override function set_y(Value:Float):Float {
		if(exists && y != Value) _bounds.y += Value;
		return super.set_y(Value);
	}
	override function get_width():Float 
		return _bounds.width;
	override function get_height():Float 
		return _bounds.height;

	public override function findMinX():Float {
		if(group.length == 0) return 0;
		var value = Math.POSITIVE_INFINITY;

		for(m in group.members) {
			if (!__shouldUpdateBounds(m)) continue;

			var minX:Float;
			if(m is Layer) minX = cast(m, Layer).findMinX();
			else minX = m.x;

			if (minX < value) value = minX;
		}

		return value;
	}

	public override function findMaxX():Float {
		if(group.length == 0) return 0;
		var value = Math.NEGATIVE_INFINITY;

		for(m in group.members) {
			if (!__shouldUpdateBounds(m)) continue;

			var maxX:Float;
			if(m is Layer) maxX = cast(m, Layer).findMaxX();
			else maxX = m.x + m.width;

			if (maxX > value) value = maxX;
		}

		return value;
	}

	public override function findMinY():Float {
		if(group.length == 0) return 0;
		var value = Math.POSITIVE_INFINITY;

		for(m in group.members) {
			if (!__shouldUpdateBounds(m)) continue;

			var minY:Float;
			if(m is Layer) minY = cast(m, Layer).findMinY();
			else minY = m.y;

			if (minY < value) value = minY;
		}

		return value;
	}

	public override function findMaxY():Float {
		if(group.length == 0) return 0;
		var value = Math.NEGATIVE_INFINITY;

		for(m in group.members) {
			if (!__shouldUpdateBounds(m)) continue;

			var maxY:Float;
			if(m is Layer) maxY = cast(m, Layer).findMaxY();
			else maxY = m.y + m.height;

			if (maxY > value) value = maxY;
		}

		return value;
	}

	// We disabled these functions since everything is pre-calculated above
	@:dox(hide) override function findMaxXHelper():Float {
		#if FLX_DEBUG
		throw "This function is disabled";
		#end
		return 0;
	}
	@:dox(hide) override function findMaxYHelper():Float {
		#if FLX_DEBUG
		throw "This function is disabled";
		#end
		return 0;
	}
	@:dox(hide) override function findMinXHelper():Float {
		#if FLX_DEBUG
		throw "This function is disabled";
		#end
		return 0;
	}
	@:dox(hide) override function findMinYHelper():Float {
		#if FLX_DEBUG
		throw "This function is disabled";
		#end
		return 0;
	}
	//endregion

	private inline function __shouldUpdateBounds(m:FlxSprite):Bool {
		return m != null && m.exists && m.alive;
	}

	override function destroy() {
		super.destroy();
		FlxDestroyUtil.destroy(onAddSprite);
		FlxDestroyUtil.destroy(onAddLayer);
		_bounds = FlxDestroyUtil.put(_bounds);
		stageSprites.clear();
		stageLayers.clear();
	}

	override public function toString():String {
		return '(Stage Layer) $name: ${FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("width", width),
			LabelValuePair.weak("height", height),
		])}';
	}
}
