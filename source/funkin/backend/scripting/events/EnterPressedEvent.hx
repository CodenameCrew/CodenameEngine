package funkin.backend.scripting.events;

import funkin.backend.utils.CoolUtil.CoolSfx;
import flixel.util.FlxColor;

final class EnterPressedEvent extends CancellableEvent {
  /**
   * Whether the screen should flash on PRESS ENTER TO START
   */
  public var flash:Bool;

    /**
   * The color that the screen flashes
   */
  public var flashColor:FlxColor;

    /**
   * Whether PRESS ENTER TO START should play a menu sfx
   */
  public var playSfx:Bool;

    /**
   * The menu sound to play
   */
  public var menuSound:CoolSfx;

    /**
   * The time between enter being pressed and the transition into MainMenuState
   */
  public var timerLength:Float;
}
