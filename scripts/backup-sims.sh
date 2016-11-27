#!/bin/bash

source common.sh
getPrgDir

for i in $(seq 99)
do
    j=$(num2name ${i})
    if [ -e "${PRGDIR}/../config/${j}" ]
    then
	cd ${PRGDIR}/../config/$j
	./backup-sim
	# Sleep for a while, so that there is plenty of time to do the backup,
	# and we are not keeping the computer very busy if there are lots of sims.
	sleep 200
    fi
done
