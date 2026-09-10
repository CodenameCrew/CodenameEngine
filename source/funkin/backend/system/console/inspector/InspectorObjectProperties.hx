package funkin.backend.system.console.inspector;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.system.console.inspector.ConsoleInspector.InspectorObject;

#if IMGUI_ENABLED
import lime.tools.imgui.ImGuiFlags;
import lime.tools.imgui.ImGuiTypes;
import lime.tools.imgui.ImGuiPtr;
#end
#if foxlite
import foxlite.FoxScene;
import foxlite.group.FoxTypedGroup;
import foxlite.group.FoxObjectGroup;
import foxlite.FoxBasic;
import foxlite.FoxObject;
import foxlite.FoxModel;
#end

class InspectorObjectProperties {

	#if IMGUI_ENABLED
	var boolPool:ImGuiPtrPool<ImGuiBoolPtr> = new ImGuiPtrPool<ImGuiBoolPtr>(function() {return new ImGuiBoolPtr(false);});
	var floatPool:ImGuiPtrPool<ImGuiFloatPtr> = new ImGuiPtrPool<ImGuiFloatPtr>(function() {return new ImGuiFloatPtr(0.0);});
	var intPool:ImGuiPtrPool<ImGuiIntPtr> = new ImGuiPtrPool<ImGuiIntPtr>(function() {return new ImGuiIntPtr(0);});
	var float4Pool:ImGuiPtrPool<ImGuiFloat4Ptr> = new ImGuiPtrPool<ImGuiFloat4Ptr>(function() {return new ImGuiFloat4Ptr(0, 0, 0, 0);});
	var stringPool:ImGuiPtrPool<ImGuiStringPtr> = new ImGuiPtrPool<ImGuiStringPtr>(function() {return new ImGuiStringPtr("");});
	
	var mainImageViewer:ImGuiImageViewer = new ImGuiImageViewer();
	var imageViewerMap:Map<Int, ImGuiImageViewer> = [];

	var tableFlags = ImGuiTableFlags.SizingStretchSame | ImGuiTableFlags.Resizable | ImGuiTableFlags.BordersOuter | ImGuiTableFlags.BordersV | ImGuiTableFlags.RowBg;

	public function new() {}

	public function show(objectData:InspectorObject, justChanged:Bool) {
		boolPool.reset();
		floatPool.reset();
		intPool.reset();
		float4Pool.reset();
		stringPool.reset();

		if (justChanged) {
			mainImageViewer.viewReset = true;
			imageViewerMap.clear();
		}

		var selectedObject:Dynamic = objectData.obj;

		if (ImGui.begin("Object Properties")) {
			ImGui.text(objectData.name + " - " + objectData.type);

			var basic:FlxBasic = selectedObject is FlxBasic ? cast selectedObject : null;
			if (basic != null) {
				showFlxBasicProperties(basic);
				//TODO: script stuff here
			}
			#if foxlite
			var foxbasic:FoxBasic = selectedObject is FoxBasic ? cast selectedObject : null;
			if (foxbasic != null) {
				showFoxBasicProps(foxbasic);
			}
			#end
		}
		ImGui.end();
	}

	function showFlxBasicProperties(basic:FlxBasic) {
		var object:FlxObject = basic is FlxObject ? cast basic : null;
		var sprite:FlxSprite = basic is FlxSprite ? cast basic : null;
		var text:FlxText = basic is FlxText ? cast basic : null;
		var funkinSprite:FunkinSprite = basic is FunkinSprite ? cast basic : null;
		var funkinText:FunkinText = basic is FunkinText ? cast basic : null;

		if (object != null) {
			showFlxObjectTransformProperties(object, sprite, funkinSprite, funkinText);
			if (sprite != null) {
				showFlxSpriteGraphicsProperties(sprite);
				showFlxSpriteAnimationProperties(sprite);
			}
			showFlxObjectPhysicsProperties(object);
			if (text != null) {
				showFlxTextProperties(text);
			}
		}

		if (ImGui.collapsingHeader("Basic")) {
			if (ImGui.beginTable("Basic##1", 2, tableFlags))
			{
				checkboxField("Active", "active", basic);
				checkboxField("Visible", "visible", basic);
				checkboxField("Alive", "alive", basic);
				checkboxField("Exists", "exists", basic);
				ImGui.endTable();
			}
		}
	}

