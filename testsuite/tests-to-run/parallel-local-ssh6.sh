#!/bin/bash

# At most 2 parallel sshs per function

export SSHLOGIN1=parallel@lo
export SSHLOGIN2=csh@lo
mkdir -p tmp

par_test_onall() {
    echo '### Test --onall'
    parallel --onall --tag -k -S $SSHLOGIN1,$SSHLOGIN2 '(echo {1} {2}) | awk \{print\ \$2}' ::: a b c ::: 1 2
}

par_test_pipe_onall() {
    echo '### Test | --onall'
    seq 3 |
	parallel --onall --tag -k -S $SSHLOGIN1,$SSHLOGIN2 '(echo {1} {2}) | awk \{print\ \$2}' ::: a b c :::: -
}

par_test_onall_u() {
    echo '### Test --onall -u'
    parallel --onall -S $SSHLOGIN1,$SSHLOGIN2 -u '(echo {1} {2}) | awk \{print\ \$2}' ::: a b c ::: 1 2 3 |
	sort
}    

par_test_nonall() {
    echo '### Test --nonall'
    parallel --nonall -k -S $SSHLOGIN1,$SSHLOGIN2 pwd |
	sort
}    

par_test_nonall_u() {
    echo '### Test --nonall -u - should be interleaved x y x y'
    parallel --nonall -S $SSHLOGIN1,$SSHLOGIN2 -u 'pwd|grep -q csh && sleep 3; pwd;sleep 12;pwd;'
}    

par_read_sshloginfile_from_stdin() {
    echo '### Test read sshloginfile from STDIN'
    echo $SSHLOGIN1,$SSHLOGIN2 | parallel -S - -k --nonall pwd
    echo $SSHLOGIN1,$SSHLOGIN2 | parallel --sshloginfile - -k --onall pwd\; echo ::: foo
}

par_nonall_basefile() {
    echo '### Test --nonall --basefile'
    touch tmp/nonall--basefile
    stdout parallel --nonall --basefile tmp/nonall--basefile -S $SSHLOGIN1,$SSHLOGIN2 ls tmp/nonall--basefile
    stdout parallel --nonall -S $SSHLOGIN1,$SSHLOGIN2 rm tmp/nonall--basefile
    stdout rm tmp/nonall--basefile
}

par_onall_basefile() {
    echo '### Test --onall --basefile'
    touch tmp/onall--basefile
    stdout parallel --onall --basefile tmp/onall--basefile -S $SSHLOGIN1,$SSHLOGIN2 ls {} ::: tmp/onall--basefile
    stdout parallel --onall -S $SSHLOGIN1,$SSHLOGIN2 rm {} ::: tmp/onall--basefile
    stdout rm tmp/onall--basefile
}    

par_nonall_basefile_cleanup() {
    echo '### Test --nonall --basefile --cleanup (rm should fail)'
    touch tmp/nonall--basefile--clean
    stdout parallel --nonall --basefile tmp/nonall--basefile--clean --cleanup -S $SSHLOGIN1,$SSHLOGIN2 ls tmp/nonall--basefile--clean
    stdout parallel --nonall -S $SSHLOGIN1,$SSHLOGIN2 rm tmp/nonall--basefile--clean
    stdout rm tmp/nonall--basefile--clean
}

par_onall_basefile_cleanup() {
    echo '### Test --onall --basefile --cleanup (rm should fail)'
    touch tmp/onall--basefile--clean
    stdout parallel --onall --basefile tmp/onall--basefile--clean --cleanup -S $SSHLOGIN1,$SSHLOGIN2 ls {} ::: tmp/onall--basefile--clean
    stdout parallel --onall -S $SSHLOGIN1,$SSHLOGIN2 rm {} ::: tmp/onall--basefile--clean
    stdout rm tmp/onall--basefile--clean
}

par_workdir_dot() {
    echo '### Test --workdir .'
    ssh $SSHLOGIN1 mkdir -p mydir
    mkdir -p $HOME/mydir
    cd $HOME/mydir
    parallel --workdir . -S $SSHLOGIN1 ::: pwd
}

par_wd_dot() {
    echo '### Test --wd .'
    ssh $SSHLOGIN2 mkdir -p mydir
    mkdir -p $HOME/mydir
    cd $HOME/mydir
    parallel --workdir . -S $SSHLOGIN2 ::: pwd
}    

par_wd_braces() {
    echo '### Test --wd {}'
    ssh $SSHLOGIN2 rm -rf wd1 wd2
    mkdir -p $HOME/mydir
    cd $HOME/mydir
    parallel --workdir {} -S $SSHLOGIN2 touch ::: wd1 wd2
    ssh $SSHLOGIN2 ls -d wd1 wd2
}

par_wd_perlexpr() {
    echo '### Test --wd {= =}'
    ssh $SSHLOGIN2 rm -rf WD1 WD2
    mkdir -p $HOME/mydir
    cd $HOME/mydir
    parallel --workdir '{= $_=uc($_) =}' -S $SSHLOGIN2 touch ::: wd1 wd2
    ssh $SSHLOGIN2 ls -d WD1 WD2
}

par_nonall_wd() {
    echo '### Test --nonall --wd'
    parallel --workdir /tmp -S $SSHLOGIN2 --nonall pwd
}

par_remote_symlink_dir() {
    echo 'bug #51293: parallel does not preserve symlinked directory structure on remote'
    ssh parallel@lo 'mkdir -p tmp; rm -rf wd; ln -s tmp wd'
    mkdir -p wd
    touch wd/testfile
    parallel --nonall -S parallel@lo --basefile wd/testfile
    ssh parallel@lo rm wd && echo OK: wd is still a symlink
}

export -f $(compgen -A function | grep par_)
#compgen -A function | grep par_ | sort | parallel --delay $D -j$P --tag -k '{} 2>&1'
compgen -A function | grep par_ | sort |
    parallel --joblog /tmp/jl-`basename $0` -j5 --tag -k '{} 2>&1'
