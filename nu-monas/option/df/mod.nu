#
# Option DataFrame operations
#
# This module provides monadic operations for DataFrames where all cells
# are treated uniformly as Options. It enables safe transformation of
# entire DataFrames between regular values and Option-wrapped values.
#
# Examples:
#   # Convert DataFrame to Options
#   [{name: "Alice", age: 30}, {name: "Bob", age: null}] | option df when-not null
#   # Returns: [{name: (some "Alice"), age: (some 30)}, {name: (some "Bob"), age: (none)}]
#
#   # Convert Option DataFrame back to regular
#   $option_df | option df unwrap-or "N/A"
#   # Returns: [{name: "Alice", age: 30}, {name: "Bob", age: "N/A"}]
#
#   # Option-aware joins
#   $left_table | option df join $right_table id name --left
#   # Properly handles Option values in join keys and normalizes result columns
#

use ../../df
use ../../option

# Convert all DataFrame cells to Options
#
# Applies the when-not constructor to every cell in the DataFrame,
# creating an Option DataFrame where regular values become Some(value)
# and empty_value instances become None.
#
# This creates a homogeneous Option DataFrame where all cells are
# guaranteed to be Option types, enabling safe monadic operations
# across the entire dataset.
#
# Parameters:
#   empty_value: any - Value to treat as "empty" (converts to None)
#
# Examples:
#   [{name: "Alice", age: 30}, {name: "Bob", age: null}] | option df when-not null
#   # Returns: [{name: (some "Alice"), age: (some 30)}, {name: (some "Bob"), age: (none)}]
#
#   [{name: "Alice", status: ""}, {name: "Bob", status: "active"}] | option df when-not ""
#   # Returns: [{name: (some "Alice"), status: (none)}, {name: (some "Bob"), status: (some "active")}]
#
# See also: unwrap-or, df update
export def "when-not" [empty_value: any = null] {
    df update { |x|
        $x | option when-not $empty_value
    }
}

# Convert all Option cells back to regular values
#
# Applies unwrap-or to every cell in an Option DataFrame, converting
# Some(value) back to value and None to the specified default.
# This assumes the DataFrame is homogeneous (all cells are Options).
#
# Parameters:
#   default: any - Value to use for None cells
#
# Examples:
#   [{name: (some "Alice"), age: (some 30)}, {name: (some "Bob"), age: (none)}] | option df unwrap-or "N/A"
#   # Returns: [{name: "Alice", age: 30}, {name: "Bob", age: "N/A"}]
#
#   $option_df | option df unwrap-or 0
#   # Returns: All None values become 0
#
# See also: when-not, df update
export def "unwrap-or" [default: any = null] {
    df update { |x|
        $x | option unwrap-or $default
    }
}

# Re-export join operations from the join submodule
export use join