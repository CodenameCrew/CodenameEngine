package funkin.backend.scripting.events;



final class StartIntroEvent extends CancellableEvent {
  /**
   * Whether StoryMenuState should play the menu song
   */
  public var playMenuSong:Bool;

  /**
   * Whether StoryMenuState should use the title screen's XML file
   */
  public var titleScreenXML:Bool;

  /**
   * The path for the title sprite (PRESS ENTER TO PLAY)
   */
  public var titleSprite:String;

  /**
   * The path for the Newgrounds sprite
   */
  public var ngSprite:String;

  /**
   * Whether the mouse should be visible
   */
  public var showMouse:Bool;
}
