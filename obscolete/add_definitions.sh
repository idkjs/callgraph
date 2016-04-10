#!/bin/bash
#set -x
# author: Hugues Balp
# WARNING: We assume here that at least one input parameter is present and correspond to:
# param1: the temporary analysis root directory where raw json files are generated (default to /tmp/callers)
# param2: is a second optional parameter to focus on a specific subdirectory
rootdir_fullpath=$1
optional_subdir=$2

echo "Try to complete declarations with definitions when possible in files *.file.callers.gen.json present in directory \"${rootdir_fullpath}/${optional_subdir}\""
echo "Callees function definitions are searched in this directory..."

for json in `find ${rootdir_fullpath}/${optional_subdir} -name "*.file.callers.gen.json"`
do
src_dirname=`dirname ${json}`
src_filename=`basename ${json} ".file.callers.gen.json"`
echo "################################################################################"
echo "file ${src_dirname}/${src_filename}: try to add definitions to function declaration's metadata file ${json}"
echo "################################################################################"
add_definitions.native ${src_dirname}/${src_filename} ${rootdir_fullpath}
if [ $? -ne 0 ]; then
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo "ERROR in add_definitions.native ${src_dirname}/${src_filename} ${rootdir_fullpath}. Stop here !"
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    exit -1
fi
done
