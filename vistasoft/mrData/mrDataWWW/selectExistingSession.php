<?php
/*
 * selectExistingSession.php
 *
 * Builds various HTML forms to process a typical scan session.
 * 
 * HISTORY:
 *  041404 Display wizard steps on top. AJM (antoine@psych.stanford.edu))
 *  2003.05.01 RFD (bob@white.stanford.edu) wrote it.
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
writeHeader("Building session- build new session", "secure", $msg);
wizardHeader(2);
//echo "<p><font size=+1><a href=\"selectExistingSession.php?table=sessions&returnURL=".urlencode($selfUrl)."&returnIdName=sessionId\">Select existing session</a>\n";
//echo "&nbsp;&nbsp; or add a new session:\n</font></p>";

$idStr = '<a href="buildSession3.php?studyId='.$studyId.'&sessionId=<ID>"><ID></a>';
$sortbyStr = '<a href="'.selfURL().'?table='.$table.'&studyId='.$studyId.'&sortDir=<DIR2>&sortBy=<ID>"><ID><DIR></a>';
if($sortBy=="")
  // Default sort
  $sortBy='id';
$displaySummary = 1;
echo "<p><font size=+1><b>Select from the following existing sessions:</b></font></p>";
//tableText = displayTable($db, $table, $idStr, "WHERE primaryStudyID=".$studyId, 0, $displaySummary, "", $studyId, $subjectId, $sessionId, "", "", "", "");
$tableText = displayTable($db, $table, $idStr, "WHERE primaryStudyID=".$studyId, 0, $displaySummary, "", $studyId, 0, $sessionId, $sortbyStr, $sortBy, $sortDir, "");
if($tableText!=""){
  echo $tableText;
}else{
  echo "<p class=error>No entries found for studyid=".$studyId.".</p>\n";
  echo "<p><a href=buildSession2.php?studyId=".$studyId.">Back to previous page</a></p>\n";
}

//echo "<p><a href=\"editTable.php?table=studies&returnURL=".urlencode($selfUrl);
//echo "&returnIdName=studyId\">Select a study...</a>\n";
//echo "(Create a new one or select an existing study by clicking the id).</p>\n";

writeFooter('basic');

?>
