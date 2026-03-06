---
title: Creating UI
---

Instances are created with `create()`.

## Basic shape

```luau
local bide = require("bide")

local create = bide.Instance.create

return create "ScreenGui" {
    create "Frame" {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.4, 0.7),

        create "TextLabel" {
            Text = "hi",
        },

        create "TextLabel" {
            Text = "bye",
        },

        create "TextButton" {
            Text = "click me",

            Activated = function()
                print("clicked!")
            end,
        },
    },
}
```

## Property channels

- String keys set properties or events.
- Function values on non-event properties create implicit reactive bindings.
- Number keys append children or nested child accessors.
- `Attach` is reserved for node-level attachments.
