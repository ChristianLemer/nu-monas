---
name: intro
description: Use when introducing nu-monas concepts — railway programming, why monadic wrappers matter, how pipelines and wrapped types fit together. Triggers on "what is nu-monas", "why not just try/catch", "railway programming", "explain monads", "why wrap values", "what's the point of Option/Result", or when onboarding someone unfamiliar with monadic pipeline composition.
---

# nu-monas — The Idea

## Setup

```nushell
# Per-script (const required — use resolves at parse-time)
const NU_LIB_DIRS = ["/path/to/nu-monas"]

# Or globally in env.nu
$env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | append "/path/to/nu-monas")
```

Then import by module — **do not glob-import multiple modules in the same scope** (Option and Result share 13 command names and will shadow each other):

```nushell
use nu-monas/option    # → option map, option unwrap-or, ...
use nu-monas/result    # → result safely, result and-then, ...
use nu-monas/validation  # → validation check, validation collect, ...
```

## The Problem

Nushell pipelines are beautiful when everything works:

```nushell
$data | get "users" | where age > 18 | sort-by name
```

But the real world introduces cracks:
- `get "users"` — what if the field doesn't exist?
- `where age > 18` — what if `age` is null in some rows?
- What if `$data` came from a file that didn't parse?

The usual fix: scatter `if`, `try/catch`, null checks everywhere. The pipeline breaks into fragments. The shape of the code stops reflecting the shape of the logic.

## The Railway

Imagine your pipeline as a railway track. There are two rails:

```
───── happy path ─────────────────────────────────►  value
───── problem track ──────────────────────────────►  nothing / error / issues
```

A **wrapped type** is a train car that knows which rail it's on. Operations that transform the value only fire on the happy path — if the car is on the problem track, it glides through untouched.

```nushell
use nu-monas/result

$input                                    # raw value
| result safely { from json }             # → Ok(data) or Err(parse error)
| result and-then-safely { get "id" }     # only runs if still Ok
| result and-then-safely { into int }     # only runs if still Ok
| result unwrap-or 0                      # exit the railway with a default
```

Three steps that might each fail, but zero `try/catch` nesting. The error track carries the failure through silently. At the end, you decide what to do.

## Three Kinds of Track

nu-monas gives you three wrappers because problems come in three shapes:

| Shape | Wrapper | Problem track |
|---|---|---|
| **Absence** — value might not exist | Option | `None` (no info, just absent) |
| **Failure** — operation might throw | Result | `Err(error)` (with message + context) |
| **Accumulation** — many checks, want all results | Validation | Messages pile up, never short-circuits |

## Why Not Just try/catch?

`try/catch` works, but it **breaks the pipeline**:

```nushell
# Fragmented — shape of code ≠ shape of logic
let parsed = try { $input | from json } catch { {} }
let id = try { $parsed | get "id" } catch { null }
let num = if $id != null { try { $id | into int } catch { 0 } } else { 0 }
```

```nushell
# Railway — shape preserved
use nu-monas/result
$input | result safely { from json } | result and-then-safely { get "id" } | result and-then-safely { into int } | result unwrap-or 0
```

Same logic, same safety. But the second version reads as one thought, because it *is* one thought.

## Why Not Just null checks?

Null checks spread virally. Every function that *might* receive null has to check. Every caller that *might* get null back has to check. The checks are repetitive and easy to forget.

Option makes the "might be absent" explicit in the type — operations on it are safe by construction, and you extract at the boundary where you decide the default.

## The Pattern

1. **Enter** — wrap your value at the boundary (`safely`, `when-not`, `pure`)
2. **Transform** — chain operations that stay on the happy path (`map`, `and-then`, `check`)
3. **Exit** — unwrap at the end with a decision (`unwrap-or`, `collect`, `expect`)

Wrap early. Unwrap late. Transform in between.

## Next Steps

Now pick your type: invoke the **choose-type** skill.
