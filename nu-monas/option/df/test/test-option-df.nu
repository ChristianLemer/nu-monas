#
# Test option df functions
#
use std/assert
use ../../../option/df [when-not unwrap-or]
use ../../../option [some none]

# ============================================================
# Test Helper Functions
# ============================================================

# Create test DataFrame with mixed types
def create-test-df [] {
    [
        {name: "Alice", age: 30, status: "active"},
        {name: "Bob", age: null, status: "inactive"},
        {name: "Charlie", age: 25, status: null}
    ]
}

# Create Option DataFrame manually for comparison
def create-option-df [] {
    [
        {name: ("Alice" | some), age: (30 | some), status: ("active" | some)},
        {name: ("Bob" | some), age: (none), status: ("inactive" | some)},
        {name: ("Charlie" | some), age: (25 | some), status: (none)}
    ]
}

# Assert that a value is a proper Option type
def assert-option [expected_type: string, expected_value?: any] {
    let option = $in
    assert equal $option.type $expected_type
    
    if $expected_type == "some" and $expected_value != null {
        assert equal $option.value $expected_value
    }
}

# ============================================================
# Test Functions
# ============================================================

# [test] converts regular DataFrame to Option DataFrame with null as empty
def test-when-not-null [] {
    let input = [
        {name: "Alice", age: 30, status: "active"},
        {name: "Bob", age: null, status: "inactive"},
        {name: "Charlie", age: 25, status: null}
    ]
    let result = ($input | when-not null)
    
    # Check structure is preserved
    assert equal ($result | length) 3
    assert equal ($result | columns | sort) ["age", "name", "status"]
    
    # Check first record - all Some values
    let record1 = ($result | get 0)
    $record1.name | assert-option "some" "Alice"
    $record1.age | assert-option "some" 30
    $record1.status | assert-option "some" "active"
    
    # Check second record - age is None
    let record2 = ($result | get 1)
    $record2.name | assert-option "some" "Bob"
    $record2.age | assert-option "none"
    $record2.status | assert-option "some" "inactive"
    
    # Check third record - status is None
    let record3 = ($result | get 2)
    $record3.name | assert-option "some" "Charlie"
    $record3.age | assert-option "some" 25
    $record3.status | assert-option "none"
}

# [test] converts regular DataFrame to Option DataFrame with empty string as empty
def test-when-not-empty-string [] {
    let input = [
        {name: "Alice", note: "important"},
        {name: "Bob", note: ""},
        {name: "Charlie", note: "draft"}
    ]
    
    let result = ($input | when-not "")
    
    # Check first record
    let record1 = ($result | get 0)
    $record1.name | assert-option "some" "Alice"
    $record1.note | assert-option "some" "important"
    
    # Check second record - note should be None
    let record2 = ($result | get 1)
    $record2.name | assert-option "some" "Bob"
    $record2.note | assert-option "none"
    
    # Check third record
    let record3 = ($result | get 2)
    $record3.name | assert-option "some" "Charlie"
    $record3.note | assert-option "some" "draft"
}

# [test] unwraps Option DataFrame back to regular DataFrame
def test-unwrap-or-default [] {
    let input = (create-option-df)
    let result = ($input | unwrap-or "N/A")
    
    # Check structure is preserved
    assert equal ($result | length) 3
    assert equal ($result | columns | sort) ["age", "name", "status"]
    
    # Check first record - all values unwrapped
    let record1 = ($result | get 0)
    assert equal $record1.name "Alice"
    assert equal $record1.age 30
    assert equal $record1.status "active"
    
    # Check second record - None becomes default
    let record2 = ($result | get 1)
    assert equal $record2.name "Bob"
    assert equal $record2.age "N/A"  # None became default
    assert equal $record2.status "inactive"
    
    # Check third record - None becomes default
    let record3 = ($result | get 2)
    assert equal $record3.name "Charlie"
    assert equal $record3.age 25
    assert equal $record3.status "N/A"  # None became default
}

