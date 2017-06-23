#!/bin/bash

par_distribute_input_by_ability() {
    echo "### bug #48290: round-robin does not distribute data based on business"
    echo "### Distribute input to jobs that are ready"
    echo "Job-slot n is 50% slower than n+1, so the order should be 1..7"
    seq 20000000 |
    parallel --tagstring {#} -j7 --block 300k --round-robin --pipe \
	'pv -qL{=$_=$job->seq()**3+9=}0000 |wc -c' |
    sort -nk2 | field 1
}

par_print_before_halt_on_error() {
    echo '### What is printed before the jobs are killed'
    mytest() {
	HALT=$1
	(echo 0.1;
	    echo 3.2;
	    seq 0 7;
	    echo 0.3;
	    echo 8) |
	    parallel --tag --delay 0.1 -j4 -kq --halt $HALT \
		     perl -e 'sleep 1; sleep $ARGV[0]; print STDERR "",@ARGV,"\n"; '$HALT' > 0 ? exit shift : exit not shift;' {};
	echo exit code $?
    }
    export -f mytest
    parallel -j0 -k --tag mytest ::: -2 -1 0 1 2
}

export -f $(compgen -A function | grep par_)
compgen -A function | grep par_ | sort |
    #    parallel --joblog /tmp/jl-`basename $0` -j10 --tag -k '{} 2>&1'
        parallel --joblog /tmp/jl-`basename $0` -j1 --tag -k '{} 2>&1'
