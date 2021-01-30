#!/bin/bash

##########################################################################
# keytool.sh
# for centos 7.x
# author : yong.ran@cdjdgm.com
##########################################################################

# local variable
keytoolcmd="jre/bin/keytool"         #keytoolcmd
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
arg_alias=
arg_file=

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
args=`getopt -o h -a -l help,init,list,import,export,delete,alias:,file: -n "${source_name}" -- "$@"`
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
        --list | -list)
            info "option --list"
            arg_subcmd=list
            shift
            ;;
        --import | -import)
            info "option --import"
            arg_subcmd=import
            shift
            ;;
        --export | -export)
            info "option --export"
            arg_subcmd=export
            shift
            ;;
        --delete | -delete)
            info "option --delete"
            arg_subcmd=delete
            shift
            ;;
        --alias | -alias)
            info "option --alias argument : $2"
            arg_alias=$2
            shift 2
            ;;
        --file | -file)
            info "option --file argument : $2"
            arg_file=$(getRealPath "$2")
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
usage=$"`basename $0` [-h|--help] [--init] [--list] [--import] [--export] [--delete] [--alias=xxx] [--file=xxx.crt]
       [-h|--help]................show help info.
       [--init]...................execute init command.
       [--list]...................execute list command.
       [--import].................execute import command.
       [--export].................execute export command.
       [--delete].................execute delete command.
       [--alias=xxx]..............alias of the entry.
       [--file=xxx.crt]...........the name of the certificate.
"

# show usage
fun_show_usage() {
    usage "$usage";
    exit 1
}

##########################################################################

