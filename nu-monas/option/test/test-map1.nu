#
# Test map1 function
#
use std/assert
use ../../option

# ============================================================
# Test Functions
# ============================================================

# [test] transforms Some value with unary function
def test-map1-some [] {
    let result = (option map1 { $in * 2 } (21 | option some))
    assert equal $result {type: "some", value: 42}
}

# [test] returns None when given None
def test-map1-none [] {
    let result = (option map1 { $in * 2 } (option none))
    assert equal $result {type: "none"}
}

# [test] works with string transformation
def test-map1-string [] {
    let result = (option map1 { str upcase } ("hello" | option some))
    assert equal $result {type: "some", value: "HELLO"}
}

# [test] works with list operations
def test-map1-list [] {
    let result = (option map1 { length } ([1, 2, 3] | option some))
    assert equal $result {type: "some", value: 3}
}

# [test] works with record access
def test-map1-record [] {
    let result = (option map1 { $in.name } ({name: "test", value: 42} | option some))
    assert equal $result {type: "some", value: "test"}
}

# [test] chains with other Option operations
def test-map1-chain [] {
    let result = (option map1 { $in + 10 } (32 | option some) | option unwrap)
    assert equal $result 42
}

# [test] preserves None through multiple operations
def test-map1-none-chain [] {
    let result = (option map1 { $in * 2 } (option none) | option map { $in + 1 })
    assert equal $result {type: "none"}
}