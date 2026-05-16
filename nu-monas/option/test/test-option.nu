#!/usr/bin/env nu

use std/assert
use ../../option
use ../../monad

# =============================================================================
# CONSTRUCTION TESTS
# =============================================================================

# [test] Some wraps value correctly
def test_option_some_wraps_value [] {
    let result = 42 | option some
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] Some wraps string correctly
def test_option_some_wraps_string [] {
    let result = "hello" | option some
    assert equal $result.type "some"
    assert equal $result.value "hello"
}

# [test] Some wraps list correctly
def test_option_some_wraps_list [] {
    let result = [1, 2, 3] | option some
    assert equal $result.type "some"
    assert equal $result.value [1, 2, 3]
}

# [test] Some rejects null value
def test_option_some_rejects_null [] {
    assert error { null | option some }
}

# [test] None creates none type
def test_option_none_creates_none [] {
    let result = option none
    assert equal $result.type "none"
    assert equal ($result | columns | length) 1  # Only has 'type' field
}

# [test] When-not constructor converts non-null int to some
def test_option_when_not_null_int_to_some [] {
    let result = 42 | option when-not null
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] When-not constructor converts non-null string to some
def test_option_when_not_null_string_to_some [] {
    let result = "hello" | option when-not null
    assert equal $result.type "some"
    assert equal $result.value "hello"
}

# [test] When-not constructor converts non-null list to some
def test_option_when_not_null_list_to_some [] {
    let result = [1, 2, 3] | option when-not null
    assert equal $result.type "some"
    assert equal $result.value [1, 2, 3]
}

# [test] When-not constructor converts non-null record to some
def test_option_when_not_null_record_to_some [] {
    let result = {name: "Alice", age: 30} | option when-not null
    assert equal $result.type "some"
    assert equal $result.value.name "Alice"
    assert equal $result.value.age 30
}

# [test] When-not constructor converts null to none
def test_option_when_not_null_null_to_none [] {
    let result = null | option when-not null
    assert equal $result.type "none"
    assert equal ($result | columns | length) 1  # Only has 'type' field
}

# [test] When-not constructor works with zero values
def test_option_when_not_null_zero_to_some [] {
    let result = 0 | option when-not null
    assert equal $result.type "some"
    assert equal $result.value 0
}

# [test] When-not constructor works with empty string
def test_option_when_not_null_empty_string_to_some [] {
    let result = "" | option when-not null
    assert equal $result.type "some"
    assert equal $result.value ""
}

# [test] When-not constructor works with empty list
def test_option_when_not_null_empty_list_to_some [] {
    let result = [] | option when-not null
    assert equal $result.type "some"
    assert equal $result.value []
}

# =============================================================================
# TRANSFORMATION TESTS
# =============================================================================

# [test] Map transforms some value
def test_option_map_transforms_some [] {
    let result = 42 | option some | option map { $in * 2 }
    assert equal $result.type "some"
    assert equal $result.value 84
}

# [test] Map passes through none
def test_option_map_passes_through_none [] {
    let result = option none | option map { $in * 2 }
    assert equal $result.type "none"
}

# [test] Map with string transformation
def test_option_map_with_string_transformation [] {
    let result = "hello" | option some | option map { str length }
    assert equal $result.type "some"
    assert equal $result.value 5
}

# [test] And-then chains some value
def test_option_and_then_chains_some [] {
    let result = 42 | option some | option and-then {
        if $in > 0 { option some } else { option none }
    }
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] And-then returns none
def test_option_and_then_returns_none [] {
    let result = -5 | option some | option and-then {
        if $in > 0 { option some } else { option none }
    }
    assert equal $result.type "none"
}

# [test] And-then passes through none
def test_option_and_then_passes_through_none [] {
    let result = option none | option and-then { $in * 2 | option some }
    assert equal $result.type "none"
}

# [test] Keep-if keeps matching value
def test_option_keep-if_keeps_matching [] {
    let result = 42 | option some | option keep-if { $in > 0 }
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] Keep-if removes non-matching value
def test_option_keep-if_removes_non_matching [] {
    let result = -5 | option some | option keep-if { $in > 0 }
    assert equal $result.type "none"
}

