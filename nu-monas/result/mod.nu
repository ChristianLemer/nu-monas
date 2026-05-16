#
# Result module - Monadic error handling for Nushell
#
# This module implements the Result type (Ok/Err) for safe error handling.
# It provides a monadic interface for working with operations that might fail
# without explicit error checking throughout your code.
#
# Examples:
#   # Parse string to number (might fail):
#   "42" | ok | and-then {
#       try { into int | ok }
#       catch { err "invalid number" }
#   } | unwrap
#
#   # Safe division chain:
#   let dividend = 16
#   4 | ok | and-then {
#       if $in != 0 {
#           ($dividend / $in) | ok
#       } else {
#           err "division by zero"
#       }
#   } | unwrap
#
#   # Error handling with defaults:
#   "bad data" | err "validation error" | unwrap-or 0
#   [1, 2, 3] | ok | map { length } | unwrap

use std/assert

# Import validation functions
use utils.nu *

# Constants for Result types
export const OK = "ok"
export const ERR = "err"

# Constant for unwrap panic message - Hitchhiker's Guide style :)
export const DONT_PANIC = ([
    $"(ansi yellow)╔═════════════════════════════════════════════════════════════╗(ansi reset)"
    $"(ansi yellow)║                       DON'T PANIC!                          ║(ansi reset)"
    $"(ansi yellow)║      Relax and read the issue below... really do it!        ║(ansi reset)"
    $"(ansi yellow)╚═════════════════════════════════════════════════════════════╝(ansi reset)"
    ""
] | str join "\n")

# =============================================================================
# CONSTRUCTION - Create Result types
# =============================================================================

# Ok constructor - wraps successful value
#
# Creates a Result containing a successful value.
# Use this when an operation completed successfully.
#
# Examples:
#   42 | ok
#   [1, 2, 3] | ok
#   "success" | ok
#
# See also: err, is-ok
export def ok [] {
    {
        type: "ok"
        value: $in
    }
}

# Err constructor - wraps error with message
#
# Creates a Result containing an error.
# Use this when an operation failed.
# Only accepts real system errors (with 'rendered' field) to ensure type safety.
#
# Parameters:
#   data: any - The original input data that caused the error
#
# Examples:
#   try { risky-operation } catch {|e| $e | err $original_input }
#   $value | safely { $in / 0 }  # Auto-wraps errors
#   $value | ensure { $in > 0 }  # Creates proper error on assertion failure
#
# See also: ok, safely, ensure, is-err
export def err [data: any] {
    let error = $in

    # Validate that this is a real system error with 'rendered' field
    let is_valid_error = (
        ($error | describe | str starts-with "record") and
        ("rendered" in ($error | columns))
    )

    if not $is_valid_error {
        error make {
            msg: "err requires a real system error (with 'rendered' field)"
            label: {text: "Use 'safely' or 'ensure' to create Result from operations"}
        }
    }

    {
        type: "err"
        error: $error  # Real system error (rendered field preserved)
        data: $data    # Original input that caused the error
    }
}

# Safely - execute operation with automatic Result wrapping
#
# Executes a closure that might throw, automatically converting
# success to Ok and exceptions to Err. This is a constructor that
# provides automatic try/catch wrapping.
#
# Parameters:
#   operation: closure - Function to execute that might throw
#   catch?: closure - Optional closure that receives the error and can transform it
#   finally?: closure - Optional closure that runs after operation (regardless of success/failure)
#
# Examples:
#   42 | safely { $in / 2 }                         # Ok(21)
#   0 | safely { 10 / $in }                         # Err with division error
#   "text" | safely { into int }                    # Err with conversion error
#
#   # With catch block for error transformation
#   0 | safely { 10 / $in } { update msg "Division failed" }  # Custom error message
#
#   # With finally block for cleanup
#   $file | safely { open $in | process } null { rm -f temp.txt }  # Cleanup runs regardless
#
#   # With both catch and finally
#   $data | safely { process $in } { log-error $in } { cleanup }
#
# See also: attempt, and-then-safely, err
export def safely [
    operation: closure,
    catch?: closure,
    finally?: closure
] {
    let input = $in
    try {
        $input | do $operation | ok
    } catch {
        if $catch != null { do $catch } else { $in }
        | err $input
    }
    | tee {
        if $finally != null {
            $input | do $finally
        }
    }
}

