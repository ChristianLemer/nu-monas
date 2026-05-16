use std/assert
use ../../record

# [test] Transform all values in a record while preserving keys
def test-map-values [] {
    let result = {a: 1, b: 2, c: 3} | record map-values {|v| $v * 2}
    assert equal $result {a: 2, b: 4, c: 6}
}

# [test] Keep only key-value pairs where values match a predicate
def test-filter-values [] {
    let result = {a: 1, b: 2, c: 3} | record filter-values {|v| $v > 1}
    assert equal $result {b: 2, c: 3}
}

# [test] Transform both keys and values using key-value pairs
def test-map [] {
    let result = {a: 1, b: 2} | record map {|entry| 
        {
            key: $entry.key
            value: ($entry.value + ($entry.key | str length))
        }
    }
    assert equal $result {a: 2, b: 3}
}

# [test] Filter using both key and value information
def test-filter [] {
    let result = {a: 1, b: 2, c: 3} | record filter {|entry| 
        ($entry.key != 'b') and ($entry.value < 3)
    }
    assert equal $result {a: 1}
}

# [test] Select only specified keys from a record
def test-pick [] {
    let result = {a: 1, b: 2, c: 3, d: 4} | record pick a c
    assert equal $result {a: 1, c: 3}
    
    # Test with non-existent keys
    let result2 = {a: 1, b: 2} | record pick a x
    assert equal $result2 {a: 1}
}

# [test] Remove specified keys from a record
def test-omit [] {
    let result = {a: 1, b: 2, c: 3, d: 4} | record omit b d
    assert equal $result {a: 1, c: 3}
    
    # Test with non-existent keys
    let result2 = {a: 1, b: 2} | record omit x y
    assert equal $result2 {a: 1, b: 2}
}


# [test] Transform only the keys of a record
def test-map-keys [] {
    let result = {a: 1, b: 2} | record map-keys {|k| $k | str upcase}
    assert equal $result {A: 1, B: 2}
}

# [test] Filter record by key predicate
def test-filter-keys [] {
    let result = {apple: 1, banana: 2, apricot: 3} | record filter-keys {|k| $k | str starts-with 'a'}
    assert equal $result {apple: 1, apricot: 3}
}

# [test] Apply different transformations to specific keys
def test-evolve [] {
    let result = {a: 1, b: "hello", c: 3} | record evolve {
        a: {|v| $v + 10}
        b: {|v| $v | str upcase}
    }
    assert equal $result {a: 11, b: "HELLO", c: 3}
}

# [test] Split record into two based on predicate
def test-partition [] {
    let result = {a: 1, b: 2, c: 3, d: 4} | record partition {|entry| $entry.value > 2}
    assert equal $result.passing {c: 3, d: 4}
    assert equal $result.failing {a: 1, b: 2}
}


# [test] Get all values from a record as a list
def test-values [] {
    let result = {a: 1, b: 2, c: 3} | record values | sort
    assert equal $result [1, 2, 3]
}

# [test] Get all keys from a record as a list
def test-keys [] {
    let result = {a: 1, b: 2, c: 3} | record keys | sort
    assert equal $result [a, b, c]
}

# [test] Convert record to entries and back to record
def test-entries-and-from-entries [] {
    let original = {a: 1, b: 2, c: 3}
    let entries = $original | record entries
    assert equal ($entries | length) 3
    
    let reconstructed = $entries | record from-entries
    assert equal $reconstructed $original
}


# [test] Chain multiple record operations together
def test-chaining [] {
    # Test that functions can be chained together
    let result = {a: 1, b: 2, c: 3, d: 4} 
        | record filter-values {|v| $v > 1}
        | record map-values {|v| $v * 10}
        | record pick b c
    assert equal $result {b: 20, c: 30}
}

# [test] Complex transformations combining multiple operations
def test-complex-transformations [] {
    # Transform keys and values
    let result = {first_name: "john", last_name: "doe", age: 30}
        | record map-keys {|k| $k | str replace '_' '-'}
        | record map {|entry|
            if ($entry.key == "age") {
                {
                    key: $entry.key
                    value: ($entry.value + 1)
                }
            } else {
                {
                    key: $entry.key
                    value: ($entry.value | str upcase)
                }
            }
        }
    assert equal $result {"first-name": "JOHN", "last-name": "DOE", age: 31}
}