#!/usr/bin/env nu

use std/assert
use ../../result

# =============================================================================
# SAFELY TESTS
# =============================================================================

# [test] safely wraps successful operations in Ok
def test-result-safely-wraps-success [] {
    let result = 42 | result safely { $in / 2 }
    assert equal $result.type "ok"
    assert equal $result.value 21
}

# [test] safely wraps errors in Err with original input as data
def test-result-safely-wraps-error [] {
    let result = 0 | result safely { 10 / $in }
    assert equal $result.type "err"
    assert equal $result.data 0
    assert ($result.error.msg | str contains "Division by zero")
}

# [test] safely preserves input in error data field
def test-result-safely-preserves-context [] {
    let input = {value: "test"}
    let result = $input | result safely { $in.missing_field }
    assert equal $result.type "err"
    assert equal $result.data $input
}

# =============================================================================
# AND-THEN-SAFELY TESTS
# =============================================================================

# [test] and-then-safely chains successful operations
def test-result-and-then-safely-chains-success [] {
    let result = 10 | result ok
        | result and-then-safely { $in * 2 }
        | result and-then-safely { $in + 5 }
    assert equal $result.type "ok"
    assert equal $result.value 25
}

# [test] and-then-safely handles errors in chain
def test-result-and-then-safely-handles-error [] {
    let result = 10 | result ok
        | result and-then-safely { $in / 0 }
        | result and-then-safely { $in * 2 }  # Should not execute
    assert equal $result.type "err"
    assert equal $result.data 10  # Original value preserved
}

# [test] and-then-safely passes through Err unchanged
def test-result-and-then-safely-passthrough-err [] {
    let original_err = 5 | result safely { error make {msg: "original error"} }
    let result = $original_err | result and-then-safely { $in * 2 }
    assert equal $result $original_err
}

# =============================================================================
# ENSURE TESTS
# =============================================================================

# [test] ensure returns Ok when predicate is true
def test-result-ensure-success [] {
    let result = 42 | result ensure { $in > 0 }
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] ensure returns Err when predicate is false
def test-result-ensure-failure [] {
    let result = -5 | result ensure { $in > 0 }
    assert equal $result.type "err"
    assert equal $result.data (-5)
    assert ($result.error.msg | str contains "Assertion failed")
}

# [test] ensure uses custom error message
def test-result-ensure-custom-message [] {
    let result = -5 | result ensure { $in > 0 } "Value must be positive"
    assert equal $result.type "err"
    assert equal $result.data (-5)
    assert ($result.error.msg | str contains "Value must be positive")
}

# =============================================================================
# AND-THEN-ENSURE TESTS
# =============================================================================

# [test] and-then-ensure chains validations successfully
def test-result-and-then-ensure-chains-success [] {
    let result = 50 | result ok
        | result and-then-ensure { $in > 0 } { "Must be positive" }
        | result and-then-ensure { $in < 100 } { "Must be less than 100" }
    assert equal $result.type "ok"
    assert equal $result.value 50
}

# [test] and-then-ensure fails on first invalid condition
def test-result-and-then-ensure-first-failure [] {
    let result = -5 | result ok
        | result and-then-ensure { $in > 0 } { "Must be positive" }
        | result and-then-ensure { $in < 100 } { "Must be less than 100" }
    assert equal $result.type "err"
    assert equal $result.data (-5)
    assert ($result.error.msg | str contains "Must be positive")
}

# [test] and-then-ensure fails on second invalid condition
def test-result-and-then-ensure-second-failure [] {
    let result = 150 | result ok
        | result and-then-ensure { $in > 0 } { "Must be positive" }
        | result and-then-ensure { $in < 100 } { "Must be less than 100" }
    assert equal $result.type "err"
    assert equal $result.data 150
    assert ($result.error.msg | str contains "Must be less than 100")
}

# [test] and-then-ensure passes through existing Err
def test-result-and-then-ensure-passthrough-err [] {
    let original_err = 5 | result safely { error make {msg: "original error"} }
    let result = $original_err
        | result and-then-ensure { $in > 0 }
        | result and-then-ensure { $in < 100 }
    assert equal $result $original_err
}

# =============================================================================
# COMPLEX CHAIN TESTS
# =============================================================================

# [test] complex chain mixing all auto-wrapping functions
def test-result-complex-chain-success [] {
    let result = "42" | result ok
        | result and-then-safely { into int }  # Parse string
        | result and-then-ensure { $in > 0 } { "Must be positive" }
        | result and-then-safely { $in * 2 }  # Multiply
        | result and-then-ensure { $in < 100 } { "Result too large" }
    assert equal $result.type "ok"
    assert equal $result.value 84
}

# [test] complex chain with early error
def test-result-complex-chain-early-error [] {
    let result = "not-a-number" | result ok
        | result and-then-safely { into int }  # Will fail here
        | result and-then-ensure { $in > 0 }
        | result and-then-safely { $in * 2 }
    assert equal $result.type "err"
    assert equal $result.data "not-a-number"
}