#
# DataFrame utilities for Nushell
#
# This module provides utilities for working with tabular data (DataFrames)
# represented as lists of records in Nushell. It includes functions for
# analyzing schema, normalizing structure, joining tables, and preparing data
# for various export formats.
#

# Re-export join functionality
export use join

# Analyze column types across all records in a DataFrame
#
# Examines each column across all records to determine what data types
# are present. Useful for data quality analysis and schema understanding.
#
# Returns a list of records with column name and list of types found.
#
# Examples:
#   [{name: "Alice", age: 30}, {name: "Bob", age: "25"}] | df types
#   # Returns: [{column: "name", types: ["string"]}, {column: "age", types: ["int", "string"]}]
#
# See also: homogenize
#
# TODO: Refactor for simplicity
# 
export def types [] {
    let data = $in
    
    $data
    | columns
    | each { |col|
        let column_values = ($data | reduce -f [] { |record, acc|
            let value = if ($col in ($record | columns)) { $record | get $col } else { null }
            $acc ++ [$value]
        })
        let types = ($column_values | reduce -f [] { |value, acc|
            let type_desc = ($value | describe)
            $acc ++ [$type_desc]
        } | uniq)
        {column: $col, types: $types}
    }
}

# Ensure all records have the same columns (normalize DataFrame structure)
#
# Takes a list of records with potentially different column sets and ensures
# all records have the same columns. Missing columns are filled with null.
# Optionally accepts a specific list of columns to use.
#
# Parameters:
#   columns?: list - Optional list of columns to use (defaults to all columns found)
#
# Examples:
#   [{name: "Alice"}, {name: "Bob", age: 25}] | df homogenize
#   # Returns: [{name: "Alice", age: null}, {name: "Bob", age: 25}]
#
# See also: types
# 
# TODO: Refactor for simplicity
# 
export def homogenize [columns?: list] {
    let data = $in

    $data | each { |record|
        $columns
        | default ($data | columns)
        | each { |col|
            let value = if ($col in ($record | columns)) { 
                $record | get $col 
            } else { 
                null 
            }
            {$col: $value}
        } | reduce -f {} { |item, acc| $acc | merge $item }
    }
}

# Apply transformation to every cell in DataFrame
#
# Takes a closure and applies it to every cell value in the DataFrame.
# This is useful for type conversions, monadic wrapping, or any uniform
# transformation that needs to be applied to all data.
#
# Parameters:
#   transform: closure - Function to apply to each cell value
#
# Examples:
#   [{name: "Alice", age: 30}, {name: "Bob", age: null}] | df update { str length }
#   # Returns: [{name: 5, age: 0}, {name: 3, age: 0}] (assuming null becomes empty string)
#
#   $data | df update { when-not null }  # Wrap all cells as Options
#   $options_df | df update { unwrap-or "N/A" }  # Unwrap all Option cells
#
# See also: homogenize, types
export def update [transform: closure] {
    each {
        items {|col, value|
            {$col: (do $transform $value)}
        } | into record
    }
}
