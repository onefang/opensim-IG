#!/bin/bash

source common.sh
getPrgDir

for i in $(seq -w 1 99)
do
    j=$(num2name ${i})
    if [ -e "${PRGDIR}/../config/${j}" ]
    then
	pushd ${PRGDIR}/../config/${j} >/dev/null
	# Find out the size of the last backup, base our later sleep on that, but do it now before backup-sim packs it away.
	sizeSleep=`sleepPerSize o "$(getSimName ${i})"`
	./backup-sim
	# Sleep for a while, so that there is plenty of time to do the backup,
	# and we are not keeping the computer very busy if there are lots of sims.
	sleep ${sizeSleep}
	popd > /dev/null
    fi
done
