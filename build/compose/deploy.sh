#!/bin/bash

##########################################################################
# deploy.sh
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

# args flag
arg_subcmd=
arg_images=
arg_war=
arg_context=
default_context=ROOT

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
args=`getopt -o h -a -l help,init,load,deploy,images:,war:,context: -n "${source_name}" -- "$@"`
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
        --init | -init)
            info "option --init"
            arg_subcmd=init
            shift
            ;;
        --load | -load)
            info "option --load"
            arg_subcmd=load
            shift
            ;;
        --deploy | -deploy)
            info "option --deploy"
            arg_subcmd=deploy
            shift
            ;;
        --images | -images)
            info "option --images argument : $2"
            arg_images=$(getRealPath "$2")
            shift 2
            ;;
        --war | -war)
            info "option --war argument : $2"
            arg_war=$(getRealPath "$2")
            shift 2
            ;;
        --context | -context)
            info "option --context argument : $2"
            arg_context="$2"
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
usage=$"`basename $0` [-h|--help] [--init] [--load] [--deploy] [--images=xxx.tgz] [--war=xxx.war] [--context=test]
       [-h|--help]................show help info.
       [--init]...................init volume.
       [--load]...................load images.
       [--deploy].................deploy war to datadir.
       [--images=xxx.tgz].........images.
       [--war=xxx.war]............war.
       [--context=test]...........context.
"

# show usage
fun_show_usage() {
    usage "$usage";
    exit 1
}

##########################################################################

# execute init command
fun_execute_init_command() {
    header "[Step ${step}]: execute init command."; let step+=1
    set +e

    hasconf=$(find "${base_dir}/volume" -type d -name conf | wc -w)
    hasdata=$(find "${base_dir}/volume" -type d -name data | wc -w)
    haslogs=$(find "${base_dir}/volume" -type d -name logs | wc -w)
    hastemp=$(find "${base_dir}/volume" -type d -name temp | wc -w)
    if [ ${hasconf} -gt 0 ]; then
        info "init conf volume start."
        for confdir in `find "${base_dir}/volume" -type d -name conf`; do
            info "init conf volume : ${confdir}"
            chmod -R 777 ${confdir};
        done
        success "successfully initialized conf volume"
    fi
    if [ ${hasdata} -gt 0 ]; then
        info "init data volume start."
        for datadir in `find "${base_dir}/volume" -type d -name data`; do
            info "init data volume : ${datadir}"
            chmod -R 777 ${datadir};
        done
        success "successfully initialized data volume"
    fi
    if [ ${haslogs} -gt 0 ]; then
        info "init logs volume start."
        for logsdir in `find "${base_dir}/volume" -type d -name logs`; do
            info "init logs volume : ${logsdir}"
            chmod -R 777 ${logsdir};
        done
        success "successfully initialized logs volume"
    fi
    if [ ${hastemp} -gt 0 ]; then
        info "init temp volume start."
        for tempdir in `find "${base_dir}/volume" -type d -name temp`; do
            info "init temp volume : ${tempdir}"
            chmod -R 777 ${tempdir};
        done
        success "successfully initialized temp volume"
    fi

    success "successfully executed init command."
    set -e
    return 0
}

# execute load command
fun_execute_load_command() {
    header "[Step ${step}]: execute load command."; let step+=1
    set +e

    if [ ! -f "${arg_images}" ]; then
        error "images does not exist!"
        usage "$usage"
        return 1
    fi

    info "load image : ${arg_images}"
    docker load -i "${arg_images}";
    success "successfully loaded ${arg_images}"

    success "successfully executed load command."
    set -e
    return 0
}

# execute deploy command
fun_execute_deploy_command() {
    header "[Step ${step}]: execute deploy command."; let step+=1
    set +e

    if [ ! -f "${arg_war}" ]; then
        error "war does not exist!"
        usage "$usage"
        return 1
    fi

    suffix="${arg_war##*.}"
    if [ ! "x${suffix}" == "xwar" ]; then
        error "unsupported file format : ${arg_war}"
        usage "$usage"
        return 1
    fi

    if [ "x${arg_context}" == "x" ]; then
        warn "the context parameter is empty and deployed to [${default_context}] by default."
        arg_context="${default_context}"
    fi

    info "deploy data : ${arg_war}, context : ${arg_context}"
    \rm -rf "${base_dir}/volume/tomcat/data/${arg_context}/"
    mkdir -p "${base_dir}/volume/tomcat/data/ROOT/"
    mkdir -p "${base_dir}/volume/tomcat/data/${arg_context}/"
    chmod -R 777 "${base_dir}/volume/tomcat/data/${arg_context}/"
    unzip -q "${arg_war}" -d "${base_dir}/volume/tomcat/data/${arg_context}/"
    success "successfully deployed ${arg_war}"

    success "successfully executed deploy command."
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
    init)
        # execute init command
        fun_execute_init_command;
        ;;
    load)
        # execute load command
        fun_execute_load_command;
        ;;
    deploy)
        # execute deploy command
        fun_execute_deploy_command;
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
