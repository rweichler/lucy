local ffi = require 'ffi'

ffi.cdef[[
void *dlopen(const char *filename, int flag);
void * dlsym(void * handle, const char *symbol);
]]

local lib = ffi.C.dlopen("librect.dylib", 1)
local dlsym = function(symbol)
    return ffi.C.dlsym(lib, symbol)
end

local get_width = dlsym("get_width")

get_width = ffi.cast([[
float (*)(
    struct {
        struct {
            float a;
            float a;
        } a;
        struct {
            float a;
            float a;
        } a;
    } a

)
]], get_width)

--[[
]]

local width = get_width({{2, 3}, {4, 6}})

print(width)
