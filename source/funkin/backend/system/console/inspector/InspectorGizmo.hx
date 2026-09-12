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

	public var gizmoMode:Int = 0;
	var lastViewportID:Int = 0;
	var positionActive:Bool = false;
	var positionX:Float = 0;
	var positionY:Float = 0;
	var rotationActive:Bool = false;
	var rotationStartX:Float = 0;
	var rotationStartY:Float = 0;
	var rotationStartAngle:Float = 0;
	var scaleActive:Bool = false;
	var scaleX:Float = 0;
	var scaleY:Float = 0;

	var size:Float = 120;
	var arrowWidth = 10;
	var scaleBoxWidth = 15;

	var moveSpeedPos:Float = 1;
	var moveSpeedScale:Float = 0.05;

	var snapPos:Float = 50;
	var snapAngle:Float = 15;
	var snapScale:Float = 0.25;

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

		if (ImGui.isKeyPressed(ImGuiKey.Q)) gizmoMode = -1;
		if (ImGui.isKeyPressed(ImGuiKey.W)) gizmoMode = 0;
		if (ImGui.isKeyPressed(ImGuiKey.E)) gizmoMode = 1;
		if (ImGui.isKeyPressed(ImGuiKey.R)) gizmoMode = 2;

		if (gizmoMode > -1) {
			var windowX = position.x-(size/2);
			var windowY = position.y-(size/2);
			ImGui.setNextWindowPos(windowX, windowY);
			ImGui.setNextWindowSize(size, size);
			var flags = ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.NoDocking | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoSavedSettings | ImGuiWindowFlags.NoFocusOnAppearing;
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
			positionY += ImGuiIO.mouseDeltaY*moveSpeedPos;
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
			positionX += ImGuiIO.mouseDeltaX*moveSpeedPos;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				object.x = Math.fround(positionX / snapPos) * snapPos;
			} else {
				object.x = positionX;
			}
		}

		ImGui.setCursorPos(halfSizeMinusHalfArrow, halfSizeMinusHalfArrow);
		ImGui.invisibleButton("##centerArrow", arrowWidth, arrowWidth);
		var centerHover = ImGui.isItemHovered();
		var centerActive = ImGui.isItemActive();
		var centerDragged = ImGui.isItemActive() && ImGui.isMouseDragging(0);
		if (centerDragged) {
			if (!positionActive) {
				positionX = object.x;
				positionY = object.y;
				positionActive = true;
			}
			positionX += ImGuiIO.mouseDeltaX*moveSpeedPos;
			positionY += ImGuiIO.mouseDeltaY*moveSpeedPos;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				object.x = Math.fround(positionX / snapPos) * snapPos;
				object.y = Math.fround(positionY / snapPos) * snapPos;
			} else {
				object.x = positionX;
				object.y = positionY;
			}
		}

		if (vertActive || horiActive || centerActive) {
			var text = FlxMath.roundDecimal(object.x, 2) + ", " + FlxMath.roundDecimal(object.y, 2);
			var size = ImGui.calcTextSize(text);
			var offset = halfSize - (size.x/2);
			ImGui.setCursorPos(offset, halfSizePlusHalfArrow);
			windowDrawList.addRectFilled([windowX + offset, windowY + halfSizePlusHalfArrow, windowX + size.x + offset, windowY + halfSizePlusHalfArrow + size.y], 0x94000000, 2);
			ImGui.text(text);
		} else {
			positionActive = false;
		}

		{
			var color = 0xFF76BC02;
			if (vertDragged) color = 0xFFC1F273;
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
			if (horiDragged) color = 0xFFFB899A;
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

		{
			var color = 0xFFA2A2A2;
			if (centerDragged) color = 0xFFFFFFFF;
			else if (centerHover) color = 0xFFC4C3C3;
			windowDrawList.addRectFilled([windowX + halfSizeMinusHalfArrow, windowY + halfSizeMinusHalfArrow,
										  windowX + halfSizePlusHalfArrow, windowY + halfSizePlusHalfArrow], color, 2);
		}
	}


	function showRotationGizmo(object:FlxObject, position:FlxPoint) {

		var windowDrawList = ImGui.getWindowDrawList();
		var windowX = position.x-(size/2);
		var windowY = position.y-(size/2);
		var halfSize = size/2;
		var halfArrow = arrowWidth/2;
		var lineLength = halfSize-halfArrow;
		var halfSizeMinusHalfArrow = halfSize-halfArrow;
		var halfSizePlusHalfArrow = halfSize+halfArrow;

		ImGui.setCursorPos(0, 0);
		ImGui.invisibleButton("##rotation", size, size);
		var hover = ImGui.isItemHovered();
		var active = ImGui.isItemActive();
		var dragged = ImGui.isItemActive() && ImGui.isMouseDragging(0);
		if (dragged) {
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

				var rad = (rotationStartAngle-90) * (Math.PI/180);
				windowDrawList.addLine([windowX + halfSize, windowY + halfSize,
					windowX + halfSize + (Math.cos(rad)*lineLength), windowY + halfSize + (Math.sin(rad)*lineLength)], 0xFF737373, halfArrow);
				
				start.put();
				cur.put();
			}
		} else {
			rotationActive = false;
		}

		var rad = (object.angle-90) * (Math.PI/180);
		windowDrawList.addLine([windowX + halfSize, windowY + halfSize,
								windowX + halfSize + (Math.cos(rad)*lineLength), windowY + halfSize + (Math.sin(rad)*lineLength)], 0xFFCDCDCD, halfArrow);

		var color = 0xFF298cf5;
		if (dragged) color = 0xff7fb6f1;
		else if (hover) color = 0xff4a9aef;
		windowDrawList.addCircle(windowX + halfSize, windowY + halfSize, halfSize-(halfArrow/2), color, 0, halfArrow);

		if (active) {
			var text = FlxMath.roundDecimal(object.angle, 2) + "°";
			var size = ImGui.calcTextSize(text);
			var offset = halfSize - (size.x/2);
			ImGui.setCursorPos(offset, halfSizePlusHalfArrow);
			windowDrawList.addRectFilled([windowX + offset, windowY + halfSizePlusHalfArrow, windowX + size.x + offset, windowY + halfSizePlusHalfArrow + size.y], 0x94000000, 2);
			ImGui.text(text);
		} else {
			rotationActive = false;
		}
	}

	function showScaleGizmo(sprite:FlxSprite, position:FlxPoint) {

		var windowDrawList = ImGui.getWindowDrawList();
		var windowX = position.x-(size/2);
		var windowY = position.y-(size/2);
		var halfSize = size/2;
		var halfBox = scaleBoxWidth/2;
		var halfSizeMinusHalfBox = halfSize-halfBox;
		var halfSizePlusHalfBox = halfSize+halfBox;
		var halfArrow = arrowWidth/2;
		var halfSizeMinusHalfArrow = halfSize-halfArrow;
		var halfSizePlusHalfArrow = halfSize+halfArrow;

		ImGui.setCursorPos(halfSizeMinusHalfArrow, 0);
		ImGui.invisibleButton("##vertArrow", arrowWidth, halfSizeMinusHalfArrow);
		var vertHover = ImGui.isItemHovered();
		var vertActive = ImGui.isItemActive();
		var vertDragged = ImGui.isItemActive() && ImGui.isMouseDragging(0);
		if (vertDragged) {
			if (!scaleActive) {
				scaleX = sprite.scale.x;
				scaleY = sprite.scale.y;
				scaleActive = true;
			}
			scaleY -= ImGuiIO.mouseDeltaY*moveSpeedScale;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				sprite.scale.y = Math.fround(scaleY / snapScale) * snapScale;
			} else {
				sprite.scale.y = scaleY;
			}
		}

		ImGui.setCursorPos(halfSizePlusHalfArrow, halfSizeMinusHalfArrow);
		ImGui.invisibleButton("##horiArrow", halfSizeMinusHalfArrow, arrowWidth);
		var horiHover = ImGui.isItemHovered();
		var horiActive = ImGui.isItemActive();
		var horiDragged = ImGui.isItemActive() && ImGui.isMouseDragging(0);
		if (horiDragged) {
			if (!scaleActive) {
				scaleX = sprite.scale.x;
				scaleY = sprite.scale.y;
				scaleActive = true;
			}
			scaleX += ImGuiIO.mouseDeltaX*moveSpeedScale;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				sprite.scale.x = Math.fround(scaleX / snapScale) * snapScale;
			} else {
				sprite.scale.x = scaleX;
			}
		}

		ImGui.setCursorPos(halfSizeMinusHalfBox, halfSizeMinusHalfBox);
		ImGui.invisibleButton("##scaleCenter", scaleBoxWidth, scaleBoxWidth);
		var centerHover = ImGui.isItemHovered();
		var centerActive = ImGui.isItemActive();
		var centerDragged = ImGui.isItemActive() && ImGui.isMouseDragging(0);
		if (centerDragged) {
			if (!scaleActive) {
				scaleX = sprite.scale.x;
				scaleY = sprite.scale.y;
				scaleActive = true;
			}
			scaleX += ImGuiIO.mouseDeltaX*moveSpeedScale;
			scaleY -= ImGuiIO.mouseDeltaY*moveSpeedScale;
			if (ImGui.isKeyDown(ImGuiKey.LeftCtrl)) {
				sprite.scale.x = Math.fround(scaleX / snapScale) * snapScale;
				sprite.scale.y = Math.fround(scaleY / snapScale) * snapScale;
			} else {
				sprite.scale.x = scaleX;
				sprite.scale.y = scaleY;
			}
		}

		if (vertActive || horiActive || centerActive) {
			var text = FlxMath.roundDecimal(sprite.scale.x, 2) + ", " + FlxMath.roundDecimal(sprite.scale.y, 2);
			var size = ImGui.calcTextSize(text);
			var offset = halfSize - (size.x/2);
			ImGui.setCursorPos(offset, halfSizePlusHalfArrow);
			windowDrawList.addRectFilled([windowX + offset, windowY + halfSizePlusHalfArrow, windowX + size.x + offset, windowY + halfSizePlusHalfArrow + size.y], 0x94000000, 2);
			ImGui.text(text);
		} else {
			scaleActive = false;
		}

		{
			var color = 0xFF76BC02;
			if (vertDragged) color = 0xFFC1F273;
			else if (vertHover) color = 0xFF8ED914;
			windowDrawList.addLine([windowX + halfSize, 
									windowY + arrowWidth, 
									windowX + halfSize, 
									windowY + halfSizeMinusHalfArrow], color, arrowWidth/2);
			windowDrawList.addRectFilled([windowX + halfSizeMinusHalfBox, windowY,
										  windowX + halfSizePlusHalfBox, windowY + scaleBoxWidth], color);
		}

		{
			var color = 0xFFD72C47;
			if (horiDragged) color = 0xFFFB899A;
			else if (horiHover) color = 0xFFF35069;
			windowDrawList.addLine([windowX + size - arrowWidth,
									windowY + halfSize,
									windowX + halfSizePlusHalfArrow, 
									windowY + halfSize], color, arrowWidth/2);
			windowDrawList.addRectFilled([windowX + size - scaleBoxWidth, windowY + halfSizeMinusHalfBox,
										  windowX + size, windowY + halfSizePlusHalfBox], color);
		}

		{
			var color = 0xFFA2A2A2;
			if (centerDragged) color = 0xFFFFFFFF;
			else if (centerHover) color = 0xFFC4C3C3;
			windowDrawList.addRectFilled([windowX + halfSizeMinusHalfBox, windowY + halfSizeMinusHalfBox,
										  windowX + halfSizePlusHalfBox, windowY + halfSizePlusHalfBox], color);
		}
	}

	#end
}