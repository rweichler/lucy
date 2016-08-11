#import <Foundation/Foundation.h>
#define ROCKETBOOTSTRAP_LOAD_DYNAMIC
#import <LightMessaging.h>
#import <substrate.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define LUCY_SERVER_NAME "com.r333d.lucy.default"
#define APPS_IPC_SERVER_NAME "com.r333d.lucy.apps.ipc.server"
#define Log(format, ...) NSLog(@"Lucy: %@", [NSString stringWithFormat: format, ## __VA_ARGS__])

void springboard_start_server();
const char *run_lua_code(const char *code, bool *err);
void restart_lua();
void apps_create_listener();

int l_remote(lua_State *L);
