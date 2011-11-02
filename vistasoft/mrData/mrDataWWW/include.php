<?php
/*
 * include.php
 *
 * Contains functions used in other modules.
 *
 * HISTORY:
 *  021904 Copied displayTable to displayBrowseResult. Now displays subject and study browsers accordingly. AJM (antoine@psych.stanford.edu).
 *  102703 Added displayRecord based on displayTable. AJM (antoine@psych.stanford.edu).
 *  103003 Modified displayTable to allow summary or full display. AJM (antoine@psych.stanford.edu).
 */

require_once("conf.php");

function hostURL($protocol=""){
  if($protocol==""){
    if(isset($_SERVER["HTTPS"]))
      $protocol = "https";
    else
      $protocol = "http";
  }
   return($protocol."://".$_SERVER["HTTP_HOST"]);
}

function homeURL($protocol=""){
  //return(hostURL($protocol)."/mrdata");
  return("mrdata");
}

function selfURL($protocol=""){
  return(hostURL($protocol).$_SERVER["PHP_SELF"]);
}

function mediaURL(){
  return("images");
}

function init_session(){
  session_name($GLOBALS["conf"]->sessionName);
  session_start();
}

function destroy_session(){
  $_SESSION = array();
  session_destroy();
}

function login(){
  //
  // $db = login();
  // 
  // Tries to connect to database using session vars. 
  // Sends user to login script if the session has not been initialized
  // or if the current session values are not valid.
  //
  init_session();
  if(isset($_SESSION['dbname']) && isset($_SESSION['username']) && isset($_SESSION['password'])){
    list($db, $msg) = dbConnect($_SESSION['username'], $_SESSION['password'], 
				$_SESSION['dbname'], 'localhost');
    if(!$db){
      destroy_session();
      header("Location: login.php?continueURL=".urlencode(hostURL()."/".$_SERVER["REQUEST_URI"])
	     ."&msg=".urlencode($msg));
      exit;
    }else{
      return($db);
    }
  }else{
    destroy_session();
    header("Location: login.php?continueURL=".urlencode(hostURL()."/".$_SERVER["REQUEST_URI"]));
    exit;
  }
  if(!isset($_SESSION['username'])){
    // Session not started OK
    trigger_error("Session failed to initialize- problem with cookies?");
  	exit;
  }

//   $db = FALSE;
//   // Force basic auth
//   $realm = "mrData";
//   if (isset($_SERVER['PHP_AUTH_USER']) && isset($_SERVER['PHP_AUTH_PW']))
//     list($db,$msg) = dbConnect($_SERVER['PHP_AUTH_USER'], $_SERVER['PHP_AUTH_PW'], 'mrDataDB');
//   if (!isset($_SERVER['PHP_AUTH_USER']) || !isset($_SERVER['PHP_AUTH_PW']) || !$db){
//     header('WWW-Authenticate: Basic realm="'.$realm.'"');
//     header('HTTP/1.0 401 Unauthorized');
//     // We only get here if the user cancels the basic auth dialog.
//     echo 'Sorry- you must log in.';
//     exit;
//   } else {
//     //echo "<p>Hello {$_SERVER['PHP_AUTH_USER']}.</p>";
//     //echo "<p>You entered {$_SERVER['PHP_AUTH_PW']} as your password.</p>";
//   }
//   return($db);
}

