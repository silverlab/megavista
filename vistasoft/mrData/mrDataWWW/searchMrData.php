<?php 
/*
 * searchMrData.php
 *
 * Builds an html form to run general and refined searches on MrData database.
 *
 * HISTORY:
 *  120103 Finished second draft where table and field can be specified. AJM (antoine@psych.stanford.edu)
 *  111303 Wrote first draft: general search on test table using full text (mysql indexing feature) search. AJM (antoine@psych.stanford.edu)
 *  121003 General search on all tables and all fields. AJM (antoine@psych.stanford.edu)
 *  121103 Specialized search. AJM (antoine@psych.stanford.edu)
 */

require_once("include.php");

$db = login();
$msg = "Connected as user ".$_SESSION['username'];

if (isset($_REQUEST["tbl"]))
  $tbl = $_REQUEST["tbl"];
else
  $tbl = "studies";

if (isset($_REQUEST["fld"]))
  $fld = $_REQUEST["fld"];
else
  $fld = "all fields";

$selfURL = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];

writeHeader("Search tool", "secure", $msg);
echo "<h1>Search tool:</h1>\n";

/*
// Get searchable (i.e. text) fields in mrData db
$mrDataTables = array('people', 'scans', 'sessions', 'studies');
//$textTypes = array('');
$notgoodarray = array('species', 'scannerCertified', )
foreach ($mrDataTables as $value){
  $query = "SELECT * FROM $value";
  if(!$res = mysql_query($query, $db)){
    print "\n<p>ERROR ".mysql_error($db);
	exit;
  }
  $fullTextString = '';
  for($i = 0; $i < mysql_num_fields($res); $i++){
//    echo mysql_field_type($res, $i);
    if(mysql_field_type($res, $i)=='string' && mysql_field_name($res, $i)){
	  $fullTextString = $fullTextString.', '.mysql_field_name($res, $i);
	}
  }
  echo $fullTfextString;
}
*/
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
//$subjectsTblFldLst = array('firstName', 'lastName', 'address', 'email', 'notes');
//$scansTblFldLst = array('scanCode', 'notes', 'scanParams');
//$sessionsTblFldLst = array('sessionCode', 'readme', 'notes', 'dataSubDirectory');
//$studiesTblFldList = array('studyCode', 'title', 'purpose', 'notes', 'dataDirectory');

?>

<p>
<form method=get action="<?=$selfURL."?tableIndex=".$_GET['tbl']."&fieldIndex=".$_GET['fld']?>">
<ul><li><h2>General search</h2></li>
<ul><li><b>Look for</b>
<input type="text" name="keyword" value="<?=$keyword?>" size=16>

<script>
function fillfields(fldMenu, tblMenu){
  fieldList = new Array();
  fieldList['studies'] = new Array('studyCode', 'title', 'purpose', 'notes', 'dataDirectory');
  fieldList['sessions'] = new Array('sessionCode', 'readme', 'notes', 'dataSubDirectory');
  fieldList['scans'] = new Array('scanCode', 'notes', 'scanParams');
  fieldList['subjects'] = new Array('firstName', 'lastName', 'address', 'email', 'notes');
  fieldList['subjectTypes'] = new Array('name', 'description');
  fieldList['users'] = new Array('firstName', 'lastName', 'organization', 'email', 'username', 'notes');
  fieldList['analyses'] = new Array('notes', 'summaryResult');
  fieldList['dataFiles'] = new Array('path', 'backupLocation');
  fieldList['displayCalibration'] = new Array('computer', 'videoCard', 'notes');
  fieldList['displays'] = new Array('location', 'description');
  fieldList['grants'] = new Array('agency', 'lucasCode', 'notes');
  fieldList['protocols'] = new Array('sedesc', 'protocolName', 'coil', 'iopt', 'psdname', 'te', 'spc', 'saturation', 'contrast', 'contam');
  fieldList['rois'] = new Array('ROIname');
  fieldList['stimuli'] = new Array('name',' description', 'code');
  if(tblMenu.value!="all tables"){
    // Clear it out first
    for (i=0; i<10; i++)
	  fldMenu.options[i+1] = null;
    for (i=0; i<fieldList[tblMenu.value].length; i++)
      fldMenu.options[i+1] = new Option(fieldList[tblMenu.value][i],fieldList[tblMenu.value][i]);
  }
}
</script>

