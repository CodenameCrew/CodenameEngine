package funkin.backend.utils;

#if ALLOW_MULTITHREADING
import sys.thread.Thread;
#end

#if !macro
import funkin.backend.scripting.MultiThreadedScript;
import funkin.backend.scripting.Script;
#end

final class EngineUtil {
	#if !macro
	/**
	 * Starts a new multithreaded script.
	 * This script will share all the variables with the current one, which means already existing callbacks will be replaced by new ones on conflict.
	 * @param path
	 */
	public static function startMultithreadedScript(path:String) {
		return new MultiThreadedScript(path, Script.curScript);
	}
	#end

	#if ALLOW_MULTITHREADING
	public static var gameThreads:Array<Thread> = [];

	private static var maxThreads:Int = 4;
	private static var threadCycle:Int = 0;
	private static var threadsInitialized:Bool = false;
	#else
	public static var gameThreads:Array<Dynamic> = [];
	#end

	/**
	 * Execute a function asynchronously using existing threads when initialized with ALLOW_MULTITHREADING.
	 * @param func Void -> Void
	 */
	public static function execAsync(func:Void->Void) {
		#if ALLOW_MULTITHREADING
		if (!threadsInitialized) {
			threadsInitialized = true;
			for (i in 0...maxThreads) gameThreads.push(Thread.createWithEventLoop(() -> Thread.current().events.promise()));
		}
		gameThreads[threadCycle].events.run(func);
		if (++threadCycle >= maxThreads) threadCycle = 0;
		#else
		func();
		#end
	}
}