package funkin.backend.system;

import flixel.FlxState;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.backend.chart.ChartData;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.system.interfaces.IBeatCancellableReceiver;
import funkin.editors.charter.Charter;

enum BeatType {
	BEAT;
	MEASURE;
	STEP;
}

@:structInit
class BPMChangeEvent
{
	public var songTime:Float;
	public var bpm:Float;
	public var beatsPerMeasure:Float = 4;
	public var stepsPerBeat:Int = 4;

	public var endSongTime:Float = 0;
	public var endStepTime:Float = 0;
	public var continuous:Bool = false;

	public var stepTime:Float;
	public var beatTime:Float;
	public var measureTime:Float;
}

final class Conductor
{
	public static function getBeats(?every:BeatType, interval:Float, offset:Float = 0):Float {
		final beat = switch(every) {
			case MEASURE: curMeasureFloat;
			case STEP: curStepFloat;
			default: curBeatFloat;
		}
		if (interval <= 0) return beat - offset;
		else return Math.floor((beat - offset) / interval) * interval;
	}

	/**
	 * FlxSignals
	 */
	public static var onMeasureHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var onBeatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var onStepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
	public static var onBPMChange:FlxTypedSignal<(Float,Float)->Void> = new FlxTypedSignal();
	public static var onTimeSignatureChange:FlxTypedSignal<(Float,Float)->Void> = new FlxTypedSignal();

	/**
	 * Current position of the song, in milliseconds.
	 */
	public static var songPosition(get, default):Float;
	private static function get_songPosition() {
		if (!Options.songOffsetAffectEditors && Charter.instance != null) {
			songOffset = 0;
			return songPosition;
		}
		else
			return songPosition - (songOffset = Options.songOffset);
	}

	/**
	 * Offset of the song
	 */
	public static var songOffset:Float = 0;

	/**
	 * Current bpmChangeMap index
	 */
	public static var curChangeIndex:Int = 0;

	/**
	 * Current bpmChangeMap
	 */
	public static var curChange(get, never):BPMChangeEvent;
	private static var dummyChange:BPMChangeEvent = {bpm: 100, beatsPerMeasure: 4, stepsPerBeat: 4, songTime: 0, stepTime: 0, beatTime: 0, measureTime: 0};
	private static function get_curChange()
		return bpmChangeMap.length == 0 ? dummyChange : bpmChangeMap[curChangeIndex];

	/**
	 * Current BPM
	 */
	public static var bpm(get, never):Float;
	private static function get_bpm()
		return (curChangeIndex == 0 || bpmChangeMap.length == 0) ? startingBPM : getTimeWithIndexInBPM(songPosition, curChangeIndex);

	/**
	 * Starting BPM
	 */
	public static var startingBPM(get, never):Float;
	private static function get_startingBPM()
		return (bpmChangeMap.length == 0 ? dummyChange : bpmChangeMap[0]).bpm;

	/**
	 * Current Crochet (time per beat), in milliseconds.
	 * It should be crotchet but ehhh, now it's there for backward compatibility.
	 */
	public static var crochet(get, never):Float;
	private static function get_crochet() return 15000 * stepsPerBeat / bpm;

	/**
	 * Current StepCrochet (time per step), in milliseconds.
	 */
	public static var stepCrochet(get, never):Float;
	private static function get_stepCrochet() return 15000 / bpm;

	/**
	 * Number of beats per mesure (top number in time signature). Defaults to 4.
	 */
	public static var beatsPerMeasure(get, never):Float;
	private static function get_beatsPerMeasure()
		return (bpmChangeMap.length == 0 ? dummyChange : bpmChangeMap[curChangeIndex]).beatsPerMeasure;

	/**
	 * Number of steps per beat. Defaults to 4.
	 * Not a divisor number for time signature, it does the complete opposite.
	 * It's because CNE Conductor is based in sixteenth note instead of beat.
	 */
	public static var stepsPerBeat(get, never):Int;
	private static function get_stepsPerBeat()
		return (bpmChangeMap.length == 0 ? dummyChange : bpmChangeMap[curChangeIndex]).stepsPerBeat;

	/**
	 * How much value notes to divide for beat (bottom or divisor number in time signature).
	 * Only for a convinient way to access divisor instead of multiply by steps per beat.
	 */
	public static var denominator(get, never):Float;
	private static function get_denominator() return FlxMath.roundDecimal(16 / stepsPerBeat, 2);

