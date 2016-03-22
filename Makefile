ISDKP=$(shell xcrun --sdk iphoneos --show-sdk-path)

link = $(wildcard lib/*.dylib)
lucy=liblucybootstrap.dylib
deb=lucy.deb

all: $(deb)

$(deb): $(lucy) scripts/*
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

$(lucy): bootstrap.m
	clang $^ $(link) -I/usr/local/include/luajit-2.0 -isysroot $(ISDKP) -mios-version-min=7.0 -arch arm64 -arch armv7 -dynamiclib -o $@ -framework Foundation -Ilib -I/usr/local/include

clean:
	rm -f $(lucy) $(deb)

install: $(deb)
ifndef IP
	$(error IP not defined)
else
	scp $(deb) $(IP):.
	ssh $(IP) "dpkg -i $(deb) && rm $(deb)"
endif
