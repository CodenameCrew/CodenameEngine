package funkin.backend.utils;

import flixel.text.FlxText;
import flixel.util.FlxColor;

final class MarkdownUtil {
	public static function applyMarkdownText(text:FlxText, str:String) {
		text.textField.htmlText = Markdown.markdownToHtml(prepareMarkdown(str));
		var changes:Array<FlxTextFormatMarkerPair> = [
			createAdvancedMarkerPair("{title}", 0xFFFFFFFF, text.size * 2, false, true, true),
			createAdvancedMarkerPair("{subtitle}", 0xFFFFFFFF, text.size * 1.5, false, true, true),
			createAdvancedMarkerPair("{subsubtitle}", 0xFFFFFFFF, text.size * 1.25, false, true, true),
			createAdvancedMarkerPair("{ident1}", 0xFFFFFFFF, null, false, false, false, text.size * 2, true),
			createAdvancedMarkerPair("{ident2}", 0xFFFFFFFF, null, false, false, false, text.size * 4, true),
			createAdvancedMarkerPair("{ident3}", 0xFFFFFFFF, null, false, false, false, text.size * 6, true),
			createAdvancedMarkerPair("{ident4}", 0xFFFFFFFF, null, false, false, false, text.size * 8, true),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF00, false, true), "{o}"),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF0000, false, true), "{r}"),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF00FF08, false, true), "{g}"),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF7D7D7D, false, true), "{gray}"),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFFFF, false, true, 0xFF222222), "{italic}"),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFFFF, false, true, 0xFF666666), "{bold}"),
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFFFF, false, true, 0xFF888888), "{bold-italic}"),
		];

		text.applyMarkup(
			parseWarnings(text.textField.text),
			changes
		);
		@:privateAccess {
			// hacky fix for the text cutting when bigger text formats are used
			text._regen = true;
			text.regenGraphic();
			text._regen = true;
			text.regenGraphic();
		}
	}

	public static function createAdvancedMarkerPair(marker:String, color:FlxColor, size:Null<Float>, bold:Bool = false, italic:Bool = false, ?underline:Bool = false, ?blockIndent:Int, ?bullet:Bool) {
		@:privateAccess {
			var format = new FlxTextFormat(color, bold, italic);
			format.format.size = size == null ? null : Std.int(size);
			format.format.underline = underline;
			format.format.blockIndent = blockIndent;
			format.format.bullet = bullet;
			return new FlxTextFormatMarkerPair(format, marker);
		}
	}

	public static function parseWarnings(text:String) {
		text = text.replace("&nbsp;", " ");
		text = parseEmote(text, "⚠", "{o}(!)", "{o}");
		text = parseEmote(text, "❌", "{r}(X)", "{r}");
		text = parseEmote(text, "✔", "{g}(+)", "{g}");
		return text;
	}

	public static function prepareMarkdown(text:String) {
		text = "\n" + text;
		text = parseEmote(text, "\n- ",             "\n{ident1}&nbsp;&nbsp;• ",             "{ident1}");
		text = parseEmote(text, "\n    - ",         "\n{ident2}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• ",         "{ident2}");
		text = parseEmote(text, "\n        - ",     "\n{ident3}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• ",     "{ident3}");
		text = parseEmote(text, "\n            - ", "\n{ident4}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• ", "{ident4}");
		text = parseEmote(text, "\n> ",             "\n{gray}",                 "{gray}");
		text = parseEmote(text, "\n### ",           "\n{subsubtitle}",          "{subsubtitle}");
		text = parseEmote(text, "\n## ",            "\n{subtitle}",             "{subtitle}");
		text = parseEmote(text, "\n# ",             "\n{title}",                "{title}");
		text = parseEmote(text, "***",              "{bold-italic}",            "{bold-italic}",    "***");
		text = parseEmote(text, "**",               "{bold}",                   "{bold}",           "**");
		text = parseEmote(text, "*",                "{italic}",                 "{italic}",         "*");
		text = parseEmote(text, "_",                "{italic}",                 "{italic}",         "*");
		text = parseEmote(text, "__",               "{bold}",                   "{bold}",           "*");
		text.substr("\n".length);
		return text;
	}

	public static function parseEmote(text:String, emote:String, beginning:String, end:String, emoteEnd:String = "\n") {
		var index:Int;
		while((index = text.indexOf(emote)) >= 0) {
			var nextIndex = text.indexOf(emoteEnd, index + emote.length);
			if (nextIndex < 0)
				nextIndex = text.length;
			text = text.substr(0, index) + beginning + text.substring(index + emote.length, nextIndex) + end + (emote == emoteEnd ? "" : emoteEnd) + text.substring(nextIndex + emoteEnd.length);
		}
		return text;
	}
}