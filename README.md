# Lucy

Lua Cycript

![](screen.png)

## Why???

Because it's (mostly) written in Lua! It's way less code than Cycript. And thus way easier to maintain.

## That example is really ugly. I don't want to do raw runtime calls.

I know. But that's because I haven't added Objective-C bindings yet. But it's *definitely* doable. Just look at [Wax](https://github.com/alibaba/wax).

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
