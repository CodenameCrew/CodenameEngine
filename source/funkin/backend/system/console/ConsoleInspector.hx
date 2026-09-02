package funkin.backend.system.console;

//WIP

import lime.tools.imgui.ImGuiFlags;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import funkin.backend.scripting.HScript;
import funkin.backend.scripting.ScriptPack;
import lime.tools.imgui.ImGuiFlags.ImGuiTreeNodeFlags;
import funkin.game.Stage;
import flixel.FlxState;
import openfl.Lib;

#if IMGUI_ENABLED
import lime.tools.imgui.ImGuiTypes;
import lime.tools.imgui.ImGuiTypes.ImTextureID;
import lime.tools.imgui.ImGuiFlags.ImGuiSliderFlags;
import lime.tools.imgui.ImGuiPtr.ImGuiFloatPtr;
import lime.tools.imgui.ImGuiPtr.ImGuiIntPtr;
import lime.tools.imgui.ImGuiPtr.ImGuiBoolPtr;
#end

typedef InspectorObject = {
	var obj:Dynamic;
	var name:String;
	var type:String;
	var members:Array<InspectorObject>;
	var memberIndex:Int;
	var ?groupParent:InspectorObject;
}

class ConsoleInspector {

	var hscript:ConsoleHscript;
	var cachedInstanceFields:Map<String, Array<String>> = [];
	public function new(hscript:ConsoleHscript) {
		this.hscript = hscript;
	}

	#if IMGUI_ENABLED
	var selectedObject:Dynamic = null;
	var selectedObjectData:InspectorObject = null;
	var selectedObjectValidThisFrame:Bool = false;

	var currentStateObjects:Array<InspectorObject> = [];
	var inspectorObjectsThatNeedUpdating:Array<InspectorObject> = [];

	function updateObjects() {
		var states:Array<FlxState> = [FlxG.state];
		var stateToCheck:FlxState = FlxG.state;
		while(stateToCheck.subState != null) {
			states.push(stateToCheck.subState);
			stateToCheck = stateToCheck.subState;
		}
		
		if (currentStateObjects.length > states.length) {
			currentStateObjects.resize(states.length);
		}
		for (index => state in states) {
			if (currentStateObjects[index] == null || currentStateObjects[index].obj != state) {

				var packageName = hscript.getFieldTypeName(state);
				if (!cachedInstanceFields.exists(packageName)) {
					cachedInstanceFields.set(packageName, Type.getInstanceFields(Type.getClass(state)));
				}
				var packageSplit = packageName.split(".");
				var stateName = packageSplit[packageSplit.length-1];

				currentStateObjects[index] = {
					obj: state,
					name: stateName,
					type: packageName,
					memberIndex: index,
					members: []
				};
			}
		}

		for (index => inspectorObject in currentStateObjects) {
			updateObjectMembers(index, inspectorObject);
		}
	}

	function updateObjectMembers(index:Int, inspectorObject:InspectorObject, fromGroup:Bool = false) {
		var objMembers:Array<Dynamic> = inspectorObject.obj.members;
		if (objMembers == null) {
			return;
		}

		//sort and remove if needed
		var membersToRemove:Array<InspectorObject> = [];
		for (member in inspectorObject.members) {
			var currentIndex:Int = objMembers.indexOf(member.obj);
			if (currentIndex == -1) {
				membersToRemove.push(member);
			}
			member.memberIndex = currentIndex;
		}
		for (m in membersToRemove) inspectorObject.members.remove(m);
		inspectorObject.members.sort(function(a, b) {
           if(a.memberIndex < b.memberIndex) return -1;
           else if(a.memberIndex > b.memberIndex) return 1;
           else return 0;
        });

		//we have new members to add
		if (inspectorObject.members.length != objMembers.length) {
			var newList:Array<InspectorObject> = [];
			var oldListIndex:Int = 0;
			for (i in 0...objMembers.length) {
				if (inspectorObject.members[oldListIndex] == null || inspectorObject.members[oldListIndex].memberIndex != i || inspectorObject.members[oldListIndex].obj != objMembers[i]) {
					var member = objMembers[i];
					var memberPackage = hscript.getFieldTypeName(member);
					var memberPackageSplit = memberPackage.split(".");
					var memberType = memberPackageSplit[memberPackageSplit.length-1];
					var memberName:String = fromGroup ? inspectorObject.name + ".members[" + i + "]" : figureOutObjectName(inspectorObject.type, inspectorObject.obj, member);
					var newObj = {
						obj: objMembers[i],
						name: memberName,
						type: memberType,
						memberIndex: i,
						members: [],
						groupParent: fromGroup ? inspectorObject : null
					};
					newList.push(newObj);
					if (member is FlxTypedGroup || member is FlxTypedSpriteGroup) {
						updateObjectMembers(i, newObj, true);
					}
				} else {
					newList.push(inspectorObject.members[oldListIndex]);
					oldListIndex++;
				}
			}
			inspectorObject.members = newList;
		}
	}