	/**
	 * Last step from BPM Change
	 */
	public static var lastStepChange(get, never):Float;
	private static function get_lastStepChange() return curChange.stepTime;

	/**
	 * Last beat from BPM Change
	 */
	public static var lastBeatChange(get, never):Float;
	private static function get_lastBeatChange() return curChange.beatTime;

	/**
	 * Last measure from BPM Change
	 */
	public static var lastMeasureChange(get, never):Float;
	private static function get_lastMeasureChange() return curChange.measureTime;

	/**
	 * Current step
	 */
	public static var curStep:Int = 0;

	/**
	 * Current beat
	 */
	public static var curBeat:Int = 0;

	/**
	 * Current measure
	 */
	public static var curMeasure:Int = 0;

	/**
	 * Current step, as a `Float` (ex: 4.94, instead of 4)
	 */
	public static var curStepFloat:Float = 0;

	/**
	 * Current beat, as a `Float` (ex: 1.24, instead of 1)
	 */
	public static var curBeatFloat:Float = 0;

	/**
	 * Current measure, as a `Float` (ex: 1.24, instead of 1)
	 */
	public static var curMeasureFloat:Float = 0;


	@:dox(hide) public static var lastSongPos:Float = 0;
	@:dox(hide) public static var offset:Float = 0;

	/**
	 * Array of all BPM changes that have been mapped.
	 */
	public static var bpmChangeMap:Array<BPMChangeEvent>;

	/**
	 * Array of all events that have been rejected by the Conductor.
	 */
	public static var invalidEvents:Array<ChartEvent> = [];

	private static var validEventNames:Array<String> = ["BPM Change", "Time Signature Change", "Continuous BPM Change"];

	@:dox(hide) public function new() {}

	public static function reset() {
		songPosition = lastSongPos = curBeatFloat = curStepFloat = curBeat = curStep = 0;
		curChangeIndex = 0;
		changeBPM();
	}

	public static function changeBPM(bpm:Float = 100, beatsPerMeasure:Float = 4, stepsPerBeat:Int = 4)
		bpmChangeMap = [{bpm: bpm, beatsPerMeasure: beatsPerMeasure, stepsPerBeat: stepsPerBeat, songTime: 0, stepTime: 0, beatTime: 0, measureTime: 0}];

	public static function setupSong(SONG:ChartData) {
		reset();
		mapBPMChanges(SONG);
	}

	private static function mapBPMChange(curChange:BPMChangeEvent, time:Float, bpm:Float):BPMChangeEvent {
		var beatTime:Float, measureTime:Float, stepTime:Float;
		stepTime = (curChange.continuous ? curChange.endStepTime : curChange.stepTime) + (time - (curChange.continuous ? curChange.endSongTime : curChange.songTime)) / (15000 / curChange.bpm);

		beatTime = curChange.beatTime + (stepTime - curChange.stepTime) / curChange.stepsPerBeat;
		measureTime = curChange.measureTime + (beatTime - curChange.beatTime) / curChange.beatsPerMeasure;

		bpmChangeMap.push(curChange = {
			songTime: time,
			stepTime: stepTime,
			beatTime: beatTime,
			measureTime: measureTime,
			bpm: bpm,
			beatsPerMeasure: curChange.beatsPerMeasure,
			stepsPerBeat: curChange.stepsPerBeat
		});
		return curChange;
	}

	/**
	 * Maps BPM changes from a song.
	 * @param song Song to map BPM changes from.
	 */
	public static function mapBPMChanges(song:ChartData) {
		var curChange:BPMChangeEvent = {
			songTime: 0,
			stepTime: 0,
			beatTime: 0,
			measureTime: 0,
			bpm: song.meta.bpm,
			beatsPerMeasure: song.meta.beatsPerMeasure.getDefault(4),
			stepsPerBeat: CoolUtil.floorInt(song.meta.stepsPerBeat.getDefault(4))
		};
		curChangeIndex = 0;
		bpmChangeMap = [curChange];
		invalidEvents = [];
		if (song.events == null) return;

		// fix the sort first...
		var events:Array<ChartEvent> = [for (e in song.events) if (e.params != null && validEventNames.contains(e.name)) e];
		events.sort((a, b) -> MathUtil.equal(a.time, b.time) ? (a.name == "Time Signature Change" ? -1 : 1) : Std.int(a.time - b.time));

		for (e in events) curChange = mapEvent(e, curChange);
	}

