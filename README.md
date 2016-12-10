Use this to create a sim that links into Infinite Grid from Linux.

It's only been tested on Ubuntu 10.04, 11.04, 12.04, 16.04' as well as
Debian 8, YMMV.  This is also a WIP, use it at your own risk.  It's been
used to set up a few freshly installed Ubuntu servers though.

The directory layout.
---------------------

The various directories are -

.git		Used by git for it's internal accounting, and the older versions.

.nant		Used by the nant build tool.

OpenSim		OpenSim source code.

Prebuild	Used by the build system.

ThirdParty	For third party OpenSim modules.

addon-modules	Also for third party modules.  Don't ask me why there's two.

bin		The OpenSim binaries, and other files.

doc		Supposedly for documentation, which I wish OpenSim devs would write some.

scripts		Various Linux scripts for managing OpenSim.

share		No idea really.

Also, the installation script moves the following directories to outside
of this main directory, they are all used for writing various things. 
Makes it easy to upgrade, and separates them from actual executable
stuff.

AssetFiles	Stores assets if running in grid mode.

backups		All sim and inventory backups are stored here.

caches		Various cached things.

config		All your configurtion files.

db		If you are not using MySQL, your data lives here.

logs		Log files get stored here.


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
following script, from inside the OpenSim directory -

./InstallItAll.sh DatabasePassword

This will do most of the work for you, except for creating sims.  There
is a final step that needs to be done manually for now.  Edit
/etc/rc.local, make sure it has the following line in it somewhere,
probably at the end -

/opt/opensim/current/scripts/fix_var_run.sh


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

Once you have all that information sorted out, run this script from the
installed scripts directory -

./create_sim.sh "My new sim" "1234,5678" "sims.example.net"

Or this if you want to override the detected IP address -

./create_sim.sh "My new sim" "1234,5678" "sims.example.net" "1.2.3.4"

Also, you can create a varregion with something like -

./create_sim.sh "My new sim" "1234,5678" "sims.example.net" "1.2.3.4" 512

Note that the size has to be a multiple of 256, so 512, 768, 1024, etc.

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



Finishing up.
-------------

Once it's all tested, you can use this to finish things off (back in
the scripts directory) -

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

