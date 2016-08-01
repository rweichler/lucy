#include "lucy.h"

CFMessagePortRef l_ipc_create_port(const char *name)
{
    CFStringRef str = CFStringCreateWithCString(NULL, name, kCFStringEncodingUTF8);
    CFMessagePortRef remotePort = rocketbootstrap_cfmessageportcreateremote(nil, str);
    CFRelease(str);
    return remotePort;
}

typedef UInt8 byte_t;
bool l_ipc_send_data(CFMessagePortRef port, const char *cmd, char **result)
{
    size_t cmd_len = strlen(cmd);
    CFDataRef data = CFDataCreate(NULL, (const byte_t *)cmd, cmd_len + 1);
    SInt32 messageID = 0x1111; // Arbitrary
    CFTimeInterval timeout = 10.0;

    CFDataRef returnData = NULL;
    SInt32 status = CFMessagePortSendRequest(
        port,
        messageID,
        data,
        timeout,
        timeout,
        (result != NULL ? kCFRunLoopDefaultMode : NULL),
        &returnData
    );
    CFRelease(data);

    if(status != kCFMessagePortSuccess) return false;
    
    if (returnData != NULL) {
        if(result != NULL) {
            CFIndex len = CFDataGetLength(returnData);
            *result = malloc(len * sizeof(byte_t));
            CFDataGetBytes(returnData, CFRangeMake(0, len), (byte_t *)(*result));
        }
        CFRelease(returnData);
    } else if(result != NULL) {
        *result = NULL;
    }

    return true;
}

#include <termios.h>
#define STDIN_FD 0
// non-canonical mode
// i have no clue what this does,
// i just copy pasted it from somewhere
static struct termios SavedTermAttributes;
static bool non_canonical_enabled = false;
bool l_toggle_noncanonical_mode()
{
    int fd = STDIN_FD;
    struct termios *savedattributes = &SavedTermAttributes;

    // Make sure stdin is a terminal. 
    if(!isatty(fd)){
        return false;
    }

    if(non_canonical_enabled) {
        tcsetattr(STDIN_FILENO, TCSANOW, savedattributes);
        non_canonical_enabled = false;
        return false;
    }

    struct termios TermAttributes;
    char *name;

    // Save the terminal attributes so we can restore them later. 
    tcgetattr(fd, savedattributes);

    // Set the funny terminal modes. 
    tcgetattr (fd, &TermAttributes);
    TermAttributes.c_lflag &= ~(ICANON | ECHO); // Clear ICANON and ECHO. 
    TermAttributes.c_cc[VMIN] = 1;
    TermAttributes.c_cc[VTIME] = 0;
    tcsetattr(fd, TCSAFLUSH, &TermAttributes);
    non_canonical_enabled = true;
    return true;
}


