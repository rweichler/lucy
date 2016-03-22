#!/usr/bin/env luajit

local ffi = require 'ffi'
local objc = require 'objc'
ffi.cdef [[
int getpid();
void * CFNotificationCenterGetDarwinNotifyCenter();
void CFNotificationCenterPostNotification(void *r, id str, void *lol, void *wut, bool istrue);
]]

if not arg[1] then
    print("need the process name")
end

if not arg[2] then
    print("need the lua file")
else
    assert(loadfile(arg[2]))
end



if not arg[1] or not arg[2] then
    return
end


local function find_process(name)
    local f = assert(io.popen("ps aux", "r"))
    local ps = assert(f:read('*a'))
    f:close()

    local current_pid = ffi.C.getpid()..""
    local pid = nil

    for s in string.gmatch(ps, "[^\n]+") do
        if string.match(s, name) then
            local i = 0
            for s in string.gmatch(s, "%S+") do
                i = i + 1
                if i == 2 and s ~= current_pid then
                    if pid == nil then
                        pid = s
                    else
                        print("too many pids, make your search more specific")

                        return
                    end
                end
            end
        end
    end

    return pid
end

local pid = find_process(arg[1])
if not pid then
    print("couldnt find process '"..arg[1].."' using ps")
    return
end
local dir = "/tmp/lucypid"
local dest = dir.."/"..pid..".lua"

if
    os.execute("rm -rf "..dir) ~= 0
    or
    os.execute("mkdir -p "..dir) ~= 0
    or
    os.execute("cp "..arg[2].." "..dest) ~= 0
    or
    os.execute("cynject "..pid.." /usr/local/lib/liblucybootstrap.dylib") ~= 0
then
    os.execute("rm -f "..dest)
    return
end



os.execute("chmod 777 "..dest)
local str = objc.NSString("LUA_LOAD_FILE_PLZ")
local r = ffi.C.CFNotificationCenterGetDarwinNotifyCenter()
ffi.C.CFNotificationCenterPostNotification(r, str, nil, nil, true)

objc.release(str)

print("loaded script '"..arg[2].."' into "..pid)
