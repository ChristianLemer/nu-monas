# Option-aware multi-column join utilities for Nushell tables
# Provides join operations that properly handle Option types in join keys and data columns
#
# Architecture:
# - Delegates to df/join internal utilities for core join logic
# - Uses Option-specific key extraction and post-processing
# - Maintains same external API as before
#
# The join process:
# 1. Extract values from Option types in join keys (Some→value, None→null)
# 2. Perform join using df/join with Option-aware extractors
# 3. Apply Option post-processing to maintain type consistency

use ../../../df/join/util.nu

# Join two tables on multiple columns with Option-aware handling
# Both tables must have the same column names for the join keys
#
# Fully Monadic DataFrames:
# Uses --null-value {type: "none"} to ensure all cells in the result are Option types.
# No hybrid null/Option mixing - the result is a fully monadic DataFrame.
#
# Parameters:
#   right_table: The table to join with
#   ...columns: Column names to join on (must exist in both tables)
#   join type flags: --inner (default), --left, --right, or --outer
#
# Examples:
#   # Inner join on columns with Option values (default)
#   $left | option df join $right id category
#   
#   # Left join - all nulls become {type: "none"}
#   $left | option df join $right id type --left
export def main [
    right_table: table,
    ...columns: string,
    --inner (-i),
    --left (-l),
    --right (-r),
    --outer (-o),
] {
    # Validate columns
    if ($columns | length) == 0 {
        error make {msg: "columns cannot be empty"}
    }

    # Use df/join with Option-specific null handling - creates fully monadic DataFrame
    $in | util join $right_table ...$columns --inner=$inner --left=$left --right=$right --outer=$outer --custom-null {type: "none"}
}

