#!/usr/bin/env nu

# Join utility function tests
use std/assert
use ../../../df/join/util.nu *

# =============================================================================
# composite-key tests
# =============================================================================

# [test] Create composite key with complete regular data
def test_composite_key_regular_complete [] {
    let row = {id: 1, name: "John", dept: "Engineering"}
    
    # Single column
    let single_key = (composite-key $row [id])
    assert equal $single_key {id: 1}
    
    # Multiple columns
    let multi_key = (composite-key $row [id name])
    assert equal $multi_key {id: 1, name: "John"}
    
    # All columns
    let full_key = (composite-key $row [id name dept])
    assert equal $full_key {id: 1, name: "John", dept: "Engineering"}
}

# [test] Create composite key always returns record (preserves nulls)
def test_composite_key_regular_nulls [] {
    let row_complete = {id: 1, name: "John", dept: "Engineering"}
    let row_null_middle = {id: 1, name: null, dept: "Engineering"}
    let row_null_end = {id: 1, name: "John", dept: null}

    # Complete row returns record
    let complete_key = (composite-key $row_complete [id name dept])
    assert equal $complete_key {id: 1, name: "John", dept: "Engineering"}

    # Null values are preserved in the record
    let null_middle_key = (composite-key $row_null_middle [id name dept])
    assert equal $null_middle_key {id: 1, name: null, dept: "Engineering"}

    let null_end_key = (composite-key $row_null_end [id name dept])
    assert equal $null_end_key {id: 1, name: "John", dept: null}
}

# [test] Create composite key preserves data types
def test_composite_key_preserves_types [] {
    let row = {id: 1, score: 95.5, active: true, name: "John"}
    
    # Test that different data types are preserved as-is in the list
    let key = (composite-key $row [id score active name])
    
    assert equal $key {id: 1, score: 95.5, active: true, name: "John"}
    assert equal ($key | get id | describe) "int"
    assert equal ($key | get score | describe) "float" 
    assert equal ($key | get active | describe) "bool"
    assert equal ($key | get name | describe) "string"
}

# [test] Create composite key with different data types
def test_composite_key_data_types [] {
    let row = {
        id: 1,
        score: 95.5,
        active: true,
        name: "Alice",
        tags: [tag1, tag2]  # This will be converted to string
    }
    
    # Mixed data types are preserved in list
    let mixed_key = (composite-key $row [id score active name])
    assert equal $mixed_key {id: 1, score: 95.5, active: true, name: "Alice"}
    
    # Lists are preserved as-is
    let with_list_key = (composite-key $row [name tags])
    assert equal $with_list_key {name: "Alice", tags: [tag1, tag2]}
}

# [test] Create composite key edge cases
def test_composite_key_edge_cases [] {
    # Empty columns list should error - but we can't test that here easily
    # Single column with null - preserves null
    let row_null = {id: null, name: "John"}
    let null_key = (composite-key $row_null [id])
    assert equal $null_key {id: null}

    # All nulls - preserves all nulls
    let row_all_null = {id: null, name: null}
    let all_null_key = (composite-key $row_all_null [id name])
    assert equal $all_null_key {id: null, name: null}

    # Single column, no nulls
    let row_single = {id: 42}
    let single_key = (composite-key $row_single [id])
    assert equal $single_key {id: 42}
}

# =============================================================================
# join-key tests (null filtering for join matching)
# =============================================================================

# [test] Join key returns null when any key value is null
def test_join_key_null_filtering [] {
    let row_complete = {id: 1, name: "John", dept: "Engineering"}
    let row_null_middle = {id: 1, name: null, dept: "Engineering"}
    let row_null_end = {id: 1, name: "John", dept: null}

    # Complete row returns the key record
    let complete_key = (join-key $row_complete [id name dept] null)
    assert equal $complete_key {id: 1, name: "John", dept: "Engineering"}

    # Null in middle -> null result (prevents matching)
    let null_middle_key = (join-key $row_null_middle [id name dept] null)
    assert equal $null_middle_key null

    # Null at end -> null result (prevents matching)
    let null_end_key = (join-key $row_null_end [id name dept] null)
    assert equal $null_end_key null
}

# [test] Join key edge cases with nulls
def test_join_key_edge_cases [] {
    # Single column with null -> null
    let row_null = {id: null, name: "John"}
    let null_key = (join-key $row_null [id] null)
    assert equal $null_key null

    # All nulls -> null
    let row_all_null = {id: null, name: null}
    let all_null_key = (join-key $row_all_null [id name] null)
    assert equal $all_null_key null

    # Single column, no nulls -> record
    let row_single = {id: 42}
    let single_key = (join-key $row_single [id] null)
    assert equal $single_key {id: 42}
}