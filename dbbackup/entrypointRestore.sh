#! /bin/bash
echo "# Source entrypointRestore.sh from $0"
source /entrypointConfig.sh

# set -x 

if [[ -e "${tardirectory}/data/edit-log" ]]; then
    echo "Found ${tardirectory}/data/edit-log"
else
    echo "NOT Found ${tardirectory}/data/edit-log"
    ls -l ${tardirectory}/data/
fi


FILE=$( aws s3api list-objects-v2 \
          --bucket "${S3_BUCKET_NAME}" \
          --prefix "${basefilename}" \
          --query 'sort_by(Contents, &LastModified)[-1].Key' \
          --output=text
      )
if [[ "${FILE}" == "" ]]; then
    echo "ERROR: did not find file to restore in ${S3_BUCKET_NAME} / ${basefilename}"
    exit 1
else
    echo "Found: FILE=${FILE}"
fi 

# 2022-12-08 tar error:: tar: data/event-log: file changed as we read it
time aws s3 cp s3://${S3_BUCKET_NAME}/${FILE} - |\
xz --decompress - |\
tar --extract -f - \
    -C ${tardirectory} 
if [[ $? == 0 ]]; then
    echo "S3 Restore SUCCESS"
else
    echo "Error during s3 restore"
    sleep 600
    exit 1
fi

echo "The End."; sleep 10
