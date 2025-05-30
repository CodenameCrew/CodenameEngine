package funkin.backend.utils;

enum abstract RegistryHive(Int) {
	var HKEY_CLASSES_ROOT = 0x80000000;
	var HKEY_CURRENT_USER = 0x80000001;
	var HKEY_LOCAL_MACHINE = 0x80000002;
	var HKEY_USERS = 0x80000003;
	var HKEY_CURRENT_CONFIG = 0x80000005;
}
#if windows
@:cppFileCode('
#include <windows.h>
#include <tchar.h>
#include <string>
#include <vector>
')
#end
class RegistryUtil {
	#if windows
	@:functionCode('
		HKEY hKey;
		LONG result;
		DWORD dataSize = 0;
		DWORD dataType = 0;

		std::wstring subkey = std::wstring(key.wchar_str());
		std::wstring valname = std::wstring(string.wchar_str());

		result = RegOpenKeyExW((HKEY)reinterpret_cast<HKEY>(static_cast<uintptr_t>(hive)), subkey.c_str(), 0, KEY_READ, &hKey);
		if (result != ERROR_SUCCESS) return ::String((String)0);

		result = RegQueryValueExW(hKey, valname.c_str(), NULL, &dataType, NULL, &dataSize);
		if (result != ERROR_SUCCESS || dataSize == 0) {
			RegCloseKey(hKey);
			return (::String)0;
		}

		std::vector<wchar_t> buffer(dataSize / sizeof(wchar_t));
		result = RegQueryValueExW(hKey, valname.c_str(), NULL, NULL, (LPBYTE)buffer.data(), &dataSize);
		RegCloseKey(hKey);

		if (result == ERROR_SUCCESS) {
			return ::String(buffer.data());
		}
		return (::String)0;
	')
	#end
	public static function get(hive:RegistryHive, key:String, string:String):String
	{
		return null;
	}

	#if windows
	@:functionCode('
		HKEY hKey;
		LONG result;

		std::wstring subkey = std::wstring(key.wchar_str());
		std::wstring valname = std::wstring(string.wchar_str());
		std::wstring data = std::wstring(value.wchar_str());

		result = RegCreateKeyExW((HKEY)reinterpret_cast<HKEY>(static_cast<uintptr_t>(hive)), subkey.c_str(), 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL);
		if (result != ERROR_SUCCESS) return false;

		result = RegSetValueExW(hKey, valname.c_str(), 0, REG_SZ, (const BYTE*)data.c_str(), (DWORD)((data.length() + 1) * sizeof(wchar_t)));
		RegCloseKey(hKey);

		return result == ERROR_SUCCESS;
	')
	#end
	public static function set(hive:RegistryHive, key:String, string:String, value:String):Bool
	{
		return false;
	}

	#if windows
	@:functionCode('
		HKEY hKey;
		LONG result;

		std::wstring subkey = std::wstring(key.wchar_str());
		std::wstring valname = std::wstring(string.wchar_str());

		result = RegOpenKeyExW((HKEY)reinterpret_cast<HKEY>(static_cast<uintptr_t>(hive)), subkey.c_str(), 0, KEY_READ, &hKey);
		if (result != ERROR_SUCCESS) return false;

		DWORD dataType = 0;
		result = RegQueryValueExW(hKey, valname.c_str(), NULL, &dataType, NULL, NULL);

		RegCloseKey(hKey);

		return result == ERROR_SUCCESS;
	')
	#end
	public static function exists(hive:RegistryHive, key:String, string:String):Bool
	{
		return false;
	}

	#if windows
	@:functionCode('
		HKEY hKey;
		LONG result;

		std::wstring subkey = std::wstring(key.wchar_str());
		std::wstring valname = std::wstring(string.wchar_str());

		result = RegOpenKeyExW((HKEY)reinterpret_cast<HKEY>(static_cast<uintptr_t>(hive)), subkey.c_str(), 0, KEY_SET_VALUE, &hKey);
		if (result != ERROR_SUCCESS) return false;

		result = RegDeleteValueW(hKey, valname.c_str());
		RegCloseKey(hKey);

		return result == ERROR_SUCCESS;
	')
	#end
	public static function delete(hive:RegistryHive, key:String, string:String):Bool {
		return false;
	}
}