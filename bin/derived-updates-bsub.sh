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
# Submit job and capture job ID
# Note: -K flag removed because pods have no stable IP for LSF to call back to.
# Instead, we poll bjobs every 30 seconds to keep the Jenkins connection alive.
JOB_ID=$(bsub \
  -W 1:00 \
  -n ${PROCESSES} \
  -o derived-updates/logs/${DATASET}-derived-updates.lsf-output.log \
  derived-updates \
    --config=derived-updates/${DATASET}-derived-updates.yaml \
    --processes=${PROCESSES} \
  | grep -oP '(?<=Job <)\d+')

echo "Submitted job $JOB_ID, waiting for completion..."

# Poll until job is no longer pending or running
while bjobs $JOB_ID 2>&1 | grep -qE "PEND|RUN"; do
    echo "Job $JOB_ID still running at $(date)..."
    sleep 30
done

# Check exit status
EXIT_CODE=$(bjobs -l $JOB_ID 2>&1 | grep -oP '(?<=Exit Code )\d+' || echo "0")
if [ "${EXIT_CODE}" != "0" ]; then
    echo "ERROR: Cluster job failed with exit code $EXIT_CODE"
    exit $EXIT_CODE
fi

echo "Cluster job completed successfully"
exit 0
