#!/usr/bin/perl

#$file = shift or die "\nUSAGE: $0 \n\n"
#        ."   will create mrDataDB (if necessary).\n\n";

$dbName = "mrDataDB";
$sqlFile = "mrDataDB.sql";
$test = 0;

print "A simple script to build the mrData database.\n\n";
print "WARNING! if you continue, it will DESTROY any data in your database!\n\n";
print "NOTE: If you haven\'t already done so, you should set a root password.\n";
print "You can do this with:\n";
print "  /usr/bin/mysqladmin -u root -p password \'new_password\'\n\n"; 
print "Hit 'control-C' to abort.\n\n";

print "Enter the database name: ($dbName) ";
chop($tmp = <>);
if($tmp ne ""){ $dbName = $tmp; }
print "Using dbName = $dbName.\n\n";

do{
  print "Enter the SQL file to load: ($sqlFile) ";
  chop($tmp = <>);
  if($tmp ne ""){ $sqlFile = $tmp; }
  if(! -e $sqlFile) { print "File not found- try again.\n\n"; } 
}while(! -e $sqlFile);
print "Using SQL file = $sqlFile.\n\n";

print "Enter the mySQL root password: ";
system("stty -echo");
chop($rootPwd = <>);
system("stty echo");
print "\n\n";

print "Enter the apache password: ";
system("stty -echo");
chop($apachePwd = <>);
system("stty echo");
print "\n\n";

# Hash for users- username->passwd.
%userList = ('apache@localhost', $apachePwd); 
# SHOULD DO THIS IN A LOOP- to allow more than one user to be entered.
print "Enter a username: ";
chop($user = <>);
print "\n";

print "Enter ".$user."'s password: ";
system("stty -echo");
chop($pwd = <>);
system("stty echo");
print "\n\n";

# add to users hash
$userList{$user} = $pwd;
$userList{$user.'@localhost'} = $pwd;

# Create the databases:
$cmd = "mysql -u root -p$rootPwd -e \"CREATE DATABASE IF NOT EXISTS $dbName;\"";
if($test){
  print $cmd."\n";
}else{
  if(system($cmd)){
    exit(-1);
  }
}
print "Created database $dbname.\n";

foreach $username (keys %userList) {
  $cmd = "mysql -u root -p$rootPwd -e 'GRANT ALL ON ".$dbName.".* TO $username "
        ."IDENTIFIED BY \"$userList{$username}\";'";
  if($test){
    print $cmd."\n";
  }else{
    if(system($cmd)){
      exit(-1);
    }
  }
  print "Granted permissions to user $username.\n";
}
# Force mySQL to flush the grant tables
if(!$test){
  system("mysqladmin -u root -p$rootPwd reload");
}

$cmd = "mysql -u root -p$rootPwd $dbname < $sqlFile";
if($test){
  print $cmd."\n";
}else{
  if(system($cmd)){
    exit(-1);
  }
}
print "Tables built.\n";

print "FINISHED.\n\n";

exit(0);
