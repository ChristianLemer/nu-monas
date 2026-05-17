#
# Test df types function
#
use std/assert
use ../../df

# ============================================================
# Test Functions
# ============================================================

# [test] analyzes types across multiple records
def test-df-types-basic [] {
    # Arrange
    let input = [
        {name: "Alice", age: 30, active: true},
        {name: "Bob", age: "25", active: false},
        {name: null, age: 35, active: null}
    ]
    
    # Act
    let result = ($input | df types)
    
    # Assert
    assert equal ($result | length) 3
    
    # Extract type information for each column
    let name_types = ($result | where column == "name" | get 0 | get types | sort)
    let age_types = ($result | where column == "age" | get 0 | get types | sort)
    let active_types = ($result | where column == "active" | get 0 | get types | sort)
    
    # Verify type combinations
    assert equal $name_types [nothing, string]
    assert equal $age_types [int, string]
    assert equal $active_types [bool, nothing]
}

# [test] handles empty input gracefully
def test-df-types-empty [] {
    # Act & Assert
    let result = ([] | df types)
    assert equal $result []
}

# [test] analyzes multiple columns each with uniform single type
def test-df-types-uniform [] {
    # Arrange
    let input = [
        {score: 85, name: "Alice", active: true, created: 2024-01-15},
        {score: 92, name: "Bob", active: false, created: 2024-01-16}, 
        {score: 78, name: "Charlie", active: true, created: 2024-01-17}
    ]
    
    # Act
    let result = ($input | df types)
    
    # Assert
    assert equal ($result | length) 4
    
    # Extract column analyses 
    let score_analysis = ($result | where column == "score" | get 0)
    let name_analysis = ($result | where column == "name" | get 0)
    let active_analysis = ($result | where column == "active" | get 0)
    let created_analysis = ($result | where column == "created" | get 0)
    
    # Verify uniform types
    assert equal $score_analysis.types ["int"]
    assert equal $name_analysis.types ["string"]
    assert equal $active_analysis.types ["bool"]
    assert equal $created_analysis.types ["datetime"]
}

# [test] handles missing columns in type analysis (records with heterogeneous structure)
def test-df-types-missing-values [] {
    # Arrange
    let input = [
        {id: 1, name: "Alice"},
        {id: 2, email: "bob@test.com"},
        {id: 3, name: "Charlie", email: "charlie@test.com"}
    ]
    
    # Act
    let result = ($input | df types)
    
    # Assert - missing columns create nothing types
    assert equal ($result | length) 3
    
    # Extract type information
    let name_types = ($result | where column == "name" | get 0 | get types | sort)
    
    # Verify missing columns create nothing types
    assert equal $name_types [nothing, string]
}

# [test] comprehensive null value handling in df types
def test-df-types-null-integration [] {
    # Arrange - data with explicit null values
    let input = [
        {subject: "TST1", value: 42, notes: "first", active: true},
        {subject: "TST2", value: null, notes: "second", active: false},
        {subject: null, value: 55, notes: null, active: null}
    ]
    
    # Act
    let result = ($input | df types)
    
    # Assert - verify null handling across all columns
    assert equal ($result | length) 4
    
    # Extract type information for each column
    let subject_types = ($result | where column == "subject" | get 0 | get types | sort)
    let value_types = ($result | where column == "value" | get 0 | get types | sort)
    let notes_types = ($result | where column == "notes" | get 0 | get types | sort)
    let active_types = ($result | where column == "active" | get 0 | get types | sort)
    
    # Verify null handling creates nothing types
    assert equal $subject_types [nothing, string]
    assert equal $value_types [int, nothing]
    assert equal $notes_types [nothing, string]
    assert equal $active_types [bool, nothing]
}
