#source this config variables for Backup and Restore script
echo "# loading config from entrypointConfig.sh"

export GATEWAY=$(ip route list | awk '/default/ { print $3 }')
tardirectory="/opt/share/moin"
basefilename="backupMoinVigor"
fullName="${basefilename}-$d" ##Create new baseName+date
f="${basefilename}/$(date +%Y)/${basefilename}-$d.tar.xz"

#S3_BUCKET_NAME="backupVigor"
S3_BUCKET_NAME="backups.vigor.nz"
S3_FILE_NAME_FILTER="${basefilename}-*"

d="$(date +%F-%Hh%M%z)"

if [[ "${AWS_ACCESS_KEY_ID}" == "" ]]; then
    echo "ERROR: empty env AWS_ACCESS_KEY_ID"
    exit 1
else
    echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
fi
