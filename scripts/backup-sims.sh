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

for i in $(seq 99)
do
    j=$(printf "sim%02d" $i)
    if [ -e "${PRGDIR}/../config/$j" ]
    then
	cd ${PRGDIR}/../config/$j
	./backup-sim
	# Sleep for a while, so that there is plenty of time to do the backup,
	# and we are not keeping the computer very busy if there are lots of sims.
	sleep 200
    fi
done
