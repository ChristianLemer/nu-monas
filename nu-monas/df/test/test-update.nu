#
# Test df update function
#
use std/assert
use .. [update]

# ============================================================
# Test Helper Functions
# ============================================================

# Create test DataFrame
def create-test-df [] {
    [
        {name: "Alice", age: 30, score: 95.5},
        {name: "Bob", age: 25, score: 87.2},
        {name: "Charlie", age: null, score: 92.0}
    ]
}

# ============================================================
# Test Functions
# ============================================================

# [test] applies string length transformation to all cells
def test-update-string-length [] {
    let input = [
        {name: "Alice", city: "Boston"},
        {name: "Bob", city: "NYC"}
    ]
    
    let result = ($input | update {|x| $x | describe})
    
    # Check structure preserved
    assert equal ($result | length) 2
    assert equal ($result | columns | sort) ["city", "name"]
    
    # Check transformations - all should be "string"
    let record1 = ($result | get 0)
    assert equal $record1.name "string"
    assert equal $record1.city "string"
    
    let record2 = ($result | get 1)
    assert equal $record2.name "string"
    assert equal $record2.city "string"
}

# [test] applies numeric doubling to all cells
def test-update-double-numbers [] {
    let input = [
        {a: 10, b: 20},
        {a: 5, b: 15}
    ]
    
    let result = ($input | update { |x| $x * 2 })
    
    # Check structure preserved
    assert equal ($result | length) 2
    assert equal ($result | columns | sort) ["a", "b"]
    
    # Check transformations
    let record1 = ($result | get 0)
    assert equal $record1.a 20
    assert equal $record1.b 40
    
    let record2 = ($result | get 1)
    assert equal $record2.a 10
    assert equal $record2.b 30
}

# [test] handles null values in transformation
def test-update-with-nulls [] {
    let input = [
        {value: 10, optional: null},
        {value: 20, optional: 5}
    ]
    
    let result = ($input | update {|x| 
        if $x == null { 
            "NULL" 
        } else { 
            $x | into string 
        }
    })
    
    # Check null handling
    let record1 = ($result | get 0)
    assert equal $record1.value "10"
    assert equal $record1.optional "NULL"
    
    let record2 = ($result | get 1)
    assert equal $record2.value "20"
    assert equal $record2.optional "5"
}

# [test] applies type conversion to all cells
def test-update-type-conversion [] {
    let input = [
        {number: 42, text: "hello"},
        {number: 0, text: "world"}
    ]
    
    let result = ($input | update { |x| $x | describe })
    
    # All cells should now contain their type descriptions
    let record1 = ($result | get 0)
    assert equal $record1.number "int"
    assert equal $record1.text "string"
    
    let record2 = ($result | get 1)
    assert equal $record2.number "int"
    assert equal $record2.text "string"
}

# [test] preserves DataFrame structure with simple transformation
def test-update-complex-transformation [] {
    let input = (create-test-df)
    
    let result = ($input | update {|x| $x | describe})
    
    # Check structure preserved
    assert equal ($result | length) 3
    assert equal ($result | columns | sort) ["age", "name", "score"]
    
    # Check transformations - should show types
    let record1 = ($result | get 0)
    assert equal $record1.name "string"
    assert equal $record1.age "int"
    assert equal $record1.score "float"
}

# [test] handles empty DataFrame
def test-update-empty-dataframe [] {
    let empty_df = []
    let result = ($empty_df | update { |x| $x | into string })
    
    assert equal $result []
}

# [test] handles single-row DataFrame
def test-update-single-row [] {
    let input = [{value: 42}]
    let result = ($input | update { |x| $x * 2 })
    
    assert equal ($result | length) 1
    assert equal (($result | get 0).value) 84
}

# [test] handles single-column DataFrame
def test-update-single-column [] {
    let input = [
        {data: "a"},
        {data: "b"},
        {data: "c"}
    ]
    
    let result = ($input | update { |x| $x | str upcase })
    
    assert equal ($result | length) 3
    assert equal ($result | columns) ["data"]
    
    let values = ($result | get data)
    assert equal $values ["A", "B", "C"]
}