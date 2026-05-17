#
# Test map1 function
#
use std/assert
use ../../result

# ============================================================
# Test Functions
# ============================================================

# [test] transforms Ok value with unary function
def test-map1-ok [] {
    let result = (result map1 { $in * 2 } (21 | result ok))
    assert equal $result {type: "ok", value: 42}
}

# [test] returns Err when given Err
def test-map1-err [] {
    let result = (result map1 { $in * 2 } ("bad data" | result safely { error make {msg: "invalid input"} }))
    assert equal $result.type "err"
    assert equal $result.error.msg "invalid input"
    assert equal $result.data "bad data"
}

# [test] works with string transformation
def test-map1-string [] {
    let result = (result map1 { str upcase } ("hello" | result ok))
    assert equal $result {type: "ok", value: "HELLO"}
}

# [test] works with list operations
def test-map1-list [] {
    let result = (result map1 { length } ([1, 2, 3] | result ok))
    assert equal $result {type: "ok", value: 3}
}

# [test] works with record access
def test-map1-record [] {
    let result = (result map1 { $in.name } ({name: "test", value: 42} | result ok))
    assert equal $result {type: "ok", value: "test"}
}

# [test] chains with other Result operations
def test-map1-chain [] {
    let result = (result map1 { $in + 10 } (32 | result ok) | result unwrap)
    assert equal $result 42
}

# [test] preserves Err through multiple operations
def test-map1-err-chain [] {
    let result = (result map1 { $in * 2 } ("data" | result safely { error make {msg: "failed"} }) | result map { $in + 1 })
    assert equal $result.type "err"
    assert equal $result.error.msg "failed"
    assert equal $result.data "data"
}

# [test] works with error recovery
def test-map1-with-or-else [] {
    let result = (result map1 { $in * 2 } ("x" | result safely { error make {msg: "failed"} }) | result or-else { 0 | result ok })
    assert equal $result {type: "ok", value: 0}
}

# [test] preserves error information
def test-map1-preserves-error [] {
    let err_result = ("test data" | result safely { error make {msg: "validation failed"} })
    let result = (result map1 { str length } $err_result)
    assert equal $result $err_result
}
