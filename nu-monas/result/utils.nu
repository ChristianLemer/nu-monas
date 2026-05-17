#
# Result module utilities - Internal functions for testing
#
# This module exports internal/private functions that need to be tested
# but are not part of the public API of the result module.
#

# Import shared validation functions
use ../monad/monad-common validate-monadic-structure

# Result-specific validation - validates input is a proper Result type
export def validate-result [] {
    let input = $in | validate-monadic-structure
    
    # Check for valid Result types
    if (not ($input.type in [ok, err])) {
        error make {
            msg: "Called Result function on non-Result value"
            label: {text: $"Expected Result \(ok/err\), got type '($input.type)'. Use 'ok' to wrap success values"}
        }
    }
    
    # If it's an error, validate the error structure
    if ($input.type == err) {
        if ("error" not-in $input) {
            error make {
                msg: "Invalid Err structure: missing error field"
                label: {text: "Expected Err to have error field with msg and optional label"}
            }
        }
        
        let $err = $input.error
        if ("msg" not-in $err) {
            error make {
                msg: "Invalid error structure: missing msg field"
                label: {text: "Expected error.msg to contain the error message"}
            }
        }
        
        # If label exists, validate it has text
        if ("label" in $err) and ("text" not-in $err.label) {
            error make {
                msg: "Invalid error structure: label missing text field"
                label: {text: "Expected error.label.text to contain label description"}
            }
        }
    }
    
    $input
}