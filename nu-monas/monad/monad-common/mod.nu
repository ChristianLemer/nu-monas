#
# Monad common utilities - Shared validation functions
#
# This module provides common validation functions that can be used
# by all monadic types without creating circular dependencies.
#

# Validate basic monadic structure - common validation for all monadic types
#
# Checks that input is not null and has the required record structure
# with a 'type' field. This is the foundation for all monadic type validation.
#
# Returns the input if valid, throws error otherwise.
#
# Examples:
#   {type: "some", value: 42} | validate-monadic-structure    # Returns input
#   null | validate-monadic-structure                         # Error
#   42 | validate-monadic-structure                           # Error
#
export def validate-monadic-structure [] {
    let input = $in
    
    # Check for null/nothing
    if ($input | describe) == "nothing" {
        error make {
            msg: "Cannot call monadic function on null/nothing"
            label: {text: "Expected monadic type, got nothing"}
        }
    }
    
    # Check for record structure with 'type' field
    if not (($input | describe) | str starts-with "record") {
        let input_type = ($input | describe)
        error make {
            msg: "Invalid monadic structure"
            label: {text: $"Expected monadic type - record with 'type' field, got '($input_type)'"}
        }
    }
    
    if ($input.type? == null) {
        error make {
            msg: "Invalid monadic structure"
            label: {text: $"Expected record with 'type' field, got ($input | describe)"}
        }
    }
    
    $input
}
