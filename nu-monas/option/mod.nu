#
# Option module - Monadic null handling for Nushell
#
# This module implements the Option type (Some/None) for safe null handling.
# It provides a monadic interface for working with nullable values without
# explicit null checks throughout your code.
#
# Example usage:
#   # Safe string parsing
#   "42" | some | and-then {|x|

# Import shared validation functions
use ../monad/monad-common validate-monadic-structure

# Option-specific validation - validates input is a proper Option type
def validate-option [] {
    let input = $in | validate-monadic-structure
    
    # Check for valid Option types
    if (not ($input.type in ["some", "none"])) {
        error make {
            msg: "Called Option function on non-Option value"
            label: {text: $"Expected Option \\(some/none\\), got type '($input.type)'. Use 'some' to wrap regular values"}
        }
    }
    
    $input
} 
#       try { $x | into int | some } catch { none }
#   } | unwrap-or 0
#   
#   # Chaining operations that might return null
#   $data | some | map {|x| $x.field } | and-then {|x| $x.subfield } | is-some
#   
#   # Filtering and transforming
#   [1, 2, 3] | some | filter {|x| ($x | length) > 2 } | map {|x| $x | reverse }
#

# Constants for Option types
export const SOME = "some"
export const NONE = "none"

# =============================================================================
# CONSTRUCTION - Create Option types
# =============================================================================

# Some constructor - wraps a non-null value
#
# Creates an Option containing the input value.
# Use this when you have a value that might be null elsewhere.
#
# Examples:
#   42 | some
#   "hello" | some
#   [1, 2, 3] | some
#
# See also: none, is-some
export def some [] {
    let input = $in
    
    if $input == null {
        error make {
            msg: "Cannot create Some from null value"
            label: {text: "Use None for null values"}
        }
    }
    {
        type: "some"
        value: $input
    }
}

# None constructor - represents absence of value
#
# Creates an Option representing no value.
# This is the monadic way to handle null/missing values.
#
# Examples:
#   none
#   if ($x == null) { none } else { $x | some }
#
# See also: some, is-none
export def none [] {
    {
        type: "none"
    }
}

# When-not constructor - create Option based on inequality with "empty" value
#
# Creates None if input equals the specified empty value, otherwise Some(input).
# This provides perfect symmetry with unwrap-or and handles any "empty" value type.
#
# Parameters:
#   empty_value: any - Value to treat as "empty" (converts to None)
#
# Examples:
#   42 | when-not null         # Some(42)
#   null | when-not null       # None
#   "hello" | when-not ""     # Some("hello")
#   "" | when-not ""           # None
#   [1, 2] | when-not []       # Some([1, 2])
#   [] | when-not []           # None
#   
# Perfect symmetry with unwrap-or:
#   $value | when-not null | unwrap-or null     # Identity
#   $value | when-not "" | unwrap-or ""         # Identity
#
# See also: some, none, unwrap-or
export def when-not [empty_value: any] {
    if $in == $empty_value {
        none
    } else {
        some
    }
}


# =============================================================================
# TRANSFORMATION - Work with Option types
# =============================================================================

# Map - transform the contained value
#
# Transforms the value inside a Some while keeping it wrapped.
# None values pass through unchanged.
# Only works on Option types - errors on non-Option input.
#
# Parameters:
#   transform: closure - Function to apply to the Some value
#
# Examples:
#   42 | some | map { $in * 2 }                      # Some(84)
#   none | map { $in * 2 }                           # None
#   "hello" | some | map { str length }              # Some(5)
#   1 | some | map { into bool }                     # Some(true)
#
# See also: and-then, filter
export def map [transform: closure] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: $val} => ($val | do $transform | some),
        {type: "none"} => $input
    }
}


# And-then - chain operations that return Options
#
# Chains operations that might return None. Also known as flatMap or bind.
# Use when the operation itself returns an Option.
# Only works on Option types - errors on non-Option input.
#
# If input is Some: runs operation on the value
# If input is None: passes None through unchanged
#
# Parameters:
#   operation: closure - Must return an Option (some or none)
#
# Examples:
#   # Parse string to number (might fail)
#   "42" | some | and-then { 
#       try { into int | some } catch { none }
#   }
#   
#   # Chain field access that might be null
#   $data | some | and-then { 
#       if ($in.field? == null) { none } else { $in.field | some }
#   }
#
# See also: map, or-else
export def and-then [operation: closure] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: $val} => ($val | do $operation),
        {type: "none"} => $input
    }
}