	function showFlxObjectTransformProperties(object:FlxObject, ?sprite:FlxSprite = null, ?funkinSprite:FunkinSprite = null, ?funkinText:FunkinText = null) {
		if (ImGui.collapsingHeader("Transform")) {
			if (ImGui.beginTable("TransformTable", 2, tableFlags))
			{
				dragFloat2Field("Position", "x", "y", object);
				dragFloat2Field("Width/Height", "width", "height", object);
				if (sprite != null) {
					dragFloat2Field("Scale", "x", "y", sprite.scale, 0.05);
					dragFloat2Field("Origin", "x", "y", sprite.origin, 0.1);
					dragFloat2Field("Offset", "x", "y", sprite.offset);
				}
				dragFloatField("Angle", "angle", object);
				dragFloat2Field("Scroll Factor", "x", "y", object.scrollFactor, 0.05);
				if (funkinSprite != null || funkinText != null) {
					dragFloatField("Zoom Factor", "zoomFactor", object, 0.05);
					checkboxField("Enabled", "zoomFactorEnabled", object);
					dragFloatField("Angle Factor", "angleFactor", object, 0.05);
					checkboxField("Enabled", "angleFactorEnabled", object);

					dragFloat2Field("Skew", "x", "y", funkinSprite != null ? funkinSprite.skew : funkinText.skew, 0.05);
				}

				//TODO: scripting

				ImGui.endTable();
			}
		}
	}
	function showFlxSpriteGraphicsProperties(sprite:FlxSprite) {
		if (ImGui.collapsingHeader("Graphics")) {
			if (sprite.graphic != null) {
				ImGui.text("Key: " + sprite.graphic.key);
				var wid = ImGui.getContentRegionAvail().x;
				if (sprite.graphic.bitmap != null) {
					mainImageViewer.drawCanvas(wid, 300, ImTextureID.fromBitmapData(sprite.graphic.bitmap), sprite.graphic.width, sprite.graphic.height);
				}
			}

			if (ImGui.beginTable("GraphicsTable", 2, tableFlags))
			{
				colorField("Color", "color", sprite);
				sliderFloatField("Alpha", "alpha", sprite, 0, 1);

				checkboxField("Flip X", "flipX", sprite);
				checkboxField("Flip Y", "flipY", sprite);
				checkboxField("Antialiasing", "antialiasing", sprite);

				enumAbstractField("Blend Mode", "blend", sprite, "openfl.display.BlendMode");

				ImGui.endTable();
			}
		}
	}

	function showFlxSpriteAnimationProperties(sprite:FlxSprite) {
		if (ImGui.collapsingHeader("Animation")) {
			//TODO
			ImGui.text("Not yet implemented");
		}
	}

	function showFlxObjectPhysicsProperties(object:FlxObject) {
		if (ImGui.collapsingHeader("Physics")) {
			if (ImGui.beginTable("PhysicsTable", 2, tableFlags))
			{
				checkboxField("Moves", "moves", object);
				checkboxField("Immovable", "immovable", object);
				checkboxField("Solid", "solid", object);

				dragFloat2Field("Velocity", "x", "y", object.velocity);
				dragFloat2Field("Acceleration", "x", "y", object.acceleration);
				dragFloat2Field("Drag", "x", "y", object.drag);
				dragFloatField("Mass", "mass", object);
				dragFloatField("Elasticity", "elasticity", object);
				dragFloatField("Angular Velocity", "angularVelocity", object);
				dragFloatField("Angular Acceleration", "angularAcceleration", object);
				dragFloatField("Angular Drag", "angularDrag", object);
				dragFloat2Field("Max Velocity", "x", "y", object.maxVelocity);
				dragFloatField("Max Angular", "maxAngular", object);
				ImGui.endTable();
			}
		}
	}

