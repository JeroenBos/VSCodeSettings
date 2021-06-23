set -eu


if [ "$#" -gt 0 ]; then
    git stash -u
    git checkout master
    git pull
    git checkout -b "$1"
    git stash pop

else
    echo "Branch name is required"
    exit 1
fi