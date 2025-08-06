package funkin.backend.utils;

import haxe.Http;

final class HttpUtil
{
	public static var userAgent:String = Flags.USER_AGENT;

	public static function requestText(url:String):String
	{
		var result:String = null;
		var error:HttpError = null;
		var redirected:Bool = false;

		var h = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = function(status)
		{
			redirected = isRedirect(status);
			if (redirected)
			{
				var loc = h.responseHeaders.get("Location");
				if (loc != null)
					result = requestText(loc);
				else
					error = new HttpError("Missing Location header in redirect", url, status, true);
			}
		};

		h.onData = function(data)
		{
			if (result == null)
				result = data;
		};

		h.onError = function(msg)
		{
			error = new HttpError(msg, url);
		};

		h.request(false);

		if (error != null)
			throw error;

		if (result == null)
			throw new HttpError("Unknown error or empty response", url);

		return result;
	}

	public static function requestBytes(url:String):haxe.io.Bytes
	{
		var result:haxe.io.Bytes = null;
		var error:HttpError = null;
		var redirected:Bool = false;

		var h = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = function(status)
		{
			redirected = isRedirect(status);
			if (redirected)
			{
				var loc = h.responseHeaders.get("Location");
				if (loc != null)
					result = requestBytes(loc);
				else
					error = new HttpError("Missing Location header in redirect", url, status, true);
			}
		};

		h.onBytes = function(data)
		{
			if (result == null)
				result = data;
		};

		h.onError = function(msg)
		{
			error = new HttpError(msg, url);
		};

		h.request(false);

		if (error != null)
			throw error;

		if (result == null)
			throw new HttpError("Unknown error or empty byte response", url);

		return result;
	}

	public static function hasInternet():Bool
	{
		try {
			var r = requestText("https://www.google.com/");
			return true;
		} catch (e:HttpError) {
			Logs.trace('[HttpUtil.hasInternet] Failed: ${e.toString()}', WARNING);
			return false;
		}
	}

	private static function isRedirect(status:Int):Bool
	{
		switch (status)
		{
			// 301: Moved Permanently, 302: Found (Moved Temporarily), 307: Temporary Redirect, 308: Permanent Redirect  - Nex
			case 301 | 302 | 307 | 308:
				Logs.traceColored([Logs.logText('[Connection Status] ', BLUE), Logs.logText('Redirected with status code: ', YELLOW), Logs.logText('$status', GREEN)], VERBOSE);
				return true;
		}
		return false;
	}
}

private class HttpError {
	public var message:String;
	public var url:String;
	public var status:Int;
	public var redirected:Bool;

	public function new(message:String, url:String, ?status:Int = -1, ?redirected:Bool = false) {
		this.message = message;
		this.url = url;
		this.status = status;
		this.redirected = redirected;
	}

	public function toString():String {
		var parts:Array<String> = ['[HttpError]'];

		if (status != -1)
			parts.push('Status: $status');

		if (redirected)
			parts.push('(Redirected)');

		parts.push('URL: $url');
		parts.push('Message: $message');

		return parts.join(' | ');
	}
}
