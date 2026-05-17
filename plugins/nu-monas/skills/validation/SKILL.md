---
name: validation
description: Use when working with nu-monas Validation type — accumulating multiple checks without short-circuiting, building validation pipelines, collecting all errors at once. Triggers on "Validation", "accumulate errors", "check all fields", "validate schema", "collect messages", "applicative", or when the user needs to report all issues in data rather than stopping at the first.
---

# Validation — Applicative Error Accumulation

Validation runs **all checks** and accumulates messages. It never short-circuits — unlike Result, which stops at the first error.

```nushell
use nu-monas/validation
```

## When to Use

- You want ALL errors at once, not just the first
- You're validating a record/schema against multiple rules
- You need a report with successes, failures, warnings, skips
- You're building data quality checks

## Key Insight

Validation is an **Applicative Functor**, not a Monad. It has no `and-then`/`bind` — deliberately. Each `check` runs independently, so failures accumulate instead of short-circuiting.

## Construct

| Command | Does | Example |
|---|---|---|
| `pure` | Lift value, no messages | `$data \| validation pure` |
| `success` | Value + success message | `$data \| validation success "Schema OK"` |
| `failure` | Value + failure message | `$data \| validation failure "Missing name"` |
| `warning` | Value + warning message | `$data \| validation warning "Extra field"` |
| `skipped` | Value + skipped message | `$data \| validation skipped "Not applicable"` |

**`pure` vs `success`:**
- `pure` — no message, just enter the Validation context (identity element)
- `success` — enter with an initial success message

## Accumulate

The single operation: **`check`**

```nushell
$data
| validation success "Starting"
| validation check {|d| if condition { $d | validation success "OK" } else { $d | validation failure "Bad" }}
| validation check {|d| ... }   # runs regardless of previous check
| validation check {|d| ... }   # still runs
```

The closure receives the value both as `$in` and as a parameter (like Nushell's `insert` — use `$in` for one-liners, the named param for multi-line). Every `check` runs — no short-circuit.

**Status priority:** failure > warning > skipped > success. The overall status is the worst encountered.

## Extract

| Command | Does |
|---|---|
| `validation collect` | Messages (failures + warnings + skipped only) |
| `validation collect --verbose` | All messages including successes |
| `validation get-value` | The original value (ignores messages) |
| `validation is-success` | `true` if no failures or warnings |
| `validation is-failure` | `true` if any failure |
| `validation is-warning` | `true` if warnings but no failures |

## Recipes

### Validate a record
```nushell
$record
| validation pure
| validation check {|r| if "name" in ($r | columns) { $r | validation success "Has name" } else { $r | validation failure "Missing name" }}
| validation check {|r| if "age" in ($r | columns) {
    if ($r.age >= 0) { $r | validation success "Age valid" } else { $r | validation failure "Age negative" }
  } else { $r | validation skipped "No age field" }}
| validation check {|r| if "email" in ($r | columns) {
    if ($r.email | str contains "@") { $r | validation success "Email valid" } else { $r | validation failure "Invalid email" }
  } else { $r | validation warning "No email" }}
| validation collect
```

### Validate with a list of rules
```nushell
let rules = [
    {|r| if "id" in ($r | columns) { $r | validation success "Has ID" } else { $r | validation failure "Missing ID" }}
    {|r| if "status" in ($r | columns) { $r | validation success "Has status" } else { $r | validation failure "Missing status" }}
]

$rules | reduce --fold ($record | validation pure) {|rule, acc|
    $acc | validation check $rule
}
| validation collect
```

### Validate a table (row by row)
```nushell
$table | each {|row|
    $row
    | validation pure
    | validation check {|r| ... }
    | validation check {|r| ... }
    | validation collect
} | flatten
```

### Pass/fail gate
```nushell
let result = $data | validation pure | validation check {|d| ...} | validation check {|d| ...}

if ($result | validation is-success) {
    $result | validation get-value | process-further
} else {
    $result | validation collect | print
}
```

## Anti-patterns

- Don't chain `check` where the second depends on the first passing — that's sequential logic, use Result
- Don't use Validation for a single pass/fail — use `ensure` from Result
- Don't ignore the `collect` output — the whole point is the accumulated report
