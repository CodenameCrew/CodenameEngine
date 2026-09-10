package funkin.backend.system.console.inspector;

import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import openfl.Lib;
import lime.math.Vector2;
import openfl.geom.Vector3D;
import funkin.backend.system.console.inspector.ConsoleInspector.InspectorObject;

#if IMGUI_ENABLED
import lime.tools.imgui.ImGuiFlags;
import lime.tools.imgui.ImGuiTypes;
import lime.tools.imgui.ImGuiPtr;
#end
#if foxlite
import foxlite.FoxScene;
import foxlite.FoxBasic;
import foxlite.FoxObject;
import foxlite.FoxModel;
import foxlite.FoxCamera;
#end

class InspectorGizmo3D {

	var gizmoMode:Int = 0;
	var lastViewportID:Int = 0;

	var size:Float = 120;
	var arrowWidth = 10;

	var snapPos:Float = 0.1;
	var snapAngle:Float = 15;
	var snapScale:Float = 0.1;

	public function new() {}

	#if (IMGUI_ENABLED && foxlite)

	inline function transformVector3DScreenSpaceToWindowSpace(point:Vector3D) {
		if ((ImGuiIO.configFlags & ImGuiConfigFlags.ViewportsEnable) != 0) {
			point.x = (Lib.application.window.x + FlxG.scaleMode.offset.x) + (point.x * FlxG.scaleMode.scale.x);
			point.y = (Lib.application.window.y + FlxG.scaleMode.offset.y) + (point.y * FlxG.scaleMode.scale.y);
		} else {
			point.x = (FlxG.scaleMode.offset.x) + (point.x * FlxG.scaleMode.scale.x);
			point.y = (FlxG.scaleMode.offset.y) + (point.y * FlxG.scaleMode.scale.y);
		}
	}

	inline function transformVector3DWorldSpaceToScreenSpace(point:Vector3D, camera:FoxCamera, scene:FoxScene, clamp:Bool = false) {
		var screen = camera.getScreenPoint(point);
		point.x = screen.x;
		point.y = screen.y;
		point.x = ((point.x*0.5) + 0.5);
		point.y = (-((point.y*0.5) + 0.5) + 1.0);
		if (clamp) {
			point.x = FlxMath.bound(point.x, 0, 1);
			point.y = FlxMath.bound(point.y, 0, 1);
		}
		point.x *= scene.__width;
		point.y *= scene.__height;
	}

	function figureOutScene(objectData:InspectorObject, object:FoxObject) {
		var parent = objectData.groupParent;
		while(parent != null) {
			if (parent.obj is FoxScene) {
				return parent.obj;
			} else if (parent.obj is FoxBasic) {
				var basic:FoxBasic = cast parent.obj;
				if (basic.scene != null) return basic.scene;
			}
			parent = parent.groupParent;
		}
		return null;
	}