# [test] Keep-if passes through none
def test_option_keep-if_passes_through_none [] {
    let result = option none | option keep-if { $in > 0 }
    assert equal $result.type "none"
}

# [test] Or-else returns some value
def test_option_or_else_returns_some [] {
    let result = 42 | option some | option or-else { 0 | option some }
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] Or-else returns alternative
def test_option_or_else_returns_alternative [] {
    let result = option none | option or-else { 0 | option some }
    assert equal $result.type "some"
    assert equal $result.value 0
}

# [test] Or-else can return none
def test_option_or_else_can_return_none [] {
    let result = option none | option or-else { option none }
    assert equal $result.type "none"
}

# =============================================================================
# INSPECTION TESTS
# =============================================================================

# [test] Is-some returns true for some
def test_option_is_some_returns_true [] {
    let result = 42 | option some | option is-some
    assert $result
}

# [test] Is-some returns false for none
def test_option_is_some_returns_false [] {
    let result = option none | option is-some
    assert not $result
}

# [test] Is-none returns false for some
def test_option_is_none_returns_false [] {
    let result = 42 | option some | option is-none
    assert not $result
}

# [test] Is-none returns true for none
def test_option_is_none_returns_true [] {
    let result = option none | option is-none
    assert $result
}

# =============================================================================
# EXTRACTION TESTS
# =============================================================================

# [test] Unwrap extracts value from some
def test_option_unwrap_extracts_value [] {
    let result = 42 | option some | option unwrap
    assert equal $result 42
}

# [test] Unwrap errors on none
def test_option_unwrap_errors_on_none [] {
    assert error { option none | option unwrap }
}

# [test] Unwrap-or returns value from some
def test_option_unwrap_or_returns_value [] {
    let result = 42 | option some | option unwrap-or 0
    assert equal $result 42
}

# [test] Unwrap-or returns default for none
def test_option_unwrap_or_returns_default [] {
    let result = option none | option unwrap-or 0
    assert equal $result 0
}

# [test] Unwrap-or errors on regular integer  
def test_option_unwrap_or_errors_on_regular_int [] {
    assert error { 42 | option unwrap-or 0 }
}

# [test] Unwrap-or errors on regular string
def test_option_unwrap_or_errors_on_regular_string [] {
    assert error { "hello" | option unwrap-or "default" }
}

# [test] Unwrap-or errors on regular list
def test_option_unwrap_or_errors_on_regular_list [] {
    assert error { [1, 2, 3] | option unwrap-or [] }
}

# [test] Unwrap-or errors on null
def test_option_unwrap_or_errors_on_null [] {
    assert error { null | option unwrap-or "default" }
}

# [test] Map errors on regular values
def test_option_map_errors_on_regular_values [] {
    assert error { 42 | option map { $in * 2 } }
}

# [test] And-then errors on regular values
def test_option_and_then_errors_on_regular_values [] {
    assert error { 42 | option and-then { option some } }
}

# [test] Keep-if errors on regular values  
def test_option_keep_if_errors_on_regular_values [] {
    assert error { 42 | option keep-if { $in > 0 } }
}

# [test] Is-some errors on regular values
def test_option_is_some_errors_on_regular_values [] {
    assert error { 42 | option is-some }
}

# [test] Is-none errors on regular values
def test_option_is_none_errors_on_regular_values [] {
    assert error { 42 | option is-none }
}

# [test] Expect extracts value from some
def test_option_expect_extracts_value [] {
    let result = 42 | option some | option expect "Should have value"
    assert equal $result 42
}

# [test] Expect errors with custom message on none
def test_option_expect_errors_with_message [] {
    assert error { option none | option expect "Custom error message" }
}

# =============================================================================
# UTILITY TESTS
# =============================================================================

# [test] Flatten unwraps nested some value
def test_option_flatten_some_some [] {
    let result = 42 | option some | option some | option unnest
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] Flatten converts some(none) to none
def test_option_flatten_some_none [] {
    let nested = option none
    let wrapped = {type: "some", value: $nested}
    let result = $wrapped | option unnest
    assert equal $result.type "none"
}

