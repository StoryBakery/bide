# Strict Mode

While developing UI with Vide, you should use Vide's strict mode, which can
be set with `vide.strict = true` once when you first require Vide. Strict mode
will add extra safety checks and emit better error traces, particularly when
errors occur in property bindings.

By default, strict mode is disabled. You can turn it on once when Vide is
required.

```luau
vide.strict = true
```

A full list of what strict mode will do can be found
[here](../../api/strict-mode).
