package funkin.backend.system.framerate;

import funkin.backend.system.macros.GitCommitMacro;
import openfl.text.TextField;

class CodenameBuildField extends TextField {
	public function new() {
		super();
		autoSize = LEFT;
		multiline = wordWrap = false;
		reload();
	}

	public function reload() {
		defaultTextFormat = Framerate.textFormat;

		#if TEST_BUILD
		text = '${Flags.VERSION_MESSAGE} (Test Build)';
		#elseif COMPILE_EXPERIMENTAL
		text = '${Flags.VERSION_MESSAGE} (Experimental Build)';
		#else
		text = '${Flags.VERSION_MESSAGE}';
		#end

		#if (debug || COMPILE_EXPERIMENTAL)
		text += '\n${Flags.COMMIT_MESSAGE}';
		#end
	}
}