	function showFlxTextProperties(text:FlxText) {
		if (ImGui.collapsingHeader("Text")) {
			if (ImGui.beginTable("TextTable", 2, tableFlags))
			{
				inputTextFieldMultiline("Text", "text", text, 400, 200);
				dragIntField("Size", "size", text);
				inputTextField("Font", "font", text);
				dragFloat2Field("Field Width/Height", "fieldWidth", "fieldHeight", text);
				enumAbstractField("Alignment", "alignment", text, "flixel.text.FlxTextAlign");
				dragFloatField("Letter Spacing", "letterSpacing", text);

				colorField("Border Color", "borderColor", text);

				{
					ImGui.tableNextRow();
					ImGui.tableSetColumnIndex(0);
					ImGui.text("Border Style");
					ImGui.tableSetColumnIndex(1);
					var wid = ImGui.getContentRegionAvail().x;
					ImGui.setNextItemWidth(wid);

					var index = intPool.get();
					var list = ["NONE", "SHADOW", "SHADOW_XY", "OUTLINE", "OUTLINE_FAST"];
					switch(text.borderStyle) { //not that easy to automate due to args on SHADOW_XY
						case NONE:
							index.value = 0;
						case SHADOW:
							index.value = 1;
						case SHADOW_XY(offsetX, offsetY):
							index.value = 2;
						case OUTLINE:
							index.value = 3;
						case OUTLINE_FAST:
							index.value = 4;
					}			
					if (ImGui.combo("##Border StyleborderStyle", index, list)) {
						switch(index.value) {
							case 0:
								text.borderStyle = NONE;
							case 1:
								text.borderStyle = SHADOW;
							case 2:
								text.borderStyle = SHADOW_XY(0, 0);
							case 3:
								text.borderStyle = OUTLINE;
							case 4:
								text.borderStyle = OUTLINE_FAST;
						}
					}

					switch(text.borderStyle) {
						case SHADOW_XY(offsetX, offsetY):
							//todo
						default:
					}	
				}
				dragFloatField("Border Size", "borderSize", text);
				dragFloatField("Border Quality", "borderQuality", text);

				checkboxField("Bold", "bold", text);
				checkboxField("Underline", "underline", text);
				checkboxField("Italic", "italic", text);
				checkboxField("Word Wrap", "wordWrap", text);
				checkboxField("Auto Size", "autoSize", text);
				ImGui.endTable();
			}				
		}
	}

	#if foxlite
	function showFoxBasicProps(basic:FoxBasic) {
		var object:FoxObject = basic is FoxObject ? cast basic : null;
		var model:FoxModel = basic is FoxModel ? cast basic : null;

		if (object != null) {
			ImGui.separator();
			showFoxObjectTransformProperties(object);
			if (model != null) showFoxModelGraphicsProperties(model);
		}

		if (ImGui.collapsingHeader("Basic")) {
			if (ImGui.beginTable("Basic##1", 2, tableFlags))
			{
				textField("Name", basic.name);
				checkboxField("Active", "active", basic);
				checkboxField("Visible", "visible", basic);
				ImGui.endTable();
			}
		}
	}

	function showFoxObjectTransformProperties(object:FoxObject) {
		if (ImGui.collapsingHeader("Transform")) {
			if (ImGui.beginTable("TransformTable", 2, tableFlags))
			{
				var dirty = false;
				if (dragFloat3Field("Position", "x", "y", "z", object.position, 0.05)) dirty = true;
				if (dragFloat3Field("Rotation", "angleX", "angleY", "angleZ", object)) dirty = true;
				if (dragFloat3Field("Scale", "x", "y", "z", object.scale, 0.05)) dirty = true;
				if (dirty) {
					object.update(0.0); //force update transform
				}
				ImGui.endTable();
			}
		}
	}

