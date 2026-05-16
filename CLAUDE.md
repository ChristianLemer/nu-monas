# CLAUDE.md

## Repository Overview

nu-monas is a pure Nushell library providing monadic types for safe pipeline composition. It implements Option (Some/None), Result (Ok/Err), and Validation (applicative accumulation) with DataFrame integration.

## Architecture

### Dependency Layers (upward-only dependencies)

- **Level 0 (Foundation):** `monad/monad-common/`, `df/`, `record/`
- **Level 1 (Monadic):** `option/`, `result/`, `validation/` (each uses monad-common)
- **Level 2 (Integration):** `monad/` (conversions), `option/df/` (DataFrame adapter)

### Key Design Principles

1. No circular dependencies — lower layers never import higher layers
2. Adapter pattern — `option/df/` bridges Option and DataFrame without coupling them
3. Monadic laws — all operations satisfy identity and associativity
4. Validation is deliberately NOT a monad — it's an applicative (accumulates, never short-circuits)

## Testing

```bash
nutest run-tests --path nu-monas/
```

## Jujutsu Commit Convention

**Pattern:** `type(scope): :emoji: description`

**Types:** `feat`, `fix`, `refactor`, `chore`, `docs`

**Scopes:** `option`, `result`, `validation`, `monad`, `df`, `record`, `meta`

**Examples:**
- `feat(option): :sparkles: add zip combinator`
- `fix(result): :bug: preserve error span in and-then`
- `docs(meta): :memo: update README examples`
