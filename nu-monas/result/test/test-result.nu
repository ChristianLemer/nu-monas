#!/usr/bin/env nu

use std/assert
use ../../result

# =============================================================================
# CONSTRUCTION TESTS
# =============================================================================

# [test] Ok wraps value correctly
def test_result_ok_wraps_value [] {
    let result = 42 | result ok
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] Ok wraps string correctly
def test_result_ok_wraps_string [] {
    let result = "hello" | result ok
    assert equal $result.type "ok"
    assert equal $result.value "hello"
}

# [test] Ok wraps list correctly
def test_result_ok_wraps_list [] {
    let result = [1, 2, 3] | result ok
    assert equal $result.type "ok"
    assert equal $result.value [1, 2, 3]
}

# [test] Err wraps error with data
def test_result_err_wraps_error [] {
    let result = "bad data" | result safely { error make {msg: "validation failed"} }
    assert equal $result.type "err"
    assert equal $result.error.msg "validation failed"
    assert equal $result.data "bad data"
}

# [test] Err accepts null data
def test_result_err_with_null_data [] {
    let result = null | result safely { error make {msg: "null value"} }
    assert equal $result.type "err"
    assert equal $result.error.msg "null value"
    assert equal $result.data null
}

# =============================================================================
# TRANSFORMATION TESTS
# =============================================================================

# [test] Map transforms ok value
def test_result_map_transforms_ok [] {
    let result = 42 | result ok | result map { $in * 2 }
    assert equal $result.type "ok"
    assert equal $result.value 84
}

# [test] Map passes through err unchanged
def test_result_map_passes_through_err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result map { $in * 2 }
    assert equal $result.type "err"
    assert equal $result.error.msg "failed"
    assert equal $result.data "data"
}

# [test] Map with string transformation
def test_result_map_with_string_transformation [] {
    let result = "hello" | result ok | result map { str length }
    assert equal $result.type "ok"
    assert equal $result.value 5
}

# [test] Map-err transforms error message
def test_result_map_err_transforms_err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result map-err { {msg: $"prefix: ($in.msg)"} }
    assert equal $result.type "err"
    assert equal $result.error.msg "prefix: failed"
    assert equal $result.data "data"
}

# [test] Map-err passes through ok unchanged
def test_result_map_err_passes_through_ok [] {
    let result = 42 | result ok | result map-err { "prefix: " + $in }
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] And-then chains ok value
def test_result_and_then_chains_ok [] {
    let result = 42 | result ok | result and-then {
        if $in > 0 { result ok } else { result safely { error make {msg: "negative"} } }
    }
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] And-then returns err result
def test_result_and_then_returns_err [] {
    let result = -5 | result ok | result and-then {
        if $in > 0 { result ok } else { result safely { error make {msg: "negative"} } }
    }
    assert equal $result.type "err"
    assert equal $result.error.msg "negative"
}

# [test] And-then passes through err unchanged
def test_result_and_then_passes_through_err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result and-then { $in * 2 | result ok }
    assert equal $result.type "err"
    assert equal $result.error.msg "failed"
}

# [test] Or-else returns ok value
def test_result_or_else_returns_ok [] {
    let result = 42 | result ok | result or-else { 0 | result ok }
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] Or-else returns alternative on err
def test_result_or_else_returns_alternative [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result or-else { 0 | result ok }
    assert equal $result.type "ok"
    assert equal $result.value 0
}

# [test] Or-else can return err alternative
def test_result_or_else_can_return_err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result or-else { "data" | result safely { error make {msg: "still failed"} } }
    assert equal $result.type "err"
    assert equal $result.error.msg "still failed"
}

# =============================================================================
# INSPECTION TESTS
# =============================================================================

# [test] Is-ok returns true for ok
def test_result_is_ok_returns_true [] {
    let result = 42 | result ok | result is-ok
    assert $result
}

# [test] Is-ok returns false for err
def test_result_is_ok_returns_false [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result is-ok
    assert not $result
}

# [test] Is-err returns false for ok
def test_result_is_err_returns_false [] {
    let result = 42 | result ok | result is-err
    assert not $result
}

# [test] Is-err returns true for err
def test_result_is_err_returns_true [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result is-err
    assert $result
}

# =============================================================================
# EXTRACTION TESTS
# =============================================================================

# [test] Unwrap extracts value from ok
def test_result_unwrap_extracts_value [] {
    let result = 42 | result ok | result unwrap
    assert equal $result 42
}

# [test] Unwrap errors on err - REMOVED: unwrap now panics, can't be caught
# def test_result_unwrap_errors_on_err [] {
#     assert error { "data" | result safely { error make {msg: "failed"} } | result unwrap }
# }

# [test] Unwrap-or returns value from ok
def test_result_unwrap_or_returns_value [] {
    let result = 42 | result ok | result unwrap-or 0
    assert equal $result 42
}

