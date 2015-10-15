#!/bin/bash
set -x
# author: Hugues Balp
# example: function_callers_to_dot.native callees "main" "int main()" `pwd`/test_dummy.c
# with configuration = callers | callees | c2c
direction=$1
caller_jsonfile_absolute_path=$2
caller_id=$3
caller_sign=$4
shift
shift
shift
shift
extra_args=$2

echo "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"
echo "Generate a dot file following either callers, callees or any path between a caller and a callee"
echo "file ${src_file_absolute_path}: try to generate a ${direction} dot graph from entry point \"${caller_sign}\""
echo "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"

if [ -z $extra_args ]
then
    files=$1
    function_callers_to_dot.native "${direction}" "${caller_jsonfile_absolute_path}" "${caller_id}" "${caller_sign}" $files    
else    
    callee_jsonfile_absolute_path=$1
    callee_id=$2
    callee_sign=$3
    files=$4
    function_callers_to_dot.native "${direction}" "${caller_jsonfile_absolute_path}" "${caller_id}" "${caller_sign}" "${callee_jsonfile_absolute_path}" "${callee_id}" "${callee_sign}"  $files
fi
if [ $? -ne 0 ]; then
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo "ERROR in function_callers_to_dot.native ${src_dirname}/${src_filename} ${defined_symbols}. Stop here !"
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    exit -1
fi

