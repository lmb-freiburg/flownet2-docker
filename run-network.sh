##
# Author: Nikolaus Mayer
##

#!/usr/bin/env bash

## Fail if any command fails (use "|| true" if a command is ok to fail)
set -e
## Treat unset variables as error
set -u

## Exit with error code
fun__die () {
  exit `false`;
}

## Print usage help
fun__print_usage () {
  printf "###################################################################\n";
  printf "#                           FlowNet 2.0                           #\n";
  printf "###################################################################\n";
  printf "\n";
  printf "Usage: ./run-network.sh -n network [-g gpu] [-v|vv] first-input second-input output\n";
  printf "\n";
  printf "where 'first-input' and 'second-input' are either both images (in which\n";
  printf "case 'output' is interpreted as output file) or both files of newline-\n";
  printf "separated filepaths (in which case the output argument must be a file\n";
  printf "of newline-separated output filenames). All files must have the exact\n";
  printf "same number of lines (one output per input pair).\n";
  printf "The estimated flow maps the first input to the second input (i.e.\n";
  printf "'first'==t, 'second'==t+1).\n";
  printf "The input files must be within the current directory. All input and\n";
  printf "output filenames will be treated as relative to this directory.\n";
  printf "\n";
  printf "The 'gpu' argument is the numeric index of the GPU you want to use.\n";
  printf "This only makes sense on a multi-GPU system.\n";
  printf "\n";
  printf "By default, only errors are printed. Single verbosity (-v) prints\n";
  printf "debug outputs, and double verbosity (-vv) also prints whatever the\n";
  printf "docker container prints to stdout\n";
  printf "\n";
  printf "Available 'network' values:\n";
  printf "  FlowNet2\n";
  printf "  FlowNet2-c\n";
  printf "  FlowNet2-C\n";
  printf "  FlowNet2-cs\n";
  printf "  FlowNet2-CS\n";
  printf "  FlowNet2-css\n";
  printf "  FlowNet2-CSS\n";
  printf "  FlowNet2-css-ft-sd\n";
  printf "  FlowNet2-CSS-ft-sd\n";
  printf "  FlowNet2-s\n";
  printf "  FlowNet2-S\n";
  printf "  FlowNet2-SD\n";
  printf "  FlowNet2-ss\n";
  printf "  FlowNet2-SS\n";
  printf "  FlowNet2-sss\n";
  printf "  FlowNet2-KITTI\n";
  printf "  FlowNet2-Sintel\n";
}

## Parameters (some hardcoded, others user-settable)
GPU_IDX=0;
CONTAINER="flownet2";
NETWORK="";
VERBOSITY=0;

## Verbosity-controlled "printf" wrapper for ERROR
fun__error_printf () {
  if test $VERBOSITY -ge 0; then
    printf "%s\n" "$@";
  fi
}
## Verbosity-controlled "printf" wrapper for DEBUG
fun__debug_printf () {
  if test $VERBOSITY -ge 1; then
    printf "%s\n" "$@";
  fi
}

## Parse arguments into parameters
while getopts g:n:vh OPTION; do
  case "${OPTION}" in
    g) GPU_IDX=$OPTARG;;
    n) NETWORK=$OPTARG;;
    v) VERBOSITY=`expr $VERBOSITY + 1`;;
    h) fun__print_usage; exit `:`;;
    [?]) fun__print_usage; fun__die;;
  esac
done
shift `expr $OPTIND - 1`;

## Isolate network inputs
FIRST_INPUT="";
SECOND_INPUT="";
OUTPUT="";
if test "$#" -ne 3; then
  fun__error_printf "! Missing input or output arguments";
  fun__die;
else
  FIRST_INPUT="$1";
  SECOND_INPUT="$2";
  OUTPUT="$3";
fi

## Check if input files exist
if test ! -f "${FIRST_INPUT}"; then
  fun__error_printf "First input '${FIRST_INPUT}' is unreadable or does not exist.";
  fun__die;
fi
if test ! -f "${SECOND_INPUT}"; then
  fun__error_printf "Second input '${SECOND_INPUT}' is unreadable or does not exist.";
  fun__die;
fi


## Check and use "-n" input argument
BASEDIR="/flownet2/flownet2/models";
WORKDIR="/flownet2/flownet2/scripts";
case "${NETWORK}" in
  "FlowNet2")           ;;
  "FlowNet2-c")         ;;
  "FlowNet2-C")         ;;
  "FlowNet2-cs")        ;;
  "FlowNet2-CS")        ;;
  "FlowNet2-css")       ;;
  "FlowNet2-CSS")       ;;
  "FlowNet2-css-ft-sd") ;;
  "FlowNet2-CSS-ft-sd") ;;
  "FlowNet2-s")         ;;
  "FlowNet2-S")         ;;
  "FlowNet2-SD")        ;;
  "FlowNet2-ss")        ;;
  "FlowNet2-SS")        ;;
  "FlowNet2-sss")       ;;
  "FlowNet2-KITTI")     ;;
  "FlowNet2-Sintel")    ;;
  *) fun__error_printf "Unknown network: ${NETWORK} (run with -h to print available networks)";
     fun__die;;
esac
WEIGHTS="${BASEDIR}/${NETWORK}/${NETWORK}_weights.caffemodel*";
DEPLOYPROTO="${BASEDIR}/${NETWORK}/${NETWORK}_deploy.prototxt.template";

## (Debug output)
fun__debug_printf "Using GPU:       ${GPU_IDX}";
fun__debug_printf "Running network: ${NETWORK}";
fun__debug_printf "Working dir:     ${WORKDIR}";
fun__debug_printf "First input:     ${FIRST_INPUT}";
fun__debug_printf "Second input:    ${SECOND_INPUT}";
fun__debug_printf "Output:          ${OUTPUT}";


## Run docker container
#  - "--device" lines map a specified host GPU into the contained
#  - "-v" allows the container the read from/write to the current $PWD
#  - "-w" executes "cd" in the container (each network has a folder)
## Note: The ugly conditional only switches stdout on/off.
if test $VERBOSITY -ge 2; then
  nvidia-docker run \
    --rm \
    --volume "${PWD}:/input-output:rw" \
    --workdir "${WORKDIR}" \
    -it "$CONTAINER" /bin/bash -c "cd ..; source set-env.sh; cd -; python run-flownet-docker.py --verbose --gpu ${GPU_IDX} ${WEIGHTS} ${DEPLOYPROTO} ${FIRST_INPUT} ${SECOND_INPUT} ${OUTPUT}"
else
  nvidia-docker run \
    --rm \
    --volume "${PWD}:/input-output:rw" \
    --workdir "${WORKDIR}" \
    -it "$CONTAINER" /bin/bash -c "cd ..; source set-env.sh; cd -; python run-flownet-docker.py --gpu ${GPU_IDX} ${WEIGHTS} ${DEPLOYPROTO} ${FIRST_INPUT} ${SECOND_INPUT} ${OUTPUT}"
    > /dev/null;
fi

## Bye!
fun__debug_printf "Done!";
exit `:`;

