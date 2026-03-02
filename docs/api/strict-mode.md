# Strict Mode

Strict mode is library-wide and can get set by doing:

```luau
vide.strict = true
```

By default, strict mode is disabled.

Strict mode is designed to help the development process by adding safety checks
and identifying improper usage.

Currently, strict mode will:

1. Throw an error if yields occur where they are not allowed.
1. Check for `values()` input having duplicate values.
1. Check for duplicate nested properties at same depth.
1. Check for destruction of an active scope.
1. Emit better error reporting and stack traces.

Accidental yielding within reactive scopes can break Vide's reactive graph,
which strict mode will catch.

As well as additional safety checks, Vide will dedicate extra resources to
recording and better emitting stack traces where errors occur, particularly
when implicit effects are created for instance property updating.

It is recommended to develop UI with strict mode enabled, and disable it in
performance-sensitive production paths if needed.
