
local objc = require 'objc'
local ffi = require 'ffi'

ffi.cdef[[
void MSHookMessageEx(Class class, SEL message, void *hook, void *old);
typedef void (*func_t)(id, SEL, id);
]]

local log = function(x)
    objc.log("liblucy: "..tostring(x))
end

local make_func = function(f)
    return ffi.new("void (*)(id, SEL, id)", f)
end

local old = ffi.new("func_t[1]")
local hook = nil

ffi.C.MSHookMessageEx(objc.class("SBRootFolderView"), objc.SEL("scrollViewDidScroll:"), make_func(function(self, _cmd, scrollView)
    hook(scrollView)
    old[0](self, _cmd, scrollView)
end), old)
log("hooked "..tostring(old))



ffi.cdef[[
typedef struct CATransform3D
{
  double m11, m12, m13, m14;
  double m21, m22, m23, m24;
  double m31, m32, m33, m34;
  double m41, m42, m43, m44;
} CATransform3D;
CATransform3D CATransform3DRotate ( CATransform3D t, double angle, double x, double y, double z );
]]

local identity = ffi.new("CATransform3D",
                    {   1, 0, 0, 0,
                        0, 1, 0, 0,
                        0, 0, 1, -.002,
                        0, 0, 0, 1
                    })

local genscrol = nil

function hook(self)
    local subviews = objc.call(self, "subviews")
    local count = objc.msg("int,id,id", subviews, objc.SEL("count"))
    for i=0,count-1 do
        local page = objc.msg("id,id,id,int", subviews, objc.SEL("objectAtIndex:"), i)
        genscrol(page, i, self)
    end
end

function genscrol(page, i, self)
    local layer = objc.call(page, "layer")

    local set_transform = function(t)
        objc.msg("void,id,id,CATransform3D", layer, objc.SEL("setTransform:"), t)
    end

    local contentOffset = objc.msg("struct {double x; double y;},id,id", self, objc.SEL("contentOffset"))
    local x = contentOffset.x

    x = x - i*320
    if math.abs(x) > 320 then
        set_transform(identity)
    else
        local percent = -x/320
        local angle = percent*math.pi/2
        local transform = ffi.C.CATransform3DRotate(identity, angle, 0, 1, 0)
        set_transform(transform)
    end

end
