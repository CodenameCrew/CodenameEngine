package funkin.editors.charter;

import flixel.math.FlxPoint;
import haxe.io.Path;

class CharterNoteTypesList extends UISubstateWindow {
	public static var pathString:String = 'data/notes/';

	public var noteTypesList:UIButtonList<NoteTypeButton>;
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public override function create() {
		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		winTitle = 'Note Types List Editor';
		winWidth = 380; winHeight = 390;

		super.create();

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Edit Note Types", 28));

		var noteTypesFileList = getNoteTypesList(true);
		if (noteTypesFileList.length == 0) noteTypesFileList = getNoteTypesList(false);

		noteTypesList = new UIButtonList<NoteTypeButton>(20, title.y + title.height + 10, winWidth - 40, 342 - 85 - 16, "", FlxPoint.get(winWidth - 40, (342 - 85 - 16)/4), null, 0);
		noteTypesList.addButton.callback = () -> noteTypesList.add(new NoteTypeButton(0, 0, 'Note Type ${noteTypesList.buttons.members.length}', noteTypesList.buttons.members.length, noteTypesFileList, noteTypesList));
		noteTypesList.cameraSpacing = 0; noteTypesList.dragCallback = (object:NoteTypeButton, oldIndex:Int, newIndex:Int) -> {object.IDText.text = '${newIndex}.';};
		for (i=>noteType in Charter.instance.noteTypes)
			noteTypesList.add(new NoteTypeButton(0, 0, noteType, i, noteTypesFileList, noteTypesList));
		add(noteTypesList);
		noteTypesList.frames = Paths.getFrames('editors/ui/inputbox');

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
			saveList();
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, "Close", function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
	}

	public function getNoteTypesList(?mods:Bool = false) {
		var list:Array<String> = [];
		for (path in Paths.getFolderContent(pathString, true, mods ? MODS : BOTH)) if(Path.extension(path) == "hx") {
				var file:String = Path.withoutDirectory(path);
				if (!list.contains(file)) list.push(file);
			}

		return list;
	}

	public function saveList() {
		var oldList:Array<String> = Charter.instance.noteTypes;
		var newList:Array<String> = [for (note in noteTypesList.buttons.members) note.textBox.label.text];

		Charter.instance.noteTypes = newList;
		Charter.instance.changeNoteType(null, false);

		Charter.undos.addToUndo(CEditNoteTypes(oldList, newList));
	}
}

class NoteTypeButton extends UIButton {
	public var IDText:UIText;
	public var noteSpr:FlxSprite;
	public var textBox:UIAutoCompleteTextBox;
	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public function new(x:Float, y:Float, name:String, noteID:Int, suggestList:Array<String>, parent:UIButtonList<NoteTypeButton>) {
		super(x, y, '', null, Std.int(parent.buttonSize.x), Std.int(parent.buttonSize.y));
		autoAlpha = false;

		members.push(IDText = new UIText(10, 10, 0, '${noteID}.'));

		updateNote(name);

		members.push(textBox = new UIAutoCompleteTextBox(IDText.x + 10, 10, name, 200-4));
		textBox.suggestItems = [for(script in (suggestList)) Path.withoutExtension(script)];
		textBox.onChange = function(noteType:String) {
			updateNote(noteType);
		};
		textBox.antialiasing = true;

		deleteButton = new UIButton(textBox.x + textBox.label.width + 10, textBox.y, "", function () {
			parent.remove(this);
		}, 32);
		deleteButton.color = 0xFFFF0000;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + (15/2), deleteButton.y + 8).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);
	}

	public function updateNote(notetype:String) {
		if (noteSpr == null) members.push(noteSpr = new FlxSprite());

		var path:String = 'game/notes/default';
		if (Assets.exists(Paths.image('game/notes/${notetype}')))
			path = 'game/notes/${notetype}';

		noteSpr.frames = Paths.getFrames(path);
		noteSpr.animation.addByPrefix('scroll', 'green0');
		noteSpr.animation.play("scroll");
		noteSpr.updateHitbox(); /*noteSpr.angle = 20;*/
		noteSpr.setGraphicSize(34, 34);
		noteSpr.updateHitbox(); noteSpr.antialiasing = true;
	}

	override function update(elapsed:Float) {
		IDText.x = x + 12; IDText.y = (y + bHeight/2) - (IDText.height/2);
		noteSpr.x = IDText.x + IDText.width + 2; noteSpr.y = (y + bHeight/2) - (noteSpr.height/2);
		textBox.x = noteSpr.x + noteSpr.width + 12; textBox.y = (y + bHeight/2) - (textBox.bHeight/2);
		deleteButton.x = textBox.x + textBox.bWidth + 14; deleteButton.y = textBox.y;
		deleteIcon.x = deleteButton.x + (15/2); deleteIcon.y = deleteButton.y + 8;

		deleteButton.selectable = selectable;
		deleteButton.shouldPress = shouldPress;

		super.update(elapsed);
	}
}