	public function displayUI() {
		
		updateObjects();

		if (ImGui.begin("Inspector")) {
			for (index => member in currentStateObjects) {
				var nodeID = member.name + index;
				var flags = ImGuiTreeNodeFlags.DefaultOpen;
				if (member.obj == selectedObject) flags |= ImGuiTreeNodeFlags.Selected;
				if (ImGui.treeNodeEx(nodeID, flags, member.name + " (" + member.type + ")")) {
					if (ImGui.isItemClicked()) {
						selectObject(member.obj);
					}
					if (member.members.length > 0) {
						generateTreeForMembers(nodeID, member);
					}
					ImGui.treePop();
				}
			}
		}
		ImGui.end();

		if (selectedObject != null) {
			selectedObjectValidThisFrame = false;
			for (member in currentStateObjects) {
				if (member.obj == selectedObject) {
					selectedObjectValidThisFrame = true;
					selectedObjectData = member;
					break;
				}
				checkForSelectedObjectThisFrame(member);
			}

			if (selectedObjectValidThisFrame) {
				showObjectProperties();
			} else {
				selectedObject = null;
				selectedObjectData = null;
			}
		}
	}

	function checkForSelectedObjectThisFrame(object:InspectorObject) {
		if (selectedObjectValidThisFrame) return;
		for (member in object.members) {
			if (member.obj == selectedObject) {
				selectedObjectValidThisFrame = true;
				selectedObjectData = member;
				return;
			}
			if (member.members.length > 0) {
				checkForSelectedObjectThisFrame(member);
			}
		}
	}

	function generateTreeForMembers(id:String, object:InspectorObject) {
		for (index => member in object.members) {
			var valid = member.obj != null;
			var nodeID = id + object.name + index;
			var flags = ImGuiTreeNodeFlags.None;
			if (member.members.length == 0) flags |= ImGuiTreeNodeFlags.Leaf;
			if (valid && member.obj == selectedObject) flags |= ImGuiTreeNodeFlags.Selected;
			if (ImGui.treeNodeEx(nodeID, flags, member.name + (valid ? " (" + member.type + ")" : ""))) {
				if (valid && ImGui.isItemClicked()) {
					selectObject(member.obj);
				}
				if (valid && member.members.length > 0) {
					generateTreeForMembers(nodeID, member);
				}
				ImGui.treePop();
			}
		}
	}

	function selectObject(obj:Dynamic) {
		if (selectedObject != obj) {
			selectedObject = obj;
			justChangedObject = true;
		}
	}

