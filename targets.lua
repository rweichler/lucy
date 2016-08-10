local deb = debber()
deb.packageinfo = {
    Version = '0.2.4',
    Depends = 'luajit, mobilesubstrate, com.rpetrich.rocketbootstrap',
    Package = 'com.r333d.lucy',
    Name = 'Lucy',
    Architecture = 'iphoneos-arm',
    Description = 'Lua Cycript',
    Maintainer = 'Reed Weichler <rweichler@gmail.com>',
    Author = 'Reed Weichler',
    Section = 'Development'
}
deb.input = 'layout'
deb.output = 'lucy.deb'

-- for my repo
function info()
    deb:print_packageinfo()
end


function default()
    -- setup builder
    local b = builder('apple')
    b.compiler = 'clang'
    b.sdk = 'iphoneos'
    b.build_dir = 'build'
    b.include_dirs = {
        'deps/include',
        'client',
        'server',
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
        'client/liblucy.c',
    }
    b.output = 'layout/usr/local/lib/liblucy.dylib'
    b:link(b:compile())
    -- copy client executable
    fs.mkdir("layout/usr/local/bin")
    os.pexecute("cp client/shell.lua layout/usr/local/bin/lucy")
    os.pexecute("chmod +x layout/usr/local/bin/lucy")

    -- compile server
    b.src = table.merge('client/liblucy.c', fs.scandir('server/*.m'))
    b.frameworks = {
        'Foundation'
    }
    b.output = 'layout/Library/MobileSubstrate/DynamicLibraries/LucyServer.dylib'
    b:link(b:compile())
    -- copy server plist
    os.pexecute("cp res/LucyServer.plist layout/Library/MobileSubstrate/DynamicLibraries/")


    deb:make_deb()
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
