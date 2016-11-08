Use this to create a sim that links into Infinite Grid from Linux.

It's only been tested on Ubuntu 10.04, 11.04, and 12.04, YMMV.  This is
also a WIP, use it at your own risk.  It's been used to set up two
freshly installed Ubuntu servers though.

Follow these steps.
-------------------

Go to -

http://wiki.infinitegrid.org/index.php/Howto_Link_your_Opensim_region_to_Infinite_Grid

and follow the directions to create an admin user account.  You can skip
that bit if you already have a suitable user with sudo access.

Note that these scripts pretty much follow that above wiki description,
with some exceptions.  The configuration information per sim has been
rearranged so that there is only ONE copy of the OpenSim installation.

Next you need to figure out what password you want to use for OpenSims
access to the database.  We will call this "DatabasePassword".  Run the
following script -

./install_opensim.sh DatabasePassword

This will do most of the work for you, except for creating sims.  There
is a final step that needs to be done manually for now.  Edit
/etc/rc.local, make sure it has the following line in it somewhere,
probably at the end -

/opt/opensim/setup/fix_var_run.sh


Creating sims.
--------------

A separate script is here for sim creation, you can use it to create many
sims.  You will need -

Your host name, or it could be your IP, we will use "sims.example.net".

A name for your sim, we will use "My new sim".  It should be unique on
the grid.

A location for your sim, we will use "1234,5678".  You can use the
Infinite Grid web based map to poke around and find a good location. 
Choose an empty spot.

Once you have all that information sorted out, run this script -

./create_sim.sh "My new sim" "1234,5678" "sims.example.net"

Or this if you want to override the detected IP address -

./create_sim.sh "My new sim" "1234,5678" "sims.example.net" "1.2.3.4"


Running sims.
-------------

Now you can go to /opt/opensim/config/sim01 and run the following script
to start it up -

./start-sim

You will see the screen console.  You can run the screen console again by
running that command once more, or running the sim-console command.

You can stop the sim with -

./stop-sim

You can backup the sim with -

./backup-sim

Though they all get backed up every six hours anyway.


Finishing up.
-------------

Once it's all tested, you can use this to finish things off (back in
this setup directory) -

./go_live.sh

Which sets up the monit control file/s, though you should double check
it all, and you still have to do the basic configuration and enabling of
monit yourself.  This is in case you already have monit set the way you
like.


NOTES -

This attempts to use only one copy of the OS install for all sims.  We
are running one instance of OS for each sim though, as this prevents one
sim crashing from bringing down the others.  OS however really wants to
write data to directories within it's own bin directory.  I'm not at all
certian if that data can be shared.  For the same reason, so far I've
not been able to get to the point where we can make the OS directory
read only.  This complicates things during upgrades.

