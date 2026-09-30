package funkin.backend.scripting.events.gameover;

class GameOverEndEvent extends CancellableEvent {
  // TODO: Add documentation for every variable.
  
  public var sndLength:Null<Float>; // There is little reason for you to change this.
  
  public var delayTime:Null<Float>;
  public var timeCap:Null<Float>;

  public var fadeColor:Null<FlxColor>;

  public var onTimerEnd:Void -> Void;
  public var onFadeEnd:Void -> Void;
  
  public var state:FlxState;
}
