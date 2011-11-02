<?php
/*
 * editTable.php
 *
 * eg. editTable?table=sessions
 *
 * Builds an html form to add a new entry to the specfied table.
 * Fields that specify an entry in another table are automatically
 * converted to a pull-down list of all entries in that other table.
 *
 * NOTE: this code assumes that any table that you want to edit
 * has a primary key field named 'id'.
 * 
 *
 * TODO:
 * 
 *
 * - Add DELETE option. The deleteRecord function is written, and the
 *   plan is to add a 'delete' link to the $idStr
 * - Add session support and store d[...] in a session var. 
 *   This would clean up the code quite a bit. Most of the confusing
 *   stuff below is beacuse we currently use hidden fields in the 
 *   forms to preserve state.
 *
 * HISTORY:
 *  2003.04.28 RFD (bob@white.stanford.edu) wrote it.
 */

require_once("include.php");

$db = login();

if(!isset($_REQUEST["table"]) || $_REQUEST["table"]==""){
  trigger_error("'table' is not specified.");
  exit;
}

if (isset($_REQUEST["studyMem"]))
  $studyMem = $_REQUEST["studyMem"];
else
  $studyMem = "All studies";

if (isset($_REQUEST["sessionMem"]))
  $sessionMem = $_REQUEST["sessionMem"];
else
  $sessionMem = "All sessions";

// The PHP default behavior will change soon, so that form-submit
// variable will no longer be available as simple globals. The preferred
// syntax for accessing them is via the "super globals" $_GET,
// $_POST and $_REQUEST (which includes both $_POST and $_GET vars).
// I find the $REQUEST['varName'] thing unwieldy, so I unpack them here.
// This is probably a good thing, since it makes it clear what vars we are 
// expecting.
if(isset($_REQUEST["d"])) $d = $_REQUEST["d"];
if(isset($_REQUEST["prevTable"])) $prevTable = $_REQUEST["prevTable"];
if(isset($_REQUEST["deleteId"])) $deleteId = $_REQUEST["deleteId"];
else $deleteId = 0;
$extras = array();
if(isset($_REQUEST["returnURL"])) $extras["returnURL"] = $_REQUEST["returnURL"];
if(isset($_REQUEST["returnIdName"])) $extras["returnIdName"] = $_REQUEST["returnIdName"];
if(isset($_REQUEST["defaultDataId"])) $defaultDataId = $_REQUEST["defaultDataId"];
else $defaultDataId = 0;
if(isset($_REQUEST["msg"])) $msg = $_REQUEST["msg"];
else $msg = "";
if(isset($_REQUEST["updateId2"]))
  $updateId2 = $_REQUEST["updateId2"];
else 
  $updateId2 = 0;

// NOTE! $table may not be set correctly yet. The code just below 
// here will check to see if $table should be changed given the state
// of the table stack ($prevTable). So, if you need to know $table,
// check it AFTER the SUBMIT and CANCEL processing steps below.
$table = $_REQUEST["table"];

$passwd = $d[$table]['password'];
if(isset($_REQUEST["verify"])) $verify = $_REQUEST["verify"];
else $verify = "";

// Encryption key for password
$key = "PaulVerlaine";

if(isset($prevTable) && is_array($prevTable)) $numPendingTables = count($prevTable);
else $numPendingTables = 0;

if(isset($_REQUEST[$table])){
  // PROCESS SUBMIT
  // If a submit button with a name matching our current table is set, then
  // we think the user wants to submit the data for this table.
  
  // Hash/binary-encrypt password if match verify
  $failed = false;
  if($table == 'users')
    if($passwd != "" || $verify != ""){
      if($passwd != $verify){?>
        <script type="text/javascript">
        alert ('Password verification failed: please type password again.');
        </script><?
	    $failed = true;
	    // Keep in mind we might be here on an update task
	  }
	  else{
	    $d[$table]['password'] = encrypt_md5($d[$table]['password'], $key);
	    $failed = false;
	  }
    }
  if(!$failed){
    list($success, $msg, $id) = updateRecord($db, $table, $d[$table], $updateId);
    if($success){
      unset($d[$table]);
      if($numPendingTables>0){
        // pop one off the previous table stack.
        $table = array_pop($prevTable);
      }
      if(isset($extras["returnURL"]) && $numPendingTables==0){
        if (strpos(urldecode($extras["returnURL"]),'?')===FALSE) $urlChar = "?";
        else $urlChar = "&";
        if(isset($extras["returnIdName"]))
	      header("Location: ".$returnURL.$urlChar.$extras["returnIdName"]."=".$id);
        else
	      header("Location: ".$returnURL.$urlChar."id=".$id); 
        exit;
      }
    }
  }
}elseif(isset($_REQUEST["cancel"])){
  // PROCESS CANCEL
  $msg = "Cancelled insert/update for table $table.";
  unset($d[$table]);
  if($numPendingTables>0){
    // pop one off the previous table stack.
    $table = array_pop($prevTable);
  }
  if(isset($extras["returnURL"]) && $numPendingTables==0){
    header("Location: ".$returnURL);
    exit;
  }
}
// Now we need to look for another submit button with a different table name.
// This would tell us that the user wants to add an entry to a different
// table before finishing the current table.
foreach($_REQUEST as $key=>$val){
  if($val=="New"){
    if(isset($prevTable) && is_array($prevTable))
      array_push($prevTable, $table);
    else
      $prevTable = array($table);
    $table = $key;
  }
}
// $table should be set properly now.

