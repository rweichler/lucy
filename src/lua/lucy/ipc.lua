local ffi = require 'ffi'
local success, lucy = pcall(function() return ffi.load("lucy") end)
if not success then return end

ffi.cdef[[
void free(void *);
void *l_ipc_create_port(const char *name);
bool l_ipc_send_data(void *port, const char *cmd, char **result);
]]

if not pcall(function() return lucy.l_ipc_create_port end) then return end

local port_name = ARGS[1]
if not port_name then return end

port_name = 'com.r333d.lucy.'..port_name

local success, port = pcall(function() return lucy.l_ipc_create_port(port_name) end)
if not success then return end

local string_ptr_type = ffi.typeof("char *[1]")
return function(code)
    local result = ffi.new(string_ptr_type)
    local success = lucy.l_ipc_send_data(port, code, result)
    if not success then
        print("*** Connection has been reset")
        EXIT(1)
    end
    result = result[0]
    if not (result == ffi.NULL) then
        local str = ffi.string(result)
        ffi.C.free(result)
        return str
    end
end
