# Lucy

![](screen.png)

# Building

### Requirements

* Mac OS X
* LuaJIT (`brew install luajit`)
* LEOS (this is already in the repository)

### The command you need to run

```
git submodule update --init
make
```


# Shit you can do

## IPC

So I have shitty IPC coded in. Just do this:

```lua
remote("com.facebook.Messenger", "x = 3; return x")
```

To execute code on a non-SpringBoard process.

To get the result, you do:

```lua
return response()
```

This should be synchronous. But I'm tired rn. I'll figure it out eventually.

I want it to be like this eventually:

```lua
CURRENT_APP = "com.facebook.Messenger"
-- do whatever
CURRENT_APP = nil
-- back in SpringBoard
```

It's a WIP.
