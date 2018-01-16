#!/usr/bin/env bash
LOGFILE=/var/log/gitlab/r10k/deployment.log
if [ ! -w $LOGFILE ]
then
  touch $LOGFILE
fi

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$LOGFILE 2>&1

echo "`date "+%Y-%m-%d %H:%M:%S"` : Starting Puppet Environment Deployment/Update"
while read oldref newref refname
do
  foreman=foreman
  env=$(basename $refname)
  repo=$(basename -s .git $(pwd))
  group=$(basename `dirname $(pwd)`)
  echo "Old branch: $oldref"
  echo "New newbranch: $newref"
  echo "Environment: $env"
  echo "Repo: $repo"
  echo "Group: $group"
  echo "Puppet Server: $foreman"

#### r10k-environment control
  if echo $repo | egrep -q 'r10k-environment'
  then
    ## If a environment is being deleted, call r10k to cleanup enironment
    if echo $newref | egrep -q '^0*$'
    then
      echo "Branch $env is being deleted, updating all to trigger cleanup"
      ssh -T r10k@$foreman "r10k deploy environment -v"

    ## If a environment is being created, call r10k to deploy the environment
    elif echo $oldref | egrep -q '^0*$'
    then
      echo "Branch $env is being created, deploy $env environment"
      ssh -T r10k@$foreman "r10k deploy environment $env -v"

    ## If this isn't a new environment  and the Puppetfile in the r10k-environment repo has been changed, call r10k to update the environment
    elif git diff --name-only $oldref $newref | grep -q Puppetfile
    then
      ssh -T r10k@$foreman "r10k deploy environment $env -pv"
    fi
  else
#### If the repo is part of the puppet module group inf-puppet-dist or inf-puppet-site, call r10k to deploy module only   
    if echo $group | egrep -q 'inf-puppet-(dist|site)'
    then
      ssh -T r10k@$foreman "r10k deploy module $repo -e $env -v"
    fi
  fi
done
echo "`date "+%Y-%m-%d %H:%M:%S"` : End Puppet Environment Deployment/Update"
