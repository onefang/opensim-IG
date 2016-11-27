#!/bin/bash

source common.sh
getPrgDir

# Get the database credentials.
declare -A creds
while read -d ';' p; do
  k=$(echo ${p} | cut -d '=' -f 1)
  v=$(echo ${p} | cut -d '=' -f 2)
  creds[${k}]="${v}"
done < <(grep ConnectionString ${PRGDIR}/../config/config.ini | cut -d '"' -f 2)
# The above seems the best way to get bash to let the creds assignments survive outside the loop.

# Only backup those that have not logged on since their last backup, but returning prims from sims will bypass this check.
timestamp=$(ls -o --time-style="+%s" ${PRGDIR}/../../backups/.keep | cut -d ' ' -f 5)
touch ${PRGDIR}/../../backups/.keep
# Well it was good in theory, but looks like they broke it in 8.2, no logging in or out updates to GridUser.

# Get the user names, and back 'em up.
mysql --host="${creds[Data Source]}" "${creds[Database]}" --user="${creds[User ID]}" --password="${creds[Password]}" \
  -e "select FirstName,LastName from UserAccounts,GridUser where UserAccounts.PrincipalID=LEFT(GridUser.UserID,36) and GridUser.Login>${timestamp};" -ss | while read user; do
  # Replace tab with space
  user=${user//	/ }
  # Find out the size of the last backup, base our later sleep on that, but do it now before backup-inventory packs it away.
  sizeSleep=`sleepPerSize i "${user}"`
  ${PRGDIR}/backup-inventory "${user}"
  # Sleep for a while, so that there is plenty of time to do the backup,
  # and we are not keeping the computer very busy if there are lots of users.
  sleep ${sizeSleep}
done
