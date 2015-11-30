#!/bin/bash
#set -x
# author: Hugues Balp
# example: classes_depgraph.native child `pwd`/test_dummy.c "A"
# with configuration = base | child | c2b
direction=$1
class_jsonfile_absolute_path=$2
class_id=$3
shift
shift
shift
shift
extra_args=$2

echo "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"
echo "Generate a dot file following either callers, callees or any path between a caller and a callee"
echo "file ${src_file_absolute_path}: try to generate a ${direction} dot graph from entry point \"${class_sign}\""
echo "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"

if [ -z $extra_args ]
then
    files=$1
    classes_depgraph.native "${direction}" "${class_jsonfile_absolute_path}" "${class_id}" $files    
else
    callee_jsonfile_absolute_path=$1
    callee_id=$2
    files=$3
    classes_depgraph.native "${direction}" "${class_jsonfile_absolute_path}" "${class_id}" "${callee_jsonfile_absolute_path}" "${callee_id}" $files
fi
if [ $? -ne 0 ]; then
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo "ERROR in classes_depgraph.native ${src_dirname}/${src_filename} ${defined_symbols}. Stop here !"
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    exit -1
fi

