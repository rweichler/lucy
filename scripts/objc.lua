#!/usr/bin/env luajit

local ffi = require 'ffi'
local R = {}

local function framework(name)
    return ffi.load("/System/Library/Frameworks/"..name..".framework/"..name, true)
end
framework("Foundation")
--framework("UIKit")
--framework("UIKit")
ffi.cdef [[
typedef void * Method;
typedef void * id;
typedef void * Class;
typedef void * SEL;

Class objc_getClass(const char *name);
SEL sel_getUid(const char *name);
id objc_msgSend(id self, SEL _cmd, ...);

Method class_getClassMethod(Class class, SEL _cmd);
Method class_getInstanceMethod(Class class, SEL _cmd);
bool class_isMetaClass(Class class);

Class object_getClass(id self);

const char * method_getTypeEncoding(Method m);
void NSLog(id fmt);
]]


local function get_method(self, cmd)
    local class = ffi.C.object_getClass(self)
    local f = nil
    if ffi.C.class_isMetaClass(class) then
        f = ffi.C.class_getClassMethod
    else
        f = ffi.C.class_getInstanceMethod
    end
    return f(class, cmd)
end

local SEL = function(name)
    return ffi.C.sel_getUid(name)
end
local function C(name)
    return ffi.C.objc_getClass(name)
end

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local reg = function(str)
    result = ""
    split = string.split(str, ",")
    local first = true
    for i, s in ipairs(split) do
        if first then
            first = false
            result = s.." (*)("
        else
            result = result..s..","
        end
    end
    return string.sub(result, 1, #result- 1)..")"
end

local msg = function(fptr, ...)
    local lol = reg(fptr)
    local f = ffi.cast(lol, ffi.C.objc_msgSend)
    return f(...)
end


local function first_char_uppercase(str)
    local first_char = string.sub(str, 1, 1)
    return string.upper(first_char) == first_char
end

local reg = "id (*)(id, SEL)"

--[[
local UIView = C("UIView")
local view = msg("id (*)(id, SEL)", UIView, SEL("alloc"))
view = msg("id (*)(id, SEL)", view, SEL("init"))
local method = get_method(view, SEL("setFrame:"))
local str = ffi.C.method_getTypeEncoding(method)
print(ffi.string(str))

local NSBundle = C("NSBundle")
local bundle = msg("id,id,id", NSBundle, SEL("mainBundle"))
local identifier = msg("id,id,id", bundle, SEL("bundleIdentifier"))

local fmt = msg("id,id,id", C("NSString"), SEL("alloc"))
fmt = msg("id,id,id, const char *", fmt, SEL("initWithUTF8String:"), "%@")

ffi.C.NSLog(fmt, identifier)
local str = msg("const char *,id,id", identifier, SEL("UTF8String"))
]]

R.NSString = function(s)
    local str = msg("id,id,id", C("NSString"), SEL("alloc"))
    return msg("id,id,id, const char *", str, SEL("initWithUTF8String:"), s)
end

R.release = function(self)
    msg("void,id,id", self, SEL("release"))
end

R.call = function(self, cmd)
    return msg("id,id,id", self, SEL(cmd))
end

R.msg = msg
R.class = C
R.SEL = SEL
R.log = function(fmt)
    ffi.C.NSLog(R.NSString(fmt))
end
return R
