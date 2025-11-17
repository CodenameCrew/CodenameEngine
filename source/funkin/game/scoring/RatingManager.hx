package funkin.game.scoring;

import funkin.game.scoring.*;
import funkin.game.scoring.HitWindowData.WindowPreset;

import haxe.ds.StringMap;

/**
 * Judges note hits and returns a rating.
 */
class RatingManager
{
	public var hitWindows:StringMap<Float>;
	public var ratingData:Array<Rating> = [];

	public function new(?preset:WindowPreset):Void
	{
		var usedPreset = preset != null ? preset : WindowPreset.DEFAULT;
		hitWindows = HitWindowData.getWindows(usedPreset);
		initDefaultData(hitWindows);
	}

	/**
	 * Returns a rating based on a wimdow of time.
	 * @param time The timing window to judge.
	 */
	public function judgeNote(time:Float):Rating
	{
		for (i => rating in ratingData)
		{
			if (rating.hittable && rating.window > -1 && time <= rating.window)
			{
				return rating;
			}
		}
		return ratingData.last();
	}

	/**
	 * Initializes the default rating data containing the four judgements.
	 * 
	 * "Sick", "Good", "Bad", "Shit"
	 */
	public function initDefaultData(windows:StringMap<Float>)
	{
		inline function getWindow(name:String):Float
		{
			return windows.exists(name) ? windows.get(name) : -1;
		}

		addRating({name: "sick", window: getWindow("sick"), accuracy: 1, score: 300, splash: true});
		addRating({name: "good", window: getWindow("good"), accuracy: 0.75, score: 200});
		addRating({name: "bad", window: getWindow("bad"), accuracy: 0.45, score: 100});
		addRating({name: "shit", window: getWindow("shit"), accuracy: 0.25, score: 50});
	}

	public function addRating(data:Dynamic)
	{
		if (data == null || data.name == null) return;

		var name = data.name.toLowerCase();
		var window = data.window != null
			? data.window
			: (hitWindows.exists(name) ? hitWindows.get(name) : -1);

		var newRating:Rating = {
			name: name,
			window: window,
			accuracy: data.accuracy != null ? data.accuracy : 1,
			score: data.score != null ? data.score : 0,
			splash: data.splash == true,
			hittable: data.hittable != null ? data.hittable : true
		};

		var existingIndex = -1;
		for (i in 0...ratingData.length)
			if (ratingData[i].name == name)
				existingIndex = i;

		if (existingIndex >= 0)
			ratingData[existingIndex] = newRating;
		else
			ratingData.push(newRating);

		ratingData.sort((a, b) -> Reflect.compare(a.window, b.window));
	}

	public function removeRating(name:String):Void
	{
		if (name == null) return;
		name = name.toLowerCase();
		ratingData = ratingData.filter(r -> r.name != name);
	}

	public function getHitWindow(name:String):Float
	{
		return hitWindows.exists(name) ? hitWindows.get(name) : -1;
	}
}

@:structInit
final class Rating
{
	/**
	 * Name of rating.
	 * 
	 * Also used for the image file name of the rating.
	 */
	public var name:String = "unknown";

	/**
	 * Amount of accuracy given when earning this rating.
	 */
	public var accuracy:Float = 0.0;

	/**
	 * MS Timing Window to hit the rating.
	 */
	public var window:Float = -1;

	/**
	 * Amount of score given when earning this rating.
	 */
	public var score:Int = 0;

	/**
	 * If this rating was hit, a note splash will appear.
	 */
	@:optional public var splash:Bool = false;

	/**
	 * Whether the rating is hittable or not.
	 */
	@:optional public var hittable:Bool = true;
}