	private static function mapEvent(e:ChartEvent, curChange:BPMChangeEvent) {
		var name = e.name, params = e.params, time = e.time;
		if (curChange.continuous && MathUtil.lessThan(time, curChange.endSongTime)) { //ensure that you cannot place any conductor events during a continuous change
			invalidEvents.push(e);
			Logs.trace('Invalid Conductor event "${e.name}" at ${e.time} (Intersecting continuous change!)', WARNING);
			return curChange;
		}

		if (name == "BPM Change" && params[0] is Float && curChange.bpm != params[0])
			curChange = mapBPMChange(curChange, time, params[0]);
		else if (name == "Time Signature Change") {
			//if (beatsPerMeasure == curChange.beatsPerMeasure && stepsPerBeat == curChange.stepsPerBeat) continue;
			/* TODO: make so time sigs doesnt stop the bpm change if its in the duration of bpm change */

			if (curChange.songTime != time) curChange = mapBPMChange(curChange, time, curChange.bpm);
			curChange.beatsPerMeasure = params[0];

			if (params[2]) curChange.stepsPerBeat = params[1];
			else curChange.stepsPerBeat = Math.floor(16 / params[1]); // convert from denominator to stepsPerBeat

			curChange.stepTime = CoolUtil.floorInt(curChange.stepTime + .99998);
			curChange.beatTime = CoolUtil.floorInt(curChange.beatTime + .99998);
			curChange.measureTime = CoolUtil.floorInt(curChange.measureTime + .99998);
		}
		else if (name == "Continuous BPM Change") {
			var prevBPM = curChange.bpm;
			if (curChange.bpm == params[0]) {
				invalidEvents.push(e);
				return curChange; //DO NOT!!!!
			}

			curChange = mapBPMChange(curChange, time, params[0]);
			curChange.endSongTime = time + (params[1]) / (curChange.bpm - prevBPM) * Math.log(curChange.bpm / prevBPM) * 15000;
			curChange.endStepTime = curChange.stepTime + params[1];
			curChange.continuous = true;
		}
		return curChange;
	}

	public static function mapCharterBPMChanges(song:ChartData) {
		var curChange:BPMChangeEvent = {
			songTime: 0,
			stepTime: 0,
			beatTime: 0,
			measureTime: 0,
			bpm: song.meta.bpm,
			beatsPerMeasure: song.meta.beatsPerMeasure.getDefault(4),
			stepsPerBeat: CoolUtil.floorInt(song.meta.stepsPerBeat.getDefault(4))
		};
		bpmChangeMap = [curChange];
		invalidEvents = [];

		var grpEvents = Charter.instance.leftEventsGroup.members.concat(Charter.instance.rightEventsGroup.members);
		var n = grpEvents.length;

		if (n != 0) {
			grpEvents.sort((a, b) -> a.step < b.step ? -1 : 1);
			curChangeIndex = 0;

			var i = 0, i2 = 0, j = 0, x = 0, events = [], ce, e;
			while (i < n) {
				x += (ce = grpEvents[i]).events.length;
				if (++i < n && grpEvents[i].step == ce.step) continue;

				var eventTime = Conductor.getStepsInTime(ce.step, curChangeIndex);
				if (Math.isNaN(eventTime)) eventTime = 0;

				events.resize(x);
				while (i2 < i) {
					x = 0;
					ce = grpEvents[i2++];
					while (x < ce.events.length) if (validEventNames.contains((e = ce.events[x++]).name)) {
						events[j++] = e;
						if (eventTime != 0) e.time = eventTime;
					}
				}
				events.resize(x = j);
				events.sort((a, b) -> MathUtil.equal(a.time, b.time) ? (a.name == "Time Signature Change" ? -1 : 1) : 0);

				j = 0;
				while (j < x) curChange = mapEvent(events[j++], curChange);
				curChangeIndex = bpmChangeMap.length - 1;

				x = j = 0;
			}
		}

		curChangeIndex = 0;
	}

	private static var elapsed:Float;

	public static function init() {
		FlxG.signals.preUpdate.add(update);
		FlxG.signals.preStateCreate.add(onStateSwitch);
		reset();
	}

	private static function __updateSongPos(elapsed:Float) {
		if (FlxG.sound.music != null) { // CNE FlxSound is Interpolated.
			lastSongPos = FlxG.sound.music.time - songOffset;
			if (FlxG.sound.music.playing) songPosition = FlxG.sound.music.time;
		}
	}

