#source this config variables for Backup and Restore script
echo "# loading config from entrypointConfig.sh"

export GATEWAY=$(ip route list | awk '/default/ { print $3 }')

tardirectory="/opt/share/moin"

basefilename="moinmoin"
# Date
d="$(env TZ=Pacific/Auckland date +%F-%Hh%M%z)"
backupHostname=$(hostname)
# FullName
f="${basefilename}/$(date +%Y)/$d-${basefilename}-${backupHostname:-vigor}.tar.xz"

# Set s3 object tag for first day of month
day_of_month="$(env TZ=Pacific/Auckland date +%d)"
if [ "$day_of_month" -eq 1 ]; then
    # Ensure that the tags follow S3 tagging rules:
    #   keys and values must be URL-encoded if they contain special characters, e.g. space = %20
    #   and each key-value pair must be separated by &.
    s3_tags="first_day_of_month=true"
else
    s3_tags="first_day_of_month=false"
fi

#S3_BUCKET_NAME="backupVigor"
S3_BUCKET_NAME="backups.vigor.nz"
S3_FILE_NAME_FILTER="${basefilename}-*"


if [[ "${AWS_ACCESS_KEY_ID}" == "" ]]; then
    echo "ERROR: empty env AWS_ACCESS_KEY_ID"
    echo "exit 1"
    sleep 3
    exit 1
else
    echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
fi

echo "#Debug $0"
echo "# S3_BUCKET_NAME=${S3_BUCKET_NAME} tardirectory=${tardirectory}"
echo "# d=${d} f=${f}"
echo "# s3_tags=${s3_tags}"

## Shared bash functions
time_start=$(date +%s)
function ElapsedTime() {
    # Prints lapsed time in user readable format, uses $1 or time since $time_start
    time_elapsed=${1:-$(( $(date +%s) - time_start))}
    eval "echo Elapsed time: $(date -ud "@$time_elapsed" +'$((%s/3600/24)) days %H hr %M min %S sec') $2"
}

echo "# entrypointConfig.sh loaded"