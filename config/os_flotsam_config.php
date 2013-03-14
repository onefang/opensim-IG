<?php
    // be sure to set "error_reporting = E_ALL & ~E_NOTICE & ~E_DEPRECATED" in your php.ini

    // Set to 0 for no debugging, 1 for essential debugging, 2 for more information.
    $debugXMLRPC = 0;
    $debugXMLRPCFile = "/var/log/opensim_beta/xmlrpc.log";

	//////////////////////////////
	//// Group security
	/////////////////////

	// A xmlrpc client must have this key to commit changes to the Groups DB
	// Leave blank to allow all clients to make changes.
	$groupWriteKey = '';
	$groupReadKey  = '';

	// Enabling this, will require that the service attempt to verify the agent
	// is authentic by contacting the User Service specified in the request
	// to authenticate the AgentID and SessionID provided.
	$groupRequireAgentAuthForWrite = FALSE;

	// This enforces the role Permissions bitmask.
	$groupEnforceGroupPerms = FALSE;

	// Specify the following to hard-code / lockdown the User Service used to authenticate
	// user sessions.  Example: http://osgrid.org:8002
	// Note:  This causes the User Service specified with requests to be ignored, and 
	// prevents the service from being used cross-grid or by hypergridded users.
	$overrideAgentUserService = '';


	// This setting configures the behavior of the "Members are Visible" checkbox
	// provided for on the Role configuration panel -- and determines who is allowed
	// to get a list of members for a role when that checkbox is *NOT* checked.

	$membersVisibleTo = 'Group'; // Anyone in the group can see members
	// $membersVisibleTo = 'Owners'; // Only members of the owners role can see members
	// $membersVisibleTo = 'All'; // Anyone can see members

	// Enable UTF-8 characters in group descriptions, ranks or notices, to prevent them from getting garbled:
	$xmlrpc_internalencoding = 'UTF-8'
?>
