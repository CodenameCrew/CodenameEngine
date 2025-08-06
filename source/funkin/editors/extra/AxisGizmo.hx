package funkin.editors.extra;

class AxisGizmo extends FlxObject {
	var _worldPos:FlxPoint = FlxPoint.get();

	public override function draw() {
		super.draw();

		for (camera in cameras) {
			if (DrawUtil.line == null) DrawUtil.createDrawers();
			DrawUtil.line.camera = camera; DrawUtil.line.alpha = 0.85;

			CoolUtil.pointToScreenPosition(FlxPoint.weak(), FlxG.camera, _worldPos);
			// Stole these colors directly from godot >:D -luanr
			DrawUtil.drawLine(
				FlxPoint.weak(_worldPos.x, 0), 
				FlxPoint.weak(_worldPos.x, camera.height), 
			1, 0xFF76BC02);

			DrawUtil.drawLine(
				FlxPoint.weak(0, _worldPos.y), 
				FlxPoint.weak(camera.width, _worldPos.y),
			1, 0xFFD72C47);
		}
	}

	public override function destroy() {
		super.destroy();
		_worldPos.put();
	}
}