	public function figureOutObjectName(packageName:String, parent:Dynamic, object:FlxBasic) {
		if (object == null) return "Null Member";
		if (!cachedInstanceFields.exists(packageName)) {
			cachedInstanceFields.set(packageName, Type.getInstanceFields(Type.getClass(parent)));
		}
		var instanceFields:Array<String> = cachedInstanceFields.get(packageName);
		var uselessFields:Array<String> = [];
		for (field in instanceFields) {
			if (field == "members") {
				uselessFields.push(field);
				continue;
			}

			var fieldObj:Dynamic = Reflect.getProperty(parent, field);
			if (fieldObj != null) {
				if (fieldObj is FlxBasic) {
					if (object == fieldObj) {
						return field;
					} else if (fieldObj is Stage) {
						var stage:Stage = cast fieldObj;
						for (name => stageObj in stage.stageSprites) {
							if (object == stageObj) return name;
						}
						for (name => posObj in stage.characterPoses) {
							if (object == posObj) return name;
						}
					}
				} else if (fieldObj is Array) {
					var arr:Array<Dynamic> = cast fieldObj;
					var firstMember = arr[0];
					if (firstMember != null && firstMember is FlxBasic) {
						for (index => arrayObj in arr) {
							if (object == arrayObj) {
								return field + "[" + index + "]";
							}
						}
					}
				} else {
					uselessFields.push(field);
				}
			}
		}
		if (uselessFields.length > 0) { //these aren't flxbasic
			for (field in uselessFields) {
				instanceFields.remove(field);
			}
			cachedInstanceFields.set(packageName, instanceFields);
		}

		var scriptPacksToCheck:Array<ScriptPack> = [];
		if (parent is MusicBeatState) {
			var state:MusicBeatState = cast parent;
			scriptPacksToCheck.push(state.stateScripts);
		}
		if (parent is PlayState) {
			var playstate:PlayState = cast parent;
			for (strumLineIndex => strumLine in playstate.strumLines.members) {
				for (charIndex => char in strumLine.characters) {
					if (object == char) {
						return "strumLines[" + strumLineIndex + "].characters[" + charIndex + "] (" + char.curCharacter + ")";
					}
				}
			}
			scriptPacksToCheck.push(playstate.scripts);
		}
		
		for (pack in scriptPacksToCheck) {
			
			for (script in pack.scripts) {
				if (script is HScript) {
					var hscript:HScript = cast script;
					for (name => scriptObj in hscript.interp.variables) {
						if (scriptObj is FlxBasic) {
							if (scriptObj == object) return name;
						} else if (scriptObj is Array) {
							var arr:Array<Dynamic> = cast scriptObj;
							var firstMember = arr[0];
							if (firstMember != null && firstMember is FlxBasic) {
								for (index => arrayObj in arr) {
									if (object == arrayObj) {
										return name + "[" + index + "]";
									}
								}
							}
						}
					}
				}
			}
		}

		return "Unknown" + object.ID;
	}

	var justChangedObject:Bool = false;
	var boolPool:ImGuiPtrPool<ImGuiBoolPtr> = new ImGuiPtrPool<ImGuiBoolPtr>(function() {return new ImGuiBoolPtr(false);});
	var floatPool:ImGuiPtrPool<ImGuiFloatPtr> = new ImGuiPtrPool<ImGuiFloatPtr>(function() {return new ImGuiFloatPtr(0.0);});
	var intPool:ImGuiPtrPool<ImGuiIntPtr> = new ImGuiPtrPool<ImGuiIntPtr>(function() {return new ImGuiIntPtr(0);});
	
	var mainImageViewer:ImGuiImageViewer = new ImGuiImageViewer();
	var graphicIndex:ImGuiIntPtr = new ImGuiIntPtr(0);

