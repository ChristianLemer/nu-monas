# Multi-column join utilities for Nushell dataframes
# Provides clean join operations with Nushell-standard flag-based API
#
# This module provides the public interface for multi-column joins.
# For advanced usage (Option handling), use the internal utilities.

use util.nu

# Join two tables on multiple columns using composite keys
# Both tables must have the same column names for the join keys
#
# Uses Nushell's standard join flag convention for consistency.
# Records with null values in any join key column will be filtered out.
#
# Parameters:
#   right_table: The table to join with
#   ...columns: Column names to join on (must exist in both tables)
#   separator: String to use when combining columns into composite key (default: ASCII record separator ␞)
#   join type flags: --inner (default), --left, --right, or --outer
#
# Examples:
#   # Inner join on multiple columns (default)
#   $left | df join $right id category
#   
#   # Left join
#   $left | df join $right id type --left
#   
#   # Right join with custom separator
#   $left | df join $right id type --right --separator "|"
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

    # Pass all flags directly to internal implementation
    $in | util join $right_table ...$columns --inner=$inner --left=$left --right=$right --outer=$outer
}