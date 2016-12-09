#!/bin/bash

OSPATH="/opt/opensim"

for i in $(seq 99)
do
    j=$(printf "sim%02d" $i)
    if [ -e "$OSPATH/config/$j" ]
    then
	sudo ln -s $OSPATH/config/$j/opensim-monit.conf /etc/monit/conf.d/$j.conf
    fi
done