// PROCESS A DELETE REQUEST
if($deleteId!=0){
	if($numPendingTables>0){
		$msg .= " Refusing to process delete- there are pending tables.";
	}else{
		list($success, $m) = deleteRecord($db, $table, $deleteId);
		if(strlen($msg>0)) $msg .= " / ".$m; else $msg = $m;
		// We do a redirect so that the 'deleteId' won't remain in the url.
		// *** RFD: There's got to be a better way!
		header("Location: ".$_SERVER["PHP_SELF"]."?table=".$table."&msg=".urlencode($msg));
		exit;
	}
}

// We do something confusing here. The idea is that we can either 
// create a new row or edit an existing row. If the 'id' field is 
// set and non-zero, then we assume that it is an update. Otherwise, it
// will be treated as an insert.
if(isset($_REQUEST["updateId"]))
  $d[$table]['id'] = $_REQUEST["updateId"];
else 
  $d[$table]['id'] = 0;

// Here we actually start writing the HTML.
writeHeader("Edit $table", "secure", $msg);
if(($d[$table]['id']!=0) || ($updateId2!=0 && $failed)){
  echo "<h1>Update entry in table '$table':</h1>\n";
  if($d[$table]['id']==0)
    $d[$table]['id'] = $updateId2;
}
else echo "<h1>Add entry to table '$table':</h1>\n";

$selfUrl = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];
// The following function requires the non-trivial code above to process the
// data, so I'm not sure that it makes sense to keep it in a separate function.
echo buildFormFromTable($db, $table, $prevTable, $selfUrl, $d, $extras, $defaultDataId);

?>
<hr>
<h1>Existing entries in table '<?=$table?>':</h1>
<?
if(isset($extras["returnURL"]) && isset($extras["returnIdName"])){
  // This is a little hack to make the displayTable more flexible. We can send in
  // a string that will build a more useful id for each row. Background:
  // the first column of any of our substantive tables is the item id (the primary key).
  // The displayTable function will replace every occurance of "<ID>" in $idStr with
  // that entry (the row id) and show the hacked $idStr instead of the raw id. 
  // Here we send in a link that will return the row id to the returnURL. 
  // Check for returnURL having a q mark. If so, use an ampersand instead so that 
  // the URL doesn't get garbled.
  if (strpos(urldecode($extras["returnURL"]),'?')===FALSE) {
    $idStr = "<a href=\"".$extras["returnURL"]."?".$extras["returnIdName"]."=<ID>\">use <ID></a>";
  }else{
    $idStr = "<a href=\"".$extras["returnURL"]."&".$extras["returnIdName"]."=<ID>\">use <ID></a>";
    echo 'foo';
  }

}elseif(!is_array($prevTable) || count($prevTable)<1){
  // We don't allow edits/deletes if there are tables in the prevTable stack.
  // That would screw up our fragile state-preservation mechanism and
  // it isn't really the intended workflow. 
/*  $idStr = "<a href=\"".$selfUrl."?table=".$table."&updateId=<ID>\">edit <ID></a>";
	$idStr .= "<br><a href=\"javascript: if(confirm('Permanently delete this item?')){ "
		       ." self.location='".$selfUrl."?table=".$table."&deleteId=<ID>'; }\">delete <ID></a>";*/
  if($table=="sessions" || $table=="scans"){
    // Display combo box with list of existing studies
	$q = "SELECT studyCode FROM studies";
    if (!$res = mysql_query($q, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db); exit;
    }else{
	  if(mysql_num_rows($res)>0){
	    
	  }
	}
  }else{
  
  }
  
  $idStr = "<a href=\"".$selfUrl."?table=".$table."&updateId=<ID>\">Edit</a>".
           "<br><br><a href=\"javascript: if(confirm('Permanently delete this item?')){ ".
		   " self.location='".$selfUrl."?table=".$table."&deleteId=<ID>'; }\">Delete</a>";
}else{
  $idStr = "";
}
$tableText = displayTable($db, $table, $idStr);
if($tableText!=""){
  echo $tableText;
} else {
  echo "<p class=error>No entries found.</p>\n";
}
writeFooter('basic');
?>
