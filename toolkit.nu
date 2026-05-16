# nu-monas development toolkit

# Run all tests
export def "run tests" [] {
    print "Running nu-monas test suite..."
    nutest run-tests --path nu-monas/
}

# Verify module loads cleanly
export def "check load" [] {
    print "Verifying module load..."
    ^nu -c "use nu-monas; print '✓ nu-monas loaded'"
    ^nu -c "use nu-monas/option; 42 | option some | option unwrap | if $in == 42 { print '✓ option works' }"
    ^nu -c "use nu-monas/result; 42 | result ok | result unwrap | if $in == 42 { print '✓ result works' }"
    ^nu -c "use nu-monas/validation; 42 | validation success 'ok' | validation is-success | if $in { print '✓ validation works' }"
    print "All checks passed."
}

# List all exported commands
export def "list commands" [] {
    print "=== Option ==="
    scope commands | where name =~ "^option" | select name usage | print
    print "\n=== Result ==="
    scope commands | where name =~ "^result" | select name usage | print
    print "\n=== Validation ==="
    scope commands | where name =~ "^validation" | select name usage | print
}
