#! /bin/sh
echo "# Source entrypointRestore.sh from $0"
set -x 
export GATEWAY=$(ip route list | awk '/default/ { print $3 }')

tardirectory="/opt/share/moin/"
#tardirectory="/var/lib/moinmoin/vigor"
basefilename="backupMoinVigor"
S3_BUCKET_NAME="backupVigor"
S3_FILE_NAME_FILTER="${basefilename}-*"
FILE=$( aws s3api list-objects-v2 \
          --bucket "${S3_BUCKET_NAME}" \
          --prefix "${basefilename}" \
          --query 'sort_by(Contents, &LastModified)[-1].Key' \
          --output=text
      )
echo "Found: FILE=${FILE}" 

# 2022-12-08 tar error:: tar: data/event-log: file changed as we read it
time aws s3 cp s3://${S3_BUCKET_NAME}/${FILE} - |\
xz --decompress - |\
tar --extract -f - \
    -C ${tardirectory} 


echo "The End."; sleep 600