# Ensure - validate condition with automatic Result wrapping
#
# Tests a predicate using assert, returning Ok(input) if true, or Err if false.
# The assert throws a proper error that gets caught and wrapped.
#
# Parameters:
#   predicate: closure - Function that returns true/false for assertion
#   error_message: string - Error message for failed assertion (default: "Assertion failed")
#
# Examples:
#   42 | ensure { $in > 0 }                         # Ok(42)
#   -5 | ensure { $in > 0 }                         # Err with assertion error
#   42 | ensure { $in > 0 } "Value must be positive" # Ok(42)
#   -5 | ensure { $in > 0 } "Value must be positive" # Err with custom message
#
# See also: and-then-ensure, safely
export def ensure [
    predicate: closure,
    error_message: string = "Assertion failed"
] {
    safely {
        assert ($in | do $predicate) $error_message
        $in
    }
}

# =============================================================================
# TRANSFORMATION - Work with Result types
# =============================================================================

# Map - transform the success value
#
# Transforms the value inside an Ok while keeping it wrapped.
# Err values pass through unchanged.
#
# Parameters:
#   transform: closure - Function to apply to the Ok value
#
# Examples:
#   42 | ok | map { $in * 2 }                      # Ok(84)
#   "error" | err "failed" | map { $in * 2 }       # Err("failed")
#   [1, 2, 3] | ok | map { length }                # Ok(3)
#
# See also: and-then, map-err
export def map [transform: closure] {
    let input = $in | validate-result
    match $input {
        {type: "ok", value: $val} => ($val | do $transform | ok)
        _ => $input
    }
}


# Map-err - transform the error value
#
# Transforms the error inside an Err while keeping it wrapped.
# Ok values pass through unchanged.
#
# Parameters:
#   transform: closure - Function to apply to the error message
#
# Examples:
#   42 | ok | map-err { $"prefix: ($in)" }                    # Ok(42)
#   "data" | err "failed" | map-err { $"prefix: ($in)" }      # Err("prefix: failed")
#
# See also: map, and-then
export def map-err [transform: closure] {
    let input = $in | validate-result
    match $input {
        {type: "ok"} => $input
        {type: "err"} => {
            $input | update error {|rec| $rec.error | do $transform}
        }
    }
}

# And-then - chain operations that return Results
#
# Chains operations that might fail. Also known as flatMap or bind.
# Use when the operation itself returns a Result.
#
# If input is Ok: runs operation on the value
# If input is Err: passes Err through unchanged
#
# Parameters:
#   operation: closure - Must return a Result (ok or err)
#
# Examples:
#   # Parse string to number (might fail)
#   "42" | ok | and-then {
#       try { into int | ok } catch { err "invalid number" }
#   }
#   
#   # Chain validation that can fail at any step
#   $data | ok | and-then { validate-positive $in } | and-then { validate-even $in }
#
# See also: map, or-else
export def and-then [operation: closure] {
    let input = $in | validate-result
    match $input {
        {type: "ok", value: $val} => ($val | do $operation)
        _ => $input
    }
}

