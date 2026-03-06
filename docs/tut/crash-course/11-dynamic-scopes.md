---
title: Dynamic Scopes
---

Dynamic helpers create and destroy child stable scopes from signal updates.

## show()

`show()` renders a branch while its input is truthy.

```luau
local function Button(props: {
    Text: string,
    Activated: () -> (),
})
    return create "TextButton" {
        Text = props.Text,
        Activated = props.Activated,
    }
end

local function Menu()
    return create "TextLabel" {
        Text = "This is a menu",
    }
end

local function App()
    local toggled, setToggled = signal(false)

    return create "ScreenGui" {
        Button({
            Text = "Toggle Menu",
            Activated = function()
                setToggled(not toggled())
            end,
        }),

        show(toggled, function()
            return Menu()
        end),
    }
end
```

## indexes()

`indexes()` keys child scopes by index.

```luau
local function Todo(props: {
    text: () -> string,
    position: number,
    onActivated: () -> (),
})
    return create "TextButton" {
        Text = function()
            return `{props.position}: {props.text()}`
        end,
        LayoutOrder = props.position,
        Activated = props.onActivated,
    }
end

local function TodoList(props: {
    list: () -> { string },
    setList: ({ string }) -> { string },
})
    return create "Frame" {
        create "UIListLayout" {},

        indexes(props.list, function(text, index)
            return Todo({
                text = text,
                position = index,
                onActivated = function()
                    local nextList = table.clone(props.list())
                    table.remove(nextList, index)
                    props.setList(nextList)
                end,
            })
        end),
    }
end
```

When you update a table-backed signal, set a new table reference.

```luau
local list, setList = signal({ 1, 2 })

local nextList = table.clone(list())
table.insert(nextList, 3)
setList(nextList)
```

## Delayed destruction

`show()`, `switch()`, `indexes()`, and `values()` can keep a branch alive for a
while after `present()` becomes `false`.

```luau
local toggled, setToggled = signal(true)

create "ScreenGui" {
    show(toggled, function(_, present)
        return create "Frame" {
            BackgroundTransparency = function()
                return if present() then 0 else 1
            end,
        }, 0.3
    end),
}

setToggled(false)
```

The branch starts leaving immediately, but its scope is destroyed only after the
delay expires.
