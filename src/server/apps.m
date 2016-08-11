#include "globals.h"
#include "liblucy.h"

#define IDENTIFIER_BASE ([@"com.r333d.lucy.listener." stringByAppendingString:NSBundle.mainBundle.bundleIdentifier])

#define IDENTIFIER(x) ([IDENTIFIER_BASE stringByAppendingString:@x])

LMConnection *_port = NULL;
static inline void callback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSLog(@"Lucy: nsnotifaction recieved");
    if(_port == NULL) {
        NSLog(@"Lucy: creating port");
        _port = l_ipc_create_port(APPS_IPC_SERVER_NAME);
        restart_lua();
    }
    char *code;
    bool success;
    success = l_ipc_send_data(_port, "request", &code);
    if(!success) {
        NSLog(@"Lucy: fucked up");
        l_ipc_free_port(_port);
        _port = NULL;
        return;
    }

    bool err = false;
    const char *result = run_lua_code(code, &err);
    free(code);
    if(result == NULL) {
        result = "";
    }
    char bytes[strlen("ERROR: ") + strlen(result) + 1];
    bytes[0] = 0;
    if(err) {
        strcat(bytes, "ERROR: ");
    }
    strcat(bytes, result);

    success = l_ipc_send_data(_port, bytes, NULL);
    if(!success) {
        NSLog(@"Lucy: fucked up");
        l_ipc_free_port(_port);
        _port = NULL;
        return;
    }
}

void apps_create_listener()
{
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, &callback, (CFStringRef)IDENTIFIER_BASE, NULL, 0);
}