# [test] Unwrap-or returns default for err
def test_result_unwrap_or_returns_default [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result unwrap-or 0
    assert equal $result 0
}

# [test] Unwrap-err extracts error from err
def test_result_unwrap_err_extracts_error [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result unwrap-err
    assert equal $result.msg "failed"
}

# [test] Unwrap-err errors on ok - REMOVED: unwrap-err now panics, can't be caught
# def test_result_unwrap_err_errors_on_ok [] {
#     assert error { 42 | result ok | result unwrap-err }
# }

# [test] Expect extracts value from ok
def test_result_expect_extracts_value [] {
    let result = 42 | result ok | result expect "Should have value"
    assert equal $result 42
}

# [test] Expect errors with custom message on err - REMOVED: expect now panics, can't be caught
# def test_result_expect_errors_with_message [] {
#     assert error { "data" | result safely { error make {msg: "failed"} } | result expect "Custom error message" }
# }

# =============================================================================
# UTILITY TESTS
# =============================================================================

# [test] Flatten unwraps nested ok value
def test_result_flatten_ok_ok [] {
    let result = 42 | result ok | result ok | result unnest
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] Flatten converts ok(err) to err
def test_result_flatten_ok_err [] {
    let inner = "data" | result safely { error make {msg: "inner error"} }
    let wrapped = {type: "ok", value: $inner}
    let result = $wrapped | result unnest
    assert equal $result.type "err"
    assert equal $result.error.msg "inner error"
    assert equal $result.data "data"
}

# [test] Flatten passes through err unchanged
def test_result_flatten_err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result unnest
    assert equal $result.type "err"
    assert equal $result.error.msg "failed"
}

# [test] Flatten errors on non-nested result
def test_result_flatten_errors_on_non_nested [] {
    assert error { 42 | result ok | result unnest }
}


# =============================================================================
# MONADIC LAW TESTS
# =============================================================================

# [test] Left identity monadic law holds
def test_result_left_identity [] {
    # Left identity: ok(a) | and-then f == f(a)
    let a = 42
    let f = { ($in * 2) | result ok }
    
    let result1 = $a | result ok | result and-then $f
    let result2 = $a | do $f
    
    assert equal $result1 $result2
}

# [test] Right identity monadic law holds
def test_result_right_identity [] {
    # Right identity: m | and-then ok == m
    let m = 42 | result ok
    let result = $m | result and-then { result ok }

    assert equal $result $m
}

# [test] Associativity monadic law holds
def test_result_associativity [] {
    # Associativity: (m | and-then f) | and-then g == m | and-then {|x| f(x) | and-then g}
    let m = 10 | result ok
    let f = { ($in * 2) | result ok }
    let g = { ($in + 5) | result ok }
    
    let result1 = $m | result and-then $f | result and-then $g
    let result2 = $m | result and-then { do $f | result and-then $g }

    assert equal $result1 $result2
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

# [test] Parse number chain with validation
def test_result_parse_number_chain [] {
    # Simulates parsing a string to number with validation
    let result = "42" | result ok | result and-then {
        try { into int | result ok } catch {|e| $e | result err $in }
    } | result and-then {
        if $in > 0 { result ok } else { result safely { error make {msg: "not positive"} } }
    } | result map { $in * 2 }
    
    assert equal $result.type "ok"
    assert equal $result.value 84
}

# [test] Parse invalid number returns default
def test_result_parse_invalid_number [] {
    let result = "abc" | result ok | result and-then {
        try { into int | result ok } catch {|e| $e | result err $in }
    } | result unwrap-or 0
    
    assert equal $result 0
}

# [test] Division by zero returns default
def test_result_division_by_zero [] {
    let result = 0 | result ok | result and-then {
        if $in != 0 {
            let quotient = 42 / $in
            $quotient | result ok
        } else {
            result safely { error make {msg: "division by zero"} }
        }
    } | result unwrap-or (-1)
    
    assert equal $result (-1)
}

# [test] Error chain short-circuits on first error
def test_result_error_chain_short_circuits [] {
    # Once an error occurs, it should short-circuit the rest
    let result = 42 | result ok
        | result and-then { result safely { error make {msg: "first error"} } }
        | result and-then { result ok }  # This should not execute
        | result map { $in * 2 }        # This should not execute

    assert equal $result.type "err"
    assert equal $result.error.msg "first error"
    assert equal $result.data 42
}

# [test] Recovery with or-else after error
def test_result_recovery_with_or_else [] {
    # Test recovery from error using or-else
    let result = "invalid" | result ok
        | result and-then { try { into int | result ok } catch {|e| $e | result err $in } }
        | result or-else { 0 | result ok }
        | result map { $in + 10 }

    assert equal $result.type "ok"
    assert equal $result.value 10
}
