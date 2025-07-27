#! /bin/bash
echo "# entrypointBackup.sh from $0"
source /entrypointConfig.sh

echo "# Check if ls works ..."
aws s3 ls s3://${S3_BUCKET_NAME}/${basefilename}/

ElapsedTime
UPLOAD_MAX_BYTES_PER_SEC="${UPLOAD_MAX_BYTES_PER_SEC:-1024k}"
UPLOAD_SIZE_BYTES_EST="${UPLOAD_SIZE_BYTES_EST:-280M}"
# 2025-07 ave size 240MB
# 2023-01-01 @128k backup to s3 24min, size in s3 183MB , rateimit to prevent high cpu usage
#  .b try 256k used to high cpu go xz and tar
#  .c try 128+64=192, still high cpu and disk wait 20min to finish
#  .d try 256k and resource.limit.cpu 20m

echo "# start backup ... s3://${S3_BUCKET_NAME}/${f} ..."
echo "    UPLOAD_MAX_BYTES_PER_SEC=${UPLOAD_MAX_BYTES_PER_SEC}  UPLOAD_SIZE_BYTES_EST=${UPLOAD_SIZE_BYTES_EST}"
# 2022-12-08 tar error:: tar: data/event-log: file changed as we read it
#pv -t -r -b -s $(du -sb ${tardirectory} | awk '{print $1}') \
#   --cursor --name "tar" --fineta |\
#pv -t -r -b --wait \
#   --cursor --name "xz" |\
if  [[ "${testrun}" == "true" ]]; then
    echo "# Testrun: uploading small test data to s3, just creating tar.gz file ..."
    f="testrun/${f}"
    basefilename="testrun/${basefilename}"
    echo "Test data $(date -Is)" | gzip | aws s3 cp - s3://${S3_BUCKET_NAME}/${f}
else
    nice -n18 tar --create -f - \
            --sparse --recursion \
            -C ${tardirectory} \
            --exclude "data/event-log" \
            data |\
    nice -n19 gzip |\
    pv --rate-limit "${UPLOAD_MAX_BYTES_PER_SEC}" \
        --size "${UPLOAD_SIZE_BYTES_EST}" \
        --interval 30 --delay-start 20 \
        --force --format $' %t %r %p %e  \n' \
        --buffer-size 100m |\
    aws s3 cp - s3://${S3_BUCKET_NAME}/${f}
fi
# --expected-size $((1024*1024*300)) 
ElapsedTime
echo "# Upload to s3 done. adding tags ..."
tag_key="first_day_of_month"
if [ "$day_of_month" -eq 1 ]; then
    tag_value="true"
else
    tag_value="false"
fi
# 
aws s3api put-object-tagging --bucket "${S3_BUCKET_NAME}" --key "${f}" \
    --tagging "{\"TagSet\": [{\"Key\": \"${tag_key}\", \"Value\": \"${tag_value}\"}]}"

echo "# sleep 10sec ..."
sleep 10
# Now check if latest file is the one we just uploaded
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
