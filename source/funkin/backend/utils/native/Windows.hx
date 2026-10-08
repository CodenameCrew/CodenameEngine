package funkin.backend.utils.native;

#if windows
import funkin.backend.utils.NativeAPI.FileAttribute;
import funkin.backend.utils.NativeAPI.MessageBoxIcon;
import lime.graphics.Image;
import lime.utils.Bytes;
@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows" />
	<lib name="shell32.lib" if="windows" />
	<lib name="gdi32.lib" if="windows" />
	<lib name="ole32.lib" if="windows" />
	<lib name="uxtheme.lib" if="windows" />
</target>
')

// majority is taken from Microsoft's doc
@:cppFileCode('
#include "mmdeviceapi.h"
#include "combaseapi.h"
#include <iostream>
#include <Windows.h>
#include <cstdio>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <Shlobj.h>
#include <wingdi.h>
#include <shellapi.h>
#include <uxtheme.h>
#include <psapi.h>

static HWND findTargetWindow(const char* title) {
	HWND window = FindWindowA(NULL, title);
	// Look for child windows if top level is not found
	if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title);
	// If still not found, try to get the active window
	if (window == NULL) window = GetActiveWindow();

	return window;
}
')
@:dox(hide)
final class Windows {

	@:functionCode('
		int darkMode = enable ? 1 : 0;

		HWND window = findTargetWindow(title.c_str());
		if (window == NULL) return;

		if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
			DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
		}
		UpdateWindow(window);
	')
	public static function setDarkMode(title:String, enable:Bool) {}

