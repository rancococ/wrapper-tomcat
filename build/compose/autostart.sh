#!/usr/bin/env bash

##########################################################################
# autostart.sh
# --enable   : enable autostart
# --disable  : disable autostart
##########################################################################

# set -x
set -e

# set author info
date1=`date "+%Y-%m-%d %H:%M:%S"`
date2=`date "+%Y%m%d%H%M%S"`
author="yong.ran@cdjdgm.com"

set -o noglob

# init font and color 
if [ "${TERM}" == "xterm" ]; then
    bold=$(tput bold); underline=$(tput sgr 0 1); reset=$(tput sgr0);
    red=$(tput setaf 1); green=$(tput setaf 2); yellow=$(tput setaf 3); blue=$(tput setaf 4); white=$(tput setaf 7);
else
    bold=""; underline=""; reset="";
    red=""; green=""; yellow=""; blue=""; white="";
fi

# header and logging
header() { printf "\n${underline}${bold}${blue}> %s${reset}\n" "$@"; }
header2() { printf "\n${underline}${bold}${blue}>> %s${reset}\n" "$@"; }
info() { printf "${white}➜ %s${reset}\n" "$@"; }
warn() { printf "${yellow}➜ %s${reset}\n" "$@"; }
error() { printf "${red}✖ %s${reset}\n" "$@"; }
success() { printf "${green}✔ %s${reset}\n" "$@"; }
usage() { printf "\n${underline}${bold}${blue}Usage:${reset} ${blue}%s${reset}\n" "$@"; }

trap "error '******* ERROR: Something went wrong.*******'; exit 1" sigterm
trap "error '******* Caught sigint signal. Stopping...*******'; exit 2" sigint

set +o noglob

# entry base dir
pwd=`pwd`
base_dir="${pwd}"
source="$0"
while [ -h "$source" ]; do
    base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$base_dir/$source"
done
base_dir="$( cd -P "$( dirname "$source" )" && pwd )"
cd "${base_dir}"

# envirionment

# args flag
arg_help=
arg_enable=
arg_disable=
arg_empty=true

# parse parameter
# echo $@
# define options, -o : short options, -a : simple mode for long options (starts with -), -l : long options
# no colon after, indicating no parameter
# followed by a colon to indicate that there is a required parameter
# followed by two colons to indicate that there is an optional parameter (the optional parameter must be next to the option)
# -n information on error
# -- it is also an option. for example, to create a directory named "-f", "mkdir -- -f" will be used
# $@ take the parameter list from the command line
# args=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "${source}" -- "$@"`
args=`getopt -o h -a -l help,enable,disable -n "${source}" -- "$@"`
# terminate the execution when there is an error in the execution of getopt
if [ $? != 0 ]; then
    error "terminating..." >&2
    exit 1
fi
# echo ${args}
# reorder parameters(The purpose of using eval is to prevent the shell command in the parameter from being extended by mistake)
eval set -- "${args}"
# handling specific options
while true
do
    case "$1" in
        -h | --help | -help)
            info "option -h|--help"
            arg_help=true
            arg_empty=false
            shift
            ;;
        --enable | -enable)
            info "option --enable"
            arg_enable=true
            arg_empty=false
            shift
            ;;
        --disable | -disable)
            info "option --disable"
            arg_disable=true
            arg_empty=false
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            error "internal error!"
            exit 1
            ;;
    esac
done
# display parameters other than options (parameters without options will be last)
# arg is the built-in variable of getopt. the value in arg is $@ (the parameter passed in from the command line) after processing
for arg do
   warn "$arg";
done

##########################################################################

# show usage
usage=$"`basename $0` [-h|--help] [--enable] [--disable]
       [-h|--help]
                       show help info.
       [--enable]
                       enable autostart.
       [--disable]
                       disable autostart.
"

# enable autostart
fun_enable_autostart() {
    header "enable autostart : "
    info "enable autostart : ${base_dir}/compose.yml"
    sed -i "s/restart:\ \"no\"/restart:\ \"always\"/g" ${base_dir}/compose.yml
    success "successfully enabled autostart"
    return 0
}

# disable autostart
fun_disable_autostart() {
    header "disable autostart : "
    info "disable autostart : ${base_dir}/compose.yml"
    sed -i "s/restart:\ \"always\"/restart:\ \"no\"/g" ${base_dir}/compose.yml
    success "successfully disabled autostart"
    return 0
}

##########################################################################

# argument is empty
if [ "x${arg_empty}" == "xtrue" ]; then
    usage "$usage";
    exit 1
fi

# show usage
if [ "x${arg_help}" == "xtrue" ]; then
    usage "$usage";
    exit 1
fi

# enable autostart
if [ "x${arg_enable}" == "xtrue" ]; then
    fun_enable_autostart;
fi

# disable autostart
if [ "x${arg_disable}" == "xtrue" ]; then
    fun_disable_autostart;
fi


echo ""

# exit $?
