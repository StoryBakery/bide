---
title: Cleanup
---

`cleanup()` registers work to run when the current scope reruns or is destroyed.

## Basic cleanup

```luau
local count, setCount = signal(0)

local destroy = root(function(dispose)
    effect(function()
        local current = count()

        cleanup(function()
            print(current)
        end)
    end)

    cleanup(function()
        print("root destroyed")
    end)

    return dispose
end)

setCount(1) -- prints 0
setCount(2) -- prints 1
destroy() -- prints 2, then "root destroyed"
```

## Common use

Use `cleanup()` for resources that need an explicit release step, such as:

- event connections,
- delayed threads,
- custom objects with `Destroy()` or `Disconnect()`,
- side-effects that need teardown between reruns.