	function showFoxModelGraphicsProperties(model:FoxModel) {
		if (model != null && ImGui.collapsingHeader("Graphics")) {
			if (ImGui.beginTable("Model##1", 2, tableFlags))
			{
				checkboxField("Frustrum Culling", "frustumCulling", model);
				checkboxField("Cast Shadows", "castShadows", model);
				checkboxField("Cast Colored Shadows", "castColoredShadows", model);
				ImGui.endTable();
			}

			ImGui.separator();
			
			for (i => mesh in model.meshes) {
				var nodeID = "mesh" + i;
				if (ImGui.treeNode(nodeID, mesh.assetsKey != null ? mesh.assetsKey : "Mesh " + i)) {
					ImGui.pushIDFromInt(i);
					if (ImGui.beginTable("MeshTable" + i, 2, tableFlags))
					{
						textField("Key", mesh.assetsKey);
						textField("Is Copy", mesh.__isCopy ? "True" : "False");
						@:privateAccess {
							if (mesh.vertexBuffer != null) textField("Vertex Buffer", "Num: " + mesh.vertexBuffer.__numVertices + ", Stride: " + mesh.vertexBuffer.__stride + ", Size: " + mesh.vertexBuffer.__memoryUsage);
							if (mesh.uvBuffer != null) textField("UV Buffer", "Num: " + mesh.uvBuffer.__numVertices + ", Stride: " + mesh.uvBuffer.__stride + ", Size: " + mesh.uvBuffer.__memoryUsage);
							if (mesh.indexBuffer != null) textField("Index Buffer", "Num: " + mesh.indexBuffer.__numIndices + ", Size: " + mesh.indexBuffer.__memoryUsage);
							if (mesh.normalBuffer != null) textField("Normal Buffer", "Num: " + mesh.normalBuffer.__numVertices + ", Stride: " + mesh.normalBuffer.__stride + ", Size: " + mesh.normalBuffer.__memoryUsage);
							if (mesh.tangentBuffer != null) textField("Tangent Buffer", "Num: " + mesh.tangentBuffer.__numVertices + ", Stride: " + mesh.tangentBuffer.__stride + ", Size: " + mesh.tangentBuffer.__memoryUsage);
							if (mesh.colorBuffer != null) textField("Color Buffer", "Num: " + mesh.colorBuffer.__numVertices + ", Stride: " + mesh.colorBuffer.__stride + ", Size: " + mesh.colorBuffer.__memoryUsage);
							if (mesh.boneWeights != null) textField("Bone Weights Buffer", "Num: " + mesh.boneWeights.__numVertices + ", Stride: " + mesh.boneWeights.__stride + ", Size: " + mesh.boneWeights.__memoryUsage);
							if (mesh.colorBuffer != null) textField("Bone Indices Buffer", "Num: " + mesh.boneIndices.__numVertices + ", Stride: " + mesh.boneIndices.__stride + ", Size: " + mesh.boneIndices.__memoryUsage);
						}
						ImGui.endTable();
					}
					
					if (mesh.material != null) {
						ImGui.separatorText("Material");
						if (ImGui.beginTable("MaterialTable" + i, 2, tableFlags))
						{
							textField("Name", mesh.material.name);
							textField("Key", mesh.material.assetsKey);
							dragIntField("Render Priority", "renderPriority", mesh.material);
							checkboxField("Depth Test", "depthTest", mesh.material);
							enumAbstractField("Depth Func", "depthFunc", mesh.material, "foxlite.material.FoxDepthCompareMode");
							checkboxField("Depth Write", "depthWrite", mesh.material);
							checkboxField("Color Write", "colorWrite", mesh.material);
							enumAbstractField("Culling", "culling", mesh.material, "foxlite.material.FoxTriangleFace");
							enumAbstractField("Shadow Culling", "shadowCulling", mesh.material, "foxlite.material.FoxTriangleFace");
							enumAbstractField("Blend Mode", "blendMode", mesh.material, "foxlite.material.FoxBlendMode");
							sliderFloatField("Alpha Scissor", "alphaScissor", mesh.material, 0, 1);
							ImGui.endTable();
						}



						if (ImGui.treeNode(nodeID + "textures", "Textures")) {
							for (texName => tex in mesh.material.textures) {
								ImGui.separatorText(texName);
								var wid = ImGui.getContentRegionAvail().x;
								@:privateAccess
								var id:Int = tex.glTexture.__getTexture().id;
								if (id != 0) {
									if (!imageViewerMap.exists(id)) imageViewerMap.set(id, new ImGuiImageViewer());
									imageViewerMap.get(id).drawCanvas(wid, 300, new ImTextureID(id), tex.width, tex.height);
								}
							}
							ImGui.treePop();
						}
						if (ImGui.treeNode(nodeID + "params", "Parameters")) {
							if (ImGui.beginTable("ParamsTable" + i, 2, tableFlags)) {
								for (name => value in mesh.material.params) {
									textField(name, Std.string(value));
								}
								ImGui.endTable();
							}
							ImGui.treePop();
						}						
					}
					ImGui.popID();
					ImGui.treePop();
				}
			}
		}
	}