	private static function onStateSwitch(newState:FlxState) {
		if (FlxG.sound.music == null)
			reset();
	}
	private static var __lastChange:BPMChangeEvent;
	private static var __updateStep:Bool;
	private static var __updateBeat:Bool;
	private static var __updateMeasure:Bool;

	private static function update() {
		if (FlxG.state == null) return;
		else {
			var state = FlxG.state;
			while (state != null) {
				if (state is IBeatCancellableReceiver && cast(FlxG.state, IBeatCancellableReceiver).cancelConductorUpdate) return;
				state = state.subState;
			}
		}
		__updateSongPos(FlxG.elapsed);

		var oldStep = curStep, oldBeat = curBeat, oldMeasure = curMeasure, oldChangeIndex = curChangeIndex;

		if ((curChangeIndex = getTimeInChangeIndex(songPosition, curChangeIndex)) > 0) {
			var change = curChange;
			curStepFloat = getTimeWithBPMInSteps(songPosition, curChangeIndex, getTimeWithIndexInBPM(songPosition, curChangeIndex));
			curBeatFloat = change.beatTime + (curStepFloat - change.stepTime) / change.stepsPerBeat;
			curMeasureFloat = change.measureTime + (curBeatFloat - change.beatTime) / change.beatsPerMeasure;
		}
		else
			curMeasureFloat = (curBeatFloat = (curStepFloat = songPosition / stepCrochet) / stepsPerBeat) / beatsPerMeasure;

		if (curChangeIndex != oldChangeIndex) {
			var prev = bpmChangeMap[oldChangeIndex];
			if (prev != null) {
				if (beatsPerMeasure != prev.beatsPerMeasure || stepsPerBeat != prev.stepsPerBeat)
					onTimeSignatureChange.dispatch(beatsPerMeasure, stepsPerBeat);

				if (curChange.bpm != prev.bpm) onBPMChange.dispatch(curChange.bpm, curChange.endSongTime);
			}
			else {
				onTimeSignatureChange.dispatch(beatsPerMeasure, stepsPerBeat);
				onBPMChange.dispatch(curChange.bpm, curChange.endSongTime);
			}
		}

		if (__updateStep = (curStep != (curStep = CoolUtil.floorInt(curStepFloat)))) {
			if (curStep > oldStep) for (i in oldStep...curStep) onStepHit.dispatch(i + 1);
			else onStepHit.dispatch(curStep);
		}

		if (__updateBeat = (curBeat != (curBeat = CoolUtil.floorInt(curBeatFloat)))) {
			if (curBeat > oldBeat) for (i in oldBeat...curBeat) onBeatHit.dispatch(i + 1);
			else onBeatHit.dispatch(curBeat);
		}

		if (__updateMeasure = (curMeasure != (curMeasure = CoolUtil.floorInt(curMeasureFloat)))) {
			if (curMeasure > oldMeasure) for (i in oldMeasure...curMeasure) onMeasureHit.dispatch(i + 1);
			else onMeasureHit.dispatch(curMeasure);
		}

		if (__updateStep || __updateBeat || __updateMeasure) {
			var state = FlxG.state;
			while (state != null) {
				if (state is IBeatReceiver && (state.subState == null || state.persistentUpdate)) {
					var st = cast(state, IBeatReceiver);

					if (__updateStep) {
						if (curStep > oldStep) for (i in oldStep...curStep) st.stepHit(i + 1);
						else st.stepHit(curStep);
					}

					if (__updateBeat) {
						if (curBeat > oldBeat) for (i in oldBeat...curBeat) st.beatHit(i + 1);
						else st.beatHit(curBeat);
					}

					if (__updateMeasure) {
						if (curMeasure > oldMeasure) for (i in oldMeasure...curMeasure) st.measureHit(i + 1);
						else st.measureHit(curMeasure);
					}
				}
				state = state.subState;
			}
		}
	}

	public static function getTimeInChangeIndex(time:Float, index:Int = 0):Int {
		if (bpmChangeMap.length < 2) return bpmChangeMap.length - 1;
		else if (bpmChangeMap[index = CoolUtil.boundInt(index, 0, bpmChangeMap.length - 1)].songTime > time) {
			while (--index > 0) if (time > bpmChangeMap[index].songTime) return index;
			return 0;
		}
		else {
			for (i in index...bpmChangeMap.length) if (bpmChangeMap[i].songTime > time) return i - 1;
			return bpmChangeMap.length - 1;
		}
	}

