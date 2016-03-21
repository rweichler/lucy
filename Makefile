ISDKP=$(shell xcrun --sdk iphoneos --show-sdk-path)

link = $(wildcard lib/*.dylib)
lucy=liblucybootstrap.dylib
deb=lucy.deb

all: $(deb)

$(deb): $(lucy)
	mkdir -p tmp
	cp -r deb_structure/* tmp/
	cp -r DEBIAN tmp/
	cp scripts/lucy.lua tmp/usr/local/bin/lucy
	cp scripts/objc.lua tmp/usr/local/share/lua/5.1/
	cp scripts/lucy_load.lua tmp/var/mobile/Library/Preferences/lua/
	cp $(lucy) tmp/usr/local/lib/
	dpkg-deb -Zgzip -b tmp
	mv tmp.deb $@
	rm -r tmp

$(lucy): main.m
	clang $^ $(link) -I/usr/local/include/luajit-2.0 -isysroot $(ISDKP) -mios-version-min=3.0 -arch arm64 -arch armv7 -dynamiclib -o $@ -framework Foundation -Ilib

clean:
	rm -f $(lucy) $(deb)
