#!/usr/bin/env nu

use std/assert
use ../mod.nu [option-to-result, result-to-option]
use ../../option [traverse, attempt, some, none]
use ../../result [traverse, ok, err, safely]
use ../../option
use ../../result

# =============================================================================
# CONVERSION TESTS
# =============================================================================

# [test] Option-to-result converts some to ok
def test_monad_option_to_result_some [] {
    let result = 42 | some | option-to-result "no value"
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] Option-to-result converts none to err
def test_monad_option_to_result_none [] {
    let result = none | option-to-result "no value"
    assert equal $result.type "err"
    assert equal $result.error.msg "no value"
}

# [test] Result-to-option converts ok to some
def test_monad_result_to_option_ok [] {
    let result = 42 | ok | result-to-option
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] Result-to-option converts err to none
def test_monad_result_to_option_err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result-to-option
    assert equal $result.type "none"
}

# =============================================================================
# WHEN-NOT CONSTRUCTOR INTEGRATION TESTS
# =============================================================================

# [test] When-not constructor with null converts null to none
def test_monad_when_not_null_null [] {
    let result = null | option when-not null
    assert equal $result.type "none"
}

# [test] When-not constructor with null converts non-null values to some
def test_monad_when_not_null_value [] {
    let result = 42 | option when-not null
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] When-not constructor with empty string converts empty to none
def test_monad_when_not_empty_string_empty [] {
    let result = "" | option when-not ""
    assert equal $result.type "none"
}

# [test] When-not constructor with empty string converts non-empty to some
def test_monad_when_not_empty_string_value [] {
    let result = "hello" | option when-not ""
    assert equal $result.type "some"
    assert equal $result.value "hello"
}

# [test] When-not constructor symmetry with unwrap-or for null
def test_monad_when_not_unwrap_or_symmetry_null [] {
    let original = 42
    let result = $original | option when-not null | option unwrap-or null
    assert equal $result $original
    
    let original2 = null
    let result2 = $original2 | option when-not null | option unwrap-or null
    assert equal $result2 $original2
}

# [test] When-not constructor symmetry with unwrap-or for empty string
def test_monad_when_not_unwrap_or_symmetry_empty [] {
    let original = "hello"
    let result = $original | option when-not "" | option unwrap-or ""
    assert equal $result $original
    
    let original2 = ""
    let result2 = $original2 | option when-not "" | option unwrap-or ""
    assert equal $result2 $original2
}

# =============================================================================
# RESULT-NULLABLE CONVERSION TESTS
# =============================================================================

# [test] Result unwrap-or null extracts ok values
def test_monad_result_unwrap_or_null_ok [] {
    let result = 42 | ok | result unwrap-or null
    assert equal $result 42
}

# [test] Result unwrap-or null converts err to null
def test_monad_result_unwrap_or_null_err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result unwrap-or null
    assert equal $result null
}

# =============================================================================
# SEQUENCE TESTS
# =============================================================================

# [test] Sequence-option collects all some values
def test_monad_sequence_option_all_some [] {
    let options = [1, 2, 3] | each { some }
    let result = $options | option sequence
    assert equal $result.type "some"
    assert equal $result.value [1, 2, 3]
}

# [test] Sequence-option returns none if any none
def test_monad_sequence_option_with_none [] {
    let options = [
        (1 | some),
        (none),
        (3 | some)
    ]
    let result = $options | option sequence
    assert equal $result.type "none"
}

# [test] Sequence-option handles empty list
def test_monad_sequence_option_empty [] {
    let options = []
    let result = $options | option sequence
    assert equal $result.type "some"
    assert equal $result.value []
}

# [test] Sequence-result collects all ok values
def test_monad_sequence_result_all_ok [] {
    let results = [1, 2, 3] | each { ok }
    let result = $results | result sequence
    assert equal $result.type "ok"
    assert equal $result.value [1, 2, 3]
}

# [test] Sequence-result returns first error
def test_monad_sequence_result_with_err [] {
    let results = [
        (1 | ok),
        ("data" | result safely { error make {msg: "failed"} }),
        (3 | ok)
    ]
    let result = $results | result sequence
    assert equal $result.type "err"
    assert equal $result.error.msg "failed"
}

# [test] Sequence-result handles empty list
def test_monad_sequence_result_empty [] {
    let results = []
    let result = $results | result sequence
    assert equal $result.type "ok"
    assert equal $result.value []
}

# =============================================================================
# TRAVERSE TESTS
# =============================================================================

# [test] Traverse-option succeeds with all some
def test_monad_traverse_option_success [] {
    let result = [1, 2, 3] | option traverse { $in * 2 | some }
    assert equal $result.type "some"
    assert equal $result.value [2, 4, 6]
}

# [test] Traverse-option fails with any none
def test_monad_traverse_option_failure [] {
    let result = [1, 2, 3] | option traverse {
        if $in == 2 { none } else { $in * 2 | some }
    }
    assert equal $result.type "none"
}

# [test] Traverse-result succeeds with all ok
def test_monad_traverse_result_success [] {
    let result = [1, 2, 3] | result traverse { $in * 2 | ok }
    assert equal $result.type "ok"
    assert equal $result.value [2, 4, 6]
}

