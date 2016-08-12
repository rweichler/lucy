#import <Foundation/Foundation.h>
#define ROCKETBOOTSTRAP_LOAD_DYNAMIC
#import <LightMessaging.h>
#import <substrate.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define LUCY_SERVER_NAME "com.r333d.lucy.default"
#define Log(format, ...) NSLog(@"Lucy: %@", [NSString stringWithFormat: format, ## __VA_ARGS__])

void server_start();
bool run_lua_code(const char *code, const char **result);
void unwind_lua_stack();
void restart_lua();
