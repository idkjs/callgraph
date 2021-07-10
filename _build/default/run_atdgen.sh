#!/bin/bash

atdgen -t src/Callers.atd && atdgen -j src/Callers.atd
atdgen -t src/callgraph.atd && atdgen -j src/callgraph.atd
