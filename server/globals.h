#import <Foundation/Foundation.h>
#import <rocketbootstrap.h>
#import <substrate.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define LUCY_SERVER_NAME "com.r333d.lucy.console.server"
#define APPS_IPC_SERVER_NAME "com.r333d.lucy.apps.ipc.server"

void springboard_start_server();
const char *run_lua_code(const char *code, bool *err);
void restart_lua();
void apps_create_listener();

int l_remote(lua_State *L);
int l_response(lua_State *L);
