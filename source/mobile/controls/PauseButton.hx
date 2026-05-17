package mobile.controls;

class Pause extends FlxGroup
{
    public var pauseButton:FlxSprite;
    public var pauseCircle:FlxSprite;
    public var isButtonActive:Bool = false;
    public var PauseCam:FlxCamera;

    public function new()
    {
        super();

        PauseCam = new FlxCamera();
        PauseCam.bgColor = 0x00000000;
        FlxG.cameras.add(PauseCam, false);

        pauseButton = new FlxSprite(0, 0);
        pauseButton.frames = Paths.getSparrowAtlas('game/pauseButton');
        pauseButton.animation.addByIndices('idle', 'pause', [0], "", 24, false);
        pauseButton.animation.addByIndices('hold', 'pause', [5], "", 24, false);
        
        var confirmIndices:Array<Int> = [];
        for (i in 6...33) confirmIndices.push(i);
        pauseButton.animation.addByIndices('confirm', 'pause', confirmIndices, "", 24, false);
        
        pauseButton.scale.set(0.8, 0.8);
        pauseButton.updateHitbox();
        pauseButton.animation.play('idle');
        pauseButton.setPosition((FlxG.width - pauseButton.width) - 35, 35);
        
        pauseButton.antialiasing = Options.antialiasing; 
        
        pauseButton.scrollFactor.set();
        pauseButton.cameras = [PauseCam];

        pauseCircle = new FlxSprite(0, 0).loadGraphic(Paths.image('game/pauseCircle'));
        pauseCircle.scale.set(0.84, 0.8);
        pauseCircle.updateHitbox();
        pauseCircle.x = ((pauseButton.x + (pauseButton.width / 2)) - (pauseCircle.width / 2));
        pauseCircle.y = ((pauseButton.y + (pauseButton.height / 2)) - (pauseCircle.height / 2));
        pauseCircle.alpha = 0.2;
        pauseCircle.scrollFactor.set();
        pauseCircle.cameras = [PauseCam];

        add(pauseCircle);
        add(pauseButton);

        pauseButton.visible = false;
        pauseCircle.visible = false;
    }

    public function setPauseButton(state:String)
{
    isButtonActive = (state == 'true');

    pauseButton.visible = isButtonActive;
    pauseCircle.visible = isButtonActive;

    if (Options.pauseButton == false) {
        pauseButton.alpha = 0;
        pauseCircle.alpha = 0;
    } else {
        pauseButton.alpha = 1;
        pauseCircle.alpha = 0.2;
    }
}
    
    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (!isButtonActive) return;

        var touchedPause:Bool = false;

        for (touch in FlxG.touches.list)
        {
            if (touch.justPressed)
            {
                if (pauseButton.overlapsPoint(touch.getScreenPosition(PauseCam), true, PauseCam))
                {
                    touchedPause = true;
                    break;
                }
            }
        }

        var game = PlayState.instance;

        if (touchedPause && !game.paused && game.health > 0)
        {
            pauseButton.animation.play('confirm');
            
            game.pauseGame();
        }
    }
}