# Keep-if - keep value only if predicate is true
#
# Converts Some to None if the predicate returns false.
# None values pass through unchanged.
# Only works on Option types - errors on non-Option input.
#
# Parameters:
#   predicate: closure - Function that returns true/false
#
# Examples:
#   42 | some | keep-if { $in > 0 }                   # Some(42)
#   -5 | some | keep-if { $in > 0 }                   # None
#   none | keep-if { $in > 0 }                        # None
#
# See also: map, and-then
export def keep-if [predicate: closure] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: $val} => {
            if ($val | do $predicate) {
                $input
            } else {
                none
            }
        }
        {type: "none"} => $input
    }
}

# Or-else - provide alternative Option if None
#
# Returns the input if it's Some, otherwise returns the alternative.
# Useful for chaining fallback values.
#
# Parameters:
#   alternative: closure - Function that returns an Option
#
# Examples:
#   42 | some | or-else { 0 | some }                # Some(42)
#   none | or-else { 0 | some }                     # Some(0)
#   none | or-else { none }                         # None
#
# See also: unwrap-or, and-then
export def or-else [alternative: closure] {
    let input = $in | validate-option
    match $input {
        {type: "some"} => $input
        {type: "none"} => (do $alternative)
    }
}

# =============================================================================
# INSPECTION - Check Option types
# =============================================================================

# Check if Option is Some
#
# Returns true if the Option contains a value.
# Only works on Option types - errors on non-Option input.
#
# Examples:
#   42 | some | is-some                             # true
#   none | is-some                                  # false
#
# See also: is-none, some
export def is-some [] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: $_} => true,
        {type: "none"} => false
    }
}

# Check if Option is None
#
# Returns true if the Option contains no value.
# Only works on Option types - errors on non-Option input.
#
# Examples:
#   42 | some | is-none                             # false
#   none | is-none                                  # true
#
# See also: is-some, none
export def is-none [] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: $_} => false,
        {type: "none"} => true
    }
}

# =============================================================================
# EXTRACTION - Get values from Option types
# =============================================================================

# Unwrap - extract value or error on None
#
# Extracts the value from Some or throws an error for None.
# Use when you're confident the Option contains a value.
#
# Examples:
#   42 | some | unwrap                              # 42
#   none | unwrap                                   # Error!
#
# See also: unwrap-or, expect
export def unwrap [] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: $val} => $val
        {type: "none"} => {
            error make {
                msg: "Called unwrap on None value"
                label: {text: "Option was None"}
            }
        }
    }
}


# Unwrap-or - extract value or return default
#
# Safely extracts the value from Some, returning a default for None.
# Only works on Option types - errors on non-Option input.
# Never throws errors for valid Option input.
#
# Parameters:
#   default: any - Value to return if the Option is None
#
# Examples:
#   42 | some | unwrap-or 0                         # 42 (extracts from Some)
#   none | unwrap-or 0                              # 0 (uses default for None)
#   $opt | unwrap-or "N/A"                          # Safe Option extractor
#
# See also: unwrap, or-else
export def unwrap-or [default: any] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: $val} => $val,
        {type: "none"} => $default
    }
}


# Expect - extract value or error with custom message
#
# Like unwrap but with a custom error message.
# Use when you want to provide context about why None is unexpected.
#
# Parameters:
#   message: string - Error message to show if None
#
# Examples:
#   $user_id | some | expect "User ID must be set"
#   $config.port | some | expect "Port configuration required"
#
# See also: unwrap, unwrap-or
export def expect [message: string] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: $val} => $val
        {type: "none"} => {
            error make {
                msg: $message
                label: {text: "Option was None"}
            }
        }
    }
}

# =============================================================================
# SEQUENCE OPERATIONS
# =============================================================================

# Sequence - convert list of Options to Option of list
#
# Transforms [Some(a), Some(b), Some(c)] to Some([a, b, c]).
# If any element is None, the entire result is None.
#
# This is useful for "all or nothing" operations where you need
# all values to be present to proceed.
#
# Parameters:
#   options: list - List of Option values
#
# Examples:
#   [1, 2, 3] | each {|x| $x | some } | sequence     # Some([1, 2, 3])
#   [1, 2, 3] | each {|x| if $x == 2 { none } else { $x | some }} | sequence  # None
#
# See also: traverse
export def sequence [] {
    reduce --fold ([] | some) {|option, acc|
        match [$acc.type, $option.type] {
            ["some", "some"] => ($acc.value ++ [$option.value] | some)
            _ => none  # Any None results in None
        }
    }
}

