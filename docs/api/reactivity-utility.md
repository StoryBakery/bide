---
title: Reactivity Utility
---

Utility APIs that sit on top of the core reactive graph.

## cleanup()

Queues cleanup work for the current scope.

- Type

  ```luau
  function cleanup(value: (() -> ()) | thread | unknown)
  ```

- Details

  - Functions are queued directly.
  - Common cleanup objects such as connections, instances, and tables with
    `destroy`/`disconnect` style methods are also supported.
  - Cleanup callbacks run when the current reactive scope reruns or when the
    owning scope is destroyed.

- Example

  ```luau
  local count, setCount = signal(0)

  local destroy = root(function(dispose)
      effect(function()
          local current = count()

          cleanup(function()
              print(`cleaned: {current}`)
          end)
      end)

      return dispose
  end)

  setCount(1)
  setCount(2)
  destroy()
  ```

## untrack()

Reads signals without subscribing the current reactive scope.

- Type

  ```luau
  function untrack<T>(getter: () -> T): T
  ```

- Example

  ```luau
  local a, setA = signal(0)
  local b, setB = signal(0)

  root(function()
      local sum = memo(function()
          return a() + untrack(b)
      end)

      print(sum()) -- 0
      setB(1)
      print(sum()) -- 0
      setA(1)
      print(sum()) -- 2
  end)
  ```

## read()

Reads either a plain value or a signal accessor.

- Type

  ```luau
  function read<T>(value: T | (() -> T)): T
  ```

## batch()

Defers graph flushing until the callback finishes.

- Type

  ```luau
  function batch<T...>(callback: () -> T...): T...
  ```

- Example

  ```luau
  local a, setA = signal(0)
  local b, setB = signal(0)

  root(function()
      effect(function()
          print(a() + b())
      end)

      batch(function()
          setA(1)
          setB(2)
      end)
  end)
  ```

## createContext()

Creates a context object with a `Provider` and a default value.

- Type

  ```luau
  function createContext<T>(defaultValue: T?): Context<T?>

  type Context<T> = {
      id: any,
      defaultValue: T,
      Provider: <TReturn>(props: {
          value: T,
          children: any,
      }) -> TReturn,
  }
  ```

- Details

  - `Provider` creates a child stable scope.
  - `children` may be a plain value or a function.
  - If no provider exists, `useContext()` returns `defaultValue`.

## useContext()

Reads the nearest value from a context provider.

- Type

  ```luau
  function useContext<T>(context: Context<T>): T
  ```

- Example

  ```luau
  local Theme = createContext("light")

  root(function()
      Theme.Provider({
          value = "dark",
          children = function()
              print(useContext(Theme)) -- dark
          end,
      })
  end)
  ```
