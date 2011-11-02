<?php 
/*
 * advancedsearchMrData.php
 *
 * Builds an html form to run advanced searches on MrData database.
 *
 * HISTORY:
 *  020404 Divided searchMrData.php into generalsearchMrData.php and advancedsearchMrData.php. AJM (antoine@psych.stanford.edu)
 *  120103 Finished second draft where table and field can be specified. AJM (antoine@psych.stanford.edu)
 *  111303 Wrote first draft: general search on test table using full text (mysql indexing feature) search. AJM (antoine@psych.stanford.edu)
 *  121003 General search on all tables and all fields. AJM (antoine@psych.stanford.edu)
 *  121103 Specialized search. AJM (antoine@psych.stanford.edu)
 */

require_once("include.php");

$db = login();
$msg = "Connected as user ".$_SESSION['username'];

$selfURL = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];

if (isset($_REQUEST["ss1"]))
  $specialSearch1 = $_REQUEST["ss1"];

if (isset($_REQUEST["ss2"]))
  $specialSearch2 = $_REQUEST["ss2"];

//if (isset($_REQUEST["ss3"]))
//  $specialSearch3 = $_REQUEST["ss3"];

if (isset($_REQUEST["displaySummary"]))
  $displaySummary = $_REQUEST["displaySummary"];
else
  $displaySummary = 1;

if (isset($_REQUEST["sortBy"]))
  $sortBy = $_REQUEST["sortBy"];
else
  $sortBy = "";

if (isset($_REQUEST["sortDir"]))
  $sortDir = $_REQUEST["sortDir"];
else
  $sortDir = "ASC";

if (isset($_REQUEST["subjectName"]))
  $subjectName = $_REQUEST["subjectName"];
else
  $subjectName = "";

if (isset($_REQUEST["ageRangeLow"]))
  $ageRangeLow = $_REQUEST["ageRangeLow"];
else
  $ageRangeLow = "";

if (isset($_REQUEST["ageRangeHigh"]))
  $ageRangeHigh = $_REQUEST["ageRangeHigh"];
else
  $ageRangeHigh = "";

if (isset($_REQUEST["subjectNotes"]))
  $subjectNotes = $_REQUEST["subjectNotes"];
else
  $subjectNotes = "";

if (isset($_REQUEST["dateAfterMo"]))
  $dateAfterMo = $_REQUEST["dateAfterMo"];
else
  $dateAfterMo = "";

if (isset($_REQUEST["dateAfterDd"]))
  $dateAfterDd = $_REQUEST["dateAfterDd"];
else
  $dateAfterDd = "";

if (isset($_REQUEST["dateAfterYr"]))
  $dateAfterYr = $_REQUEST["dateAfterYr"];
else
  $dateAfterYr = "";

if (isset($_REQUEST["dateBeforeMo"]))
  $dateBeforeMo = $_REQUEST["dateBeforeMo"];
else
  $dateBeforeMo = "";

if (isset($_REQUEST["dateBeforeDd"]))
  $dateBeforeDd = $_REQUEST["dateBeforeDd"];
else
  $dateBeforeDd = "";

if (isset($_REQUEST["dateBeforeYr"]))
  $dateBeforeYr = $_REQUEST["dateBeforeYr"];
else
  $dateBeforeYr = "";

if (isset($_REQUEST["sessionNotes"]))
  $sessionNotes = $_REQUEST["sessionNotes"];
else
  $sessionNotes = "";

if (isset($_REQUEST["scanType"]))
  $scanType = $_REQUEST["scanType"];
else
  $scanType = "";

if (isset($_REQUEST["scanNotes"]))
  $scanNotes = $_REQUEST["scanNotes"];
else
  $scanNotes = "";


writeHeader("Search tool", "secure", $msg);
echo "<h1>Search tool:</h1>\n";

