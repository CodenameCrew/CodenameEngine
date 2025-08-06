#if !macro
import funkin.backend.system.Main;
import funkin.backend.assets.Paths;
import funkin.backend.MusicBeatState;
import funkin.backend.MusicBeatSubstate;
import funkin.backend.MusicBeatGroup;
import funkin.backend.FunkinSprite;
import funkin.backend.utils.*;
import funkin.backend.utils.TranslationUtil as TU;
import funkin.backend.system.Logs;
import funkin.options.Options;
import funkin.game.PlayState;
import funkin.backend.scripting.EventManager;

import openfl.utils.Assets;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxDestroyUtil;

import funkin.backend.system.Flags;
import funkin.Types;

import funkin.menus.ui.Alphabet;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

using StringTools;
using funkin.backend.utils.CoolUtil;
#end