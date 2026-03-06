---
title: Signals
---

Signals store reactive state as an accessor and setter pair.

## Create a signal

```luau
local count, setCount = signal(0)
```

The first value reads the signal. The second value updates it.

```luau
print(count()) -- 0
setCount(count() + 1)
print(count()) -- 1
```

## Derive plain values

A plain function can derive a value from one or more signals.

```luau
local count, setCount = signal(0)

local text = function()
    return `count: {count()}`
end

print(text()) -- count: 0
setCount(1)
print(text()) -- count: 1
```

This is enough for one-off derived reads. When the same derived value will be
read many times, use `memo()` instead.
