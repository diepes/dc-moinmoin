#! /bin/sh
echo "# Source entrypointBackupRestore.sh from $0"
set -x 
export GATEWAY=$(ip route list | awk '/default/ { print $3 }')
tardirectory="/opt/share/moin/"
#tardirectory="/var/lib/moinmoin/vigor"
basefilename="backupMoinVigor"
d="$(date +%F-%Hh%M%z)"
fullName="${basefilename}-$d" ##Create new baseName+date
f="${basefilename}/$(date +%Y)/${basefilename}-$d.tar.xz"

S3_BUCKET_NAME="backupVigor"
S3_FILE_NAME_FILTER="${basefilename}-*"
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


# /tmp/$( basename $f)

#       aws s3api list-objects-v2 \
#         --bucket "my-awesome-bucket" \
#         --query 'sort_by(Contents, &LastModified)[-1].Key' \
#         --output=text
FILE=$( aws s3api list-objects-v2 \
          --bucket "${S3_BUCKET_NAME}" \
          --query 'sort_by(Contents, &LastModified)[-1].Key' \
          --output=text
      )
echo "Found: FILE=${FILE}"; echo "Write: f=$f"
echo "Write: basename f >> $(basename $f)"

# aws s3 cp "s3://${S3_BUCKET_NAME}/$FILE" .


echo "The End."; sleep 600
