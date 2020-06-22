#!/bin/bash

set -e
# gets or sets global boolean variables by name and by owner (arbitrary string identifying the process)
# when getting the state, you must provide the variable name, and optionally a specific owner. 
# Returns the recursive OR on all non-expired matches and FALSE is no non-expired match is found.

# example usage:
# globals set "varname" "ownername" "expiration_duration"   # duration is in seconds
# globals get "varname" "ownername"?
# globals unset "varname" ("ownername"|"*")
# globals wait "varname" (TRUE|FALSE)?
# globals wait "varname" "ownername" (TRUE|FALSE)?

DIR="$HOME/.globals"
SEP=" "
MODE=$1
VAR=$2
OWNER=$3
EXPIRATION_DURATION=$4
FILE=$DIR/$VAR
N_ARGS=$(($# - 1))

# argument validation
if [[ "$MODE" == "get" ]] ; then
    if [[ $N_ARGS -ne 1 ]] && [[ $N_ARGS -ne 2 ]]; then 
        echo "Expected 1 or 2 arguments after '$MODE'; got $N_ARGS"
        exit 1
    fi
elif [[ "$MODE" == "set" ]] ; then
    if [[ $N_ARGS -ne 3 ]]; then 
        echo "Expected 3 arguments after '$MODE'; got $N_ARGS"
        exit 1
    fi
    EXPIRATION_DURATION=$(($EXPIRATION_DURATION * 1000))
elif [[ "$MODE" == "unset" ]] ; then
    if [[ $N_ARGS -ne 2 ]]; then 
        echo "Expected 2 arguments after '$MODE'; got $N_ARGS"
        if [[ $N_ARGS -eq 1 ]]; then 
            echo 'To unset all owners of a variable, specify "*"'
        fi
        exit 1
    fi
elif [[ "$MODE" == "wait" ]] ; then
    if [[ $N_ARGS -eq 1 ]] ; then  # only get VAR
        OWNER=""
        WAIT=FALSE
    elif [[ $N_ARGS -eq 2 ]]; then # got VAR, and owner or wait
        WAIT=$(echo "$3" | tr a-z A-Z)
        if [[ $WAIT == "FALSE" ]] || [[ $WAIT == "TRUE" ]]; then
            OWNER=""
        else
            WAIT=FALSE
        fi
    elif [[ $N_ARGS -eq 3 ]]; then 
        echo "$4"
        WAIT=$(echo "$4" | tr a-z A-Z)
        EXPIRATION_DURATION=""
        if [[ $WAIT != "FALSE" ]] && [[ $WAIT != "TRUE"  ]]; then
            echo "Invalid 3rd argument after wait. Expected TRUE or FALSE, got '$4'"
            exit 0
        fi
    else 
        echo "Expected 1, 2, or 3 arguments after '$MODE'; got $N_ARGS"
        exit 0
    fi
elif [[ "$MODE" == "get_remaining_time" ]] ; then
    if [[ $N_ARGS -ne 1 ]] && [[ $N_ARGS -ne 2 ]]; then 
        echo "Expected 1 or 2 arguments after '$MODE'; got $N_ARGS"
        exit 1
    fi
else
    echo "Unexpected first argument. Expected 'get' or 'set'; got '$1'"
    exit 1
fi

# ensure directory and file exist
mkdir -p $DIR
touch $FILE

current_time=$(date +%s%3N)

if [[ "$MODE" == "get" ]]; then
    if [ -f "$FILE" ]; then
        while read -r line
        do
            expiration_timestamp=${line/*$SEP/}
 
            if [ "$expiration_timestamp" -ge "$current_time" ]; then 
                if [[ $OWNER == "" ]] || [[ "$line" == $OWNER$SEP* ]]; then
                    echo TRUE
                    exit 0
                fi
            fi
        done < "$FILE"
    fi

    echo FALSE
    exit 0

elif [[ "$MODE" == "set" ]] ; then
    expiration_timestamp=$(($current_time + $EXPIRATION_DURATION))
    line=$OWNER$SEP$expiration_timestamp
    echo "$line" >> $FILE
elif [[ "$MODE" == "unset" ]] ; then
    if [[ "$OWNER" == "*" ]] ; then 
        rm $FILE
        echo "Number of entries unset for '$VAR': all"
        exit 0
    fi

    TMP_FILE=$FILE.tmp
    touch $TMP_FILE
    ENTRIES_UNSET=0

    while read -r line
    do
        expiration_timestamp=${line/*$SEP/}
        # copy over lines not related to the specified owner
        # such that in effect it's unset
        # as a bonus skip the non-expired lines, cleaning up
        if [ "$expiration_timestamp" -ge "$current_time" ]; then 
            if [[ "$line" != $OWNER$SEP* ]]; then
                echo "$line" >> $TMP_FILE
            else
                ENTRIES_UNSET=$(($ENTRIES_UNSET + 1))
            fi
        fi
    done < "$FILE"
    
    cp -f $TMP_FILE $FILE
    rm $TMP_FILE
    echo "Number of entries unset for '$VAR': $ENTRIES_UNSET"

elif [[ "$MODE" == "wait" ]] ; then
    while :
    do
        output=$(bash $0 get $VAR $OWNER)
        if [[ $output == *$WAIT ]] ;then
            exit 0
        fi
        sleep .1
    done
fi
