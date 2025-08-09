package funkin.backend.system.macros;

#if macro
import sys.io.Process;
#end

class GitCommitMacro {
	/**
	 * Returns the current commit number
	 */
	public static var commitNumber(get, never):Int;
	/**
	 * Returns the current commit hash
	 */
	public static var commitHash(get, never):String;
	/**
	 * Returns the current commit hash in long format
	 */
	public static var commitHashLong(get, never):String;
	/**
	 * Returns the current commit message
	 */
	public static var commitMessage(get, never):String;
	/**
	 * Returns the current commit author
	 */
	public static var commitAuthor(get, never):String;
	/**
	 * Returns the current commit date + time
	**/
	public static var commitDate(get, never):Date;
	/**
	 * Returns the current branch name
	**/
	public static var currentBranch(get, never):String;
	/**
	 * Returns if there are uncommitted changes
	**/
	public static var hasUncommittedChanges(get, never):Bool;

	// GETTERS
	#if REGION
	private static inline function get_commitNumber()
		return __getCommitNumber();

	private static inline function get_commitHash()
		return __getCommitHash();
	private static inline function get_commitHashLong()
		return __getCommitHashLong();

	private static inline function get_commitMessage()
		return __getCommitMessage();
	private static inline function get_commitAuthor()
		return __getCommitAuthor();
	private static inline function get_commitDate()
		return __getCommitDate();

	private static inline function get_currentBranch()
		return __getCurrentBranch();
	private static inline function get_hasUncommittedChanges()
		return __getHasUncommittedChanges();
	#end

	// INTERNAL MACROS
	#if REGION
	private static macro function __getCommitHash() {
		#if display
		return macro $v{"-"};
		#else
		try {
			var proc = new Process('git', ['rev-parse', '--short', 'HEAD'], false);
			proc.exitCode(true);

			return macro $v{proc.stdout.readLine()};
		} catch(e) {}
		return macro $v{"-"}
		#end
	}

	private static macro function __getCommitNumber() {
		#if display
		return macro $v{0};
		#else
		try {
			var proc = new Process('git', ['rev-list', 'HEAD', '--count'], false);
			proc.exitCode(true);

			return macro $v{Std.parseInt(proc.stdout.readLine())};
		} catch(e) {}
		return macro $v{0}
		#end
	}

	private static macro function __getCommitHashLong() {
		#if display
		return macro $v{"-"};
		#else
		try {
			var proc = new Process('git', ['rev-parse', 'HEAD'], false);
			proc.exitCode(true);

			return macro $v{proc.stdout.readLine()};
		} catch(e) {}
		return macro $v{"-"}
		#end
	}

	private static macro function __getCommitMessage() {
		#if display
		return macro $v{"-"};
		#else
		try {
			var proc = new Process('git', ['log', '-1', '--pretty=%B'], false);
			proc.exitCode(true);
			var all = proc.stdout.readAll().toString();
			while(StringTools.endsWith(all, "\r\n")) all = all.substr(0, all.length - 2);
			while(StringTools.endsWith(all, "\n")) all = all.substr(0, all.length - 1);
			while(StringTools.endsWith(all, "\r")) all = all.substr(0, all.length - 1);

			return macro $v{all};
		} catch(e) {}
		return macro $v{"-"}
		#end
	}

	private static macro function __getCommitAuthor() {
		#if display
		return macro $v{"-"};
		#else
		try {
			var proc = new Process('git', ['log', '-1', '--pretty=%an'], false);
			proc.exitCode(true);

			return macro $v{StringTools.trim(proc.stdout.readLine())};
		} catch(e) {}
		return macro $v{"-"}
		#end
	}

	private static macro function __getCommitDate() {
		#if display
		return macro $v{Date.now()};
		#else
		try {
			// get the time in UTC format
			var oldTz = Sys.getEnv("TZ");
			Sys.putEnv("TZ", "UTC0");
			var proc = new Process('git', ['log', "--date='format-local:%Y-%m-%dT%H:%M:%SZ'", '-1', '--pretty=%cd'], false);
			proc.exitCode(true);
			Sys.putEnv("TZ", oldTz);

			var rawDate = StringTools.trim(proc.stdout.readLine());

			try {
				Date.fromString(rawDate);
			} catch(e) {
				throw 'Invalid date format: $rawDate';
			}

			return macro Date.fromString($v{rawDate});
		} catch(e) {}
		return macro Date.fromString("1970-01-01T00:00:00"); // failed to parse date
		#end
	}

	private static macro function __getCurrentBranch() {
		#if display
		return macro $v{"-"};
		#else
		try {
			var process = new Process("git", ["rev-parse", "--abbrev-ref", "HEAD"], false);
			if (process.exitCode() != 0)
				throw 'Could not fetch current branch';

			return macro $v{process.stdout.readLine().toString()};
		} catch(e) {}
		return macro $v{"-"}
		#end
	}

	private static macro function __getHasUncommittedChanges() {
		#if display
		return macro $v{false};
		#else
		try {
			var process = new Process("git", ["status", "--porcelain"], false);
			if (process.exitCode() != 0)
				throw 'Could not fetch current branch';

			return macro $v{process.stdout.readLine().toString() != ""};
		} catch(e) {}
		return macro $v{false}
		#end
	}
	#end
}