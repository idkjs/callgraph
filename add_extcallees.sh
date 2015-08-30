#!/bin/bash
#set -x
# author: Hugues Balp
# WARNING: We assume here that two input parameters are present and correspond to:
# param1: a valid json file
# param2: a valid path to the defined symbol json file
dir=$1
defined_symbols=$2

echo "Try to complete extcallees definitions when possible in files *.file.callers.gen.json present in directory \"${dir}\""

for json in `find $dir -name "*.file.callers.gen.json"`
do
src_dirname=`dirname ${json}`
src_filename=`basename ${json} ".file.callers.gen.json"`
echo "################################################################################"
echo "file ${src_dirname}/${src_filename}: try to add extcallees to metadata file ${json}"
echo "################################################################################"
add_extcallees.native ${src_dirname}/${src_filename} ${defined_symbols}
if [ $? -ne 0 ]; then                                                                                                                             
    echo "################################################################################"                                                       
    echo "# ERROR in add_extcallees.native ${src_dirname}/${src_filename} ${defined_symbols}. Stop here !"                                               echo "################################################################################"                                                       
    exit -1                                                                                                                                       
fi 
done
