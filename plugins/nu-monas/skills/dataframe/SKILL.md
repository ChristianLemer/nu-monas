---
name: dataframe
description: Use when working with nu-monas Option types in DataFrames — wrapping table cells as Options, unwrapping with defaults, Option-aware joins. Triggers on "DataFrame", "option df", "table with nulls", "join with Options", "wrap table cells", "null handling in tables", "df when-not", "df unwrap-or", "df join", or when processing tabular data that has nullable cells and needs monadic safety.
---

# DataFrame — Option-Aware Table Operations

Treat entire DataFrames as monadic structures: every cell becomes an Option, operations are null-safe by construction, joins preserve Option semantics.

```nushell
use nu-monas/option       # for option is-some, option map, etc.
use nu-monas/option/df    # for df when-not, df unwrap-or, df join
```

> **Namespace:** importing `nu-monas/option/df` gives you commands prefixed with `df` (not `option df`). Import both modules when you need per-cell Option operations alongside table-wide operations.

## When to Use

- Your table has nullable cells and you want safe transformations
- You're joining tables where keys or values might be null
- You want uniform null handling across all columns at once
- You're building a pipeline that processes real-world data with gaps

## Commands

| Command | Does | Example |
|---|---|---|
| `df when-not` | Wrap all cells as Options | `$table \| df when-not null` |
| `df unwrap-or` | Unwrap all cells with default | `$opt_table \| df unwrap-or "N/A"` |
| `df join` | Join with Option-aware keys | `$left \| df join $right id name --left` |

## Wrap / Unwrap

### Wrap a table (enter monadic DataFrame)
```nushell
let data = [
    {name: "Alice", age: 30, email: "a@b.com"}
    {name: "Bob", age: null, email: null}
]

let opt_data = $data | df when-not null
# Every cell is now an Option:
# [{name: Some("Alice"), age: Some(30), email: Some("a@b.com")},
#  {name: Some("Bob"),   age: None,     email: None}]
```

### Unwrap a table (exit monadic DataFrame)
```nushell
$opt_data | df unwrap-or "N/A"
# [{name: "Alice", age: 30, email: "a@b.com"},
#  {name: "Bob",   age: "N/A", email: "N/A"}]
```

### Different defaults per column
```nushell
$opt_data
| update age { option unwrap-or 0 }
| update email { option unwrap-or "unknown@example.com" }
| update name { option unwrap-or "Anonymous" }
```

## Joins

Option-aware joins ensure the result is a **fully monadic DataFrame** — no hybrid null/Option mixing. Missing values from outer/left/right joins become `None`, not raw `null`.

### Inner join
```nushell
$left | df join $right id
# Only matching rows, all cells are Options
```

### Left join (keep all left rows)
```nushell
$left | df join $right id category --left
# Non-matching right columns become None (not null)
```

### Multi-column join
```nushell
$left | df join $right study_id site_id visit --outer
# Join on multiple keys, full outer
```

## Recipes

### Clean pipeline: load → wrap → transform → unwrap
```nushell
use nu-monas/option
use nu-monas/option/df

open data.csv
| df when-not ""                          # empty strings → None
| update age { option and-then {|a|              # parse age safely
    try { $a | into int | option some } catch { option none }
  }}
| update email { option keep-if { str contains "@" } }  # invalid → None
| df unwrap-or null                       # exit monadic world
```

### Join two CSVs with nullable keys
```nushell
use nu-monas/option/df

let patients = open patients.csv | df when-not ""
let visits = open visits.csv | df when-not ""

$patients | df join $visits patient_id --left
| df unwrap-or "N/A"
```

### Validate then process
```nushell
use nu-monas/option
use nu-monas/option/df
use nu-monas/validation

let data = open raw.csv | df when-not null

# Validate each row
$data | each {|row|
    $row | validation pure
    | validation check {|r| if ($r.id | option is-some) { $r | validation success "Has ID" } else { $r | validation failure "Missing ID" }}
    | validation check {|r| if ($r.name | option is-some) { $r | validation success "Has name" } else { $r | validation failure "Missing name" }}
    | validation collect
} | flatten
```

## Key Concept

The pattern is: **wrap early at the boundary** (when data enters from CSV/JSON/DB), **work in Option-space** (all operations are null-safe), **unwrap late** (when outputting or displaying).

This mirrors the general nu-monas philosophy — but applied to entire tables instead of single values.
