#!/usr/bin/env nu

# Comprehensive integration tests for the monadic system
# This file demonstrates real-world usage patterns and ensures all modules work together

use std/assert
use ../../option
use ../../result
use ../mod.nu *
use ../../option [traverse]
use ../../result [traverse]

# =============================================================================
# REAL-WORLD SCENARIO TESTS
# =============================================================================

#[test]
def test_user_profile_validation [] {
    # Simulate validating a user profile with optional fields
    let user_data = {
        name: "Alice"
        email: "alice@example.com"
        age: 30
        bio: "Software engineer"
    }
    
    # Chain of validations that might fail
    let result = $user_data | result ok
        | result and-then {
            if ($in.name | str length) > 0 {
                result ok
            } else {
                result safely { error make {msg: "Name is required"} }
            }
        }
        | result and-then {
            if ($in.email | str contains "@") {
                result ok
            } else {
                result safely { error make {msg: "Invalid email format"} }
            }
        }
        | result and-then {
            if $in.age >= 18 {
                result ok
            } else {
                result safely { error make {msg: "Must be 18 or older"} }
            }
        }
    
    assert equal $result.type "ok"
    assert equal $result.value.name "Alice"
}

#[test]
def test_user_profile_validation_failure [] {
    # Test with invalid data
    let user_data = {
        name: ""
        email: "invalid-email"
        age: 16
    }
    
    let result = $user_data | result ok
        | result and-then {
            if ($in.name | str length) > 0 {
                result ok
            } else {
                result safely { error make {msg: "Name is required"} }
            }
        }
    
    assert equal $result.type "err"
    assert equal $result.error.msg "Name is required"
}

#[test]
def test_config_field_extraction [] {
    # Simulate extracting optional configuration fields
    let config = {
        database: {
            host: "localhost"
            port: 5432
        }
        cache: {
            enabled: true
        }
    }
    
    # Extract nested optional fields safely
    let db_host = $config | option some
        | option and-then { try { $in.database | option some } catch { option none }}
        | option and-then { try { $in.host | option some } catch { option none }}
        | option unwrap-or "localhost"
    
    assert equal $db_host "localhost"
    
    # Extract missing field
    let timeout = $config | option some
        | option and-then { try { $in.database | option some } catch { option none }}
        | option and-then { try { $in.timeout | option some } catch { option none }}
        | option unwrap-or 30
    
    assert equal $timeout 30
}

#[test]
def test_batch_number_parsing [] {
    # Test parsing a batch of strings to numbers
    let string_numbers = ["1", "2", "3", "4", "5"]

    let result = $string_numbers | result traverse {
        try { into int | result ok } catch { result safely { error make {msg: "invalid number"} } }
    }

    assert equal $result.type "ok"
    assert equal $result.value [1, 2, 3, 4, 5]
}

#[test]
def test_batch_number_parsing_with_failure [] {
    # Test with one invalid number
    let string_numbers = ["1", "abc", "3"]

    let result = $string_numbers | result traverse {
        try { into int | result ok } catch { result safely { error make {msg: "invalid number"} } }
    }

    assert equal $result.type "err"
    assert equal $result.error.msg "invalid number"
}

#[test]
def test_optional_field_aggregation [] {
    # Test aggregating optional fields from multiple records
    let records = [
        {name: "Alice", score: 85}
        {name: "Bob", score: 92}
        {name: "Charlie", score: 78}
        {name: "David"}  # Missing score
    ]
    
    # Extract all scores that exist
    let scores = $records | each { 
        try { $in.score | option some } catch { option none }
    } | where { $in.type == "some" } | each { $in.value }
    
    assert equal $scores [85, 92, 78]
    
    # Try to get all scores (should fail due to missing one)
    let all_scores = $records | option traverse { 
        try { $in.score | option some } catch { option none }
    }
    
    assert equal $all_scores.type "none"
}

#[test]
def test_pipeline_with_conversions [] {
    # Test a complex pipeline with conversions between Option and Result
    let data = "42"
    
    let result = $data | option some                          # Start with Option
        | option-to-result "no data"                   # Convert to Result
        | result and-then {
            try { into int | result ok } catch { result safely { error make {msg: "parse error"} } }
        }                                              # Parse as int
        | result and-then {
            if $in > 0 { result ok } else { result safely { error make {msg: "not positive"} } }
        }                                              # Validate positive
        | result-to-option                             # Convert back to Option
        | option and-then { ($in * 2) | option some }         # Double the value
        | option unwrap-or 0                              # Extract with default
    
    assert equal $result 84
}

