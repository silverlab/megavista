<?php
/*
 * buildSession.php
 *
 *
 * Builds various HTML forms to process a typical scan session.
 * 
 *
 * TODO:
 * 
 * - Add session support and store d[...] in a session var. 
 *   This way, we can preserve the form state even when users
 *   click to create a new entry in a cross-linked table.
 * 
 *
 * HISTORY:
 *  2003.05.01 RFD (bob@white.stanford.edu) wrote it.
 */

require_once("include.php");
//init_session();
$db = login();
$selfUrl = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];
$msg = "";
if(isset($_REQUEST["sessionId"])) $sessionId = $_REQUEST["sessionId"];
if(isset($_REQUEST["studyId"])) $studyId = $_REQUEST["studyId"];

if(!isset($sessionId) || $sessionId==""){
  // If the sessionId isn't set, we get the user to create a new one or select an 
  // existing one.
  //
  // We always start with the study. This way, we can force the proper
  // creation of the sessionCode, which should be derived from the studyCode.
  if(!isset($studyId) || $studyId==""){
    writeHeader("Building session- select study", "secure", $msg);
    echo "<p><a href=\"editTable.php?table=studies&returnURL=".urlencode($selfUrl);
    echo "&returnIdName=studyId\">Select a study...</a>\n";
    echo "(Create a new one or select an existing study by clicking the id).</p>\n";
    writeFooter('basic');
    exit;
  }
  // OK- if we get here then the sessionId is NOT set, but the studyId IS set.
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
writeFooter('basic');
?>
