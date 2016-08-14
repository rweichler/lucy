local ffi = require 'ffi'
local lucy = ffi.load("lucy")
ffi.cdef[[
bool l_toggle_noncanonical_mode();
]]

local self = {}

function self.toggle()
    self.enabled = lucy.l_toggle_noncanonical_mode()
    return self.enabled
end

return self
