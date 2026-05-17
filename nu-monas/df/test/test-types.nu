#
# Test df types function
#
use std/assert
use ../../df [types]

# ============================================================
# Test Helper Functions
# ============================================================

# Create test DataFrame with uniform types per column
def create-uniform-df [] {
    [
        {name: "Alice", age: 30, active: true},
        {name: "Bob", age: 25, active: false},
        {name: "Charlie", age: 35, active: true}
    ]
}

# Create test DataFrame with mixed types per column
def create-mixed-df [] {
    [
        {name: "Alice", age: 30, score: 95.5},
        {name: "Bob", age: "25", score: 87},
        {name: "Charlie", age: null, score: "92.0"}
    ]
}

# Extract column analysis for assertions
def get-column-analysis [data: any, column_name: string] {
    $data | where column == $column_name | get 0
}

# Assert specific column type patterns
def assert-column-types [data: any, column: string, expected_types: list] {
    let analysis = (get-column-analysis $data $column)
    assert equal $analysis.types $expected_types
}

# ============================================================
# Test Functions
# ============================================================

# [test] analyzes multiple columns each with uniform single type
def test-types-uniform-columns [] {
    let input = (create-uniform-df)
    let result = ($input | types)
    
    # Should have analysis for all 3 columns
    assert equal ($result | length) 3
    
    # Check each column has single type
    assert-column-types $result "name" ["string"]
    assert-column-types $result "age" ["int"]
    assert-column-types $result "active" ["bool"]
}

# [test] analyzes columns with mixed types
def test-types-mixed-columns [] {
    let input = (create-mixed-df)
    let result = ($input | types)
    
    # Should have analysis for all 3 columns
    assert equal ($result | length) 3
    
    # Name column should be uniform
    assert-column-types $result "name" ["string"]
    
    # Age column should have mixed types (int, string, nothing)
    let age_analysis = (get-column-analysis $result "age")
    let age_types = ($age_analysis.types | sort)
    assert equal $age_types ["int", "nothing", "string"]
    
    # Score column should have mixed types (float, int, string)
    let score_analysis = (get-column-analysis $result "score")
    let score_types = ($score_analysis.types | sort)
    assert equal $score_types ["float", "int", "string"]
}

# [test] handles empty input gracefully
def test-types-empty-input [] {
    let empty_df = []
    let result = ($empty_df | types)
    
    # Should return empty list for empty input
    assert equal $result []
}

# [test] handles records with missing columns
def test-types-missing-columns [] {
    let input = [
        {name: "Alice", age: 30},
        {name: "Bob", city: "NYC"},
        {name: "Charlie", age: 25, city: "Boston"}
    ]
    
    let result = ($input | types)
    
    # Should analyze all columns that appear in any record
    assert equal ($result | length) 3
    
    # Name appears in all records
    assert-column-types $result "name" ["string"]
    
    # Age appears in some records, missing in others (creates null)
    let age_analysis = (get-column-analysis $result "age")
    let age_types = ($age_analysis.types | sort)
    assert equal $age_types ["int", "nothing"]
    
    # City appears in some records, missing in others
    let city_analysis = (get-column-analysis $result "city")
    let city_types = ($city_analysis.types | sort)
    assert equal $city_types ["nothing", "string"]
}

# [test] handles single record input
def test-types-single-record [] {
    let input = [{name: "Alice", age: 30, score: 95.5}]
    let result = ($input | types)
    
    assert equal ($result | length) 3
    assert-column-types $result "name" ["string"]
    assert-column-types $result "age" ["int"]
    assert-column-types $result "score" ["float"]
}

# [test] handles single column DataFrame
def test-types-single-column [] {
    let input = [
        {value: 1},
        {value: "two"},
        {value: 3.0}
    ]
    
    let result = ($input | types)
    
    assert equal ($result | length) 1
    let value_analysis = (get-column-analysis $result "value")
    let value_types = ($value_analysis.types | sort)
    assert equal $value_types ["float", "int", "string"]
}

# [test] handles all-null column
def test-types-all-null-column [] {
    let input = [
        {name: "Alice", missing: null},
        {name: "Bob", missing: null},
        {name: "Charlie", missing: null}
    ]
    
    let result = ($input | types)
    
    assert equal ($result | length) 2
    assert-column-types $result "name" ["string"]
    assert-column-types $result "missing" ["nothing"]
}

# [test] handles complex nested data types
def test-types-complex-types [] {
    let input = [
        {data: [1, 2, 3], meta: {version: 1}},
        {data: "string", meta: {version: 2}},
        {data: 42, meta: null}
    ]
    
    let result = ($input | types)
    
    assert equal ($result | length) 2
    
    # Data column has mixed types
    let data_analysis = (get-column-analysis $result "data")
    let data_types = ($data_analysis.types | sort)
    assert equal $data_types ["int", "list<int>", "string"]
    
    # Meta column has mixed types
    let meta_analysis = (get-column-analysis $result "meta")
    let meta_types = ($meta_analysis.types | sort)
    assert equal $meta_types ["nothing", "record<version: int>"]
}