	public function show(objectData:InspectorObject, object:FoxObject, justChanged:Bool) {
		var model:FoxModel = cast object;
		var drawList = ImGui.getBackgroundDrawList(ImGui.getMainViewport());
		var scene:FoxScene = object.scene;
		if (scene == null) scene = figureOutScene(objectData, object);
		var camera:FoxCamera = scene.foxCameras[0];
		if (camera == null) return;

		var position = camera.getScreenPoint(object.position);
		position.x = ((position.x*0.5) + 0.5) * scene.__width;
		position.y = (-((position.y*0.5) + 0.5) + 1.0) * scene.__height;

		var position = object.position.clone();
		transformVector3DWorldSpaceToScreenSpace(position, camera, scene);
		transformVector3DScreenSpaceToWindowSpace(position);
		drawList.addCircleFilled(position.x, position.y, 10, 0xFFFF0000);

		if (model != null) {
			for (mesh in model.meshes) {
				if (mesh.bounds != null) {
					
					var topTopLeft = model.transform.transformVector(new Vector3D(mesh.bounds.center.x - mesh.bounds.extents.x, mesh.bounds.center.y - mesh.bounds.extents.y, mesh.bounds.center.z - mesh.bounds.extents.z));
					var topTopRight = model.transform.transformVector(new Vector3D(mesh.bounds.center.x + mesh.bounds.extents.x, mesh.bounds.center.y - mesh.bounds.extents.y, mesh.bounds.center.z - mesh.bounds.extents.z));
					var topBottomLeft = model.transform.transformVector(new Vector3D(mesh.bounds.center.x - mesh.bounds.extents.x, mesh.bounds.center.y - mesh.bounds.extents.y, mesh.bounds.center.z + mesh.bounds.extents.z));
					var topBottomRight = model.transform.transformVector(new Vector3D(mesh.bounds.center.x + mesh.bounds.extents.x, mesh.bounds.center.y - mesh.bounds.extents.y, mesh.bounds.center.z + mesh.bounds.extents.z));

					var bottomTopLeft = model.transform.transformVector(new Vector3D(mesh.bounds.center.x - mesh.bounds.extents.x, mesh.bounds.center.y + mesh.bounds.extents.y, mesh.bounds.center.z - mesh.bounds.extents.z));
					var bottomTopRight = model.transform.transformVector(new Vector3D(mesh.bounds.center.x + mesh.bounds.extents.x, mesh.bounds.center.y + mesh.bounds.extents.y, mesh.bounds.center.z - mesh.bounds.extents.z));
					var bottomBottomLeft = model.transform.transformVector(new Vector3D(mesh.bounds.center.x - mesh.bounds.extents.x, mesh.bounds.center.y + mesh.bounds.extents.y, mesh.bounds.center.z + mesh.bounds.extents.z));
					var bottomBottomRight = model.transform.transformVector(new Vector3D(mesh.bounds.center.x + mesh.bounds.extents.x, mesh.bounds.center.y + mesh.bounds.extents.y, mesh.bounds.center.z + mesh.bounds.extents.z));

					//TODO: fix offscreen weirdness
					transformVector3DWorldSpaceToScreenSpace(topTopLeft, camera, scene); transformVector3DScreenSpaceToWindowSpace(topTopLeft);
					transformVector3DWorldSpaceToScreenSpace(topTopRight, camera, scene); transformVector3DScreenSpaceToWindowSpace(topTopRight);
					transformVector3DWorldSpaceToScreenSpace(topBottomLeft, camera, scene); transformVector3DScreenSpaceToWindowSpace(topBottomLeft);
					transformVector3DWorldSpaceToScreenSpace(topBottomRight, camera, scene); transformVector3DScreenSpaceToWindowSpace(topBottomRight);
					transformVector3DWorldSpaceToScreenSpace(bottomTopLeft, camera, scene); transformVector3DScreenSpaceToWindowSpace(bottomTopLeft);
					transformVector3DWorldSpaceToScreenSpace(bottomTopRight, camera, scene); transformVector3DScreenSpaceToWindowSpace(bottomTopRight);
					transformVector3DWorldSpaceToScreenSpace(bottomBottomLeft, camera, scene); transformVector3DScreenSpaceToWindowSpace(bottomBottomLeft);
					transformVector3DWorldSpaceToScreenSpace(bottomBottomRight, camera, scene); transformVector3DScreenSpaceToWindowSpace(bottomBottomRight);

					drawList.addQuad([topTopLeft.x, topTopLeft.y, topTopRight.x, topTopRight.y, topBottomRight.x, topBottomRight.y, topBottomLeft.x, topBottomLeft.y], 0xFFB922F5, 4);
					drawList.addLine([topTopLeft.x, topTopLeft.y, bottomTopLeft.x, bottomTopLeft.y], 0xFFB922F5, 4);
					drawList.addLine([topTopRight.x, topTopRight.y, bottomTopRight.x, bottomTopRight.y], 0xFFB922F5, 4);
					drawList.addLine([topBottomLeft.x, topBottomLeft.y, bottomBottomLeft.x, bottomBottomLeft.y], 0xFFB922F5, 4);
					drawList.addLine([topBottomRight.x, topBottomRight.y, bottomBottomRight.x, bottomBottomRight.y], 0xFFB922F5, 4);
					drawList.addQuad([bottomTopLeft.x, bottomTopLeft.y, bottomTopRight.x, bottomTopRight.y, bottomBottomRight.x, bottomBottomRight.y, bottomBottomLeft.x, bottomBottomLeft.y], 0xFFB922F5, 4);
				}
			}
		}

		if (justChanged) {

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
			ImGui.begin("3dGizmo", null, flags);
			if ((ImGuiIO.configFlags & ImGuiConfigFlags.ViewportsEnable) != 0) lastViewportID = ImGui.getWindowViewport().id;
			
			if (gizmoMode == 0) {
				//showPositionGizmo(object, position);
			} else if (gizmoMode == 1) {
				//showRotationGizmo(object, position);
			} else if (gizmoMode == 2) {
				//showScaleGizmo(sprite, position);
			}

			ImGui.end();	
		}
		
	}

	#end
}