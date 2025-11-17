#!/bin/bash

##
## Launch a bsub job to run the 'derived-updates' tool
## (shipped with neuclease as an executable) on a particular dataset,
## assuming your config is named derived-updates/{dataset}-derived-updates.yaml
## This script waits for the bsub job to complete and fails if the job failed.
##
## Usage:
##
##   cd flyem-jenkins-jobs/<datset-dir>
##   ../bin/derived-updates-bsub.sh <dataset> <processes>
##

# Here, the DATASET must match the subdirectory in flyem-jenkins-jobs
# AND must match the name of the derived-updates config file.
DATASET=$1
PROCESSES=${2:-16}

if [ -z "$DATASET" ]; then
  echo "ERROR: DATASET is not set"
  echo "Usage: $0 <dataset> <processes>"
  exit 1
fi

. /misc/lsf/conf/profile.lsf

# Must come after the above line.
set -ex

mkdir -p derived-updates/logs

# Submit job with -K flag to wait for completion
# The -K flag makes bsub run synchronously and return the job's exit code
bsub \
  -W 1:00 \
  -n ${PROCESSES} \
  -K  \
  -o derived-updates/logs/${DATASET}-derived-updates.lsf-output.log \
  derived-updates \
    --config=derived-updates/${DATASET}-derived-updates.yaml \
    --processes=${PROCESSES} \
##


EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR: Cluster job failed with exit code $EXIT_CODE"
    exit $EXIT_CODE
fi

echo "Cluster job completed successfully"
exit 0
