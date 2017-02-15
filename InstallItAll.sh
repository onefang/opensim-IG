#!/bin/bash

OSPATH="/opt/opensim"
MYSQL_HOST="localhost"
MYSQL_DB="InfiniteGrid"
MYSQL_USER="opensim"
OS_USER="opensim"

OSVER="0.8.2.1"


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

# This should all be safe for pre existing installs that are being updated.

MYSQL_PASSWORD=$1
# Try to get old database credentials if they exist.
if [ -f ${OSPATH}/config/config.ini ]; then
    # Get the database credentials.
    declare -A creds
    while read -d ';' p; do
	k=$(echo ${p} | cut -d '=' -f 1)
	v=$(echo ${p} | cut -d '=' -f 2)
	creds[${k}]="${v}"
    done < <(sudo grep ConnectionString ${OSPATH}/config/config.ini | cut -d '"' -f 2)
    # The above seems the best way to get bash to let the creds assignments survive outside the loop.

    MYSQL_HOST="${creds[Data Source]}"
    MYSQL_DB="${creds[Database]}"
    MYSQL_USER="${creds[User ID]}"
    MYSQL_PASSWORD="${creds[Password]}"
fi
if [ -z $MYSQL_PASSWORD ]; then
    MYSQL_PASSWORD="OpenSimSucks${RANDOM}"
fi

USER=$(whoami)

echo "Installing software."
sudo apt-get install mysql-server tmux mono-complete mono-gmcs nant nunit uuid-runtime monit mc
sudo /etc/init.d/mysql restart

echo "Setting up OpenSim users."
# "create user if not exists" doesn't exist until MySQL 5.7, so we have to put up with a warning, which we can ignore.
mysql -u root -p -h localhost << zzzzEOFzzz
create database if not exists $MYSQL_DB;
create user $OS_USER identified by '$MYSQL_PASSWORD';
create user $OS_USER@localhost identified by '$MYSQL_PASSWORD';
grant all on $MYSQL_DB.* to $OS_USER;
grant all on $MYSQL_DB.* to $OS_USER@localhost;
FLUSH PRIVILEGES;
zzzzEOFzzz

sudo adduser --system --shell /bin/bash --group $OS_USER
sudo addgroup $USER $OS_USER

echo "Building OpenSim."
./runprebuild.sh
./nant-color

echo "Setting up OpenSim."
sudo rm -fr   $OSPATH/opensim-IG_*
sudo mkdir -p $OSPATH/opensim-IG_$OSVER
sudo cp -fr $PRGDIR/* $OSPATH/opensim-IG_$OSVER

cd $OSPATH
sudo ln -fs opensim-IG_$OSVER current

cd current

for dir in AssetFiles backups caches config db logs
do
    if [ ! -f ../$dir ]; then
	sudo cp -fr $dir ..
	sudo rm -fr $dir
	sudo ln -fs ../$dir $dir
    fi
done

pushd config/ROBUST >/dev/null
sudo ln -fs ../../current/scripts/common.sh common.sh
sudo ln -fs ../../current/scripts/start-sim start-sim
sudo ln -fs ../../current/scripts/start-sim stop-sim
popd >/dev/null

echo "Securing OpenSim."
sudo chown -R $OS_USER:$OS_USER $OSPATH
sudo chmod -R 775 $OSPATH
sudo chmod -R a-x $OSPATH
sudo chmod -R a+X $OSPATH
sudo chmod -R g+w $OSPATH
sudo chmod -R a+x $OSPATH/current/scripts/*.sh
sudo chmod a+x $OSPATH/current/scripts/show-console
sudo chmod a+x $OSPATH/current/scripts/start-sim

sudo chmod ug+rwx  $OSPATH/config
sudo chmod g+s     $OSPATH/config
sudo chmod 600 $OSPATH/config/config.ini

sudo sed -i "s@MYSQL_HOST@${MYSQL_HOST}@g" config/config.ini
sudo sed -i "s@MYSQL_DB@${MYSQL_DB}@g" config/config.ini
sudo sed -i "s@MYSQL_USER@${MYSQL_USER}@g" config/config.ini
sudo chmod 600 config/config.ini
sudo sed -i "s@MYSQL_PASSWORD@${MYSQL_PASSWORD}@g" config/config.ini
sudo chmod 600 config/config.ini

sudo cp scripts/opensim.tmux.conf /home/$OS_USER/.tmux.conf
sudo chown $USER /home/$OS_USER/.tmux.conf
sudo chmod 644 /home/$OS_USER/.tmux.conf

sudo scripts/fix_var_run.sh

echo "Done installing OpenSim."
