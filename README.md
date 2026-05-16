# nu-monas

Monadic types for Nushell pipelines.

*μονάς: unit, the indivisible.*

---

## What This Is

Three algebraic structures for safe data pipeline composition in Nushell:

| Type | Purpose | Key Operation |
|------|---------|---------------|
| **Option** (Some/None) | Handle absent values without null checks | `and-then` (bind) |
| **Result** (Ok/Err) | Handle failures with full error context | `and-then` (bind) |
| **Validation** | Accumulate ALL findings without short-circuiting | `check` (apply) |

Plus DataFrame integration (`option df when-not`, `option df join`) and functional record utilities.

## Installation

```bash
# Clone
git clone https://github.com/ChristianLemer/nu-monas.git

# Add to NU_LIB_DIRS in your config.nu
$env.NU_LIB_DIRS = ($env.NU_LIB_DIRS | append "/path/to/nu-monas")
```

Or with nupm:
```nushell
nupm install --path /path/to/nu-monas
```

## Quick Start

### Option — safe null handling

```nushell
use nu-monas/option

# Wrap values
42 | option some                          # Some(42)
null | option when-not null               # None

# Chain operations (short-circuits on None)
"42" | option some | option and-then {
    try { into int | option some } catch { option none }
} | option unwrap-or 0                    # 42

# Bulk DataFrame operations
$data | option df when-not null           # All cells become Options
$data | option df unwrap-or "N/A"         # All Options back to values
```

### Result — railway-oriented error handling

```nushell
use nu-monas/result

# Safe operations with automatic error capture
42 | result safely { $in / 2 }            # Ok(21)
0 | result safely { 10 / $in }           # Err(division by zero)

# Chain validations
$value | result ok
| result and-then-ensure { $in > 0 } { "must be positive" }
| result and-then-safely { $in | into string }
| result unwrap-or "invalid"
```

### Validation — accumulate all findings

```nushell
use nu-monas/validation

# All checks run regardless of failures (not monadic — applicative)
$data
| validation pure
| validation check { if "Name" in ($in | columns) { $in | validation success "Has Name" } else { $in | validation failure "Missing Name" } }
| validation check { if "Age" in ($in | columns) { $in | validation success "Has Age" } else { $in | validation warning "Age missing" } }
| validation collect
```

## Theoretical Foundation

This library implements Wadler's formalization of monads as composable effects:

- **Option** handles the *partiality* effect (computation may produce no value)
- **Result** handles the *failure* effect (computation may fail with context)
- **Validation** is an *applicative functor* (deliberately not a monad — preserves error accumulation by never short-circuiting)

All monadic operations satisfy the three laws: left identity, right identity, associativity.

## Modules

```
nu-monas/
├── option/          Option monad (Some/None)
│   └── df/          DataFrame integration (when-not, unwrap-or, join)
├── result/          Result monad (Ok/Err) with resource management
├── validation/      Applicative validation (accumulates all checks)
├── monad/           Cross-type conversions (option↔result)
├── df/              DataFrame utilities (types, homogenize, update, join)
└── record/          Functional record operations (map, filter, evolve)
```

## License

MIT
