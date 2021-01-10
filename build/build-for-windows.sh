#!/usr/bin/env bash

##########################################################################
# build tomcat for windows
# for centos 7.x
# author : yong.ran@cdjdgm.com
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
header() { printf "\n${underline}${bold}${blue}■ %s${reset}\n" "$@"; }
header2() { printf "\n${underline}${bold}${blue}❏ %s${reset}\n" "$@"; }
info() { printf "${white}➜ %s${reset}\n" "$@"; }
warn() { printf "${yellow}➜ %s${reset}\n" "$@"; }
error() { printf "${red}✖ %s${reset}\n" "$@"; }
success() { printf "${green}✔ %s${reset}\n" "$@"; }
usage() { printf "\n${underline}${bold}${blue}Usage:${reset} ${blue}%s${reset}\n" "$@"; }

# trap signal
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
product_name="wrapper-tomcat"
version=3.5.43.7
jre_version=1.8.192
tomcat_version=8.5.57
wrapper_version=3.5.43.7
serverjre=server-jre-8u192-windows-x64.tar.gz
arch=x86_64

build_name="$(cat /proc/sys/kernel/random/uuid)"
build_home=/tmp/${build_name}

# args flag
arg_help=
arg_build=
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
args=`getopt -o h -a -l help,build -n "${source}" -- "$@"`
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
        --build | -build)
            info "option --build"
            arg_build=true
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
usage=$"`basename $0` [-h|--help] [--build]
       [-h|--help]
                  show help info.
       [--build]
                  build ${product_name}.
"

# build
fun_build() {
    header "build ${product_name} : "

    info "init directory"
    \rm -rf "${build_home}"
    mkdir -p "${build_home}/${product_name}/jre"

    info "unzip jre"
    tar_first_name=$(tar -tf ${base_dir}/windows/${serverjre} | awk -F "/" '{print $1}' | sed -n '1p') && \
    tar --no-same-owner -zxf ${base_dir}/windows/${serverjre} --directory=${build_home}/${product_name}/jre ${tar_first_name}/jre --strip-components=2 && \
    sed -i 's@securerandom.source=file:/dev/random@securerandom.source=file:/dev/urandom@g' "${build_home}/${product_name}/jre/lib/security/java.security" && \
    sed -i 's@#crypto.policy=unlimited@crypto.policy=unlimited@g' "${build_home}/${product_name}/jre/lib/security/java.security"

    info "copy files"
    \cp -rf ${base_dir}/../source/. ${build_home}/${product_name}

    info "generate version info"
    touch ${build_home}/${product_name}/bin/version && \
    echo "jre:${jre_version}"          >> ${build_home}/${product_name}/bin/version && \
    echo "tomcat:${tomcat_version}"    >> ${build_home}/${product_name}/bin/version && \
    echo "wrapper:${wrapper_version}"  >> ${build_home}/${product_name}/bin/version

    info "change file permissions"
    find "${build_home}/${product_name}" -exec touch {} \; && \
    find "${build_home}/${product_name}" -type d -exec chmod 755 {} \; && \
    find "${build_home}/${product_name}" -type f -exec chmod 644 {} \; && \
    find "${build_home}/${product_name}" -type f -name ".keep" -exec rm -rf {} \;

    chmod 744 ${build_home}/${product_name}/jre/bin/* && \
    chmod 744 ${build_home}/${product_name}/bin/* && \
    chmod 644 ${build_home}/${product_name}/bin/*.bat && \
    chmod 644 ${build_home}/${product_name}/bin/*.exe && \
    chmod 644 ${build_home}/${product_name}/bin/*.jar && \
    chmod 644 ${build_home}/${product_name}/bin/*.cnf && \
    chmod 644 ${build_home}/${product_name}/bin/version && \
    chmod 600 ${build_home}/${product_name}/conf/*.password && \
    chmod 777 ${build_home}/${product_name}/logs && \
    chmod 777 ${build_home}/${product_name}/temp

    tar -C "${build_home}" -czf "${base_dir}"/${product_name}-${version}-windows-${arch}.tar.gz "${product_name}"

    \rm -rf "${build_home}"

    success "successfully builded ${product_name}."

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

# build
if [ "x${arg_build}" == "xtrue" ]; then
    fun_build;
fi

echo ""

# exit $?