function writeHeader($title='', $type='basic', $msg='', $js=''){
  // basic- for standard public pages
  // secure- forces SSL before continuing
  if($type=='secure' && !isset($_SERVER["HTTPS"])){
    header("Location: ".selfURL('https'));
    exit;
  }
  if($msg=='' && isset($_SESSION['dbname'])) 
    $msg = "Currently logged in to ".$_SESSION['dbname']." as user '".$_SESSION['username']."'.";
?>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>mrData: <?=$title?></title>
<style type="text/css" media=screen>
<!--
  TD   { font-family: Verdana,Arial; font-size: 10pt; }
  TH   { font-family: Verdana,Arial; font-size: 10pt; font-weight : bold}
  H1   { font-family: Verdana,Arial; font-size: 18pt; }
  H2   { font-family: Verdana,Arial; font-size: 14pt; }
  H3   { font-family: Verdana,Arial; font-size: 12pt; }
  p    { font-family: Times,Serif; font-size: 12pt; }
  ul    { font-family: Times,Serif; font-size: 12pt; }
  ol    { font-family: Times,Serif; font-size: 12pt; }
  p.foot { font-family: Verdana,Arial; font-size: 8pt; font-style: italic;
           text-align: center; color: #aaaaaa; 
           margin-left: 5%; margin-right: 5%; margin-top: 2em}
  p.error { font-family: Verdana,Arial; font-size: 14pt; font-weight: bold;
            color: red; }
  p.msg { font-family: Verdana,Arial; font-size: 12pt; color: red; }
  font.msg { font-family: Verdana,Arial; color: red; }
  a.foot:link    { color: #9999ff }
  a.foot:visited { color: #9999ff }
  a.foot:hover   { color: #0000ff }
  a.topNav:link    { color: #ffffff }
  a.topNav:visited { color: #ffffff }
  a.topNav:hover   { color: #ffffaa }
  td.topNav   { font-family: Verdana,Arial; font-size: 10pt; 
                color: #ffffff; font-weight : bold}
-->
</style>
<?php
    if($js != "") echo "<script language=JAVASCRIPT><!--\n".$js."// --></script>\n";
?>

</head>
<body bgcolor=#ffffff>
<table border=0 cellpadding=0 cellspacing=0 width=800>
<tr><td align=left><strong><a href="/mrdata/">mrData Home</a></strong>
    <?php if($msg!="") echo "&nbsp; &nbsp; Status: <font class=msg>$msg</font>\n"; ?>
</td></tr>
<tr><td><hr></td></tr>
<tr><td>
<?php
}

function writeFooter($type='basic', $extra=""){
   // currently, no support for different footer types
?>
</td></tr>
<tr><td>
<p class="foot">
Site manager: 
<a class=foot 
href="http://white.stanford.edu/">Stanford VISTA group</a>. 
Page last modified <?=date ("Y-M-d H:i T", getlastmod())?>.
<?=$extra?>
</p>
</td></tr></table>
</body></html>
<?php
}

function dbConnect($username, $password, $dbname, $dbhost='localhost'){
  $db = @mysql_pconnect($dbhost, $username, $password);
  if($db){
    if(!mysql_select_db($dbname, $db)){
      $msg = "MySQL- ".mysql_error($db);
      $db = FALSE;
    }
  }else{
    $msg = "database denied connection- invalid username/password?";
  }
  return(array($db,$msg));
}

function displaytable($db, $table, $idString="", $where="", $showRowNum=0, $displaySummary=0, $table2="",
  $studyId=0, $subjectId=0, $sessionId=0, $sortbyStr="", $sortBy="", $sortDir="", $browserType=""){
  //
  // Returns the table text in one big string. Display at your leisure.
  //
  // $db is the database link and $table is the name of the table to display.
  //
  // $where is a string that will get appended to the main SELECT query.
  // It will typically be something like "WHERE id=3 AND name='foo'".
  //
  // $idString is a little hack to make this function more flexible. 
  // Background: the first column of any of our substantive tables is the 
  // item id (the primary key). This function will replace every occurance 
  // of "<ID>" in $idStr with the first column of each row(typically the 
  // row id) and show the hacked $idStr instead of the raw value. 
  // 
  // For example, you could send in a link that will return the row id to 
  // a specified URL with something like:
  //
  //     $idString = <a href="someUrl?id=<ID>">use <ID></a> 
  //
  // Each occurance of <ID> will get replaced with the value of the first
  // column of for each row. 
  //
  // $table2: used to display join table search results
  // $studyId, $subjectId, $sessionId: used to retrieve names of study, subjects and sessions in browse mode
  // $sortXXX: used for the sorting feature in browse mode
  // $browserType: used to display study and subject browsing differently

//  echo '$db='.$db.' $table='.$table.' $idString='.$idString.'$where='.$where.' $showRowNum='.$showRowNum.'$displaySummary='.$displaySummary.
//    ' $table2='.$table2.' $studyId='.$studyId.' $subjectId='.$subjectId.' $sessionId='.$sessionId.' $sortbyStr='.$sortbyStr.
//	' $sortBy='.$sortBy.' $sortDir='.$sortDir;

  $htmlFilter = 0;
  if($displaySummary)
	$maxDataLength = 120;
  else
    $maxDataLength = 60;
  $template = getTemplate('default');

  // GET FOREIGN TABLE LINKS
  $res = mysql_query('SELECT * FROM xLinks WHERE fromTable="'.$table.'"', $db)
    or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
  while ($row = mysql_fetch_array($res)) {
    //$linkTables[$row['fromColumn']] = $row['toTable'];
    //$linkColumns[$row['fromColumn']] = $row['toColumn'];
    // Here we select all the relevant entries from the linked table.
    // It is much faster to get all of them at once here than it would be to run a
    // query for each iteration of the row loop belop.
    $q = "SELECT DISTINCT ".$row['toTable'].".* FROM $table,".$row['toTable']." WHERE "
         .$table.".".$row['fromColumn']."=".$row['toTable'].".".$row['toColumn'];
    $res2 = mysql_query($q, $db)
      or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
    while ($row2 = mysql_fetch_row($res2)){
      $links[$row['fromColumn']][$row2[0]] = $row2[1]." ".$row2[2]." (".$row2[0].")";
	  $str = "";
	  foreach($row2 as $num=>$val){
		$str = $str.$val."  ";
	  }
	  $linksFull[$row['fromColumn']][$row2[0]] = $str;
    }
  }
  
  // GET ALL ITEMS IN SPECIFIED TABLE(S)
  if($table=='sessions' && $table2=='subjects')
    if($sortBy=='subjectID')
	  $q = "SELECT DISTINCT $table.subjectID, $table2.* FROM $table, $table2 ".$where.
	    " AND $table2.id = $table.subjectID ORDER by $table.subjectID";
	else
	  $q = "SELECT DISTINCT $table.subjectID, $table2.* FROM $table, $table2 ".$where.
	    " AND $table2.id = $table.subjectID ORDER by $table2.".$sortBy." ".$sortDir;
  else
    if($table=='sessions' && $table2=='studies')
	  if($sortBy=='primaryStudyID')
	    $q = "SELECT DISTINCT $table.primaryStudyID, $table2.* FROM $table, $table2 ".$where.
	      " AND $table2.id = $table.primaryStudyID ORDER by $table.studyID";
	  else
	    $q = "SELECT DISTINCT $table.primaryStudyID, $table2.* FROM $table, $table2 ".$where.
	      " AND $table2.id = $table.primaryStudyID ORDER by $table2.".$sortBy." ".$sortDir;
	else
      if($sortBy!='' && $sortDir!=''){
	    $q = "SELECT * FROM $table ".$where." ORDER BY $table.".$sortBy." ".$sortDir;
	  }
	  else
        $q = "SELECT * FROM $table ".$where." ORDER BY id";
  if (!$res = mysql_query($q, $db)){
    print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
  }
  $totalNumRows = mysql_num_rows($res);
  if($totalNumRows<1)
    return("");
  // We retrieve the study title, subject name and session code to position the current display
  // in the database hierarchy
  if($table=='sessions' && $table2=='subjects'){
    $q2 = "SELECT title FROM studies WHERE id=".$studyId;
    if (!$res2 = mysql_query($q2, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db);
	  exit;
	}
    $studytitle = mysql_fetch_row($res2);
    $tableText = "<p><ul><li>Study: ".$studytitle[0]."</li></ul></p>";	
  } 
  if($table=='sessions' && $table2=='studies'){
    $q2 = "SELECT firstName, lastName FROM subjects WHERE id=".$subjectId;
    if (!$res2 = mysql_query($q2, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db);
	  exit;
	}
    $subjecttitle = mysql_fetch_row($res2);
    $tableText = "<p><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1]."</li></ul></p>";	
  }
  if($table=='sessions' && $table2==''){
    $q3 = "SELECT title FROM studies WHERE id=".$studyId;
	if (!$res3 = mysql_query($q3, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
    }
    $studytitle = mysql_fetch_row($res3);
	$q4 = "SELECT firstName, lastName FROM subjects WHERE id=".$subjectId;
    if (!$res4 = mysql_query($q4, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
    }
    $subjecttitle = mysql_fetch_row($res4);
    switch ($browserType){
	case 'study':
	  $tableText = "<p><ul><li>Study: ".$studytitle[0]."</li><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1]."</li></ul></ul></p>";
	  break;
	case 'subject':
	  $tableText = "<p><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1]."</li><ul><li>Study: ".$studytitle[0]."</li></ul></ul></p>";
	  break;
	}
  }
  if($table=='scans'){
	$q3 = "SELECT title FROM studies WHERE id=".$studyId;
	if (!$res3 = mysql_query($q3, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
    }
    $studytitle = mysql_fetch_row($res3);
	$q4 = "SELECT firstName, lastName FROM subjects WHERE id=".$subjectId;
    if (!$res4 = mysql_query($q4, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
    }
    $subjecttitle = mysql_fetch_row($res4);
	$q5 = "SELECT sessioncode FROM sessions WHERE id=".$sessionId;
    if (!$res5 = mysql_query($q5, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
    }
    $sessiontitle = mysql_fetch_row($res5);
	switch ($browserType){
	case 'study':
	  $tableText = "<p><ul><li>Study: ".$studytitle[0]."</li><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1].
	    "</li><ul><li>Session: ".$sessiontitle[0]."</li></ul></ul></ul></p>";
	  break;
	case 'subject':
	  $tableText = "<p><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1]."</li><ul><li>Study: ".$studytitle[0].
	    "</li><ul><li>Session: ".$sessiontitle[0]."</li></ul></ul></ul></p>";
	  break;
	}
  }  

  $tableText .= "<table border=1 cellpadding=4 cellspacing=2><tr bgcolor=$template->headerColor>\n";
  if($showRowNum)
    $tableText .= "<th>Row #</th>";
  // To display table summaries, we choose relevant fields.
  if($displaySummary){
    switch ($table){
	case 'subjects':
	  $SummaryArray = array('id', 'subjectID', 'firstName', 'lastName');
	  break;
	case 'studies':
	  $SummaryArray = array('id', 'title', 'purpose', 'startDate');
	  break;
	case 'sessions':
	  if($table2=='')
	    $SummaryArray = array('id', 'subjectID', 'notes');
	  else
	    if($table2=='subjects')
	      $SummaryArray = array('subjectID', 'firstName', 'lastName');
		else
		  if($table2=='studies')
		    $SummaryArray = array('primaryStudyID', 'title', 'purpose', 'dataDirectory');
	  break;
    case 'scans':
	  $SummaryArray = array('id', 'scanNumber', 'stimulusID', 'stimulusType', 'notes');
	  break;
	}  
  }
  // Actually extract the data from the query result
  $stop = mysql_num_fields($res);
  while ($field = mysql_fetch_field($res)){
    $fields[] = $field->name;
	if((!$displaySummary || ($displaySummary && in_array($field->name, $SummaryArray))) && ($field->name!='password'))
      if($sortbyStr!=""){
		$data = str_replace("<ID>", $field->name, $sortbyStr);
		$data = str_replace("<ID2>", translateField($db, $table, $field->name), $data);
		//$data = str_replace("<ID>", $field->name, $sortbyStr);
		if($sortBy==$field->name)
		  if($sortDir=="ASC"){
		    $data = str_replace("<DIR>", "<BR><img src=./media/downarrow.bmp>", $data);
			$data = str_replace("<DIR2>", "DESC", $data);
		  }
		  else{
		    $data = str_replace("<DIR>", "<BR><img src=./media/uparrow.bmp>", $data);
			$data = str_replace("<DIR2>", "ASC", $data);
		  }
		else{
		  $data = str_replace("<DIR>", "", $data);
		  $data = str_replace("<DIR2>", "ASC", $data);
		}
		$tableText .= "<th>".$data."</th>\n";
	  }
	  else
	    $tableText .= "<th>".$field->name."</th>\n";
  }
  $tableText .= "</tr>\n";
  $rowNum = 0;
  while ($row = mysql_fetch_row($res)){
    if($rowNum++%2) 
      $tableText .= "<tr bgcolor=$template->bgColor1>\n";
    else 
      $tableText .= "<tr bgcolor=$template->bgColor2>\n";
    if($showRowNum)
      $tableText .= "<td align=center>$rowNum</td>\n";
    foreach($row as $num=>$data){
      if($htmlFilter)
	    $data = htmlentities($data);
	  // Chop data if it is too long
	  if(strlen($data)>$maxDataLength)
		$data = substr($data, 0, $maxDataLength)."...";
	  // Special case: append studyCode to dataDirectory
	  if($fields[$num] == 'studyCode')
	    $studyCodeMem = $data;
      if($num==0 && $idString!="")
		$data = str_replace("<ID>", $data, $idString);
      // Check for a foreign table link. If we find one, then we insert the first
      // few fields from that table rather than the uninformative ID #.
      if(isset($links[$fields[$num]][$data])){
      	$data = $links[$fields[$num]][$data]
					      ." <a href=\"javascript:alert('".$linksFull[$fields[$num]][$data]."');\">...</a>";
      }
	  if((!$displaySummary || ($displaySummary && in_array($fields[$num], $SummaryArray))) && ($fields[$num]!='password')){
	    // Special case: append studyCode to dataDirectory
		if($fields[$num] == 'dataDirectory')
		  $data = $data.$studyCodeMem;
        if(mysql_field_type($res, $num)=='blob'){
          //echo "<td>[BLOB]</td>\n";
          $tableText .= "<td>".$data."&nbsp;</td>\n";
        }elseif(mysql_field_type($res, $num)=='string'){
          $tableText .= "<td align=left>".$data."&nbsp;</td>\n";
        }else{
		  $tableText .= "<td align=center>".$data."&nbsp;</td>\n";
	    }
	  }
    }
    $tableText .= "</tr>\n";
  }
  $tableText .= "</tr>\n</table>\n";
  return($tableText);
}

function displayBrowserResult($db, $table, $idString="", $where="", $showRowNum=0, $displaySummary=0, $table2="",
  $studyId=0, $subjectId=0, $sessionId=0, $sortbyStr="", $sortBy="", $sortDir="", $browserType=""){

  //
  // Returns the table text in one big string. Display at your leisure.
  //
  // $db is the database link and $table is the name of the table to display.
  //
  // $where is a string that will get appended to the main SELECT query.
  // It will typically be something like "WHERE id=3 AND name='foo'".
  //
  // $idString is a little hack to make this function more flexible. 
  // Background: the first column of any of our substantive tables is the 
  // item id (the primary key). This function will replace every occurance 
  // of "<ID>" in $idStr with the first column of each row(typically the 
  // row id) and show the hacked $idStr instead of the raw value. 
  // 
  // For example, you could send in a link that will return the row id to 
  // a specified URL with something like:
  //
  //     $idString = <a href="someUrl?id=<ID>">use <ID></a> 
  //
  // Each occurance of <ID> will get replaced with the value of the first
  // column of for each row. 
  //
  // $table2: used to display join table search results
  // $studyId, $subjectId, $sessionId: used to retrieve names of study, subjects and sessions in browse mode
  // $sortXXX: used for the sorting feature in browse mode
  // $browserType: used to display study and subject browsing differently

//  echo '$db='.$db.' $table='.$table.' $idString='.$idString.'$where='.$where.' $showRowNum='.$showRowNum.'$displaySummary='.$displaySummary.
//    ' $table2='.$table2.' $studyId='.$studyId.' $subjectId='.$subjectId.' $sessionId='.$sessionId.' $sortbyStr='.$sortbyStr.
//	' $sortBy='.$sortBy.' $sortDir='.$sortDir;

  $htmlFilter = 0;
  if($displaySummary)
	$maxDataLength = 120;
  else
    $maxDataLength = 60;
  $template = getTemplate('default');

  // GET FOREIGN TABLE LINKS
  $res = mysql_query('SELECT * FROM xLinks WHERE fromTable="'.$table.'"', $db)
    or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
  while ($row = mysql_fetch_array($res)) {
    //$linkTables[$row['fromColumn']] = $row['toTable'];
    //$linkColumns[$row['fromColumn']] = $row['toColumn'];
    // Here we select all the relevant entries from the linked table.
    // It is much faster to get all of them at once here than it would be to run a
    // query for each iteration of the row loop belop.
    $q = "SELECT DISTINCT ".$row['toTable'].".* FROM $table,".$row['toTable']." WHERE "
         .$table.".".$row['fromColumn']."=".$row['toTable'].".".$row['toColumn'];
    $res2 = mysql_query($q, $db)
      or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
    while ($row2 = mysql_fetch_row($res2)){
      $links[$row['fromColumn']][$row2[0]] = $row2[1]." ".$row2[2]." (".$row2[0].")";
	  $str = "";
	  foreach($row2 as $num=>$val){
		$str = $str.$val."  ";
	  }
	  $linksFull[$row['fromColumn']][$row2[0]] = $str;
    }
  }
  
  // GET ALL ITEMS IN SPECIFIED TABLE(S)
  if($table=='sessions' && $table2=='subjects')
    if($sortBy=='subjectID')
	  $q = "SELECT DISTINCT $table.subjectID, $table2.* FROM $table, $table2 ".$where.
	    " AND $table2.id = $table.subjectID ORDER by $table.subjectID";
	else
	  $q = "SELECT DISTINCT $table.subjectID, $table2.* FROM $table, $table2 ".$where.
	    " AND $table2.id = $table.subjectID ORDER by $table2.".$sortBy." ".$sortDir;
  else
    if($table=='sessions' && $table2=='studies')
	  if($sortBy=='primaryStudyID')
	    $q = "SELECT DISTINCT $table.primaryStudyID, $table2.* FROM $table, $table2 ".$where.
	      " AND $table2.id = $table.primaryStudyID ORDER by $table.studyID";
	  else
	    $q = "SELECT DISTINCT $table.primaryStudyID, $table2.* FROM $table, $table2 ".$where.
	      " AND $table2.id = $table.primaryStudyID ORDER by $table2.".$sortBy." ".$sortDir;
	else
      if($sortBy!='' && $sortDir!=''){
	    $q = "SELECT * FROM $table ".$where." ORDER BY $table.".$sortBy." ".$sortDir;
	  }
	  else
        $q = "SELECT * FROM $table ".$where." ORDER BY id";


  if (!$res = mysql_query($q, $db)){
    print "\n<p>mrData ERROR: ".mysql_error($db);
    print "\n<p><B>Offending SQL</B>: " . $q;
    exit; 
  }
  $totalNumRows = mysql_num_rows($res);
  if($totalNumRows<1)
    return("");
  // We retrieve the study title, subject name and session code to position the current display
  // in the database hierarchy
  if($table=='sessions' && $table2=='subjects'){
    $q2 = "SELECT title FROM studies WHERE id=".$studyId;
    if (!$res2 = mysql_query($q2, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db);
	  exit;
	}
    $studytitle = mysql_fetch_row($res2);
    $tableText = "<p><ul><li>Study: ".$studytitle[0]."</li></ul></p>";	
  } 
  if($table=='sessions' && $table2=='studies'){
    if(strpos($subjectId, '*')!==false)
	  $tableText = "<p><ul><li>Subject: All</li></ul></p>";
	else{
      $q2 = "SELECT firstName, lastName FROM subjects WHERE id=".$subjectId;
      if (!$res2 = mysql_query($q2, $db)){
        print "\n<p>mrData ERROR: ".mysql_error($db);
	    exit;
	  }
      $subjecttitle = mysql_fetch_row($res2);
      $tableText = "<p><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1]."</li></ul></p>";	
	}
  }
  if($table=='sessions' && $table2==''){
    $q3 = "SELECT title FROM studies WHERE id=".$studyId;
	if (!$res3 = mysql_query($q3, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
    }
    $studytitle = mysql_fetch_row($res3);
	if(strpos($subjectId, '*')!==false){
	  $subjecttitle[0] = 'All';
	  $subjecttitle[1] = '';
	}
	else{
	  $q4 = "SELECT firstName, lastName FROM subjects WHERE id=".$subjectId;
      if (!$res4 = mysql_query($q4, $db)){
        print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
      }
      $subjecttitle = mysql_fetch_row($res4);
	}
    switch ($browserType){
	case 'study':
	  $tableText = "<p><ul><li>Study: ".$studytitle[0]."</li><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1]."</li></ul></ul></p>";
	  break;
	case 'subject':
	  $tableText = "<p><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1]."</li><ul><li>Study: ".$studytitle[0]."</li></ul></ul></p>";
	  break;
	}
  }
  if($table=='scans'){
	$q3 = "SELECT title FROM studies WHERE id=".$studyId;
	if (!$res3 = mysql_query($q3, $db)){
	  print $q3;
      print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
    }
    $studytitle = mysql_fetch_row($res3);
	if(strpos($subjectId, '*')!==false){
	  $subjecttitle[0] = 'All';
	  $subjecttitle[1] = '';
	}
	else{
	  $q4 = "SELECT firstName, lastName FROM subjects WHERE id=".$subjectId;
      if (!$res4 = mysql_query($q4, $db)){
        print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
      }
      $subjecttitle = mysql_fetch_row($res4);
	}
	$q5 = "SELECT sessioncode FROM sessions WHERE id=".$sessionId;
    if (!$res5 = mysql_query($q5, $db)){
      print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
    }
    $sessiontitle = mysql_fetch_row($res5);
	switch ($browserType){
	case 'study':
	  $tableText = "<p><ul><li>Study: ".$studytitle[0]."</li><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1].
	    "</li><ul><li>Session: ".$sessiontitle[0]."</li></ul></ul></ul></p>";
	  break;
	case 'subject':
	  $tableText = "<p><ul><li>Subject: ".$subjecttitle[0]." ".$subjecttitle[1]."</li><ul><li>Study: ".$studytitle[0].
	    "</li><ul><li>Session: ".$sessiontitle[0]."</li></ul></ul></ul></p>";
	  break;
	}
  }  

  $tableText .= "<table border=1 cellpadding=4 cellspacing=2 bgcolor=$template->headerColor2><tr bgcolor=$template->headerColor>\n";
  if($showRowNum)
    $tableText .= "<th>Row #</th>";
  // To display table summaries, we choose relevant fields.
  if($displaySummary){
    switch ($table){
	case 'subjects':
	  $SummaryArray = array('id', 'subjectID', 'firstName', 'lastName');
	  break;
	case 'studies':
	  $SummaryArray = array('id', 'title', 'purpose', 'startDate', 'endDate');
	  break;
	case 'sessions':
	  if($table2=='')
	    $SummaryArray = array('id', 'subjectID', 'notes');
	  else
	    if($table2=='subjects')
	      $SummaryArray = array('subjectID', 'firstName', 'lastName');
		else
		  if($table2=='studies')
		    $SummaryArray = array('primaryStudyID', 'title', 'purpose', 'dataDirectory');
	  break;
    case 'scans':
	  $SummaryArray = array('id', 'scanNumber', 'stimulusID', 'stimulusType', 'notes');
	  break;
	}  
  }
  // Actually extract the data from the query result
  $stop = mysql_num_fields($res);
  while ($field = mysql_fetch_field($res)){
    $fields[] = $field->name;
	if(!$displaySummary || ($displaySummary && in_array($field->name, $SummaryArray)))
      if($sortbyStr!=""){
		$data = str_replace("<ID>", $field->name, $sortbyStr);
		if($sortBy==$field->name)
		  if($sortDir=="ASC"){
		    $data = str_replace("<DIR>", "<BR><img src=./media/downarrow.bmp>", $data);
			$data = str_replace("<DIR2>", "DESC", $data);
		  }
		  else{
		    $data = str_replace("<DIR>", "<BR><img src=./media/uparrow.bmp>", $data);
			$data = str_replace("<DIR2>", "ASC", $data);
		  }
		else{
		  $data = str_replace("<DIR>", "", $data);
		  $data = str_replace("<DIR2>", "ASC", $data);
		}
		$tableText .= "<th align=center valign=top>".$data."</th>\n";
	  }
	  else
	    $tableText .= "<th align=center valign=top>".$field->name."</th>\n";
  }
  $tableText .= "</tr>\n";
  $rowNum = 0;
  while ($row = mysql_fetch_row($res)){
    if($rowNum++%2) 
      $tableText .= "<tr bgcolor=$template->bgColor1>\n";
    else 
      $tableText .= "<tr bgcolor=$template->bgColor2>\n";
    if($showRowNum)
      $tableText .= "<td align=center>$rowNum</td>\n";
    foreach($row as $num=>$data){
      if($htmlFilter)
	    $data = htmlentities($data);
	  // Chop data if it is too long
	  if(strlen($data)>$maxDataLength)
		$data = substr($data, 0, $maxDataLength)."...";
	  // Special case: append studyCode to dataDirectory
	  if($fields[$num] == 'studyCode')
	    $studyCodeMem = $data;
      if($num==0 && $idString!="")
		$data = str_replace("<ID>", $data, $idString);
      // Check for a foreign table link. If we find one, then we insert the first
      // few fields from that table rather than the uninformative ID #.
      if(isset($links[$fields[$num]][$data])){
      	$data = $links[$fields[$num]][$data]
					      ." <a href=\"javascript:alert('".$linksFull[$fields[$num]][$data]."');\">...</a>";
      }
	  if(!$displaySummary || ($displaySummary && in_array($fields[$num], $SummaryArray))){
	    // Special case: append studyCode to dataDirectory
		if($fields[$num] == 'dataDirectory')
		  $data = $data.$studyCodeMem;
        if(mysql_field_type($res, $num)=='blob'){
          //echo "<td>[BLOB]</td>\n";
          $tableText .= "<td>".$data."&nbsp;</td>\n";
        }elseif(mysql_field_type($res, $num)=='string'){
          $tableText .= "<td align=center>".$data."&nbsp;</td>\n";
        }else{
		  $tableText .= "<td align=center>".$data."&nbsp;</td>\n";
	    }
	  }
    }
    $tableText .= "</tr>\n";
  }
  $tableText .= "</tr>\n</table>\n";
  return($tableText);
}
/*
function displayTable2($db, $table, $idString="", $where="", $showRowNum=0, $displaySummary=0, $table2="", $studyId=0, $sortbyStr="", $sortBy="", $sortDir=""){
  //
  // Returns the table text in one big string. Display at your leisure.
  //
  // $db is the database link and $table is the name of the table to display.
  //
  // $where is a string that will get appended to the main SELECT query.
  // It will typically be something like "WHERE id=3 AND name='foo'".
  //
  // $idString is a little hack to make this function more flexible. 
  // Background: the first column of any of our substantive tables is the 
  // item id (the primary key). This function will replace every occurance 
  // of "<ID>" in $idStr with the first column of each row(typically the 
  // row id) and show the hacked $idStr instead of the raw value. 
  // 
  // For example, you could send in a link that will return the row id to 
  // a specified URL with something like:
  //
  //     $idString = <a href="someUrl?id=<ID>">use <ID></a> 
  //
  // Each occurance of <ID> will get replaced with the value of the first
  // column of for each row. 
  //

  $htmlFilter = 0;
  if($displaySummary)
	$maxDataLength = 120;
  else
    $maxDataLength = 60;
  $template = getTemplate('default');

  // GET FOREIGN TABLE LINKS
  $res = mysql_query('SELECT * FROM xLinks WHERE fromTable="'.$table.'"', $db)
    or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
  while ($row = mysql_fetch_array($res)) {
    //$linkTables[$row['fromColumn']] = $row['toTable'];
    //$linkColumns[$row['fromColumn']] = $row['toColumn'];
    // Here we select all the relevant entries from the linked table.
    // It is much faster to get all of them at once here than it would be to run a
    // query for each iteration of the row loop belop.
    $q = "SELECT DISTINCT ".$row['toTable'].".* FROM $table,".$row['toTable']." WHERE "
         .$table.".".$row['fromColumn']."=".$row['toTable'].".".$row['toColumn'];
    $res2 = mysql_query($q, $db)
      or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
    while ($row2 = mysql_fetch_row($res2)){
      $links[$row['fromColumn']][$row2[0]] = $row2[1]." ".$row2[2]." (".$row2[0].")";
	  $str = "";
	  foreach($row2 as $num=>$val){
		$str = $str.$val."  ";
	  }
	  $linksFull[$row['fromColumn']][$row2[0]] = $str;
    }
  }
  
  // GET ALL ITEMS IN SPECIFIED TABLE
  if($table=='sessions' || $table2=='subjects')
    $q = "SELECT studyCode FROM studies WHERE id=".$studyId;
  if (!$res = mysql_query($q, $db)){
    print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
  }
  $studytitle = mysql_fetch_row($res);
  $tableText = "<p><ul><li>Study: ".$studytitle[0]."</li></ul></p>";
  if($table=='sessions' || $table2=='subjects')
    if($sortBy=='subjectID')
	  $q = "SELECT DISTINCT $table.subjectID, $table2.* FROM $table, $table2 ".$where.
	    " AND $table2.id = $table.subjectID ORDER by $table.subjectID";
	else
	  $q = "SELECT DISTINCT $table.subjectID, $table2.* FROM $table, $table2 ".$where.
	    " AND $table2.id = $table.subjectID ORDER by $table2.".$sortBy." ".$sortDir;
  else
    $q = "SELECT * FROM $table ".$where." ORDER BY id";
  if (!$res = mysql_query($q, $db)){
    print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
  }
  $totalNumRows = mysql_num_rows($res);
  if($totalNumRows<1) return("");

  $tableText .= "<table border=1 cellpadding=4 cellspacing=2><tr bgcolor=$template->headerColor>\n";
  if($showRowNum)
    $tableText .= "<th>Row #</th>";
  // To display table summaries, we choose relevant fields.
  if($displaySummary){
    switch ($table){
	case 'studies':
	  $SummaryArray = array('id', 'title', 'purpose', 'dataDirectory');
	  break;
	case 'sessions':
	  if($table2=='')
	    $SummaryArray = array('id', 'subjectID', 'notes');
	  else
	    $SummaryArray = array('subjectID', 'firstName', 'lastName');
	  break;
    case 'scans':
	  $SummaryArray = array('id', 'scanNumber', 'stimulusID', 'stimulusType', 'notes');
	  break;
	}  
  }
  $stop = mysql_num_fields($res);
  while ($field = mysql_fetch_field($res)){
    $fields[] = $field->name;
	if(!$displaySummary || ($displaySummary && in_array($field->name, $SummaryArray))){
      if($sortbyStr!=""){
		$data = str_replace("<ID>", $field->name, $sortbyStr);
		if($sortBy==$field->name)
		  if($sortDir=="ASC"){
		    $data = str_replace("<DIR>", " ^", $data);
			$data = str_replace("<DIR2>", "DESC", $data);
		  }
		  else{
		    $data = str_replace("<DIR>", " v", $data);
			$data = str_replace("<DIR2>", "ASC", $data);
		  }
		else{
		  $data = str_replace("<DIR>", "", $data);
		  $data = str_replace("<DIR2>", "ASC", $data);
		}
		$tableText .= "<th>".$data."</th>\n";
	  }
	  else
	    $tableText .= "<th>".$field->name."</th>\n";
	}
  }
  $tableText .= "</tr>\n";
  $rowNum = 0;
  while ($row = mysql_fetch_row($res)){
    if($rowNum++%2) 
      $tableText .= "<tr bgcolor=$template->bgColor1>\n";
    else 
      $tableText .= "<tr bgcolor=$template->bgColor2>\n";
    if($showRowNum)
      $tableText .= "<td align=center>$rowNum</td>\n";
    foreach($row as $num=>$data){
      if($htmlFilter)
	    $data = htmlentities($data);
	  // Chop data if it is too long
	  if(strlen($data)>$maxDataLength)
		$data = substr($data, 0, $maxDataLength)."...";
	  // Special case: append studyCode to dataDirectory
	  if($fields[$num] == 'studyCode')
	    $studyCodeMem = $data;
      if($num==0 && $idString!="")
		$data = str_replace("<ID>", $data, $idString);
      // Check for a foreign table link. If we find one, then we insert the first
      // few fields from that table rather than the uninformative ID #.
      if(isset($links[$fields[$num]][$data])){
      	$data = $links[$fields[$num]][$data]
					      ." <a href=\"javascript:alert('".$linksFull[$fields[$num]][$data]."');\">...</a>";
      }
	  if(!$displaySummary || ($displaySummary && in_array($fields[$num], $SummaryArray))){
	    // Special case: append studyCode to dataDirectory
		if($fields[$num] == 'dataDirectory')
		  $data = $data.$studyCodeMem;
        if(mysql_field_type($res, $num)=='blob'){
          //echo "<td>[BLOB]</td>\n";
          $tableText .= "<td>".$data."&nbsp;</td>\n";
        }elseif(mysql_field_type($res, $num)=='string'){
          $tableText .= "<td align=left>".$data."&nbsp;</td>\n";
        }else{
		  $tableText .= "<td align=center>".$data."&nbsp;</td>\n";
	    }
	  }
    }
    $tableText .= "</tr>\n";
  }
  $tableText .= "</tr>\n</table>\n";
  return($tableText);
}
*/
function displaySearchResult ($db, $tbl, $result, $rowOffset=0, $displaySummaryStr, $displaySummary, $sortbyStr, $sortBy, $sortDir){
  $template = getTemplate('default');
  $showRowNum = 0;
  $htmlFilter = 0;
  $showColumnTotals = 0;
  $maxDataLength = 50;
  $SummaryArray = array('subjects'=>array('firstName', 'lastName', 'address', 'email', 'notes'),
  						'scans'=>array('scanCode', 'notes', 'scanParams'),
						'sessions'=>array('sessionCode', 'readme', 'notes', 'dataSubDirectory'),
						'studies'=>array('studyCode', 'title', 'purpose', 'notes', 'dataDirectory'),
						'analyses'=>array('notes', 'summaryResult'),
						'dataFiles'=>array('path', 'backupLocation'),
						'displayCalibration'=>array('computer', 'videoCard', 'notes'),
						'displays'=>array('location', 'description'),
						'grants'=>array('agency', 'lucasCode', 'notes'),
						'protocols'=>array('sedesc', 'protocolName', 'coil', 'iopt', 'psdname', 'te', 'spc', 'saturation', 'contrast', 'contam'),
						'rois'=>array('ROIname'),
						'stimuli'=>array('name', 'description', 'code'),
						'subjectTypes'=>array('name', 'description'),
						'users'=>array('firstName', 'lastName', 'organization', 'email', 'username', 'notes'));

  echo "<h1>Results:</h1>\n";
  echo "<table border=1 cellpadding=4 cellspacing=1 bgcolor=$template->headerColor2>\n";
  echo "<tr bgcolor=$template->headerColor>\n";
  if($showRowNum)
    echo "<th>Row #</th>";
  while ($field = mysql_fetch_field($result)){
    $fields[] = $field->name;
	if(!$displaySummary || ($displaySummary && in_array($field->name, $SummaryArray[$tbl])))
	  if($sortbyStr!=""){
	    $data = str_replace("<ID>", $field->name, $sortbyStr);
		$data = str_replace("<ID2>", translateField($db, $tbl, $field->name), $data);
		if($sortBy==$field->name)
		  if($sortDir=="ASC"){
		    $data = str_replace("<DIR>", "<BR><img src=./media/downarrow.bmp>", $data);
			$data = str_replace("<DIR2>", "DESC", $data);
		  }
		  else{
		    $data = str_replace("<DIR>", "<BR><img src=./media/uparrow.bmp>", $data);
			$data = str_replace("<DIR2>", "ASC", $data);
		  }
		else{
		  $data = str_replace("<DIR>", "", $data);
	      $data = str_replace("<DIR2>", "ASC", $data);
		}  
		echo "<th>".$data."</th>\n";
	  }
	  else
        echo "<th>".$field->name."</th>\n";
  }
  echo "</tr>\n";
  $rowNum = $rowOffset;
  while ($row = mysql_fetch_row($result)){
    if($rowNum++%2) 
      echo "<tr bgcolor=$template->bgColor1>\n";
    else 
      echo "<tr bgcolor=$template->bgColor2>\n";
    if($showRowNum)
      echo "<td align=center>$rowNum</td>\n";
    foreach($row as $num=>$data){
	  if($htmlFilter)
	    $data = htmlentities($data);
	  if(strlen($data)>$maxDataLength)
		$data = substr($data, 0, $maxDataLength)."...";
	  if(!$displaySummary || ($displaySummary && in_array($fields[$num], $SummaryArray[$tbl]))){
        if(mysql_field_type($result, $num)=='blob')
          //echo "<td>[BLOB]</td>\n";
          echo "<td>".$data."&nbsp;</td>\n";
        elseif(mysql_field_type($result, $num)=='string')
          echo "<td align=left>".$data."&nbsp;</td>\n";
        else{
          if(mysql_field_type($result, $num)=='real')
            if(isset($colTotal[$num]))
			  $colTotal[$num] += $data;
            else
			  $colTotal[$num] = $data;
	      echo "<td align=center>".$data."&nbsp;</td>\n";
		}
	  }
    }
    echo "</tr>\n";
  }
  if($showColumnTotals){
    echo "<tr bgcolor=#aaffff>\n";
    if($showRowNum) echo "<td>&nbsp;</td>\n";
    for($num=0; $num<mysql_num_fields($result); $num++){
      if(isset($colTotal[$num])) 
        echo "<td align=center>".$colTotal[$num]."</td>\n";
      else 
        echo "<td align=center>&nbsp;</td>\n";
    }
  }
  echo "</tr>\n";
  echo "</table>\n";
  if($displaySummaryStr!=""){
    if($displaySummary){
	  $data = str_replace("<DS>", "0", $displaySummaryStr);
	  $data = str_replace("<DSS>", "complete", $data);
	}
	else{
	  $data = str_replace("<DS>", "1", $displaySummaryStr);
	  $data = str_replace("<DSS>", "summarized", $data);
	}
  }
  else{
    $data = str_replace("<DS>", "1", $displaySummaryStr);
	$data = str_replace("<DSS>", "DONT KNOW", $data);
  }
  echo "<p>".$data."</p>";
}

function displaySearchResult2 ($db, $tbl, $tbl2, $result, $rowOffset=0, $displaySummaryStr, $displaySummary, $sortbyStr, $sortBy, $sortDir){
  $template = getTemplate('default');
  $showRowNum = 0;
  $htmlFilter = 0;
  $showColumnTotals = 0;
  $maxDataLength = 50;
  $SummaryArray = array('subjects'=>array('firstName', 'lastName', 'dob', 'notes'),
  						'scans'=>array('scanCode', 'notes', 'scanParams'),
						'sessions'=>array('sessionCode', 'readme', 'notes', 'dataSubDirectory'),
						'studies'=>array('studyCode', 'title', 'purpose', 'notes', 'dataDirectory'),
						'analyses'=>array('notes', 'summaryResult'),
						'dataFiles'=>array('path', 'backupLocation'),
						'displayCalibration'=>array('computer', 'videoCard', 'notes'),
						'displays'=>array('location', 'description'),
						'grants'=>array('agency', 'lucasCode', 'notes'),
						'protocols'=>array('sedesc', 'protocolName', 'coil', 'iopt', 'psdname', 'te', 'spc', 'saturation', 'contrast', 'contam'),
						'rois'=>array('ROIname'),
						'stimuli'=>array('name', 'description', 'code'),
						'subjectTypes'=>array('name', 'description'),
						'users'=>array('firstName', 'lastName', 'organization', 'email', 'username', 'notes'));

  echo "<h1>Results:</h1>\n";
  echo "<table border=5 cellpadding=4 cellspacing=1 bgcolor=$template->headerColor2>\n";
  echo "<tr bgcolor=$template->headerColor>\n";
  if($showRowNum)
    echo "<th>Row #</th>";
  $colnum = 0;
  while ($field = mysql_fetch_field($result)){
    $fields[] = $field->name;
	if((!$displaySummary/* && (in_array($field->name, $SummaryArray[$tbl]))*/) || 
	   ($displaySummary && (in_array($field->name, $SummaryArray[$tbl]) || in_array($field->name, $SummaryArray[$tbl2])))) {
	  $colnum++;
	  if($sortbyStr!=""){
	    $data = str_replace("<ID>", $field->name, $sortbyStr);
		$trans1 = translateField($db, $tbl, $field->name);
		$trans2 = translateField($db, $tbl, $trans1);
		$data = str_replace("<ID2>", $trans2, $data);
		if($sortBy==$field->name)
		  if($sortDir=="ASC"){
		    $data = str_replace("<DIR>", "<BR><img src=./media/downarrow.bmp>", $data);
			$data = str_replace("<DIR2>", "DESC", $data);
		  }
		  else{
		    $data = str_replace("<DIR>", "<BR><img src=./media/uparrow.bmp>", $data);
			$data = str_replace("<DIR2>", "ASC", $data);
		  }
		else{
		  $data = str_replace("<DIR>", "", $data);
	      $data = str_replace("<DIR2>", "ASC", $data);
		}
		if($colnum>=sizeof($SummaryArray[$tbl])+1)
		  echo "<th bgcolor=$template->headerColor3>";
		else
		  echo "<th>";
		echo $data."</th>\n";
	  }
	  else {
	    if($colnum>=sizeof($SummaryArray[$tbl])+1)
		  echo "<th bgcolor=$template->headerColor3>";
		else
		  echo "<th>";
        echo $field->name."</th>\n";
	  }
	}
  }
  echo "</tr>\n";
  $rowNum = $rowOffset;
  while ($row = mysql_fetch_row($result)){
    $colnum = 0;
    if($rowNum++%2)
      echo "<tr bgcolor=$template->bgColor1>\n";
    else
      echo "<tr bgcolor=$template->bgColor2>\n";
    if($showRowNum)
      echo "<td align=center>$rowNum</td>\n";
    foreach($row as $num=>$data){
	  $colnum++;
	  if($htmlFilter)
	    $data = htmlentities($data);
	  if(strlen($data)>$maxDataLength)
		$data = substr($data, 0, $maxDataLength)."...";
	  if(!$displaySummary || ($displaySummary && (in_array($fields[$num], $SummaryArray[$tbl]) || in_array($fields[$num], $SummaryArray[$tbl2])))){
        if(mysql_field_type($result, $num)=='blob')
          //echo "<td>[BLOB]</td>\n";
          echo "<td>".$data."&nbsp;</td>\n";
        elseif(mysql_field_type($result, $num)=='string')
          echo "<td align=left>".$data."&nbsp;</td>\n";
        else{
          if(mysql_field_type($result, $num)=='real')
            if(isset($colTotal[$num]))
			  $colTotal[$num] += $data;
            else
			  $colTotal[$num] = $data;
	      echo "<td align=center>".$data."&nbsp;</td>\n";
		}
	  }
    }
    echo "</tr>\n";
  }
  if($showColumnTotals){
    echo "<tr bgcolor=#aaffff>\n";
    if($showRowNum) echo "<td>&nbsp;</td>\n";
    for($num=0; $num<mysql_num_fields($result); $num++){
      if(isset($colTotal[$num])) 
        echo "<td align=center>".$colTotal[$num]."</td>\n";
      else 
        echo "<td align=center>&nbsp;</td>\n";
    }
  }
  echo "</tr>\n";
  echo "</table>\n";
  if($displaySummaryStr!=""){
    if($displaySummary){
	  $data = str_replace("<DS>", "0", $displaySummaryStr);
	  $data = str_replace("<DSS>", "complete", $data);
	}
	else{
	  $data = str_replace("<DS>", "1", $displaySummaryStr);
	  $data = str_replace("<DSS>", "summarized", $data);
	}
  }
  else{
    $data = str_replace("<DS>", "1", $displaySummaryStr);
	$data = str_replace("<DSS>", "DONT KNOW", $data);
  }
  echo "<p>".$data."</p>";
}

function translate($txt){
  $translateTable = array('lastName' => 'Last Name', 'firstName' => 'First Name', 'dob' => 'D.O.B.', 'sessionCode' => 'Session Code',
    'id' => 'ID', 'start' => 'Session Start', 'end' => 'Session End', 'examNumber' => 'Exam Number', 'primaryStudyID' => "Primary Study ID");
  $translated = $translateTable[$txt];
  if($translated=="")
    $translated = $txt;
  return ($translated);
}

function translateField($db, $table, $field){
  $q = 'SELECT fieldTranslation FROM translate WHERE inTable="'.$table.'" AND fieldName="'.$field.'"';
  if (!$res = mysql_query($q, $db))
    print "\n<p>mrData ERROR: ".mysql_error($db);
  else {
    $row = mysql_fetch_array($res);
    $translated = $row[0];
	if ($translated=="")
	  $translated = $field;
  }
  return ($translated);
}

function wizardHeader($whichhighlight){
  echo "<br/><br/>\n";
  echo "<table border=1 rules=none cellspacing=0 align=center>\n";
  echo "<tr><td>\n";
  echo "<table ".($whichhighlight==1?"bgcolor=yellow":"")." border=0 align=center>\n";
  echo "<tr><td align=center><b>Step 1</b></td></tr>\n";
  echo "<tr><td align=center><b>Choose study</b></td></tr></table></td>\n";
  echo "<td align=center><img src=rightarrow.bmp></td>\n";
  echo "<td><table ".($whichhighlight==2?"bgcolor=yellow":"")." border=0 align=center>\n";
  echo "<tr><td align=center><b>Step 2</b></td></tr>\n";
  echo "<tr><td align=center><b>Create/Select session</b></td></tr></table></td>\n";
  echo "<td align=center><img src=rightarrow.bmp></td>\n";
  echo "<td><table ".($whichhighlight==3?"bgcolor=yellow":"")." border=0 align=center>\n";
  echo "<tr><td align=center><b>Step 3</b></td></tr>\n";
  echo "<tr><td align=center><b>Create scan</b></td></tr></table></td>\n";
  echo "</td></table>\n";
  echo "<br/><br/>\n";
}

function displayRecord($db, $table, $where=""){
  //
  // Returns the table text in one big string. Display at your leisure.
  //
  // $db is the database link and $table is the name of the table to display.
  //
  // $where is a string that will get appended to the main SELECT query.
  // It will typically be something like "WHERE id=3 AND name='foo'".
  //
  // $idString is a little hack to make this function more flexible. 
  // Background: the first column of any of our substantive tables is the 
  // item id (the primary key). This function will replace every occurance 
  // of "<ID>" in $idStr with the first column of each row(typically the 
  // row id) and show the hacked $idStr instead of the raw value. 
  // 

  $htmlFilter = 0;
  /*$maxDataLength = 60;*/
  $template = getTemplate('default');

  // GET FOREIGN TABLE LINKS
  $res = mysql_query('SELECT * FROM xLinks WHERE fromTable="'.$table.'"', $db)
    or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
  while ($row = mysql_fetch_array($res)) {
    //$linkTables[$row['fromColumn']] = $row['toTable'];
    //$linkColumns[$row['fromColumn']] = $row['toColumn'];
    // Here we select all the relevant entries from the linked table.
    // It is much faster to get all of them at once here than it would be to run a
    // query for each iteration of the row loop belop.
    $q = "SELECT DISTINCT ".$row['toTable'].".* FROM $table,".$row['toTable']." WHERE "
         .$table.".".$row['fromColumn']."=".$row['toTable'].".".$row['toColumn'];
    $res2 = mysql_query($q, $db)
      or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
    while ($row2 = mysql_fetch_row($res2)){
      $links[$row['fromColumn']][$row2[0]] = $row2[1]." ".$row2[2]." (".$row2[0].")";
			$str = "";
			foreach($row2 as $num=>$val){
				$str = $str.$val."  ";
			}
			$linksFull[$row['fromColumn']][$row2[0]] = $str;
    }
  }
  
  // GET ALL ITEMS IN SPECIFIED TABLE
  $q = "SELECT * FROM $table ".$where." ORDER BY id";
  if (!$res = mysql_query($q, $db)){
    print "\n<p>mrData ERROR: ".mysql_error($db); exit; 
  }
  $totalNumRows = mysql_num_rows($res);
  if($totalNumRows<>1) {
    print "\n<p>error in displayRecord: more than one record";
    return("");
  }

/*  $tableText = "<table border=1 cellpadding=4 cellspacing=2><tr bgcolor=$template->headerColor>\n";*/
  $tableText = "<table border=1 cellpadding=4 cellspacing=2>\n";
  /*if($showRowNum)
    $tableText .= "<th>Row #</th>";*/
  while ($field = mysql_fetch_field($res)){
    $fields[] = $field->name;
/*    $tableText .= "<th>".$field->name."</th>\n";*/
  }
/*  $tableText .= "</tr>\n";*/
  $columnNum = 0;
  while ($row = mysql_fetch_row($res)){
/*    if($columnNum++%2) 
      $tableText .= "<tr bgcolor=$template->bgColor1>\n";
    else 
      $tableText .= "<tr bgcolor=$template->bgColor2>\n";*/
/*    if($showRowNum)
      $tableText .= "<td align=center>$rowNum</td>\n";*/
    foreach($row as $num=>$data){
/*      if($htmlFilter) $data = htmlentities($data);
			// Chop data if it is too long
	  if(strlen($data)>$maxDataLength)
				$data = substr($data, 0, $maxDataLength)."...";*/
	  $tableText .= "<tr bgcolor=$template->headerColor>\n"."<th>".$fields[$columnNum]."</th>";
      if($columnNum++%2) 
        $tableText .= "<td bgcolor=$template->bgColor1>\n";
      else 
        $tableText .= "<td bgcolor=$template->bgColor2>\n";
      if($num==0 && $idString!="")
		$data = str_replace("<ID>", $data, $idString);
      // Check for a foreign table link. If we find one, then we insert the first
      // few fields from that table rather than the uninformative ID #.
      if(isset($links[$fields[$num]][$data])){
      	$data = $links[$fields[$num]][$data]
					      ." <a href=\"javascript:alert('".$linksFull[$fields[$num]][$data]."');\">...</a>";
      }
	  $tableText .= $data."&nbsp;</td></tr>\n";
/*      if(mysql_field_type($res, $num)=='blob'){
        //echo "<td>[BLOB]</td>\n";
        $tableText .= $data."&nbsp;</td>\n";
      }elseif(mysql_field_type($res, $num)=='string'){
        $tableText .= "<td align=left>".$data."&nbsp;</td>\n";
      }else{
		$tableText .= "<td align=center>".$data."&nbsp;</td>\n";
	  }*/
    }
    $tableText .= "</tr>\n";
  }
  $tableText .= "</tr>\n</table>\n";
  return($tableText);
}

function updateRecord($db, $table, $data){
  //
  // list($success, $msg, $id) = updateRecord($db, $table, $data)
  // 
  // Returns (success, message, id) where success is a boolean- 
  // 1 means insert/update was successful, 0 means it failed. 
  // msg is a text string with something informative about what 
  // was done. id is the id of the inserted/updated item.

  // Updating an id field for an existing record would be bad, 
  // since we don't check for foreign table links. There is really 
  // no reason to do this, so we assume that if the id field is
  // set, then this should be an update request. 
  if(isset($data['id']) && $data['id']!=0){
    // do an update
    $q = "UPDATE $table SET ";
    $msg = "Updated ";
    $id = $data['id'];
  }else{
    // do an Insert
    $q = "INSERT INTO $table SET ";
    $msg = "Inserted ";
    $id = 0;
  }

//  if($data[]!=$data[]){
//  }
  
  foreach($data as $name=>$value){
    // try to be clever with dates. This should allow some flexibility
    // in date formats that are accepted. However, we should do some
    // sanity checking here.
    if(strcasecmp(substr($name, -4), 'date')==0)
      $value = date("Y-m-d", strtotime($value));
      $q .= $name."='$value', ";
  }
  $createdOn = date("Y-m-d H:i:s");
  $q = substr($q, 0, -2);
  // For updates, we have to add the WHERE clause.
  if($id!=0) $q .= " WHERE id=$id";
  if($res = mysql_query($q, $db)){
    if($id==0) $id = mysql_insert_id($db);
    $msg .= "item $id in table $table.";
    $success = 1;
  }else{
    $msg = "MySQL error nr ".mysql_errno($db).": ".mysql_error($db)
      ." (".$createdOn.", ".$_SERVER["REMOTE_ADDR"].", ".$_SERVER["HTTP_USER_AGENT"].")";;
    //echo $q;
    //mail("bob@white.stanford.edu", "mrData ERROR", $errMsg);
    $success = 0;
  }
  return(array($success, $msg, $id));
}

function deleteRecord($db, $table, $id){
  //
  // list($success, $msg) = deleteRecord($db, $table, $id)
  // 
  // Returns (success, message) where success is a boolean- 
  // 1 means insert/update was successful, 0 means it failed. 
  // msg is a text string with something informative about what 
  // was done.
  
  if($res = mysql_query("DELETE FROM $table WHERE id=$id", $db)){
    $msg .= "Deleted item $id from table $table.";
    $success = 1;
  }else{
    $msg = "MySQL error while deleting nr ".mysql_errno($db).": ".mysql_error($db)
      ." (".$createdOn.", ".$_SERVER["REMOTE_ADDR"].", ".$_SERVER["HTTP_USER_AGENT"].")";
    //mail("bob@white.stanford.edu", "mrData ERROR", $errMsg);
    $success = 0;
  }
  // CLEAN UP FOREIGN TABLE LINKS
  // We set all links to this item in all other tables to 0.
  // *** We should also handle the xLink tables, which deal with the 
  // many-to-many links.
  if(!$res = mysql_query('SELECT * FROM xLinks WHERE toTable="'.$table.'"', $db)){
    $msg .= "<br>MySQL error while cleaning foreign table links, db may be corrupt: "
            .mysql_error($db);
  }else{
    while ($row = mysql_fetch_array($res)) {
      $q = 'UPDATE '.$row['fromTable'].' SET '.$row['fromColumn'].'=0 WHERE '.$row['fromColumn'].'='.$id;
      //echo $q;
      if($res2 = mysql_query($q, $db))
	$msg .= "<br>Fixed ".mysql_affected_rows($db)." foreign table links in table "
	        .$row['fromTable'].".";
      else
	$msg .= "<br>MySQL error while cleaning foreign table links, db may be corrupt: "
	        .mysql_error($db);
    }
  }
  return(array($success, $msg));
}

function buildFormFromTable($db, $table, $prevTable, $submitURL, $data="", $extras="", $fillDataFromID=0, $from=""){
  //
  // $formText = buildFormFromTable($db, $table, ...)
  // 
  // Builds an html form for the specified table. The form will
  // include pull-downs for foreign table links. If anything fails,
  // $formText will comprise an informative message rather than 
  // an actual table. You can include default values in 'd'.
  //
  // If d[id] is set, then this will be treated as an update rather
  // than an insert. The other values in d will over ride those from
  // the existing record, so be sure to unset those (or set them ="")
  // if you want to start with defaults from the db.
  //
  // if $fillDataFromID != 0, then it is sort of like an update- default
  // values will be pulled from the db from the specified id. Again, values
  // in d that are set and !="" will override those from the db, so be
  // sure to unset them if you want all defaults pulled from the db.
  //
  // Note that all the form fields are named "d[tableName][fieldName]".
  // Obviously, your function that processes the form data will need
  // to know this.
  // Eg:
  //
  //
  // Also, note that this function assumes that a new table form can be
  // displayed by submitting the form with "$table" set to the new table name. 
  //

  $maxSelectLength = 30;

  //
  // GET FOREIGN TABLE LINKS
  //
  if(!$res = mysql_query('SELECT * FROM xLinks WHERE fromTable="'.$table.'"', $db)){
    $formText = "MySQL error nr ".mysql_errno($db).": ".mysql_error($db);
    return($formText);
  }
  while ($row = mysql_fetch_array($res)) {
    $xlinks[$row['fromColumn']][-1] = "select from ".$row['toTable'];
    $xlinksTable[$row['fromColumn']] = $row['toTable'];
    // *** IS THERE A WAY TO SELECT JUST THE FIRST THREE COLUMNS?
    $res2 = mysql_query('SELECT * FROM '.$row['toTable'], $db)
      or trigger_error("MySQL error nr ".mysql_errno($db).": ".mysql_error($db));
    while ($row2 = mysql_fetch_row($res2)) {
      // This will be a 2d array- the 2nd dim is a hash with the item ID # as the key.
			if(strlen($row2[1])>$maxSelectLength) $row2[1] = substr($row2[1],0,$maxSelectLength)."...";
      $xlinks[$row['fromColumn']][$row2[0]] = "(".$row2[0].") ".$row2[1];
			// We decide if we should show the third field based on it's length. If it's too long,
			// then it's probably not worth showing, unless the second field is empty.
			if(mysql_field_len($res2,2)<100 | strlen($row2[1])==0){
				if(strlen($row2[2])>$maxSelectLength) $row2[2] = substr($row2[2],0,$maxSelectLength)."...";
				$xlinks[$row['fromColumn']][$row2[0]] .= " ".$row2[2];
			}
    }
  }
  
  $d = $data[$table];
  unset($data[$table]);

  // If the fillDataFromID var is set to a real ID, then try to fill in the data from this entry.
  // This will be like an update except that we'll zero out the ID later so that it becomes a new entry.
  if (isset($fillDataFromID) && ($fillDataFromID!=0)) {
    $d['id'] = $fillDataFromID;
  }
  
  // If the 'id' field is set and non-zero, then this is an update form.
  // Get the old data for fill-in the defaults.
  if((isset($d['id']) && $d['id']!=0)){
    if(!$res = mysql_query("SELECT * FROM $table WHERE id=".$d['id'], $db)){
      $formText = "MySQL error nr ".mysql_errno($db).": ".mysql_error($db);
      return($formText);
    }
    // We no longer overwrite defaults sent in via $data
    while($row = mysql_fetch_array($res)) {
      foreach($row as $field=>$value){
	if(!isset($d[$field]) || $d[$field]=="")
	  $d[$field] = $value;
      } // end foreach
    } // end while
    
    // Zero the ID if we're cloning rather than updating
    if (isset($fillDataFromID) && ($fillDataFromID!=0)) {
    	$d['id'] = 0;
    }	
  } // end if

  // 
  // BUILD HTML FORM
  //
  if(!$res = mysql_query("SHOW FIELDS FROM $table", $db)){
    $formText = "MySQL error nr ".mysql_errno($db).": ".mysql_error($db);
    return($formText);
  }

  $formText = "";
  if($d['id']!=0){
    $pos = strpos($submitURL, '?');
	if($pos===false)
	  $formTopText = "<form method=POST name=\"".$table."_form\" action=\"$submitURL?updateId2=".$d['id']."\">\n";
	else
	  $formTopText = "<form method=POST name=\"".$table."_form\" action=\"$submitURL&updateId2=".$d['id']."\">\n";
  }
  else
    $formTopText = "<form method=POST name=\"".$table."_form\" action=\"$submitURL\">\n";
  //$formTopText = "<form method=POST name=\"".$table."_form\" action=\"http://snarp.stanford.edu/info.php\">\n";
  $formTopText .= "<table border=0 cellspacing=2 cellpadding=2>\n";
  $formTopText .= "<input type=hidden name=\"table\" value=\"$table\">\n";
  if(is_array($extras)){
    foreach($extras as $name=>$value){
      $formTopText .= "<input type=hidden name=\"$name\" value=\"$value\">\n";
    }
  }
  if(is_array($data)){
    foreach($data as $otherTableName=>$otherTableArray){
      foreach($otherTableArray as $name=>$value){
	    $formTopText .= "<input type=hidden name=\"d[$otherTableName][$name]\" value=\"$value\">\n";
      }
    }
  }
  if(isset($prevTable) && is_array($prevTable)){
  foreach($prevTable as $key => $val)
    $formTopText .= "<input type=hidden name=prevTable[$key] value=\"$val\">\n";
  array_push($prevTable, $table);
  }else{
    $prevTable = array($table);
  }
  
  while ($row = mysql_fetch_array($res)) {
    $name = $row['Field']; //mysql_field_name($fields, $i);
    $typeStr = $row['Type']; //mysql_field_type($fields, $i);
    if($name=='id'){
      if($d[$name]!=0){
		$formTopText .= textField("Updating row ".$name.":", "d[$table][$name]", $d[$name], 6, 0);
		// Since it will be disabled, we can't count on it being submitted with
		// the form. So, we add a hidden field.
		$formTopText .= "<input type=hidden name=\"d[$table][$name]\" value=\"$d[$name]\">\n";
      }//else $formTopText .= textField($name.":", "junk", "<auto>", 6, 0);
    }elseif($typeStr=='date'){
      if(!isset($d[$name])) $d[$name] = date("Y-m-d");
      $formText .= textField(translateField($db, $table, $name)." (YYYY-MM-DD):", "d[$table][$name]", $d[$name], 10);
    }elseif($typeStr=='datetime'){
//      if(!isset($d[$name])) $d[$name] = date("Y-m-d H:00:00");
	  if($name=='end') $d[$name] = date("Y-m-d H:59:00");
	  else $d[$name] = date("Y-m-d H:00:00");
      $formText .= textField($name." (YYYY-MM-DD HH:MM:SS):", "d[$table][$name]", $d[$name], 19);
    }elseif($typeStr=='text'){
      $formText .= textBox($name.":", "d[$table][$name]", $d[$name], 10);
    }elseif(strncasecmp($typeStr,'enum',4)==0){
      $vals = explode("','", "',".substr($typeStr,5,-1).",'");
      $vals = array_slice($vals, 1, -1);
      $formText .= radioField($name.":", "d[$table][$name]", $vals, $d[$name]);
	}elseif($name=='password'){
	  $formText .= pwdField($name.":", "d[$table][$name]", $d[$name], 16);
    }else{
      if(isset($xlinks[$name])){
				if(!isset($d[$name]) || $d[$name]=='') $d[$name] = -1;
				$newLink = "";
				foreach($prevTable as $key => $val)
					$newLink .= "&prevTable[$key]=$val";
				// We put these at the beginning of formText so that all the pull-downs
				// appear at the top of the page.
				$formTopText .= selectField(translateField($db, $table, $name).":", "d[$table][$name]", $xlinks[$name], $d[$name], 
																		" <input type=submit name=\"".$xlinksTable[$name]."\" value=New>");
      }else{
				list($type, $size, $extra) = preg_split('(\(|\))', $typeStr);
				if($size>40) 
					$formText .= textBox(translateField($db, $table, $name).":", "d[$table][$name]", $d[$name], round($size/40));
				else
					$formText .= textField(translateField($db, $table, $name).":", "d[$table][$name]", $d[$name], $size);
      }
    }
  }
  $formText .= "</table><br><br>\n";
  $formText .= "&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<input type=submit name=\"$table\" value=Submit>\n";
  $formText .= "&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<input type=submit name=cancel value=Cancel>\n";
  if($from=="buildSession3")
    $formText .= "&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<input type=submit name=index value='Back to Main Index'>\n";
  $formText .= "</form>\n";
  return($formTopText.$formText);
}

function textField($displayName, $varName, $defaultValue, $size="", $enabled=1){
  $ret = "<tr>\n";
  $ret .= "<td align=right>$displayName</td>\n<td>";
  $ret .= "<input type=text";
  $ret.= " name=\"$varName\" value=\"$defaultValue\"";
  if($size!="") $ret .= " size=\"$size\"";
  if(!$enabled) $ret .= " DISABLED"; // or READONLY
  $ret .= ">";
  $ret .= "</td></tr>\n";
  return($ret);
}

function pwdField($displayName, $varName, $defaultValue, $size="", $enabled=1){
  // Decrypt password to present hidden in form
  if($defaultValue!=""){
    $key = "PaulVerlaine";
	$defaultValue = decrypt_md5($defaultValue, $key);
  }
  $ret = "<tr>\n";
  $ret .= "<td align=right>$displayName</td>\n<td>";
  $ret .= "<input type=password";
  $ret.= " name=\"$varName\" value=\"$defaultValue\"";
  if($size!="") $ret .= " size=\"$size\"";
  if(!$enabled) $ret .= " DISABLED"; // or READONLY
  $ret .= ">";
  $ret .= "&nbsp&nbsp&nbsp&nbspverify password:&nbsp&nbsp";
  $ret .= "<input type=password name=\"verify\" value=\"$defaultValue\" size=\"$size\">";
  $ret .= "</td></tr>\n";
  return($ret);
}

function textBox($displayName, $varName, $defaultValue, $rows=5, $cols=40, $enabled=1){
  $ret = "<tr>\n";
  $ret .= "<td align=right valign=top>$displayName</td>\n<td>";
  $ret .= "<textarea name=\"$varName\" rows=$rows cols=$cols wrap=virtural";
  if(!$enabled) $ret .= " DISABLED";
  $ret .= ">";
  $ret .= "$defaultValue</textarea>";
  $ret .= "</td></tr>\n";
  return($ret);
}

function radioField($displayName, $varName, $values, $defaultValue="", $enabled=1){
  $ret = "<tr><td align=right>$displayName</td>\n";
  $ret .= "<td><strong>\n";
  if($enabled){
    foreach($values as $key=>$val){
      $ret .= "<input type=radio name=\"$varName\" value=\"$val\"";
      if($val==$defaultValue) $ret .= " checked";
      if(!$enabled) $ret .= " DISABLED";
      $ret .= ">$val\n";
    }
  }
  $ret .= "</strong></td></tr>\n";
  return($ret);
}

function selectField($displayName, $varName, $values, $defaultValue="", $extraStuff, 
		     $onChange="", $enabled=1){
  $ret = "<tr>\n";
  $ret .= "<td align=right>$displayName</td>\n<td>";
  $ret .= "<select name=\"$varName\"";
  if(!$enabled) $ret .= " READONLY";
  if($onChange!="") $ret .= " onChange=\"javascript:".$onChange;
  $ret .= ">\n";
  foreach($values as $key=>$val){
    $ret .= "<option ";
    if($key==$defaultValue) $ret .= "SELECTED ";
    $ret .= "value=\"$key\">$val</option>\n";
  }
  $ret .= "</select>\n";
  if($extraStuff!="") $ret .= " $extraStuff";
  $ret .= "</td></tr>\n";
  return($ret);
}

function getTemplate($name='default'){
  $t->headerColor = "#ffffaa";
  $t->headerColor2 = "#66cc66";
  $t->headerColor3 = "#aaffaa";
  $t->bgColor1 = "#ffffff";
  $t->bgColor2 = "#ffffee";
  $t->fontColor = "#000000";
  return($t);
}

function getFileSizeString($size){
  if($size < 1024) $sizeStr = $size." Bytes";
  else if($size < 1048576) $sizeStr = round($size/1024,0)." KB";
  else if($size < 1073741824) $sizeStr = round($size/1048576,2)." MB";
  else $sizeStr = round($size/1073741824,2)." GB";
  return($sizeStr);
}

function ls($dirPath){
  if ($handle = @opendir($dirPath)){
    while (false !== ($file = readdir($handle)))
      if ($file != "." && $file != "..")
        $filesArr[] = trim($file);
    closedir($handle);
  }  
  return $filesArr;
}

function bytexor($a,$b)
{
  $c="";
  for($i=0;$i<16;$i++)
    $c.=$a{$i}^$b{$i};
  return $c;
}

function decrypt_md5($msg,$key)
{
  $string="";
  $buffer="";
  $key2="";
  while($msg) {
    $key2=pack("H*",md5($key.$key2.$buffer));
    $buffer=bytexor(substr($msg,0,16),$key2);
    $string.=$buffer;
    $msg=substr($msg,16);
  }
  return($string);
}

function encrypt_md5($msg,$key)
{
  $string="";
  $buffer="";
  $key2="";
  while($msg) {
    $key2=pack("H*",md5($key.$key2.$buffer));
    $buffer=substr($msg,0,16);
    $string.=bytexor($buffer,$key2);
    $msg=substr($msg,16);
  }
  return($string);
}

function checkSessionForRecon( $db, $study_id, $session_id ) {
  $scans[] = array();
  $localizer_scan_count = 0;
  $localizer_scan_id = 0;
  $reference_scan_count = 0;
  $reference_scan_id = 0;
  $good_scan_count = 0;
  $q = "SELECT * FROM scans WHERE primaryStudyID = $study_id AND sessionID = $session_id";
  if (!$res = mysql_query($q, $db)){
    print "\n<p>mrData ERROR: ".mysql_error($db);
    print "\n<p><b>Offending SQL:</b> $q";
  }
  while ($row = mysql_fetch_array($res)) {
    $scans[ $row[ 'id' ] ] = $row;
  }

  foreach( $scans as $scan_id=>$scan_row ) {
    if ( $scan_row[ 'scanType' ] == "Localizer" ) {
      $localizer_scan_count += 1;
      $localizer_scan_id = $scan_id;
    }
    else if ( $scan_row[ 'scanType' ] == "Reference" ) {
      $reference_scan_count += 1;
      $reference_scan_id = $scan_id;
    }
    else if ( $scan_row[ 'ignoreScan' ] == 0 ) 
      $good_scan_count += 1;
  }

  $errors = array();
//   if ( $localizer_scan_count < 1 ) 
//     array_push( $errors, "No localizer scan" );
//   if ( $localizer_scan_count > 1 ) 
//     array_push( $errors, "More than one localizer scan" );
  if ( $reference_scan_count < 1 ) 
    array_push( $errors, "No reference scan" );
  if ( $reference_scan_count > 1 ) 
    array_push( $errors, "More than one reference scan" );
  if ( $good_scan_count < 1 )
    array_push( $errors, "No good scans" );
  

  if ( count( $errors ) > 0 ) {
    print "<TABLE WIDTH=100% BORDER=1><TR><TD BGCOLOR=#AAFF><B>Problems with this session:</B><P>";
    foreach ( $errors as $error ) {
      print "<LI>$error</LI>";
    } 
    print "<P>If you don't correct these problems, your data may not get reconned/motion corrected.</TD></TR>"; 
    print "</TABLE>";
  }
  
}

?>
