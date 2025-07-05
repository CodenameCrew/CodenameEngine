package funkin.backend.utils.native;

#if windows
import funkin.backend.utils.NativeAPI.FileAttribute;
import funkin.backend.utils.NativeAPI.MessageBoxIcon;
@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows" />
	<lib name="shell32.lib" if="windows" />
	<lib name="gdi32.lib" if="windows" />
	<lib name="ole32.lib" if="windows" />
	<lib name="uxtheme.lib" if="windows" />
</target>
')

// majority is taken from microsofts doc
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

#define SAFE_RELEASE(punk)  \\
			  if ((punk) != NULL)  \\
				{ (punk)->Release(); (punk) = NULL; }

static long lastDefId = 0;

class AudioFixClient : public IMMNotificationClient {
	LONG _cRef;
	IMMDeviceEnumerator *_pEnumerator;

	public:
	AudioFixClient() :
		_cRef(1),
		_pEnumerator(NULL)
	{
		HRESULT result = CoCreateInstance(__uuidof(MMDeviceEnumerator),
							  NULL, CLSCTX_INPROC_SERVER,
							  __uuidof(IMMDeviceEnumerator),
							  (void**)&_pEnumerator);
		if (result == S_OK) {
			_pEnumerator->RegisterEndpointNotificationCallback(this);
		}
	}

	~AudioFixClient()
	{
		SAFE_RELEASE(_pEnumerator);
	}

	ULONG STDMETHODCALLTYPE AddRef()
	{
		return InterlockedIncrement(&_cRef);
	}

	ULONG STDMETHODCALLTYPE Release()
	{
		ULONG ulRef = InterlockedDecrement(&_cRef);
		if (0 == ulRef)
		{
			delete this;
		}
		return ulRef;
	}

	HRESULT STDMETHODCALLTYPE QueryInterface(
								REFIID riid, VOID **ppvInterface)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceAdded(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	};

	HRESULT STDMETHODCALLTYPE OnDeviceRemoved(LPCWSTR pwstrDeviceId)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDeviceStateChanged(
								LPCWSTR pwstrDeviceId,
								DWORD dwNewState)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnPropertyValueChanged(
								LPCWSTR pwstrDeviceId,
								const PROPERTYKEY key)
	{
		return S_OK;
	}

	HRESULT STDMETHODCALLTYPE OnDefaultDeviceChanged(
		EDataFlow flow, ERole role,
		LPCWSTR pwstrDeviceId)
	{
		::funkin::backend::_hx_system::Main_obj::audioDisconnected = true;
		return S_OK;
	};
};

AudioFixClient *curAudioFix;
')
@:dox(hide)
class Windows {

	public static var __audioChangeCallback:Void->Void = function() {
		trace("test");
	};


	@:functionCode('
	if (!curAudioFix) curAudioFix = new AudioFixClient();
	')
	public static function registerAudio() {
		funkin.backend.system.Main.audioDisconnected = false;
	}

	@:functionCode('
		int darkMode = enable ? 1 : 0;

		HWND window = FindWindowA(NULL, title.c_str());
		// Look for child windows if top level aint found
		if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
		// If still not found, try to get the active window
		if (window == NULL) window = GetActiveWindow();
		if (window == NULL) return;

		if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
			DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
		}
		UpdateWindow(window);
	')
	public static function setDarkMode(title:String, enable:Bool) {}

	@:functionCode('
	HWND window = FindWindowA(NULL, title.c_str());
	if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
	if (window == NULL) window = GetActiveWindow();
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
	HWND window = FindWindowA(NULL, title.c_str());
	if (window == NULL) window = FindWindowExA(GetActiveWindow(), NULL, NULL, title.c_str());
	if (window == NULL) window = GetActiveWindow();
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
	// https://stackoverflow.com/questions/15543571/allocconsole-not-displaying-cout

	if (!AllocConsole())
		return;

	freopen("CONIN$", "r", stdin);
	freopen("CONOUT$", "w", stdout);
	freopen("CONOUT$", "w", stderr);
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
}
#end