	#end

	////////////////////////////////////

	inline function dragFloatField(name:String, field:String, object:Dynamic, speed:Float = 1.0, min:Float = 0.0, max:Float = 0.0, format:String = "%.3f", flags:ImGuiSliderFlags = 0) {
		var didChange:Bool = false;
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);

		var wid = ImGui.getContentRegionAvail().x;
		ImGui.setNextItemWidth(wid);

		var f = floatPool.get();
		f.value = Reflect.getProperty(object, field);
		if (ImGui.dragFloat("##" + name + field, f, speed, min, max, format, flags)) {
			Reflect.setProperty(object, field, f.value);
			didChange = true;
		}
		return didChange;
	}
	inline function dragFloat2Field(name:String, field:String, field2:String, object:Dynamic, speed:Float = 1.0, min:Float = 0.0, max:Float = 0.0, format:String = "%.3f", flags:ImGuiSliderFlags = 0) {
		var didChange:Bool = false;
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);
		var wid = ImGui.getContentRegionAvail().x / 2;
		ImGui.setNextItemWidth(wid);

		var f = floatPool.get();
		f.value = Reflect.getProperty(object, field);
		if (ImGui.dragFloat("##" + name + field, f, speed, min, max, format, flags)) {
			Reflect.setProperty(object, field, f.value);
			didChange = true;
		}

		ImGui.sameLine();
		ImGui.setNextItemWidth(wid);

		var f2 = floatPool.get();
		f2.value = Reflect.getProperty(object, field2);
		if (ImGui.dragFloat("##" + name + field2, f2, speed, min, max, format, flags)) {
			Reflect.setProperty(object, field2, f2.value);
			didChange = true;
		}
		return didChange;
	}
	inline function dragFloat3Field(name:String, field:String, field2:String, field3:String, object:Dynamic, speed:Float = 1.0, min:Float = 0.0, max:Float = 0.0, format:String = "%.3f", flags:ImGuiSliderFlags = 0) {
		var didChange:Bool = false;
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);
		var wid = ImGui.getContentRegionAvail().x / 3;
		ImGui.setNextItemWidth(wid);

		var f = floatPool.get();
		f.value = Reflect.getProperty(object, field);
		if (ImGui.dragFloat("##" + name + field, f, speed, min, max, format, flags)) {
			Reflect.setProperty(object, field, f.value);
			didChange = true;
		}

		ImGui.sameLine();
		ImGui.setNextItemWidth(wid);

		var f2 = floatPool.get();
		f2.value = Reflect.getProperty(object, field2);
		if (ImGui.dragFloat("##" + name + field2, f2, speed, min, max, format, flags)) {
			Reflect.setProperty(object, field2, f2.value);
			didChange = true;
		}

		ImGui.sameLine();
		ImGui.setNextItemWidth(wid);

		var f3 = floatPool.get();
		f3.value = Reflect.getProperty(object, field3);
		if (ImGui.dragFloat("##" + name + field3, f3, speed, min, max, format, flags)) {
			Reflect.setProperty(object, field3, f3.value);
			didChange = true;
		}
		return didChange;
	}
	inline function sliderFloatField(name:String, field:String, object:Dynamic, min:Float, max:Float, format:String = "%.3f", flags:ImGuiSliderFlags = 0) {
		var didChange:Bool = false;
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);
		var wid = ImGui.getContentRegionAvail().x;
		ImGui.setNextItemWidth(wid);

		var f = floatPool.get();
		f.value = Reflect.getProperty(object, field);
		if (ImGui.sliderFloat("##" + name + field, f, min, max, format, flags)) {
			Reflect.setProperty(object, field, f.value);
			didChange = true;
		}
		return didChange;
	}
	inline function dragIntField(name:String, field:String, object:Dynamic, speed:Float = 1.0, min:Int = 0, max:Int = 0, format:String = "%d", flags:ImGuiSliderFlags = 0) {
		var didChange:Bool = false;
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);
		var wid = ImGui.getContentRegionAvail().x;
		ImGui.setNextItemWidth(wid);

		var i = intPool.get();
		i.value = Reflect.getProperty(object, field);
		if (ImGui.dragInt("##" + name + field, i, speed, min, max, format, flags)) {
			Reflect.setProperty(object, field, i.value);
			didChange = true;
		}
		return didChange;
	}
	inline function checkboxField(name:String, field:String, object:Dynamic) {
		var didChange:Bool = false;
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);
		var b = boolPool.get(); b.value = Reflect.getProperty(object, field); 
		if (ImGui.checkbox("##" + name + field, b)) {
			Reflect.setProperty(object, field, b.value);
			didChange = true;
		}
		return didChange;
	}
	inline function textField(name:String, text:String) {
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);
		ImGui.text(text);
	}
	inline function colorField(name:String, field:String, object:Dynamic, flags:ImGuiColorEditFlags = 0) {
		var didChange:Bool = false;
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);
		var wid = ImGui.getContentRegionAvail().x;
		ImGui.setNextItemWidth(wid);

		var color:FlxColor = Reflect.getProperty(object, field);
		var float4 = float4Pool.get();
		float4.values[0] = color.redFloat;
		float4.values[1] = color.greenFloat;
		float4.values[2] = color.blueFloat;
		float4.values[3] = color.alphaFloat;
		if (ImGui.colorEdit4("##" + name + field, float4, flags)) {
			Reflect.setProperty(object, field, FlxColor.fromRGBFloat(float4.values[0], float4.values[1], float4.values[2], float4.values[3]));
			didChange = true;
		}
		return didChange;
	}
	inline function inputTextField(name:String, field:String, object:Dynamic, flags:ImGuiInputTextFlags = 0) {

		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);

		var wid = ImGui.getContentRegionAvail().x;
		ImGui.setNextItemWidth(wid);

		var s = stringPool.get();
		s.value = Reflect.getProperty(object, field);
		if (ImGui.inputText("##" + name + field, s, flags)) {
			Reflect.setProperty(object, field, s.value);
		}
	}
	inline function inputTextFieldMultiline(name:String, field:String, object:Dynamic, width:Float, height:Float, flags:ImGuiInputTextFlags = 0) {
		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);
		var s = stringPool.get();
		s.value = Reflect.getProperty(object, field);
		if (ImGui.inputTextMultiline("##" + name + field, s, width, height, flags)) {
			Reflect.setProperty(object, field, s.value);
		}
	}
	inline function enumFieldString(name:String, field:String, object:Dynamic, list:Array<String>) { //not working
		var index = intPool.get();
		index.value = list.indexOf(Std.string(Reflect.getProperty(object, field)));
		if (ImGui.combo(name + "##" + field, index, list)) {
			Reflect.setProperty(object, field, list[index.value]);
		}
	}
	inline function enumAbstractField(name:String, field:String, object:Dynamic, type:String) {

		ImGui.tableNextRow();
		ImGui.tableSetColumnIndex(0);
		ImGui.text(name);
		ImGui.tableSetColumnIndex(1);

		var t = Type.resolveClass(type + "_HSC");
		if (t != null) {
			var wid = ImGui.getContentRegionAvail().x;
			ImGui.setNextItemWidth(wid);

			var curValue = Reflect.getProperty(object, field);
			var index = intPool.get();

			var fields = Type.getClassFields(t);
			var filteredFields:Array<String> = [];
			for (f in fields) {
				if (!f.startsWith("from") && !f.startsWith("to")) filteredFields.push(f);
			}
			index.value = -1;
			for (i => f in filteredFields) {
				if (Reflect.getProperty(t, f) == curValue) index.value = i;
			}

			if (ImGui.combo("##" + name + field, index, filteredFields)) {
				Reflect.setProperty(object, field, Reflect.getProperty(t, filteredFields[index.value]));
			}

		}
	}
	#end
}

