#!/bin/bash
#set -x
# author: Hugues Balp
# WARNING: We assume here that two input parameters are present and correspond to:
# param1: a valid json file
# param2: a valid path to the defined symbol json file
rootdir_fullpath=$1
#rootdir_fullpath=$2

echo "Try to complete extcallees definitions when possible in files *.file.callers.gen.json present in directory \"${rootdir_fullpath}\""

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
