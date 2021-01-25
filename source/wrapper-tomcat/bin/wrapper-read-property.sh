#!/bin/bash

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

conf_dir=${base_dir}/../conf

# read config info from wrapper-property.conf
# echo read config info from wrapper-property.conf
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
    tmp1=$(echo ${trim:0:4})
    if [ "x$tmp1" != "xset." ]; then
        # ignore not set.
        continue;
    fi
    tmp2=$(echo ${trim:4})
    key=$(echo _${tmp2%%=*} | sed 's/^[ ]*//g' | sed 's/[ ]*$//g')
    value=$(echo ${tmp2#*=} | sed 's/^[ ]*//g' | sed 's/[ ]*$//g')
    # echo -${key}=${value}-
    eval "${key}=${value}"
done < "${conf_dir}/wrapper-property.conf"
