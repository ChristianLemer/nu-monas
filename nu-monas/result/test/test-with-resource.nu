#!/usr/bin/env nu

#
# Test with-resource function
#
use std/assert
use ../../result

# ============================================================
# Test Helper Functions
# ============================================================

# Create a mock resource that tracks its lifecycle
#
# Creates a record that simulates a resource with state tracking.
# Used to verify that create, use, and cleanup happen in correct order.
#
# Parameters:
#   name: string - Name of the resource for tracking
#
# Returns:
#   record - Mock resource with state tracking
def create-mock-resource [name: string] {
    {
        name: $name,
        state: "created",
        operations: ["created"]
    }
}

# Simulate using a resource
#
# Updates the resource state to track that it was used.
#
# Parameters:
#   resource: record - The mock resource to use
#   operation: string - The operation being performed
#
# Returns:
#   record - Updated resource with operation tracked
def use-mock-resource [resource: record, operation: string] {
    $resource | update operations {|r| $r.operations | append $operation}
}

# ============================================================
# Test Functions
# ============================================================

# [test] successful resource lifecycle with cleanup
def test-with-resource-success [] {
    let result = {} | result with-resource {
        # Create
        create-mock-resource "test-resource" | result ok
    } {|resource|
        # Cleanup - in real usage this would clean up the resource
        # For testing we just pass through
    } {|resource|
        # Use
        use-mock-resource $resource "processed" | result ok
    }
    
    assert ($result | result is-ok)
    let value = ($result | result unwrap)
    assert equal $value.name "test-resource"
    assert equal ($value.operations | last) "processed"
}

# [test] propagates error from body operation
def test-with-resource-body-failure [] {
    let result = {} | result with-resource {
        # Create succeeds
        create-mock-resource "test-resource" | result ok
    } {|resource|
        # Cleanup always runs
    } {|resource|
        # Use fails
        "test" | result safely { error make {msg: "processing failed"} }
    }
    
    assert ($result | result is-err)
    assert equal ($result | result unwrap-err | get msg) "processing failed"
}

# [test] handles exception in body with attempt
def test-with-resource-body-exception [] {
    let result = {} | result with-resource {
        # Create succeeds
        create-mock-resource "test-resource" | result ok
    } {|resource|
        # Cleanup always runs
    } {|resource|
        # Use throws exception (captured by attempt in with-resource)
        error make {msg: "unexpected error"}
    }
    
    assert ($result | result is-err)
    assert ($result | result unwrap-err | get msg | str contains "unexpected error")
}

# [test] propagates error from create phase
def test-with-resource-create-failure [] {
    let result = {} | result with-resource {
        # Create fails
        "data" | result safely { error make {msg: "resource creation failed"} }
    } {|resource|
        # Cleanup should not run if create failed
        error make {msg: "cleanup should not run"}
    } {|resource|
        # Use should not run if create failed
        error make {msg: "use should not run"}
    }
    
    assert ($result | result is-err)
    assert equal ($result | result unwrap-err | get msg) "resource creation failed"
}

# [test] handles nested resource management
def test-with-resource-nested [] {
    let result = {} | result with-resource {
        # Create outer resource
        create-mock-resource "outer" | result ok
    } {|outer|
        # Cleanup outer
    } {|outer|
        # Use outer by creating inner
        {} | result with-resource {
            # Create inner resource
            create-mock-resource "inner" | result ok
        } {|inner|
            # Cleanup inner
        } {|inner|
            # Use both resources
            {
                outer: $outer.name,
                inner: $inner.name
            } | result ok
        }
    }
    
    assert ($result | result is-ok)
    let value = ($result | result unwrap)
    assert equal $value.outer "outer"
    assert equal $value.inner "inner"
}

# [test] works with file-like resources
def test-with-resource-file-pattern [] {
    let temp_file = (mktemp)
    
    let result = {} | result with-resource {
        # Create file
        "test content" | save -f $temp_file
        $temp_file | result ok
    } {|file|
        # Cleanup file
        rm -f $file
    } {|file|
        # Use file
        null | result safely { open $file }
    }
    
    assert ($result | result is-ok)
    assert equal ($result | result unwrap) "test content"
    assert not ($temp_file | path exists) "file should be cleaned up"
}

# [test] cleanup runs even with ok result
def test-with-resource-cleanup-verification [] {
    # Create a temp file to verify cleanup
    let marker_file = (mktemp)
    "marker" | save -f $marker_file
    
    let result = {} | result with-resource {
        # Create returns the marker file path
        $marker_file | result ok
    } {|file|
        # Cleanup removes the file
        rm -f $file
    } {|file|
        # Use just returns success
        "success" | result ok
    }
    
    assert ($result | result is-ok)
    assert equal ($result | result unwrap) "success"
    assert not ($marker_file | path exists) "cleanup should have removed the file"
}

# [test] preserves input through pipeline
def test-with-resource-input-preservation [] {
    let input_data = {initial: "data", value: 42}
    
    let result = $input_data | result with-resource {
        # Create uses the input
        {resource: "created", input: $in} | result ok
    } {|resource|
        # Cleanup
    } {|resource|
        # Use verifies input was passed to create
        assert equal $resource.input $input_data
        $resource | result ok
    }
    
    assert ($result | result is-ok)
    let value = ($result | result unwrap)
    assert equal $value.input.initial "data"
    assert equal $value.input.value 42
}