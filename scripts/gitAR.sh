#!/bin/bash

# Work around OpenSims slow database corruption bug by using git to store all old backups.
# Try to squeeze every last byte out of the tarballs.  Seems to cut the total storage size down to one third the size of just the raw I/OAR files.
# Saves even more if there's been no changes.
# On the other hand, these backup files will grow indefinately, the more changes, the faster it grows.  I can live with that for more reliable backups that go back further.
# Tries to avoid loosing data if things go wrong.  I think the main remaining problem would be running out of space, in which case you have bigger problems to deal with.

# Strategy - unpack the last one, unpack and commit any old I/OARs, pack up the result, delete it's working directory, THEN run the save i/oar.
# Avoids having to sync with OpenSim finishing the current I/OAR, and as a bonus, an easy to deliver latest I/OAR for people that want it.

# Not really meant to be called by users, so don't bother validating the input and such.

source common.sh
getPrgDir

type=$1
title=$2
date=$(date '+%F_%T')

# Convert the type to uppercase.
gar="_git$(echo -n ${type} | tr '[:lower:]' '[:upper:]')AR"
name=$(sanitize "${title}")

if [ -d ${PRGDIR}/../../backups/temp_backup${type}_${name} ]; then
  echo "WARNING - Mess left over from last backup, not gonna run!"
  mv ${PRGDIR}/../../backups/temp_backup${type}_${name}/*.oar ${PRGDIR}/../backups
  exit 1
fi

mkdir -p ${PRGDIR}/../../backups/temp_backup${type}_${name}
pushd ${PRGDIR}/../../backups/temp_backup${type}_${name} >/dev/null
if [ -f ../${name}${gar}.tar.xz ]; then
  nice -n 19 tar -xf ../${name}${gar}.tar.xz
else
  mkdir -p ${name}${gar}
  git init ${name}${gar} >log
fi

pushd ${name}${gar} >/dev/null

# Make sure stuff that's already compressed doesn't get compressed by git.
# Also tries to protect binaries from mangling.
cat >.gitattributes <<- zzzzEOFzzzz
*.bvh -delta -diff -text
*.jp2 -delta -diff -text
*.jpg -delta -diff -text
*.llmesh -delta -diff -text
*.ogg -delta -diff -text
*.png -delta -diff -text
*.r32 -delta -diff -text
*.tga -delta -diff -text
zzzzEOFzzzz
# Coz git insists.
git config user.email "opensim@$(hostname -A | cut -d ' ' -f 1)"
git config user.name  "opensim"

# Git is such a pedantic bitch, let's just fucking ignore any errors it gives due to lack of anything to do.
# Even worse the OpenSim devs breaking logout tracking gives git plenty of nothing to do.  lol

# Looping through them in case there's a bunch of I/OARs from previous versions of this script.
# Ignore files of zero size that OpenSim might create.
find ../.. -maxdepth 1 -type f -name "${name}-*.${type}ar" -size '+0c' | sort | while read file;  do
  # Deal with deletions in the inventory / sim, easy method, which becomes a nop for files that stay in the git add below.
  git rm -fr * &>>../log 		#|| echo "ERROR - Could not clean git for  ${file} !" >>../errors
  if [ ! -f ../errors ]; then
    nice -n 19 tar -xzf "${file}" || echo "ERROR - Could not unpack ${file} !" >>../errors
  fi
  if [ ! -f ../errors ]; then
    git add * &>>../log
    git add */\* &>>../log 		#|| echo "ERROR - Could not add ${file} to git!" >>../errors
    git add .gitattributes &>>../log
    # Magic needed to figure out if there's anything to commit.
    # After all the pain to get this to work, there's an ever changing timestamp in archive.xml that screws it up.
    # Like this system didn't have enough timestamps in it already.  lol
    # TODO - I could sed out that timestamp, and put it back again based on the OAR file name when extracting.
    #        IARs don't seem to have the timestamp.
    if t=$(git status --porcelain) && [ -z "${t}" ]; then
      true
    else
      # Note this commit message has to be just the file name, as the ungitAR script uses it.
      git commit -qm "$(basename ${file})" &>>../log || echo "ERROR - Could not commit ${file} !" >>../errors
    fi
    if [ ! -f ../errors ]; then
      mv ${file} ..
    fi
  fi
  if [ -f ../errors ]; then
    exit 1	# Seems to only exit from this loop, not the script.  Makes me want to rewrite this in a real language.  lol
  fi
done

#git gc --aggressive --prune=now		# Takes a long time, doesn't gain much.  Even worse, it increases the size of the resulting tarball.  lol

popd >/dev/null

if [ ! -f errors ]; then
  XZ_OPT="-9e" nice -n 19 tar -c --xz ${name}${gar} -f ../${name}${gar}.tar.xz || echo "ERROR - Could not pack gitAR!" >>errors
fi

popd >/dev/null

if [ -f ${PRGDIR}/../../backups/temp_backup${type}_${name}/errors ]; then
  echo "NOT cleaning up coz - "
  cat ${PRGDIR}/../../backups/temp_backup${type}_${name}/errors
else
  rm -fr ${PRGDIR}/../../backups/temp_backup${type}_${name}
fi
