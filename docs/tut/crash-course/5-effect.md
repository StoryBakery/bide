---
title: Effects
---

Effects rerun when the signals they read update.

## Create an effect

`effect()` must be created inside a stable scope.

```luau
local count, setCount = signal(0)

root(function()
    effect(function()
        print(`count: {count()}`)
    end)

    setCount(1)
end)
```

Any signal accessor read inside the callback becomes a dependency.

## Track derived reads

Nested reads are tracked too.

```luau
local count, setCount = signal(1)

local doubled = function()
    return count() * 2
end

root(function()
    effect(function()
        print(`doubled count: {doubled()}`)
    end)

    setCount(2)
end)
```

## Skip tracking with untrack()

```luau
local a, setA = signal(0)
local b, setB = signal(0)

root(function()
    effect(function()
        print(`a: {a()} b: {untrack(b)}`)
    end)

    setA(1) -- reruns
    setB(1) -- does not rerun
    setA(2) -- reruns
end)
```
