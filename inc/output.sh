#!/bin/bash 
#
#   Some useful functions to make a nice output
#   Author: funkym0nk3y
#   Email: funkym0nk3y@linuxm0nk3ys.vpn
#   Web: https://evilshit.wordpress.com
#

#
#   Some color and column definitions
#
RES_COL=60
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_WARNING="echo -en \\033[1;33m"
SETCOLOR_NORMAL="echo -en \\033[1;39m"

#
#   These functions are copies from the
#   functions.sh (located at /etc/init.d [Slackware])
#   and are not written by me.
#

#
#   TODO
#
echo_success() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_SUCCESS
    echo -n "  OK  "
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 0
}


#
#   TODO
#
echo_failure() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_FAILURE
    echo -n "FAILED"
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 0
}


#
#   TODO
#
echo_passed() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_WARNING
    echo -n "PASSED"
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 0
}


#
#   TODO
#
echo_warning() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_WARNING
    echo -n "WARNING"
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 0
}


#
#   written by funkym0nk3y
#

#
#   Prints some debug information
#   Parameter:
#   $1  name of function 
#   $2  "var" = print variable value 
#   $3  name of variable
#   $4  value of variable
echo_debug() {
    $SETCOLOR_WARNING
    case $2 in 
        "var")
            echo "DEBUG [$1]: variable $3: $4"
            ;;
        *)
            echo_error $FUNCNAME "INVALID PARAMETER \$2: $2"
    esac
    $SETCOLOR_NORMAL
}


#
#   Prints a colored error message.
#   Parameter:
#   $1  name of the function, if the function is empty, it will be the error message
#   $2  error message
echo_error() {
    $SETCOLOR_FAILURE
    if [ $# -eq 2 ]
    then
        echo "ERROR in function $1: $2"
    elif [ $# -eq 1 ]
    then
        echo "ERROR: $1"
    else
        echo "ERROR"
    fi
    $SETCOLOR_NORMAL
}

#
#   Prints the information of the ca. It prints the current ca, the path to the private key and the certificate. 
#   Parameter:
#   $1  string with current ca 
#   $2  path to private key 
#   $3  path to certificate 
echo_ca_info() {
    if [[ $1 =~ CA_[[:graph:]]+ ]]; then
        echo " Current CA: ${1#CA_}"
    fi
    echo -n "Private Key: "
    if [ ! -z $2 ] && [ -s $2 ]; then
        $SETCOLOR_SUCCESS
        echo $2
    else
        $SETCOLOR_FAILURE
        echo $2
    fi
    $SETCOLOR_NORMAL
    echo -n "Certificate: "
    if [ ! -z $3 ] && [ -s $3 ]; then
        $SETCOLOR_SUCCESS
        echo $3
    else
        $SETCOLOR_FAILURE
        echo $3 
    fi
    $SETCOLOR_NORMAL
    echo -e "\n"
}

