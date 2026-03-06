---
title: Strict Mode
---

Strict mode enables additional safety checks for the reactive runtime.

## Enable strict mode

```luau
reactive.strict = true
```

Strict mode is disabled by default.

## Current checks

1. Detects yields inside stable or reactive scopes.
2. Rejects duplicate values passed to `values()`.
3. Rejects duplicate nested properties at the same depth.
4. Rejects destroying an active scope.
5. Produces more helpful effect stack traces.

Strict mode is mainly a development tool. It spends extra work on validation and
error reporting, so enable it while iterating and disable it if you need the
lowest possible overhead in production paths.
