package funkin.editors.charter;

import flixel.math.FlxPoint;
import funkin.backend.chart.ChartData.ChartBookmark;

class CharterBookmarkList extends UISubstateWindow {
	public var bookmarkList:UIButtonList<BookmarkButton>;
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public override function create() {
		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();

		winTitle = TU.translate("charter.bookmarks.editBookmarkListTitle");
		winWidth = 380;
		winHeight = 390;

		super.create();

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, TU.translate("charter.bookmarks.editBookmarksTitle"), 28));

		bookmarkList = new UIButtonList<BookmarkButton>(20, title.y + title.height + 10, winWidth - 40, 342 - 85 - 16, null, FlxPoint.get(winWidth - 40, (342 - 85 - 16)/4), null, 0);
		bookmarkList.cameraSpacing = 0;
		
		for (b in Charter.instance.getBookmarkList())
			bookmarkList.add(new BookmarkButton(0, 0, b, bookmarkList));

		add(bookmarkList);
		bookmarkList.frames = Paths.getFrames('editors/ui/inputbox');

		bookmarkList.content.remove(bookmarkList.addButton); //i dont need it

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, TU.translate("editor.saveClose"), function() {
			saveList();
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, TU.translate("editor.close"), function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
	}

	public function saveList() {
		var oldList:Array<ChartBookmark> = Charter.instance.getBookmarkList();
		var newList:Array<ChartBookmark> = [for (btn in bookmarkList.buttons.members) {time: btn.bookmark.time, name: btn.textBox.label.text, color: btn.bookmark.color}];
		
		PlayState.SONG.bookmarks = newList;
		Charter.instance.updateBookmarks();	
		Charter.undos.addToUndo(CEditBookmarks(oldList, newList));
	}
}

class BookmarkButton extends UIButton {
	public var textBox:UITextBox;
	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;
	public var bookmark:ChartBookmark;

	public function new(x:Float, y:Float, bookmark:ChartBookmark, parent:UIButtonList<BookmarkButton>) {
		super(x, y, '', null, Std.int(parent.buttonSize.x), Std.int(parent.buttonSize.y));
		this.bookmark = bookmark;
		autoAlpha = false;

		members.push(textBox = new UITextBox(10, 10, bookmark.name, 276));
		textBox.antialiasing = true;

		deleteButton = new UIButton(textBox.x + textBox.label.width + 10, textBox.y, null, function () {
			parent.remove(this);
		}, 32);
		deleteButton.color = 0xFFFF0000;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + (15/2), deleteButton.y + 8).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);
	}

	override function update(elapsed:Float) {
		textBox.y = (y + bHeight/2) - (textBox.bHeight/2);
		deleteButton.x = textBox.x + textBox.bWidth + 14; deleteButton.y = textBox.y;
		deleteIcon.x = deleteButton.x + (15/2); deleteIcon.y = deleteButton.y + 8;

		deleteButton.selectable = selectable;
		deleteButton.shouldPress = shouldPress;

		super.update(elapsed);
	}
}