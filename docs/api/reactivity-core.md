---
title: Reactivity Core
---

Core reactive primitives: scopes, signals, effects, and memoized accessors.

## Scopes

Reactive code runs in one of two scopes.

- Stable scopes never rerun.
- Reactive scopes rerun when tracked signals update.
- Child scopes are owned by the scope that created them.
- Destroying a scope also destroys all scopes created within it.

Yielding is not allowed inside stable or reactive scopes. `reactive.strict = true`
adds stricter checks and better stack traces for these failures.

## root()

Runs a function in a new stable scope.

- Type

  ```luau
  function root<T...>(fn: (destroy: () -> ()) -> T...): T...
  ```

- Details

  - `root()` is the entry point for creating a top-level stable scope.
  - The callback receives `destroy()`, which disposes that scope manually.
  - `root()` returns the callback return values.

## signal()

Creates a signal accessor and setter pair.

- Type

  ```luau
  function signal<T>(
      initialValue: T,
      options: {
          equals: boolean | ((T, T) -> boolean)?,
      }?
  ): (() -> T, (T | ((T) -> T)) -> T)
  ```

- Details

  - The accessor reads the current value and participates in dependency tracking.
  - The setter updates the value and notifies dependents when the equality check fails.
  - Table mutation must still produce a new table reference if you want updates to
    propagate.

- Example

  ```luau
  local count, setCount = signal(0)

  print(count()) -- 0
  setCount(count() + 1)
  print(count()) -- 1
  ```

## effect()

Creates a reactive scope that reruns when tracked signals change.

- Type

  ```luau
  function effect(callback: () -> ())
  ```

- Details

  - `effect()` must be called from an existing scope.
  - Any signal accessor read during the callback becomes a dependency.
  - Use `untrack()` for reads that should not become dependencies.

- Example

  ```luau
  local count, setCount = signal(0)

  root(function()
      effect(function()
          print(`count: {count()}`)
      end)

      setCount(1)
  end)
  ```

## memo()

Caches a derived value inside a reactive scope.

- Type

  ```luau
  function memo<T>(
      callback: (previous: T?) -> T,
      initialValue: T?,
      options: {
          equals: boolean | ((T, T) -> boolean)?,
      }?
  ): () -> T
  ```

- Details

  - `memo()` must be created from an existing scope.
  - The callback receives the previous derived value.
  - Repeated reads return the cached result until dependencies change.
  - `options.equals` controls whether downstream updates should propagate.

- Example

  ```luau
  local count, setCount = signal(0)

  root(function()
      local label = memo(function()
          return `count: {count()}`
      end)

      print(label()) -- count: 0
      setCount(1)
      print(label()) -- count: 1
  end)
  ```
