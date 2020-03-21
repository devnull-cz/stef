#!/bin/bash
#
# STEF - a Simple TEst Framework.
#
# (c) Jan Pechanec <jp@devnull.cz>
#

typeset -i fail=0
typeset -i untested=0
typeset -i ret
typeset diffout=stef-diff.out
typeset testnames
typeset testfiles
typeset output=stef-output-file.data
typeset tests
typeset LS=/bin/ls
typeset STEF_CONFIG=stef-config

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
[[ -f $STEF_CONFIG ]] && source ./$STEF_CONFIG

[[ -n "$STEF_TESTSUITE_NAME" ]] && printf "=== [ $STEF_TESTSUITE_NAME ] ===\n"

# If this variable is set, the test suite clone specific settings may put in
# that file.  For example, stuff that each user will need to set differently,
# like mysh, myed, or mytar binaries.
if [[ -n $STEF_CONFIG_LOCAL && -f $STEF_CONFIG_LOCAL ]]; then
	echo "Sourcing test suite specific configuration: $STEF_CONFIG_LOCAL"
	source ./$STEF_CONFIG_LOCAL
fi

for var in $STEF_EXECUTABLE_LOCAL_VARS; do
	echo "Checking test suite specific executables:" \
	    "$STEF_EXECUTABLE_LOCAL_VARS"
	varexec=$(eval echo \$$var)
	[[ -x $varexec && $varexec == /* ]] && continue

	if [[ $varexec != /* ]]; then
		printf "%s\n%s\n" \
		    "Variable '$var' set as '$varexec' in STEF_EXECUTABLE_VARS" \
		    "variable defined in '$STEF_CONFIG' must be an absolute path."
		echo "Please fix it before trying to re-run.  Exiting."
		exit 1
	fi

	printf "%s\n%s\n" \
	    "Variable '$var' set as '$varexec' in STEF_EXECUTABLE_VARS" \
	    "variable defined in '$STEF_CONFIG' does not point to an executable."
	echo "Please fix it before trying to re-run.  Exiting."
	exit 1
done

if [[ -n $STEF_CONFIGURE ]]; then
	echo "Configuring the test run..."
	if [[ ! -x $STEF_CONFIGURE ]]; then
		echo "Error: $STEF_CONFIGURE not executable."
		ret=1
	else
		$STEF_CONFIGURE
		ret=$?
	fi
	if ((ret != 0)); then
		echo "Configuration failed, fix it and rerun.  Exiting."
		exit 1
	fi
	echo "Configuration done."
fi

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

echo "Running tests."
printf -- "------------\n"

for i in $testnames; do
	# Print the test number.
	printf "  $i\t"

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

printf -- "------------\n"

if [[ $fail -eq 1 ]]; then
	echo "WARNING: some tests FAILED !!!"
	retval=1
fi
if [[ $untested -eq 1 ]]; then
	echo "WARNING: some tests UNTESTED !!!"
	retval=1
fi
if [[ $fail -eq 0 && $untested -eq 0 ]]; then
	echo "All tests passed."
	retval=0
fi

if [[ -n $STEF_UNCONFIGURE ]]; then
	if ((ret != 0)); then
		echo "Skipping unconfiguration due to some test failures."
	else
		echo "Unconfiguring the test run..."
		if [[ ! -x $STEF_UNCONFIGURE ]]; then
			echo "Error: $STEF_UNCONFIGURE not executable."
			ret=1
		else
			$STEF_UNCONFIGURE
		fi
		if ((ret != 0)); then
			echo "WARNING: Unconfiguration failed."
		else
			echo "Unconfiguration done."
		fi
	fi
fi

exit $retval
