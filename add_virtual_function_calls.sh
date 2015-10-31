#!/bin/bash
#set -x
# author: Hugues Balp
# WARNING: We assume here that one input parameter is present and correspond to:
# param1: a valid json file
rootdir_fullpath=$1

echo "Try to complete virtual methods definitions when possible in files *.file.callers.gen.json present in root directory \"${rootdir_fullpath}\""
echo "redefined virtual function definitions are searched in inherited classes of the base class defining the virtual method"

for json in `find $rootdir_fullpath -name "*.file.callers.gen.json"`
do
src_dirname=`dirname ${json}`
src_filename=`basename ${json} ".file.callers.gen.json"`
echo "################################################################################"
echo "file ${src_dirname}/${src_filename}: try to add extcallees to metadata file ${json}"
echo "################################################################################"
add_virtual_function_calls.native ${src_dirname}/${src_filename} ${rootdir_fullpath}
if [ $? -ne 0 ]; then
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo "ERROR in add_virtual_function_calls.native ${src_dirname}/${src_filename} ${rootdir_fullpath}. Stop here !"
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    exit -1
fi
done