# [test] round-trip conversion preserves data structure
def test-round-trip-conversion [] {
    let original = (create-test-df)
    
    # Convert to Options and back with null default
    let round_trip = ($original | when-not null | unwrap-or null)
    
    # Should have same structure
    assert equal ($round_trip | columns | sort) ($original | columns | sort)
    assert equal ($round_trip | length) ($original | length)
    
    # Content should be identical (null values remain null)
    assert equal $round_trip $original
}

# [test] handles empty DataFrame
def test-empty-dataframe [] {
    let empty_df = []
    
    let result_when_not = ($empty_df | when-not null)
    assert equal $result_when_not []
    
    let result_unwrap = ($empty_df | unwrap-or "default")
    assert equal $result_unwrap []
}

# [test] unwrap-or with different default types
def test-unwrap-or-different-defaults [] {
    let option_df = [
        {value: ("test" | some), number: (none)},
        {value: (none), number: (42 | some)}
    ]
    
    # Test with numeric default
    let result_numeric = ($option_df | unwrap-or 0)
    assert equal ($result_numeric | get 0 | get number) 0
    assert equal ($result_numeric | get 1 | get value) 0
    
    # Test with string default  
    let result_string = ($option_df | unwrap-or "missing")
    assert equal ($result_string | get 0 | get number) "missing"
    assert equal ($result_string | get 1 | get value) "missing"
}

# ============================================================
# Error Handling Tests
# ============================================================

# [test] rejects invalid Option structures with clear errors
def test-invalid-option-structures [] {
    let invalid_df = [
        {value: {type: "invalid", data: "test"}},
        {value: {type: "some"}}  # Missing value field
    ]
    
    # when-not should still work since it creates new Options
    let result_when_not = ($invalid_df | when-not null)
    assert equal ($result_when_not | length) 2
    
    # unwrap-or should error on invalid Option structures
    try {
        $invalid_df | unwrap-or "DEFAULT"
        error make {msg: "Expected error but unwrap-or succeeded"}
    } catch {|e|
        # Error is wrapped in "Eval block failed", check the raw error
        assert ($e | describe | str contains "error")
    }
}

# [test] rejects mixed Option and non-Option data
def test-mixed-option-non-option [] {
    let mixed_df = [
        {option_col: ("value" | some), regular_col: "regular"},
        {option_col: (none), regular_col: 42}
    ]
    
    # when-not creates Options from all values
    let result_when_not = ($mixed_df | when-not null)
    ($result_when_not | get 0 | get regular_col) | assert-option "some" "regular"
    ($result_when_not | get 1 | get regular_col) | assert-option "some" 42
    
    # unwrap-or should error on non-Option values
    try {
        $mixed_df | unwrap-or "N/A"
        error make {msg: "Expected error but unwrap-or succeeded"}
    } catch {|e|
        # Error is wrapped in "Eval block failed", check the raw error
        assert ($e | describe | str contains "error")
    }
}

# [test] rejects malformed Option records
def test-malformed-option-records [] {
    let malformed_df = [
        {data: {type: "some", value: "good"}},
        {data: {type: "some", wrong_field: "bad"}},  # Wrong field name
        {data: {different: "structure"}}             # Completely wrong
    ]
    
    # unwrap-or should error on malformed Option structures
    try {
        $malformed_df | unwrap-or "FALLBACK"
        error make {msg: "Expected error but unwrap-or succeeded"}
    } catch {|e|
        # Error is wrapped in "Eval block failed", check the raw error
        assert ($e | describe | str contains "error")
    }
}

# [test] handles Option with null values in DataFrame  
def test-option-with-null-values [] {
    let null_df = [
        {value: null},        # Regular null value
        {value: "test"}       # Regular string value for comparison
    ]
    
    # when-not null should convert null to None, string to Some
    let result_when_not = ($null_df | when-not null)
    ($result_when_not | get 0 | get value) | assert-option "none"
    ($result_when_not | get 1 | get value) | assert-option "some" "test"
    
    # unwrap-or should use default for None values
    let result_unwrap = ($result_when_not | unwrap-or "DEFAULT")
    assert equal ($result_unwrap | get 0 | get value) "DEFAULT"
    assert equal ($result_unwrap | get 1 | get value) "test"
}

