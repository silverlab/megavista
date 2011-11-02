<?php
/*
 * sessionBrowser.php
 *
 * Builds an html form to browse for sessions.
 *
 * HISTORY:
 *  100103 AJM (antoine@psych.stanford.edu).
 */
require_once("include.php");
init_session();
/*if(!isset($table) || $table==""){
 *trigger_error("'table' is not specified.");
 *exit;
 }*/

$msg = "Connected as user ".$_SERVER['PHP_AUTH_USER'];
$db = login();

$selfURL = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];

if (isset($_REQUEST["scanId"])){
  $scanId = $_REQUEST["scanId"];
  writeHeader("Display record", "secure", $msg);
  echo "<h1>Display record:</h1>\n";
}else{
  $scanId = 0;
  if(isset($_REQUEST["sessionId"])){
    $sessionId = $_REQUEST["sessionId"];
    writeHeader("Browse scan", "secure", $msg);
    echo "<h1>Browse scan:</h1>\n";
  }else{
    $sessionId = 0;
	writeHeader("Browse session", "secure", $msg);
    echo "<h1>Browse session:</h1>\n";
  }
}

/*if(isset($_REQUEST["sessionId"])){
  $sessionId = $_REQUEST["sessionId"];
}else{
  $sessionId = 0;
}*/

/*if($scanId>0){
  $table = 'scans';
  $idStr = '<a href="'.selfURL().'?sessionId='.$sessionId.'&scanId=<ID>"><ID></a>';
  $tableText = displayTable($db, $table, $idStr, "WHERE primarySessionID=".$studyId);
  if($tableText!=""){
    echo $tableText;
  } else {
    echo "<p class=error>No entries found.</p>\n";
  }
}else{
  $table = 'session';
  $idStr = '<a href="'.selfURL().'?sessionId=<ID>"><ID></a>';
  $tableText = displayTable($db, $table, $idStr);
  if($tableText!=""){
    echo $tableText;
  } else {
    echo "<p class=error>No entries found.</p>\n";
  }
}*/

/*if($sessionId>0){
  $table = 'scans';
  $idStr = '<a href="'.selfURL().'?sessionId='.$sessionId.'&scanId=<ID>"><ID></a>';
  $tableText = displayTable($db, $table, $idStr, "WHERE primarySessionID=".$studyId);
  if($tableText!=""){
    echo $tableText;
  } else {
    echo "<p class=error>No entries found.</p>\n";
  }
}else{
  $table = 'sessions';
  $idStr = '<a href="'.selfURL().'?sessionId=<ID>"><ID></a>';
  $tableText = displayTable($db, $table, $idStr);
  if($tableText!=""){
    echo $tableText;
  } else {
    echo "<p class=error>No entries found.</p>\n";
  }
}

echo '<p><a href="'.selfURL().'">Select new session</a>'."</p>\n";*/
if($scanId>0){
	$table = 'scans';
	$tableText = displayRecord($db, $table, "WHERE id=".$scanId);
	if($tableText!=""){
	  echo $tableText;
	}else{
	  echo "<p class=error>Entry not found.</p>\n";
	}
    echo '<p><a href="'.selfURL().'?sessionId='.$sessionId.'">Back to scan list</a>'."</p>\n";
}else{
  if($sessionId>0){
    $table = 'scans';
    $idStr = '<a href="'.selfURL().'?sessionId='.$sessionId.'&scanId=<ID>"><ID></a>';
    $tableText = displayTable($db, $table, $idStr, "WHERE sessionID=".$sessionId);
    if($tableText!=""){
      echo $tableText;
    }else{
      echo "<p class=error>No entries found.</p>\n";
    }
    echo '<p><a href="'.selfURL().'">Select new session</a>'."</p>\n";
  }else{
  	$table = 'sessions';
	$idStr = '<a href="'.selfURL().'?sessionId=<ID>"><ID></a>';
	$tableText = displayTable($db, $table, $idStr);
    if($tableText!=""){
      echo $tableText;
    }else{
      echo "<p class=error>No entries found.</p>\n";
    }
  }
}
writeFooter('basic');
?>