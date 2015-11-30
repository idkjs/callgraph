#!/bin/bash
set -x
working_dirpath=`dirname $PWD/..`
working_dirname=`basename ${working_dirpath}`

# # List generated json files
# list_json_files_in_dirs.native `pwd` .json dir.callers.gen.json

# List all defined symbols in file defined_symbols.json
list_defined_symbols.native defined_symbols.json $working_dirname dir.callers.gen.json
#read_defined_symbols.native defined_symbols.json file.callers.gen.json

# # add extcallees to json files
# source add_extcallees.sh `pwd` defined_symbols.json

# # add extcallers to json files
# source add_extcallers.sh .
# source indent_jsonfiles.sh .

# generate callee's tree from main entry point
#function_callgraph.native callees "main" "int main()" `pwd`/test.cpp
# function_callgraph.native callees "main" "int main()" `pwd`/test.cpp files
# source process_dot_files.sh . analysis/callers
# inkscape analysis/callers/svg/main.fct.callees.gen.dot.svg
