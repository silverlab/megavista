<?php
/*
 * editTable.php
 *
 * eg. editTable?table=sessions
 *
 * Builds an html form to add a new entry to the specfied table.
 * Fields that specify an entry in another table are automatically
 * converted to a pull-down list os all entries in that other table.
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
 *  2003.05.01 ARW (wade@ski.org) wrote it based on RFD's editTable.php.
 */
//echo $table;
require_once("include.php");
//echo $table;
//init_session();
//echo $table;
//if(!isset($table) || $table==""){
$db = login();
//echo $table;
if (isset($_REQUEST["table"]) && $_REQUEST["table"]!="")
  $table = $_REQUEST["table"];
else{
  trigger_error("'table' is not specified.");
  exit;
}
$msg = "Connected as user ".$_SESSION['username'];


writeHeader("Display $table", "secure", $msg);
echo "<h1>Display table '$table':</h1>\n";
$selfURL = "https://".$_SERVER["HTTP_HOST"].$_SERVER["PHP_SELF"];

?>
<hr>
<h1>Existing entries in table '<?=$table?>':</h1>
<?
$tableText = displayTable($db, $table);
if($tableText!=""){
  echo $tableText;
} else {
  echo "<p class=error>No entries found.</p>\n";
}
writeFooter('basic');
?>