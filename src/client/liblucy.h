#include <CoreFoundation/CoreFoundation.h>
#if TARGET_OS_IPHONE
#define ROCKETBOOTSTRAP_LOAD_DYNAMIC
#include <LightMessaging/LightMessaging.h>

LMConnection * l_ipc_create_port(const char *name);
void l_ipc_free_port(LMConnection *connection);
bool l_ipc_send_data(LMConnection *connection, const char *cmd, char **result);
#endif
bool l_toggle_noncanonical_mode();
