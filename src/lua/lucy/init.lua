#!/usr/bin/env luajit

ARGS = arg

local KEY = require 'lucy.key'
local ipc = require 'lucy.ipc'
if ipc == true then ipc = nil end
require 'lucy.func'
local noncanon = require 'lucy.noncanon'
local ffi = require 'ffi'
ffi.cdef[[
int read(int handle, void *buffer, int nbyte);
int write(int handle, const char *buffer, int nbyte);
bool isprint(int c);
]]

function main_loop()
    local count = ffi.C.read(STDIN_FD, buffer, 3)
    if count == 0 then return end

    if buffer[0] ~= 27 then
        PRINT_BUFFER(count)
    end

    if count == 1 or buffer[0] == 27 then
        local c = buffer[count - 1]
        local f = KEY[count] and KEY[count][c]
        if f then f() end
    end
end

RUN_CODE = ipc or RUN_CODE_LOCALLY

STDIN_FD = 0
STDOUT_FD = 1
STDRERR_FD = 2

if noncanon.toggle() then 
    if RUN_CODE == RUN_CODE_LOCALLY then
        -- tell user that we are not hooked into
        -- a process, since a lot of first-time users
        -- probably will just type "lucy", expecting to be
        -- hooked into SpringBoard or something
        MAGENTA_PRINT("Running local shell. Not hooking anything.\n")
    end
    -- start the REPL.
    buffer = ffi.new("char[3]")
    history = {}
    PROMPT(false)
    while true do
        main_loop()
    end
else
    -- if we couldn't start noncanon mode,
    -- this usually means we're piping.
    -- in that case, just read from the pipe
    -- and process it all, no pretty shell
    -- or REPL needed.
    local code = io.input():read("*all")
    code = string.sub(code, 1, #code - 1)
    local output = RUN_CODE(code)
    if output then
        print(output)
    end
end