$fullTextString = array('subjects'=>'(firstName, lastName, address, email, notes)',
                        'scans'=>'(scanCode, notes, scanParams)',
						'sessions'=>'(sessionCode, readme, notes, dataSubDirectory)',
						'studies'=>'(studyCode, title, purpose, notes, dataDirectory)',
						'analyses'=>'(notes, summaryResult)',
						'dataFiles'=>'(path, backupLocation)',
						'displayCalibration'=>'(computer, videoCard, notes)',
						'displays'=>'(location, description)',
						'grants'=>'(agency, lucasCode, notes)',
						'protocols'=>'(sedesc, protocolName, coil, iopt, psdname, te, spc, saturation, contrast, contam)',
						'rois'=>'(ROIname)',
						'stimuli'=>'(name, description, code)',
						'subjectTypes'=>'(name, description)',
						'users'=>'(firstName, lastName, organization, email, username, notes)');

?>
<form method=get action="<?=$selfURL?>">
<p>
<ul><li><h2>Advanced search</h2></li>
<ul><li><h3>Session search</h3></li>
<ul><li><h4>Subject:</h4></li><ul><li><b>name</b>
<input type="text" name="subjectName" value="<?=$subjectName?>" size=16>
&nbsp&nbsp
<b>age range</b>
<input type="text" name="ageRangeLow" value="<?=$ageRangeLow?>" size=2>
<b>-</b>
<input type="text" name="ageRangeHigh" value="<?=$ageRangeHigh?>" size=2>
&nbsp&nbsp
<b>notes</b>
<input type="text" name="subjectNotes" value="<?=$subjectNotes?>" size=16>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
<input type=submit name=specialSearch1 value=search>
</li></ul></ul>
<br>
<ul><li><h4>Session/Scan:</h4></li>
<ul><li><p><b>after</b>
<input type="text" name="dateAfterMo" value="<?=$dateAfterMo?>" size=2>-
<input type="text" name="dateAfterDd" value="<?=$dateAfterDd?>" size=2>-
<input type="text" name="dateAfterYr" value="<?=$dateAfterYr?>" size=4>
&nbsp&nbsp
<b>before</b>
<input type="text" name="dateBeforeMo" value="<?=$dateBeforeMo?>" size=2>-
<input type="text" name="dateBeforeDd" value="<?=$dateBeforeDd?>" size=2>-
<input type="text" name="dateBeforeYr" value="<?=$dateBeforeYr?>" size=4>
&nbsp&nbsp&nbsp
<b>Format is month-day-year</b></p>
<p><b>session notes</b>
<input type="text" name="sessionNotes" value="<?=$sessionNotes?>" size=30>
</p>
</li></ul>
<ul><li><b>scan type</b>
<input type="text" name="scanType" value="<?=$scanType?>" size=16>
&nbsp&nbsp
<b>scan notes</b>
<input type="text" name="scanNotes" value="<?=$scanNotes?>" size=16>
&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
<input type=submit name=specialSearch2 value=search>
</li></ul></ul></ul></ul>
</p>
</form>
<a href="generalsearchMrData.php">General search</a>
<hr>

<?php
if(!isset($int_cur_position))
  $int_cur_position = 0;
$numPerPage = 10;

