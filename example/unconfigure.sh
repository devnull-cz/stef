#!/bin/bash
#
# It is advisable for the configure/unconfigure scripts to indent its output.

# This sets the 'tmpdir' variable which contains a temporary directory name
# different for each configure run.  That is why we need to source $configvar.
source $configvar

echo "Removing tmp directory '$tmpdir'."

if [[ -z $tmpdir ]]; then
	echo "Variable 'tmpdir' not set.  Exiting."
	exit 1
fi

: rm -f ./$tmpdir/*
: rmdir ./$tmpdir
if (($? != 0)); then
	echo "Failed to rmdir '$tmpdir'.  Exiting."
	exit 1
fi

echo "Temp directory '$tmpdir' succesufully removed."
echo "Removing '$configvar'."
