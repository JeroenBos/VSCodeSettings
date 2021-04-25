git merge HEAD &> /dev/null
result=$?
if [ $result -ne 0 ]
then #  Merge in progress
    git add .
    git commit -anm "wip"
else
    git add .
    git commit -anm "wip"
fi