<b>in table</b>
<select name="tbl" value="<?=$tbl?>" onChange="fillfields(this.form.fld, this.form.tbl)">
<?
$selected = ($tbl=="studies") ? " selected" : "";
echo "<option value=\"studies\"".$selected.">studies</option>";
$selected = ($tbl=="sessions") ? " selected" : "";
echo "<option value=\"sessions\"".$selected.">sessions</option>";
$selected = ($tbl=="scans") ? " selected" : "";
echo "<option value=\"scans\"".$selected.">scans</option>";
$selected = ($tbl=="subjects") ? " selected" : "";
echo "<option value=\"subjects\"".$selected.">subjects</option>";
$selected = ($tbl=="subjectTypes") ? " selected" : "";
echo "<option value=\"subjectTypes\"".$selected.">subjectTypes</option>";
$selected = ($tbl=="users") ? " selected" : "";
echo "<option value=\"users\"".$selected.">users</option>";
$selected = ($tbl=="analyses") ? " selected" : "";
echo "<option value=\"analyses\"".$selected.">analyses</option>";
$selected = ($tbl=="dataFiles") ? " selected" : "";
echo "<option value=\"dataFiles\"".$selected.">dataFiles</option>";
$selected = ($tbl=="displayCalibration") ? " selected" : "";
echo "<option value=\"displayCalibration\"".$selected.">displayCalibration</option>";
$selected = ($tbl=="displays") ? " selected" : "";
echo "<option value=\"displays\"".$selected.">displays</option>";
$selected = ($tbl=="grants") ? " selected" : "";
echo "<option value=\"grants\"".$selected.">grants</option>";
$selected = ($tbl=="protocols") ? " selected" : "";
echo "<option value=\"protocols\"".$selected.">protocols</option>";
$selected = ($tbl=="rois") ? " selected" : "";
echo "<option value=\"rois\"".$selected.">rois</option>";
$selected = ($tbl=="stimuli") ? " selected" : "";
echo "<option value=\"stimuli\"".$selected.">stimuli</option>";
?>
</select>

