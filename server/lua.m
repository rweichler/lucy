#include "globals.h"

static lua_State *L = NULL;
const char *run_lua_code(const char *code, bool *err)
{
    if(L == NULL) {
        return "Lua isn't running\nUse the `restart` command to restart it.";
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

    lua_pushcfunction(L, l_remote);
    lua_setglobal(L, "remote");
}
