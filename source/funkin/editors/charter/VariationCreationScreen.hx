package funkin.editors.charter;

import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import funkin.backend.chart.ChartData;
import funkin.editors.charter.SongCreationScreen;

class VariationCreationScreen extends SongCreationScreen {
	public var parentMeta:ChartMetaData;

	public function new(parent:ChartMetaData, ?onSave:SongCreationData -> Null<String -> Void> -> Void) {
		super(onSave);
		this.parentMeta = parent;
	}

	override function create() {
		super.create();

		songNameTextBox.label.text = translateMeta("variation");
		cast(songNameTextBox.members[songNameTextBox.members.length - 1], UIText).text = translateMeta("variation");

		cast(importIdTextBox.members[importIdTextBox.members.length - 1], UIText).applyMarkup(
			translateMeta("variation"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]
		);

		bpmStepper.value = parentMeta.bpm;
		beatsPerMeasureStepper.value = parentMeta.beatsPerMeasure;
		denominatorStepper.value = Std.int(16 / parentMeta.stepsPerBeat);
		displayNameTextBox.label.text = parentMeta.displayName;
		iconTextBox.label.text = parentMeta.icon;
		opponentModeCheckbox.checked = parentMeta.opponentModeAllowed;
		coopAllowedCheckbox.checked = parentMeta.coopAllowed;
		colorWheel.setColor(parentMeta.color);
		difficultiesTextBox.label.text = parentMeta.difficulties.join(', ');
	}

	override function formatMeta(meta:ChartMetaData):ChartMetaData {
		meta.variant = meta.name;
		meta.vocalsSuffix = meta.instSuffix = '-${meta.variant}';
		meta.name = parentMeta.name;
		meta.icon = parentMeta.icon;
		meta.color = parentMeta.color;
		return super.formatMeta(meta);
	}
}