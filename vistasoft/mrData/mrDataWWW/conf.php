<?php
#
# This is a sample conf file. Copy it to a file named 'conf.php'
# in the mrData home directory (the same directory with index.php)
# and edit the parameters below to suit your installation.
#

#
# SESSION PARAMS
#
# The session name is used by PHP's session management routines.
# If the user allows cookies, this will form the cookie name.
$conf->sessionName = "mrDataWWW";

#
# RAW DATA FTP SOURCES
#
# A hash of all available data sources.
#
# NOTE! Passwords must be stored in cleartext here! This is an pbvious
# security concern! You should consider using ssh/scp with public/private 
# keys instead. You can configure apache to securely run commands 
# on your data server with something like:
#  ssh -i /var/www/.ssh/id_dsa -o "StrictHostKeyChecking no" $serverName [some commands]
# And you can get files with:
#  scp -i /var/www/.ssh/id_dsa -o "StrictHostKeyChecking no" $servername:/get/this/file /put/it/here
# If the target username on the server is not apache, then be sure to add
# "-u $username" or prepend $username@ to the servername
# 
# For this to work, you must have an ssh private key stored in 
# the specified place (/var/www/.ssh/id_dsa). The public component 
# of this key needs to be entered into the ~/.shh/authorized_hosts 
# file on your server. Use something like this to generate the key pair:
#  ssh-keygen -t rsa -f /var/www/.ssh/id_dsa
#
# mrsic3t
$conf->rawDataSrc["lucas30t"]->name = "mrsic3t.stanford.edu";
$conf->rawDataSrc["lucas30t"]->host = "mrsic3t.stanford.edu";
$conf->rawDataSrc["lucas30t"]->port = 21;
$conf->rawDataSrc["lucas30t"]->user = "signa";
$conf->rawDataSrc["lucas30t"]->pwd = "30tlucas";
$conf->rawDataSrc["lucas30t"]->dataDir = "/usr/gvx/mrraw/*.7*";
# mrsic1
$conf->rawDataSrc["lucas15t"]->name = "mrsic1";
$conf->rawDataSrc["lucas15t"]->host = "mrsic1.stanford.edu";
$conf->rawDataSrc["lucas15t"]->port = 21;
$conf->rawDataSrc["lucas15t"]->user = "username";
$conf->rawDataSrc["lucas15t"]->pwd = "password";
$conf->rawDataSrc["lucas15t"]->dataDir = "/usr/gvx/mrraw/*.7*";
# lucas (uses public key- no password needed)
$conf->rawDataSrc["lucas"]->name = "mrsic1";
$conf->rawDataSrc["lucas"]->host = "lucas.stanford.edu";
$conf->rawDataSrc["lucas"]->port = 22;
$conf->rawDataSrc["lucas"]->user = "wandell";
$conf->rawDataSrc["lucas"]->pwd = "wb70lucas";
$conf->rawDataSrc["lucas"]->dataDir = "/tmp";
?>