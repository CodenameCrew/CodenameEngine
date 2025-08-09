package funkin.editors;

import funkin.editors.ui.old.OldUISliceSpriteTri;
import funkin.editors.ui.UITopMenu.UITopMenuButton;
import flixel.tweens.FlxTween;
import funkin.editors.ui.*;
import funkin.game.Character;

class UIDebugState extends UIState {
	public var topMenuSpr:UITopMenu;

	public var testingUIItems:Array<FlxSprite> = [];
	public var testingUIHidden:Bool = false;

	public override function create() {
		super.create();

		FlxG.mouse.useSystemCursor = FlxG.mouse.visible = true;

		var bg = new FlxSprite().makeSolid(FlxG.width, FlxG.height, 0xFF444444);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		var gf = new Character(0, 0, "gf");
		gf.dance();
		add(gf);

		add(topMenuSpr = new UITopMenu([
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
			},
			{
				label: "9-Splice Benchmark >",
				childs: [
					{
						label: "Hide Other UI Items",
						onSelect: (t) -> {
							testingUIHidden = !testingUIHidden;
							t.icon = testingUIHidden ? 1 : 0;

							for (item in testingUIItems)
								item.visible = !testingUIHidden;
						},
						icon: testingUIHidden ? 1 : 0
					},
					{
						label: "Clear Benchmark Sprites",
						onSelect: (t) -> {
							for (splice in spliceSprites) {
								splice.kill();
								splice.destroy();

								this.remove(splice);
							}

							spliceSprites.resize(0);
							MemoryUtil.clearMajor();
						}
					},
					null,
					{
						label: "Draw Triangles?",
						onSelect: (t) -> {
							spliceUseTris = !spliceUseTris;
							t.icon = spliceUseTris ? 1 : 0;

							spliceCl = spliceUseTris ? OldUISliceSpriteTri : UISliceSprite;
							trace(spliceCl);
						},
						icon: spliceUseTris ? 1 : 0
					}
				]
			}
		]));

		testingUIItems.push(cast add(new UICheckbox(10, 40, "Test unchecked", false)));
		testingUIItems.push(cast add(new UICheckbox(10, 70, "Test checked", true)));
		testingUIItems.push(cast add(new UIButton(10, 100, "Test button", function() {
			trace("Hello, World!");
		}, 130, 32)));
		testingUIItems.push(cast add(new UIButton(10, 140, "Warning test", function() {
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
		}, 130, 32)));
		testingUIItems.push(cast add(new UIButton(10, 180, "Warning test (Overflowing)", function() {
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
		}, 130, 48)));
		testingUIItems.push(cast add(new UITextBox(10, 220, "")));

		spliceText = new UIText(0, 0, 0, "(0) Sprites");
		add(spliceText);
	}

	public var spliceSprites:Array<FlxSprite> = [];
	public var spliceText:UIText;

	public var spliceTimer:Float = 0;
	public var spliceCoolDown:Float = 0.04;

	public var spliceUseTris:Bool = false;
	public var spliceCl:Class<FlxSprite> = UISliceSprite;

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.pressed.SPACE) {
			spliceTimer += elapsed;
			if (spliceTimer >= spliceCoolDown) {
				spliceTimer -= spliceCoolDown;

				for (i in 0...3) {
					var width:Int = FlxG.random.int(10, 200);
					var height:Int = FlxG.random.int(10, 200);

					var spliceSprite:FlxSprite = Type.createInstance(spliceCl,
						[
							FlxG.random.float(0, FlxG.width-width), 
							FlxG.random.float(22, FlxG.height-height), 
							width, height, "editors/ui/context-bg"
						]
					);
	
					spliceSprites.push(cast add(spliceSprite));
				}
			}
		}

		var spliceTopButton:UITopMenuButton = cast topMenuSpr.members[topMenuSpr.members.length-1];

		spliceText.x = spliceTopButton.x + spliceTopButton.bWidth - 2;
		spliceText.y = spliceTopButton.label.y+1;

		spliceText.text = '(${spliceSprites.length}) 9-Splice Sprites';

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