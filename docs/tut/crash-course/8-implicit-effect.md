---
title: Implicit Effects
---

`create()` can build property effects for you when a non-event property value is
an accessor function.

## Implicit property binding

```luau
local function Counter()
    local count, setCount = signal(0)

    return create "TextButton" {
        Activated = function()
            setCount(count() + 1)
        end,

        Text = function()
            return `count: {count()}`
        end,
    }
end
```

This is equivalent to creating an explicit `effect()` that updates `Text`.

## Reactive children

Numeric child entries can also be accessor functions.

```luau
local items, setItems = signal({
    create "TextLabel" { Text = "A" },
})

local function List(props: {
    children: () -> { Instance },
})
    return create "Frame" {
        create "UIListLayout" {},
        props.children,
    }
end

local list = List({
    children = items,
})

setItems({
    create "TextLabel" { Text = "B" },
    create "TextLabel" { Text = "C" },
})
```

When the child accessor returns a different set of instances, `create()`
unparents removed children and parents the new ones automatically.