<b>in field</b>
<select name="fld" value="<?=$fld?>">
<?
$selected = ($fld=="all fields") ? " selected" : "";
echo "<option value=\"all fields\"".$selected.">all fields</option>";
switch($tbl){
  case "studies":
    $selected = ($fld=="studyCode") ? " selected" : "";
    echo "<option value=\"studyCode\"".$selected.">studyCode</option>";
	$selected = ($fld=="title") ? " selected" : "";
	echo "<option value=\"title\"".$selected.">title</option>";
	$selected = ($fld=="purpose") ? " selected" : "";
	echo "<option value=\"purpose\"".$selected.">purpose</option>";
	$selected = ($fld=="notes") ? " selected" : "";
	echo "<option value=\"notes\"".$selected.">notes</option>";
	$selected = ($fld=="dataDirectory") ? " selected" : "";
	echo "<option value=\"dataDirectory\"".$selected.">dataDirectory</option>";
	break;
  case "sessions":
	$selected = ($fld=="sessionCode") ? " selected" : "";
    echo "<option value=\"sessionCode\"".$selected.">sessionCode</option>";
	$selected = ($fld=="readme") ? " selected" : "";
	echo "<option value=\"readme\"".$selected.">readme</option>";
	$selected = ($fld=="notes") ? " selected" : "";
	echo "<option value=\"notes\"".$selected.">notes</option>";
	$selected = ($fld=="dataSubDirectory") ? " selected" : "";
	echo "<option value=\"dataSubDirectory\"".$selected.">dataSubDirectory</option>";
	break;
  case "scans":
    $selected = ($fld=="scanCode") ? " selected" : "";
    echo "<option value=\"scanCode\"".$selected.">scanCode</option>";
    $selected = ($fld=="notes") ? " selected" : "";
	echo "<option value=\"notes\"".$selected.">notes</option>";
    $selected = ($fld=="scanParams") ? " selected" : "";
	echo "<option value=\"scanParams\"".$selected.">scanParams</option>";
	break;
  case "subjects":
	$selected = ($fld=="firstName") ? " selected" : "";
    echo "<option value=\"firstName\"".$selected.">firstName</option>";
	$selected = ($fld=="lastName") ? " selected" : "";
	echo "<option value=\"lastName\"".$selected.">lastName</option>";
	$selected = ($fld=="address") ? " selected" : "";
	echo "<option value=\"address\"".$selected.">address</option>";
	$selected = ($fld=="email") ? " selected" : "";
	echo "<option value=\"email\"".$selected.">email</option>";
	$selected = ($fld=="notes") ? " selected" : "";
	echo "<option value=\"notes\"".$selected.">notes</option>";
	break;
  case "subjectTypes":
	$selected = ($fld=="name") ? " selected" : "";
    echo "<option value=\"name\"".$selected.">name</option>";
	$selected = ($fld=="description") ? " selected" : "";
	echo "<option value=\"description\"".$selected.">description</option>";
	break;
  case "users":
	$selected = ($fld=="firstName") ? " selected" : "";
    echo "<option value=\"firstName\"".$selected.">firstName</option>";
	$selected = ($fld=="lastName") ? " selected" : "";
	echo "<option value=\"lastName\"".$selected.">lastName</option>";
	$selected = ($fld=="organization") ? " selected" : "";
	echo "<option value=\"organization\"".$selected.">organization</option>";
	$selected = ($fld=="email") ? " selected" : "";
	echo "<option value=\"email\"".$selected.">email</option>";
	$selected = ($fld=="username") ? " selected" : "";
	echo "<option value=\"username\"".$selected.">username</option>";
	$selected = ($fld=="notes") ? " selected" : "";
	echo "<option value=\"notes\"".$selected.">notes</option>";
	break;
  case "analyses":
	$selected = ($fld=="notes") ? " selected" : "";
    echo "<option value=\"notes\"".$selected.">notes</option>";
	$selected = ($fld=="summaryResult") ? " selected" : "";
	echo "<option value=\"summaryResult\"".$selected.">summaryResult</option>";
	break;
  case "dataFiles":
	$selected = ($fld=="path") ? " selected" : "";
    echo "<option value=\"path\"".$selected.">path</option>";
	$selected = ($fld=="backupLocation") ? " selected" : "";
	echo "<option value=\"backupLocation\"".$selected.">backupLocation</option>";
	break;
  case "displayCalibration":
	$selected = ($fld=="computer") ? " selected" : "";
    echo "<option value=\"computer\"".$selected.">computer</option>";
	$selected = ($fld=="videoCard") ? " selected" : "";
	echo "<option value=\"videoCard\"".$selected.">videoCard</option>";
	$selected = ($fld=="notes") ? " selected" : "";
	echo "<option value=\"notes\"".$selected.">notes</option>";
	break;
  case "displays":
	$selected = ($fld=="location") ? " selected" : "";
    echo "<option value=\"location\"".$selected.">location</option>";
	$selected = ($fld=="description") ? " selected" : "";
	echo "<option value=\"description\"".$selected.">description</option>";
	break;
  case "grants":
	$selected = ($fld=="agency") ? " selected" : "";
    echo "<option value=\"agency\"".$selected.">agency</option>";
	$selected = ($fld=="lucasCode") ? " selected" : "";
	echo "<option value=\"lucasCode\"".$selected.">lucasCode</option>";
	$selected = ($fld=="notes") ? " selected" : "";
	echo "<option value=\"notes\"".$selected.">notes</option>";
	break;
  case "protocols":
	$selected = ($fld=="sedesc") ? " selected" : "";
    echo "<option value=\"sedesc\"".$selected.">sedesc</option>";
	$selected = ($fld=="protocolName") ? " selected" : "";
	echo "<option value=\"protocolName\"".$selected.">protocolName</option>";
	$selected = ($fld=="coil") ? " selected" : "";
	echo "<option value=\"coil\"".$selected.">coil</option>";
	$selected = ($fld=="iopt") ? " selected" : "";
    echo "<option value=\"iopt\"".$selected.">iopt</option>";
	$selected = ($fld=="psdname") ? " selected" : "";
    echo "<option value=\"psdname\"".$selected.">psdname</option>";
	$selected = ($fld=="te") ? " selected" : "";
    echo "<option value=\"te\"".$selected.">te</option>";
	$selected = ($fld=="spc") ? " selected" : "";
    echo "<option value=\"spc\"".$selected.">spc</option>";
	$selected = ($fld=="saturation") ? " selected" : "";
    echo "<option value=\"saturation\"".$selected.">saturation</option>";
	$selected = ($fld=="contrast") ? " selected" : "";
    echo "<option value=\"contrast\"".$selected.">contrast</option>";
	$selected = ($fld=="contam") ? " selected" : "";
    echo "<option value=\"contam\"".$selected.">contam</option>";
	break;
  case "rois":
	$selected = ($fld=="ROIname") ? " selected" : "";
    echo "<option value=\"ROIname\"".$selected.">ROIname</option>";
	break;
  case "stimuli":
	$selected = ($fld=="name") ? " selected" : "";
    echo "<option value=\"name\"".$selected.">name</option>";
	$selected = ($fld=="description") ? " selected" : "";
	echo "<option value=\"description\"".$selected.">description</option>";
	$selected = ($fld=="code") ? " selected" : "";
	echo "<option value=\"code\"".$selected.">code</option>";
	break;
}
?>
</select>
<input type=submit name=generalSearch value=search>
</li></ul></ul>
</p>

