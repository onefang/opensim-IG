CREATE TABLE IF NOT EXISTS `Offline_IM` (
  `uuid` varchar(36) NOT NULL,
  `message` text NOT NULL,
  PRIMARY KEY  (`uuid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