	function showObjectProperties() {

		boolPool.reset();
		floatPool.reset();
		intPool.reset();

		if (justChangedObject) {
			mainImageViewer.viewReset = true;
			graphicIndex.value = 0;
			justChangedObject = false;
		}

		if (ImGui.begin("Object Properties")) {
			ImGui.text(selectedObjectData.name + " - " + selectedObjectData.type);

			var basic:FlxBasic = selectedObject is FlxBasic ? cast selectedObject : null;
			var object:FlxObject = selectedObject is FlxObject ? cast selectedObject : null;
			var sprite:FlxSprite = selectedObject is FlxSprite ? cast selectedObject : null;
		
			if (object != null) {
				showObjectGizmo(object);
				if (ImGui.collapsingHeader("Transform")) {
					ImGui.separator();
					ImGui.text("Position");
					ImGui.setNextItemWidth(150);
					var x = floatPool.get(); x.value = object.x; if (ImGui.dragFloat("##X", x)) object.x = x.value;
					ImGui.sameLine();
					ImGui.setNextItemWidth(150);
					var y = floatPool.get(); y.value = object.y; if (ImGui.dragFloat("##Y", y)) object.y = y.value;

					ImGui.text("Width");
					ImGui.sameLine(150, 2);
					ImGui.text("Height");
					ImGui.setNextItemWidth(150);
					var width = floatPool.get(); width.value = object.width; if (ImGui.dragFloat("##Width", width)) object.width = width.value;
					ImGui.sameLine();
					ImGui.setNextItemWidth(150);
					var height = floatPool.get(); height.value = object.height; if (ImGui.dragFloat("##Height", height)) object.height = height.value;

					if (sprite != null) {
						ImGui.text("Scale");
						ImGui.setNextItemWidth(150);
						var scalex = floatPool.get(); scalex.value = sprite.scale.x; if (ImGui.dragFloat("##scalex", scalex, 0.05)) sprite.scale.x = scalex.value;
						ImGui.sameLine();
						ImGui.setNextItemWidth(150);
						var scaley = floatPool.get(); scaley.value = sprite.scale.y; if (ImGui.dragFloat("##scaley", scaley, 0.05)) sprite.scale.y = scaley.value;

						ImGui.text("Origin");
						ImGui.setNextItemWidth(150);
						var originx = floatPool.get(); originx.value = sprite.origin.x; if (ImGui.dragFloat("##originx", originx, 0.1)) sprite.origin.x = originx.value;
						ImGui.sameLine();
						ImGui.setNextItemWidth(150);
						var originy = floatPool.get(); originy.value = sprite.origin.y; if (ImGui.dragFloat("##originy", originy, 0.1)) sprite.origin.y = originy.value;

						ImGui.text("Offset");
						ImGui.setNextItemWidth(150);
						var offsetx = floatPool.get(); offsetx.value = sprite.offset.x; if (ImGui.dragFloat("##offsetx", offsetx)) sprite.offset.x = offsetx.value;
						ImGui.sameLine();
						ImGui.setNextItemWidth(150);
						var offsety = floatPool.get(); offsety.value = sprite.offset.y; if (ImGui.dragFloat("##offsety", offsety)) sprite.offset.y = offsety.value;
					}

					ImGui.text("Angle");
					ImGui.setNextItemWidth(150);
					var angle = floatPool.get(); angle.value = object.angle; if (ImGui.dragFloat("##Angle", angle)) object.angle = angle.value;

					ImGui.text("Scroll Factor");
					ImGui.setNextItemWidth(150);
					var scrollx = floatPool.get(); scrollx.value = object.scrollFactor.x; if (ImGui.dragFloat("##Scrollx", scrollx, 0.05)) object.scrollFactor.x = scrollx.value;
					ImGui.sameLine();
					ImGui.setNextItemWidth(150);
					var scrolly = floatPool.get(); scrolly.value = object.scrollFactor.y; if (ImGui.dragFloat("##Scrolly", scrolly, 0.05)) object.scrollFactor.y = scrolly.value;
				}
				if (sprite != null && ImGui.collapsingHeader("Graphics")) {

					if (sprite.graphic != null) {
						ImGui.text("Key: " + sprite.graphic.key);
						mainImageViewer.drawOptions();
						if (sprite.graphic.bitmap != null) {
							mainImageViewer.drawCanvas(400, 400, ImTextureID.fromBitmapData(sprite.graphic.bitmap), sprite.graphic.width, sprite.graphic.height);
						}
					}

					ImGui.text("Alpha");
					ImGui.setNextItemWidth(150);
					var alpha = floatPool.get(); alpha.value = sprite.alpha; if (ImGui.sliderFloat("##Alpha", alpha, 0, 1)) sprite.alpha = alpha.value;

					var flipX = boolPool.get(); flipX.value = sprite.flipX; if (ImGui.checkbox("Flip X", flipX)) sprite.flipX = flipX.value;
					ImGui.sameLine();
					var flipY = boolPool.get(); flipY.value = sprite.flipY; if (ImGui.checkbox("Flip Y", flipY)) sprite.flipY = flipY.value;
					var antialiasing = boolPool.get(); antialiasing.value = sprite.antialiasing; if (ImGui.checkbox("Antialiasing", antialiasing)) sprite.antialiasing = antialiasing.value;

					final blendModes:Array<String> = ["add", "alpha", "darken", "difference", "erase", "hardlight", "invert", "layer", "lighten", "multiply", "normal", "overlay", "screen", "shader", "subtract", 
						"colordodge", "colorburn", "softlight", "exclusion", "hue", "saturation", "color", "luminosity"];
					var blend = intPool.get(); blend.value = blendModes.indexOf(Std.string(sprite.blend)); if (ImGui.combo("Blend Mode", blend, blendModes)) sprite.blend = blendModes[blend.value];
				}
				if (ImGui.collapsingHeader("Physics")) {

				}
			}

			if (basic != null) {
				ImGui.separator();
				var active = boolPool.get(); active.value = basic.active; if (ImGui.checkbox("Active", active)) basic.active = active.value;
				ImGui.sameLine();
				var visible = boolPool.get(); visible.value = basic.visible; if (ImGui.checkbox("Visible", visible)) basic.visible = visible.value;
				var alive = boolPool.get(); alive.value = basic.alive; if (ImGui.checkbox("Alive", alive)) basic.alive = alive.value;
				ImGui.sameLine();
				var exists = boolPool.get(); exists.value = basic.exists; if (ImGui.checkbox("Exists", exists)) basic.exists = exists.value;
			}
		}
		ImGui.end();
	}
	
