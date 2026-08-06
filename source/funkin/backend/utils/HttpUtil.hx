package funkin.backend.utils;

import haxe.Http;

/**
 * Utility class for making synchronous HTTP requests with automatic redirect handling.
 * All methods are blocking and throw `HttpError` on failure. Redirects (301, 302, 307, 308) are followed recursively using the `Location` response header.
 */
final class HttpUtil
{
	/**
	 * The User-Agent header sent with every request.
	 * Defaults to `Flags.USER_AGENT`.
	 */
	public static var userAgent:String = Flags.USER_AGENT;

	/**
	 * Makes a synchronous GET request and returns the response body as a string.
	 * Automatically follows redirects.
	 * @param url The URL to request.
	 * @return The response body as a `String`.
	 * @throws HttpError If the request fails, redirects without a `Location` header, or returns an empty response.
	 */
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

	/**
	 * Makes a synchronous GET request and returns the response body as raw bytes.
	 * This automatically follows redirects.
	 * @param url The URL to request.
	 * @return The response body as `haxe.io.Bytes`.
	 * @throws HttpError If the request fails, redirects without a `Location` header, or returns an empty response.
	 */
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

	/**
	 * Checks whether an internet connection is available by pinging (or requesting) `google.com`.
	 * @return `true` if the request succeeded, `false` if it threw an `HttpError`.
	 */
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

	/**
	 * Returns whether an HTTP status code represents a redirect.
	 * It handles 301, 302, 307, and 308.
	 * @param status The HTTP status code to check.
	 * @return `true` if the status is a redirect code.
	 */
	private static function isRedirect(status:Int):Bool
	{
		switch (status)
		{
			case 301 | 302 | 307 | 308:
				Logs.traceColored([Logs.logText('[Connection Status] ', BLUE), Logs.logText('Redirected with status code: ', YELLOW), Logs.logText('$status', GREEN)], VERBOSE);
				return true;
		}
		return false;
	}
}

/**
 * Represents an HTTP error with context about the failed request.
 */
private class HttpError
{
	/** The error message. */
	public var message:String;
	/** The URL that triggered the error. */
	public var url:String;
	/** The HTTP status code, or `-1` if not applicable. */
	public var status:Int;
	/** Whether the error occurred during a redirect. */
	public var redirected:Bool;

	/**
	 * @param message Description of the Error
	 * @param url The URL associated with the failed request.
	 * @param status HTTP status code. Defaults to `-1`.
	 * @param redirected Whether this error occurred mid-redirect. Defaults to `false`.
	 */
	public function new(message:String, url:String, ?status:Int = -1, ?redirected:Bool = false)
	{
		this.message = message;
		this.url = url;
		this.status = status;
		this.redirected = redirected;
	}

	/**
	 * Returns a formatted string representation of the error.
	 * The format should look like this: `[HttpError] | Status: N | (Redirected) | URL: ... | Message: ...`
	 * @return An error summary in a string
	 */
	public function toString():String
	{
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
