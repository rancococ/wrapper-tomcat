#!/bin/bash

##########################################################################
# build for docker
# for centos 7.x
# author : yong.ran@cdjdgm.com
# require : docker
##########################################################################

# local variable
step=1

set -e
set -o noglob

# save old work path
pwd_old=`pwd`

# set author info
date1=`date "+%Y-%m-%d %H:%M:%S"`
date2=`date "+%Y%m%d%H%M%S"`
author="yong.ran@cdjdgm.com"

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
header3() { printf "\n${underline}${bold}${blue}❏ %s${reset}\n" "$@"; }
info() { printf "${white}➜ %s${reset}\n" "$@"; }
warn() { printf "${yellow}➜ %s${reset}\n" "$@"; }
error() { printf "${red}✖ %s${reset}\n" "$@"; }
success() { printf "${green}✔ %s${reset}\n" "$@"; }
usage() { printf "\n${underline}${bold}${blue}Usage:${reset} ${blue}%s${reset}\n" "$@"; }
timestamp() { printf "➜ current time : $(date +%Y-%m-%d' '%H:%M:%S.%N | cut -b 1-23)\n"; }

# get real path
getRealPath() { if [[ "$1" =~ ^\/.* ]]; then temp_path="$1"; else temp_path="${pwd_old}/$1"; fi; printf "$(readlink -f ${temp_path})"; }

# trap signal
trap "error '******* ERROR: Something went wrong.*******'; exit 1" sigterm
trap "error '******* Caught sigint signal. Stopping...*******'; exit 2" sigint

set +o noglob

