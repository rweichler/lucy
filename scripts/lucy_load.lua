local ffi = require 'ffi'

ffi.cdef[[
int getpid();
int access(const char *filename, int flags);
]]

local f= "/tmp/lucypid/"..ffi.C.getpid()..".lua"
--only attempt to open it if the file exists
if ffi.C.access(f, 0) ~= -1 then
    dofile(f)
end
