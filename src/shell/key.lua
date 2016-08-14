-- functions for various
-- special keypresses

local KEY = {}
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
--ctrl-L
KEY[1][12] = function()
    local steps = #command + 1 - cursor_pos
    os.execute("clear")
    PRINT(prompt_text)
    PRINT(command)
    CURSOR_LEFT(steps)
end
--ctrl-A
KEY[1][1] = function()
    CURSOR_LEFT(cursor_pos - 1)
    cursor_pos = 1
end

--ctrl-E
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
void (*signal(int sig, void (*func)(int)))(int);
]]

-- ctrl-C
local SIGINT = 2
ffi.C.signal(SIGINT, function()
    CURSOR_RIGHT(#command + 1 - cursor_pos)
    PRINT("^C")
    history_idx = nil
    PROMPT()
end)

return KEY
