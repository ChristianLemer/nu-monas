#
# Validation module - Applicative validation for Nushell
#
# This module implements the Validation applicative functor for accumulating
# validation results. Unlike Result which short-circuits on first error,
# Validation collects ALL validation messages (success/failure/warning/skipped).
#
# This is an Applicative Functor, NOT a Monad - it deliberately lacks bind/and-then
# to preserve error accumulation semantics.
#
# Examples:
#   # Simple validation
#   $data
#   | success "Starting validation"
#   | check {|d|
#       if "Name" in ($d | columns) {
#         $d | success "Name field present"
#       } else {
#         $d | failure "Missing Name field"
#       }
#     }
#   | collect
#
#   # Multiple validations
#   $data
#   | success "Validation started"
#   | check { validate-schema }
#   | check { validate-ranges }
#   | check { validate-relationships }
#   | collect --verbose  # Include success messages

# Import shared validation functions
use ../monad/monad-common validate-monadic-structure

# Validation-specific validation - validates input is a proper Validation type
def validate-validation [] {
    let input = $in | validate-monadic-structure

    # Check for valid Validation types
    if (not ($input.type in ["success", "failure", "warning", "skipped"])) {
        error make {
            msg: "Called Validation function on non-Validation value"
            label: {text: $"Expected Validation \(success/failure/warning/skipped\), got type '($input.type)'. Use constructors to create Validation"}
        }
    }

    $input
}

# Constants for Validation types
export const SUCCESS = "success"
export const FAILURE = "failure"
export const WARNING = "warning"
export const SKIPPED = "skipped"

# =============================================================================
# CONSTRUCTION - Create Validation types
# =============================================================================

# Pure - lift a value into Validation context (identity/empty)
#
# Creates a Validation with no messages. This is the identity element
# for the Validation applicative, used to initialize validation folds.
#
# Follows the Applicative functor pattern where `pure` lifts a value
# into the context without adding any messages.
#
# Examples:
#   $data | pure  # Start validation chain
#   $fields | reduce --fold ($data | pure) {|field, acc| ... }
#
# See also: success, failure, warning
export def pure [] {
    {
        type: "success"
        value: $in
        messages: []
    }
}

# Success constructor - validation passed
#
# Creates a Validation indicating a successful check.
# The value is preserved and message is added to the validation accumulator.
#
# Parameters:
#   message: string - Description of what passed validation
#
# Examples:
#   $data | success "Schema validation passed"
#   42 | success "Age is valid"
#
# See also: failure, warning, skipped, pure
export def success [message: string] {
    {
        type: "success"
        value: $in
        messages: [{status: "success", message: $message}]
    }
}

# Failure constructor - validation failed
#
# Creates a Validation indicating a failed check.
# The value is preserved and error message is added to the validation accumulator.
#
# Parameters:
#   message: string - Description of what failed validation
#
# Examples:
#   $data | failure "Missing required field: Name"
#   -5 | failure "Age must be positive"
#
# See also: success, warning, skipped
export def failure [message: string] {
    {
        type: "failure"
        value: $in
        messages: [{status: "failure", message: $message}]
    }
}

# Warning constructor - validation passed with warnings
#
# Creates a Validation indicating a non-critical issue.
# The value is preserved and warning message is added to the validation accumulator.
#
# Parameters:
#   message: string - Description of the warning
#
# Examples:
#   $data | warning "Extra field found: Notes"
#   100 | warning "Age is at maximum allowed value"
#
# See also: success, failure, skipped
export def warning [message: string] {
    {
        type: "warning"
        value: $in
        messages: [{status: "warning", message: $message}]
    }
}

# Skipped constructor - validation not applicable
#
# Creates a Validation indicating a check was skipped.
# Used when a validation doesn't apply (e.g., parent field missing).
#
# Parameters:
#   message: string - Description of why validation was skipped
#
# Examples:
#   $data | skipped "Age validation skipped (field not present)"
#   null | skipped "Optional field validation skipped"
#
# See also: success, failure, warning
export def skipped [message: string] {
    {
        type: "skipped"
        value: $in
        messages: [{status: "skipped", message: $message}]
    }
}

# =============================================================================
# APPLICATIVE OPERATIONS - Accumulate validations
# =============================================================================

