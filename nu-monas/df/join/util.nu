# Internal join utilities with advanced capabilities
# 
# Internal utility functions for join operations that provide:
# - Key value extraction for custom data types
# - Custom null value handling for outer joins
# - Helper functions for validation and processing
#
# These functions are exported for testing and internal use by monadic modules
# but should not be re-exported by the main df module.

# Create an alias for the built-in join to avoid naming conflict
alias builtin_join = join

# Constants for composite and join key column names
const COMPOSITE_KEY = "__composite_key__"
const JOIN_KEY = "__join_key__"




# Create composite key from a row using specified keys
# Always returns the key record, preserving all values (including nulls)
# Used for restoration after join via flatten
export def composite-key [
    row: record,
    keys: list<string>,
] {
    $row | select ...$keys
}

# Create join key from a row using specified keys
# Returns null if any key part equals custom_null, otherwise returns the key record
# Used to control join matching behavior (nulls don't match)
export def join-key [
    row: record,
    keys: list<string>,
    custom_null: any = null  # Value to check for (e.g., null or {type: "none"})
] {
    let key_record = $row | select ...$keys
    let values = $key_record | values

    # Validate: no native nulls when using custom custom_null
    if $custom_null != null and ($values | any {$in == null}) {
        error make {msg: $"Unexpected native null value found in keys when custom_null is ($custom_null)"}
    }

    # Return null if any value matches custom_null, otherwise the key record
    if ($values | any {$in == $custom_null}) { null } else { $key_record }
}

# Helper function to add both composite and join keys to a table
def add-join-keys [
    keys: list<string>,
    custom_null: any = null
] {
    $in
    | insert $COMPOSITE_KEY {|row| composite-key $row $keys}
    | insert $JOIN_KEY {|row| join-key $row $keys $custom_null}
}

# Internal join implementation with full configurability
# Supports custom null values for advanced use cases
export def join [
    right_table: table,
    ...keys: string,
    --inner (-i) = false,
    --left (-l) = false,
    --right (-r) = false,
    --outer (-o) = false,
    --custom-null: any = null,        # Value for missing data in outer joins
] {
    # Add both composite (preserve) and join (match) keys to both tables
    let left_with_keys = $in | add-join-keys $keys $custom_null
    let right_with_keys = $right_table | add-join-keys $keys $custom_null

    $left_with_keys
    | builtin_join $right_with_keys $JOIN_KEY --inner=$inner --left=$left --right=$right --outer=$outer
    | reject ...$keys ...($keys | each {$in + "_"}) $JOIN_KEY --optional  # Remove original keys, suffixed keys, and join key
    | upsert $COMPOSITE_KEY {|row|  # Coalesce composite keys: use left if present, else right
        ($row | get $COMPOSITE_KEY) | default ($row | get --optional ($COMPOSITE_KEY + "_"))
    }
    | reject --optional ($COMPOSITE_KEY + "_")  # Remove right composite key
    | flatten $COMPOSITE_KEY  # Flatten composite key to restore original keys
    | if $custom_null == null { $in } else { update cells {|v| $v | default $custom_null }}
}
