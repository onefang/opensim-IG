#!/bin/bash

source common.sh
getPrgDir

NAME=$1
LOCATION=$2
URL=$3
IP=$4
SIZE=$5

OSPATH="/opt/opensim"
cd $OSPATH/config

k=0
for i in $(seq -w 1 99)
do
    j=$(num2name "$i")
    if [ -e "$j" ]
    then
	k=$i
    fi
done

if [ "x$NAME" = "x" ]
then
    NAME="No name sim $RANDOM"	# Should be unique per grid.
    echo "WARNING setting the sim name to [$NAME], this may not be what you want."
fi
# Sanitize the name.  Not removing [ or ], couldn't get that to work, only important for Windows.
sim=$(sanitize $NAME)

if [ "x$LOCATION" = "x" ]
then
    LOCATION="$RANDOM,$RANDOM"	# again UNIQUE (i.e. ONLY ONE) per grid in THIS case!
    echo "WARNING setting the Location to $LOCATION, this may not be what you want."
fi

if [ "x$IP" = "x" ]
then
				# 0.0.0.0 will work for a single sim per physical machine, otherwise we need the real internal IP.
    IP="0.0.0.0"
    echo "WARNING setting the InternalAddress to $IP, this may not be what you want."
#    echo "  0.0.0.0 will work for a single sim per physical machine, otherwise we need the real internal IP."
# According to the OpenSim docs, 0.0.0.0 means to listen on all NICs the machine has, which should work fine.
fi

if [ "x$URL" = "x" ]
then
# Here we make use of an external IP finding service.  Careful, it may move.
#    URL=$(wget -q http://automation.whatismyip.com/n09230945.asp -O -)	# URL is best (without the HTTP://), but IP (e.g. 88.109.81.55) works too.
    URL="SYSTEMIP"
    echo "WARNING setting the ExternalHostName to $URL, this may not be what you want."
fi

if [ "x$SIZE" = "x" ]
then
    SIZE="256"
fi

# Wow, the hoops we have to jump through to avoid octal.
if [ 9 -gt $k ]; then
    NUM=$(printf '0%1s' $(( 10#$k + 1 )) )
else
    NUM=$(printf '%2s' $(( 10#$k + 1 )) )
fi

PORT=$(( 9005 + (10#$k * 5) ))	# 9002 is used for HTTP/UDP so START with port 9003! CAUTION Diva/D2 starts at port 9000.
UUID=$(uuidgen)

echo "Creating sim$NUM on port $PORT @ $LOCATION - $NAME."

cp -r sim_skeleton sim$NUM

cd sim$NUM
mv My_sim.xml ${sim}.xml
sed -i "s@SIM_NAME@$NAME@g" ${sim}.xml
sed -i "s@SIM_UUID@$UUID@g" ${sim}.xml
sed -i "s@SIM_POS@$LOCATION@g" ${sim}.xml
sed -i "s@SIM_IP@$IP@g" ${sim}.xml
sed -i "s@SIM_INT_PORT@$(( $PORT + 1 ))@g" ${sim}.xml
sed -i "s@SIM_URL@$URL@g" ${sim}.xml
sed -i "s@SIM_SIZE@$SIZE@g" ${sim}.xml

ln -s ../../current/scripts/common.sh common.sh
ln -s ../../current/scripts/start-sim start-sim
cp -P start-sim backup-sim
cp -P start-sim stop-sim

sed -i "s@SIM_NUMBER@$NUM@g" ThisSim.ini
sed -i "s@SIM_PORT@$PORT@g" ThisSim.ini

sed -i "s@SIM_NUMBER@$NUM@g" opensim-monit.conf

sudo chown -R opensim:opensim ..
sudo chmod -R g+w ..
