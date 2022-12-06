#! /bin/sh
echo "# Source entrypointBackupRestore.sh from $0"
export GATEWAY=$(ip route list | awk '/default/ { print $3 }')

#tardirectory="/opt/share/moin/"
tardirectory="/var/lib/moinmoin/vigor"

basefilename="backupMoinVigor"
d="$(date +%F-%Hh%M)"
fullName="${basefilename}-$d" ##Create new baseName+date
f="backupsFull/$(date +%Y)/${fullName}-FULL.tar.xz" 

s3bucket="backupVigor"

nice -n18 tar --create -f -         \
    --sparse --recursion            \
    -C ${tardirectory} data           |
nice -n19 xz --compress -6 --memlimit=200MiB  --check=crc64 - |
pv -t -r -b                                  |
aws s3 cp --expected-size $((1024*1024*1024*30)) - s3://${s3bucket}/$f

