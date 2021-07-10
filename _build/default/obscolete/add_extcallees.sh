#!/bin/bash
#set -x
# author: Hugues Balp
# WARNING: We assume here that one input parameter is present and correspond to:
# param1: the temporary analysis root directory where raw json files are generated (default to /tmp/callers)
rootdir_fullpath=$1

echo "Try to complete extcallees definitions when possible in files *.file.callers.gen.json present in root directory \"${rootdir_fullpath}\""
echo "Callees function definitions can be found in root directory"

for json in `find $rootdir_fullpath -name "*.file.callers.gen.json"`
do
src_dirname=`dirname ${json}`
src_filename=`basename ${json} ".file.callers.gen.json"`
echo "################################################################################"
echo "file ${src_dirname}/${src_filename}: try to add extcallees to metadata file ${json}"
echo "################################################################################"
add_extcallees.native ${src_dirname}/${src_filename} ${rootdir_fullpath}
if [ $? -ne 0 ]; then
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo "ERROR in add_extcallees.native ${src_dirname}/${src_filename} ${rootdir_fullpath}. Stop here !"
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    exit -1
fi
done
