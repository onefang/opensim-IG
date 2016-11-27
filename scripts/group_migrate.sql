INSERT INTO `griddy`.`os_groups_groups`
(GroupID, Name, Charter, InsigniaID, FounderID, MembershipFee, OpenEnrollment, ShowInList,
AllowPublish, MaturePublish, OwnerRoleID)
SELECT GroupID, Name, Charter, InsigniaID, FounderID, MemberShipFee, OpenEnrollment, ShowInList, AllowPublish,
MaturePublish, OwnerRoleID
FROM `griddy`.osgroup;
 
/*fill os_groups_invites in ROBUST database with values from osgroupinvite
or FlotSam osgroupinvite*/
INSERT INTO `griddy`.`os_groups_invites`
(InviteID, GroupID, RoleID, PrincipalID, TMStamp)
SELECT InviteID, GroupID, RoleID, AgentID, TMStamp
FROM `griddy`.osgroupinvite;
 
/*fill os_groups_membership in ROBUST database with values from osgroupmembership
or FlotSam osgroupmembership*/
INSERT INTO `griddy`.`os_groups_membership`
(GroupID, PrincipalID, SelectedRoleID, Contribution, ListInProfile, AcceptNotices)
SELECT GroupID, AgentID, SelectedRoleID, Contribution, ListInProfile, AcceptNotices
FROM `griddy`.osgroupmembership;
 
/*fill os_groups_notices in ROBUST database with values from osgroupnotice
or FlotSam osgroupnotice*/
INSERT INTO `griddy`.`os_groups_notices`
(GroupID, NoticeID, TMStamp, FromName, Subject, Message)
SELECT GroupID, NoticeID, Timestamp, FromName, Subject, Message
FROM `griddy`.osgroupnotice;
 
/*fill os_groups_principals in ROBUST database with values from osagent
or FlotSam osagent*/
INSERT INTO `griddy`.`os_groups_principals`
(PrincipalID, ActiveGroupID)
SELECT AgentID, ActiveGroupID
FROM `griddy`.osagent;
 
/*fill os_groups_rolemembership in ROBUST database with values from osrolemembership
or FlotSam osgrouprolemembership*/
INSERT INTO `griddy`.os_groups_rolemembership
(GroupID, RoleID, PrincipalID)
SELECT GroupID, RoleID, AgentID
FROM `griddy`.osgrouprolemembership;
 
/*fill os_groups_roles in ROBUST database with values from osroles
or FlotSam osrole*/
INSERT INTO `griddy`.os_groups_roles
(GroupID, RoleID, Name, Description, Title, Powers)
SELECT GroupID, RoleID, Name, Description, Title, Powers
FROM `griddy`.osrole;
