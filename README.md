ALPHA SOFTWARE. Only tested on iOS 8.1.2 arm64.

Need Mac OS X to build this.

then run something like:

```
brew install luajit
make
```
then install it like so
```
scp lucy.deb iphone:.
ssh iphone "dpkg -i lucy.deb"
```

use one of the examples like this:

```
lucy SpringBoard print_bundle_to_syslog.lua
```
