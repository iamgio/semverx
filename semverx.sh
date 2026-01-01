#!/bin/bash

set -e

SCRIPT_PATH="${BASH_SOURCE[0]}"
if [[ -L "$SCRIPT_PATH" ]]; then
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SEMVER="$SCRIPT_DIR/semver/src/semver"

usage() {
    cat <<EOF
Usage:
  semverx bump-tag [major|minor|patch] [options]

Options:
  --tag       Create a new git tag with the bumped version
  --push      Push the new tag to remote (implies --tag)
  --prefix    Tag prefix (default: "v")
  --help      Show this help message

Examples:
  semverx bump-tag patch
  semverx bump-tag minor --tag --push
  semverx bump-tag patch --prefix ""
EOF
}

error() {
    echo "Error: $1" >&2
    exit 1
}

bump_git_tag() {
    local bump_type=""
    local do_tag=false
    local do_push=false
    local prefix="v"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            major|minor|patch)
                bump_type="$1"
                shift
                ;;
            --tag)
                do_tag=true
                shift
                ;;
            --push)
                do_push=true
                do_tag=true
                shift
                ;;
            --prefix)
                shift
                prefix="${1:-}"
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                ;;
        esac
    done

    # Validate bump type
    if [[ -z "$bump_type" ]]; then
        error "Missing bump type. Must be one of: major, minor, patch"
    fi

    # Get latest tag with prefix
    local latest_tag
    latest_tag=$(git tag --list "${prefix}*" --sort=-v:refname | head -n1)

    if [[ -z "$latest_tag" ]]; then
        error "No tags found with prefix '$prefix'"
    fi

    # Strip prefix and bump version
    local version="${latest_tag#"$prefix"}"
    local new_version
    new_version=$("$SEMVER" bump "$bump_type" "$version")

    # Re-add prefix
    local new_tag="${prefix}${new_version}"

    # Output the new version
    echo "$new_tag"

    # Create tag if requested
    if [[ "$do_tag" == true ]]; then
        git tag "$new_tag"
    fi

    # Push if requested
    if [[ "$do_push" == true ]]; then
        git push origin "$new_tag"
    fi
}

# Main command dispatch
case "${1:-}" in
    bump-tag)
        shift
        bump_git_tag "$@"
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        error "Unknown command: $1"
        ;;
esac
