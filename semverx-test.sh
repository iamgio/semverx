#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEMVERX="$SCRIPT_DIR/semverx.sh"

passed=0
failed=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

assert_eq() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((passed++))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((failed++))
    fi
}

assert_contains() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((passed++))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected to contain: $expected"
        echo "  Actual: $actual"
        ((failed++))
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((passed++))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        ((failed++))
    fi
}

cleanup() {
    # Remove test tags
    git tag -d v1.0.0 v1.0.1 v2.0.0 v2.1.0 release-1.0.0 2>/dev/null || true
}

# Cleanup before and after tests
trap cleanup EXIT
cleanup

echo "Running semverx tests..."
echo ""

# Test: Help output
output=$("$SEMVERX" --help)
assert_contains "bump-tag" "$output" "help shows bump-tag command"

# Test: Error when no tags exist
output=$("$SEMVERX" bump-tag patch 2>&1 || true)
assert_contains "No tags found" "$output" "error when no tags exist"

# Test: Error on missing bump type
output=$("$SEMVERX" bump-tag 2>&1 || true)
assert_contains "Missing bump type" "$output" "error on missing bump type"

# Test: Error on unknown argument
output=$("$SEMVERX" bump-tag patch --unknown 2>&1 || true)
assert_contains "Unknown argument" "$output" "error on unknown argument"

# Create test tag
git tag v1.0.0

# Test: Patch bump
output=$("$SEMVERX" bump-tag patch)
assert_eq "v1.0.1" "$output" "patch bump v1.0.0 -> v1.0.1"

# Test: Minor bump
output=$("$SEMVERX" bump-tag minor)
assert_eq "v1.1.0" "$output" "minor bump v1.0.0 -> v1.1.0"

# Test: Major bump
output=$("$SEMVERX" bump-tag major)
assert_eq "v2.0.0" "$output" "major bump v1.0.0 -> v2.0.0"

# Test: --tag creates a new tag
"$SEMVERX" bump-tag patch --tag >/dev/null
tag_exists=$(git tag -l "v1.0.1")
assert_eq "v1.0.1" "$tag_exists" "--tag creates new git tag"

# Test: Bumps from latest tag
output=$("$SEMVERX" bump-tag patch)
assert_eq "v1.0.2" "$output" "bumps from latest tag (v1.0.1 -> v1.0.2)"

# Test: Custom prefix
git tag release-1.0.0
output=$("$SEMVERX" bump-tag patch --prefix "release-")
assert_eq "release-1.0.1" "$output" "custom prefix release-1.0.0 -> release-1.0.1"

# Add more tags to test version sorting
git tag v2.0.0
git tag v2.1.0

# Test: Uses highest version tag
output=$("$SEMVERX" bump-tag patch)
assert_eq "v2.1.1" "$output" "uses highest version tag (v2.1.0 -> v2.1.1)"

echo ""
echo "---"
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
