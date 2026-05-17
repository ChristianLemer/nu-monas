---
name: monad
description: Use when converting between nu-monas types — Option to Result, Result to Option. Triggers on "convert Option to Result", "result-to-option", "option-to-result", "switch type", "discard error", "treat None as error", or when the user has one monadic type but needs the other.
---

# Monad — Type Conversions

Convert between Option and Result when the problem shape changes mid-pipeline.

```nushell
use nu-monas/monad
```

## When to Use

- You have an Option but now need error info → convert to Result
- You have a Result but only care about presence → convert to Option
- A function returns Option but your pipeline expects Result (or vice versa)

## Commands

| Command | Does | Example |
|---|---|---|
| `option-to-result` | `Some(x)` → `Ok(x)`, `None` → `Err(msg)` | `$opt \| monad option-to-result "missing"` |
| `result-to-option` | `Ok(x)` → `Some(x)`, `Err(_)` → `None` | `$res \| monad result-to-option` |

## Recipes

### Option → Result (add error context)
```nushell
use nu-monas/option
use nu-monas/monad

$record.id? | option when-not null
  | monad option-to-result "Record has no ID"
  # now in Result land — can chain with result and-then-safely, etc.
```

### Result → Option (discard error, keep presence)
```nushell
use nu-monas/result
use nu-monas/monad

$input | result safely { from json }
  | monad result-to-option
  # now in Option land — can chain with option map, option unwrap-or, etc.
```

### Mixing in a pipeline
```nushell
use nu-monas/option
use nu-monas/result
use nu-monas/monad

$record.config_path?
  | option when-not null                          # Option: might not have a path
  | monad option-to-result "no config path"       # Result: need error if missing
  | result and-then-safely { open $in | from json }  # Result: file might not parse
  | result unwrap-or {}
```

## Direction Guide

| You have | You need | Why | Command |
|---|---|---|---|
| Option | Result | Need to report *why* it's missing | `monad option-to-result "reason"` |
| Result | Option | Don't care about the error, just presence | `monad result-to-option` |
