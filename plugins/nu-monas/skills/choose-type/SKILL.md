---
name: choose-type
description: Use when deciding which nu-monas type to use — Option vs Result vs Validation. Helps choose based on the problem shape (nullable value, fallible operation, multi-check accumulation). Triggers on "which type", "Option or Result", "should I use Validation", or when the user is unsure which monadic wrapper fits their use case.
---

# Choosing a nu-monas Type

Pick the type that matches the **shape of your problem**, not the shape of your data.

## Decision Table

| You have... | You want... | Use |
|---|---|---|
| A value that might be absent | Safe access without null checks | **Option** |
| An operation that might fail | Error propagation with short-circuit | **Result** |
| Multiple checks on the same data | All errors at once, not just the first | **Validation** |

## Quick Signals

**Option** — the word "might" applies to *existence*:
- "this field might not exist"
- "the lookup might return nothing"
- "parse might not match"

```nushell
use nu-monas/option

$record.name? | option when-not null | option map { str trim } | option unwrap-or "anonymous"
```

**Result** — the word "might" applies to *failure*:
- "this operation might throw"
- "division might fail"
- "the file might not open"

```nushell
use nu-monas/result

$path | result safely { open $in | from json }
  | result and-then-safely { get "config" }
  | result unwrap-or {}
```

**Validation** — you need a *report*, not a short-circuit:
- "check all fields before rejecting"
- "accumulate every issue"
- "validate then show a summary"

```nushell
use nu-monas/validation

$record
| validation success "Starting validation"
| validation check {|r| if "name" in ($r | columns) { $r | validation success "Has name" } else { $r | validation failure "Missing name" }}
| validation check {|r| if "age" in ($r | columns) { $r | validation success "Has age" } else { $r | validation failure "Missing age" }}
| validation collect
```

## Key Differences

| | Option | Result | Validation |
|---|---|---|---|
| Short-circuits? | Yes (on None) | Yes (on Err) | **Never** |
| Error info? | No (just absent) | Yes (preserves error) | Yes (accumulates messages) |
| Chainable? | `and-then`, `map` | `and-then`, `map` | `check` (applicative) |
| Extract | `unwrap-or` | `unwrap-or` | `collect` |

## Conversions

When you start with one type and need another:

```nushell
use nu-monas/monad

# Option → Result
$opt | monad option-to-result "value was missing"

# Result → Option (discards error info)
$res | monad result-to-option
```

## Anti-patterns

- Don't use Option when you need to know *why* something failed → use Result
- Don't use Result when you want *all* errors, not just the first → use Validation
- Don't use Validation for a single pass/fail check → use Result with `ensure`
