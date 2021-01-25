#!/usr/bin/env bash

set -e

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

if [ -x "${base_dir}/wrapper-create-linkfile.sh" ]; then
    "${base_dir}/wrapper-create-linkfile.sh" >/dev/null 2>&1
fi

if [ -x "${base_dir}/wrapper.sh" ]; then
    "${base_dir}/wrapper.sh" "stop"
fi
