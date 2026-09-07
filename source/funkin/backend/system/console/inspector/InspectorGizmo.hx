package funkin.backend.system.console.inspector;

import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import openfl.Lib;
import funkin.backend.system.console.inspector.ConsoleInspector.InspectorObject;

#if IMGUI_ENABLED
import lime.tools.imgui.ImGuiFlags;
import lime.tools.imgui.ImGuiTypes;
import lime.tools.imgui.ImGuiPtr;
#end

class InspectorGizmo {

	var gizmoMode:Int = 0;
	var lastViewportID:Int = 0;
	var positionActive:Bool = false;
	var positionX:Float = 0;
	var positionY:Float = 0;
	var rotationActive:Bool = false;
	var rotationStartX:Float = 0;
	var rotationStartY:Float = 0;
	var rotationStartAngle:Float = 0;
	var scaleActive:Bool = false;
	var scaleStartX:Float = 0;
	var scaleStartY:Float = 0;

	var size:Float = 120;
	var arrowWidth = 10;

	var snapPos:Float = 50;
	var snapAngle:Float = 15;
	var snapScale:Float = 0.2;

	public function new() {}

	#if IMGUI_ENABLED
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

	function prepareObjectCamera(objectData:InspectorObject, basic:FlxBasic) {
		var parentsList:Array<Dynamic> = [];
		var oldDefaultCamerasList:Array<Array<FlxCamera>> = [];
		
		var parent = objectData.groupParent;
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

	public function show(objectData:InspectorObject, object:FlxObject, justChanged:Bool) {
		var sprite:FlxSprite = cast object;
		var drawList = ImGui.getBackgroundDrawList(ImGui.getMainViewport());

		if (justChanged) {
			positionActive = false;
			rotationActive = false;
			scaleActive = false;
		}

		var camera = prepareObjectCamera(objectData, object);
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

				pointTL.put();
				pointTR.put();
				pointBL.put();
				pointBR.put();
			}
		}

		//drawList.addCircleFilled(position.x, position.y, 5, 0xFFFF0000);
		if (sprite != null) {
			//drawList.addCircleFilled(origin.x, origin.y, 5, 0xFF1500FF);
		}

		if (ImGui.isKeyPressed(ImGuiKey.Q)) gizmoMode = -1;
		if (ImGui.isKeyPressed(ImGuiKey.W)) gizmoMode = 0;
		if (ImGui.isKeyPressed(ImGuiKey.E)) gizmoMode = 1;
		if (ImGui.isKeyPressed(ImGuiKey.R)) gizmoMode = 2;

