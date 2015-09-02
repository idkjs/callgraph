#!/bin/bash
set -x
# author: Hugues Balp
# example: function_callers_to_dot.native callees "main" "int main()" `pwd`/test_dummy.c
# with configuration = callers | callees | c2c
caller_jsonfile_absolute_path=$1
direction=$2
caller_id=$3
caller_sign=$4
shift
shift
shift
shift
extra_args=$@

echo "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"
echo "Generate a dot file following either callers, callees or any path between a caller and a callee"
echo "file ${src_file_absolute_path}: try to generate a ${direction} dot graph from entry point \"${caller_sign}\""
echo "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"

if [ -z $extra_args ]
then
    files=$1
    function_callers_to_dot.native "${caller_jsonfile_absolute_path}" "${direction}" "${caller_id}" "${caller_sign}" $files    
else    
    callee_id=$1
    callee_sign=$2
    callee_jsonfile_absolute_path=$3
    files=$4
    function_callers_to_dot.native "${caller_jsonfile_absolute_path}" "${direction}" "${caller_id}" "${caller_sign}" "${callee_id}" "${callee_sign}" "${callee_jsonfile_absolute_path}" $files
fi
if [ $? -ne 0 ]; then
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo "ERROR in function_callers_to_dot.native ${src_dirname}/${src_filename} ${defined_symbols}. Stop here !"
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    exit -1
fi

