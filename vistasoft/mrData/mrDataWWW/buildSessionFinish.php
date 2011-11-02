<?php
/*
 * buildSessionFinish.php
 *
 * Recapitulates the end of the session wizard.
 * 
 * HISTORY:
 *  042204 At the end of the wizard, before going back to index page. AJM (antoine@psych.stanford.edu))
 * At the end of the page, list all the scans in the current session
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
if(isset($_REQUEST["sessionId"])){
  $sessionId = $_REQUEST["sessionId"];
}
else{
  echo "<p class=error>Error: Can't get the session id.</p>\n";
  exit;
}
if(isset($_REQUEST["scanId"])){
  $scanId = $_REQUEST["scanId"];
}
else{
  echo "<p class=error>Error: Can't get the scan id.</p>\n";
  exit;
}

$selfUrl = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];
$msg = "";
writeHeader("Building session- Process finished", "secure", $msg);

$q = "SELECT subjectID FROM sessions WHERE id=".$sessionId;
if (!$res = mysql_query($q, $db)){
  print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
}
$getrow = mysql_fetch_row($res);
$subjectId = $getrow[0];

echo "<p><font size=+2>Congratulations! You have successfully added the following record(s):</font></p>\n";
echo "<p><b>Study:</b></p>";
$table = 'studies';
$displaySummary = 1;
$tableText = displayTable($db, $table, "", "WHERE id=".$studyId, 0, $displaySummary, "", $studyId, $subjectId, $sessionId, "", "", "", "");
if($tableText!=""){
  echo $tableText;
}else{
  echo "<p class=error>No entries found.</p>\n";
}
echo "<p><b>Session:</b></p>";
$table = 'sessions';
$displaySummary = 1;
$tableText = displayTable($db, $table, "", "WHERE id=".$sessionId, 0, $displaySummary, "", $studyId, $subjectId, $sessionId, "", "", "", "");
if($tableText!=""){
  echo $tableText;
}else{
  echo "<p class=error>No entries found.</p>\n";
}
echo "<p><b>Scan:</b></p>";
$table = 'scans';
$displaySummary = 1;
$tableText = displayTable($db, $table, "", "WHERE id=".$scanId, 0, $displaySummary, "", $studyId, $subjectId, $sessionId, "", "", "", "");
if($tableText!=""){
  echo $tableText;
}else{
  echo "<p class=error>No entries found.</p>\n";
}
//echo "<p><a href=\"editTable.php?table=studies&returnURL=".urlencode($selfUrl);
//echo "&returnIdName=studyId\">Select a study...</a>\n";
//echo "(Create a new one or select an existing study by clicking the id).</p>\n";
echo "<p><font size=+1><a href=buildSession3.php?studyId=".$studyId."&sessionId=".$sessionId.">Add another scan</a></font>";
echo "&nbsp;&nbsp;or&nbsp;&nbsp;";
echo "<font size=+1><a href=index.php>go back to home page</a></font></p>\n";

echo "<hr>\n";
echo "<p><font size=+1>Scans entered in this session so far...";
$tableText = displayTable($db, $table, $idStr, "WHERE sessionID=".$sessionId." AND primaryStudyID=".$studyId, 0, $displaySummary, "", $studyId,
  0, $sessionId, $sortbyStr, $sortBy, $sortDir, "");
if($tableText!=""){
  echo $tableText;
}else{
  echo "<p class=error>No entries found for sessionid=".$sessionId.".</p>\n";
}
writeFooter('basic');


/*  // OK- if we get here then the sessionId is NOT set, but the studyId IS set.
  $res = mysql_query("SELECT * FROM studies WHERE id=".$studyId, $db)
    or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
  $study = mysql_fetch_array($res);
  $studyName = $study["studyCode"]." (".$studyId.")";
  $sessionCode = $study["studyCode"].date("ymd");
  $msg = "Using study '$studyName'";
  writeHeader("Building session", "secure", $msg);
	echo "<p><strong>Study: $studyName</strong></p>\n";
  echo "<p><a href=\"editTable.php?table=sessions&returnURL=".urlencode($selfUrl);
  echo "&returnIdName=sessionId&d[sessions][sessionCode]=$sessionCode";
  echo "&d[sessions][primaryStudyID]=$studyId";
  echo "&d[sessions][whoReserved]=".$study['contactID'];
  echo "&d[sessions][operatorID]=".$study['contactID']."\">";
  echo "Select a session...</a>\n";
  echo "(Create a new one or select an existing session by clicking the id).</p>\n";
  writeFooter('basic');
  exit;
}
/*
$res = mysql_query("SELECT * FROM sessions WHERE id=".$sessionId, $db)
     or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
$session = mysql_fetch_array($res);
$sessionName = $session[1]." (".$sessionId.")";
$res = mysql_query("SELECT COUNT(*) FROM scans WHERE sessionID=".$sessionId, $db)
     or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
$row = mysql_fetch_row($res);
$numScans = $row[0];
$sessionCode = $session["sessionCode"];
$newScanCode = $sessionCode.sprintf('-%02d',$numScans+1);
$msg = "Building session '$sessionName'";

// *** fill in more default values, like scanCode, which is built from the 
// sessionCode and the scan number.
$addScanUrl = "editTable.php?table=scans&returnURL=".urlencode($selfUrl."?sessionId=$sessionId")
              ."&d[scans][sessionID]=$sessionId&d[scans][primaryStudyID]=".$session["primaryStudyID"]
              ."&d[scans][scanCode]=$newScanCode";

writeHeader("Building session $sessionName ", "secure", $msg);
?>
<h1 align=center>Building session <?=$sessionName?> (<?=$sessionCode?>)</h1>
<a href="<?=$addScanUrl?>">Add a scan...</a>
<h2><?=$numScans?> scans in session <?=$sessionName?>:</h2>
<?
// *** Add a link that allows you to add data to the scan.
$idStr = "<a href=\"editTable.php?table=scans&d[scans][scanCode]=$newScanCode"
     ."&returnURL=".urlencode($selfUrl."?sessionId=$sessionId")
     ."&defaultDataId=<ID>\">clone</a> <a href=\"addScanData.php?"
		 ."sessionId=$sessionId&scanId=<ID>&examNumber=".$session['examNumber']
     ."&scanner=".urlencode($session['scanner'])."\">data</a> <a href=\"editTable.php?table=scans&updateId=<ID>"
     ."&returnURL=".urlencode($selfUrl."?sessionId=$sessionId")
     ."\">edit</a>";
     
echo displayTable($db, "scans", $idStr, "WHERE sessionID=".$sessionId, 1);
writeFooter('basic');*/
?>
