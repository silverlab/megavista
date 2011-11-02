<?php
/*
 * studyBrowser.php
 *
 * Builds an html form to browse for studies.
 *
 * HISTORY:
 *  092503 Wrote first draft with Bob's help. AJM (antoine@psych.stanford.edu)
 *  102903 Added session, scan and record browsing. AJM (antoine@psych.stanford.edu)
 *  103003 Added navigation and display type links. AJM (antoine@psych.stanford.edu)
 *  111103 Added extra subject step between study and session. AJM (antoine@psych.stanford.edu)
 *  120903 Added sorting mechanism on columns. AJM (antoine@psych.stanford.edu)
 */
require_once("include.php");

$db = login();
$msg = "Connected as user ".$_SESSION['username'];

$selfURL = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];

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

if (isset($_REQUEST["scanId"]))
     $scanId = $_REQUEST["scanId"];
     else
     $scanId = 0;
if(isset($_REQUEST["sessionId"]))
     $sessionId = $_REQUEST["sessionId"];
     else
     $sessionId = 0;
if(isset($_REQUEST["subjectId"]))
     $subjectId = $_REQUEST["subjectId"];
     else
     $subjectId = 0;
if(isset($_REQUEST["studyId"]))
     $studyId = $_REQUEST["studyId"];
     else
     $studyId = 0;

$browserType = "study";

if($scanId>0){
  writeHeader("Display record", "secure", $msg);
  echo "<h1>Display record:</h1>\n";
}else
  if($sessionId>0){
    writeHeader("Browse scan", "secure", $msg);
    checkSessionForRecon( $db, $studyId, $sessionId );
    echo "<h1> Browse scan:</h1>\n";
  }else
    if($subjectId>0){
	  writeHeader("Browse session", "secure", $msg);
      echo "<h1>Browse session:</h1>\n";
    }else
      if($studyId>0){
	    writeHeader("Browse subject", "secure", $msg);
        echo "<h1>Browse subject:</h1>\n";
      }else{
        writeHeader("Browse study", "secure", $msg);
        echo "<h1>Browse study:</h1>\n";
	  }

echo '<p><a href="'.selfURL().'?studyId='.$studyId.'&subjectId='.$subjectId.'&sessionId='.$sessionId.'&scanId='.$scanId.
  '&displaySummary=1'.'">Summary (default)</a>'."\n";
echo '&nbsp;&nbsp;&nbsp;<a href="'.selfURL().'?studyId='.$studyId.'&subjectId='.$subjectId.'&sessionId='.$sessionId.'&scanId='.$scanId.
  '&displaySummary=0'.'">Full</a>'."</p>\n";

/*echo "studyId=".$studyId."  subjectId=".$subjectId."  sessionId=".$sessionId."  scanId=".$scanId;*/

