---
name: option
description: Use when working with nu-monas Option type — constructing Some/None, transforming optional values, chaining operations that might return nothing, extracting with defaults. Triggers on "Option", "Some", "None", "when-not", "nullable", "might be absent", "optional value", or when writing code that handles potentially missing values in Nushell pipelines.
---

# Option — Safe Null Handling

Option wraps a value that might not exist. `Some(x)` holds a value, `None` represents absence.

```nushell
use nu-monas/option
```

> **Import note:** If you also use Result in the same script, use qualified imports (`option map`, `result map`) — glob-importing both (`use ... *`) causes shadowing (13 shared names).

## When to Use

- A field might not exist in a record
- A lookup might return nothing
- A parse might not match
- You want a default for missing values

## Construct

| Command | Does | Example |
|---|---|---|
| `some` | Wrap a value | `42 \| option some` → `Some(42)` |
| `none` | Represent absence | `option none` → `None` |
| `when-not` | Wrap unless equal to "empty" | `$val \| option when-not null` |
| `attempt` | Try operation, None on failure | `option attempt { "42" \| into int }` |

**`when-not` + `unwrap-or` form a round-trip identity:**
```nushell
$value | option when-not null | option unwrap-or null    # returns $value
$value | option when-not "" | option unwrap-or ""        # returns $value
```

## Transform

| Command | Does | Example |
|---|---|---|
| `map` | Transform inner value | `42 \| option some \| option map { $in * 2 }` → `Some(84)` |
| `and-then` | Chain (closure returns Option) | `\| option and-then { try { into int \| option some } catch { option none } }` |
| `keep-if` | Filter by predicate | `42 \| option some \| option keep-if { $in > 0 }` → `Some(42)` |
| `or-else` | Fallback Option | `option none \| option or-else { 0 \| option some }` → `Some(0)` |

**`map` vs `and-then`:**
- `map` — your closure returns a plain value (gets wrapped automatically)
- `and-then` — your closure returns an Option (no double-wrapping)

## Extract

| Command | Does | Example |
|---|---|---|
| `unwrap` | Get value or crash | `42 \| option some \| option unwrap` → `42` |
| `unwrap-or` | Get value or default | `option none \| option unwrap-or 0` → `0` |
| `expect` | Get value or crash with message | `\| option expect "ID required"` |
| `is-some` | Test presence | `42 \| option some \| option is-some` → `true` |
| `is-none` | Test absence | `option none \| option is-none` → `true` |

## Combine

| Command | Does | Example |
|---|---|---|
| `sequence` | `[Option] → Option[list]` (all or nothing) | `[1, 2] \| each { option some } \| option sequence` |
| `traverse` | Map then sequence | `[1, 2] \| option traverse { $in * 2 \| option some }` |
| `map2` | Lift binary function | `option map2 {\|a, b\| $a + $b } (1 \| option some) (2 \| option some)` |

## Recipes

### Safe field access
```nushell
$record.email? | option when-not null | option map { str trim } | option unwrap-or "no-email"
```

### Parse with fallback
```nushell
option attempt { $input | into int } | option unwrap-or 0
```

### Chain lookups
```nushell
$config | option when-not null
  | option and-then {|c| $c.database? | option when-not null }
  | option and-then {|db| $db.port? | option when-not null }
  | option unwrap-or 5432
```

### All-or-nothing batch
```nushell
$rows | option traverse {|row|
    $row.id? | option when-not null | option map { into int }
} | option unwrap-or []
```
