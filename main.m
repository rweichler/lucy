#include <substrate.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <Foundation/Foundation.h>
#include <sys/types.h>
#include <unistd.h>

static inline void setSettingsNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    int lol = luaL_loadfile(L, "/var/mobile/Library/Preferences/lua/lucy_load.lua");
    lua_pushnumber(L, getpid());

    if(lol == LUA_ERRFILE) {
        NSLog(@"liblucy: couldnt open the fuckin file");
    } else {
        lol = lua_pcall(L, 1, LUA_MULTRET, 0);
        if(lol != 0) {
            NSLog(@"liblucy:errored");
            NSLog(@"liblucy: %s", lua_tostring(L, -1));
        }
    }
}


MSInitialize {
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, &setSettingsNotification, (CFStringRef)@"LUA_LOAD_FILE_PLZ", NULL, 0);
}
