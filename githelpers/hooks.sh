#!/bin/sh

# An example hook script to verify what is about to be pushed.  Called by "git
# push" after it has checked the remote status, but before anything has been
# pushed. If this script exits with a non-zero status nothing will be pushed.
#
# This hook is called with the following parameters:
#
# $1 -- Name of the remote to which the push is being done
# $2 -- URL to which the push is being done
#
# If pushing without using a named remote those arguments will be equal.
#
# Information about the commits which are being pushed is supplied as lines to
# the standard input in the form:
#
#   <local ref> <local oid> <remote ref> <remote oid>
#

remote="$1"
url="$2"

zero=$(git hash-object --stdin </dev/null | tr '[0-9a-f]' '0')

while read local_ref local_oid remote_ref remote_oid
do
	if test "$local_oid" = "$zero"
	then
		# Handle delete
		:
	else
		if test "$remote_oid" = "$zero"
		then
			# New branch, examine all commits
			range="$local_oid"
		else
			# Update to existing branch, examine new commits
			range="$remote_oid..$local_oid"
		fi

		# Check for WIP commit
		commit=$(git rev-list -n 1 --grep '^[Ww][Ii][Pp]' "$range")
		if test -n "$commit"
		then
			echo >&2 "Found WIP commit in $local_ref, not pushing"
			exit 1
		fi

		commit=$(git rev-list -n 1 --grep '^TBF' "$range")
		if test -n "$commit"
		then
			echo >&2 "Found TBF commit in $local_ref, not pushing"
			exit 1
		fi

		commit=$(git rev-list -n 1 --grep '^fixup!' "$range")
		if test -n "$commit"
		then
			echo >&2 "Found fixup! commit in $local_ref, not pushing"
			exit 1
		fi
	fi
	
	# Block commit if it contains 🚧. FILE_PATTERN doesn't filter anything atm
	PY_LINES_ADDED=$(git diff "$range" -- '*.py' | grep '^+' | grep -v '^+++' | grep '\sprint(')
	if [ -z "$LINES_ADDED" ]; then
		echo "Found print statement, not pushing"
		echo "\e[93m$LINES_ADDED\e[0m"
		exit 1
	fi

	LINES_ADDED=$(git diff @~ @ | grep '^+' | grep -v '^+++' | grep '🚧')
	if [ -z "$LINES_ADDED" ]; then
		echo "Found 🚧, not pushing"
		exit 1
	fi
done