# [test] Traverse-result fails with any err
def test_monad_traverse_result_failure [] {
    let result = [1, 2, 3] | result traverse {
        if $in == 2 { result safely { error make {msg: "failed"} } } else { $in * 2 | result ok }
    }
    assert equal $result.type "err"
    assert equal $result.error.msg "failed"
}

# =============================================================================
# UTILITY TESTS
# =============================================================================

# [test] Try-option captures successful operation
def test_monad_try_option_success [] {
    let result = option attempt { 42 + 8 }
    assert equal $result.type "some"
    assert equal $result.value 50
}

# [test] Try-option captures failed operation
def test_monad_try_option_failure [] {
    let result = option attempt { "abc" | into int }
    assert equal $result.type "none"
}


# =============================================================================
# COMBINATOR TESTS
# =============================================================================

# [test] Map2 combines two some values
def test_monad_map2_option_both_some [] {
    let opt1 = 1 | some
    let opt2 = 2 | some
    let result = option map2 {|a, b| $a + $b } $opt1 $opt2
    assert equal $result.type "some"
    assert equal $result.value 3
}

# [test] Map2 returns none if first none
def test_monad_map2_option_first_none [] {
    let opt1 = none
    let opt2 = 2 | some
    let result = option map2 {|a, b| $a + $b } $opt1 $opt2
    assert equal $result.type "none"
}

# [test] Map2 returns none if second none
def test_monad_map2_option_second_none [] {
    let opt1 = 1 | some
    let opt2 = none
    let result = option map2 {|a, b| $a + $b } $opt1 $opt2
    assert equal $result.type "none"
}

# [test] Map2 combines two ok values
def test_monad_map2_result_both_ok [] {
    let res1 = 1 | ok
    let res2 = 2 | ok
    let result = result map2 {|a, b| $a + $b } $res1 $res2
    assert equal $result.type "ok"
    assert equal $result.value 3
}

# [test] Map2 returns first error
def test_monad_map2_result_first_err [] {
    let res1 = "data" | result safely { error make {msg: "failed"} }
    let res2 = 2 | ok
    let result = result map2 {|a, b| $a + $b } $res1 $res2
    assert equal $result.type "err"
    assert equal $result.error.msg "failed"
}

# [test] Map2 returns first error encountered
def test_monad_map2_result_second_err [] {
    let res1 = 1 | ok
    let res2 = "data" | result safely { error make {msg: "failed"} }
    let result = result map2 {|a, b| $a + $b } $res1 $res2
    assert equal $result.type "err"
    assert equal $result.error.msg "failed"
}

# [test] Map2 prefers first of two errors
def test_monad_map2_result_both_err [] {
    let res1 = "data1" | result safely { error make {msg: "first error"} }
    let res2 = "data2" | result safely { error make {msg: "second error"} }
    let result = result map2 {|a, b| $a + $b } $res1 $res2
    assert equal $result.type "err"
    assert equal $result.error.msg "first error"  # Should return first error
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

# [test] Option-result round trip preserves value
def test_monad_option_result_round_trip [] {
    # Test Option -> Result -> Option
    let original = 42 | some
    let result = $original 
        | option-to-result "no value"
        | result-to-option
    
    assert equal $result.type "some"
    assert equal $result.value 42
}

# [test] Result-option round trip preserves value
def test_monad_result_option_round_trip [] {
    # Test Result -> Option -> Result
    let original = 42 | ok
    let result = $original 
        | result-to-option
        | option-to-result "converted back"
    
    assert equal $result.type "ok"
    assert equal $result.value 42
}

# [test] Parse numbers sequence succeeds
def test_monad_parse_numbers_sequence [] {
    # Test parsing a list of strings to numbers
    let strings = ["1", "2", "3"]
    let result = $strings | result traverse {
        result safely { into int }
    }

    assert equal $result.type "ok"
    assert equal $result.value [1, 2, 3]
}

# [test] Parse numbers with failure returns error
def test_monad_parse_numbers_with_failure [] {
    # Test parsing with one failure
    let strings = ["1", "abc", "3"]
    let result = $strings | result traverse {
        result safely { into int }
    }

    assert equal $result.type "err"
    # Should have error from "abc" conversion
    assert (($result.error.msg | str length) > 0)
}

# [test] Optional fields sequence extracts all values
def test_monad_optional_fields_sequence [] {
    # Test extracting optional fields from records
    let records = [
        {name: "Alice", age: 30},
        {name: "Bob", age: 25},
        {name: "Charlie", age: 35}
    ]
    
    let result = $records | option traverse {
        option attempt { $in.age }
    }
    
    assert equal $result.type "some"
    assert equal $result.value [30, 25, 35]
}

# [test] Optional fields with missing returns none
def test_monad_optional_fields_with_missing [] {
    # Test with missing field
    let records = [
        {name: "Alice", age: 30},
        {name: "Bob"},  # Missing age
        {name: "Charlie", age: 35}
    ]
    
    let result = $records | option traverse {
        option attempt { $in.age }
    }
    
    assert equal $result.type "none"
}