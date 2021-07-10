#!/bin/bash
#set -x
# author: Hugues Balp
# WARNING: We assume here that one or two input parameters is/are present and correspond to:
# param 1) fcg_dir: a valid directory path where at least one callgraph json file has been generated for example by extract_fcg.ml
# param 2) an optional parameter to pass additional arguments to the executable like "files" to add dot subprograms to functions
fcg_dir=$1
other=$2

for fcg in `find ${fcg_dir} -name "*.fcg.callers.gen.json" -o -name "*.fcg.callees.gen.json" -o -name "*.fcg.c2c.gen.json"`
do
  src_fcg_json=${fcg}
  src_fcg_name=`basename ${fcg} .json`
  src_fcg_dot="${src_fcg_name}.dot"
  echo "################################################################################"
  echo "generate dot graph: ${src_fcg_json} -> ${src_fcg_dot}"
  echo "################################################################################"
  callgraph_to_dot.native ${src_fcg_json} ${src_fcg_dot} ${other}
  if [ $? -ne 0 ]; then
      echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
      echo "ERROR when generating dot graph: ${src_fcg_dot}. Stop here !"
      echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
      exit -1
  fi
done
