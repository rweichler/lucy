#include "globals.h"

MSInitialize {
    @autoreleasepool {
        NSString *identifier = NSBundle.mainBundle.bundleIdentifier;
        if(identifier == nil) {
            return;
        }
        NSLog(@"Lucy: hooking %@", identifier);
        if([identifier isEqualToString:@"com.apple.springboard"]) {
            springboard_start_server();
            restart_lua();
        } else {
            apps_create_listener();
        }
    }
}
