<?php
require_once("include.php");
//init_session();
$db = login();
writeHeader("Get Data Files", "basic");
$secureUrlBase = "https://".$_SERVER['HTTP_HOST'].dirname($_SERVER['PHP_SELF'])."/";


echo "<p class=warn>This is just a place-holder function. When it's finished, you'll be able ";
echo "to select the data files that you want to add and specify if you want them transferred.</p>\n";

if(!isset($_REQUEST["scanner"])) $scanner = "lucas 1.5t";
else $scanner = $_REQUEST["scanner"];
$ifileServer = "wandell@lucas.stanford.edu";
$dataSrc = getDataSourceInfo($scanner);

if(isset($_REQUEST["examNumber"])) $examNumber = $_REQUEST["examNumber"];
else $examNumber = 0;

if($examNumber!=0){
  // Note that for this to work, you must have an ssh private 
  // key stored in the specified place (/var/www/.ssh/id_dsa).
  // The public component of this key needs to be entered into 
  // the /home/wandell/.shh/authorized_hosts file on lucas.
  // ("ssh-keygen -t rsa -f /var/www/.ssh/id_dsa" will make the keys.)
  $series = `ssh -i /var/www/.ssh/id_dsa -o "StrictHostKeyChecking no" $ifileServer listseries -r $dataSramc->name $examNum`;
  echo "<p>Scan series from exam <strong>$examNum</strong> on <strong>$scanner</strong> ($dataSrc->name):</p>\n";
  echo "<pre>$series</pre>\n";
} 

$pfileTree = listPfiles($dataSrc);
if(!$pfileTree){
	echo "<p class=msg>No P-files found on <strong>$scanner</strong> ($dataSrc->name).</p>\n";
}else{
  echo "<p>Files currently in <i>$ftpDataDir</i> on <strong>$scanner</strong> ($dataSrc->name):</p>\n";
	echo "<table border=1 cellspacing=1 cellpadding=4>\n";
	foreach($pfileTree as $pfileName=>$files){
		$filesStr = "";
		$totalSize = 0;
		foreach($files->name as $num=>$f){
			$size = getFileSizeString($files->size[$num]);
			$time = $files->time[$num];
			$filesStr .= basename($f)."($size, $time) ";
			$totalSize += $files->size[$num];
		}
		echo "<tr>\n<td>$pfileName (".getFileSizeString($totalSize)."</td>\n";
		echo "<td>$filesStr</td>\n";
		echo "</tr>\n";
	}
	echo "</table>\n";
}

writeFooter(); 
?>
