#/bin/bash

# Setup the source and destination here
SOURCE_CLUSTER_NAME='Demo'
TARGET_PROJECT_ID='5b75e82ec0c6e34530147939'
TARGET_CLUSTER_NAME='QA'

strip_quotes (){
  var=${1}
  var="${var%\"*}"
  var="${var#*\"}"
  echo "${var}"
  return 0
}

# If current snapshot is still taking place, wait for it to stop.
status=''
while [[ "${status}" != "completed" ]]
do
  status=$(mongocli atlas backups snapshots list "${SOURCE_CLUSTER_NAME}" -o json | jq '.results[0].status')
  status="${status%\"*}"
  status="${status#*\"}"
  echo "Waiting on backup to complete. status: ${status}"
  sleep 10
done

# get last snapshot ID
snapshotId=$(mongocli atlas backups snapshots list "${SOURCE_CLUSTER_NAME}" -o json | jq '.results[0].id')
snapshotId=$(strip_quotes "$snapshotId")

# Restore snapshot to TARGET_PROJECT_ID / TARGET_CLUSTER_NAME
echo "Starting restore... (snapshotId: ${snapshotId})"

# Start the restore job
mongocli atlas backups restores start automated --clusterName "${SOURCE_CLUSTER_NAME}" --output json --snapshotId "${snapshotId}" --targetClusterName "${TARGET_CLUSTER_NAME}" --targetProjectId "${TARGET_PROJECT_ID}" > /dev/null 2>&1

# Wait for restore to finish
finishedAt='null'
let count=0
while [[ "${finishedAt}" == 'null' ]]
do
  echo "Waiting for completion (${count})..."
  let count=${count}+1
  sleep 10
  finishedAt=$(mongocli atlas backups restores list "${SOURCE_CLUSTER_NAME}" --output json | jq '.results[0].finishedAt')
done

echo "Done."
