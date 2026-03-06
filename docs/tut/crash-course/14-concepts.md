---
title: Concepts Summary
---

A short summary of the reactive concepts used throughout the crash course.

## Signal

A signal is a pair of functions:

- an accessor that reads the current value,
- and a setter that writes the next value.

## Derived Value

A derived value is computed from one or more signals.

- Use a plain function for cheap one-off reads.
- Use `memo()` when the derived result should be cached.

## Effect

An effect is a reactive scope that reruns when its tracked signal reads change.

## Stable Scope

Stable scopes do not rerun.

They are created by APIs such as:

- `root()`,
- `show()`,
- `switch()`,
- `indexes()`,
- `values()`,
- `Provider()` from `createContext()`.

## Reactive Scope

Reactive scopes do rerun.

They are created by:

- `effect()`,
- `memo()`.

Reactive scopes own any child scopes created during their evaluation.

## Scope Cleanup

When a scope reruns or is destroyed:

- child scopes created inside it are destroyed,
- queued cleanup callbacks run,
- and tracked dependencies are rebuilt on the next evaluation.

## Reactive Graph

Signals, stable scopes, and reactive scopes form a graph.

```luau
local count, setCount = signal(0)

root(function()
    local text = memo(function()
        return `count: {count()}`
    end)

    effect(function()
        print(text())
    end)
end)
```

A `count` update reruns `text`, then reruns the `effect` that depends on it.
