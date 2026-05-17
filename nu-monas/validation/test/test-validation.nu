#
# Test validation module
#
use std/assert
use ../../validation *

# ============================================================
# Constructor Tests
# ============================================================

# [test] pure constructor creates empty Validation
export def test_pure_constructor [] {
    let result = 42 | pure

    assert equal $result.type "success"
    assert equal $result.value 42
    assert equal ($result.messages | length) 0
}

# [test] success constructor creates valid Validation
export def test_success_constructor [] {
    let result = 42 | success "Test passed"

    assert equal $result.type "success"
    assert equal $result.value 42
    assert equal ($result.messages | length) 1
    assert equal $result.messages.0.status "success"
    assert equal $result.messages.0.message "Test passed"
}

# [test] failure constructor creates valid Validation
export def test_failure_constructor [] {
    let result = 42 | failure "Test failed"

    assert equal $result.type "failure"
    assert equal $result.value 42
    assert equal ($result.messages | length) 1
    assert equal $result.messages.0.status "failure"
    assert equal $result.messages.0.message "Test failed"
}

# [test] warning constructor creates valid Validation
export def test_warning_constructor [] {
    let result = 42 | warning "Test warning"

    assert equal $result.type "warning"
    assert equal $result.value 42
    assert equal ($result.messages | length) 1
    assert equal $result.messages.0.status "warning"
    assert equal $result.messages.0.message "Test warning"
}

# [test] skipped constructor creates valid Validation
export def test_skipped_constructor [] {
    let result = 42 | skipped "Test skipped"

    assert equal $result.type "skipped"
    assert equal $result.value 42
    assert equal ($result.messages | length) 1
    assert equal $result.messages.0.status "skipped"
    assert equal $result.messages.0.message "Test skipped"
}

# ============================================================
# Check Operation Tests
# ============================================================

# [test] check accumulates success messages
export def test_check_accumulates_success [] {
    let result = 42
    | success "First"
    | check { success "Second" }
    | check { success "Third" }

    assert equal $result.type "success"
    assert equal ($result.messages | length) 3
    assert equal $result.messages.0.message "First"
    assert equal $result.messages.1.message "Second"
    assert equal $result.messages.2.message "Third"
}

# [test] check accumulates failure messages
export def test_check_accumulates_failures [] {
    let result = 42
    | success "Start"
    | check { failure "Error 1" }
    | check { failure "Error 2" }

    assert equal $result.type "failure"
    assert equal ($result.messages | length) 3
    assert equal $result.messages.1.status "failure"
    assert equal $result.messages.2.status "failure"
}

# [test] check accumulates mixed messages
export def test_check_accumulates_mixed [] {
    let result = 42
    | success "Start"
    | check { success "Good" }
    | check { warning "Warn" }
    | check { failure "Bad" }

    assert equal $result.type "failure"
    assert equal ($result.messages | length) 4
}

# [test] check preserves value through pipeline
export def test_check_preserves_value [] {
    let result = {name: "test", value: 42}
    | success "Start"
    | check { failure "Error" }
    | check { warning "Warn" }

    assert equal $result.value.name "test"
    assert equal $result.value.value 42
}

# [test] check works with $in (implicit pipeline)
export def test_check_with_implicit_in [] {
    let result = 42
    | success "Start"
    | check {
        if $in > 0 {
            success "Positive"
        } else {
            failure "Negative"
        }
    }

    assert equal $result.type "success"
    assert equal ($result.messages | length) 2
}

# [test] check works with parameter
export def test_check_with_parameter [] {
    let result = 42
    | success "Start"
    | check {|val|
        if $val > 0 {
            success "Positive"
        } else {
            failure "Negative"
        }
    }

    assert equal $result.type "success"
    assert equal ($result.messages | length) 2
}

# ============================================================
# Status Priority Tests
# ============================================================

# [test] failure status takes precedence over warning
export def test_status_priority_failure_over_warning [] {
    let result = 42
    | success "Start"
    | check { warning "Warn" }
    | check { failure "Fail" }

    assert equal $result.type "failure"
}

