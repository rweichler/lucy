local packageinfo = {
    Version = '0.2.1',
    Depends = 'luajit, mobilesubstrate, com.rpetrich.rocketbootstrap',
    Package = 'com.r333d.lucy',
    Name = 'Lucy',
    Architecture = 'iphoneos-arm',
    Description = 'Lua Cycript',
    Maintainer = 'Reed Weichler <rweichler@gmail.com>',
    Author = 'Reed Weichler',
    Section = 'Development'
}
local debfile = 'lucy.deb'

-- for my repo
function info()
    for k,v in pairs(packageinfo) do
        print(k..': '..v)
    end
    local md5sum = string.split(os.capture('md5sum "'..debfile..'"'), ' ')[1]
    print('MD5sum: '..md5sum)
    local f = io.open(debfile)
    local size = f:seek("end")
    io.close(f)
    print('Size: '..size)
    print('Filename: ./debs/'..debfile)
end


function default()
    -- setup builder
    local b = builder('apple')
    b.compiler = 'clang'
    b.sdk = 'iphoneos'
    b.include_dirs = {
        'outside_code/include'
    }
    b.frameworks = {
        'CoreFoundation'
    }
    b.archs = {
        'armv7',
        'arm64'
    }
    b.library_dirs = {
        'outside_code/lib'
    }
    b.libraries = {
        'substrate',
        'rocketbootstrap',
        'luajit-5.1.2'
    }

    -- compile client lib
    b.src_folder = 'client'
    b.src = {
        'lucy.c'
    }
    b.build_folder = 'build/client'
    b.output = 'layout/usr/local/lib/liblucy.dylib'
    b:link(b:compile())
    -- copy client executable
    fs.mkdir("layout/usr/local/bin")
    os.pexecute("cp client/lucy.lua layout/usr/local/bin/lucy")
    os.pexecute("chmod +x layout/usr/local/bin/lucy")

    -- compile server
    b.src_folder = 'server'
    b.src = {
        'tweak.m'
    }
    b.build_folder = 'build/server'
    b.output = 'layout/Library/MobileSubstrate/DynamicLibraries/LucyServer.dylib'
    b:link(b:compile())
    -- copy server plist
    os.pexecute("cp res/LucyServer.plist layout/Library/MobileSubstrate/DynamicLibraries/")

    local d = debber()
    d.input = 'layout'
    d.output = debfile
    d.packageinfo = packageinfo
    d:make_deb()
end

function clean()
    os.pexecute("rm -rf build layout")
    os.pexecute("rm -f lucy.deb")
end

function install(ip)
    ip = ip or 'iphone'
    os.pexecute('scp lucy.deb '..ip..':')
    os.pexecute('ssh '..ip..' "dpkg -i lucy.deb && rm lucy.deb"')
end
