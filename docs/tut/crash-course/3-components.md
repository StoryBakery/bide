---
title: Components
---

Break UI into small reusable functions.

## Component shape

A component is a function that receives props and returns UI.

::: code-group

```luau [Button.luau]
local bide = require("bide")

local create = bide.Instance.create

local function Button(props: {
    Position: UDim2,
    Text: string,
    Activated: () -> (),
})
    return create "TextButton" {
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(200, 150),

        Position = props.Position,
        Text = props.Text,
        Activated = props.Activated,

        create "UICorner" {},
    }
end

return Button
```

```luau [Menu.luau]
local Button = require("./Button")
local bide = require("bide")

local create = bide.Instance.create

local function Menu()
    return create "ScreenGui" {
        Button({
            Position = UDim2.fromOffset(200, 200),
            Text = "back",
            Activated = function()
                print("go to previous page")
            end,
        }),

        Button({
            Position = UDim2.fromOffset(400, 200),
            Text = "next",
            Activated = function()
                print("go to next page")
            end,
        }),
    }
end
```

:::

Use a single `props` table so components stay easy to compose and extend.
