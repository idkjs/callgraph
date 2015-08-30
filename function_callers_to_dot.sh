#!/bin/bash
#set -x
# author: Hugues Balp
# example: function_callers_to_dot.native callees "main" "int main()" `pwd`/test_dummy.c
# with configuration = callers | callees | c2c
configuration=$1
entry_point_id=$2
entry_point_sign=$3
src_file_absolute_path=$4

echo "Generate a dot file following either callers, callees or any path between a caller and a callee"

echo "################################################################################"
echo "file ${src_file_absolute_path}: try to generate a ${configuration} dot graph from entry point \"${entry_point_sign}\""
echo "################################################################################"
function_callers_to_dot.native "${configuration}" "${entry_point_id}" "${entry_point_sign}" "${src_file_absolute_path}"
if [ $? -ne 0 ]; then
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo "ERROR in function_callers_to_dot.native ${src_dirname}/${src_filename} ${defined_symbols}. Stop here !"
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    exit -1
fi

