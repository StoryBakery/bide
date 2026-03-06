---
title: Strict Mode
---

Enable strict mode during development to catch invalid reactive usage early.

## Enable strict mode

```luau
reactive.strict = true
```

Strict mode is disabled by default.

## Why use it

Strict mode adds validation and clearer stack traces for:

- yields inside reactive code,
- duplicate values passed to `values()`,
- duplicate nested property writes,
- invalid scope destruction,
- and effect error traces.

Keep it on while iterating, then decide per production path whether the extra
checks are still worth the overhead.
