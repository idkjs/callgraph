#!/bin/bash

source clean_test.sh

source build_tools.sh

mkdir -p dir1

cd dir1
callgraph_to_json.native dir1 file1 file2

source add_extcallees.sh .
#source add_extcallers.sh .
indent_jsonfiles.sh .

# Test the generation of callee's tree
cd ..
# ./function_callers_to_dot.native callees f11 "void fct11()" dir1/file1
# dot -Tpng f11.fct.callees.gen.dot > f11.fct.callees.gen.dot.png

# # Test the generation of caller's tree
# ./function_callers_to_dot.native callers f22 "void fct22()" dir1/file2
# dot -Tpng f22.fct.callers.gen.dot > f22.fct.callers.gen.dot.png

# ./function_callers_to_dot.native c2c f12 "void fct12()" dir1/file1 f22 "void fct22()" dir1/file2
# dot -Tpng f12.fct.callees.gen.dot > f12.fct.callees.gen.dot.png
# dot -Tpng f22.fct.callers.gen.dot > f22.fct.callers.gen.dot.png
# dot -Tpng f12.f22.c2c.gen.dot > f12.f22.c2c.gen.dot.png
