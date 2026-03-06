---
title: Scopes
---

The reactive runtime is built around stable scopes and reactive scopes.

## Scope rules

- Stable scopes do not rerun.
- Reactive scopes rerun when tracked signals update.
- Child scopes are owned by the scope that created them.
- Destroying a scope destroys everything created inside it.

`root()` creates a stable scope. `effect()` and `memo()` create reactive scopes.

## root()

`root()` is the usual entry point.

```luau
local count, setCount = signal(0)

local destroy = root(function(dispose)
    effect(function()
        print(count())
    end)

    return dispose
end)

setCount(1)
setCount(2)

destroy()
setCount(3) -- nothing reruns
```

This matters for cleanup. Effects often close over UI instances, connections,
or other resources. Destroying the parent scope releases those children as one
unit.
