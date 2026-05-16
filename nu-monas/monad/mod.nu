#
# Monad module - Shared utilities for monadic operations
#
# This module provides common operations that work across different monadic types
# (Option, Result) and utilities for converting between them. It also documents
# the monadic laws and provides higher-order functions.
#
# Example usage:
#   # Convert Option to Result
#   $option | option-to-result "value was None"
#   
#   # Convert Result to Option (discarding error)
#   $result | result-to-option
#   
#   # Work with sequences of monadic values
#   [$opt1, $opt2, $opt3] | option sequence
#   [$res1, $res2, $res3] | result sequence
#

use ../option
use ../result

# =============================================================================
# CONVERSION FUNCTIONS
# =============================================================================

# Convert Option to Result
#
# Transforms Some(x) to Ok(x) and None to Err(error_message).
# Useful when you want to treat absence of value as an error.
#
# Parameters:
#   error_message: string - Error message to use when Option is None
#
# Examples:
#   42 | some | option-to-result "no value"         # Ok(42)
#   none | option-to-result "no value"              # Err("no value")
#
# See also: result-to-option
export def option-to-result [error_message: string] {
    match $in {
        {type: "some", value: $val} => ($val | result ok)
        _ => (null | result safely { error make {msg: $error_message} })
    }
}

# Convert Result to Option
#
# Transforms Ok(x) to Some(x) and Err to None.
# Useful when you want to discard error information and just work with presence/absence.
#
# Examples:
#   42 | ok | result-to-option                      # Some(42)
#   "data" | err "failed" | result-to-option        # None
#
# See also: option-to-result
export def result-to-option [] {
    match $in {
        {type: "ok", value: $val} => ($val | option some)
        _ => (option none)
    }
}



# =============================================================================
# VALIDATION UTILITIES
# =============================================================================

# Import shared validation functions
use monad-common validate-monadic-structure

# Re-export shared validation functions for discoverability
export use monad-common validate-monadic-structure

# =============================================================================
# MONADIC LAWS DOCUMENTATION
# =============================================================================

# Documentation function - not executable, just for reference
#
# MONADIC LAWS:
#
# For any monad M with unit/return and bind operations:
#
# 1. LEFT IDENTITY:
#    return(a) | bind(f) ≡ f(a)
#    Example: 42 | some | and-then f ≡ f(42)
#
# 2. RIGHT IDENTITY:
#    m | bind(return) ≡ m
#    Example: m | and-then {|x| x | some } ≡ m
#
# 3. ASSOCIATIVITY:
#    (m | bind(f)) | bind(g) ≡ m | bind({|x| f(x) | bind(g)})
#    Example: (m | and-then f) | and-then g ≡ m | and-then {|x| f(x) | and-then g}
#
# These laws ensure that monadic operations compose predictably
# and that the monad behaves consistently across different usage patterns.
#
# FUNCTOR LAWS (for map):
#
# 1. IDENTITY:
#    fmap(id) ≡ id
#    Example: m | map {|x| x } ≡ m
#
# 2. COMPOSITION:
#    fmap(f ∘ g) ≡ fmap(f) ∘ fmap(g)
#    Example: m | map {|x| g(f(x)) } ≡ m | map f | map g
#
export def monadic-laws [] {
    error make {
        msg: "This function is for documentation only"
        label: {text: "See source code for monadic laws reference"}
    }
}