if($specialSearch1){
  $subjectNotes = strtolower(trim($subjectNotes));
  $ageRangeHigh = trim($ageRangeHigh);
  $ageRangeLow = trim($ageRangeLow);
  $q2 = "SELECT subjects.*, sessions.* FROM subjects, sessions WHERE sessions.subjectID = subjects.id ";
  if($subjectName != ""){
    $subjectName = strtolower(trim($subjectName));
	$subjectName = str_replace('*', '%', $subjectName);
	$q2 .= "AND (subjects.lastName LIKE ('%$subjectName%') OR subjects.firstName LIKE ('%$subjectName%')) ";
  }
  if(is_numeric($ageRangeLow)){
    $q2 .= "AND (DATE_ADD(subjects.dob, INTERVAL ".$ageRangeLow." YEAR) <= sessions.start) ";
  }
  if(is_numeric($ageRangeHigh)){
    $q2 .= "AND (DATE_ADD(subjects.dob, INTERVAL ".$ageRangeHigh." YEAR) >= sessions.start) ";
  }
  if($subjectNotes != ""){
	$subjectNotes = str_replace('*', '%', $subjectNotes);
	$q2 .= "AND (subjects.notes LIKE ('%$subjectNotes%')) ";
  }
  $sbjArray = array('lastName', 'firstName', 'dob');
  if($sortBy=="")
    $sortBy = "lastName";
  if(in_array($sortBy, $sbjArray))
    $sortByOrder = "subjects.".$sortBy;
  else
    $sortByOrder = "sessions.".$sortBy;	
  $q2 .= "ORDER by ".$sortByOrder." ".$sortDir;
  if(!$res = mysql_query($q2, $db)){
    print "\n<p>ERROR ".mysql_error($db);
	exit;
  }
  $totalNumRows = mysql_num_rows($res);
  $displaySummaryStr = '<a href="'.selfURL().'?displaySummary=<DS>&sortDir='.$sortDir.'&sortBy='.$sortBy.
    '&subjectName='.$subjectName.'&ageRangeLow='.$ageRangeLow.'&ageRangeHigh='.$ageRangeHigh.'&subjectNotes='.$subjectNotes.
	'&ss1=1'.'">Click here to see a <DSS> version</a>';
  $sortbyStr = '<a href="'.selfURL().'?displaySummary='.$displaySummary.'&sortDir=<DIR2>&sortBy=<ID>&subjectName='.$subjectName.
    '&ageRangeLow='.$ageRangeLow.'&ageRangeHigh='.$ageRangeHigh.'&subjectNotes='.$subjectNotes.'&ss1=1'.'"><ID2><DIR></a>';
  if($sortBy=="")
    $sortBy = "lastName";
  $tbl = 'subjects';
  $tbl2 = 'sessions';
  if($totalNumRows > 0){
    displaySearchResult2($db, $tbl, $tbl2, $res, $int_cur_position, $displaySummaryStr, $displaySummary, $sortbyStr, $sortBy, $sortDir);
  } else {
    echo "<center><h2>No result found. Try again.</h2></center>\n";
  }
}

