#!/usr/bin/env nu
#
# Test error handling for Option functions with non-monadic inputs
#

use std/assert
use ../../option
use ../../result

# ============================================================
# Test Functions
# ============================================================

# [test] or-else rejects non-monadic input with clear error
def test-or-else-non-monadic [] {
    assert error {
        42 | option or-else { 0 | option some }
    }
}

# [test] map rejects non-monadic input with clear error
def test-map-non-monadic [] {
    assert error {
        42 | option map { $in * 2 }
    }
}

# [test] and-then rejects non-monadic input with clear error
def test-and-then-non-monadic [] {
    assert error {
        "hello" | option and-then { str length | option some }
    }
}

# [test] is-some rejects non-monadic input with clear error
def test-is-some-non-monadic [] {
    assert error {
        42 | option is-some
    }
}

# [test] is-none rejects non-monadic input with clear error
def test-is-none-non-monadic [] {
    assert error {
        null | option is-none
    }
}

# [test] unwrap rejects non-monadic input with clear error
def test-unwrap-non-monadic [] {
    assert error {
        "value" | option unwrap
    }
}

# [test] unwrap-or rejects non-monadic input with clear error
def test-unwrap-or-non-monadic [] {
    assert error {
        [1, 2, 3] | option unwrap-or []
    }
}

# [test] expect rejects non-monadic input with clear error
def test-expect-non-monadic [] {
    assert error {
        {name: "test"} | option expect "Should have value"
    }
}

# [test] keep-if rejects non-monadic input with clear error
def test-keep-if-non-monadic [] {
    assert error {
        42 | option keep-if { $in > 0 }
    }
}

# [test] flatten rejects non-monadic input with clear error
def test-flatten-non-monadic [] {
    assert error {
        42 | option unnest
    }
}

# [test] or-else rejects wrong monad type with clear error  
def test-or-else-wrong-monad [] {
    assert error {
        42 | result ok | option or-else { 0 | option some }
    }
}

# [test] map rejects null input with clear error
def test-map-null [] {
    assert error {
        null | option map { $in * 2 }
    }
}

# [test] validate-option accepts valid some
def test-validate-accepts-some [] {
    let result = 42 | option some | option is-some
    assert equal $result true
}

# [test] validate-option accepts valid none
def test-validate-accepts-none [] {
    let result = option none | option is-none
    assert equal $result true
}