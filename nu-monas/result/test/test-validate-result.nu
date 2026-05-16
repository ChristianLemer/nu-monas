#!/usr/bin/env nu

#
# Test validate-result error structure validation
#
use std/assert
use .. *
use ../utils.nu *

# [test] validates proper error structure with msg
def test-validate-result-proper-error [] {
    # Manually create Result for validation testing
    let valid_err = {type: "err", error: {msg: "test error", rendered: "test"}, data: "data"}
    
    let result = ($valid_err | validate-result)
    
    assert equal $result.type err
    assert equal $result.error.msg "test error"
}

# [test] validates error structure with msg and label.text
def test-validate-result-error-with-label [] {
    # Manually create Result for validation testing
    let valid_err = {
        type: "err"
        error: {
            msg: "validation failed"
            label: {text: "expected number"}
            rendered: "test"
        }
        data: "data"
    }
    
    let result = ($valid_err | validate-result)
    
    assert equal $result.type err
    assert equal $result.error.msg "validation failed"
    assert equal $result.error.label.text "expected number"
}

# [test] rejects error missing msg field
def test-validate-result-error-missing-msg [] {
    # Manually construct invalid error (bypassing err constructor)
    let invalid_err = {
        type: err
        error: {description: "no msg field"}
        data: "test"
    }
    
    assert error {
        $invalid_err | validate-result
    }
}

# [test] rejects error with label missing text
def test-validate-result-label-missing-text [] {
    # Manually construct invalid error
    let invalid_err = {
        type: err
        error: {
            msg: "test error"
            label: {description: "no text field"}
        }
        data: "test"
    }
    
    assert error {
        $invalid_err | validate-result
    }
}

# [test] accepts error with no label (label is optional)
def test-validate-result-no-label-ok [] {
    # Manually create Result for validation testing
    let valid_err = {type: "err", error: {msg: "just message", rendered: "test"}, data: "data"}
    
    let result = ($valid_err | validate-result)
    
    assert equal $result.type err
    assert equal $result.error.msg "just message"
    assert ("label" not-in $result.error)
}

# [test] accepts error with label containing span information
def test-validate-result-label-with-span [] {
    # Manually create Result for validation testing
    let valid_err = {
        type: "err"
        error: {
            msg: "parse error"
            label: {
                text: "invalid syntax here"
                span: {start: 10, end: 20}
            }
            rendered: "test"
        }
        data: "data"
    }
    
    let result = ($valid_err | validate-result)
    
    assert equal $result.type err
    assert equal $result.error.msg "parse error"
    assert equal $result.error.label.text "invalid syntax here"
    assert equal $result.error.label.span.start 10
    assert equal $result.error.label.span.end 20
}

# [test] accepts error with additional help field
def test-validate-result-with-help-field [] {
    # Manually create Result for validation testing
    let valid_err = {
        type: "err"
        error: {
            msg: "configuration error"
            label: {text: "invalid setting"}
            help: "Check your config file"
            rendered: "test"
        }
        data: "data"
    }
    
    let result = ($valid_err | validate-result)
    
    assert equal $result.type err
    assert equal $result.error.msg "configuration error"
    assert equal $result.error.label.text "invalid setting"
    assert equal $result.error.help "Check your config file"
}

# [test] validates Ok results pass through unchanged  
def test-validate-result-ok-passthrough [] {
    let ok_val = 42 | ok
    
    let result = ($ok_val | validate-result)
    
    assert equal $result.type ok
    assert equal $result.value 42
}
