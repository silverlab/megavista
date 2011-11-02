<?php
/*
 * buildSession1.php
 *
 * Builds various HTML forms to process a typical scan session.
 * 
 * HISTORY:
 *  042304 Based on buildSession.php. Display wizard steps on top. Add new study becomes a link only. AJM (antoine@psych.stanford.edu))
 *  2003.05.01 RFD (bob@white.stanford.edu) wrote it.
 */

require_once("include.php");
$db = login();

if(isset($_REQUEST["studyId"])){
  $studyId = $_REQUEST["studyId"];
  header("Location: buildSession2.php?studyId=".$studyId);
}

if (isset($_REQUEST["sortBy"]))
  $sortBy = $_REQUEST["sortBy"];
else
  $sortBy = "";

if (isset($_REQUEST["sortDir"]))
  $sortDir = $_REQUEST["sortDir"];
else
  $sortDir = "ASC";

$selfUrl = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];
$msg = "";
writeHeader("Building session- select study", "secure", $msg);
wizardHeader(1);
echo "<p><font size=+1><a href=\"buildNewStudy.php?table=studies&returnURL=".urlencode($selfUrl)."&returnIdName=studyId\">Add new study</a>\n";
echo "&nbsp;&nbsp; or select an existing study:\n</font></p>";

$table = 'studies';
$idStr = '<a href="buildSession2.php?studyId=<ID>"><ID></a>';
$sortbyStr = '<a href="'.selfURL().'?sortDir=<DIR2>&sortBy=<ID>"><ID2><DIR></a>';
if($sortBy=="")
  // Default sort
  $sortBy='id';
$displaySummary = 1;
$tableText = displayTable($db, $table, $idStr, "", 0, $displaySummary, "", $studyId, $subjectId, $sessionId, $sortbyStr, $sortBy, $sortDir, "builder");
if($tableText!=""){
  echo $tableText;
}else{
  echo "<p class=error>No entries found.</p>\n";
}
echo "<p><font size=+1><a href=index.php>Back to home page</font></a></p>\n";

writeFooter('basic');

?>
