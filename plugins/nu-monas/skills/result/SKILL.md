---
name: result
description: Use when working with nu-monas Result type — constructing Ok/Err, chaining fallible operations, error propagation, safe resource handling. Triggers on "Result", "Ok", "Err", "safely", "ensure", "and-then-safely", "error handling", "might fail", "try/catch alternative", or when writing code that handles operations that could throw in Nushell pipelines.
---

# Result — Safe Error Handling

Result wraps an operation that might fail. `Ok(x)` holds success, `Err(e)` holds a structured error with context.

```nushell
use nu-monas/result
```

> **Import note:** If you also use Option in the same script, use qualified imports (`result map`, `option map`) — glob-importing both (`use ... *`) causes shadowing (13 shared names).

## When to Use

- An operation might throw (division, parsing, file access)
- You want to chain steps that each might fail
- You need the error message, not just "absent"
- You want guaranteed resource cleanup on failure

## Construct

| Command | Does | Example |
|---|---|---|
| `ok` | Wrap success | `42 \| result ok` → `Ok(42)` |
| `err` | Wrap real error + context | `$error \| result err $input` |
| `safely` | Try operation, auto-wrap | `$val \| result safely { $in / 2 }` |
| `safely` (3-arg) | Try + catch + finally | `$val \| result safely { op } { on-err } { cleanup }` |
| `ensure` | Assert condition | `42 \| result ensure { $in > 0 }` → `Ok(42)` |

**`safely` is the primary constructor** — it replaces manual try/catch:
```nushell
# Before (manual)
try { $x | into int | result ok } catch {|e| $e | result err $x }

# After (safely)
$x | result safely { into int }

# With error transform and cleanup (3-arg form)
$x | result safely { into int } { update msg "parse failed" } { rm -f temp.lock }
```

## Transform

| Command | Does | Example |
|---|---|---|
| `map` | Transform Ok value | `42 \| result ok \| result map { $in * 2 }` → `Ok(84)` |
| `and-then` | Chain (closure returns Result) | `\| result and-then { result safely { into int } }` |
| `and-then-safely` | Chain with auto-wrap | `\| result and-then-safely { $in / 2 }` |
| `and-then-ensure` | Chain with assertion | `\| result and-then-ensure { $in > 0 } { "must be positive" }` |
| `map-err` | Transform error | `\| result map-err { update msg "wrapped" }` |
| `or-else` | Fallback Result | `\| result or-else { 0 \| result ok }` |

**`and-then` vs `and-then-safely`:**
- `and-then` — your closure returns a Result manually
- `and-then-safely` — your closure just does work, auto-wrapped in Ok/Err

## Extract

| Command | Does | Example |
|---|---|---|
| `unwrap` | Get value or panic (shows DON'T PANIC banner with context) | `42 \| result ok \| result unwrap` → `42` |
| `unwrap-or` | Get value or default | `\| result unwrap-or 0` |
| `unwrap-err` | Get error (for testing) | `\| result unwrap-err` |
| `expect` | Get value or panic with context | `\| result expect "config required"` |
| `is-ok` | Test success | `42 \| result ok \| result is-ok` → `true` |
| `is-err` | Test failure | `\| result is-err` |

## Combine

| Command | Does | Example |
|---|---|---|
| `sequence` | `[Result] → Result[list]` (first error wins) | `[1, 2] \| each { result ok } \| result sequence` |
| `traverse` | Map then sequence | `$items \| result traverse { result safely { validate } }` |
| `map2` | Lift binary function | `result map2 {\|a, b\| $a + $b } (1 \| result ok) (2 \| result ok)` |

## Resource Management

```nushell
$data | result with-resource
  { open-connection }        # create
  {|conn| $conn | close }    # cleanup (always runs)
  {|conn| $conn | query }    # body
```

## Recipes

### Pipeline of fallible steps
```nushell
$input
| result safely { from json }
| result and-then-safely { get "data" }
| result and-then-safely { into int }
| result unwrap-or 0
```

### Validate then proceed
```nushell
$age
| result ensure { $in >= 0 } "Age must be non-negative"
| result and-then-ensure { $in < 150 } { $"Age ($in) is unrealistic" }
| result unwrap
```

### Safely with cleanup
```nushell
$path | result safely { open $in } null { rm -f temp.lock }
| result and-then-safely { from csv }
| result unwrap-or []
```

### Error transformation
```nushell
$input | result safely { into int }
| result map-err { update msg $"Parse failed for input '($input)': ($in.msg)" }
| result unwrap
```