if($scanId>0){
	$table = 'scans';
	$tableText = displayRecord($db, $table, "WHERE id=".$scanId, $studyId, $subjectId, $sessionId, $scanId);
	if($tableText!=""){
	  echo $tableText;
	}else{
	  echo "<p class=error>Entry not found.</p>\n";
	}
    echo '<p><a href="'.selfURL().'?studyId='.$studyId.'&subjectId='.$subjectId.'&sessionId='.$sessionId.'&displaySummary='.$displaySummary.
	  '">Back to scan list</a>'."</p>\n";
}else{
  if($sessionId>0){
    $table = 'scans';
    $idStr = '<a href="'.selfURL().'?studyId='.$studyId.'&subjectId='.$subjectId.'&sessionId='.$sessionId.'&displaySummary='.$displaySummary.
	  '&scanId=<ID>"><ID></a>';
	$sortbyStr = '<a href="'.selfURL().'?studyId='.$studyId.'&subjectId='.$subjectId.'&sessionId='.$sessionId.'&displaySummary='.$displaySummary.
	  '&sortDir=<DIR2>&sortBy=<ID>"><ID><DIR></a>';
	if($sortBy=="")
	  // Default sort
      $sortBy='id';
    $tableText = displayBrowserResult($db, $table, $idStr, "WHERE sessionID=".$sessionId, 0,
	  $displaySummary, $table2, $studyId, $subjectId, $sessionId, $sortbyStr, $sortBy, $sortDir, $browserType);
    if($tableText!=""){
      echo $tableText;
    }else{
      echo "<p class=error>No entries found.</p>\n";
    }
    echo '<p><ul><li><a href="'.selfURL().'?displaySummary='.$displaySummary.'">Select new study</a></li>';
    echo '<ul><li><a href="'.selfURL().'?studyId='.$studyId.'&displaySummary='.$displaySummary.'">Select new subject</a></li>';
    echo '<ul><li><a href="'.selfURL().'?studyId='.$studyId.'&subjectId='.$subjectId.'&displaySummary='.$displaySummary.
	  '">Select new session</a></li></ul></ul></ul></p>';
  }else{
    if($subjectId>0 || strpos($subjectId, '*')!==false){
	  $table = 'sessions';
      $idStr = '<a href="'.selfURL().'?studyId='.$studyId.'&subjectId='.$subjectId.'&displaySummary='.$displaySummary.
	    '&sessionId=<ID>"><ID></a>';
	  $sortbyStr = '<a href="'.selfURL().'?studyId='.$studyId.'&subjectId='.$subjectId.'&displaySummary='.$displaySummary.
	    '&sortDir=<DIR2>&sortBy=<ID>"><ID><DIR></a>';
	  if($sortBy=="")
		 // Default sort
         $sortBy='id';
    
	  if(strpos($subjectId, '*')!==false) 
	    $tableText = displayBrowserResult($db, $table, $idStr, "WHERE primaryStudyID = ".$studyId, 0,
					      $displaySummary, $table2, $studyId, $subjectId, $sessionId, $sortbyStr, $sortBy, $sortDir, $browserType);
	  else 
	    $tableText = displayBrowserResult($db, $table, $idStr, "WHERE primaryStudyID = ".$studyId." AND subjectId = ".$subjectId, 0,
					      $displaySummary, $table2, $studyId, $subjectId, $sessionId, $sortbyStr, $sortBy, $sortDir, $browserType);
      if($tableText!=""){
        echo $tableText;
      }else{
       echo "<p class=error>No entries found.</p>\n";
      }
	  echo '<p><ul><li><a href="'.selfURL().'?displaySummary='.$displaySummary.'">Select new study</a></li>';
	  echo '<ul><li><a href="'.selfURL().'?studyId='.$studyId.'&displaySummary='.$displaySummary.'">Select new subject</a></li></ul></ul></p>';
	}else{
      if($studyId>0){
	    // Add possibility to browse all sessions for all subjects
		echo '<p><a href="'.selfURL().'?studyId='.$studyId.'&subjectId=*&displaySummary='.$displaySummary.
		  '">Browse all sessions for all subjects</a></p>'."\n";
        $table = 'sessions';
		$table2 = 'subjects';
        $idStr = '<a href="'.selfURL().'?studyId='.$studyId.'&displaySummary='.$displaySummary.'&subjectId=<ID>"><ID></a>';
		$sortbyStr = '<a href="'.selfURL().'?studyId='.$studyId.'&displaySummary='.$displaySummary.'&sortDir=<DIR2>&sortBy=<ID>"><ID><DIR></a>';
		if($sortBy=="")
		  // Default sort
          $sortBy='lastName';
		$tableText = displayBrowserResult($db, $table, $idStr, "WHERE sessions.primaryStudyID=".$studyId, 0,
		  $displaySummary, $table2, $studyId, $subjectId, $sessionId, $sortbyStr, $sortBy, $sortDir, $browserType);
        if($tableText!=""){
          echo $tableText;
        }else{
         echo "<p class=error>No entries found.</p>\n";
        }
	    echo '<p><ul><li><a href="'.selfURL().'?displaySummary='.$displaySummary.'">Select new study</a></li></ul></p>';
      }else{
        $table = 'studies';
        $idStr = '<a href="'.selfURL().'?displaySummary='.$displaySummary.'&studyId=<ID>"><ID></a>';
		$sortbyStr = '<a href="'.selfURL().'?displaySummary='.$displaySummary.'&sortDir=<DIR2>&sortBy=<ID>"><ID><DIR></a>';
		if($sortBy=="")
		  // Default sort
          $sortBy='id';
        $tableText = displayBrowserResult($db, $table, $idStr, "", 0, $displaySummary, $table2,
		  $studyId, $subjectId, $sessionId, $sortbyStr, $sortBy, $sortDir, $browserType);
        if($tableText!=""){
          echo $tableText;
        }else{
          echo "<p class=error>No entries found.</p>\n";
		}
      }
    }
  }
}
writeFooter('basic');
?>