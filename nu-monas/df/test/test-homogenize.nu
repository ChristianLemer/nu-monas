#
# Test df homogenize function
#
use std/assert
use .. [homogenize]

# ============================================================
# Test Helper Functions
# ============================================================

# Create test DataFrame with missing columns
def create-irregular-df [] {
    [
        {name: "Alice", age: 30},
        {name: "Bob", city: "NYC"},
        {name: "Charlie", age: 25, city: "Boston", country: "USA"}
    ]
}

# Create test DataFrame with all same columns
def create-regular-df [] {
    [
        {name: "Alice", age: 30, city: "Boston"},
        {name: "Bob", age: 25, city: "NYC"},
        {name: "Charlie", age: 35, city: "LA"}
    ]
}

# Assert that all records have the same columns
def assert-homogeneous-structure [expected_columns: list] {
    let data = $in
    
    # Check that all records have exactly the expected columns
    $data | each { |record|
        let record_columns = ($record | columns | sort)
        assert equal $record_columns ($expected_columns | sort)
    }
}

# Assert that a specific record has expected values (including nulls)
def assert-record-values [index: int, expected_values: record] {
    let data = $in
    let record = ($data | get $index)
    
    $expected_values | items { |key, expected_value|
        let actual_value = ($record | get $key)
        assert equal $actual_value $expected_value
    }
}

# ============================================================
# Test Functions
# ============================================================

# [test] homogenizes records with missing columns by adding nulls
def test-homogenize-missing-columns [] {
    let input = (create-irregular-df)
    let result = ($input | homogenize)
    
    # Should have 3 records
    assert equal ($result | length) 3
    
    # All records should have all columns that appear in any record
    let expected_columns = ["age", "city", "country", "name"]
    $result | assert-homogeneous-structure $expected_columns
    
    # Check specific values and nulls
    $result | assert-record-values 0 {name: "Alice", age: 30, city: null, country: null}
    $result | assert-record-values 1 {name: "Bob", age: null, city: "NYC", country: null}
    $result | assert-record-values 2 {name: "Charlie", age: 25, city: "Boston", country: "USA"}
}

# [test] preserves already homogeneous data unchanged
def test-homogenize-already-regular [] {
    let input = (create-regular-df)
    let result = ($input | homogenize)
    
    # Should be identical to input
    assert equal $result $input
    
    # All records should have same columns
    let expected_columns = ["age", "city", "name"]
    $result | assert-homogeneous-structure $expected_columns
}

# [test] handles empty input gracefully
def test-homogenize-empty-input [] {
    let empty_df = []
    let result = ($empty_df | homogenize)
    
    assert equal $result []
}

# [test] handles single record input
def test-homogenize-single-record [] {
    let input = [{name: "Alice", age: 30, city: "Boston"}]
    let result = ($input | homogenize)
    
    # Should be identical to input (already homogeneous)
    assert equal $result $input
    assert equal ($result | length) 1
    
    let expected_columns = ["age", "city", "name"]
    $result | assert-homogeneous-structure $expected_columns
}

# [test] uses explicit column list when provided
def test-homogenize-explicit-columns [] {
    let input = [
        {name: "Alice", age: 30, extra: "data"},
        {name: "Bob", city: "NYC"}
    ]
    
    # Only homogenize to specific columns
    let columns = ["name", "age", "city"]
    let result = ($input | homogenize $columns)
    
    # Should have 2 records with only the specified columns
    assert equal ($result | length) 2
    $result | assert-homogeneous-structure $columns
    
    # Check values - extra column should be ignored
    $result | assert-record-values 0 {name: "Alice", age: 30, city: null}
    $result | assert-record-values 1 {name: "Bob", age: null, city: "NYC"}
}

# [test] handles explicit empty column list
def test-homogenize-empty-columns [] {
    let input = [
        {name: "Alice", age: 30},
        {name: "Bob", city: "NYC"}
    ]
    
    let result = ($input | homogenize [])
    
    # Should return records with no columns (empty records)
    assert equal ($result | length) 2
    $result | each { |record|
        assert equal ($record | columns) []
    }
}

# [test] preserves data types correctly
def test-homogenize-preserves-types [] {
    let input = [
        {name: "Alice", age: 30, score: 95.5, active: true},
        {name: "Bob", extra: "data"},
        {name: "Charlie", age: 25, score: null, active: false}
    ]
    
    let result = ($input | homogenize)
    
    # Check that non-null values preserve their types
    let alice = ($result | get 0)
    assert equal ($alice.age | describe) "int"
    assert equal ($alice.score | describe) "float"
    assert equal ($alice.active | describe) "bool"
    
    let bob = ($result | get 1)
    assert equal ($bob.name | describe) "string"
    assert equal ($bob.age | describe) "nothing"  # null
    assert equal ($bob.extra | describe) "string"
    
    let charlie = ($result | get 2)
    assert equal ($charlie.age | describe) "int"
    assert equal ($charlie.score | describe) "nothing"  # null
    assert equal ($charlie.active | describe) "bool"
}

# [test] handles records with completely different column sets
def test-homogenize-disjoint-columns [] {
    let input = [
        {a: 1, b: 2},
        {c: 3, d: 4},
        {e: 5, f: 6}
    ]
    
    let result = ($input | homogenize)
    
    # Should have all 6 columns in each record
    let expected_columns = ["a", "b", "c", "d", "e", "f"]
    $result | assert-homogeneous-structure $expected_columns
    
    # Check that original values are preserved and missing are null
    $result | assert-record-values 0 {a: 1, b: 2, c: null, d: null, e: null, f: null}
    $result | assert-record-values 1 {a: null, b: null, c: 3, d: 4, e: null, f: null}
    $result | assert-record-values 2 {a: null, b: null, c: null, d: null, e: 5, f: 6}
}

# [test] handles null values in original data
def test-homogenize-with-existing-nulls [] {
    let input = [
        {name: "Alice", age: 30, city: null},
        {name: "Bob", age: null, city: "NYC"},
        {name: "Charlie", country: "USA"}
    ]
    
    let result = ($input | homogenize)
    
    let expected_columns = ["age", "city", "country", "name"]
    $result | assert-homogeneous-structure $expected_columns
    
    # Original nulls should be preserved
    $result | assert-record-values 0 {name: "Alice", age: 30, city: null, country: null}
    $result | assert-record-values 1 {name: "Bob", age: null, city: "NYC", country: null}
    $result | assert-record-values 2 {name: "Charlie", age: null, city: null, country: "USA"}
}