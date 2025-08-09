package funkin.backend.utils;

#if ALLOW_MULTITHREADING
final class ThreadUtil {
	/**
	 * Creates a new Thread with an error handler.
	 * @param func Function to execute
	 * @param autoRestart Whenever the thread should auto restart itself after crashing.
	 */
	public static function createSafe(func:Void->Void, autoRestart:Bool = false) {
		if (autoRestart) {
			return sys.thread.Thread.create(function() {
				while(true) {
					try {
						func();
					} catch(e) {
						trace(e.details());
					}
				}
			});
		} else {
			return sys.thread.Thread.create(function() {
				try {
					func();
				} catch(e) {
					trace(e.details());
				}
			});
		}
	}
}
#end