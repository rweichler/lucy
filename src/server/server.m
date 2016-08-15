#include "globals.h"

#if TARGET_OS_IPHONE
static void callback(LMServiceRef service, LMMessage *request)
{
    mach_port_t replyPort = LMMessageGetReplyPort(request);

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
    LMService service = {
        LUCY_SERVER_NAME,
        CFRunLoopGetCurrent(),
        NULL
    };
    LMStartService(&service, callback);
#endif
}
