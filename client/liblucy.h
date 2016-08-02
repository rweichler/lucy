#include <CoreFoundation/CoreFoundation.h>
#include "rocketbootstrap.h"

CFMessagePortRef l_ipc_create_port(const char *name);
bool l_ipc_send_data(CFMessagePortRef port, const char *cmd, char **result);
bool l_toggle_noncanonical_mode();
