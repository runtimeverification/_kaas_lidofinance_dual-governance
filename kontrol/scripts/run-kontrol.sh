#!/bin/bash
set -euo pipefail

SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# shellcheck source=/dev/null
source "$SCRIPT_HOME/common.sh"
export RUN_KONTROL=true
CUSTOM_FOUNDRY_PROFILE=default
export FOUNDRY_PROFILE=$CUSTOM_FOUNDRY_PROFILE
export OUT_DIR=out # out dir of $FOUNDRY_PROFILE
parse_args "$@"

#############
# Functions #
#############
kontrol_build() {
  notif "Kontrol Build"
  # shellcheck disable=SC2086
  run kontrol build \
    --verbose \
    --require $lemmas \
    --module-import $module \
    $rekompile
}

kontrol_prove() {
  notif "Kontrol Prove"
  # shellcheck disable=SC2086
  run kontrol prove \
    --max-depth $max_depth \
    --max-iterations $max_iterations \
    --smt-timeout $smt_timeout \
    --workers $workers \
    $reinit \
    $bug_report \
    $break_on_calls \
    $auto_abstract \
    $tests \
    $use_booster
}

dump_log_results(){
  trap clean_docker ERR
    RESULTS_FILE="results-$(date +'%Y-%m-%d-%H-%M-%S').tar.gz"
    LOG_PATH="$SCRIPT_HOME/logs"
    RESULTS_LOG="$LOG_PATH/$RESULTS_FILE"

    if [ ! -d $LOG_PATH ]; then
      mkdir $LOG_PATH
    fi

    notif "Generating Results Log: $LOG_PATH"

    run tar -czvf results.tar.gz "$OUT_DIR" > /dev/null 2>&1
    if [ "$LOCAL" = true ]; then
      mv results.tar.gz "$RESULTS_LOG"
    else
      docker cp "$CONTAINER_NAME:/home/user/workspace/results.tar.gz" "$RESULTS_LOG"
    fi
    if [ -f "$RESULTS_LOG" ]; then
      cp "$RESULTS_LOG" "$LOG_PATH/kontrol-results_latest.tar.gz"
    else
      notif "Results Log: $RESULTS_LOG not found, skipping.."
    fi
    # Report where the file was generated and placed
    notif "Results Log: $(dirname "$RESULTS_LOG") generated"

    if [ "$LOCAL" = false ]; then
      notif "Results Log: $RESULTS_LOG generated"
      RUN_LOG="run-kontrol-$(date +'%Y-%m-%d-%H-%M-%S').log"
      docker logs "$CONTAINER_NAME" > "$LOG_PATH/$RUN_LOG"
    fi
}

# Define the function to run on failure
on_failure() {
  dump_log_results

  if [ "$LOCAL" = false ]; then
    clean_docker
  fi

  notif "Cleanup complete."
  exit 1
}

# Set up the trap to run the function on failure
trap on_failure ERR INT

#########################
# kontrol build options #
#########################
# NOTE: This script has a recurring pattern of setting and unsetting variables,
# such as `rekompile`. Such a pattern is intended for easy use while locally
# developing and executing the proofs via this script. Comment/uncomment the
# empty assignment to activate/deactivate the corresponding flag
lemmas=kontrol/counter-lemmas.k
base_module=COUNTER-LEMMAS
module=CounterTest:$base_module
rekompile=--rekompile
rekompile=
regen=--regen
# shellcheck disable=SC2034
regen=

#################################
# Tests to symbolically execute #
#################################
test_list=()
if [ "$SCRIPT_TESTS" == true ]; then
    # Here go the list of tests to execute with the `script` option
    test_list=( "CounterTest.prove_SetNumber" )
elif [ "$CUSTOM_TESTS" != 0 ]; then
    test_list=( "${@:${CUSTOM_TESTS}}" )
fi
tests=""
# If test_list is empty, tests will be empty as well
# This will make kontrol execute any `test`, `prove` or `check` prefixed-function
# under the foundry-defined `test` directory
for test_name in "${test_list[@]}"; do
    tests+="--match-test $test_name "
done

#########################
# kontrol prove options #
#########################
max_depth=1000000
max_iterations=1000000
smt_timeout=100000
max_workers=16 # Should be at most (M - 8) / 8 in a machine with M GB of RAM
# workers is the minimum between max_workers and the length of test_list
# unless no test arguments are provided, in which case we default to max_workers
if [ "$CUSTOM_TESTS" == 0 ] && [ "$SCRIPT_TESTS" == false ]; then
    workers=${max_workers}
else
    workers=$((${#test_list[@]}>max_workers ? max_workers : ${#test_list[@]}))
fi
reinit=--reinit
reinit=
break_on_calls=--break-on-calls
break_on_calls=
auto_abstract=--auto-abstract-gas
auto_abstract=
bug_report=--bug-report
bug_report=
use_booster=--no-use-booster
use_booster=

#############
# RUN TESTS #
#############
conditionally_start_docker

kontrol_build
kontrol_prove

dump_log_results

if [ "$LOCAL" == false ]; then
    notif "Stopping docker container"
    clean_docker
fi

notif "DONE"
