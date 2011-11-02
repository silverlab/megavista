<?php
/*
 * cloneExistingScan.php
 *
 * Builds various HTML forms to process a typical scan session.
 * 
 * HISTORY:
 *  042204 Display wizard steps on top. AJM (antoine@psych.stanford.edu))
 */

require_once("include.php");
if(isset($_REQUEST["table"])){
  $table = $_REQUEST["table"];
}
else{
  echo "<p class=error>Error: Can't get the table.</p>\n";
  exit;
}
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

if (isset($_REQUEST["sortBy"]))
  $sortBy = $_REQUEST["sortBy"];
else
  $sortBy = "";

if (isset($_REQUEST["sortDir"]))
  $sortDir = $_REQUEST["sortDir"];
else
  $sortDir = "ASC";

$db = login();
$selfUrl = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];
$msg = "";
writeHeader("Building scan- build new scan", "secure", $msg);
wizardHeader(3);
//echo "<p><font size=+1><a href=\"selectExistingSession.php?table=sessions&returnURL=".urlencode($selfUrl)."&returnIdName=sessionId\">Select existing session</a>\n";
//echo "&nbsp;&nbsp; or add a new session:\n</font></p>";

$idStr = '<a href="buildSession3.php?studyId='.$studyId.'&sessionId='.$sessionId.'&scanId=<ID>"><ID></a>';
$sortbyStr = '<a href="'.selfURL().'?table='.$table.'&studyId='.$studyId.'&sessionId='.$sessionId.'&sortDir=<DIR2>&sortBy=<ID>"><ID><DIR></a>';
if($sortBy=="")
  // Default sort
  $sortBy='id';
$displaySummary = 1;
echo "<p><font size=+1><b>Select from the following existing scans:</b></font></p>";
//tableText = displayTable($db, $table, $idStr, "WHERE primaryStudyID=".$studyId, 0, $displaySummary, "", $studyId, $subjectId, $sessionId, "", "", "", "");
$tableText = displayTable($db, $table, $idStr, "WHERE sessionID=".$sessionId." AND primaryStudyID=".$studyId, 0, $displaySummary, "", $studyId,
  0, $sessionId, $sortbyStr, $sortBy, $sortDir, "");
if($tableText!=""){
  echo $tableText;
}else{
  echo "<p class=error>No entries found for sessionid=".$sessionId.".</p>\n";
}

//echo "<p><a href=\"editTable.php?table=studies&returnURL=".urlencode($selfUrl);
//echo "&returnIdName=studyId\">Select a study...</a>\n";
//echo "(Create a new one or select an existing study by clicking the id).</p>\n";

writeFooter('basic');

?>
