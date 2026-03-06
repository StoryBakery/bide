---
title: Reactive Components
---

A reactive component combines signal state with UI creation.

## Local state inside a component

```luau
local function Counter()
    local count, setCount = signal(0)

    local instance = create "TextButton" {
        Activated = function()
            setCount(count() + 1)
        end,
    }

    effect(function()
        instance.Text = `count: {count()}`
    end)

    return instance
end
```

Each call to `Counter()` creates a new signal pair, so each instance keeps its
own state.

## Pass signal accessors through props

```luau
local function CountDisplay(props: {
    count: () -> number,
})
    local instance = create "TextLabel" {}

    effect(function()
        instance.Text = `count: {props.count()}`
    end)

    return instance
end
```

As long as the component is created inside a stable scope, local signals and
prop signals behave the same way.
