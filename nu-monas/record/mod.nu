# Record manipulation utilities
#
# This module provides functional programming utilities for working with records,
# including mapping, filtering, and transforming record values while preserving keys.

# Internal helper to apply operation on transposed record
def transpose-op [op: closure] {
    let result = (transpose key value | do $op)
    if ($result | is-empty) {
        {}
    } else {
        $result | transpose -r -d
    }
}

# Map a function over all values in a record, preserving keys
export def map-values [
    f: closure  # Function to apply to each value
] {
    transpose-op { each {|it| {key: $it.key, value: (do $f $it.value)} } }
}

# Filter a record by a predicate on values, keeping only matching key-value pairs
export def filter-values [
    pred: closure  # Predicate function to test each value
] {
    transpose-op { where {|it| do $pred $it.value } }
}

# Map a function over key-value pairs, where the function receives {key: ..., value: ...}
# The function can transform both keys and values by returning {key: newKey, value: newValue}
export def map [
    f: closure  # Function that receives {key: string, value: any} and returns {key: string, value: any}
] {
    transpose-op { 
        each {|it| 
            let result = (do $f $it)
            {key: $result.key, value: $result.value}
        }
    }
}

# Filter by a predicate on key-value pairs
export def filter [
    pred: closure  # Predicate that receives {key: string, value: any}
] {
    transpose-op { where {|it| do $pred $it } }
}

# Convert record to list of key-value pairs
export def entries [] {
    transpose key value
}

# Convert list of key-value pairs back to record
export def from-entries [] {
    transpose -r -d
}

# Select only specified keys from a record (convenience wrapper for built-in select)
export def pick [
    ...keys: string  # Keys to keep
] {
    let record = $in
    let existing_keys = ($record | columns)
    let valid_keys = ($keys | where {|key| $key in $existing_keys})
    
    if ($valid_keys | is-empty) {
        {}
    } else {
        $record | select ...$valid_keys
    }
}

# Remove specified keys from a record (convenience wrapper for built-in reject)
export def omit [
    ...keys: string  # Keys to remove
] {
    let record = $in
    let existing_keys = ($record | columns)
    let valid_keys = ($keys | where {|key| $key in $existing_keys})
    
    if ($valid_keys | is-empty) {
        $record
    } else {
        $record | reject ...$valid_keys
    }
}

# Get all keys from a record as a list (convenience wrapper for built-in columns)
export def keys [] {
    columns
}


# Transform only the keys of a record
export def map-keys [
    f: closure  # Function to transform keys
] {
    transpose-op { each {|it| {key: (do $f $it.key), value: $it.value} } }
}

# Filter record by key predicate
export def filter-keys [
    pred: closure  # Predicate to test keys
] {
    transpose-op { where {|it| do $pred $it.key } }
}

# Apply different transformations to specific keys
# Example: {a: 1, b: "hello"} | evolve {a: {|v| $v + 1}, b: {|v| $v | str upcase}}
export def evolve [
    spec: record  # Record mapping keys to transformation functions
] {
    let record = $in
    $record | entries | each {|entry|
        let key = $entry.key
        let value = $entry.value
        
        if ($key in $spec) {
            let transform = ($spec | get $key)
            {key: $key, value: (do $transform $value)}
        } else {
            $entry
        }
    } | from-entries
}

# Split record into two based on predicate
export def partition [
    pred: closure  # Predicate that receives {key: string, value: any}
] {
    let entries = ($in | entries)
    let passing = ($entries | where {|it| do $pred $it } | from-entries)
    let failing = ($entries | where {|it| not (do $pred $it) } | from-entries)
    
    {passing: $passing, failing: $failing}
}


# Get all values from a record as a list
export def values [] {
    transpose key value | get value
}

