---
title: Introduction
---

This crash course introduces the reactive runtime and UI creation model used by
bide.

bide's reactive layer is heavily inspired by [Solid](https://www.solidjs.com/).

## Why bide?

The library aims to keep UI code direct and data-oriented.

Some of the main design choices are:

- minimal syntax,
- explicit data flow,
- predictable scope lifetime,
- and compatibility with Luau typechecking.

The reactive model is built around scopes. That concept has a small learning
curve, but it is what keeps the API compact while still allowing cleanup,
derivation, and dynamic UI composition.
