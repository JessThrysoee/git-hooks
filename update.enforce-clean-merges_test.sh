#!/bin/bash -e

function create_tmp_dir() {
   TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp/}${0##*/}.XXXXXX")"
   mkdir -p "$TMP_DIR"
}

function delete_tmp_dir() {
   if [[ -n $TMP_DIR && -d $TMP_DIR ]]
   then
      rm -rf "$TMP_DIR"
   fi
}

log() {
   git log --graph --oneline --decorate --all
}

update_hook=$PWD/update.enforce-clean-merges
create_tmp_dir
trap delete_tmp_dir EXIT
cd $TMP_DIR
pwd

delete_upstream() {
   cd $TMP_DIR
   rm -rf upstream
}

create_upstream() {
   cd $TMP_DIR

   mkdir -p upstream
   cd upstream
   git init --bare
   cd hooks
   ln -s $update_hook update
}

delete_downstream() {
   cd $TMP_DIR
   rm -rf downstream
}

create_downstream() {
   cd $TMP_DIR
   git clone upstream downstream
}

setup() {
   create_upstream
   create_downstream
}

teardown() {
   delete_upstream
   delete_downstream
}

#--------------------

bad_merge_simple() {
   local test_old_rev_zeros="$1"
   setup

   cd $TMP_DIR/downstream
   echo a >> a; git add a; git commit -am a
   ! $test_old_rev_zeros && git push

   git checkout -b b master
   echo b >> b; git add b; git commit -am b

   git checkout master
   echo a >> a; git add a; git commit -am a
   git merge --no-ff b -m merge

   # old_rev is zeros on first push to remote
   git push || true
   log

   teardown
}

good_merge_simple() {
   local test_old_rev_zeros="$1"
   setup

   cd $TMP_DIR/downstream
   echo a >> a; git add a; git commit -am a
   ! $test_old_rev_zeros && git push

   git checkout -b b master
   echo b >> b; git add b; git commit -am b
   echo b >> b; git add b; git commit -am b

   git checkout master
   git merge --no-ff b -m merge

   # old_rev is zeros on first push to remote
   git push
   log

   teardown
}


merge_double() {
   local do_rebase="$1"
   setup

   cd $TMP_DIR/downstream
   echo a >> a; git add a; git commit -am a
   git push

   git checkout -b b master
   echo b >> b; git add b; git commit -am b
   echo b >> b; git add b; git commit -am b
   git checkout master
   git merge --no-ff b -m merge

   git push

   echo a >> a; git add a; git commit -am a

   git checkout b
   $do_rebase && git rebase master
   echo b >> b; git add b; git commit -am b
   echo b >> b; git add b; git commit -am b
   git checkout master
   git merge --no-ff b -m merge

   git push || true
   log

   teardown
}

merge_octopus() {
   local do_rebase_b="$1"
   local do_rebase_c="$2"
   setup

   cd $TMP_DIR/downstream
   echo a >> a; git add a; git commit -am a
   echo a >> a; git add a; git commit -am a
   git push

   git checkout -b b master~
   echo b >> b; git add b; git commit -am b
   echo b >> b; git add b; git commit -am b
   $do_rebase_b && git rebase master

   git checkout -b c master~
   echo c >> c; git add c; git commit -am c
   echo c >> c; git add c; git commit -am c
   $do_rebase_c && git rebase master

   git checkout master
   # octopus merge
   git merge --no-ff b c -m merge

   git push || true
   log

   teardown
}

test_whitelist() {
   setup
   local b="$1"

   cd $TMP_DIR/downstream
   echo a >> a; git add a; git commit -am a
   echo a >> a; git add a; git commit -am a
   git push

   git checkout -b $b master~
   echo b >> b; git add b; git commit -am b
   git push origin $b

   echo b >> b; git add b; git commit -am b

   git checkout master
   git merge --no-ff $b -m merge

   git push || true
   log

   teardown
}

test_whitelist2() {
   setup
   local b="$1"

   cd $TMP_DIR/downstream
   echo a >> a; git add a; git commit -am a
   echo a >> a; git add a; git commit -am a
   git push

   git checkout -b $b master~
   git push origin $b
   echo b >> b; git add b; git commit -am b
   echo b >> b; git add b; git commit -am b

   git checkout master
   git merge --no-ff $b -m merge

   git push || true
   log

   teardown
}

test_delete_branch() {
   setup

   cd $TMP_DIR/downstream
   echo a >> a; git add a; git commit -am a

   git checkout -b b master
   echo b >> b; git add b; git commit -am b
   git push origin b

   log
   git push --delete origin b
   log

   teardown
}

test_tags() {
   setup

   cd $TMP_DIR/downstream
   echo a >> a; git add a; git commit -am a
   git push

   git tag -a -m t t
   git push --tags
   log

   teardown
}

#bad_merge_simple true ; #fail
#bad_merge_simple true ; #fail
#good_merge_simple true ; #succeed
#good_merge_simple true ; #succeed
#merge_double true ; #succeed
#merge_double false ; #fail

#merge_octopus false false; #fail
#merge_octopus false true; #fail
#merge_octopus true false; #fail
#merge_octopus true true; #succeed

#test_whitelist 'release/2.3'; #succeed
#test_whitelist 'unknown/2.3'; #fail

#test_whitelist2 'release/2.3'; #succeed

#test_delete_branch
test_tags

echo done
