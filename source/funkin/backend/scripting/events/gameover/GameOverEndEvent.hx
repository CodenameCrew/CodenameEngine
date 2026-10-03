package funkin.backend.scripting.events.gameover;

import flixel.FlxState;
import flixel.util.FlxColor;

/**
  * A helper event used to configure the logic after the player retries after dying.
  */
class GameOverEndEvent extends CancellableEvent {
  /**
    * This is a helper variable that will calculate the fade time.
    * It may be used for the timeCap to cancel the delay.
    * (This is calculated; there is little reason for you to change this).
    */
  public var sndLength:Null<Float>;

  /**
    * The delay time before the final camera fade.
    * This is used for the timer.
    */
  public var delayTime:Float = 0.7;

  /**
    * The total time it takes for the camera to fade.
    * (This is handled automatically).
    */
  public var fadeTime:Null<Float>;

  /**
    * The time cap before the delay before the fade is reverted.
    */
  public var timeCap:Float = 0.5;

  /**
    * The color of the camera fade.
    */
  public var fadeColor:FlxColor = FlxColor.BLACK;

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
  public var skipTrans:Bool = true;

  /**
    * The redirect state after the camera fade is complete
    */
  public var state:FlxState = new PlayState();
}
