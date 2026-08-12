package funkin.backend.utils.native;

#if linux
@:cppFileCode("#include <stdio.h>")
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
		FILE *status = fopen("/proc/self/status", "r");
		if (status == NULL) return 0.0;

		char line[256];
		while (fgets(line, sizeof(line), status)) {
			long rss;
			if (sscanf(line, "VmRSS: %ld kB", &rss) == 1) {
				fclose(status);
				return (double)(rss * 1024); // kB -> bytes
			}
		}
		fclose(status);
		return 0.0;
	')
	public static function getCurrentProcessMemory():Float
	{
		return 0;
	}
}
#end