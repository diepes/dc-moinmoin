#!/bin/bash
cat ~/.aws/credentials | grep "^aws_" | sed 's/\(^[a-z_]\+\) = \([a-zA-Z0-9]*\)/\U\1\E=\2/g' > aws_credentials.env
docker-compose up --build backuprestore