	inline function transformFlxPointToWindowSpace(point:FlxPoint) {
		if ((ImGuiIO.configFlags & ImGuiConfigFlags.ViewportsEnable) != 0) {
			point.x = (Lib.application.window.x + FlxG.scaleMode.offset.x) + (point.x * FlxG.scaleMode.scale.x);
			point.y = (Lib.application.window.y + FlxG.scaleMode.offset.y) + (point.y * FlxG.scaleMode.scale.y);
		} else {
			point.x = (FlxG.scaleMode.offset.x) + (point.x * FlxG.scaleMode.scale.x);
			point.y = (FlxG.scaleMode.offset.y) + (point.y * FlxG.scaleMode.scale.y);
		}
	}
	inline function transformFlxPointOntoCamera(point:FlxPoint, camera:FlxCamera) {
		point.subtract(camera.viewMarginLeft, camera.viewMarginTop);
		point.x *= camera.zoom;
		point.y *= camera.zoom;
	}

	function prepareObjectCamera(basic:FlxBasic) {
		var parentsList:Array<Dynamic> = [];
		var oldDefaultCamerasList:Array<Array<FlxCamera>> = [];
		
		var parent = selectedObjectData.groupParent;
		while(parent != null) {
			parentsList.insert(0, parent.obj);
			parent = parent.groupParent;
		}

		@:privateAccess
		for (p in parentsList) {
			oldDefaultCamerasList.push(FlxCamera._defaultCameras);
			var group:FlxBasic = cast p;
			if (group._cameras != null) FlxCamera._defaultCameras = group._cameras;
		}

		var camera = basic.getDefaultCamera();

		@:privateAccess
		if (oldDefaultCamerasList.length > 0) FlxCamera._defaultCameras = oldDefaultCamerasList[0]; //no point looping back, just grab first

		return camera;
	}

