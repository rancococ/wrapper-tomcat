#!/usr/bin/env bash

#######################################################################################
#
# build for tomcat
#
#######################################################################################

#set -x
set -e
set -o noglob

#
# font and color 
#
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
white=$(tput setaf 7)

#
# header and logging
#
header() { printf "\n${underline}${bold}${blue}> %s${reset}\n" "$@"; }
header2() { printf "\n${underline}${bold}${blue}>> %s${reset}\n" "$@"; }
info() { printf "${white}➜ %s${reset}\n" "$@"; }
warn() { printf "${yellow}➜ %s${reset}\n" "$@"; }
error() { printf "${red}✖ %s${reset}\n" "$@"; }
success() { printf "${green}✔ %s${reset}\n" "$@"; }
usage() { printf "\n${underline}${bold}${blue}Usage:${reset} ${blue}%s${reset}\n" "$@"; }

#
# trap signal
#
trap "error '******* ERROR: Something went wrong.*******'; exit 1" sigterm
trap "error '******* Caught sigint signal. Stopping...*******'; exit 2" sigint

set +o noglob

#
# entry base dir
#
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

build_name="$(cat /proc/sys/kernel/random/uuid)"
build_home=/tmp/${build_name}

product_name="wrapper-tomcat"

version=3.5.43.7
jre_version=1.8.192
tomcat_version=8.5.57
wrapper_version=3.5.43.7

serverjre=server-jre-8u192-windows-x64.tar.gz

arch=x86_64

# build
fun_build() {
    header "build start..."

    \rm -rf ${build_home}

    mkdir -p ${build_home}/${product_name}/jre

    tar_first_name=$(tar -tf ${base_dir}/windows/${serverjre} | awk -F "/" '{print $1}' | sed -n '1p') && \
    tar --no-same-owner -zxf ${base_dir}/windows/${serverjre} --directory=${build_home}/${product_name}/jre ${tar_first_name}/jre --strip-components=2 && \
    sed -i 's@securerandom.source=file:/dev/random@securerandom.source=file:/dev/urandom@g' "${build_home}/${product_name}/jre/lib/security/java.security" && \
    sed -i 's@#crypto.policy=unlimited@crypto.policy=unlimited@g' "${build_home}/${product_name}/jre/lib/security/java.security"

    \cp -rf ${base_dir}/../source/. ${build_home}/${product_name}

    touch ${build_home}/${product_name}/bin/version && \
    echo "jre:${jre_version}"          >> ${build_home}/${product_name}/bin/version && \
    echo "tomcat:${tomcat_version}"    >> ${build_home}/${product_name}/bin/version && \
    echo "wrapper:${wrapper_version}"  >> ${build_home}/${product_name}/bin/version

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

    tar -C ${build_home} -czf ${base_dir}/${product_name}-${version}-windows-${arch}.tar.gz ${product_name}

    \rm -rf ${build_home}

    success "build success."
    return 0;
}

# entry base dir
cd "${base_dir}"

# build
fun_build

cd "${base_dir}"

success "complete."

exit $?
