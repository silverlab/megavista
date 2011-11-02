<?php
require_once("include.php");
//init_session();
login();
writeHeader("Get Data Files", "secure");
$secureUrlBase = "https://".$_SERVER['HTTP_HOST'].dirname($_SERVER['PHP_SELF'])."/";

if(!isset($_REQUEST["scanner"])) $scanner = "lucas15t";
else $scanner = $_REQUEST["scanner"];
$ifileServer = $GLOBALS["conf"]->rawDataSrc["lucas"]->user."@".$GLOBALS["conf"]->rawDataSrc["lucas"]->host;
$src = $GLOBALS["conf"]->rawDataSrc[$scanner];

if(!isset($_REQUEST["examNum"])) $examNum = $_REQUEST["examNum"];
if(isset($examNum) && $examNum!=""){
  // Note that for this to work, you must have an ssh private 
  // key stored in the specified place (/var/www/.ssh/id_dsa).
  // The public component of this key needs to be entered into 
  // the /home/wandell/.shh/authorized_hosts file on lucas.
  // ("ssh-keygen -t rsa -f /var/www/.ssh/id_dsa" will make the keys.)
  $series = `ssh -i /var/www/.ssh/id_dsa -o "StrictHostKeyChecking no" $ifileServer listseries -r $src->name $examNum`;
  echo "<p>Scan series from exam <strong>$examNum</strong> on <strong>$src->name</strong>:</p>\n";
  echo "<pre>$series</pre>\n";
} 

$pfileTree = listPfiles($src);
if(!$pfileTree){
	echo "<p class=msg>No P-files found.</p>\n";
}else{
  echo "<p>Files currently in <i>$src->dataDir</i> on <strong>$scanner</strong> ($src->host):</p>\n";
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


function listPfiles($datasrc, $filter=""){
  $con = ftp_connect($datasrc->host) or die("Couldn't connect to $datasrc->host");
  if(!ftp_login($con, $datasrc->user, $datasrc->pwd)){
    trigger_error("ftp login to $datasrc->host failed.");
    $pfileTree = 0;
  }else{
    $rawFiles = ftp_rawlist($con, $datasrc->dataDir);
    foreach($rawFiles as $raw){
      //echo $raw;
      ereg("([-d])([rwxst-]{9}).* ([0-9]*) ([a-zA-Z]+[0-9: ]* [0-9]{2}:?[0-9]{2}) (.+)", 
	   $raw, $regs);
      $files[] = array("is_dir" =>
		       ($regs[1] == "d") ? true : false,
		       "mod" => $regs[2],
		       "size" => $regs[3],
		       "time" => $regs[4],
		       "name" => $regs[5],
		       "raw" => $regs[0]);
    }
    // Find all P-files
    foreach($files as $f){
      if(ereg("^P.*\.7$", basename($f["name"]))){
	$pfiles[] = basename($f["name"]);
      }
    }
    if(count($pfiles)>0){
      // Now find the tree of files associated with each P-file
      foreach($pfiles as $pfileNum=>$pfile){
	foreach($files as $f){
	  if(ereg(".*".$pfile.".*", basename($f["name"]))){
	    $pfileTree[$pfile]->name[] = $f["name"];
	    $pfileTree[$pfile]->size[] = $f["size"];
	    $pfileTree[$pfile]->time[] = $f["time"];
	  }
	}
      }
    }else{
      $pfileTree = 0;
    }
  }
  ftp_quit($con);
  return($pfileTree);
} 
?>
