#!/bin/bash

##########################################################################
# compose.sh
# for centos 7.x
# author : yong.ran@cdjdgm.com
# require : docker and docker-compose
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
    ansi="";
else
    bold=""; underline=""; reset="";
    red=""; green=""; yellow=""; blue=""; white="";
    ansi="--no-ansi";
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
if [ -r "${base_dir}/.env" ]; then
    while read line; do
        eval "$line";
    done < "${base_dir}/.env"
fi
self_name=`basename $0 .sh`
parent_name=`basename "${base_dir}"`
project_conf=${base_dir}/${self_name}.yml
project_dir=${base_dir}
if [ -z "${PRODUCT_NAME}" ]; then
    project_name=${parent_name}
else 
    project_name=${PRODUCT_NAME}
fi

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
args=`getopt -o h -a -l help,setup,start,stop,down,list -n "${source_name}" -- "$@"`
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
        --setup | -setup)
            info "option --setup"
            arg_subcmd=setup
            shift
            ;;
        --start | -start)
            info "option --start"
            arg_subcmd=start
            shift
            ;;
        --stop | -stop)
            info "option --stop"
            arg_subcmd=stop
            shift
            ;;
        --down | -down)
            info "option --down"
            arg_subcmd=down
            shift
            ;;
        --list | -list)
            info "option --list"
            arg_subcmd=list
            shift
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
usage=$"`basename $0` [-h|--help] [--setup] [--start] [--stop] [--down] [--list]
       [-h|--help]................show help info.
       [--setup]..................docker-compose xxx up -d.
       [--start]..................docker-compose xxx start.
       [--stop]...................docker-compose xxx stop.
       [--down]...................docker-compose xxx down.
       [--list]...................docker-compose xxx list.
"

# show usage
fun_show_usage() {
    usage "$usage";
    exit 1
}

##########################################################################

# execute compose command
fun_execute_compose_command() {
    command=$1
    header "[Step ${step}]: execute [docker-compose ${command}] command."; let step+=1
    set +e

    info "compose file : ${project_conf}"
    info "project dir  : ${project_dir}"
    info "project name : ${project_name}"
    info "execute command [docker-compose ${command}] start."
    docker-compose ${ansi} --file ${project_conf} --project-name ${project_name} --project-directory ${project_dir} ${command}

    success "successfully executed [docker-compose ${command}] command."
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
    setup)
        # execute setup command
        fun_execute_compose_command "up -d";
        ;;
    start)
        # execute start command
        fun_execute_compose_command "start";
        ;;
    stop)
        # execute stop command
        fun_execute_compose_command "stop";
        ;;
    down)
        # execute down command
        fun_execute_compose_command "down";
        ;;
    list)
        # execute list command
        fun_execute_compose_command "ps";
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
