#!/usr/bin/env luajit

local port_name = arg[1] or 'default'
REMOTE_PORT = port_name ~= 'local' and "com.r333d.lucy."..port_name

function main_loop()
    local count = C.read(STDIN_FD, buffer, 3)
    if count == 0 then return end

    if buffer[0] ~= 27 then
        PRINT_BUFFER(count)
    end

    if count == 1 or buffer[0] == 27 then
        local c = buffer[count - 1]
        local f = KEY[count][c]
        if f then f() end
    end
end

KEY = {}
KEY[1] = {}
KEY[2] = {}
KEY[3] = {}

--enter
KEY[1][0x0A] = function()
    PRINT("\n")
    run_command()
end
--ctrl-D
KEY[1][0x04] = function()
    if #command == 0 then
        PRINT("^D\n")
        EXIT()
    else
        BELL()
    end
end
--backspace
KEY[1][0x08] = function()
    if #command == 0 or cursor_pos == 1 then
        BELL()
    else
        local tail
        if cursor_pos == #command + 1 then
            command = string.sub(command, 1, #command - 1)
        else
            tail = string.sub(command, cursor_pos, #command)
            command = string.sub(command, 1, cursor_pos - 2)..tail
        end
        cursor_pos = cursor_pos - 1
        BACKSPACE(1)
        if tail then
            PRINT(tail..' ')
            CURSOR_LEFT(#tail + 1)
        end
    end
end
--delete
KEY[1][0x7f] = KEY[1][0x08]
--^L
KEY[1][12] = function()
    local steps = #command + 1 - cursor_pos
    --CURSOR_RIGHT(steps)
    C.system("clear")
    PRINT(prompt_text)
    PRINT(command)
    CURSOR_LEFT(steps)
end
--^A
KEY[1][1] = function()
    CURSOR_LEFT(cursor_pos - 1)
    cursor_pos = 1
end

--^E
KEY[1][5] = function()
    CURSOR_RIGHT(#command + 1 - cursor_pos)
    cursor_pos = #command + 1
end

--up arrow
KEY[3][0x41] = function()
    if not history_idx then
        history_idx = #history
    else
        history_idx = history_idx - 1
    end
    if history_idx < 1 then
        if #history == 0 then
            history_idx = nil
        else
            history_idx = 1
        end
        BELL()
        return
    end
    if command then
        CURSOR_RIGHT(#command + 1 - cursor_pos)
        cursor_pos = #command + 1
        BACKSPACE(#command)
    end
    command = history[history_idx]
    PRINT(command)
    cursor_pos = #command + 1
end

--down arrow
KEY[3][0x42] = function()
    if not history_idx then
        BELL()
        return
    end
    
    history_idx = history_idx + 1
    CURSOR_RIGHT(#command + 1 - cursor_pos)
    cursor_pos = #command + 1
    BACKSPACE(#command)
    if history_idx > #history then
        history_idx = nil
        command = ""
    else
        command = history[history_idx]
        PRINT(command)
    end
    cursor_pos = #command + 1
end

--right arrow
KEY[3][0x43] = function()
    cursor_pos = cursor_pos + 1
    if cursor_pos > #command + 1 then
        BELL()
        cursor_pos = #command + 1
    else
        CURSOR_RIGHT(1)
    end
end

--left arrow
KEY[3][0x44] = function()
    cursor_pos = cursor_pos - 1
    if cursor_pos < 1 then
        BELL()
        cursor_pos = 1
    else
        CURSOR_LEFT(1)
    end
end

local ffi = require 'ffi'
ffi.cdef[[
int read(int handle, void *buffer, int nbyte);
int write(int handle, const char *buffer, int nbyte);
void printf(const char *fmt, ...);
void (*signal(int sig, void (*func)(int)))(int);
bool isprint(int c);
void free(void *);
void system(const char *);
]]
local lucy = ffi.load("lucy")
ffi.cdef[[
void *l_ipc_create_port(const char *name);
bool l_ipc_send_data(void *port, const char *cmd, char **result);
bool l_toggle_noncanonical_mode();
]]
local ffi_string = ffi.string
C = ffi.C
local IPC_AVAILABLE = pcall(function() return lucy.l_ipc_create_port end)
if IPC_AVAILABLE and REMOTE_PORT then
    local port
    local function refresh_port()
        port = lucy.l_ipc_create_port(REMOTE_PORT)
    end
    refresh_port()
    local string_ptr = ffi.typeof("char *[1]")
    function SEND_DATA(cmd, should_recieve)
        local result = nil
        if not (should_recieve == false) then
            result = ffi.new(string_ptr)
        end
        local success = lucy.l_ipc_send_data(port, cmd, result) 
        if not success then
            print("*** Connection to SpringBoard has been reset")
            EXIT()
        end
        if result and not (result[0] == ffi.NULL) then
            local str = ffi_string(result[0])
            C.free(result[0])
            return str
        end
    end
else
    function SEND_DATA(cmd)
        local callback = function(message)
            return debug.traceback(message, 2)
        end
        local success, result = xpcall(load(cmd), callback)
        if not success then
            result = 'ERROR: '..result
        end
        return tostring(result)
    end
end

function EXIT(code)
    lucy.l_toggle_noncanonical_mode()
    os.exit(code or 0)
end


STDIN_FD = 0
STDOUT_FD = 1
STDRERR_FD = 2
SIGINT = 2

is_piping = not lucy.l_toggle_noncanonical_mode()
local orig_error = error
error = function(...)
    lucy.l_toggle_noncanonical_mode()
    orig_error(...)
end

if is_piping then -- just process the inputs, no pretty shell needed
    local code = io.input():read("*all")
    code = string.sub(code, 1, #code - 1)
    local output = SEND_DATA(code)
    if output then
        print(output)
    end
    return
end

function string.trim(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function run_command()
    if command == "exit" then
        EXIT()
    end
    local result
    if #string.trim(command) > 0 then
        result = SEND_DATA(command)
        local ret = 'return '
        if string.sub(command, 1, #ret) == ret and not result then
            result = 'nil'
        end
        if result then
            PRINT_RESULT(string.gsub(string.gsub(result, '\n\t', '\n    '), '\n', '\n      '))
        else
            result = nil
        end
        table.insert(history, command)
    end
    history_idx = nil
    PROMPT(result or false)
end


function PRINT_RESULT(result)
    local comp = "ERROR: "
    PRINT("      ")
    if string.sub(result, 1, #comp) == comp then
        RED_PRINT(result)
    else
        GREEN_PRINT(result)
    end
end

C.signal(SIGINT, function()
    CURSOR_RIGHT(#command + 1 - cursor_pos)
    PRINT("^C")
    history_idx = nil
    PROMPT()
end)

function PRINT(str)
    C.write(STDOUT_FD, str, #str)
end

function CURSOR_RIGHT(n)
    if n == 0 then return end
    PRINT("\x1B["..n.."C")
end

function CURSOR_LEFT(n)
    if n == 0 then return end
    PRINT("\x1B["..n.."D")
end

function MAGENTA_PRINT(str)
    PRINT("\x1B[1;34m")
    PRINT(str)
    PRINT("\x1B[0m")
end

function BACKSPACE(n)
    for i=1,n do
        PRINT("\b \b")
    end
end

function BELL()
    PRINT("\a")
end

function GREEN_PRINT(str)
    PRINT("\x1B[1;32m")
    PRINT(str)
    PRINT("\x1B[0m")
end

function RED_PRINT(str)
    PRINT("\x1B[1;31m")
    PRINT(str)
    PRINT("\x1B[0m")
end

prompt_text = "\x1B[1;31m".."l".."\x1B[33m".."u".."\x1B[32m".."c".."\x1B[34m".."y".."\x1B[35m".."#".."\x1B[0m "
function PROMPT(newline)
    if newline == nil then newline = true end

    command = ""
    if newline then
        PRINT('\n')
    end
    PRINT(prompt_text)
    cursor_pos = 1
end

function PRINT_BUFFER(count)
    for i=0,count-1 do
        local c = buffer[i]
        if C.isprint(c) then
            local s = string.char(c)
            if cursor_pos == #command + 1 then
                PRINT(s)
                command = command..s
            else
                local tail = s..string.sub(command, cursor_pos, #command)
                command = string.sub(command, 1, cursor_pos - 1)..tail
                PRINT(tail)
                CURSOR_LEFT(#tail - 1)
            end
            cursor_pos = cursor_pos + 1
        end
    end
end

buffer = ffi.new("char[3]")
history = {}
PROMPT(false)
while true do
    main_loop()
end
