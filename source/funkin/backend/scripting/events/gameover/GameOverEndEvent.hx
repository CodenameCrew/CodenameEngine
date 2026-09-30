package funkin.backend.scripting.events.gameover;

class GameOverEndEvent extends CancellableEvent {
  // TODO: Add documentation for every variable.
  
  public var sndLength:Null<Float>; // There is little reason for you to change this.
  
  public var delayTime:Float = 0.7;
  public var timeCap:Float = 0.5;

  public var fadeColor:FlxColor = 0xFF000000;

  public var onTimerEnd:Void -> Void;
  public var onFadeEnd:Void -> Void;
  
  public var state:FlxState = new PlayState();
}