	@:functionCode('
	HWND window = findTargetWindow(title.c_str());
	if (window == NULL) return;

	COLORREF finalColor;
	if(color[0] == -1 && color[1] == -1 && color[2] == -1 && color[3] == -1) { // bad fix, I know :sob:
		finalColor = 0xFFFFFFFF; // Default border
	} else if(color[3] == 0) {
		finalColor = 0xFFFFFFFE; // No border (must have setBorder as true)
	} else {
		finalColor = RGB(color[0], color[1], color[2]); // Use your custom color
	}

	if(setHeader) DwmSetWindowAttribute(window, 35, &finalColor, sizeof(COLORREF));
	if(setBorder) DwmSetWindowAttribute(window, 34, &finalColor, sizeof(COLORREF));

	UpdateWindow(window);
	')
	public static function setWindowBorderColor(title:String, color:Array<Int>, setHeader:Bool = true, setBorder:Bool = true) {}

	@:functionCode('
	HWND window = findTargetWindow(title.c_str());
	if (window == NULL) return;

	COLORREF finalColor;
	if(color[0] == -1 && color[1] == -1 && color[2] == -1 && color[3] == -1) { // bad fix, I know :sob:
		finalColor = 0xFFFFFFFF; // Default border
	} else {
		finalColor = RGB(color[0], color[1], color[2]); // Use your custom color
	}

	DwmSetWindowAttribute(window, 36, &finalColor, sizeof(COLORREF));
	UpdateWindow(window);
	')
	public static function setWindowTitleColor(title:String, color:Array<Int>) {}

	@:functionCode('
	HWND window = findTargetWindow(title.c_str());
	if (window == NULL) return;

	HICON smallIcon = (HICON) LoadImage(NULL, path.c_str(), IMAGE_ICON, GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), LR_LOADFROMFILE);
	HICON icon = (HICON) LoadImage(NULL, path.c_str(), IMAGE_ICON, GetSystemMetrics(SM_CXICON), GetSystemMetrics(SM_CYICON), LR_LOADFROMFILE | LR_DEFAULTSIZE);

	if (icon) {
		HICON iconOld = (HICON) SendMessage(window, WM_GETICON, ICON_BIG, 0);
		SendMessage(window, WM_SETICON, ICON_BIG, (LPARAM) icon);
		if (iconOld) DestroyIcon(iconOld);
	}

	if (smallIcon) {
		HICON smallIconOld = (HICON) SendMessage(window, WM_GETICON, ICON_SMALL, 0);
		SendMessage(window, WM_SETICON, ICON_SMALL, (LPARAM) smallIcon);
		if (smallIconOld) DestroyIcon(smallIconOld);
	}
	')
	public static function setWindowIcon(title:String, path:String) {}

	// Expects a fixed BGRA non-premultiplied
	@:functionCode('
	HWND window = findTargetWindow(title.c_str());
	if (window == NULL) return;

	const void* data = (const void*)bytes->b->getBase();
	size_t size = (size_t)bytes->length;

	BITMAPINFO bi;
	ZeroMemory(&bi, sizeof(bi));
	bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bi.bmiHeader.biWidth = width;
	bi.bmiHeader.biHeight = -height;
	bi.bmiHeader.biPlanes = 1;
	bi.bmiHeader.biBitCount = 32;
	bi.bmiHeader.biCompression = BI_RGB;

	void* pixels = NULL;
	HDC hdc = GetDC(NULL);
	HBITMAP color = CreateDIBSection(hdc, &bi, DIB_RGB_COLORS, &pixels, NULL, 0);
	ReleaseDC(NULL, hdc);
	if (!color || !pixels) {
		if (color) DeleteObject(color);
		return;
	}
	memcpy(pixels, data, width * height * 4);

	HBITMAP mask = CreateBitmap(width, height, 1, 1, NULL);
    if (!mask) {
        DeleteObject(color);
        return;
    }

    ICONINFO ii;
	ZeroMemory(&ii, sizeof(ii));
	ii.fIcon = TRUE;
	ii.hbmMask = mask;
	ii.hbmColor = color;
	HICON icon = CreateIconIndirect(&ii);

	DeleteObject(color);
	DeleteObject(mask);

	if (big) {
		HICON iconOld = (HICON) SendMessage(window, WM_GETICON, ICON_BIG, 0);
		SendMessage(window, WM_SETICON, ICON_BIG, (LPARAM) icon);
		if (iconOld) DestroyIcon(iconOld);
	}
	else {
		HICON iconOld = (HICON) SendMessage(window, WM_GETICON, ICON_SMALL, 0);
		SendMessage(window, WM_SETICON, ICON_SMALL, (LPARAM) icon);
		if (iconOld) DestroyIcon(iconOld);
	}
	')
	public static function setWindowIconBytes(big:Bool, title:String, bytes:Bytes, width:Int, height:Int) {}

	public static function setWindowIconImage(big:Bool, title:String, image:Image)
	{
		if (image.format != BGRA32 || image.premultiplied)
		{
			image = image.clone();
			image.format = BGRA32;
			image.premultiplied = false;
		}

		setWindowIconBytes(big, title, image.data.buffer, image.width, image.height);
	}

	public static function getWindowIconMetrics(big:Bool = true):Int
	{
		return untyped __cpp__("GetSystemMetrics(big ? SM_CXICON : SM_CXSMICON)");
	}

	@:functionCode('
	// https://stackoverflow.com/questions/15543571/allocconsole-not-displaying-cout

	if (!AllocConsole())
		return;

	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);

	SetConsoleOutputCP(65001);
	SetConsoleCP(65001);
	')
	public static function allocConsole() {
	}

	@:functionCode('
		return GetFileAttributes(path);
	')
	public static function getFileAttributes(path:String):FileAttribute
	{
		return NORMAL;
	}

	@:functionCode('
		return SetFileAttributes(path, attrib);
	')
	public static function setFileAttributes(path:String, attrib:FileAttribute):Int
	{
		return 0;
	}


	@:functionCode('
		HANDLE console = GetStdHandle(STD_OUTPUT_HANDLE);
		SetConsoleTextAttribute(console, color);
	')
	public static function setConsoleColors(color:Int) {

	}

	@:functionCode('
		system("CLS");
		std::cout<< "" <<std::flush;
	')
	public static function clearScreen() {

	}


	@:functionCode('
		MessageBox(GetActiveWindow(), message, caption, icon | MB_SETFOREGROUND);
	')
	public static function showMessageBox(caption:String, message:String, icon:MessageBoxIcon = MSG_WARNING) {

	}

	@:functionCode('
		SetProcessDPIAware();
	')
	public static function registerAsDPICompatible() {}

	@:functionCode("
		// simple but effective code
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	")
	public static function getTotalRam():Float
	{
		return 0;
	}

	@:functionCode("
		PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))) {
			return (double)pmc.WorkingSetSize;
		}
		return 0.0;
	")
	public static function getCurrentProcessMemory():Float
	{
		return 0;
	}
}
#end