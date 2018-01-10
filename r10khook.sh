#!/usr/bin/env bash
LOGFILE=/var/log/gitlab/r10k/deployment.log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$LOGFILE 2>&1

echo "`date "+%Y-%m-%d %H:%M:%S"` : Starting Puppet Environment Deployment/Update"
ssh -T r10k@foreman r10k deploy environment -pv
echo "`date "+%Y-%m-%d %H:%M:%S"` : End Puppet Environment Deployment/Update"
