#include "globals.h"

char _code[BUFSIZ];
char _response[BUFSIZ];

static LMConnection _lucy_connection = {
    MACH_PORT_NULL,
    LUCY_SERVER_NAME
};

static LMConnection _apps_ipc_connection = {
    MACH_PORT_NULL,
    APPS_IPC_SERVER_NAME
};

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

static void lucy_callback(CFMachPortRef port,
                                   LMMessage *request,
                                   CFIndex size,
                                   void *info)
{
    mach_port_t replyPort = request->head.msgh_remote_port;
    if(size < sizeof(LMMessage)) {
        LMSendReply(replyPort, NULL, 0);
        LMResponseBufferFree((LMResponseBuffer *)request);
        return;
    }

    const char *data = LMMessageGetData(request);

    bool err = false;
    const char *result;
    if(strcmp(data, "restart") == 0) {
        restart_lua();
        result = "Restarted Lua state";
    } else {
        result = run_lua_code(data, &err);
    }
    if(result == NULL) {
        LMSendReply(replyPort, NULL, 0);
        LMResponseBufferFree((LMResponseBuffer *)request);
        return;
    }
    char bytes[strlen("ERROR: ") + strlen(result) + 1];
    bytes[0] = 0;
    if(err) {
        strcat(bytes, "ERROR: ");
    }
    strcat(bytes, result);
    LMSendReply(replyPort, bytes, strlen(bytes) + 1);
    LMResponseBufferFree((LMResponseBuffer *)request);
}

static void apps_ipc_callback(CFMachPortRef port,
                                   LMMessage *request,
                                   CFIndex size,
                                   void *info)
{
    mach_port_t replyPort = request->head.msgh_remote_port;
    if(size < sizeof(LMMessage)) {
        LMSendReply(replyPort, NULL, 0);
        LMResponseBufferFree((LMResponseBuffer *)request);
        return;
    }

    const char *data = LMMessageGetData(request);
    if(strcmp(data, "request") == 0) {
        Log(@"got request %p", CFRunLoopGetCurrent());
        LMSendReply(replyPort, _code, strlen(_code) + 1);
    } else {
        Log(@"got response %p", CFRunLoopGetCurrent());
        strcpy(_response, data);
        LMSendReply(replyPort, NULL, 0);
    }
    LMResponseBufferFree((LMResponseBuffer *)request);
}

void springboard_start_server()
{
    LMStartService(_lucy_connection.serverName, CFRunLoopGetCurrent(), (CFMachPortCallBack)lucy_callback);
    LMStartService(_apps_ipc_connection.serverName, CFRunLoopGetCurrent(), (CFMachPortCallBack)apps_ipc_callback);
}
