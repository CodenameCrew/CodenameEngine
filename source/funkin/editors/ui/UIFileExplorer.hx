package funkin.editors.ui;

import haxe.io.Bytes;
import lime.ui.FileDialog;

class UIFileExplorer extends UISliceSprite {
	public var uploadButton:UIButton;
	public var uploadIcon:FlxSprite;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public var file:Bytes = null;
	public var filePath:String = null;
	public var onFile:(String, Bytes)->Void;

	public var uiElement:FlxSprite;
	
	public var fileType:String = "txt";

	public function new(x:Float, y:Float, ?w:Int, ?h:Int, fileType:String = "txt", ?onFile:(String, Bytes)->Void) {
		super(x, y, (w != null ? w : 320), (h != null ? h : 58), 'editors/ui/inputbox');
		this.fileType = fileType;

		if (onFile != null) this.onFile = onFile;

		uploadButton = new UIButton(x + 8, y+ 8, null, function () {
			var fileDialog = new FileDialog();
			fileDialog.onSelect.add(loadFile);
			fileDialog.browse(OPEN, this.fileType);
		}, bWidth - 16, bHeight - 16);
		members.push(uploadButton);

		uploadIcon = new FlxSprite(uploadButton.x + (uploadButton.bWidth / 2) - 8, uploadButton.y + ((bHeight-16)/2) - 8).loadGraphic(Paths.image('editors/ui/upload-button'));
		uploadIcon.antialiasing = false;
		uploadButton.members.push(uploadIcon);

		deleteButton = new UIButton(x + bWidth - (bHeight - 16) - 8, y + 8, null, removeFile, bHeight - 16, bHeight - 16);
		deleteButton.color = 0xFFFF0000;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + ((bHeight - 16)/2) - 8, deleteButton.y + ((bHeight - 16)/2) - 8).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		deleteButton.members.push(deleteIcon);

		deleteButton.visible = deleteButton.selectable = deleteIcon.visible = false;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		alpha = selectable ? 1 : 0.4;
		uploadButton.alpha = deleteButton.alpha = deleteIcon.alpha = uploadIcon.alpha = alpha;

		if (uiElement != null) {
			uiElement.alpha = alpha;
			if (uiElement is UIButton) {
				var uiElement:UIButton = cast uiElement;
				uiElement.selectable = selectable;
			}
		}
	}

	public function loadFile(path:String) {
		file = cast sys.io.File.getBytes(filePath = path);
		deleteButton.visible = deleteButton.selectable = deleteIcon.visible = !(uploadButton.visible = uploadButton.selectable = false);

		if (this.onFile != null) this.onFile(filePath, file);
	}

	public function removeFile() {
		if (!selectable) return;
		if (uiElement != null) {
			members.remove(uiElement);
			uiElement.destroy();
		}

		file = null; onFile(null, null);
		MemoryUtil.clearMajor();

		deleteButton.visible = deleteButton.selectable = deleteIcon.visible = !(uploadButton.visible = uploadButton.selectable = true);
	}
}