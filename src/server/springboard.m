#include "globals.h"

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

void springboard_start_server()
{
    LMStartService(LUCY_SERVER_NAME, CFRunLoopGetCurrent(), (CFMachPortCallBack)callback);
}