# read environment variables from .env file
fun_read_envfile() {
    header "[Step ${step}]: read environment variables from ${base_name}.env file."; let step+=1
    while read line;
    do
        # echo ${line};
        trim=$(echo ${line} | sed 's/^[ ]*//g' | sed 's/[ ]*$//g')
        if [ "x$trim" == "x" ]; then
            # ignore empty line
            continue;
        fi
        rem=$(echo ${trim:0:1})
        if [ "x$rem" == "x#" ]; then
            # ignore rem line
            continue;
        fi
        key=$(echo ${trim%%=*} | sed 's/^[ ]*//g' | sed 's/[ ]*$//g')
        value=$(echo ${trim#*=} | sed 's/^[ ]*//g' | sed 's/[ ]*$//g')
        last=$(echo ${key##*_})
        if [ "x$last" == "xPASS" ]; then
            info "${key}=***"
        else
            info "${key}=${value}"
        fi
        eval "${key}=${value}"
    done < "${base_dir}/${base_name}.env"
    success "successfully readed environment variables."
    return 0
}

# execute init command
fun_execute_init_command() {
    header "[Step ${step}]: execute init command."; let step+=1
    set +e

    info "copy ${base_dir}/../jre/lib/security/cacerts to ${base_dir}/../${trustfile}"
    \cp -rf "${base_dir}/../jre/lib/security/cacerts" "${base_dir}/../${trustfile}"
    info "change storepasswd to ${newstorepass}"
    "${base_dir}"/../${keytoolcmd} -storepasswd -v -keystore "${base_dir}/../${trustfile}" -storepass "${oldstorepass}" -new "${newstorepass}"

    success "successfully executed init command."
    set -e
    return 0
}

# execute list command
fun_execute_list_command() {
    header "[Step ${step}]: execute list command."; let step+=1
    set +e

    if [ "x${arg_alias}" == "x" ]; then
        info "list all entries in the keystore"
        "${base_dir}"/../${keytoolcmd} -list -keystore "${base_dir}/../${trustfile}" -storepass "${newstorepass}"
        ret=$?
        if [ ${ret} == 0 ]; then
            success "successfully executed list command."
        else
            error "failed to execute list command."
        fi
    else
        info "list the specified entries in the keystore : [${arg_alias}]"
        "${base_dir}"/../${keytoolcmd} -list -v -keystore "${base_dir}/../${trustfile}" -alias "${arg_alias}" -storepass "${newstorepass}"
        ret=$?
        if [ ${ret} == 0 ]; then
            success "successfully executed list command."
        else
            error "failed to execute list command."
        fi
    fi

    set -e
    return 0
}

# execute import command
fun_execute_import_command() {
    header "[Step ${step}]: execute import command."; let step+=1
    set +e

    if [ "x${arg_alias}" == "x" -a "x${arg_file}" == "x" ]; then
        # import certificate from ${base_dir}/../${certspath}
        info "import certificate from ${base_dir}/../${certspath}"
        i=0
        for file in $(find "${base_dir}/../${certspath}" -name "*.crt" -o -name "*.cer"); do
            _file="${file##*/}"
            alias="${_file%.*}"
            #suffix="${_file##*.}"
            # list
            info "check if alias [${alias}] exists"
            "${base_dir}"/../${keytoolcmd} -list -keystore "${base_dir}/../${trustfile}" -alias "${alias}" -storepass "${newstorepass}"
            ret1=$?
            if [ ${ret1} == 0 ]; then
                info "alias [${alias}] already exists."
                echo ""
                # delete
                info "delete alias [${alias}]..."
                "${base_dir}"/../${keytoolcmd} -delete -keystore "${base_dir}/../${trustfile}" -alias "${alias}" -storepass "${newstorepass}"
                ret2=$?
                if [ ${ret2} == 0 ]; then
                    info "successfully deleted alias [${alias}]."
                else
                    info "failed to delete alias [${alias}]."
                fi
            else
                info "alias [${alias}] does not exist."
            fi
            echo ""
            # import
            info "import certificate, alias : [${alias}], file : [${file}]"
            "${base_dir}"/../${keytoolcmd} -importcert -noprompt -keystore "${base_dir}/../${trustfile}" -alias "${alias}" -file "${file}" -storepass "${newstorepass}"
            ret3=$?
            if [ ${ret3} == 0 ]; then
                info "successfully deleted alias [${alias}]."
            else
                info "failed to delete alias [${alias}]."
            fi
            echo ""
        done
        success "successfully executed import command."
        set -e
        return 0
    else
        # import certificate from specified file
        info "import certificate from specified file"
        if [ "x${arg_alias}" == "x" ]; then
            error "alias cannot be empty"
            usage "$usage"
            set -e
            return 1
        fi
        if [ "x${arg_file}" == "x" ]; then
            error "file cannot be empty"
            usage "$usage"
            set -e
            return 1
        fi
        if [ ! -f "${arg_file}" ]; then
            error "the file [${arg_file}] does not exist"
            usage "$usage"
            set -e
            return 1
        fi
        info "import certificate, alias : [${arg_alias}], file : [${arg_file}]"
        "${base_dir}"/../${keytoolcmd} -importcert -noprompt -keystore "${base_dir}/../${trustfile}" -alias "${arg_alias}" -file "${arg_file}" -storepass "${newstorepass}"
        success "successfully executed import command."
        set -e
        return 0
    fi
}

# execute export command
fun_execute_export_command() {
    header "[Step ${step}]: execute export command."; let step+=1
    set +e

    if [ "x${arg_alias}" == "x" -o "x${arg_file}" == "x" ]; then
        error "alias and file cannot be empty"
        usage "$usage"
        return 1
    fi
    if [ -f "${arg_file}" ]; then
        error "the file [${arg_file}] already exists"
        usage "$usage"
        return 1
    fi
    info "export certificate, alias : [${arg_alias}], file : [${arg_file}]"
    "${base_dir}"/../${keytoolcmd} -exportcert -rfc -keystore "${base_dir}/../${trustfile}" -alias "${arg_alias}" -file "${arg_file}" -storepass "${newstorepass}"

    success "successfully executed export command."
    set -e
    return 0
}

# execute delete command
fun_execute_delete_command() {
    header "[Step ${step}]: execute delete command."; let step+=1
    set +e

    if [ "x${arg_alias}" == "x" ]; then
        error "alias cannot be empty"
        usage "$usage"
        return 1
    fi
    info "delete certificate, alias : [${arg_alias}]"
    "${base_dir}"/../${keytoolcmd} -delete -v -keystore "${base_dir}/../${trustfile}" -alias "${arg_alias}" -storepass "${newstorepass}"

    success "successfully executed delete command."
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
        # read environment variables from .env file
        fun_read_envfile;
        # execute init command
        fun_execute_init_command;
        ;;
    list)
        # read environment variables from .env file
        fun_read_envfile;
        # execute list command
        fun_execute_list_command;
        ;;
    import)
        # read environment variables from .env file
        fun_read_envfile;
        # execute import command
        fun_execute_import_command;
        ;;
    export)
        # read environment variables from .env file
        fun_read_envfile;
        # execute export command
        fun_execute_export_command;
        ;;
    delete)
        # read environment variables from .env file
        fun_read_envfile;
        # execute delete command
        fun_execute_delete_command;
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