# [test] failure status takes precedence over success
export def test_status_priority_failure_over_success [] {
    let result = 42
    | success "Start"
    | check { success "Good" }
    | check { failure "Fail" }

    assert equal $result.type "failure"
}

# [test] warning status takes precedence over skipped
export def test_status_priority_warning_over_skipped [] {
    let result = 42
    | success "Start"
    | check { skipped "Skip" }
    | check { warning "Warn" }

    assert equal $result.type "warning"
}

# [test] warning status takes precedence over success
export def test_status_priority_warning_over_success [] {
    let result = 42
    | success "Start"
    | check { success "Good" }
    | check { warning "Warn" }

    assert equal $result.type "warning"
}

# ============================================================
# Collect Tests
# ============================================================

# [test] collect returns success message when no failures
export def test_collect_all_success [] {
    let result = 42
    | success "Start"
    | check { success "Good" }
    | collect

    assert equal ($result | length) 1
    assert equal $result.0.status "✅"
    assert equal $result.0.message "All validation checks passed"
}

# [test] collect filters out success messages by default
export def test_collect_filters_success [] {
    let result = 42
    | success "Start"
    | check { success "Good" }
    | check { failure "Bad" }
    | collect

    assert equal ($result | length) 1
    assert equal $result.0.status "❌"
}

# [test] collect includes success messages with verbose flag
export def test_collect_verbose_includes_success [] {
    let result = 42
    | success "Start"
    | check { success "Good" }
    | check { failure "Bad" }
    | collect --verbose

    assert equal ($result | length) 3
    assert ($result | any {|m| $m.status == "✅"})
}

# [test] collect returns failure messages with correct emoji
export def test_collect_failure_emoji [] {
    let result = 42
    | success "Start"
    | check { failure "Bad" }
    | collect

    assert equal $result.0.status "❌"
}

# [test] collect returns warning messages with correct emoji
export def test_collect_warning_emoji [] {
    let result = 42
    | success "Start"
    | check { warning "Warn" }
    | collect

    assert equal $result.0.status "❗"
}

# [test] collect returns skipped messages with correct emoji
export def test_collect_skipped_emoji [] {
    let result = 42
    | success "Start"
    | check { skipped "Skip" }
    | collect

    assert equal $result.0.status "💨"
}

# ============================================================
# Inspection Tests
# ============================================================

# [test] is-success returns true for success validation
export def test_is_success_true [] {
    let result = 42 | success "Good"
    assert ($result | is-success)
}

# [test] is-success returns false for failure validation
export def test_is_success_false [] {
    let result = 42 | failure "Bad"
    assert (not ($result | is-success))
}

# [test] is-failure returns true for failure validation
export def test_is_failure_true [] {
    let result = 42 | failure "Bad"
    assert ($result | is-failure)
}

# [test] is-failure returns false for success validation
export def test_is_failure_false [] {
    let result = 42 | success "Good"
    assert (not ($result | is-failure))
}

# [test] is-warning returns true for warning validation
export def test_is_warning_true [] {
    let result = 42 | warning "Warn"
    assert ($result | is-warning)
}

# [test] is-warning returns false for failure validation
export def test_is_warning_false [] {
    let result = 42 | failure "Bad"
    assert (not ($result | is-warning))
}

# ============================================================
# Utility Tests
# ============================================================

# [test] get-value extracts value from success validation
export def test_get_value_from_success [] {
    let result = 42 | success "Good" | get-value
    assert equal $result 42
}

# [test] get-value extracts value from failure validation
export def test_get_value_from_failure [] {
    let result = 42 | failure "Bad" | get-value
    assert equal $result 42
}

# [test] get-value preserves complex data structures
export def test_get_value_preserves_structure [] {
    let data = {name: "test", items: [1, 2, 3]}
    let result = $data | success "Good" | get-value

    assert equal $result.name "test"
    assert equal ($result.items | length) 3
}