# ============================================================
# Edge Case Tests  
# ============================================================

# [test] handles single-cell DataFrame
def test-single-cell-dataframe [] {
    let single_cell = [{value: ("test" | some)}]
    
    let result_unwrap = ($single_cell | unwrap-or "DEFAULT")
    assert equal ($result_unwrap | length) 1
    assert equal (($result_unwrap | get 0).value) "test"
    
    let result_when_not = ($single_cell | when-not "empty")
    assert equal ($result_when_not | length) 1
    ($result_when_not | get 0 | get value) | assert-option "some"
}

# [test] handles DataFrame with deeply nested structures
def test-nested-structures [] {
    let nested_df = [
        {config: ({database: {host: "localhost", port: 5432}} | some)},
        {config: (none)}
    ]
    
    let result = ($nested_df | unwrap-or {database: {host: "default", port: 3306}})
    assert equal ($result | get 0 | get config | get database | get host) "localhost"
    assert equal ($result | get 1 | get config | get database | get host) "default"
}

# [test] handles very large column names
def test-large-column-names [] {
    let long_name = ("very_long_column_name_that_exceeds_normal_length_" + (0..100 | each { "x" } | str join))
    let df_data = [{$long_name: ("value" | some)}]
    
    let result = ($df_data | unwrap-or "DEFAULT")
    assert equal ($result | length) 1
    assert equal ($result | get 0 | get $long_name) "value"
}

# [test] handles special characters in values
def test-special-characters [] {
    let special_df = [
        {text: ("unicode: 🚀 ñ ü" | some)},
        {text: ("newlines:\nand\ttabs" | some)},
        {text: ("quotes: \"'`" | some)}
    ]
    
    let result = ($special_df | unwrap-or "DEFAULT")
    assert equal ($result | get 0 | get text) "unicode: 🚀 ñ ü"
    assert equal ($result | get 1 | get text) "newlines:\nand\ttabs"
    assert equal ($result | get 2 | get text) "quotes: \"'`"
}

# [test] handles when-not with complex comparison values
def test-when-not-complex-values [] {
    let complex_df = [
        {data: [1, 2, 3]},
        {data: []},
        {data: {key: "value"}},
        {data: {}}
    ]
    
    # Test with empty list as empty value
    let result_empty_list = ($complex_df | when-not [])
    ($result_empty_list | get 0 | get data) | assert-option "some"
    ($result_empty_list | get 1 | get data) | assert-option "none"
    
    # Test with empty record as empty value  
    let result_empty_record = ($complex_df | when-not {})
    ($result_empty_record | get 2 | get data) | assert-option "some"
    ($result_empty_record | get 3 | get data) | assert-option "none"
}

# [test] handles DataFrame with many columns
def test-many-columns [] {
    let wide_df = [
        {
            col1: ("a" | some), col2: ("b" | some), col3: ("c" | some),
            col4: (none), col5: ("e" | some), col6: (none),
            col7: ("g" | some), col8: ("h" | some), col9: (none), col10: ("j" | some)
        }
    ]
    
    let result = ($wide_df | unwrap-or "MISSING")
    assert equal ($result | length) 1
    assert equal ($result | columns | length) 10
    assert equal (($result | get 0).col1) "a"
    assert equal (($result | get 0).col4) "MISSING"
    assert equal (($result | get 0).col10) "j"
}

# [test] handles extreme default values
def test-extreme-defaults [] {
    let option_df = [{value: (none)}]
    
    # Test with very large number as default
    let large_num = 999999999999999999
    let result_large = ($option_df | unwrap-or $large_num)
    assert equal (($result_large | get 0).value) $large_num
    
    # Test with complex structure as default
    let complex_default = {nested: {deep: {value: "buried"}}, list: [1, 2, 3]}
    let result_complex = ($option_df | unwrap-or $complex_default)
    assert equal (($result_complex | get 0).value.nested.deep.value) "buried"
    assert equal (($result_complex | get 0).value.list) [1, 2, 3]
}