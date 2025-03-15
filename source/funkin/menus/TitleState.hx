package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxState;

class RYTPTitleState extends FlxState {
    var bg:FlxSprite;
    var titleText:FlxText;

    override public function create():Void {
        super.create();

        // Фон (замени путь на свой файл)
        bg = new FlxSprite().loadGraphic(Paths.image("rytptitlebg"));
        bg.screenCenter();
        add(bg);

        // Текст заголовка
        titleText = new FlxText(0, 0, 0, "RYTP MOD", 32);
        titleText.setFormat(null, 32, FlxColor.WHITE, CENTER);
        titleText.screenCenter(X);
        titleText.y = FlxG.height * 0.7;
        add(titleText);

        // Музыка титульного экрана
        FlxG.sound.playMusic(Paths.music("rytptitlemusic"), 1, true);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Если нажата любая клавиша или клик - переходим в главное меню
        if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed) {
            FlxG.switchState(new MainMenuState());
        }
    }
}
