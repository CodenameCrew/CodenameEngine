#import <Cocoa/Cocoa.h>
#import "CursorHelper.h"

@implementation CursorHelper

+ (NSCursor *)getCursorForSelector:(SEL)selector defaultCursor:(NSCursor *)defaultCursor
{
	NSCursor *cursor = nil;

	if ([NSCursor respondsToSelector:selector])
	{
		cursor = [NSCursor performSelector:selector];
	}
	else
	{
		NSLog(@"CursorHelper: selector %@ not found", NSStringFromSelector(selector));
  
		cursor = defaultCursor;
	}

	return cursor;
}

@end
