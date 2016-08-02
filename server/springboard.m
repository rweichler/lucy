#include "globals.h"

char _code[BUFSIZ];
char _response[BUFSIZ];

int l_remote(lua_State *L)
{
    if(!lua_isstring(L, 1) || !lua_isstring(L, 2)) {
        return luaL_error(L, "expected 2 strings");
    }
    const char *app = lua_tostring(L, 1);
    const char *code = lua_tostring(L, 2);

    strcpy(_code, code);

    NSString *identifier = [NSString stringWithFormat:@"com.r333d.lucy.listener.%s", lua_tostring(L, 1)];
    Log(@"remote %p", CFRunLoopGetCurrent());

    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterPostNotification(r, (CFStringRef)identifier, NULL, nil, true);

    return 0;   
}

int l_response(lua_State *L)
{
    lua_pushstring(L, _response);
    return 1;
}

static CFDataRef lucy_callback(CFMessagePortRef port,
                          SInt32 messageID,
                          CFDataRef data,
                          void *info)
{
    CFIndex len = CFDataGetLength(data);
    char yee[len];
    CFDataGetBytes(data, CFRangeMake(0, len), (unsigned char*)yee);
    bool err = false;
    const char *result;
    if(strcmp(yee, "restart") == 0) {
        restart_lua();
        result = "Restarted Lua state";
    } else {
        result = run_lua_code(yee, &err);
    }
    if(result == NULL) {
        return NULL;
    }
    char bytes[strlen("ERROR: ") + strlen(result) + 1];
    bytes[0] = 0;
    if(err) {
        strcat(bytes, "ERROR: ");
    }
    strcat(bytes, result);
    return CFDataCreate(NULL, (const unsigned char *)bytes, strlen(bytes) + 1);
}

static CFDataRef apps_ipc_callback(CFMessagePortRef port,
                          SInt32 messageID,
                          CFDataRef data,
                          void *info)
{
    CFIndex len = CFDataGetLength(data);
    char yee[len];
    CFDataGetBytes(data, CFRangeMake(0, len), (unsigned char*)yee);
    if(strcmp(yee, "request") == 0) {
        Log(@"got request %p", CFRunLoopGetCurrent());
        return CFDataCreate(NULL, (const unsigned char *)_code, strlen(_code) + 1);
    } else {
        Log(@"got response %p", CFRunLoopGetCurrent());
        strcpy(_response, yee);
    }
    return NULL;
}

static void start_server(CFStringRef name, CFMessagePortCallBack callback)
{
    CFMessagePortRef localPort = CFMessagePortCreateLocal(nil,
                                 name,
                                 callback,
                                 nil,
                                 nil);
    rocketbootstrap_cfmessageportexposelocal(localPort);
    CFRunLoopSourceRef runLoopSource = CFMessagePortCreateRunLoopSource(nil, localPort, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       runLoopSource,
                       kCFRunLoopCommonModes);

}

void springboard_start_server()
{
    start_server(CFSTR(LUCY_SERVER_NAME), lucy_callback);
    start_server(CFSTR(APPS_IPC_SERVER_NAME), apps_ipc_callback);
}
