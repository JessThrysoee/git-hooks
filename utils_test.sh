#!/bin/bash -e

function create_tmp_dir() {
   TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp/}${0##*/}.XXXXXX")"
   mkdir -p "$TMP_DIR"
}

function delete_tmp_dir() {
   [[ -n $TMP_DIR && -d $TMP_DIR ]] &&  rm -rf "$TMP_DIR"
}

update_hook=$PWD/update.enforce-clean-merges
create_tmp_dir
trap delete_tmp_dir EXIT

log() {
   git -C $TMP_DIR/downstream log --graph --oneline --decorate --all
}

expect_ok() {
   setup

   if "$@" > $TMP_DIR/output 2>&1
   then
      echo "$1..OK"
   else
      cat $TMP_DIR/output
      log
      echo "$@""..FAILED"
      exit 1
   fi

   teardown
}

expect_fail() {
   setup

   if ! "$@" > $TMP_DIR/output 2>&1
   then
      echo "$1..OK"
   else
      cat $TMP_DIR/output
      log
      echo "$@""..FAILED"
      exit 1
   fi

   teardown
}

create_upstream() {
   cd $TMP_DIR

   mkdir -p upstream
   cd upstream
   git init --bare > /dev/null 2>&1
   cd hooks
   ln -s $update_hook update
}

delete_upstream() {
   cd $TMP_DIR
   rm -rf upstream
}

create_downstream() {
   cd $TMP_DIR
   git clone upstream downstream > /dev/null 2>&1
}

delete_downstream() {
   cd $TMP_DIR
   rm -rf downstream
}

setup() {
   create_upstream
   create_downstream
   cd $TMP_DIR/downstream
}

teardown() {
   delete_upstream
   delete_downstream
}