# [test] Flatten passes through none unchanged
def test_option_flatten_none [] {
    let result = option none | option unnest
    assert equal $result.type "none"
}

# [test] Flatten errors on non-nested option
def test_option_flatten_errors_on_non_nested [] {
    assert error { 42 | option some | option unnest }
}

# =============================================================================
# MONADIC LAW TESTS
# =============================================================================

# [test] Left identity monadic law holds
def test_option_left_identity [] {
    # Left identity: option some(a) | option and-then f == f(a)
    let a = 42
    let f = { ($in * 2) | option some }
    
    let result1 = $a | option some | option and-then $f
    let result2 = $a | do $f
    
    assert equal $result1 $result2
}

# [test] Right identity monadic law holds
def test_option_right_identity [] {
    # Right identity: m | option and-then option some == m
    let m = 42 | option some
    let result = $m | option and-then { option some }

    assert equal $result $m
}

# [test] Associativity monadic law holds
def test_option_associativity [] {
    # Associativity: (m | option and-then f) | option and-then g == m | option and-then {f($in) | option and-then g}
    let m = 10 | option some
    let f = { ($in * 2) | option some }
    let g = { ($in + 5) | option some }

    let result1 = $m | option and-then $f | option and-then $g
    let result2 = $m | option and-then { do $f | option and-then $g }

    assert equal $result1 $result2
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

# [test] Parse number chain with validation
def test_option_parse_number_chain [] {
    # Simulates parsing a string to number with validation
    let result = "42" | option some | option and-then {
        try { into int | option some } catch { option none }
    } | option keep-if { $in > 0 } | option map { $in * 2 }

    assert equal $result.type "some"
    assert equal $result.value 84
}

# [test] Parse invalid number returns default
def test_option_parse_invalid_number [] {
    let result = "abc" | option some | option and-then {
        try { into int | option some } catch { option none }
    } | option unwrap-or 0

    assert equal $result 0
}

# [test] Nested field access with safe chaining
def test_option_nested_field_access [] {
    # Simulates safe nested field access
    let data = {user: {name: "Alice", age: 30}}
    
    let result = $data | option some 
        | option and-then { try { $in.user | option some } catch { option none }}
        | option and-then { try { $in.age | option some } catch { option none }}
        | option unwrap-or 0
    
    assert equal $result 30
}

# [test] Missing field access returns default
def test_option_missing_field_access [] {
    let data = {user: {name: "Alice"}}  # No age field
    
    let result = $data | option some 
        | option and-then { try { $in.user | option some } catch { option none }}
        | option and-then { try { $in.age | option some } catch { option none }}
        | option unwrap-or 0
    
    assert equal $result 0
}

# =============================================================================
# FROM-NULLABLE INTEGRATION TESTS
# =============================================================================

# [test] When-not constructor integrates with map and unwrap-or
def test_option_when_not_null_with_map_and_unwrap [] {
    let result = 42 | option when-not null | option map { $in * 2 } | option unwrap-or 0
    assert equal $result 84
    
    let null_result = null | option when-not null | option map { $in * 2 } | option unwrap-or 0
    assert equal $null_result 0
}

# [test] When-not constructor works with map2 for binary operations
def test_option_when_not_null_with_map2 [] {
    let opt1 = 10 | option when-not null
    let opt2 = 20 | option when-not null
    let result = option map2 {|a, b| $a + $b } $opt1 $opt2 | option unwrap
    assert equal $result 30
    
    # Test with null input
    let opt_null = null | option when-not null
    let null_result = option map2 {|a, b| $a + $b } $opt1 $opt_null
    assert ($null_result | option is-none)
}

# [test] When-not constructor enables nullable data processing
def test_option_when_not_null_data_processing [] {
    # Simulate processing a list with potential null values
    let data = [42, null, 24, null, 18]
    let result = $data | each {
        option when-not null | option map { $in * 2 } | option unwrap-or (-1)
    }
    assert equal $result [84, (-1), 48, (-1), 36]
}