# And-then-safely - chain operations with automatic Result wrapping
#
# Chains operations that might throw, automatically converting
# success to Ok and exceptions to Err. Unlike and-then, the operation
# doesn't need to return a Result - it's wrapped automatically.
#
# If input is Ok: runs operation with try/catch wrapping
# If input is Err: passes Err through unchanged
#
# Parameters:
#   operation: closure - Function that might throw (auto-wrapped in Result)
#   catch?: closure - Optional closure that receives the error and can transform it
#   finally?: closure - Optional closure that runs after operation (regardless of success/failure)
#
# Examples:
#   # Division that might fail - auto-wrapped
#   10 | ok | and-then-safely { $in / 2 }           # Ok(5)
#   10 | ok | and-then-safely { $in / 0 }           # Err with division error
#
#   # Chain operations without manual Result wrapping
#   "42" | ok | and-then-safely { into int } | and-then-safely { $in * 2 }  # Ok(84)
#
#   # With catch block for error transformation
#   10 | ok | and-then-safely { $in / 0 } { update msg "Cannot divide by zero" }
#
#   # With finally block for cleanup
#   $data | ok | and-then-safely { save-to-temp $in } null { rm -f temp.txt }  # Cleanup runs
#
#   # With both catch and finally
#   $data | ok | and-then-safely { process $in } { log-error $in } { cleanup }
#
#   # Compare with and-then (requires manual wrapping):
#   # "42" | ok | and-then { try { into int | ok } catch {|e| err $in } }
#
# See also: and-then, safely, ensure
export def and-then-safely [
    operation: closure,
    catch?: closure,
    finally?: closure
] {
    and-then { safely $operation $catch $finally }
}

# And-then-ensure - chain validation with automatic Result wrapping
#
# Chains a validation that uses assert, automatically converting
# success to Ok and assertion failures to Err. Unlike and-then,
# the predicate doesn't need to return a Result - it's wrapped automatically.
#
# If input is Ok: validates with assert and wraps result
# If input is Err: passes Err through unchanged
#
# Parameters:
#   predicate: closure - Function that returns true/false for assertion
#   error_message?: closure - Closure that receives the value and returns error message (default: returns "Assertion failed")
#
# Examples:
#   42 | ok | and-then-ensure { $in > 0 } { $"Value ($in) must be positive" }  # Ok(42)
#   -5 | ok | and-then-ensure { $in > 0 } { $"Value ($in) must be positive" }  # Err with "Value -5 must be positive"
#   0 | ok | and-then-ensure { $in != 0 }  # Uses default message "Assertion failed"
#
#   # Chain multiple validations with context-aware messages
#   $value | ok
#     | and-then-ensure { $in > 0 } { $"Got ($in), but must be positive" }
#     | and-then-ensure { $in < 100 } { $"Got ($in), but must be less than 100" }
#
# See also: ensure, and-then, and-then-safely
export def and-then-ensure [
    predicate: closure,
    error_message?: closure
] {
    and-then {
        ensure $predicate ($in | do ($error_message | default { "Assertion failed" }))
    }
}

# Or-else - provide alternative Result if Err
#
# Returns the input if it's Ok, otherwise returns the alternative.
# Useful for chaining fallback operations.
#
# Parameters:
#   alternative: closure - Function that returns a Result
#
# Examples:
#   42 | ok | or-else { 0 | ok }                    # Ok(42)
#   "data" | err "failed" | or-else { 0 | ok }      # Ok(0)
#   "data" | err "failed" | or-else { err "still failed" }  # Err("still failed")
#
# See also: unwrap-or, and-then
export def or-else [alternative: closure] {
    let input = $in | validate-result
    match $input {
        {type: "ok"} => $input
        {type: "err"} => (do $alternative)
    }
}

# =============================================================================
# INSPECTION - Check Result types
# =============================================================================

# Check if Result is Ok
#
# Returns true if the Result represents a successful operation.
#
# Examples:
#   42 | ok | is-ok                                 # true
#   "data" | err "failed" | is-ok                   # false
#
# See also: is-err, ok
export def is-ok [] {
    let input = $in | validate-result
    $input.type == "ok"
}

# Check if Result is Err
#
# Returns true if the Result represents a failed operation.
#
# Examples:
#   42 | ok | is-err                                # false
#   "data" | err "failed" | is-err                  # true
#
# See also: is-ok, err
export def is-err [] {
    let input = $in | validate-result
    $input.type == "err"
}

# =============================================================================
# EXTRACTION - Get values from Result types
# =============================================================================

