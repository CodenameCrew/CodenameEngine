package funkin.backend.scripting.events.dialogue;

import flixel.sound.FlxSound;
import funkin.backend.utils.XMLUtil.TextFormat;

final class DialogueBoxPlayBubbleEvent extends CancellableEvent
{
	public var bubble:String;

	public var suffix:String;

	public var text:String;

	public var format:Array<TextFormat>;

	public var speed:Float;

	public var customSFX:FlxSound;

	public var customTypeSFX:Array<FlxSound>;

	public var setTextAfter:Bool;

	public var allowDefault:Bool;
}