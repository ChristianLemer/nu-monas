#!/usr/bin/env nu

use std/assert
use ../mod.nu [option-to-result, result-to-option]
use ../../option
use ../../result

# =============================================================================
# WHEN-NOT CONSTRUCTOR TESTS
# =============================================================================

# [test] When-not null converts non-null values to some
def test_when_not_null_non_null [] {
    let result = 42 | option when-not null
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] When-not null converts null to none
def test_when_not_null_null [] {
    let result = null | option when-not null
    assert equal $result.type "none"
}

# [test] When-not empty string converts non-empty strings to some
def test_when_not_empty_string_non_empty [] {
    let result = "hello" | option when-not ""
    assert equal $result.type "some"
    assert equal $result.value "hello"
}

# [test] When-not empty string converts empty string to none
def test_when_not_empty_string_empty [] {
    let result = "" | option when-not ""
    assert equal $result.type "none"
}

# [test] When-not empty list converts non-empty lists to some
def test_when_not_empty_list_non_empty [] {
    let result = [1, 2, 3] | option when-not []
    assert equal $result.type "some"
    assert equal $result.value [1, 2, 3]
}

# [test] When-not empty list converts empty list to none
def test_when_not_empty_list_empty [] {
    let result = [] | option when-not []
    assert equal $result.type "none"
}

# [test] When-not custom value works with integers
def test_when_not_custom_value_integer [] {
    let result = 42 | option when-not (-1)
    assert equal $result.type "some"
    assert equal $result.value 42
    
    let result2 = (-1) | option when-not (-1)
    assert equal $result2.type "none"
}

# [test] Perfect symmetry with unwrap-or for null
def test_when_not_unwrap_or_symmetry_null [] {
    let original = 42
    let result = $original | option when-not null | option unwrap-or null
    assert equal $result $original
    
    let original2 = null
    let result2 = $original2 | option when-not null | option unwrap-or null
    assert equal $result2 $original2
}

# [test] Perfect symmetry with unwrap-or for empty string
def test_when_not_unwrap_or_symmetry_empty_string [] {
    let original = "hello"
    let result = $original | option when-not "" | option unwrap-or ""
    assert equal $result $original
    
    let original2 = ""
    let result2 = $original2 | option when-not "" | option unwrap-or ""
    assert equal $result2 $original2
}

# [test] Perfect symmetry with unwrap-or for empty list
def test_when_not_unwrap_or_symmetry_empty_list [] {
    let original = [1, 2, 3]
    let result = $original | option when-not [] | option unwrap-or []
    assert equal $result $original
    
    let original2 = []
    let result2 = $original2 | option when-not [] | option unwrap-or []
    assert equal $result2 $original2
}

# =============================================================================
# RESULT-NULLABLE CONVERSION TESTS
# =============================================================================

# [test] Result unwrap-or null extracts ok values
def test_result_unwrap_or_null_ok [] {
    let result = 42 | result ok | result unwrap-or null
    assert equal $result 42
}

# [test] Result unwrap-or null converts err to null
def test_result_unwrap_or_null_err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result unwrap-or null
    assert equal $result null
}

# =============================================================================
# CROSS-TYPE CONVERSION TESTS
# =============================================================================

# [test] When-not constructor to result via option
def test_when_not_to_result_chain [] {
    let result = 42 | option when-not null | option-to-result "was null"
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] Null to result via when-not constructor creates error
def test_null_to_result_via_when_not_chain [] {
    let result = null | option when-not null | option-to-result "was null"
    assert equal $result.type "err"
    assert equal $result.error.msg "was null"
}

# [test] Complex conversion chain with when-not constructor
def test_complex_conversion_chain_with_when_not [] {
    # value → option → result → option → value
    let original = 42
    let result = $original 
        | option when-not null
        | option-to-result "error"
        | result-to-option
        | option unwrap-or null
    assert equal $result $original
}

# =============================================================================
# WHEN-NOT CONSTRUCTOR INTEGRATION TESTS
# =============================================================================

# [test] Test new when-not constructor pattern with data processing
def test_when_not_constructor_data_processing [] {
    # Test the new when-not constructor pattern for data cleaning
    let data = [42, null, "hello", null, "", "world"]
    let results = $data | each {
        # Handle both null and empty string as missing
        option when-not null | option and-then { option when-not ""} | option unwrap-or "missing"
    }
    assert equal $results [42, "missing", "hello", "missing", "missing", "world"]
}