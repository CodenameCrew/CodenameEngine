package funkin.backend.scripting.events.splash;

import funkin.game.Splash;
import funkin.game.SplashGroup;
import funkin.game.Strum;

final class SplashShowEvent extends CancellableEvent {
	/**
		Splash name/type
	**/
	public var splashName:String;
	/**
		Splash that is shown
	**/
	public var splash:Splash;
	/**
		Strum that the splash is shown on
	**/
	public var strum:Strum;
	/**
		Splash group that the splash is from
	**/
	public var group:SplashGroup;
}