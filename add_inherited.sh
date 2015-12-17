#!/bin/bash
# author: Hugues Balp
# WARNING: We assume here that only one input parameter is present and correspond to a valid directory.
rootdir_fullpath=$1
optional_subdir=$2

echo "Try to add inherited classes when possible in files *.file.callers.gen.json present in directory \"${dir}\""

for json in `find ${rootdir_fullpath}/${optional_subdir} -name "*.file.callers.gen.json"`
do
src_dirname=`dirname ${json}`
src_filename=`basename ${json} ".file.callers.gen.json"`
echo "################################################################################"
echo "file ${src_dirname}/${src_filename}: try to add inherited classes to metadata file ${json}"
echo "################################################################################"
add_inherited.native ${src_dirname}/${src_filename}
if [ $? -ne 0 ]; then
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo "ERROR in add_inherited.native ${src_dirname}/${src_filename}. Stop here !"
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    exit -1
fi
done
