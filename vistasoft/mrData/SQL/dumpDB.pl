#!/usr/bin/perl

# *** We should lock the db before dumping, or use the new
# '--databases' option.
# We can use '--databases' to dump all the db's at once to one file.
# This is a new feature of mySQL, so the dump will not be backwards-compatible.

#$file = shift or die "\nUSAGE: $0 \n\n"
#        ."   dumps mrData DB.\n\n";

$dbName = 'mrDataDB';

$outDir = shift or $outDir = "./";
if(!($outDir =~ m/\/$/)){ $outDir = $outDir.'/'; }

$dateCode = `date +%y%m%d_%H%M`;
chop($dateCode);
$dbFile = $outDir.$dbName."_".$dateCode.".sql";

print "A simple script to dump the mrData database.\n";
print "The data will be dumped to $dbFile.\n\n";

print "Enter the database root password: ";
system("stty -echo");
chop($rootPwd = <>);
system("stty echo");
print "\n\n";

if(system("mysqldump -uroot -p$rootPwd --opt --add-drop-table --extended-insert $dbName > $dbFile")){
   exit(-1);
}

print "FINISHED.\n\n";

exit(0);
