#include "globals.h"

// pilfered from the Lua source
static int traceback (lua_State *L) {
  if (!lua_isstring(L, 1))  /* 'message' not a string? */
    return 1;  /* keep it intact */
  lua_getfield(L, LUA_GLOBALSINDEX, "debug");
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return 1;
  }
  lua_getfield(L, -1, "traceback");
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 2);
    return 1;
  }
  lua_pushvalue(L, 1);  /* pass error message */
  lua_pushinteger(L, 2);  /* skip this function and traceback */
  lua_call(L, 2, 1);  /* call debug.traceback */
  return 1;

}

static lua_State *L = NULL;
bool run_lua_code(const char *code, const char **result)
{
    if(L == NULL) {
        return "Lua isn't running\nUse the `restart` command to restart it.";
    }

    lua_pushcfunction(L, traceback);

    bool success;
    success = luaL_loadstring(L, code) == 0;

    if(!success) {
        *result = lua_tostring(L, -1);
        return false;
    }

    success = lua_pcall(L, 0, 1, -2) == 0;

    lua_getglobal(L, "tostring");
    lua_pushvalue(L, -2);

    lua_pcall(L, 1, 1, 0);
    *result = lua_tostring(L, -1);

    return success;
}

void unwind_lua_stack()
{
    lua_pop(L, lua_gettop(L));
}

void restart_lua()
{
    if(L != NULL) {
        lua_close(L);
    }
    L = luaL_newstate();
    luaL_openlibs(L);
}
