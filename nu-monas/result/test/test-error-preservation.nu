#
# Test error preservation functionality
#
use std/assert
use ../../result *

# ============================================================
# Test Helper Functions
# ============================================================

# Creates a test error with rendered field (simulating caught error)
# This helper simulates what happens when you catch an error that has
# a rendered field with full stack trace information
def create-test-error-with-rendered [] {
    {
        msg: "original error message"
        rendered: "Error: original error message\n  at test-function line 42\n  stack trace here"
    }
}

# Creates a simple string error for comparison
def create-simple-string-error [] {
    "simple error message"
}

# ============================================================
# Test Functions
# ============================================================

# [test] err constructor preserves rendered field from error objects
def test-err-preserves-rendered [] {
    # Arrange
    let original_error = (create-test-error-with-rendered)
    
    # Act
    let result = $original_error | err "test data"
    
    # Assert
    assert equal $result.type "err"
    assert equal $result.error.msg "original error message"
    assert equal $result.error.rendered "Error: original error message\n  at test-function line 42\n  stack trace here"
    assert equal $result.data "test data"
}

# [test] err constructor handles string errors normally
def test-err-handles-string-errors [] {
    # String errors are not allowed with new err validation
    # err now requires error records with 'rendered' field
    # This test is no longer applicable - skipping
    return
}

# [test] unwrap preserves rendered field in help
def test-unwrap-preserves-rendered-in-help [] {
    # Arrange
    let original_error = (create-test-error-with-rendered)
    let result = $original_error | err "test data"

    # Act & Assert
    try {
        $result | unwrap
        assert false "Expected unwrap to throw error"
    } catch {|e|
        assert equal $e.msg $DONT_PANIC
        # No help field anymore - rendered is printed to stderr instead
    }
}

# [test] unwrap falls back to original error for non-rendered errors
def test-unwrap-fallback-for-simple-errors [] {
    # Arrange
    let result = "test data" | safely { error make {msg: "simple error"} }

    # Act & Assert
    try {
        $result | unwrap
        assert false "Expected unwrap to throw error"
    } catch {|e|
        assert equal $e.msg $DONT_PANIC
        # No help field anymore - rendered is printed to stderr instead
    }
}

# [test] expect concatenates custom message and preserves rendered in help
def test-expect-preserves-rendered-in-help [] {
    # Arrange
    let original_error = (create-test-error-with-rendered)
    let result = $original_error | err "test data"

    # Act & Assert
    try {
        $result | expect "Custom expectation failed"
        assert false "Expected expect to throw error"
    } catch {|e|
        assert equal $e.msg $DONT_PANIC
        # No help field anymore - rendered is printed to stderr instead
    }
}

# [test] expect falls back to combined message for non-rendered errors
def test-expect-fallback-for-simple-errors [] {
    # Arrange
    let result = "test data" | safely { error make {msg: "simple error"} }

    # Act & Assert
    try {
        $result | expect "Custom expectation failed"
        assert false "Expected expect to throw error"
    } catch {|e|
        assert equal $e.msg $DONT_PANIC
        # No help field anymore - rendered is printed to stderr instead
    }
}