#if IMGUI_ENABLED
//quick class that handles imgui pointers for temp values
class ImGuiPtrPool<T> {
	var members:Array<T> = [];
	var used:Int = 0;
	var constructor:Void->T;
	public function new(constructor:Void->T) {
		this.constructor = constructor;
	}
	public function reset() {
		used = 0;
	}
	public function get():T {
		if (used >= members.length) {
			members.push(constructor());
		}
		var obj = members[used];
		used++;
		return obj;
	}
}

//https://github.com/ocornut/imgui/blob/master/imgui_demo.cpp#L841
class ImGuiImageViewer {
	var gridEnabled:ImGuiBoolPtr = new ImGuiBoolPtr(false);
	public var viewReset:Bool = true;
	var viewOffsetX:Float = 0;
	var viewOffsetY:Float = 0;
	var zoom:ImGuiFloatPtr = new ImGuiFloatPtr(10.0);
	var zoom100:ImGuiFloatPtr = new ImGuiFloatPtr(10.0);
	var zoomMin:Float = 0.1;
	var zoomMax:Float = 10000;

	public function new() {}

	public function drawOptions() {
		ImGui.setNextItemWidth(150);
		zoom100.value = zoom.value * 100;
		if (ImGui.dragFloat("Zoom", zoom100, 5.0, zoomMin * 100.0, zoomMax * 100, "%.0f%%", ImGuiSliderFlags.AlwaysClamp))
			zoom.value = zoom100.value / 100.0;
	}

