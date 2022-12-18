#! /bin/sh
echo "# entrypointBackup.sh from $0"
source entrypointConfig.sh

set -x 
# 2022-12-08 tar error:: tar: data/event-log: file changed as we read it
nice -n18 tar --create -f - \
              --sparse --recursion \
              -C ${tardirectory} \
              --exclude "data/event-log" \
              data |\
pv -t -r -b -s $(du -sb ${tardirectory} | awk '{print $1}') \
   --cursor --name "tar" --fineta |\
nice -n19 xz --compress -6 \
             --check=crc64 \
             --memlimit=200MiB - |\
pv -t -r -b --wait \
   --cursor --name "xz" |\
aws s3 cp --expected-size $((1024*1024*300)) - s3://${S3_BUCKET_NAME}/${f}

# Now check if latest file is the one we just uploaded
FILE=$( aws s3api list-objects-v2 \
          --bucket "${S3_BUCKET_NAME}" \
          --query 'sort_by(Contents, &LastModified)[-1].Key' \
          --output=text
      )
echo "Found: s3 FILE=${FILE}"; echo "Write: f=$f"
echo "Write: basename f >> $(basename $f)"

if [[ "${FILE}" == "${f}" ]]; then
    echo "# Backup success latest file is ${f}"
    exit 0
else
    echo "# ERROR: ${FILE} != ${f}"
    sleep $(( 60*60*24 ))
    exit 1
fi

echo "The End."; sleep 10