if($specialSearch2){
  $sessionNotes = strtolower(trim($sessionNotes));
  $dateAfterMo = trim($dateAfterMo);
  $dateAfterDd = trim($dateAfterDd);
  $dateAfterYr = trim($dateAfterYr);
  $dateBeforeMo = trim($dateBeforeMo);
  $dateBeforeDd = trim($dateBeforeDd);
  $dateBeforeYr = trim($dateBeforeYr);
  $dateAfterSet = 0;
  $dateBeforeSet = 0;
  $scanType = strtolower(trim($scanType));
  $scanNotes = strtolower(trim($scanNotes));
  $q2 = "SELECT sessions.*, scans.* FROM sessions, scans WHERE scans.sessionID = sessions.id ";
  if(is_numeric($dateAfterMo) && is_numeric($dateAfterDd) && is_numeric($dateAfterYr)){
    $timeAfter = mktime(0, 0, 0, $dateAfterMo, $dateAfterDd, $dateAfterYr);
	$dateAfter = date("Y-m-d",$timeAfter);
	$q2 .= "AND ('".$dateAfter."' <= sessions.start) ";
  }
  if(is_numeric($dateBeforeMo) && is_numeric($dateBeforeDd) && is_numeric($dateBeforeYr)){
    $timeBefore = mktime(0, 0, 0, $dateBeforeMo, $dateBeforeDd, $dateBeforeYr);
	$dateBefore = date("Y-m-d",$timeBefore);
	$q2 .= "AND ('".$dateBefore."' >= sessions.end) ";
  }
  if($sessionNotes != ""){
	$sessionNotes = str_replace('*', '%', $sessionNotes);
	$q2 .= "AND (sessions.notes LIKE ('%$sessionNotes%')) ";
  }
  if($scanType != ""){
	$scanType = str_replace('*', '%', $scanType);
	$q2 .= "AND (scans.scanType LIKE ('%$scanType%')) ";
  }
  if($scanNotes != ""){
	$scanNotes = str_replace('*', '%', $scanNotes);
	$q2 .= "AND (scans.notes LIKE ('%$scanNotes%')) ";
  }
  $scanArray = array('scanCode', 'notes', 'scanParams');
  if($sortBy=="")
    $sortBy = "start";
  if(in_array($sortBy, $scanArray))
    $sortByOrder = "scans.".$sortBy;
  else
    $sortByOrder = "sessions.".$sortBy;
//  if($sortBy=="")
//    $sortBy = "start";
  $q2 .= "ORDER by ".$sortByOrder." ".$sortDir;
  if(!$res = mysql_query($q2, $db)){
    print "\n<p>ERROR ".mysql_error($db);
	exit;
  }
  $totalNumRows = mysql_num_rows($res);
  $displaySummaryStr = '<a href="'.selfURL().'?displaySummary=<DS>&sortDir='.$sortDir.'&sortBy='.$sortBy.
    '&dateAfterMo='.$dateAfterMo.'&dateAfterDd='.$dateAfterDd.'&dateAfterYr='.$dateAfterYr.
	'&dateBeforeMo='.$dateBeforeMo.'&dateBeforeDd='.$dateBeforeDd.'&dateBeforeYr='.$dateBeforeYr.'&sessionNotes='.$sessionNotes.
	'&scanType='.$scanType.'&scanNotes='.$scanNotes.'&ss2=1'.'">Click here to see a <DSS> version</a>';
  $sortbyStr = '<a href="'.selfURL().'?displaySummary='.$displaySummary.'&sortDir=<DIR2>&sortBy=<ID>&sessionNotes='.$sessionNotes.
    '&dateAfterMo='.$dateAfterMo.'&dateAfterDd='.$dateAfterDd.'&dateAfterYr='.$dateAfterYr.
	'&dateBeforeMo='.$dateBeforeMo.'&dateBeforeDd='.$dateBeforeDd.'&dateBeforeYr='.$dateBeforeYr.
	'&scanType='.$scanType.'&scanNotes='.$scanNotes.'&ss2=1'.'"><ID2><DIR></a>';
  $tbl = 'scans';
  $tbl2 = 'sessions';
  if($totalNumRows > 0){
    displaySearchResult2($db, $tbl, $tbl2, $res, $int_cur_position, $displaySummaryStr, $displaySummary, $sortbyStr, $sortBy, $sortDir);
  } else {
    echo "<center><h2>No result found. Try again.</h2></center>\n";
  }
}
/*
if($specialSearch3){
  $scanType = strtolower(trim($scanType));
  $scanNotes = strtolower(trim($scanNotes));
  $q2 = "SELECT sessions.*, scans.* FROM sessions, scans WHERE scans.sessionID = sessions.id ";
  if($scanType != ""){
	$scanType = str_replace('*', '%', $scanType);
	$q2 .= "AND (scans.scanType LIKE ('%$scanType%')) ";
  }
  if($scanNotes != ""){
	$scanNotes = str_replace('*', '%', $scanNotes);
	$q2 .= "AND (scans.notes LIKE ('%$scanNotes%')) ";
  }
  $scanArray = array('scanCode', 'notes', 'scanParams');
  if($sortBy=="")
    $sortBy = "start";
  if(in_array($sortBy, $scanArray))
    $sortByOrder = "scans.".$sortBy;
  else
    $sortByOrder = "sessions.".$sortBy;
  $q2 .= "ORDER by ".$sortByOrder." ".$sortDir;
  if(!$res = mysql_query($q2, $db)){
    print "\n<p>ERROR ".mysql_error($db);
	exit;
  }
  $totalNumRows = mysql_num_rows($res);
  $displaySummaryStr = '<a href="'.selfURL().'?displaySummary=<DS>&sortDir='.$sortDir.'&sortBy='.$sortBy.
    '&scanType='.$scanType.'&scanNotes='.$scanNotes.'&ss3=1'.'">Click here to see a <DSS> version</a>';
  $sortbyStr = '<a href="'.selfURL().'?displaySummary='.$displaySummary.'&sortDir=<DIR2>&sortBy=<ID>&scanType='.$scanType.
    '&scanNotes='.$scanNotes.'&ss3=1'.'"><ID2><DIR></a>';
//  if($sortBy=="")
//    $sortBy = "start";
  $tbl = 'scans';
  $tbl2 = 'sessions';
  if($totalNumRows > 0){
    displaySearchResult2($db, $tbl, $tbl2, $res, $int_cur_position, $displaySummaryStr, $displaySummary, $sortbyStr, $sortBy, $sortDir);
  } else {
    echo "<center><h2>No result found. Try again.</h2></center>\n";
  }
}
*/
writeFooter("basic");
?>