# Internal helper for unwrap/expect - extracts value or errors with given message
def _unwrap [transform: closure] {
    let input = $in | validate-result
    match $input {
        {type: "ok", value: $val} => $val
        {type: "err", error: $err} => {
            let columns = ($err | columns)

            let formatted_error = $err
            | reject ...($columns | where $it in [debug raw json])
            | update msg { $"(ansi yellow)($in)(ansi reset)" }
            | rename --column { rendered: trace }
            | do $transform
            | table --expand

            error make { msg: $DONT_PANIC help: $formatted_error }

        }
    }
}

# Unwrap - extract value or error on failure
#
# Extracts the value from Ok or throws an error for Err.
# Use when you're confident the operation succeeded or want the program to stop on failure.
# Preserves original error context in help field when available.
#
# Examples:
#   42 | ok | unwrap                                # 42
#   "data" | err "failed" | unwrap                  # Error!
#
# See also: unwrap-or, expect
export def unwrap [] {
    _unwrap {}
}


# Unwrap-or - extract value or return default
#
# Safely extracts the value from Ok, returning a default for Err.
# Never throws errors - always returns a value.
#
# Parameters:
#   default: any - Value to return if the Result is Err
#
# Examples:
#   42 | ok | unwrap-or 0                           # 42
#   "data" | err "failed" | unwrap-or 0             # 0
#   $result | unwrap-or "N/A"                       # Safe string fallback
#
# See also: unwrap, or-else
export def unwrap-or [default: any] {
    let input = $in | validate-result
    match $input {
        {type: "ok", value: $val} => $val
        _ => $default
    }
}


# Unwrap-err - extract error or error on success
#
# Extracts the error from Err or throws an error for Ok.
# Useful for testing error conditions.
#
# Examples:
#   "data" | err "failed" | unwrap-err              # "failed"
#   42 | ok | unwrap-err                            # Error!
#
# See also: unwrap, expect
export def unwrap-err [] {
    let input = $in | validate-result
    match $input {
        {type: "err", error: $err} => $err
        {type: "ok"} => {
            error make {
                msg: "Called unwrap-err on Ok value"
                label: {text: "Result was Ok"}
            }
        }
    }
}

# Expect - extract value or error with custom message
#
# Like unwrap but with a custom error message.
# Use when you want to provide context about why Err is unexpected.
# Preserves original error context in help field when available.
#
# Parameters:
#   message: string - Error message to show if Err
#
# Examples:
#   $user_id | ok | expect "User ID must be set"
#   $config.port | ok | expect "Port configuration required"
#
# See also: unwrap, unwrap-or
export def expect [message: string] {
    _unwrap {
        {
            expectation: $message
            error: $in
        }
    }
}

# =============================================================================
# SEQUENCE OPERATIONS
# =============================================================================

# Sequence - convert list of Results to Result of list
#
# Transforms [Ok(a), Ok(b), Ok(c)] to Ok([a, b, c]).
# If any element is Err, returns the first error encountered.
#
# This is useful for "all or nothing" operations where you need
# all operations to succeed to proceed.
#
# Parameters:
#   results: list - List of Result values
#
# Examples:
#   [1, 2, 3] | each {|x| $x | ok } | sequence       # Ok([1, 2, 3])
#   [1, 2, 3] | each {|x| if $x == 2 { $x | err "failed" } else { $x | ok }} | sequence  # Err("failed")
#
# See also: traverse
export def sequence [] {
    reduce --fold ([] | ok) {|result, acc|
        match [$acc.type, $result.type] {
            ["ok", "ok"] => ($acc.value ++ [$result.value] | ok)
            ["err", _] => $acc  # Keep first error
            [_, "err"] => $result  # Return first error encountered
        }
    }
}

# Traverse - map function over list and sequence the results
#
# Applies a function that returns Result to each element in a list,
# then sequences the results. This is map followed by sequence.
#
# Parameters:
#   transform: closure - Function that takes an element and returns a Result
#
# Examples:
#   [1, 2, 3] | traverse { $in * 2 | ok }          # Ok([2, 4, 6])
#   [1, 2, 3] | traverse { if $in == 2 { err "failed" } else { $in * 2 | ok }}  # Err("failed")
#
# See also: sequence
export def traverse [transform: closure] {
    each $transform | sequence
}