#[test]
def test_error_recovery_chain [] {
    # Test recovering from errors in a chain
    let result = "invalid" | result ok
        | result and-then {
            try { into int | result ok } catch { result safely { error make {msg: "parse failed"} } }
        }
        | result and-then { ($in * 2) | result ok }           # This won't execute
        | result unwrap-or 0                             # Recover with default
    
    assert equal $result 0
}

#[test]
def test_nested_option_flattening [] {
    # Test working with nested Options
    let maybe_maybe_value = 42 | option some | option some
    
    let result = $maybe_maybe_value | option unnest | option unwrap-or 0
    assert equal $result 42
    
    let none_nested = option none | option some
    let result2 = $none_nested | option unnest | option unwrap-or 0
    assert equal $result2 0
}

#[test]
def test_validation_with_multiple_conditions [] {
    # Test complex validation with multiple conditions
    let validate_user = {|user| 
        # All conditions must pass
        [
            # Name validation
            (if ($user.name | str length) > 0 { $user | result ok } else { $user | result safely { error make {msg: "Name required"} } }),
            # Email validation  
            (if ($user.email | str contains "@") { $user | result ok } else { $user | result safely { error make {msg: "Invalid email"} } }),
            # Age validation
            (if $user.age >= 18 { $user | result ok } else { $user | result safely { error make {msg: "Must be 18+"} } })
        ] | result sequence | result and-then { first | result ok }
    }
    
    let valid_user = {name: "Alice", email: "alice@test.com", age: 25}
    let result = do $validate_user $valid_user
    assert equal $result.type "ok"
    
    let invalid_user = {name: "", email: "alice@test.com", age: 25}
    let result2 = do $validate_user $invalid_user
    assert equal $result2.type "err"
    assert equal $result2.error.msg "Name required"
}

#[test]
def test_monadic_composition [] {
    # Test composition of monadic operations
    let safe_divide = {|dividend, divisor| 
        if $divisor != 0 { 
            ($dividend / $divisor) | result ok 
        } else { 
            $dividend | result safely { error make {msg: "division by zero"} } 
        }
    }
    
    let safe_sqrt = {|x| 
        if $x >= 0 { 
            ($x | math sqrt) | result ok 
        } else { 
            $x | result safely { error make {msg: "negative number"} } 
        }
    }
    
    # Compose: divide then square root
    let result = 16 | result ok
        | result and-then { do $safe_divide $in 4 }
        | result and-then { do $safe_sqrt $in }
    
    assert equal $result.type "ok"
    assert equal $result.value 2
    
    # Test error propagation
    let result2 = 16 | result ok
        | result and-then { do $safe_divide $in 0 }  # Division by zero
        | result and-then $safe_sqrt                   # This won't execute
    
    assert equal $result2.type "err"
    assert equal $result2.error.msg "division by zero"
}

# =============================================================================
# PERFORMANCE AND EDGE CASE TESTS
# =============================================================================

#[test]
def test_large_list_processing [] {
    # Test processing a large list
    let large_list = 1..100 | each { $in }
    
    let result = $large_list | option traverse {
        if $in <= 100 { option some } else { option none }
    }
    
    assert equal $result.type "some"
    assert equal ($result.value | length) 100
}

#[test]
def test_empty_list_handling [] {
    # Test with empty lists
    let empty_options = []
    let result = $empty_options | option sequence
    assert equal $result.type "some"
    assert equal $result.value []
    
    let empty_results = []
    let result2 = $empty_results | result sequence  
    assert equal $result2.type "ok"
    assert equal $result2.value []
}

#[test]
def test_type_safety [] {
    # Test that the monadic types maintain type safety
    let mixed_data = [
        (42 | option some),
        ("hello" | option some),
        ([1, 2, 3] | option some)
    ]
    
    let result = $mixed_data | option sequence
    assert equal $result.type "some"
    assert equal ($result.value | length) 3
    assert equal ($result.value | first) 42
    assert equal ($result.value | get 1) "hello"
    assert equal ($result.value | get 2) [1, 2, 3]
}

# Integration tests completed successfully