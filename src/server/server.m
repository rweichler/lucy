#include "globals.h"

#if TARGET_OS_IPHONE
static void callback(CFMachPortRef port,
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

    bool success = true;
    const char *result;
    if(strcmp(data, "restart") == 0) {
        restart_lua();
        result = "Restarted Lua state";
    } else {
        success = run_lua_code(data, &result);
    }
    if(result == NULL) {
        LMSendReply(replyPort, NULL, 0);
        LMResponseBufferFree((LMResponseBuffer *)request);
        return;
    }
    char bytes[strlen("ERROR: ") + strlen(result) + 1];
    bytes[0] = 0;
    if(!success) {
        strcat(bytes, "ERROR: ");
    }
    strcat(bytes, result);

    unwind_lua_stack();

    LMSendReply(replyPort, bytes, strlen(bytes) + 1);
    LMResponseBufferFree((LMResponseBuffer *)request);
}
#endif

void server_start()
{
#if TARGET_OS_IPHONE
    LMStartService(LUCY_SERVER_NAME, CFRunLoopGetCurrent(), (CFMachPortCallBack)callback);
#endif
}