# Map1 - lift a unary function to work with Result value as argument
#
# Takes a function that works on a regular value and makes it work
# with a Result value passed as an argument (not piped).
# This is useful when you need to apply a function to a Result
# that isn't in the pipeline position.
#
# Parameters:
#   f: closure - Unary function to lift
#   res: Result - Result value to transform
#
# Examples:
#   map1 { $in * 2 } (21 | ok)                      # Ok(42)
#   map1 { str length } ("hello" | ok)              # Ok(5)
#   map1 { $in + 1 } ("x" | err "failed")           # Err("failed")
#
# See also: map, map2
export def map1 [f: closure, res: any] {
    match $res {
        {type: "ok", value: $val} => ($val | do $f | ok)
        _ => $res  # Pass through Err unchanged
    }
}

# Map2 - lift a binary function to work with two Result values
#
# Takes a function that works on two regular values and makes it work
# with two Result values. Both Results must be Ok for the result to be Ok.
# If either is Err, returns the first error.
#
# Parameters:
#   f: closure - Binary function to lift
#   res1: Result - First Result value
#   res2: Result - Second Result value
#
# Examples:
#   map2 {|a, b| $a + $b } (1 | ok) (2 | ok)       # Ok(3)
#   map2 {|a, b| $a + $b } (1 | ok) ("x" | err "failed")  # Err("failed")
#
# See also: map, and-then
export def map2 [f: closure, res1: any, res2: any] {
    match [$res1, $res2] {
        [{type: "ok", value: $a}, {type: "ok", value: $b}] => (do $f $a $b | ok)
        [{type: "err"}, _] => $res1  # Return first error
        [_, {type: "err"}] => $res2  # Return second error if first is ok
    }
}

# =============================================================================
# RESOURCE MANAGEMENT - Monadic resource handling
# =============================================================================

# Generic resource management with guaranteed cleanup (RAII pattern)
#
# Creates resource, executes body, guarantees cleanup
# The cleanup action always executes, even if the body operation fails.
# This implements the Resource Acquisition Is Initialization pattern monadically.
#
# Parameters:
#   create: closure - Creates the resource, returns Result<resource, error>
#   cleanup: closure - Cleans up the resource, receives resource
#   body: closure - Uses the resource, returns Result<value, error>
#
# Examples:
#   {} | with-resource 
#     { create-temp-file } 
#     { |file| $file | close }
#     { |file| $file | process-data }
#
#   $data | with-resource
#     { open-connection }
#     { |conn| $conn | close-connection }
#     { |conn| $conn | execute-query }
export def with-resource [
    create: closure,    # Creates the resource
    cleanup: closure,   # Cleans up the resource  
    body: closure       # Uses the resource
]: any -> any {
    let input = $in
    $input 
    | do $create
    | and-then {
        let resource = $in
        let result = try { 
            $input | do $body $resource
        } catch {|e|
            $e | err $input
        }
        do $cleanup $resource
        $result
    }
}

# =============================================================================
# UTILITIES - Additional Result operations
# =============================================================================

# Unnest - remove one level of Result nesting
#
# Converts Result<Result<T, E>, E> to Result<T, E>.
# Ok(Ok(x)) becomes Ok(x), everything else becomes Err.
#
# Examples:
#   42 | ok | ok | unnest                          # Ok(42)
#   "data" | err "failed" | ok | unnest            # Err("failed")
#   "data" | err "failed" | unnest                 # Err("failed")
#
# See also: and-then
export def unnest [] {
    let input = $in | validate-result
    match $input {
        {type: "ok", value: {type: "ok", value: $_}} => {
            $input.value.value | ok
        }
        {type: "ok", value: {type: "err", error: $err, data: $data}} => {
            $err | err $data
        }
        {type: "err"} => $input
        {type: "ok", value: $_} => {
            error make {
                msg: "Cannot flatten non-nested Result"
                label: {text: "Expected Result<Result<T, E>, E>, got Result with non-Result value"}
            }
        }
    }
}


