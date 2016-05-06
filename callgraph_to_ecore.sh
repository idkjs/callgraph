#!/bin/bash
#set -x
# author: Hugues Balp
# WARNING: We assume here that one input parameter is present and correspond to:
## param: a valid directory name where at least one callgraph json file has been generated for example by extract_fcg.ml
fcg_dir=$1

for fcg in `find ${fcg_dir} -name "*.fcg.callers.gen.json" -o -name "*.fcg.callees.gen.json" -o -name "*.fcg.c2c.gen.json"`
do
  src_fcg_json=${fcg}
  src_fcg_name=`basename ${fcg} .json`
  src_fcg_ecore="${src_fcg_name}.callgraph"
  echo "################################################################################"
  echo "generate ecore graph: ${src_fcg_json} -> ${src_fcg_ecore}"
  echo "################################################################################"
  callgraph_to_ecore.native ${src_fcg_config} ${src_fcg_json} ${src_fcg_ecore}
  if [ $? -ne 0 ]; then
      echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
      echo "ERROR when generating ecore graph: ${src_fcg_ecore}. Stop here !"
      echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
      exit -1
  fi
done
