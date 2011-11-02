<?php
require_once("include.php");
init_session();
writeHeader("Login", "secure");
if(isset($_REQUEST['msg'])) $msg = $_REQUEST['msg'];
else $msg = '';

if(isset($_REQUEST['continueURL'])) $continueURL = $_REQUEST['continueURL'];
else $continueURL = dirname(selfURL())."/";

// If there are lingering session vars, then we use those. But values
// submitted via the form over-ride those.
if(isset($_REQUEST['dbname'])) $dbname = $_REQUEST['dbname'];
elseif(isset($_SESSION['dbname'])) $dbname = $_SESSION['dbname'];
else $dbname = 'mrDataDB';

if(isset($_REQUEST['username'])) $username = $_REQUEST['username'];
elseif(isset($_SESSION['username'])) $username = $_SESSION['username'];
else $username = '';
// We could send a default username, but that would be a bit 
// less secure (gives would-be hackers more info).

if(isset($_SESSION['password'])){
  $msg = "You are currently logged in. You may "
    ."<a href=\"$continueURL\">continue</a> or <a href=\"".selfURL()
    ."?logout=1\">logout</a>.";
}

if(isset($_REQUEST['logout'])){
  // Clear the session
  destroy_session();
  sendLoginForm(selfURL(), $dbname, $username, 'You have been logged out.', $continueURL);
}elseif(!isset($_REQUEST['password'])){
  sendLoginForm(selfURL(), $dbname, $username, $msg, $continueURL);
}else{
  // process the form & register the session
	$password = $_REQUEST['password'];
  list($db, $msg) = dbConnect($username, $password, $dbname, 'localhost');
  if(!$db){
    sleep(2);
    sendLoginForm(selfURL(), $dbname, $username, 'Login Failed: '.$msg, $continueURL);
  }else{
    $_SESSION['dbname'] = $dbname;
    $_SESSION['username'] = $username;
    $_SESSION['password'] = $password;
    echo "<center><h1><a href=\"$continueURL\">Continue...</a></h1></center>";
  }
}

writeFooter();

function sendLoginForm($submitURL, $dbname='', $username='', $msg='', $continueURL=''){
?>
<center><h1>mrData login</h1>
<?if($msg!='') echo "<p class=msg>$msg</p>\n";?>
<form method=POST name="login" action="<?=$submitURL?>">
<input type=hidden name=continueURL value="<?=$continueURL?>">
<table border=0 cellspacing=0 cellpadding=1>
<tr><td align=right>Database Name:</td>
<td><select name="dbname" value="<?=$dbname?>">
<option value=wandell>wandell</option>
<option value=mrDataDB>mrDataDB</option>
<option value=test>test</option>
</td>
</tr><tr>
<tr><td align=right>Login Name:</td>
<td><input type=text name="username" size=20 maxlength=40 value="<?=$username?>"></td>
</tr><tr>
<td align=right>Password:</td>
<td><input type=password name="password" size=15 maxlength=40 value="">
</td></tr>
</table>
<input type=submit value="Login">
</form>
</center>

</form>
<?php
}
?>