	public function drawCanvas(canvas_size_x:Float, canvas_size_y:Float, image_tex_ref:ImTextureID, image_w:Int, image_h:Int) {
		var drawList = ImGui.getWindowDrawList();
		ImGui.invisibleButton("##Canvas", canvas_size_x, canvas_size_y);
		var canvas_min = ImGui.getItemRectMin();
		var canvas_max = ImGui.getItemRectMax();

		if (viewReset) {
			var xZoom = canvas_size_x / image_w;
			var yZoom = canvas_size_y / image_h;
			zoom.value = (image_w > image_h ? xZoom : yZoom);
			viewOffsetX = (canvas_size_x * 0.5 / xZoom) - 0.5;
			viewOffsetY = (canvas_size_y * 0.5 / yZoom) - 0.5;
		}
		viewReset = false;

		if (ImGui.setItemKeyOwner(ImGuiKey.MouseWheelY)) {
			if (ImGuiIO.mouseWheel != 0.0) {
				zoom.value = FlxMath.bound(zoom.value * (1.0 + ImGuiIO.mouseWheel * 0.10), zoomMin, zoomMax);
			}
		}
		var zoomValue = zoom.value;
		if (ImGui.isItemActive() && ImGui.isMouseDragging(0)) {
			viewOffsetX -= ImGuiIO.mouseDeltaX / zoomValue;
			viewOffsetY -= ImGuiIO.mouseDeltaY / zoomValue;
		}

		var minX:Float = Std.int((canvas_min.x - (viewOffsetX * zoomValue)) + (canvas_size_x * 0.5));
		var minY:Float = Std.int((canvas_min.y - (viewOffsetY * zoomValue)) + (canvas_size_y * 0.5));
		var maxX:Float = Std.int(minX + image_w * zoomValue);
		var maxY:Float = Std.int(minY + image_h * zoomValue);
		drawList.addRect([canvas_min.x - 1.0, canvas_min.y - 1.0, canvas_max.x + 1.0, canvas_max.y + 1.0], 0xFFFFFFFF);
		drawList.pushClipRect(canvas_min.x, canvas_min.y, canvas_max.x, canvas_max.y, true);
		drawList.addRectFilled([minX, minY, maxX, maxY], 0xFF646464);
		drawList.addImage(image_tex_ref, [minX, minY, maxX, maxY]);

		if (gridEnabled.value && zoomValue > 6.0)
		{
			var step:Float = zoomValue;
			for (px in Std.int((canvas_min.x - minX) / step)...Std.int((canvas_max.x - minX) / step)) {
				drawList.addLineV(minX + px * step, canvas_min.y, canvas_max.y, 0x64FFFFFF, 1.0);
			}
			for (py in Std.int((canvas_min.y - minY) / step)...Std.int((canvas_max.y - minY) / step)) {
				drawList.addLineH(canvas_min.x, canvas_max.x, minY + py * step, 0x64FFFFFF, 1.0);
			}
		}
		drawList.popClipRect();
	}

	
}
#end