# Check - apply validation and accumulate results
#
# Runs a validation closure and accumulates the result.
# This is the Applicative "apply" operation (<*> in Haskell).
# Unlike monadic bind, this ALWAYS runs the validation and accumulates messages.
#
# The closure receives the current value BOTH as parameter AND via pipeline ($in),
# following the same pattern as Nushell's built-in commands like `insert`.
#
# Parameters:
#   validation: closure - Function that takes value and returns Validation
#
# Examples:
#   # Using $in (pipeline)
#   $data
#   | success "Starting"
#   | check { if "Name" in ($in | columns) { $in | success "Has Name" } else { $in | failure "Missing Name" }}
#
#   # Using parameter (like insert)
#   | check {|d| if "Age" in ($d | columns) { $d | success "Has Age" } else { $d | warning "Age missing" }}
#
#   # Using both
#   | check {|data| if "Field" in ($in | columns) { $data | success "Has Field" }}
#
# See also: collect, success, failure
export def check [validation: closure] {
    let input = $in | validate-validation

    # Run the validation with value passed BOTH as parameter AND via pipeline
    # This matches Nushell's pattern (e.g., insert {|row| ...})
    let result = $input.value | do $validation $input.value

    # Accumulate messages and determine new status
    let accumulated_messages = ($input.messages ++ $result.messages)

    # Determine overall status (failure > warning > skipped > success)
    let new_status = if ($accumulated_messages | any {|m| $m.status == "failure"}) {
        "failure"
    } else if ($accumulated_messages | any {|m| $m.status == "warning"}) {
        "warning"
    } else if ($accumulated_messages | any {|m| $m.status == "skipped"}) {
        "skipped"
    } else {
        "success"
    }

    {
        type: $new_status
        value: $input.value  # Value always preserved
        messages: $accumulated_messages
    }
}

# =============================================================================
# EXTRACTION - Get results from Validation
# =============================================================================

# Collect - extract final validation results
#
# Extracts messages from the validation accumulator.
# By default, only returns failure/warning/skipped messages.
# Use --verbose to include success messages as well.
#
# Parameters:
#   --verbose: flag - Include success messages in output
#
# Returns:
#   - If no issues: single success message record
#   - If issues: list of failure/warning/skipped message records
#   - If verbose: all message records including successes
#
# Examples:
#   $data | success "Start" | check {...} | collect
#   $data | success "Start" | check {...} | collect --verbose
#
# See also: check
export def collect [--verbose] {
    let input = $in | validate-validation

    let filtered_messages = if $verbose {
        $input.messages
    } else {
        $input.messages | where status != "success"
    }

    if ($filtered_messages | is-empty) {
        [{status: "✅", message: "All validation checks passed"}]
    } else {
        $filtered_messages | each {|msg|
            let emoji = match $msg.status {
                "success" => "✅"
                "failure" => "❌"
                "warning" => "❗"
                "skipped" => "💨"
            }
            {status: $emoji, message: $msg.message}
        }
    }
}

# =============================================================================
# INSPECTION - Check Validation status
# =============================================================================

# Check if Validation is success (no failures or warnings)
#
# Returns true if all validations passed without warnings.
#
# Examples:
#   $data | success "OK" | is-success           # true
#   $data | failure "Bad" | is-success          # false
#
# See also: is-failure, is-warning
export def is-success [] {
    let input = $in | validate-validation
    $input.type == "success"
}

# Check if Validation has failures
#
# Returns true if any validation failed.
#
# Examples:
#   $data | failure "Bad" | is-failure          # true
#   $data | success "OK" | is-failure           # false
#
# See also: is-success, is-warning
export def is-failure [] {
    let input = $in | validate-validation
    $input.type == "failure"
}

# Check if Validation has warnings
#
# Returns true if validation has warnings but no failures.
#
# Examples:
#   $data | warning "Note" | is-warning         # true
#   $data | failure "Bad" | is-warning          # false
#
# See also: is-success, is-failure
export def is-warning [] {
    let input = $in | validate-validation
    $input.type == "warning"
}

# =============================================================================
# UTILITIES - Additional operations
# =============================================================================

# Get the validated value regardless of status
#
# Extracts the value from a Validation, discarding messages.
# Useful when you need the value after validation regardless of outcome.
#
# Examples:
#   $data | success "OK" | get-value            # $data
#   $data | failure "Bad" | get-value           # $data
#
# See also: collect
export def get-value [] {
    let input = $in | validate-validation
    $input.value
}

