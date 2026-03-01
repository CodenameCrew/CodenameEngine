package funkin.backend.utils;

#if (target.threaded)
import sys.thread.Deque;
import sys.thread.Thread;
import sys.thread.Mutex;
#else
private typedef Thread = Dynamic;
#end

#if !macro
import funkin.backend.system.Logs;
#end

final class ThreadUtil {
	inline static function error(text:String) {
		#if macro
		trace(text);
		#else
		FlxG.signals.preUpdate.addOnce(Logs.error.bind(text));
		#end
	}

	/**
	 * Creates a new Thread with an error handler.
	 * @param func Function to execute
	 * @param autoRestart Whenever the thread should auto restart itself after crashing.
	 */
	public static function createSafe(func:Void->Void, autoRestart:Bool = false):Thread {
		#if (target.threaded)
		try {
			return if (autoRestart) Thread.create(() -> {
				var restart = true;
				while (restart) try {
					func();
					restart = false;
				}
				catch (e) error(e.details());
			})
			else Thread.create(() -> {
				try {func();}
				catch (e) error(e.details());
			});
		}
		catch (e) error("Failed to safely create a thread: " + e.details());
		#end
		return null;
	}

	#if ALLOW_MULTITHREADING
	public static var maxThreads:Int = 4;

	static var __threads:Array<Thread> = [];
	static var __pendingExecs:Deque<Void->Void> = new Deque();
	static var __threadMutex:Mutex = new Mutex();
	static var __threadUsed:Int = 0;

	static function __threadExecAsync() {
		var callback:Void->Void;
		while ((callback = __pendingExecs.pop(true)) != null) {
			__threadMutex.acquire();
			__threadUsed++;
			__threadMutex.release();

			callback();

			__threadMutex.acquire();
			__threadUsed--;
			__threadMutex.release();
		}
		__threadMutex.acquire();
		__threads.remove(Thread.current());
		__threadMutex.release();
	}
	#end

	public static function execAsync(func:Void->Void) {
		if (func == null) return;

		#if (ALLOW_MULTITHREADING && !macro)
		__pendingExecs.add(func);
		if (__threadUsed >= __threads.length) {
			if (__threads.length == maxThreads) return;

			__threadMutex.acquire();
			try {
				var thread = Thread.create(__threadExecAsync);
				__threads.push(thread);
			}
			catch (e) Logs.warn(e.details());
			__threadMutex.release();
		}
		#else
		func();
		#end
	}
}