<p>
<ul><li><h2>Advanced search</h2></li>
<?
if($advanced){
echo "zobi";
}
?>
<ul><li><h3>Session search</h3></li>
<ul><li><h4>Subject:</h4></li>
<ul><li><b>name</b>
<input type="text" name="subjectName" value="<?=$subjectName?>" size=16>
<b>age range</b>
<input type="text" name="ageRangeLow" value="<?=$ageRangeLow?>" size=2>
<b>-</b>
<input type="text" name="ageRangeHigh" value="<?=$ageRangeHigh?>" size=2>
<b>notes</b>
<input type="text" name="subjectNotes" value="<?=$subjectNotes?>" size=16>
<input type=submit name=specialSearch1 value=search>
</li></ul></ul>
<br>
<ul><li><h4>Session/Scan:</h4></li>
<ul><li><b>after</b>
<input type="text" name="dateAfter" value="<?=$dateAfter?>" size=5>
<b>before</b>
<input type="text" name="dateBefore" value="<?=$dateBefore?>" size=5>
<b>session notes:</b>
<input type="text" name="sessionNotes" value="<?=$sessionNotes?>" size=16>
<input type=submit name=specialSearch2 value=search>
</li></ul>
<ul><li><b>scan type</b>
<input type="text" name="scanType" value="<?=$scanType?>" size=16>
<b>scan notes</b>
<input type="text" name="scanNotes" value="<?=$scanNotes?>" size=16>
<input type=submit name=specialSearch3 value=search>
</li></ul></ul></ul></ul>
</form></p>
<hr>

<?php
if(!isset($int_cur_position))
  $int_cur_position = 0;
$numPerPage = 10;

