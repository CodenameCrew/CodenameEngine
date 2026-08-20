package funkin.backend.utils.native;

#if linux
@:cppFileCode("#include <stdio.h>\n#include <time.h>")
@:dox(hide)
final class Linux {
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

		if(meminfo == NULL)
			return -1;

		char line[256];
		while(fgets(line, sizeof(line), meminfo))
		{
			int ram;
			if(sscanf(line, "MemTotal: %d kB", &ram) == 1)
			{
				fclose(meminfo);
				return (ram / 1024);
			}
		}

		fclose(meminfo);
		return -1;
	')
	public static function getTotalRam():Float
	{
		return 0;
	}

	@:functionCode('
	struct timespec now;
	clock_gettime(CLOCK_MONOTONIC, &now);
	long long nowMs = now.tv_sec * 1000LL + now.tv_nsec / 1000000LL;

	// cache the value and only re-read /proc every 500ms, to avoid polling the kernel file every frame
	static long long lastReadMs = 0;
	static double cached = 0.0;

	if (cached != 0.0 && (nowMs - lastReadMs) < 500)
		return cached;

	lastReadMs = nowMs;

	FILE *status = fopen("/proc/self/status", "r");
	if (status == NULL) return cached;

	char line[256];
	while (fgets(line, sizeof(line), status)) {
		unsigned long long rss; // use 64-bit so the kB -> bytes conversion never overflows on 32-bit builds
		if (sscanf(line, "VmRSS: %llu kB", &rss) == 1) {
			fclose(status);
			return cached = (double)rss * 1024.0; // kB -> bytes
		}
	}
	fclose(status);
	return cached;
')
	public static function getCurrentProcessMemory():Float
	{
		return 0;
	}
}
#end