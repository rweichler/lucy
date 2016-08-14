#include "liblucy.h"

#if TARGET_OS_IPHONE
LMConnection * l_ipc_create_port(const char *name)
{
    LMConnection *connection = malloc(sizeof(LMConnection));
    strcpy(connection->serverName, name);
    return connection;
}

void l_ipc_free_port(LMConnection *connection)
{
    free(connection);
}

typedef UInt8 byte_t;
bool l_ipc_send_data(LMConnection *connection, const char *cmd, char **result)
{
    LMResponseBuffer buffer;
    bool success = LMConnectionSendTwoWay(connection, 0x1111, cmd, cmd == NULL?0:(strlen(cmd) + 1), &buffer) == 0;
    if(!success) {
        return false;
    }
    LMMessage *response = &(buffer.message);
    
    if (response != NULL) {
        if(result != NULL) {
            const char *data = LMMessageGetData(response);
            if(data == NULL) {
                *result = NULL;
            } else {
                *result = malloc(sizeof(char) * (strlen(data) + 1));
                strcpy(*result, data);
            }
        }
    } else if(result != NULL) {
        *result = NULL;
    }

    return true;
}
#endif

#include <termios.h>
// this makes it an actual shell.
// it basically suppresses echoing
// and stuff like that.
static struct termios _defaultAttrs;
static bool non_canonical_enabled = false;
bool l_toggle_noncanonical_mode()
{
    int fd = STDIN_FILENO;

    // Make sure stdin is a terminal. 
    if(!isatty(fd)){
        return false;
    }

    if(non_canonical_enabled) {
        tcsetattr(fd, TCSANOW, &_defaultAttrs);
        non_canonical_enabled = false;
        return false;
    }

    struct termios attrs;

    // Save the terminal attributes so we can restore them later. 
    tcgetattr(fd, &_defaultAttrs);

    // Set the funny terminal modes. 
    tcgetattr (fd, &attrs);
    attrs.c_lflag &= ~(ICANON | ECHO); // Clear ICANON and ECHO. 
    attrs.c_cc[VMIN] = 1;
    attrs.c_cc[VTIME] = 0;
    tcsetattr(fd, TCSAFLUSH, &attrs);
    non_canonical_enabled = true;
    return true;
}


