#ifndef MAC_H
#define MAC_H

#if defined(__APPLE__)

namespace ExternalMac
{
	bool setCursorIcon(int icon, const char *customCursor, float customX, float customY);
}

#endif

#endif
