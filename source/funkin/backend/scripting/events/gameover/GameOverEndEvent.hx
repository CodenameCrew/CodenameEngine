package funkin.backend.scripting.events.gameover;

import flixel.FlxState;
import flixel.util.FlxColor;

/**
  * A helper event used to configure the logic after the player retries after dying.
  */
class GameOverEndEvent extends CancellableEvent {
  /**
    * A helper variable that gets the retry sound's length in seconds.
    * May be used for the timeCap to cancel the delay.
    * This is calculated, so there is little reason for you to change this.
    */
  public var sndLength:Null<Float>;

  /**
    * The delay time before the final camera fade.
    * This is used for the timer.
    */
  public var delayTime:Float;

  /**
    * The total time it takes for the camera to fade.
    * (This is handled automatically).
    */
  public var fadeTime:Null<Float>;

  /**
    * The minimum limit the sound's length can be before skipping the delay.
    */
  public var timeCap:Float;

  /**
    * The color of the camera fade.
    */
  public var fadeColor:FlxColor;

  /**
    * Called when the timer has ended.
    * This will override the camera fade.
    */
  public var onTimerEnd:Void -> Void;

  /**
    * Called when the camera fade has ended.
    * This will override the state change.
    */
  public var onFadeEnd:Void -> Void;

  /**
    * Whether or not the next MusicBeatTransition should be skipped.
    */
  public var skipTrans:Bool;
 
  /**
    * The delay timer.
    * Warning, this is null by default before onPostEnd.
    */
  public var timer:FlxTimer;

  /**
    * The redirect state after the camera fade is complete
    */
  public var state:FlxState;
}
