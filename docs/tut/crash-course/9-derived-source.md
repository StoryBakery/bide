---
title: Memoized Derivations
---

A plain function can derive from signals, but it recalculates on every read.

## Plain derivation

```luau
local count, setCount = signal(0)

local text = function()
    print("ran")
    return `count: {count()}`
end

print(text())
print(text())
setCount(1)
print(text())
```

## memo()

Use `memo()` when a derived value will be read multiple times between updates.

```luau
local count, setCount = signal(0)

root(function()
    local text = memo(function()
        print("ran")
        return `count: {count()}`
    end)

    effect(function()
        text()
    end)

    effect(function()
        text()
    end)

    setCount(1)
end)
```

The memo callback reruns once for the update, and all readers reuse the cached
result.

## When to prefer memo()

Use a plain function when recomputation is trivial and only read in one place.
Use `memo()` when:

- multiple effects read the same derived value,
- the derivation is expensive,
- or you want downstream updates to respect memo equality checks.
