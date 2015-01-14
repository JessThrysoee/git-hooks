#!/bin/bash -e

. $PWD/utils_test.sh

main() {
   expect_fail bad_merge_simple true
   expect_fail bad_merge_simple false
   expect_ok good_merge_simple true
   expect_ok good_merge_simple false
   expect_ok merge_double true
   expect_fail merge_double false
   expect_fail merge_octopus false false
   expect_fail merge_octopus false true
   expect_fail merge_octopus true false
   expect_ok merge_octopus true true
   expect_ok test_whitelist 'release/2.3'
   expect_fail test_whitelist 'unknown/2.3'
   expect_ok test_whitelist2 'release/2.3'
   expect_ok test_delete_branch
   expect_ok test_create_tag
   expect_ok test_delete_tag

   echo done
}

#--------------------

bad_merge_simple() {
   local test_old_rev_zeros="$1"

   echo a >> a; git add a; git commit -am a
   ! $test_old_rev_zeros && git push

   git checkout -b b master
   echo b >> b; git add b; git commit -am b

   git checkout master
   echo a >> a; git add a; git commit -am a
   git merge --no-ff b -m merge

   # old_rev is zeros on first push to remote
   git push
}

good_merge_simple() {
   local test_old_rev_zeros="$1"

   echo a >> a; git add a; git commit -am a
   ! $test_old_rev_zeros && git push

   git checkout -b b master
   echo b >> b; git add b; git commit -am b
   echo b >> b; git add b; git commit -am b

   git checkout master
   git merge --no-ff b -m merge

   # old_rev is zeros on first push to remote
   git push
}

merge_double() {
   local do_rebase="$1"

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

   git push
}

merge_octopus() {
   local do_rebase_b="$1"
   local do_rebase_c="$2"

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

   git push
}

test_whitelist() {
   local b="$1"

   echo a >> a; git add a; git commit -am a
   echo a >> a; git add a; git commit -am a
   git push

   git checkout -b $b master~
   echo b >> b; git add b; git commit -am b
   git push origin $b

   echo b >> b; git add b; git commit -am b

   git checkout master
   git merge --no-ff $b -m merge

   git push
}

test_whitelist2() {
   local b="$1"

   echo a >> a; git add a; git commit -am a
   echo a >> a; git add a; git commit -am a
   git push

   git checkout -b $b master~
   git push origin $b
   echo b >> b; git add b; git commit -am b
   echo b >> b; git add b; git commit -am b

   git checkout master
   git merge --no-ff $b -m merge

   git push
}

test_delete_branch() {
   echo a >> a; git add a; git commit -am a

   git checkout -b b master
   echo b >> b; git add b; git commit -am b
   git push origin b

   git push --delete origin b
}

test_create_tag() {
   echo a >> a; git add a; git commit -am a
   git push

   git tag -a -m t t
   git push --tags
}

test_delete_tag() {
   echo a >> a; git add a; git commit -am a
   git push

   git tag -a -m t t
   git push --tags

   git tag -d t
   git push --delete origin t
}

main "$@"

