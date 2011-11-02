<?php
/*
 * buildSession2.php
 *
 * Builds various HTML forms to process a typical scan session.
 * 
 * HISTORY:
 *  041404 Based on buildSession1.php. Display wizard steps on top. Selecting existing session becomes a link only. AJM (antoine@psych.stanford.edu))
 *  2003.05.01 RFD (bob@white.stanford.edu) wrote it.
 */

require_once("include.php");
$db = login();

if(isset($_REQUEST["studyId"])){
  $studyId = $_REQUEST["studyId"];
}
else{
  echo "<p class=error>Error: Can't get the study id.</p>\n";
  exit;
}
$selfUrl = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"]."?studyId=".$studyId;
$returnURL = $selfUrl;
$msg = "";

if(isset($_REQUEST["d"])) $d = $_REQUEST["d"];
if(isset($_REQUEST["prevTable"])) $prevTable = $_REQUEST["prevTable"];
if(isset($_REQUEST["deleteId"])) $deleteId = $_REQUEST["deleteId"];
else $deleteId = 0;
$extras = array();
if(isset($_REQUEST["returnURL"])) $extras["returnURL"] = $_REQUEST["returnURL"];
//if(isset($_REQUEST["returnIdName"])) $extras["returnIdName"] = $_REQUEST["returnIdName"];
$extras["returnIdName"] = "sessionId";
$sessionIdSet = false;
if(isset($_REQUEST["defaultDataId"])) $defaultDataId = $_REQUEST["defaultDataId"];
else $defaultDataId = 0;
if(isset($_REQUEST["msg"])) $msg = $_REQUEST["msg"];
else $msg = "";
if(isset($_REQUEST["table"]))
  $table = $_REQUEST["table"];
else {
  $table = "sessions";
  $d[$table]['primaryStudyID'] = $studyId;
  $q = "SELECT id FROM ".$table." WHERE primaryStudyID=".$studyId." ORDER BY start DESC";
  if (!$res = mysql_query($q, $db)){
    print "\n<p>mrData ERROR: ".mysql_error($db);
    exit;
  }
  else{
    $defaultDataIdArray = mysql_fetch_row($res);
    $defaultDataId = $defaultDataIdArray[0];
    if($defaultDataId=="")
      $defaultDataId = 0;
  //  echo "defaultdataid=".$defaultDataId;
  }
}
if(isset($prevTable) && is_array($prevTable)) $numPendingTables = count($prevTable);
else $numPendingTables = 0;
//echo "ext(returnURL)=".$extras["returnURL"];
//echo "ext(returnIdName)=".$extras["returnIdName"];
if(isset($_REQUEST[$table])){
  // PROCESS SUBMIT
  // If a submit button with a name matching our current table is set, then
  // we think the user wants to submit the data for this table.
  list($success, $msg, $id) = updateRecord($db, $table, $d[$table], $updateId);
  if($success){
    unset($d[$table]);
    if($numPendingTables>0){
      // pop one off the previous table stack.
      $table = array_pop($prevTable);
    }
/*	if(isset($extras["returnURL"]) && $numPendingTables==0){
      if (strpos(urldecode($extras["returnURL"]),'?')===FALSE) $urlChar = "?";
      else $urlChar = "&";
      if(isset($extras["returnIdName"]))
	    header("Location: ".$returnURL.$urlChar.$extras["returnIdName"]."=".$id);
      else
	    header("Location: ".$returnURL.$urlChar."id=".$id); 
      exit;
    }*/
    if(isset($extras["returnIdName"]) && $numPendingTables==0){
      /*if (strpos(urldecode($extras["returnURL"]),'?')===FALSE) $urlChar = "?";
      //else $urlChar = "&";
      //if(isset($extras["returnIdName"])){
	  //  echo "111";
	  //  header("Location: buildSession3.php".$urlChar.$extras["returnIdName"]."=".$id);
		//}
      else{
	    echo "222";
	    header("Location: buildSession3.php".$urlChar."id=".$id); 
	  }
	  echo "333";
      exit;*/
	  $sessionIdSet = true;
	  $sessionId = $id;
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

foreach($_REQUEST as $key=>$val){
  if($val=="New"){
    if(isset($prevTable) && is_array($prevTable))
      array_push($prevTable, $table);
    else
      $prevTable = array($table);
    $table = $key;
  }
}

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

if(isset($_REQUEST["updateId"]))
  $d[$table]['id'] = $_REQUEST["updateId"];
else 
  $d[$table]['id'] = 0;


if(isset($_REQUEST["sessionId"])){
  $sessionId = $_REQUEST["sessionId"];
  header("Location: buildSession3.php?studyId=".$studyId."&sessionId=".$sessionId);
}
if($sessionIdSet)
  header("Location: buildSession3.php?studyId=".$studyId."&sessionId=".$sessionId);

writeHeader("Building session- build new session", "secure", $msg);
wizardHeader(2);
$q = "SELECT title FROM studies WHERE id=".$studyId;
if (!$res = mysql_query($q, $db)){
  print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
}
$title = mysql_fetch_row($res);
echo "<p><font size=-.5><b><ul><li>Study:&nbsp;".$title[0]."</li></ul></b></font></p>";

$defaultDataId=0;

echo buildFormFromTable($db, $table, $prevTable, $selfUrl, $d, $extras, $defaultDataId);

echo "<br><p><font size=+1><a href=\"selectExistingSession.php?table=sessions&studyId=".$studyId."&returnURL=".urlencode($selfUrl);
echo "&returnIdName=sessionId\">Select existing session</a></font></p>\n";
//echo "&nbsp;&nbsp; or add a new session:\n</font></p>";

writeFooter('basic');

?>
