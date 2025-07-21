//
//  NiceUtil-Bridging-Header.h
//  NiceUtil
//

#ifndef NiceUtil_Bridging_Header_h
#define NiceUtil_Bridging_Header_h

#import <Foundation/Foundation.h>

// Space management
int _CGSDefaultConnection(void);
id CGSCopyManagedDisplaySpaces(int conn);
id CGSCopyActiveMenuBarDisplayIdentifier(int conn);

// Window management
typedef uint32_t CGWindowID;
extern CFArrayRef CGWindowListCopyWindowInfo(uint32_t option, uint32_t relativeToWindow);
#define kCGWindowListOptionOnScreenOnly            (1 << 0)
#define kCGWindowListOptionAll                     (1 << 1)
#define kCGWindowListOptionOnScreenAboveWindow     (1 << 2)
#define kCGWindowListOptionOnScreenBelowWindow     (1 << 3)
#define kCGWindowListOptionIncludingWindow         (1 << 4)
#define kCGNullWindowID                           (0)

#endif /* NiceUtil_Bridging_Header_h */
