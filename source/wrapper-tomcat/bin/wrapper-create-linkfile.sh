#!/usr/bin/env bash

#######################################################################################
#
# create link file for apr/aprutil/crypto/expat/ssl/tcnative-1/z
#
#######################################################################################

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

#
# file array
#
file_array=(
libapr-1.so.0.7.0:libapr-1.so,libapr-1.so.0,libapr-1.so.0.7
libaprutil-1.so.0.6.1:libaprutil-1.so,libaprutil-1.so.0,libaprutil-1.so.0.6
libcrypto.so.1.1:libcrypto.so,libcrypto.so.1
libexpat.so.1.6.0:libexpat.so,libexpat.so.1,libexpat.so.1.6
libssl.so.1.1:libssl.so,libssl.so.1
libtcnative-1.so.0.2.23:libtcnative-1.so,libtcnative-1.so.0,libtcnative-1.so.0.2
libz.so.1.2.11:libz.so,libz.so.1,libz.so.1.2
)

#
# create link file
#
fun_create_link_file() {
    header "create link file"
    for data in ${file_array[@]}; do
        source=${data%%:*};
        target=${data#*:};
        header2 "create link file from [${source}]";
        target=${target//,/ }; # //与/之间与分割的字符, 另外/后有一个空格不可省略
        tgtarr=($target);
        for link in ${tgtarr[@]}; do
            if [ ! -L "${link}" ]; then
                info "create link file [${link}] -> [${source}]";
                \ln -s "${source}" "${link}";
            else
                warn "${link} already exists";
            fi
        done
    done
    return 0;
}

# entry libcore
cd "${base_dir}/../libcore/"

# create link file
fun_create_link_file

cd "${BASE_DIR}"

success "create link file complete."

exit $?
