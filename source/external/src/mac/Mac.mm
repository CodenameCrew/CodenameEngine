#include <unordered_map>

#import <Cocoa/Cocoa.h>
#import "CursorHelper.h"

#define ARROW 0
#define CROSSHAIR 1
#define CLICK 2
#define IBEAM 3
#define MOVE 4
#define HAND 5
#define DRAG 6
#define DRAG_OPEN 7
#define WAIT 8
#define WAIT_ARROW 9
#define DISABLED 10
#define RESIZE_TR 11
#define RESIZE_BL 12
#define RESIZE_TL 13
#define RESIZE_BR 14
#define RESIZE_H 15
#define RESIZE_V 16
#define RESIZE_T 17
#define RESIZE_B 18
#define RESIZE_L 19
#define RESIZE_R 20
#define RESIZE_TLBR 21
#define RESIZE_TRBL 22
#define CUSTOM -1

namespace ExternalMac
{
	std::unordered_map<const char *, NSCursor *> customCursorCache;

	bool setCursorIcon(int icon, const char *customCursor, float customX, float customY)
	{
		NSCursor *cursor = nil;

		switch (icon)
		{
			case ARROW:
				cursor = [NSCursor arrowCursor];
				break;
			case CLICK:
				cursor = [NSCursor pointingHandCursor];
				break;
			case CROSSHAIR:
				cursor = [NSCursor crosshairCursor];
				break;
			case HAND:
				cursor = [NSCursor closedHandCursor];
				break;
			case IBEAM:
				cursor = [NSCursor IBeamCursor];
				break;
			case RESIZE_H:
				cursor = [NSCursor resizeLeftRightCursor];
				break;
			case RESIZE_V:
				cursor = [NSCursor resizeUpDownCursor];
				break;
			// TODO: DEFAULTS
			case RESIZE_TL:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeNorthWestCursor)defaultCursor:nil];
				break;
			case RESIZE_TR:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeNorthEastCursor)defaultCursor:nil];
				break;
			case RESIZE_BL:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeSouthWestCursor)defaultCursor:nil];
				break;
			case RESIZE_BR:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeSouthEastCursor)defaultCursor:nil];
				break;
			case RESIZE_T:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeNorthCursor)defaultCursor:nil];
				break;
			case RESIZE_B:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeSouthCursor)defaultCursor:nil];
				break;
			case RESIZE_L:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeWestCursor)defaultCursor:nil];
				break;
			case RESIZE_R:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeEastCursor)defaultCursor:nil];
				break;
			case RESIZE_TLBR:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeNorthWestSouthEastCursor)defaultCursor:nil];
				break;
			case RESIZE_TRBL:
				cursor = [CursorHelper getCursorForSelector:@selector(_windowResizeNorthEastSouthWestCursor)defaultCursor:nil];
				break;
			case WAIT:
				cursor = [CursorHelper getCursorForSelector:@selector(_waitCursor)defaultCursor:nil];
				break;
			case WAIT_ARROW:
				cursor = [CursorHelper getCursorForSelector:@selector(_waitCursor)defaultCursor:nil];
				break;
			case DISABLED:
				cursor = [NSCursor operationNotAllowedCursor];
				break;
			case DRAG:
				cursor = [NSCursor closedHandCursor];
				break;
			case DRAG_OPEN:
				cursor = [NSCursor openHandCursor];
				break;
			case CUSTOM:
				if (customCursorCache.find(customCursor) != customCursorCache.end())
					cursor = customCursorCache[customCursor];
				else
				{
					NSString *cursorImageName = [NSString stringWithUTF8String:customCursor];
					NSImage *tmpImage = [[NSImage alloc] initWithContentsOfFile:cursorImageName];

					if (tmpImage != nil)
					{
						cursor = [[NSCursor alloc] initWithImage:tmpImage hotSpot:NSMakePoint(customX, customY)];
						customCursorCache[customCursor] = cursor;
						[tmpImage release];
					}
					else
						NSLog(@"Failed to load image %@", cursorImageName);

					[cursorImageName release];
				}

				break;
		}

		if (cursor != nil)
		{
			[cursor set];

			return true;
		}

		return false;
	}
}
