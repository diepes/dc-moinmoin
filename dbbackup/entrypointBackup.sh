#! /bin/bash
echo "# entrypointBackup.sh from $0"
source /entrypointConfig.sh

echo "# Check if ls works ..."
aws s3 ls s3://${S3_BUCKET_NAME}/

ElapsedTime
UPLOAD_MAX_BYTES_PER_SEC="${UPLOAD_MAX_BYTES_PER_SEC:-128k}"
UPLOAD_SIZE_BYTES_EST="${UPLOAD_SIZE_BYTES_EST:-185M}"
# 2023-01-01 @128k backup to s3 24min, size in s3 183MB , rateimit to prevent high cpu usage
#            try 256k used to high cpu go xz and tar, try 128+64=192, still high cpu and disk wait

echo "# start backup ... s3://${S3_BUCKET_NAME}/${f} ...  UPLOAD_MAX_BYTES_PER_SEC=${UPLOAD_MAX_BYTES_PER_SEC}  UPLOAD_SIZE_BYTES_EST=${UPLOAD_SIZE_BYTES_EST}"
# 2022-12-08 tar error:: tar: data/event-log: file changed as we read it
#pv -t -r -b -s $(du -sb ${tardirectory} | awk '{print $1}') \
#   --cursor --name "tar" --fineta |\
#pv -t -r -b --wait \
#   --cursor --name "xz" |\
nice -n18 tar --create -f - \
              --sparse --recursion \
              -C ${tardirectory} \
              --exclude "data/event-log" \
              data |\
nice -n19 xz --compress -5 \
             --check=crc64 \
             --memlimit=200MiB - |\
pv --rate-limit "${UPLOAD_MAX_BYTES_PER_SEC}" --size "${UPLOAD_SIZE_BYTES_EST}" --interval 30 --delay-start 20 --force --format $' %t %r %p %e  \n' |\
aws s3 cp - s3://${S3_BUCKET_NAME}/${f}

# --expected-size $((1024*1024*300)) 
# Now check if latest file is the one we just uploaded
ElapsedTime
echo "# Upload to s3 done.  sleep 10sec ..."
sleep 10
echo "# get latest file in bucket ..."
FILE=$( aws s3api list-objects-v2 \
          --bucket "${S3_BUCKET_NAME}" \
          --prefix "${basefilename}" \
          --query 'sort_by(Contents, &LastModified)[-1].Key' \
          --output=text
      )
echo "# Found: s3 latest FILE=${FILE}"
echo "# We wrote: f=$f   \$(basename \$f)=$(basename $f)"

if [[ "${FILE}" == "${f}" ]]; then
    echo "# Backup success latest file match ${f}"
    ElapsedTime
    exit 0
else
    echo "# ERROR: ${FILE} != ${f}"
    #sleep $(( 60*60*24 ))
    ElapsedTime
    exit 1
fi

ElapsedTime
echo "# The End."; sleep 1
