#!/usr/bin/env nu

use std/assert
use ../../option
use ../../result
use ../../monad [option-to-result, result-to-option]

# =============================================================================
# OPTION MODULE INTEGRATION TESTS
# =============================================================================

# [test] Option chaining with and-then works correctly
def test_option_chaining_integration [] {
    let result = 42 | option some 
        | option and-then {|x| ($x * 2) | option some }
        | option unwrap-or 0
    assert equal $result 84
}

# [test] Option none unwrap-or provides default
def test_option_none_unwrap_or_integration [] {
    let result = option none | option unwrap-or 42
    assert equal $result 42
}

# =============================================================================
# RESULT MODULE INTEGRATION TESTS
# =============================================================================

# [test] Result chaining with and-then works correctly
def test_result_chaining_integration [] {
    let result = 42 | result ok
        | result and-then {|x| ($x * 2) | result ok }
        | result unwrap-or 0
    assert equal $result 84
}

# [test] Result err unwrap-or provides default
def test_result_err_unwrap_or_integration [] {
    let result = "data" | result err "failed" | result unwrap-or 42
    assert equal $result 42
}

# =============================================================================
# MONAD CONVERSION INTEGRATION TESTS
# =============================================================================

# [test] Option to Result to Option round trip works
def test_option_result_conversion_round_trip [] {
    let result = 42 | option some 
        | option-to-result "no value"
        | result-to-option
        | option unwrap-or 0
    assert equal $result 42
}

# =============================================================================
# SEQUENCE OPERATION INTEGRATION TESTS
# =============================================================================

# [test] Option sequence operation works with all Some values
def test_option_sequence_integration [] {
    let options = [1, 2, 3] | each {|x| $x | option some }
    let result = $options | option sequence
    assert equal $result.type "some"
    assert equal $result.value [1, 2, 3]
}

# [test] Result sequence operation works with all Ok values
def test_result_sequence_integration [] {
    let results = [1, 2, 3] | each {|x| $x | result ok }
    let result = $results | result sequence
    assert equal $result.type "ok"
    assert equal $result.value [1, 2, 3]
}