# Traverse - map function over list and sequence the results
#
# Applies a function that returns Option to each element in a list,
# then sequences the results. This is map followed by sequence.
#
# Parameters:
#   transform: closure - Function that takes an element and returns an Option
#
# Examples:
#   [1, 2, 3] | traverse {|x| $x * 2 | some }        # Some([2, 4, 6])
#   [1, 2, 3] | traverse {|x| if $x == 2 { none } else { $x * 2 | some }}  # None
#
# See also: sequence
export def traverse [transform: closure] {
    each $transform | sequence
}

# Attempt - safely execute operation returning Option
#
# Executes a closure that might throw an exception, converting
# success to Some and exceptions to None.
#
# Parameters:
#   operation: closure - Function to execute safely
#
# Examples:
#   attempt { "42" | into int }                          # Some(42)
#   attempt { "abc" | into int }                         # None
#
# See also: expect, unwrap-or
export def attempt [operation: closure] {
    try {
        do $operation | some
    } catch {
        none
    }
}

# Map1 - lift a unary function to work with Option value as argument
#
# Takes a function that works on a regular value and makes it work
# with an Option value passed as an argument (not piped).
# This is useful when you need to apply a function to an Option
# that isn't in the pipeline position.
#
# Parameters:
#   f: closure - Unary function to lift
#   opt: Option - Option value to transform
#
# Examples:
#   map1 { $in * 2 } (21 | some)                    # Some(42)
#   map1 { str length } ("hello" | some)            # Some(5)
#   map1 { $in + 1 } none                           # None
#
# See also: map, map2
export def map1 [f: closure, opt: any] {
    match $opt {
        {type: "some", value: $val} => ($val | do $f | some)
        _ => none
    }
}

# Map2 - lift a binary function to work with two Option values
#
# Takes a function that works on two regular values and makes it work
# with two Option values. Both Options must be Some for the result to be Some.
#
# Parameters:
#   f: closure - Binary function to lift
#   opt1: Option - First Option value
#   opt2: Option - Second Option value
#
# Examples:
#   map2 {|a, b| $a + $b } (1 | some) (2 | some)   # Some(3)
#   map2 {|a, b| $a + $b } (1 | some) none         # None
#
# See also: map, and-then
export def map2 [f: closure, opt1: any, opt2: any] {
    match [$opt1, $opt2] {
        [{type: "some", value: $a}, {type: "some", value: $b}] => (do $f $a $b | some)
        _ => none
    }
}

# =============================================================================
# SUBMODULES - DataFrame operations (not auto-exported)
# =============================================================================

# NOTE: The 'df' submodule is intentionally NOT auto-exported to avoid circular dependencies.
# 
# Circular dependency issue:
#   option/mod.nu -> export df -> option/df/mod.nu -> use ../../option -> option/mod.nu
#
# Solution: Users must explicitly import the df submodule when needed:
#   use meth/option/df [when-not unwrap-or]    # Direct import
#   # or
#   use meth/option/df                         # Module import
#   $data | option df when-not null            # Usage
#
# This design maintains clean module boundaries while providing DataFrame-specific
# Option operations without breaking the module dependency graph.

# =============================================================================
# UTILITIES - Additional Option operations
# =============================================================================

# Unnest - remove one level of Option nesting
#
# Converts Option<Option<T>> to Option<T>.
# Some(Some(x)) becomes Some(x), everything else becomes None.
#
# Examples:
#   42 | some | some | unnest                      # Some(42)
#   42 | some | unnest                             # Error (not nested)
#   none | unnest                                   # None
#
# See also: and-then
export def unnest [] {
    let input = $in | validate-option
    match $input {
        {type: "some", value: {type: "some", value: $_}} => {
            $input.value.value | some
        }
        {type: "some", value: {type: "none"}} => none
        {type: "none"} => none
        {type: "some", value: $_} => {
            error make {
                msg: "Cannot flatten non-nested Option"
                label: {text: "Expected Option<Option<T>>, got Option with non-Option value"}
            }
        }
    }
}
