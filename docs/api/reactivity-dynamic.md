---
title: Reactivity Dynamic
---

Dynamic helpers create and destroy stable sub-scopes in response to signal
updates.

## show()

Shows a component while the input accessor is truthy.

- Type

  ```luau
  type SignalAccessor<T> = () -> T
  type ShowComponent<TInput, TObject> = (
      SignalAccessor<TInput>,
      SignalAccessor<boolean>
  ) -> (TObject, ...number)
  type ShowFallback<TObject> = (SignalAccessor<boolean>) -> (TObject, ...number)

  function show<TInput, TObject>(
      input: SignalAccessor<TInput?>,
      component: ShowComponent<TInput, TObject>,
      fallback: ShowFallback<TObject>?
  ): SignalAccessor<TObject | { TObject } | nil>
  ```

- Details

  - `show()` keeps the last truthy input value available to the component.
  - The second accessor, usually named `present`, flips to `false` immediately
    when the branch starts leaving.
  - Returning a number after the object delays scope destruction.

## switch()

Chooses one branch from a mapping table.

- Type

  ```luau
  type SwitchComponent<TObject> = (SignalAccessor<boolean>) -> (TObject, ...number)

  function switch<K, TObject>(
      input: SignalAccessor<K>
  ): (map: { [K]: SwitchComponent<TObject> }) -> SignalAccessor<TObject | { TObject } | nil>
  ```

- Details

  - Only the currently selected branch stays present.
  - Returning a delay keeps the previous branch alive until the timer expires.

## indexes()

Creates one stable sub-scope per input index.

- Type

  ```luau
  function indexes<K, V, TObject>(
      input: SignalAccessor<{ [K]: V }>,
      component: (SignalAccessor<V>, K, SignalAccessor<boolean>) -> (TObject, ...number)
  ): SignalAccessor<{ TObject }>
  ```

- Details

  - A component is reused while the same index remains present.
  - The first callback argument is a signal accessor for that index's current value.
  - The third callback argument is the branch `present` accessor.

## values()

Creates one stable sub-scope per input value.

- Type

  ```luau
  function values<K, V, TObject>(
      input: SignalAccessor<{ [K]: V }>,
      component: (V, SignalAccessor<K>, SignalAccessor<boolean>) -> (TObject, ...number)
  ): SignalAccessor<{ TObject }>
  ```

- Details

  - A component is reused while the same value object remains present.
  - The second callback argument is a signal accessor for that value's current index.
  - Duplicate values are unsafe and should be avoided. `reactive.strict = true`
    throws for this case.

## Choosing indexes() or values()

- Use `indexes()` when index identity matters or the collection contains
  primitive values.
- Use `values()` when object identity matters and items may be reordered.
- In both cases, set a new table reference when mutating the collection.
