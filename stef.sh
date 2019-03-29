#!/bin/bash
#
# STEF - a Simple TEst Framework.
#
# (c) Jan Pechanec <jp@devnull.cz>
#

typeset -i fail=0
typeset -i untested=0
typeset diffout=stef-diff.out
typeset testnames
typeset testfiles
typeset output=stef-output-file.data
typeset tests
typeset LS=/bin/ls

typeset -i STEF_UNSUPPORTED=100
typeset -i STEF_UNTESTED=101
# So that test scripts may use those.
export STEF_UNSUPPORTED
export STEF_UNTESTED

function catoutput
{
	[[ -s $output ]] || return
	echo "== 8< BEGIN output =="
	cat $output
	echo "== 8< END output====="
}

# If the first argument is a directory, go in there.
if (( $# > 0 )); then
	if [[ -d $1 ]]; then
		cd $1
		shift
	fi
fi

# If you want to use variables defined in here in the tests, export them in
# there.
[[ -f stef-config ]] && . ./stef-config

[[ -n "$STEF_TESTSUITE_NAME" ]] && printf "=== [ $STEF_TESTSUITE_NAME ] ===\n\n"

# Test must match a pattern "test-*.sh".  All other scripts are ignored.
# E.g. test-001.sh, test-002.sh, test-cmd-003, etc.
if (( $# > 0 )); then
	testnames=$*
	# Make sure all test names represent valid test scripts.
	for i in $names; do
		[[ -x test-$i.sh ]] || \
		    { echo "$i not a valid test.  Exiting." && exit 1; }
	done
else 
	testfiles=$( $LS test-*.sh )
	if (( $? != 0 )); then
		echo "No valid tests present.  Exiting."
		exit 1
	fi
	testnames=$( echo "$testfiles" | cut -f2- -d- | cut -f1 -d. )
fi

for i in $testnames; do
	# Print the test number.
	printf "$i\t"

	./test-$i.sh >$output 2>&1
	ret=$?

	# Go through some selected exit codes that has special meaning to STEF.
	if (( ret == STEF_UNSUPPORTED )); then
		echo "UNSUPPORTED"
		catoutput
		rm -f $output
		continue;
	elif (( ret == STEF_UNTESTED )); then
		echo "UNTESTED"
		# An untested test is a red flag as we failed even before
		# testing what we were supposed to.
		untested=1
		catoutput
		rm -f $output
		continue;
	fi

	# Anything else aside from 0 is a test fail.
	if (( ret != 0 )); then
		echo "FAIL"
		fail=1
		echo "== 8< BEGIN output =="
		cat $output
		echo "== 8< END output====="
		rm $output
		continue
	fi

	# If the expected output file does not exist, we consider the test
	# successful and are done.
	if [[ ! -f test-output-$i.txt ]]; then
		echo "PASS"
		rm -f $output
		continue
	fi

	diff -u test-output-$i.txt $output > $diffout
	if [[ $? -ne 0 ]]; then
		echo "FAIL"
		fail=1
		echo "== 8< BEGIN diff output =="
		cat $diffout
		echo "== 8< END diff output====="
	else
		echo "PASS"
	fi

	rm -f $output $diffout
done

printf "\n============\n\n"

if [[ $fail -eq 1 ]]; then
	echo "WARNING: some tests FAILED !!!"
	retval=1
fi
if [[ $untested -eq 1 ]]; then
	echo "WARNING: some tests UNTESTED !!!"
	retval=1
fi
if [[ $fail -eq 0 && $untested -eq 0 ]]; then
	echo "TESTS PASSED"
	retval=0
fi

echo ""

exit $retval
