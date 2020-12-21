#!/bin/sh

cpus() {
  if which nproc &>/dev/null; then
    nproc | tr -d '\n'
  else
    # fallback to 1 process
    echo -n 1
  fi
}

NUM_PROCESSES=${NUM_PROCESSES:-$(cpus)}

MIN_THREADS=${MIN_THREADS:-1}
MAX_THREADS=${MAX_THREADS:-1}

PUMA_OPTS=${PUMA_OPTS:-"--preload"}

bundle exec puma -w "${NUM_PROCESSES}" -t "$MIN_THREADS:$MAX_THREADS" $PUMA_OPTS
