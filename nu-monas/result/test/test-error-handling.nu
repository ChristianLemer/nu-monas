#!/usr/bin/env nu
#
# Test error handling for Result functions with non-monadic inputs
#

use std/assert
use ../../result
use ../../option

# ============================================================
# Test Functions
# ============================================================

# [test] or-else rejects non-monadic input with clear error
def test-or-else-non-monadic [] {
    assert error {
        42 | result or-else { 0 | result ok }
    }
}

# [test] map rejects non-monadic input with clear error
def test-map-non-monadic [] {
    assert error {
        42 | result map { $in * 2 }
    }
}

# [test] map-err rejects non-monadic input with clear error
def test-map-err-non-monadic [] {
    assert error {
        "error" | result map-err { $"prefix: ($in)" }
    }
}

# [test] and-then rejects non-monadic input with clear error
def test-and-then-non-monadic [] {
    assert error {
        "hello" | result and-then { str length | result ok }
    }
}

# [test] is-ok rejects non-monadic input with clear error
def test-is-ok-non-monadic [] {
    assert error {
        42 | result is-ok
    }
}

# [test] is-err rejects non-monadic input with clear error
def test-is-err-non-monadic [] {
    assert error {
        null | result is-err
    }
}

# [test] unwrap rejects non-monadic input with clear error
def test-unwrap-non-monadic [] {
    assert error {
        "value" | result unwrap
    }
}

# [test] unwrap-or rejects non-monadic input with clear error
def test-unwrap-or-non-monadic [] {
    assert error {
        [1, 2, 3] | result unwrap-or []
    }
}

# [test] unwrap-err rejects non-monadic input with clear error
def test-unwrap-err-non-monadic [] {
    assert error {
        "error" | result unwrap-err
    }
}

# [test] expect rejects non-monadic input with clear error
def test-expect-non-monadic [] {
    assert error {
        {name: "test"} | result expect "Should have value"
    }
}

# [test] flatten rejects non-monadic input with clear error
def test-flatten-non-monadic [] {
    assert error {
        42 | result unnest
    }
}

# [test] or-else rejects wrong monad type with clear error
def test-or-else-wrong-monad [] {
    assert error {
        42 | option some | result or-else { 0 | result ok }
    }
}

# [test] map rejects null input with clear error
def test-map-null [] {
    assert error {
        null | result map { $in * 2 }
    }
}

# [test] validate-result accepts valid ok
def test-validate-accepts-ok [] {
    let result = 42 | result ok | result is-ok
    assert equal $result true
}

# [test] validate-result accepts valid err
def test-validate-accepts-err [] {
    let result = "data" | result safely { error make {msg: "failed"} } | result is-err
    assert equal $result true
}
