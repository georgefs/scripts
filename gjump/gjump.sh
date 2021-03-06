#! /bin/bash
#
# gjump.sh
# Copyright (C) 2013 george <george@george-VirtualBox>
#
# Distributed under terms of the MIT license.
#

#JUMP_HISTORY_FILE=/tmp/`python  -c 'import uuid; print uuid.uuid1()'`.jumplist
JUMP_HISTORY_FILE=/tmp/$USER.jumplist
JUMP_POINT=0
JUMP_FLAG=0
LIST_RANGE=5
##  https://zipizap.wordpress.com/2011/09/28/quick-bash-colors/
COLOR='[41m[37m'
COLOR_END='[0m'

touch $JUMP_HISTORY_FILE


function jump_log {
#log jump path
    test ! -e $JUMP_HISTORY_FILE && touch $JUMP_HISTORY_FILE

    JUMP_POINT=0
    cur=`pwd`
    cur_pattern=`echo $cur|sed 's/\//\\\\\//g'`

    sed "/^$cur_pattern$/d" $JUMP_HISTORY_FILE > ${JUMP_HISTORY_FILE}.tmp 
    mv ${JUMP_HISTORY_FILE}.tmp $JUMP_HISTORY_FILE
    echo $cur >> $JUMP_HISTORY_FILE
}

function jump_cd {
    target=$1
    if ! [ -d $1 ]; then
        target=`dirname $1`
    fi
    \cd $target
    jump_log
}

function jump {
    JUMP_TABLE=`tail -r $JUMP_HISTORY_FILE|cat -n|tail -r`
    JUMP_POINT=$(echo "$JUMP_TABLE"|awk '{if($2=="'`pwd`'"){print $1}}')

    if [ ! -z "${num##*[!0-9]*}" ] ; then
        jump_log
        JUMP_POINT=1
    fi

    case $1 in
    "state")
        echo "JUMP_HISTORY_FILE at $JUMP_HISTORY_FILE"
        echo "JUMP_POINT at $JUMP_POINT"
        return
    ;;
    "list")
        LIST=`echo "$JUMP_TABLE"|sed -e "s/^[ \t]*$JUMP_POINT\s\+.*$/$COLOR&$COLOR_END/"|more`
        if [ $2 ] ; then
            echo "$LIST"|tail -n $(($2 + $JUMP_POINT))|head -n $(($2 + $2 + 1))
        else
            echo "$LIST"
        fi
        return
    ;;
    "clear")
    #remove jump list
        rm $JUMP_HISTORY_FILE && touch $JUMP_HISTORY_FILE
        jump_log
        JUMP_POINT=0
        return
    ;;
    "-")
    #goto prev jump path
        JUMP_POINT_MAX=`cat $JUMP_HISTORY_FILE|wc -l`
        if [ $JUMP_POINT -ge $JUMP_POINT_MAX ]; then
            echo 'first jump'
            return
        fi
        JUMP_POINT=$[ $JUMP_POINT+1 ]
    ;;
    "+")
    #goto next jump path
        if [ $JUMP_POINT -le 1 ]; then
            echo 'latest jump'
            return
        fi
        JUMP_POINT=$[ $JUMP_POINT - 1 ]
    ;;
    [0-9]*)
        JUMP_POINT_MAX=`cat $JUMP_HISTORY_FILE|wc -l`
        if [ $1 -le $JUMP_POINT_MAX ] && [ $1 -ge 0 ] ; then
            JUMP_POINT=$[ $1 ]
            echo $JUMP_POINT
        fi
    ;;
    *)

        if [ $1 ] ; then
            line=`echo "$JUMP_TABLE"|grep $1|awk '{print length, $1}'|sort -n|awk '{print $2}'|head -n 1`
            if [[ $line =~ '^[0-9]+$' ]] ; then
                JUMP_POINT=$line    
            else
                echo "not match anything"
            fi
        fi
    ;;
    esac
    JUMP_PATH=`cat $JUMP_HISTORY_FILE|tail -n$JUMP_POINT|head -n1`
    \cd $JUMP_PATH
    if [ -z "$1" ]; then
        jump list
    else
        jump list $LIST_RANGE

    fi
}

alias cd='jump_cd'
alias j='jump'
alias jp="jump -"
alias jn="jump +"
