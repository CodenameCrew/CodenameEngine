package funkin.editors;

import funkin.editors.ui.*;
import flixel.tweens.FlxTween;

class UIDebugState extends UIState {
	public override function create() {
		super.create();

		FlxG.mouse.useSystemCursor = !controls.touchC;
		FlxG.mouse.visible = true;

		var bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF444444);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		add(new UITopMenu([
			{
				label: "File",
				childs: [
					{
						label: "New"
					},
					{
						label: "Open"
					},
					{
						label: "Save"
					},
					{
						label: "Save As..."
					},
					null,
					{
						label: "Exit",
						onSelect: (t) -> {FlxG.switchState(new funkin.menus.MainMenuState());}
					}
				]
			},
			{
				label: "Edit"
			},
			{
				label: "View"
			},
			{
				label: "Help"
			}
		]));

		add(new UICheckbox(10, 40, "Test unchecked", false));
		add(new UICheckbox(10, 70, "Test checked", true));
		add(new UIButton(10, 100, "Test button", function() {
			trace("Hello, World!");
		}, 130, 32));
		add(new UIButton(10, 140, "Warning test", function() {
			openSubState(new UIWarningSubstate("Test", "This is a test message", [
				{
					label: "Alt. Choice",
					onClick: function(t) {
						trace("Alt. Choice clicked!");
					}
				},
				{
					label: "OK",
					onClick: function(t) {

					}
				}
			]));
		}, 130, 32));
		add(new UIButton(10, 180, "Warning test (Overflowing)", function() {
			openSubState(new UIWarningSubstate("Test", "This is a test message", [
				{
					label: "Alt. Choice",
					onClick: function(t) {
						trace("Alt. Choice clicked!");
					}
				},
				{
					label: "OK",
					onClick: function(t) {}
				},
				{
					label: "1",
					onClick: function(t) {}
				},
				{
					label: "2",
					onClick: function(t) {}
				},
				{
					label: "3",
					onClick: function(t) {}
				},
				{
					label: "4",
					onClick: function(t) {}
				}
			]));
		}, 130, 48));
		add(new UITextBox(10, 220, ""));

		var spliceSprite:UISliceSprite = new UISliceSprite(650, 350, 30, 30, "editors/ui/context-bg");
		add(spliceSprite);
		FlxTween.num(0, 1, 2, {type: PINGPONG}, function (v:Float) {
			spliceSprite.bWidth = Std.int(lerp(12, 200, v)); spliceSprite.bHeight = Std.int(lerp(12, 200, v));
		});
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (FlxG.mouse.justReleasedRight) {
			openContextMenu([
				{
					label: "Test 1",
					onSelect: function(t) {
						trace("Test 1 clicked");
					}
				},
				{
					label: "Test 2",
					onSelect: function(t) {
						trace("Test 2 clicked");
					}
				},
				{
					label: "Test 3",
					childs: [
						{
							label: "Test 4",
							onSelect: function(t) {
								trace("Test 4 clicked");
							}
						}
					]
				}
			]);
		}
	}
}