# entry base dir
base_name=`basename $0 .sh`
base_dir="${pwd_old}"
source_name="$0"
while [ -h "${source_name}" ]; do
    base_dir="$( cd -P "$( dirname "${source_name}" )" && pwd )"
    source_name="$(readlink "${source_name}")"
    [[ ${source_name} != /* ]] && source_name="${base_dir}/${source_name}"
done
base_dir="$( cd -P "$( dirname "${source_name}" )" && pwd )"
cd "${base_dir}"

# envirionment
product_name="wrapper-tomcat"
product_version="3.5.43.8"
project_name="wrapper"
registry_host="registry.cdjdgm.com"
registry_user=""
registry_pass=""

build_name="$(cat /proc/sys/kernel/random/uuid)"
build_home="/tmp/${build_name}"

# args flag
arg_subcmd=

# 解析参数
# echo $@
# 定义选项， -o 表示短选项 -a 表示支持长选项的简单模式(以 - 开头) -l 表示长选项 
# a 后没有冒号，表示没有参数
# b 后跟一个冒号，表示有一个必要参数
# c 后跟两个冒号，表示有一个可选参数(可选参数必须紧贴选项)
# -n 出错时的信息
# -- 也是一个选项，比如 要创建一个名字为 -f 的目录，会使用 mkdir -- -f ,
#    在这里用做表示最后一个选项(用以判定 while 的结束)
# $@ 从命令行取出参数列表(不能用用 $* 代替，因为 $* 将所有的参数解释成一个字符串
#                         而 $@ 是一个参数数组)
# args=`getopt -o ab:c:: -a -l apple,banana:,cherry:: -n "${source_name}" -- "$@"`
args=`getopt -o h -a -l help,build,user:,pass: -n "${source_name}" -- "$@"`
# 判定 getopt 的执行时候有错，错误信息输出到 STDERR
if [ $? != 0 ]; then
    error "Terminating..." >&2
    exit 1
fi

# show start time
timestamp;

# show parameter options
header "[Step ${step}]: show parameter options."; let step+=1

# echo ${args}
# 重新排列参数的顺序
# 使用eval 的目的是为了防止参数中有shell命令，被错误的扩展。
eval set -- "${args}"
# 处理具体的选项
while true
do
    case "$1" in
        -h | --help | -help)
            info "option -h|--help"
            arg_subcmd=help
            shift
            ;;
        --build | -build)
            info "option --build"
            arg_subcmd=build
            shift
            ;;
        --user | -user)
            info "option --user argument : $2"
            registry_user="$2"
            shift 2
            ;;
        --pass | -pass)
            info "option --pass argument : $2"
            registry_pass="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            error "Internal error!"
            exit 1
            ;;
    esac
done
#显示除选项外的参数(不包含选项的参数都会排到最后)
# arg 是 getopt 内置的变量 , 里面的值，就是处理过之后的 $@(命令行传入的参数)
for arg do
   warn "$arg";
done

# define usage
usage=$"`basename $0` [-h|--help] [--build] [--user=test] [--pass=xxxx]
       [-h|--help]................show help info.
       [--build]..................build ${product_name}.
       [--user=test]..............registry username.
       [--pass=xxxx]..............registry password.
"

# show usage
fun_show_usage() {
    usage "$usage";
    exit 1
}

##########################################################################

# execute build command
fun_execute_build_command() {
    header "[Step ${step}]: execute build command."; let step+=1
    set +e

    info "build ${product_name} : "

    info "docker build for centos"
    docker build --rm \
                 --no-cache \
                 --build-arg wrapper_version=${product_version} \
                 -t ${registry_host}/${project_name}/${product_name}:${product_version}-centos \
                 -f ${base_dir}/../docker/centos/Dockerfile ${base_dir}/../source/

    info "docker build for alpine"
    docker build --rm \
                 --no-cache \
                 --build-arg wrapper_version=${product_version} \
                 -t ${registry_host}/${project_name}/${product_name}:${product_version}-alpine \
                 -f ${base_dir}/../docker/alpine/Dockerfile ${base_dir}/../source/

    info "docker login registry"
    # check registry_user
    if [ "x${registry_user}" == "x" ]; then
        # Manual input username
        info "enter the username for registry [${registry_host}]"
        for i in {3..1}; do
            # enter the username
            read -s -p "enter the username for registry [${registry_host}] : " registry_user && printf "\n"
            if [ -z "${registry_user}" ]; then
                warn "username cannot be empty, please try again [$i]."
                continue
            else
                break
            fi
        done
        if [ "x${registry_user}" == "x" ]; then
            error "failed to get the username."
            exit 1
        fi
    fi
    # check registry_pass
    if [ "x${registry_pass}" == "x" ]; then
        # Manual input password
        info "verify the password for [${registry_user}]"
        for i in {3..1}; do
            # enter the password
            read -s -p "enter the password for [${registry_user}] : " registry_pass && printf "\n"
            if [ -z "${registry_pass}" ]; then
                warn "password cannot be empty, please try again [$i]."
                continue
            fi
            # login;
            result=$(echo "${registry_pass}" | docker login --username="${registry_user}" --password-stdin "${registry_host}")
            if [ $? -eq 0 ]; then
                success "successfully verified password."
                break
            else
                error "${result}"
                error "an error occurred, please try again [$i]."
                registry_pass=""
                continue
            fi
            sleep 1
        done
        if [ "x${registry_pass}" == "x" ]; then
            error "failed to verified password."
            exit 1
        fi
    else
        # Automatic input password
        # login;
        result=$(echo "${registry_pass}" | docker login --username="${registry_user}" --password-stdin "${registry_host}")
        if [ $? -eq 0 ]; then
            success "successfully verified password."
        else
            error "${result}"
            exit 1
        fi
    fi

    info "docker push registry"
    docker push ${registry_host}/${project_name}/${product_name}:${product_version}-centos
    docker push ${registry_host}/${project_name}/${product_name}:${product_version}-alpine

    info "delete none images"
    docker rmi -f $(docker images -f "dangling=true" -q);

    success "successfully builded ${product_name}."

    success "successfully executed build command."
    set -e
    return 0
}

##########################################################################

# execute subcommand
case "${arg_subcmd}" in
    help)
        # show usage
        fun_show_usage
        ;;
    build)
        # execute build command
        fun_execute_build_command;
        ;;
    *)
        # show usage
        fun_show_usage
        ;;
esac

# show end time
timestamp;
echo ""

exit $?