		if (gizmoMode > -1) {
			var windowX = position.x-(size/2);
			var windowY = position.y-(size/2);
			ImGui.setNextWindowPos(windowX, windowY);
			ImGui.setNextWindowSize(size, size);
			var flags = ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.NoDocking | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoSavedSettings;
			if ((ImGuiIO.configFlags & ImGuiConfigFlags.ViewportsEnable) == 0 || lastViewportID == ImGui.getMainViewport().id) {
				flags |= ImGuiWindowFlags.NoBackground;
				ImGui.setNextWindowBGAlpha(0);
			}
			ImGui.begin("2dGizmo", null, flags);
			if ((ImGuiIO.configFlags & ImGuiConfigFlags.ViewportsEnable) != 0) lastViewportID = ImGui.getWindowViewport().id;
			
			if (gizmoMode == 0) {
				showPositionGizmo(object, position);
			} else if (gizmoMode == 1) {
				showRotationGizmo(object, position);
			} else if (gizmoMode == 2 && sprite != null) {
				showScaleGizmo(sprite, position);
			}

			ImGui.end();	
		}
		
	}

	function showPositionGizmo(object:FlxObject, position:FlxPoint) {

		var windowDrawList = ImGui.getWindowDrawList();
		var windowX = position.x-(size/2);
		var windowY = position.y-(size/2);
		var halfSize = size/2;
		var halfArrow = arrowWidth/2;
		var halfSizeMinusHalfArrow = halfSize-halfArrow;
		var halfSizePlusHalfArrow = halfSize+halfArrow;

		ImGui.setCursorPos(halfSizeMinusHalfArrow, 0);
		ImGui.invisibleButton("##vertArrow", arrowWidth, halfSizeMinusHalfArrow);

		var vertHover = ImGui.isItemHovered();
		var vertActive = ImGui.isItemActive();
		var vertDragged = ImGui.isItemActive() && ImGui.isMouseDragging(0);
		if (vertDragged) {
			if (!positionActive) {
				positionX = object.x;
				positionY = object.y;
				positionActive = true;
			}
			positionY += ImGuiIO.mouseDeltaY;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				object.y = Math.fround(positionY / snapPos) * snapPos;
			} else {
				object.y = positionY;
			}
		}

		ImGui.setCursorPos(halfSizePlusHalfArrow, halfSizeMinusHalfArrow);
		ImGui.invisibleButton("##horiArrow", halfSizeMinusHalfArrow, arrowWidth);
		var horiHover = ImGui.isItemHovered();
		var horiActive = ImGui.isItemActive();
		var horiDragged = ImGui.isItemActive() && ImGui.isMouseDragging(0);
		if (horiDragged) {
			if (!positionActive) {
				positionX = object.x;
				positionY = object.y;
				positionActive = true;
			}
			positionX += ImGuiIO.mouseDeltaX;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				object.x = Math.fround(positionX / snapPos) * snapPos;
			} else {
				object.x = positionX;
			}
		}

		ImGui.setCursorPos(halfSizeMinusHalfArrow, halfSizeMinusHalfArrow);
		ImGui.button("##centerArrow", arrowWidth, arrowWidth);
		var centerHover = ImGui.isItemHovered();
		var centerActive = ImGui.isItemActive();
		var centerDragged = ImGui.isItemActive() && ImGui.isMouseDragging(0);
		if (centerDragged) {
			if (!positionActive) {
				positionX = object.x;
				positionY = object.y;
				positionActive = true;
			}
			positionX += ImGuiIO.mouseDeltaX;
			positionY += ImGuiIO.mouseDeltaY;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				object.x = Math.fround(positionX / snapPos) * snapPos;
				object.y = Math.fround(positionY / snapPos) * snapPos;
			} else {
				object.x = positionX;
				object.y = positionY;
			}
		}

		if (!vertActive && !horiActive && !centerActive) positionActive = false;
		if (positionActive) {
			ImGui.setCursorPos(0, halfSizePlusHalfArrow);
			var text = FlxMath.roundDecimal(object.x, 2) + ", " + FlxMath.roundDecimal(object.y, 2);
			var size = ImGui.calcTextSize(text);
			windowDrawList.addRectFilled([windowX, windowY + halfSizePlusHalfArrow, windowX + size.x, windowY + halfSizePlusHalfArrow + size.y], 0xFF000000, 5);
			ImGui.text(text);
		}

		{
			var color = 0xFF76BC02;
			if (vertDragged) color = 0xFF9EFF01;
			else if (vertHover) color = 0xFF8ED914;
			windowDrawList.addLine([windowX + halfSize, 
									windowY + arrowWidth, 
									windowX + halfSize, 
									windowY + halfSizeMinusHalfArrow], color, arrowWidth/2);
			windowDrawList.addTriangleFilled([windowX + halfSize, windowY, 
										windowX + halfSize, windowY + arrowWidth,
										windowX + halfSize - arrowWidth, windowY + arrowWidth], color);
			windowDrawList.addTriangleFilled([windowX + halfSize, windowY,
										windowX + halfSize, windowY + arrowWidth,
										windowX + halfSize + arrowWidth, windowY + arrowWidth], color);
		}

		{
			var color = 0xFFD72C47;
			if (horiDragged) color = 0xFFFF0026;
			else if (horiHover) color = 0xFFF35069;
			windowDrawList.addLine([windowX + size - arrowWidth, 
									windowY + halfSize, 
									windowX + halfSizePlusHalfArrow, 
									windowY + halfSize], color, arrowWidth/2);
			windowDrawList.addTriangleFilled([windowX + size, windowY + halfSize, 
										windowX + size - arrowWidth, windowY + halfSize,
										windowX + size - arrowWidth, windowY + halfSize - arrowWidth], color);
			windowDrawList.addTriangleFilled([windowX + size, windowY + halfSize, 
										windowX + size - arrowWidth, windowY + halfSize,
										windowX + size - arrowWidth, windowY + halfSize + arrowWidth], color);
		}
	}


	function showRotationGizmo(object:FlxObject, position:FlxPoint) {

		var windowDrawList = ImGui.getWindowDrawList();
		var windowX = position.x-(size/2);
		var windowY = position.y-(size/2);
		var halfSize = size/2;
		var halfArrow = arrowWidth/2;
		var halfSizeMinusHalfArrow = halfSize-halfArrow;
		var halfSizePlusHalfArrow = halfSize+halfArrow;

		ImGui.setCursorPos(0, 0);
		ImGui.button("##rotation", size, size);
		if (ImGui.isItemActive() && ImGui.isMouseDragging(0)) {
			var mousePos = ImGui.getMousePos();
			if (!rotationActive) {
				rotationActive = true;
				rotationStartX = mousePos.x;
				rotationStartY = mousePos.y;
				rotationStartAngle = object.angle;
			} else {
				var start = FlxPoint.get(rotationStartX - position.x, rotationStartY - position.y);
				var cur = FlxPoint.get(mousePos.x - position.x, mousePos.y - position.y);
				start = start.normalize();
				cur = cur.normalize();

				object.angle = rotationStartAngle + (cur.degrees - start.degrees);
				if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
					object.angle = Math.fround(object.angle / snapAngle) * snapAngle;
				}
				
				start.put();
				cur.put();
			}
		} else {
			rotationActive = false;
		}
	}

	function showScaleGizmo(sprite:FlxSprite, position:FlxPoint) {

		var windowDrawList = ImGui.getWindowDrawList();
		var windowX = position.x-(size/2);
		var windowY = position.y-(size/2);
		var halfSize = size/2;
		var halfArrow = arrowWidth/2;
		var halfSizeMinusHalfArrow = halfSize-halfArrow;
		var halfSizePlusHalfArrow = halfSize+halfArrow;
		var quarterSize = size/4;

		ImGui.setCursorPos(halfSizeMinusHalfArrow, 0);
		ImGui.button("##scaleVert", arrowWidth, arrowWidth);
		if (ImGui.isItemActive() && ImGui.isMouseDragging(0)) {
			sprite.scale.y -= ImGuiIO.mouseDeltaY*0.05;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				sprite.scale.y = Math.fround(sprite.scale.y / snapScale) * snapScale;
			}
		}

		ImGui.setCursorPos(size - arrowWidth, halfSizeMinusHalfArrow);
		ImGui.button("##scaleHori", arrowWidth, arrowWidth);
		if (ImGui.isItemActive() && ImGui.isMouseDragging(0)) {
			sprite.scale.x -= ImGuiIO.mouseDeltaX*0.05;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				sprite.scale.x = Math.fround(sprite.scale.x / snapScale) * snapScale;
			}
		}

		ImGui.setCursorPos(size - arrowWidth, 0);
		ImGui.button("##scaleCenter", arrowWidth, arrowWidth);
		if (ImGui.isItemActive() && ImGui.isMouseDragging(0)) {
			sprite.scale.x += ImGuiIO.mouseDeltaX*0.05;
			sprite.scale.y -= ImGuiIO.mouseDeltaY*0.05;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				sprite.scale.x = Math.fround(sprite.scale.x / snapScale) * snapScale;
				sprite.scale.y = Math.fround(sprite.scale.y / snapScale) * snapScale;
			}
		}
	}

	#end
}