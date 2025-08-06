#import <Foundation/Foundation.h>

@interface CursorHelper : NSObject

+ (NSCursor *)getCursorForSelector:(SEL)selector defaultCursor:(NSCursor *)defaultCursor;

@end