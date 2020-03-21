#!/bin/bash

tmpdir=$(mktemp -d dir.XXXXX)

if (($? != 0)); then
	echo "Could not mkdir '$tmpdir'.  Exiting."
	exit 1
fi
echo "tmpdir=$tmpdir" >$configvar

echo "Created temporary directory '$tmpdir'."
