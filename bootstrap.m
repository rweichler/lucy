#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/NSObjCRuntime.h>

static inline void setSettingsNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    int status = luaL_dofile(L, "/var/mobile/Library/Preferences/lua/lucy_load.lua");

    if(status != 0) {
        NSLog(@"liblucy: ERROR OPENING BOOTSTRAP: %s", lua_tostring(L, -1));
    }
}

__attribute__((constructor))
void ayy_lmao() {
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, &setSettingsNotification, CFSTR("LUA_LOAD_FILE_PLZ"), NULL, 0);
}
