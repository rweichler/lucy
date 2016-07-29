#import <Foundation/Foundation.h>
#import <substrate.h>
#include <rocketbootstrap.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

static lua_State *L = NULL;
const char *run_lua_code(const char *code, bool *err)
{
    if(L == NULL) {
        return "Lua isn't running in SpringBoard you retard\nUse the `restart` command to restart it.";
    }

    bool success;
    success = luaL_loadstring(L, code) == 0;

    if(!success) {
        if(err != NULL) {
            *err = !success;
        }
        return lua_tostring(L, -1);
    }

    success = lua_pcall(L, 0, 1, 0) == 0;


    if(err != NULL) {
        *err = !success;
    }

    if(lua_isnil(L, -1)) {
        return NULL;
    }

    lua_getglobal(L, "tostring");
    lua_pushvalue(L, -2);

    lua_pcall(L, 1, 1, 0);
    return lua_tostring(L, -1);
}

void restart_lua()
{
    if(L != NULL) {
        lua_close(L);
    }
    L = luaL_newstate();
    luaL_openlibs(L);
}

static CFDataRef Callback(CFMessagePortRef port,
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
        result = "Restarted Lua state.";
    }else {
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


void create_port()
{
    CFMessagePortRef localPort = CFMessagePortCreateLocal(nil,
                                 CFSTR("com.r333d.lucy.console.server"),
                                 Callback,
                                 nil,
                                 nil);
    rocketbootstrap_cfmessageportexposelocal(localPort);
    CFRunLoopSourceRef runLoopSource = CFMessagePortCreateRunLoopSource(nil, localPort, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       runLoopSource,
                       kCFRunLoopCommonModes);

}

MSInitialize {
    create_port();
    restart_lua();
}
