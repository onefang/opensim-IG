# Create the opensim run dir.
mkdir -p /var/run/opensim
chown opensim:opensim /var/run/opensim
chmod ug+rwx  /var/run/opensim
chmod o-rwx  /var/run/opensim
chmod g+s  /var/run/opensim
