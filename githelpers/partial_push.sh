set -eu

BRANCH_NAME="refs/heads/$(git branch --show-current)"


if [ "$#" -gt 0 ]; then
    REF="$1"
    shift

    # "$@" can be -f for instance
    git push "$@" origin "$REF":"$BRANCH_NAME"
else
    echo "fatal: A commit reference is required"
    exit 1
fi