	function showObjectGizmo(object:FlxObject) {
		var sprite:FlxSprite = cast object;
		var drawList = ImGui.getForegroundDrawList(ImGui.getMainViewport());

		var camera = prepareObjectCamera(object);
		var bounds = object.getScreenPosition(null, camera);
		var position = bounds.clone();
		var origin = bounds.clone();
		if (sprite != null) {
			bounds.subtractPoint(sprite.offset);
			origin.addPoint(sprite.origin);
		}
		transformFlxPointOntoCamera(bounds, camera);
		transformFlxPointToWindowSpace(bounds);
		transformFlxPointOntoCamera(position, camera);
		transformFlxPointToWindowSpace(position);
		transformFlxPointOntoCamera(origin, camera);
		transformFlxPointToWindowSpace(origin);

		if (sprite == null)
		{
			var x = bounds.x;
			var y = bounds.y;
			var right = x + (object.width * camera.zoom);
			var bottom = y + (object.height * camera.zoom);
			/*var minX = Lib.application.window.x + FlxG.scaleMode.offset.x;
			var minY = Lib.application.window.y + FlxG.scaleMode.offset.y;
			var maxX = Lib.application.window.x + FlxG.scaleMode.offset.x + FlxG.scaleMode.gameSize.x;
			var maxY = Lib.application.window.y + FlxG.scaleMode.offset.y + FlxG.scaleMode.gameSize.y;
			
			if (x < minX) x = minX;
			if (y < minY) y = minY;
			if (right > maxX) right = maxX;
			if (bottom > maxY) bottom = maxY;*/
			drawList.addRect([x, y, right, bottom], 0xFFB922F5, 0, 4);
		}
		else
		{
			if (sprite.frame != null) {
				@:privateAccess
				var matrix:FlxMatrix = sprite._matrix;
				//var pointTL = new Point(sprite.frame.x, sprite.frame.frame.y);
				//var pointTR = new Point(sprite.frame.frame.x + sprite.frame.frame.width, sprite.frame.frame.y);
				//var pointBL = new Point(sprite.frame.frame.x, sprite.frame.frame.y + sprite.frame.frame.height);
				//var pointBR = new Point(sprite.frame.frame.x + sprite.frame.frame.width, sprite.frame.frame.y + sprite.frame.frame.height);
				//var pointTL = FlxPoint.get(sprite.frame.offset.x, sprite.frame.offset.y);
				//var pointTR = FlxPoint.get(pointTL.x + sprite.frame.frame.width, pointTL.y);
				//var pointBL = FlxPoint.get(pointTL.x, pointTL.y + sprite.frame.frame.height);
				//var pointBR = FlxPoint.get(pointTL.x + sprite.frame.frame.width, pointTL.y + sprite.frame.frame.height);

				var pointTL = FlxPoint.get(0, 0);
				var pointTR = FlxPoint.get(0 + sprite.frame.frame.width, 0);
				var pointBL = FlxPoint.get(0, 0 + sprite.frame.frame.height);
				var pointBR = FlxPoint.get(0 + sprite.frame.frame.width, 0 + sprite.frame.frame.height);
				
				pointTL = pointTL.transform(matrix);
				pointTR = pointTR.transform(matrix);
				pointBL = pointBL.transform(matrix);
				pointBR = pointBR.transform(matrix);
				transformFlxPointOntoCamera(pointTL, camera);
				transformFlxPointOntoCamera(pointTR, camera);
				transformFlxPointOntoCamera(pointBL, camera);
				transformFlxPointOntoCamera(pointBR, camera);
				transformFlxPointToWindowSpace(pointTL);
				transformFlxPointToWindowSpace(pointTR);
				transformFlxPointToWindowSpace(pointBL);
				transformFlxPointToWindowSpace(pointBR);
				drawList.addQuad([pointTL.x, pointTL.y, pointTR.x, pointTR.y, pointBR.x, pointBR.y, pointBL.x, pointBL.y], 0xFFB922F5, 4);
			}
		}

		drawList.addCircleFilled(position.x, position.y, 5, 0xFFFF0000);
		if (sprite != null) {
			drawList.addCircleFilled(origin.x, origin.y, 5, 0xFF1500FF);
		}
	}
}

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

	#end
}