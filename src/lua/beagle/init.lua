local ffi = require 'ffi'
local objc = require 'objc'

local lib = ffi.load('objcbeagle')
ffi.cdef[[
id beagle_getInstancesOfClass(Class aClass);
id beagle_getInstancesOfExactClass(Class aClass);
id beagle_getFirstInstanceOfClass(Class aClass);
]]

local beagle = {}

function beagle.beagle(class)
    local arr = lib.beagle_getInstancesOfClass(objc.class(class))
    return arr and objc.tolua(arr)
end

function beagle.exact(class)
    local arr = lib.beagle_getInstancesOfExactClass(objc.class(class))
    return arr and objc.tolua(arr)
end

function beagle.first(class)
    local arr = lib.beagle_getFirstInstanceOfClass(objc.class(class))
    return arr and objc.tolua(arr)
end

return setmetatable({}, {__index = beagle, __call = function(self, ...) return beagle.beagle(...) end})