	public static function getStepsInChangeIndex(stepTime:Float, index:Int = 0):Int {
		if (bpmChangeMap.length < 2) return bpmChangeMap.length - 1;
		else if (bpmChangeMap[index = CoolUtil.boundInt(index, 0, bpmChangeMap.length - 1)].stepTime > stepTime) {
			while (--index > 0) if (stepTime > bpmChangeMap[index].stepTime) return index;
			return 0;
		}
		else {
			for (i in index...bpmChangeMap.length) if (bpmChangeMap[i].stepTime > stepTime) return i - 1;
			return bpmChangeMap.length - 1;
		}
	}

	public static function getBeatsInChangeIndex(beatTime:Float, index:Int = 0):Int {
		if (bpmChangeMap.length < 2) return bpmChangeMap.length - 1;
		else if (bpmChangeMap[index = CoolUtil.boundInt(index, 0, bpmChangeMap.length - 1)].beatTime > beatTime) {
			while (--index > 0) if (beatTime > bpmChangeMap[index].beatTime) return index;
			return 0;
		}
		else {
			for (i in index...bpmChangeMap.length) if (bpmChangeMap[i].beatTime > beatTime) return i - 1;
			return bpmChangeMap.length - 1;
		}
	}

	public static function getMeasuresInChangeIndex(measureTime:Float, index:Int = 0):Int {
		if (bpmChangeMap.length < 2) return bpmChangeMap.length - 1;
		else if (bpmChangeMap[index = CoolUtil.boundInt(index, 0, bpmChangeMap.length - 1)].measureTime > measureTime) {
			while (--index > 0) if (measureTime > bpmChangeMap[index].measureTime) return index;
			return 0;
		}
		else {
			for (i in index...bpmChangeMap.length) if (bpmChangeMap[i].measureTime > measureTime) return i - 1;
			return bpmChangeMap.length - 1;
		}
	}

	public static function getTimeWithIndexInBPM(time:Float, index:Int):Float {
		var bpmChange = bpmChangeMap[index];
		if (bpmChange.continuous && time < bpmChange.endSongTime && index > 0) {
			var prevBPM = bpmChangeMap[index - 1].bpm;
			if (time <= bpmChange.songTime) return prevBPM;

			var ratio = (time - bpmChange.songTime) / (bpmChange.endSongTime - bpmChange.songTime);
			return Math.pow(prevBPM, 1 - ratio) * Math.pow(bpmChange.bpm, ratio);
		}
		return bpmChange.bpm;
	}

	public static function getStepsWithIndexInBPM(stepTime:Float, index:Int):Float {
		var bpmChange = bpmChangeMap[index];
		if (bpmChange.continuous && index > 0) {
			var prevBPM = bpmChangeMap[index - 1].bpm;
			if (stepTime <= bpmChange.stepTime) return prevBPM;

			var endStepTime = bpmChange.stepTime + (bpmChange.endSongTime - bpmChange.songTime) * (bpmChange.bpm - prevBPM) / Math.log(bpmChange.bpm / prevBPM) / 15000;
			if (stepTime < endStepTime) return FlxMath.remapToRange(stepTime, bpmChange.stepTime, endStepTime, prevBPM, bpmChange.bpm);
		}
		return bpmChange.bpm;
	}

	public static function getTimeInBPM(time:Float):Float {
		if (bpmChangeMap.length == 0) return dummyChange.bpm;
		return getTimeWithIndexInBPM(time, getTimeInChangeIndex(time));
	}

	public static function getTimeWithBPMInSteps(time:Float, index:Int, bpm:Float):Float {
		var bpmChange = bpmChangeMap[index];
		if (bpmChange.continuous && time > bpmChange.songTime && index > 0) {
			var prevBPM = bpmChangeMap[index - 1].bpm;
			if (time > bpmChange.endSongTime)
				return bpmChange.stepTime + (((bpmChange.endSongTime - bpmChange.songTime) * (bpmChange.bpm - prevBPM))
					/ Math.log(bpmChange.bpm / prevBPM) + (time - bpmChange.endSongTime) * bpm) / 15000;
			else
				return bpmChange.stepTime + (time - bpmChange.songTime) * (bpm - prevBPM) / Math.log(bpm / prevBPM) / 15000;
		}
		else {
			return bpmChange.stepTime + (time - bpmChange.songTime) / (15000 / bpm);
		}
	}

