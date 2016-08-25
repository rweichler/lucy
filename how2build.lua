--[[

How to build this:

Go to http://github.com/rweichler/aite and install that. I promise it's easy.
Come back here, and run the `aite` command.

--]]

local deb = debber()
deb.packageinfo = {
    Version = '0.5',
    Depends = 'luajit, mobilesubstrate, com.rpetrich.rocketbootstrap',
    Conflicts = 'com.luapower.objc, objcbeagle',
    Package = 'com.r333d.lucy',
    Name = 'Lucy',
    Architecture = 'iphoneos-arm',
    Description = 'Lua Cycript',
    Maintainer = 'Reed Weichler <rweichler@gmail.com>',
    Author = 'Reed Weichler',
    Section = 'Development',
    Depiction = 'http://github.com/rweichler/lucy',
}
deb.input = 'layout'
deb.output = 'lucy.deb'

-- for my repo
function info()
    deb:print_packageinfo()
end

function default()
    jb()
end

function jb()
    os.pexecute("rm -rf layout")

    -- compile objective beagle lib
    beagle()

    -- setup builder
    local b = builder('apple')
    b.compiler = 'clang'
    b.sdk = 'iphoneos'
    b.build_dir = 'build'
    b.include_dirs = {
        'deps/include',
        'src/client',
        'src/server',
    }
    b.frameworks = {
        'CoreFoundation',
    }
    b.archs = {
        'armv7',
        'arm64',
    }
    b.library_dirs = {
        'deps/lib',
    }
    b.libraries = {
        'luajit-5.1.2',
    }

    -- compile client lib
    b.src = {
        'src/client/liblucy.c',
    }
    b.output = 'build/liblucy.dylib'
    b:link(b:compile())
    fs.mkdir('layout/usr/local/lib')
    os.pexecute('cp build/liblucy.dylib layout/usr/local/lib/')
    -- copy client executable
    fs.mkdir("layout/usr/local/bin")
    local lpath = '/usr/local/share/lua/5.1'
    fs.mkdir("layout"..lpath)
    os.pexecute("    cp -r src/lua/* layout"..lpath)
    os.pexecute("    chmod +x layout"..lpath.."/lucy/init.lua")
    os.pexecute("    ln -s "..lpath.."/lucy/init.lua layout/usr/local/bin/lucy")

    -- compile server
    b.src = table.merge('src/client/liblucy.c', fs.scandir('src/server/*.m'))
    b.frameworks = {
        'Foundation'
    }
    b.output = 'build/LucyServer.dylib'
    fs.mkdir('layout/Library/MobileSubstrate/DynamicLibraries')
    os.pexecute('cp build/LucyServer.dylib layout/Library/MobileSubstrate/DynamicLibraries/')
    b:link(b:compile())
    -- copy server plist
    os.pexecute("    cp res/LucyServer.plist layout/Library/MobileSubstrate/DynamicLibraries/")


    deb:make_deb()
end

function beagle()
    local b = builder('apple')
    b.compiler = 'clang'
    b.src = fs.scandir('src/beagle/*.m')
    b.sdk = 'iphoneos'
    b.archs = {
        'armv7',
        'arm64',
    }
    b.include_dirs = { -- this fucks it up
        'src/lib',
    }
    b.frameworks = {
        'Foundation',
    }
    b.build_dir = 'build'
    b.output = 'build/libobjcbeagle.dylib'
    b:link(b:compile())
    fs.mkdir(deb.input..'/usr/local/lib')
    os.pexecute('cp '..b.output..' '..deb.input..'/usr/local/lib')
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
