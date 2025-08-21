#!/bin/sh

#./graph.sh [module name [test name [sub-directory] ] ]
#convention is that module name equals sub-direcory name, if module name differs (e.g. sub component of a module with seperate testbench) an explicit directory must be provided.

MOD=$1 #{1?"Usage: $0 <module> [test]"}
TEST=$2

export PYTHONPATH=$HOME/devel/vunit

if [ $# -lt 1 ] ; then
	#list available modules
	python3 run.py lib.* -l | grep "^lib" | cut -d '.' -f 2 | sort | uniq | xargs -n 1 basename -s _tb
else if [ $# -gt 1 ] ; then
	#execute test and display graphical output
	MOD_DIR=${3-$MOD}
	python3 run.py lib.${MOD}_tb.$TEST -g --gtkwave-args "-a ../ip/$MOD_DIR/$MOD.gtkw" -v
else
	#list available test for current module
	python3 run.py lib.${MOD}_tb.* -l | grep "^lib" | cut -d '.' -f 3- | sort
fi
fi

