# STEF - a Simple TEst Framework

STEF is a standalone test framework useful for small projects.  It is written in
bash.

## Running the tests

The STEF itself consists of a single script, `stef.sh`.  It contains all the
framework inteligence.

Any project tests are supposed to reside in one directory.  No subdirectories
are supported.

Usage:

```
stef.sh [<test-dir>] [<name> [<name> ...]]
```

A test filename has a mandatory format of `test-<name>.sh`.  Anything else is
ignored by STEF.  For example, a valid test filenames are `test-001.sh`,
`test-init.sh`, `test-exec-001.sh`, etc.

If the `<test-dir>` is specified, STEF cd's into the directory before running
the tests.

STEF prints a result line for each test, and possibly some output if the test
does not succeed.  For example:

```
$ stef
=== [ maish shell unit tests ] ===

001	PASS
002	PASS
003	PASS
004	PASS
005	PASS
============

TESTS PASSED
```

## Common test configuration

Use `stef-config` in the test directory to define common variables.  You need
those variables exported in order to be defined in the tests themselves.  If you
want to be able to override those variables via exporting them before running
the tests, use `:-`.  For example:

```
$ cat stef-config
export STEF_TESTSUITE_NAME="NPRG099 ed tests, Part 2"
export LS=/bin/ls
export INPUTFILE=inputfile
export TESTBINARY={TESTBINARY:-/data/hg/maied/ed}
```

Then you can set `export TESTBINARY=/bin/ed` to use a different test binary.

## Special test variables

STEF recognizes the following variables:

Variable name | Purpose
------------ | -------------
STEF\_TESTSUITE\_NAME | if defined, a simple header is printed when running the tests.  Set it in `stef-config` if needed.
STEF\_UNTESTED | exit with $STEF\_UNTESTED when the test fails before actually testing the objective.  E.g. one cannot create a file for temporary output.
STEF\_UNSUPPORTED | exit with $STEF\_UNSUPPORTED when the test is not supported.  E.g. having an x86 test run on SPARC architecture.

## Test Output Files

Each test may have an expected output file.  If the test succeeds (i.e. returns
zero) and an output file `test-output-<name>.txt` exists, the test script both
standard and error output is compared to the output file.  If there is no output
file, a test returning 0 is considered successful right away.

STEF run each scripts as `./test-xxx.sh >$output 2>&1`.  Note that if you test
prints large amount of text to standard output and expects stderr output as
well, you might run into issues with buffering and ordering of the output lines.
However, for simple tests this tends not to be a problem.

## Test results

STEF returns 1 if there are any untested or failed tests.  Unsupported tests are
not considered a failure.  See below for an example.

## Example

See the `./examples` subdirectory which contains a set of tests.  The output is
like the following:

```
$ stef
=== [ STEF Example Use Case ] ===

001	PASS
002	UNSUPPORTED
== 8< BEGIN output ==
Even for unsupported runs, the output is printed if there is any.
== 8< END output=====
003	UNTESTED
== 8< BEGIN output ==
Even for untested runs, the output is printed if there is any.
== 8< END output=====
004	FAIL
== 8< BEGIN output ==
This is some output the test script printed.
It is printed here as the test failed.
== 8< END output=====
005	PASS
006	FAIL
== 8< BEGIN diff output ==
--- test-output-006.txt	2019-03-29 11:07:22.000000000 +0100
+++ stef-output-file.data	2019-03-29 11:36:13.000000000 +0100
@@ -1,2 +1 @@
-This is an example of a test which returned 0 but its output
-does not match the expected printed output.
+hello
== 8< END diff output=====

============

WARNING: some tests FAILED !!!
WARNING: some tests UNTESTED !!!
```

## Developing STEF

Each new feature should have a corresponding test under `./examples` to present
the feature use.
