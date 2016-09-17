# Lucy

![](screen.png)

This injects a LuaJIT interpreter into SpringBoard which can be controlled using the `lucy` command.

You can also edit `res/LucyServer.plist` to make it inject wherever you want.

# Goals

* Painless ~~Objective-C integration~~ 
  * [Achieved with objc.lua](http://github.com/rweichler/objc.lua) (still a bit painful, though)
  * TODO:
    * Implicit typecasting
    * Fix C struct support
* ~~`choose()` function~~ [Achieved with Objective Beagle](http://github.com/rweichler/beagle.lua)
  * e.g. `beagle('UIWindow')`
* Inject into any process

# Installation

Add http://cydia.r333d.com as a Cydia repo, and install the Lucy package from there.

# Building

### Requirements

* Mac OS X
* LuaJIT (`brew install luajit`)

### The commands you need to run

1: Clone [aite](https://github.com/rweichler/aite) and put it somewhere

```
git clone https://github.com/rweichler/aite.git
```

2: Clone this and put it somewhere

```
git clone https://github.com/rweichler/lucy.git
```

3: cd into this repo and run aite

```
cd lucy
/PATH/TO/AITE/main.lua
```

That creates a new file `lucy.deb` which you can install on your device.

# Running

## Injecting into SpringBoard

Go into terminal, type the `lucy` command. Get Objective-C and Beagle by doing:

```lua
objc = require 'objc'
beagle = require 'beagle'
```

## Local shell

`lucy local`