	public static function getTimeInBeats(time:Float, from:Int = 0):Float {
		var index = getTimeInChangeIndex(time, from);
		if (index == -1) return time / (60000 / dummyChange.bpm);
		else if (index == 0) return time / (15000 / bpmChangeMap[index].bpm) / bpmChangeMap[index].stepsPerBeat;
		else {
			var change = bpmChangeMap[index];
			return change.beatTime + (getTimeWithBPMInSteps(time, index, getTimeWithIndexInBPM(time, index)) - change.stepTime) / change.stepsPerBeat;
		}
	}

	public static function getTimeInSteps(time:Float, from:Int = 0):Float {
		var index = getTimeInChangeIndex(time, from);
		return index < 1 ? time / (15000 / getTimeInBPM(time)) : getTimeWithBPMInSteps(time, index, getTimeWithIndexInBPM(time, index));
	}

	@:noCompletion
	@:haxe.warning("-WDeprecated")
	public static inline function getStepForTime(time:Float):Float return getTimeInSteps(time);

	public static function getStepsWithBPMInTime(stepTime:Float, index:Int, bpm:Float):Float {
		var bpmChange = bpmChangeMap[index];
		if (bpmChange.continuous && stepTime > bpmChange.stepTime && index > 0) {
			var prevBPM = bpmChangeMap[index - 1].bpm;
			var time = bpmChange.songTime + (stepTime - bpmChange.stepTime) / (bpm - prevBPM) * Math.log(bpm / prevBPM) * 15000;
			if (time > bpmChange.endSongTime)
				return (15000 * (stepTime - bpmChange.stepTime) - ((bpmChange.endSongTime - bpmChange.songTime) * (bpm - prevBPM))
					/ Math.log(bpm / prevBPM)) / bpm + bpmChange.endSongTime;
			else
				return time;
		}
		else {
			return bpmChange.songTime + (stepTime - bpmChange.stepTime) * (15000 / bpm);
		}
	}

	public static function getMeasuresInTime(measureTime:Float, from:Int = 0):Float {
		var index = getMeasuresInChangeIndex(measureTime, from);
		if (index == -1) return measureTime * (15000 / dummyChange.bpm);
		else if (index == 0) return measureTime * (15000 / bpmChangeMap[index].bpm) * bpmChangeMap[index].stepsPerBeat * bpmChangeMap[index].beatsPerMeasure;
		else {
			var change = bpmChangeMap[index];
			var stepTime = change.stepTime + (measureTime - change.measureTime) * change.stepsPerBeat * change.beatsPerMeasure;
			return getStepsWithBPMInTime(stepTime, index, getStepsWithIndexInBPM(stepTime, index));
		}
	}

	public static function getBeatsInTime(beatTime:Float, from:Int = 0):Float {
		var index = getBeatsInChangeIndex(beatTime, from);
		if (index == -1) return beatTime * (15000 / dummyChange.bpm);
		else if (index == 0) return beatTime * (15000 / bpmChangeMap[index].bpm) * bpmChangeMap[index].stepsPerBeat;
		else {
			var change = bpmChangeMap[index];
			var stepTime = change.stepTime + (beatTime - change.beatTime) * change.stepsPerBeat;
			return getStepsWithBPMInTime(stepTime, index, getStepsWithIndexInBPM(stepTime, index));
		}
	}

	public static function getStepsInTime(stepTime:Float, from:Int = 0):Float {
		var index = getStepsInChangeIndex(stepTime, from);
		return index < 1 ? stepTime * (15000 / bpmChangeMap[index].bpm) : getStepsWithBPMInTime(stepTime, index, getStepsWithIndexInBPM(stepTime, index));
	}

	@:noCompletion
	@:haxe.warning("-WDeprecated")
	public static inline function getTimeForStep(steps:Float):Float return getStepsInTime(steps);

	public static inline function getMeasureLength()
		return stepsPerBeat * beatsPerMeasure;

	public static inline function getMeasuresLength() {
		if (FlxG.sound.music == null) return 0.0;
		var length = FlxG.sound.music.length;
		var index = getTimeInChangeIndex(length, bpmChangeMap.length - 1);
		var change = bpmChangeMap[index];
		return change.measureTime + (getTimeInBeats(length, index) - change.beatTime) / change.beatsPerMeasure;
	}
}