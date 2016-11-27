#!/bin/echo Don't run this file, it's for common functions."


# Figure out where we are, most of this mess is to troll through soft links.
# PRGDIR=$(getPrgDir)
getPrgDir()
{
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
  export PRGDIR=$(pwd)
  popd >/dev/null
}


# Convert number to sim name
# name=$(num2name 1)
num2name()
{
  # Using a string format, coz using a number format ends with an octal error, coz 08 isn't a valid octal number.
  # Why isn't octal dead already?
  printf 'sim%02s' "$1"
}


# Sanitize the name.  Not removing [ or ], couldn't get that to work, only important for Windows.
# name=$(sanitize "the name")
sanitize()
{
  echo "$1" | sed -e 's/[\\/:\*\?"<>\|@#$%&\0\x01-\x1F\x27\x40\x60\x7F. ]/_/g' -e 's/^$/NONAME/'
}


# Grab the first Section line of the sims .xml file, cut it down to the name.
# name=$(getSimName 1)
getSimName()
{
    grep "<Section " ${PRGDIR}/../../config/$(num2name $1)/*.xml | head -n 1 | cut -d '"' -f 2
}


# Calculate size of the sleep @ one second per megabyte of combined I/OAR file sizes.
# sleepPerSize o "the name"
# sleepPerSize i "the name"
sleepPerSize()
{
  type="$1"
  name=$(sanitize "$2")

  rm -f ${PRGDIR}/../../backups/${name}-sleepPerSize
  for file in ${PRGDIR}/../../backups/${name}-*.${type}ar; do
    if [ -f ${file} ]; then
      # We only loop through them coz bash sucks, we can find the total size now and jump out of the loop.
      echo $(du -c -BM ${PRGDIR}/../../backups/${name}-*.${type}ar | tail -n 1 | cut -f 1 | cut -d 'M' -f 1)
      touch ${PRGDIR}/../../backups/${name}-sleepPerSize
      break
    fi
  done

  # Sleep 200 instead if we can't find any files.
  if [ -f ${PRGDIR}/../../backups/${name}-sleepPerSize ]; then
    rm -f ${PRGDIR}/../../backups/${name}-sleepPerSize
  else
    echo 200
  fi
}

