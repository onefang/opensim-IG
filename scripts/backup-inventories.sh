#!/bin/bash

# Figure out where we are, most of this mess is to troll through soft links.
PRG="$0"
while [ -h "${PRG}" ] ; do
  ls=$(ls -ld "${PRG}")
  link=`expr "${ls}" : '.*-> \(.*\)$'`
  if expr "${link}" : '.*/.*' > /dev/null; then
    PRG="${link}"
  else
    PRG=$(dirname "${PRG}")/"${link}"
  fi
done
PRGDIR=$(dirname "${PRG}")
pushd ${PRGDIR} >/dev/null
PRGDIR=$(pwd)
popd >/dev/null

# Get the database credentials.
declare -A creds
while read -d ';' p; do
  k=$(echo ${p} | cut -d '=' -f 1)
  v=$(echo ${p} | cut -d '=' -f 2)
  creds[${k}]="${v}"
done < <(grep ConnectionString ${PRGDIR}/../config/config.ini | cut -d '"' -f 2)
# The above seems the best way to get bash to let the creds assignments survive outside the loop.

# Only backup those that have not logged on since their last backup, but returning prims from sims will bypass this check.
timestamp=$(ls -o --time-style="+%s" ${PRGDIR}/../backups/.keep | cut -d ' ' -f 5)
touch ${PRGDIR}/../backups/.keep

# Get the user names, and back 'em up.
mysql --host="${creds[Data Source]}" "${creds[Database]}" --user="${creds[User ID]}" --password="${creds[Password]}" \
  -e "select FirstName,LastName from UserAccounts,GridUser where UserAccounts.PrincipalID=GridUser.UserID and GridUser.Logout>${timestamp};" -ss | while read user; do
  # Replace tab with space
  user=${user//	/ }
  ${PRGDIR}/backup-inventory "${user}"
  # Sleep for a while, so that there is plenty of time to do the backup,
  # and we are not keeping the computer very busy if there are lots of users.
  # My big arsed 1 GB OAR takes about ten minutes to create, and maybe an hour to gitIOR!
  sleep 200
done
