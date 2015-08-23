#!/bin/bash
# author: Hugues Balp
# WARNING: We assume here that only one input parameter is present and correspond to a valid directory.
dir=$1

echo "Try to complete extcallees definitions when possible in files *.file.callers.gen.json present in directory \"${dir}\""

for json in `find $dir -name "*.file.callers.gen.json"`
do
src_dirname=`dirname ${json}`
src_filename=`basename ${json} ".file.callers.gen.json"`
echo "################################################################################"
echo "file ${src_dirname}/${src_filename}: try to add extcallees to metadata file ${json}"
echo "################################################################################"
add_extcallees.native ${src_dirname}/${src_filename}
done
