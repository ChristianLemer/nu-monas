#
# Test df homogenize function
#
use std/assert
use ../../df

# ============================================================
# Test Functions  
# ============================================================

# [test] homogenizes records with heterogeneous columns and preserves all value types
def test-homogenize-preserves-all-values [] {
    # Arrange
    let input = [
        {name: "Alice", date: "2024-01-01", value: ""}
        {name: "", date: "2024-01-02", value: "test"}
        {name: "Bob", date: "", value: ""}
    ]
    
    # Act
    let result = $input | df homogenize
    
    # Assert - structure and value preservation including empty strings
    assert equal ($result | length) 3
    assert equal ($result | columns | sort) ["date", "name", "value"]
    
    # Extract record data
    let record0 = ($result | get 0)
    let record1 = ($result | get 1)
    let record2 = ($result | get 2)
    
    # Verify value preservation including empty strings
    assert equal ($record0 | get name) "Alice"
    assert equal ($record0 | get date) "2024-01-01"
    assert equal ($record0 | get value) ""
    assert equal ($record1 | get name) ""
    assert equal ($record1 | get value) "test"
    assert equal ($record2 | get name) "Bob"
    assert equal ($record2 | get date) ""
    assert equal ($record2 | get value) ""
}

# [test] homogenizes records with mixed data types including nulls
def test-homogenize-mixed-types [] {
    # Arrange
    let input = [
        {id: 1, date: "2024-01-01", notes: ""}
        {id: 2, date: "", notes: "important"}
        {id: 3, date: "2024-01-03", notes: null}
    ]
    
    # Act
    let result = $input | df homogenize
    
    # Assert - structure and mixed type preservation
    assert equal ($result | length) 3
    assert equal ($result | columns | sort) ["date", "id", "notes"]
    
    # Extract record data
    let record0 = ($result | get 0)
    let record1 = ($result | get 1)
    let record2 = ($result | get 2)
    
    # Verify mixed type and null preservation
    assert equal ($record0 | get id) 1
    assert equal ($record0 | get date) "2024-01-01"
    assert equal ($record0 | get notes) ""
    assert equal ($record1 | get id) 2
    assert equal ($record1 | get date) ""
    assert equal ($record1 | get notes) "important"
    assert equal ($record2 | get id) 3
    assert equal ($record2 | get notes) null
}

# [test] homogenizes records with multiple types per column (3+ types)
def test-homogenize-multiple-types-per-column [] {
    # Arrange - data with varied types in each column
    let input = [
        {subject_id: "TST001", measurement: 85.5, status: "active"},
        {subject_id: 2, measurement: "below_threshold", status: true},
        {subject_id: null, measurement: null, status: null}
    ]
    
    # Act
    let result = ($input | df homogenize)
    
    # Assert - structure preserved
    assert equal ($result | length) 3
    assert equal ($result | columns | sort) [measurement, status, subject_id]
    
    # Extract type analysis for verification
    let type_analysis = ($result | df types)
    let subject_types = ($type_analysis | where column == "subject_id" | get 0 | get types | sort)
    let measurement_types = ($type_analysis | where column == "measurement" | get 0 | get types | sort)
    let status_types = ($type_analysis | where column == "status" | get 0 | get types | sort)
    
    # Verify type diversity maintained by checking df types integration
    assert equal $subject_types ["int", "nothing", "string"]
    assert equal $measurement_types ["float", "nothing", "string"]
    assert equal $status_types ["bool", "nothing", "string"]
}

# [test] homogenizes records with missing columns by adding nulls
def test-homogenize-missing-columns [] {
    # Arrange - records with different column sets
    let input = [
        {Subject: "TST1", Serial: 123},
        {Subject: "TST2", Kit: "RLV", Model: "X1"},
        {Subject: "TST3"}
    ]
    
    # Act
    let result = ($input | df homogenize)
    
    # Assert - all columns present, missing filled with nulls
    assert equal ($result | length) 3
    assert equal ($result | columns | sort) [Kit, Model, Serial, Subject]
    
    # Extract record data
    let record0 = ($result | get 0)
    let record1 = ($result | get 1)
    let record2 = ($result | get 2)
    
    # Verify missing columns filled with nulls
    assert equal ($record0 | get Subject) "TST1"
    assert equal ($record0 | get Serial) 123
    assert equal ($record0 | get Kit) null
    assert equal ($record1 | get Kit) "RLV"
    assert equal ($record1 | get Serial) null
    assert equal ($record2 | get Subject) "TST3"
    assert equal ($record2 | get Kit) null
}

# [test] handles empty input gracefully
def test-homogenize-empty-input [] {
    # Act & Assert
    let result = ([] | df homogenize)
    assert equal $result []
}

# [test] homogenizes single record without changes
def test-homogenize-single-record [] {
    # Arrange
    let input = [{Subject: "TST1", Serial: 123}]
    
    # Act
    let result = ($input | df homogenize)
    
    # Assert - single record unchanged
    assert equal ($result | length) 1
    assert equal ($result | columns | sort) [Serial, Subject]
    
    # Extract record data
    let record0 = ($result | get 0)
    
    # Verify single record unchanged
    assert equal ($record0 | get Subject) "TST1"
    assert equal ($record0 | get Serial) 123
}
