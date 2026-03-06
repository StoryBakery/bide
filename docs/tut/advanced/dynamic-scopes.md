---
title: Dynamic Scopes
---

Dynamic scopes are stable child scopes that appear and disappear in response to
signal updates.

## Recreating show()

A minimal `show()` can be modeled with `memo()` and `untrack()`.

```luau
local function show(toggle: () -> unknown, component: () -> Instance)
    return memo(function()
        return if toggle() then untrack(component) else nil
    end)
end
```

`untrack()` keeps the component's internal signal reads from being tracked by the
outer `memo()`. That way the branch only depends on `toggle()`.

## Recreating switch()

```luau
local function switch(key)
    return function(map)
        return memo(function()
            local component = map[key()]
            return if component then untrack(component) else nil
        end)
    end
end
```

## Recreating indexes()

`indexes()` is more involved because multiple child scopes must stay alive across
updates.

```luau
local function indexes<I, VI, VO>(
    input: () -> { [I]: VI },
    transform: (value: () -> VI, index: I) -> VO
)
    local caches = {} :: {
        [I]: {
            destroy: () -> (),
            output: VO,
            previousInput: VI,
            setValue: (VI) -> VI,
        }?,
    }

    cleanup(function()
        for _, cache in caches do
            assert(cache).destroy()
        end
    end)

    return memo(function()
        local nextInput = input()

        for index, cache in caches do
            if nextInput[index] == nil then
                assert(cache).destroy()
                caches[index] = nil
            end
        end

        for index, value in nextInput do
            local cache = caches[index]

            if cache == nil then
                local currentValue, setValue = signal(value)

                local output, destroy = root(function(dispose)
                    return transform(currentValue, index), dispose
                end)

                caches[index] = {
                    destroy = destroy,
                    output = output,
                    previousInput = value,
                    setValue = setValue,
                }
            elseif cache.previousInput ~= value then
                cache.previousInput = value
                cache.setValue(value)
            end
        end

        local output = table.create(0)

        for _, cache in caches do
            output[#output + 1] = assert(cache).output
        end

        return output
    end)
end
```

The built-in helpers already handle delayed destruction and branch presence.
This section is mainly useful when you need a custom dynamic helper that does
not fit `show()`, `switch()`, `indexes()`, or `values()`.
