<?php
/*
 * buildNewStudy.php
 *
 * Add new study.
 * 
 * HISTORY:
 *  041204 New form to enter new study (based on editTable.php by Bob). AJM (antoine@psych.stanford.edu))
 *  2003.05.01 RFD (bob@white.stanford.edu) wrote it.
 */

require_once("include.php");
$db = login();
if(!isset($_REQUEST["table"]) || $_REQUEST["table"]==""){
  trigger_error("'table' is not specified.");
  exit;
}
//$selfUrl = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];
//$msg = "";
//writeHeader("Add new study", "secure", $msg);

if(isset($_REQUEST["d"])) $d = $_REQUEST["d"];
if(isset($_REQUEST["prevTable"])) $prevTable = $_REQUEST["prevTable"];
if(isset($_REQUEST["deleteId"])) $deleteId = $_REQUEST["deleteId"];
else $deleteId = 0;
$extras = array();
if(isset($_REQUEST["returnURL"])) $extras["returnURL"] = $_REQUEST["returnURL"];
if(isset($_REQUEST["returnIdName"])) $extras["returnIdName"] = $_REQUEST["returnIdName"];
if(isset($_REQUEST["defaultDataId"])) $defaultDataId = $_REQUEST["defaultDataId"];
else $defaultDataId = 0;
if(isset($_REQUEST["msg"])) $msg = $_REQUEST["msg"];
else $msg = "";
$table = $_REQUEST["table"];
if(isset($prevTable) && is_array($prevTable)) $numPendingTables = count($prevTable);
else $numPendingTables = 0;
if(isset($_REQUEST[$table])){
  list($success, $msg, $id) = updateRecord($db, $table, $d[$table], $updateId);
  if($success){
    unset($d[$table]);
    if($numPendingTables>0){
      // pop one off the previous table stack.
      $table = array_pop($prevTable);
    }
    if(isset($extras["returnURL"]) && $numPendingTables==0){
      if (strpos(urldecode($extras["returnURL"]),'?')===FALSE) $urlChar = "?";
      else $urlChar = "&";
      if(isset($extras["returnIdName"]))
	header("Location: ".$returnURL.$urlChar.$extras["returnIdName"]."=".$id);
      else
	header("Location: ".$returnURL.$urlChar."id=".$id); 
      exit;
    }
  }
}elseif(isset($_REQUEST["cancel"])){
  $msg = "Cancelled insert/update for table $table.";
  unset($d[$table]);
  if($numPendingTables>0){
    // pop one off the previous table stack.
    $table = array_pop($prevTable);
  }
  if(isset($extras["returnURL"]) && $numPendingTables==0){
    header("Location: ".$returnURL);
    exit;
  }
}
foreach($_REQUEST as $key=>$val){
  if($val=="New"){
    if(isset($prevTable) && is_array($prevTable))
      array_push($prevTable, $table);
    else
      $prevTable = array($table);
    $table = $key;
  }
}
if($deleteId!=0){
	if($numPendingTables>0){
		$msg .= " Refusing to process delete- there are pending tables.";
	}else{
		list($success, $m) = deleteRecord($db, $table, $deleteId);
		if(strlen($msg>0)) $msg .= " / ".$m; else $msg = $m;
		// We do a redirect so that the 'deleteId' won't remain in the url.
		// *** RFD: There's got to be a better way!
		header("Location: ".$_SERVER["PHP_SELF"]."?table=".$table."&msg=".urlencode($msg));
		exit;
	}
}
if(isset($_REQUEST["updateId"]))
  $d[$table]['id'] = $_REQUEST["updateId"];
else 
  $d[$table]['id'] = 0;

// Here we actually start writing the HTML.
writeHeader("Edit $table", "secure", $msg);
wizardHeader(1);
if($d[$table]['id']!=0) echo "<h1>Update entry in table '$table':</h1>\n";
else echo "<p><font size=+1><b>Add entry to table '$table':</b></font></p>\n";

$selfUrl = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];
// The following function requires the non-trivial code above to process the
// data, so I'm not sure that it makes sense to keep it in a separate function.
echo buildFormFromTable($db, $table, $prevTable, $selfUrl, $d, $extras, $defaultDataId);

writeFooter('basic');
?>
