#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

aws --profile minio --no-verify --endpoint-url https://localhost:9000 s3 ls
echo
result=$?

echo
echo

read -p "Are you willing to delete? ok? (y/N): " yn
case "$yn" in
  [yY]*)
 echo
 echo
 echo Wipeout bucket.....
 echo
 echo
 aws --profile minio --no-verify --endpoint-url https://localhost:9000 s3 rb s3://backupkasten --force
 aws --profile minio --no-verify --endpoint-url https://localhost:9000 s3 ls
 ;;
  *) echo "abort";;
esac

