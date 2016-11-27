#!/usr/bin/perl
use strict;
use warnings;


# Took almost two and a half hours on IG.


=pod
# 7/30/2015 3:58PM
Rev B - cleanup
Rev C - added in missing UPDATE

 quthor Jeff Kelley <opensim@pescadoo.net>
 mods by Fred Beckhusen <fred@mitsi.com> aka Ferd Frederix

 This version has minimum Perl module dependencies.

 This script connects to an Opensim asset database and scans and fixed bug Mantis-7514
 The files that are fixed have multiple xmlns : in it, such as xmlns:xmlns:

 http://opensimulator.org/mantis/view.php?id=7514

############################################################################
# DO A BACKUP BEFORE YOU ATTEMPT THIS. DO A DRY RUN WITH UPDATE SET TO ZERO #
#############################################################################

 Set variable UPDATE to a 1 to write updates to the db.  A 0 will show you what it would change and also save the bad
 data to disk in a folder name 'corrupt' for you to examine.

 For safety, we will never update a record unless the UPDATE flag is on.

#############################################################
# DO NOT RUN THIS UNTIL YOU SET THE CONSTANTS BELOW         #
#############################################################

=cut

# these are typically found in StandaloneCommon.ini or GridCommon.ini

my $username = '*****';
my $password = '*****';
my $hostname = '*****'; # probably you use localhost for standalone, but it could be an IP address or a DNS name for a asset server.
my $robustDB = '*****'; # your MySQl DB name

# for safety, we will never update a record unless the UPDATE flag is on.
use constant LISTALL 	=> 0;                  # show all assets as they are scanned
use constant UPDATE     => 0;                  # set to 1 if you want to actually update the database
use constant MAX      	=> 16000000;           # max size of blob from your MySQL ini - see My.ini :  max_allowed_packet = 16M, You may need to set this to 64 MB if you have large assets. My largest was over 10 MB..jeepers!
use constant GETMAX  	=> 1;                  # set to 1 to query MAX object size (see above line) automatically - much slower to start, but less memory is used overall both at the server and at the client
use constant MANTIS7514 => '/tmp/fix_some_assets.ini';   # path to a temp file to keep track of each run. Delete the file to start at the beginning

# all these modules should already be in core.  If not, run "cpan name_of_module', or just go get Strawberry Perl.
use v5.10;                    # so we can say, and not need to add a newline
use DBI;                      # database I/O
$|=1;  #no buffering STDIO

my $counter = 0;       # count of xmlmns corruption
my $havedone = 0;
my $OddCounter = 0;    # other corrupt data

mkdir 'corrupt';       # save the data in this folder

my $dbh = DBI->connect(
    "dbi:mysql:dbname=$robustDB;host=$hostname",
    $username, $password,{RaiseError => 1 , LongReadLen => MAX, LongTruncOk => 0,AutoCommit => 1},
    ) or die $DBI::errstr;

# Get the largest blob in table data in the DB and set our size of memory buffers to that.
if (GETMAX) {
    my $max_len = GetLenData ();
    say "Largest object is $max_len bytes";
    $dbh->{LongReadLen}  = $max_len;
}

my $todo;
my $objectsList = GetAssetList();  # get a hash of all objects
$todo = scalar @$objectsList if ref $objectsList;   # count them
say "Found $todo objects";

for (@$objectsList) {
    my $obj_uuid = $_->{id};
    my $obj_name = $_->{name};
    my $obj_time = $_->{create_time};

    $havedone++;   # keep track of how many done

    my $obj_data = GetAssetData ($obj_uuid); # grab the blob

    ValidateXML ($obj_data,$obj_uuid, $obj_name);  # repair it and check it

    #save where we are at so we can be stopped and run again some other rainy day
    open(my $in_file, ">",MANTIS7514) || die 'Cannot save the last file date';
    print $in_file $obj_time;
    close $in_file;
}

say "Found $counter corrupt xmlns objects";
say "Found $OddCounter other possibly corrupted objects";
say "Done!";


sub GetAssetList {

    my $answref;

	my $time = 0;
	# read the last run date from a file
	if (open(my $in_file, "<",MANTIS7514))
	{
	   $time = <$in_file> || 0;
	   close $in_file;
	}
	my $query = "SELECT id,name, create_time FROM $robustDB.assets WHERE assetType=6 and create_time > $time order by create_time asc;";
	$answref = $dbh->selectall_arrayref ($query, { Slice => {} });

    return $answref;
}

sub GetAssetData {
    my $uuid = shift;
    my $query = "SELECT data FROM $robustDB.assets WHERE id='$uuid';";
    my $answr = $dbh->selectall_arrayref ($query, { Slice => {} });
    return @$answr[0]->{data};
}

sub UpdateData {
    return unless UPDATE;
    my $uuid = shift;
    my $data = shift;

    my $sth = $dbh->prepare("UPDATE $robustDB.assets set data = ? WHERE id = ?;");
    $sth->execute($data, $uuid) or die $DBI::errstr;;
}
sub GetLenData {
    my $len = $dbh->selectrow_array("SELECT MAX(OCTET_LENGTH(data)) FROM $robustDB.assets WHERE assetType=6;");
}


sub ValidateXML {
    my $data = shift;
    my $obj_uuid = shift;
    my $obj_name = shift || '';

	####  FORCES AN ERROR FOR DEBUG $data =~ s/xmlns:/xmlns:xmlns:/g; # the fix is in !!!!!!!!!

    # Test for repeated xmlns, clever RegEx by Jeff Kelley.
    my $corrupt = ($data =~ m/((xmlns:){2,}+)/g);
    my $err = $1 || '';

    # show them where we are at, if enabled or corrupted.
    printf "%d/%d | %s | %s | %s\n", $havedone, $todo, $corrupt ? 'Bad ' : 'Ok ', $obj_uuid, $obj_name if ($corrupt || LISTALL);

    if ($corrupt)
    {
        $counter++;

        print ("Found $err\n", 'red') ;
        my $original = $data;   # so we can save it to disk later, if need be.

        $data =~ s/(xmlns:){2,}+/xmlns:/g; # the fix is in

        UpdateData($obj_uuid,$data) if UPDATE;  # we update if we are enabled and had an error Rev C

        save({
              name        => "$obj_uuid-$obj_name-before.txt",
              uuid        => $obj_uuid,
              corrupt     => $err,
              data        => $original,
              type        => 0,
            });

        save({
              name        => "$obj_uuid-$obj_name-after.txt",
              uuid        => $obj_uuid,
              corrupt     => $err,
              data        => $data,
              type        => 0,
            });
	}

	return $corrupt; # in case the caller wants to know
}

sub save {
    my $c = shift;

	$c->{name} =~ s/[^A-Za-z0-9\-\.]//g; # make a safe file name

	# may have to force an UTF-16LE or UTF-BE encoding here but my tests show the data is always UTF-8 or ASCII.

    if (open(my $out_file, "> :encoding(UTF-8)",'corrupt/' . $c->{name})) {
        binmode ($out_file,":encoding(UTF-8)");

        $c->{data} =~ s/encoding="utf-8"/encoding="utf-16"/;  # not right, but that's they way they coded the XML in the DB.

        print $out_file $c->{data};
        print $out_file "\0";       # zero termination is in the OAR, lets put it back
    } else {
        say "Failed to open file";
        die;
    }

}

__END__

BSD License:
Copyright (c) 2015
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
Space here is intentionally left blank for note taking
