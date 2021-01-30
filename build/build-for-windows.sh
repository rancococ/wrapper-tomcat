#!/bin/bash

##########################################################################
# build for windows
# for centos 7.x
# author : yong.ran@cdjdgm.com
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
product_version="3.5.43.7"
product_platform="windows"
product_arch="x86_64"
jre_version="1.8.192"
tomcat_version="8.5.57"
wrapper_version="3.5.43.7"
serverjre="server-jre-8u192-windows-x64.tar.gz"
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
args=`getopt -o h -a -l help,build -n "${source_name}" -- "$@"`
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
usage=$"`basename $0` [-h|--help] [--build]
       [-h|--help]................show help info.
       [--build]..................build ${product_name}.
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

    info "init directory"
    \rm -rf "${build_home}"
    mkdir -p "${build_home}/${product_name}/jre"

    info "unzip jre"
    tar_first_name=$(tar -tf ${base_dir}/${product_platform}/${serverjre} | awk -F "/" '{print $1}' | sed -n '1p')
    tar --no-same-owner -zxf ${base_dir}/${product_platform}/${serverjre} --directory=${build_home}/${product_name}/jre ${tar_first_name}/jre --strip-components=2
    sed -i 's@securerandom.source=file:/dev/random@securerandom.source=file:/dev/urandom@g' "${build_home}/${product_name}/jre/lib/security/java.security"
    sed -i 's@#crypto.policy=unlimited@crypto.policy=unlimited@g' "${build_home}/${product_name}/jre/lib/security/java.security"

    info "copy files"
    \cp -rf "${base_dir}/../source/${product_name}"/. "${build_home}/${product_name}"

    info "generate version info"
    touch ${build_home}/${product_name}/bin/version
    echo "jre:${jre_version}"          >> ${build_home}/${product_name}/bin/version
    echo "tomcat:${tomcat_version}"    >> ${build_home}/${product_name}/bin/version
    echo "wrapper:${wrapper_version}"  >> ${build_home}/${product_name}/bin/version

    info "change file permissions"
    find "${build_home}/${product_name}" -exec touch {} \;
    find "${build_home}/${product_name}" -type d -exec chmod 755 {} \;
    find "${build_home}/${product_name}" -type f -exec chmod 644 {} \;
    find "${build_home}/${product_name}" -type f -name ".keep" -exec rm -rf {} \;

    chmod 744 ${build_home}/${product_name}/jre/bin/*
    chmod 744 ${build_home}/${product_name}/bin/*
    chmod 644 ${build_home}/${product_name}/bin/*.bat
    chmod 644 ${build_home}/${product_name}/bin/*.exe
    chmod 644 ${build_home}/${product_name}/bin/*.jar
    chmod 644 ${build_home}/${product_name}/bin/*.cnf
    chmod 644 ${build_home}/${product_name}/bin/version
    chmod 600 ${build_home}/${product_name}/conf/*.password
    chmod 777 ${build_home}/${product_name}/logs
    chmod 777 ${build_home}/${product_name}/temp

    info "pack file"
    tar -C "${build_home}" -czf "${base_dir}"/${product_name}-${product_version}-${product_platform}-${product_arch}.tgz "${product_name}"

    info "delete temp file"
    \rm -rf "${build_home}"

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
