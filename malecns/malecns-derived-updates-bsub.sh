#!/bin/bash

PROCESSES=16

. /misc/lsf/conf/profile.lsf

# Must come after the above line.
set -ex

# Submit job with -K flag to wait for completion
# The -K flag makes bsub run synchronously and return the job's exit code
# Note: The 'derived-updates' command is shipped with the neuclease package.
bsub -o logs/malecns-derived-updates.lsf-output.log -n ${PROCESSES} -K  "derived-updates --config=malecns-derived-updates.yaml --processes=${PROCESSES}"

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR: Cluster job failed with exit code $EXIT_CODE"
    exit $EXIT_CODE
fi

echo "Cluster job completed successfully"
exit 0
