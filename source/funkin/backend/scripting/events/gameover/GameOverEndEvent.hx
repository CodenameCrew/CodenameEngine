package funkin.backend.scripting.events.gameover;

class GameOverEndEvent extends CancellableEvent {
  public var secLength:Float;
  public var waitTime:Float;
  public var fadeTime:Float;
  public var fadeCap:Float;
  public var state:FlxState;
} 