if($generalSearch){
//  echo "generalSearch";
  $keyword = strtolower(trim($keyword));
// Can use IN BOOLEAN MODE only when we upgrade to mySQL 4.0.1 (done as of 12/03)
  if($fld == 'all fields'){
    $q1 = "SELECT * FROM $tbl WHERE MATCH $fullTextString[$tbl] AGAINST ('$keyword' IN BOOLEAN MODE) ORDER BY id";
  }else{
    //echo "*".$fld."*".$q. "*".$tbl."^";
	$keyword = str_replace('*', '%', $keyword);
    $q1 = "SELECT * FROM $tbl WHERE $fld LIKE ('%$keyword%') ORDER BY id";
  }
  if(!$res = mysql_query($q1, $db)){
    print "\n<p>ERROR ".mysql_error($db);
	exit;
  }
  $totalNumRows = mysql_num_rows($res);
/*  if($keywordClause==""){
    //$q = "SELECT count(products.id) FROM products,vendors"
    //   ." WHERE vendors.id=products.vendorID $gradeClause $priceClause";
    //if (!$res = mysql_query($q, $db)){
    //  print "\n<p>ERROR ".mysql_error($db); exit; 
    //}
    //$totalNumRows = mysql_result($res,0);
  }else{
    // I can't figure out how to make this work without returning the whole set of rows.
    $q = "SELECT count(productSearch.keyword) FROM products,vendors,productSearch"
       ." WHERE vendors.id=products.vendorID $gradeClause $priceClause"
       ." AND products.id=productSearch.qid $keywordClause"
       ." GROUP BY productSearch.qid";
    if (!$res = mysql_query($q, $db)){
      print "\n<p>ERROR ".mysql_error($db); exit; 
    }
    $totalNumRows = mysql_num_rows($res);
  }*/

//  echo "<!-- Last query: '$q' -->\n";

/*  if($keywordClause==""){
    $qs = "SELECT "
       ." concat('<a href=\"$dispFullURL?tbl=products&id=',products.id,'\">',products.name,'</a>')"
       ." as 'Product Name',"
       ." if(length(products.url)>0,"
       ." concat('<a href=\"',products.url,'\">go to web page</a>'),'(no URL on file)')"
       ." as 'Vendor URL', "
       ." concat(left(products.description,60),'...') as 'Description', "
       ." vendors.name as 'Vendor'"
       ." FROM products,vendors"
       ." WHERE vendors.id=products.vendorID $gradeClause $priceClause"
       ." ORDER BY products.id"
       ." LIMIT $int_cur_position, $numPerPage";
  }else{
    $qs = "SELECT count(productSearch.keyword) as relevance,"
       ." concat('<a href=\"$dispFullURL?tbl=products&id=',products.id,'\">',products.name,'</a>')"
       ." as 'Product Name',"
       ." if(length(products.url)>0,"
       ." concat('<a href=\"',products.url,'\">go to web page</a>'),'(no URL on file)')"
       ." as 'Vendor URL', "
       ." concat(left(products.description,60),'...') as 'Description', "
       ." vendors.name as 'Vendor'"
       ." FROM products,vendors,productSearch"
       ." WHERE vendors.id=products.vendorID $gradeClause $priceClause"
       ." AND products.id=productSearch.qid $keywordClause"
       ." GROUP BY productSearch.qid"
       ." ORDER BY relevance DESC"
       ." LIMIT $int_cur_position, $numPerPage";
  }
  if (!$res = mysql_query($qs, $db)){
    print "\n<p>ERROR ".mysql_error($db); exit; 
  }*/

  if($totalNumRows > 0){
    displaySearchResult($res, $int_cur_position);
  } else {
    echo "<center><h2>No result found. Try again.</h2></center>\n";
  }
/*  if($totalNumRows > $numPerPage){
    $p = new Paging($totalNumRows, $int_cur_position, $numPerPage, 
                    "#336699", "500", $str_ext_argv );
    echo "<p><center>";
    $p->printPaging();
    echo "</center></p>\n";
  }*/
}
if($specialSearch1){
  $subjectNotes = strtolower(trim($subjectNotes));
  $ageRangeHigh = trim($ageRangeHigh);
  $ageRangeLow = trim($ageRangeLow);
  $q2 = "SELECT subjects.lastName, subjects.firstName, subjects.dob, sessions.* FROM subjects, sessions WHERE sessions.subjectID = subjects.id ";
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
    $subjectNotes = strtolower(trim($subjectNotes));
	$subjectNotes = str_replace('*', '%', $subjectNotes);
	$q2 .= "AND (subjects.notes LIKE ('%$subjectNotes%')) ";
  }
  $q2 .= "ORDER by sessions.id";
  if(!$res = mysql_query($q2, $db)){
    print "\n<p>ERROR ".mysql_error($db);
	exit;
  }
  $totalNumRows = mysql_num_rows($res);
  if($totalNumRows > 0){
    displaySearchResult($res, $int_cur_position);
  } else {
    echo "<center><h2>No result found. Try again.</h2></center>\n";
  }
}

writeFooter("basic");
?>
