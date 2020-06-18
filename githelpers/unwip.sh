commit_message=$(git log -1 --pretty=%B)

if [ "$commit_message" == "wip" ]; then
   git reset @~
else
   echo Commit is not 'wip', but $commit_message
fi
