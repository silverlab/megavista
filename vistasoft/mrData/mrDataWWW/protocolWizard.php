<?php
require_once("include.php");
//init_session();
login();
if(!isset($_REQUEST["scanner"])) $scanner = $scannerList[0];
else $scanner = $_REQUEST["scanner"];
$src = $GLOBALS["conf"]->rawDataSrc[$scanner];
$cacheDir = $GLOBALS["conf"]->protocolCacheDir."_".$scanner;
$cacheTime = date("l M j, Y \a\t g:ia T", filemtime($cacheDir));
if(isset($_REQUEST["scanner"]) && isset($_REQUEST["refreshCache"])){
  getAllProtocols($src, $cacheDir);
  // We do a redirect so that the 'refreshCache' flag won't remain in the url.
  header("Location: ".$_SERVER["PHP_SELF"]."?scanner=".urlencode($_REQUEST["scanner"]));
  exit;
}

writeHeader("Protocol Wizard", "secure");

foreach($GLOBALS["conf"]->rawDataSrc as $key=>$val)
  if(isset($val->protocolDir))
    $scannerList[] = $key;

if(isset($_REQUEST["add"]) && isset($_REQUEST["scanner"]) 
   && isset($_REQUEST["cat"]) && isset($_REQUEST["protocol"])){
  $protocol = getCachedProtocol($cacheDir, $_REQUEST["cat"], $_REQUEST["protocol"]);
  echo "<h1>Select a series from ".$protocol['name'].":</h1>\n";
  echo "<ul>\n";
  foreach($protocol['series'] as $sNum=>$s){
    echo "<li>Series $sNum (".$s['sedesc']."):";
    echo "<form method=POST name=\"protocolWizard_form\" action=\"editTable.php\">\n";
    echo "<input type=hidden name=table value=protocols>\n";
    echo "<input type=hidden name=d[protocols][protocolName] value=\"".$protocol['name']."\">\n";
    foreach($s as $name=>$value){
      echo "<input type=hidden name=d[protocols][$name] value=\"$value\">\n";
    }
    echo "<input type=submit name=submit value=\"Add to database...\">\n";
    echo "</form></li>\n";
  }
  echo "</ul>\n";
}elseif(isset($_REQUEST["cat"]) && isset($_REQUEST["protocol"])){
  // SHOW THIS PROTOCOL
  $protocol = getCachedProtocol($cacheDir, $_REQUEST["cat"], $_REQUEST["protocol"]);
  echo "<h1>".$protocol['name']."</h1>";
  echo "<ul>\n";
  foreach($protocol['series'] as $seriesNum=>$series){
    echo "<li>Series $seriesNum</li>\n";
    echo "<ul>\n";
    foreach($series as $name=>$val)
      if($val!="") echo "<li>$name = $val</li>\n";
    echo "</ul>\n";
  }
  echo "</ul>\n";
  //echo "<pre>".$protocol['raw']."</pre>";

}else{
  // LIST ALL PROTOCOLS
  $protocols = listCachedProtocols($cacheDir);
  echo "<p class=msg>Cache for <strong>$scanner</strong> last updated $cacheTime</p>\n";
  if(!$protocols){
    echo "<p class=msg>No Protocols found in cache.</p>\n";
  }else{
    echo "<p>Protocols from <strong>$scanner</strong> ($src->host):</p>\n";
    echo "<table border=1 cellspacing=1 cellpadding=4>\n";
    echo "<tr><th>Category</th><th>Name</th><th>Action</th>\n</tr>\n<tr>\n";

    foreach($protocols as $pCatName=>$pCat){
      foreach($pCat as $p){
	echo "<tr>\n<td>$pCatName</td>\n";
	echo "<td>".str_replace('@20',' ',$p)."</td>\n";
	echo "<td><a href=\"".selfURL()."?scanner=$scanner&cat=".urlencode($pCatName)
	  ."&protocol=".urlencode($p)."\">display</a> | \n";
	echo "<a href=\"".selfURL()."?scanner=$scanner&add=1&cat=".urlencode($pCatName)
	  ."&protocol=".urlencode($p)."\">add to mrData</a></td>\n";
	echo "</tr>\n";
      }
    }
    echo "</table>\n";
  }
  echo "<ul>\n";
  foreach($scannerList as $s){
    echo "<li><a href=\"".$_SERVER["PHP_SELF"]."?scanner=".urlencode($s)."&refreshCache=1\">";
    echo "Refresh protocol cache for $s</a></li>\n";
  }
  echo "</ul>\n";
}

writeFooter(); 

function listCachedProtocols($cacheDir){
  $protocolDirs = ls($cacheDir);
  if(count($protocolDirs)>0){
    foreach($protocolDirs as $pdir){
      $curProtocols = ls($cacheDir."/".$pdir);
      if(count($curProtocols)>0){
	foreach($curProtocols as $pname){
	  $protocols[$pdir][] = $pname;
	  //echo basename($pdir)."/".basename($pname)." ";
	}
      }
    }
  }else{
    $protocols = 0;
  }
  return($protocols);
}

function getCachedProtocol($cacheDir, $category, $protocol){
  // Try to prevent rogue users from getting any random file from the server.
  // This should prevent 'category=../../../' style hacks.
  $category = basename($category);
  $protocol = basename($protocol);
  
  $file = $cacheDir."/".$category."/".$protocol;
  //$protStr = file_get_contents($cacheDir."/".$category."/".$protocol);
  $fp = fopen($file,"rt");
  $protStr = fread($fp,filesize($file));
  fclose($fp);

  // PARSE PROTOCOL FILE

  // For debugging:
  //echo "<pre>$protStr</pre>";

  // First, remove the many useless 'GLOBAL' lines
  $protStr = preg_replace("/global .*\n/", "", $protStr);

  // Extract the protocol description fields
  preg_match("/set PROTNAME \"(.*)\"/", $protStr, $matches);
  $p["name"] = $matches[1];
  preg_match("/set REVNO \"(.*)\"/", $protStr, $matches);
  $p["revno"] = $matches[1];
  preg_match("/set SCANNUM \"(.*)\"/", $protStr, $matches);
  $p["scanNum"] = $matches[1];
  preg_match("/set SERIESNUM \"(.*)\"/", $protStr, $matches);
  $p["seriesNum"] = $matches[1];
  // Now, parse each series
  $ser = explode('proc ',$protStr);
  array_shift($ser);
  foreach($ser as $seriesNum=>$seriesStr){
    $tmp = explode('set ',$seriesStr);
    array_shift($tmp);
    foreach($tmp as $paramNum=>$paramStr){
      preg_match("/(.*) \"(.*)\"/", $paramStr, $matches);
      $p['series'][$seriesNum+1][strtolower(trim($matches[1]))] = $matches[2];
      //echo "$seriesNum $matches[1] $p[$seriesNum+1][$matches[1]]";
    }
  }
  return($p);
} 

function getAllProtocols($datasrc, $cacheDir){
  exec("rm -rf $cacheDir");
  mkdir($cacheDir, 0775);
  $protocols = listProtocols($datasrc);
  $con = ftp_connect($datasrc->host) or die("Couldn't connect to $datasrc->host");
  if(!ftp_login($con, $datasrc->user, $datasrc->pwd)){
    trigger_error("ftp login to $datasrc->host failed.");
  }else{
    foreach($protocols as $categoryName=>$protocolList){
      mkdir($cacheDir."/".$categoryName, 0775);
      foreach($protocolList as $p){
	$getFile = $datasrc->protocolDir."/".$categoryName."/".$p;
	$putFile = $cacheDir."/".$categoryName."/".$p;
	$stat = ftp_get($con, $putFile, $getFile, FTP_ASCII);
      }
    }
  }
  ftp_quit($con);
}

function listProtocols($datasrc, $filter=""){
  $con = ftp_connect($datasrc->host) or die("Couldn't connect to $datasrc->host");
  if(!ftp_login($con, $datasrc->user, $datasrc->pwd)){
    trigger_error("ftp login to $datasrc->host failed.");
  }else{
    $protocolDirs = ftp_nlist($con, $datasrc->protocolDir);
    foreach($protocolDirs as $pdir){
      $curProtocols = ftp_nlist($con, $pdir);
      foreach($curProtocols as $pname){
	$protocols[basename($pdir)][] = basename($pname);
	//echo basename($pdir)."/".basename($pname)." ";
      }
    }
  }
  ftp_quit($con);
  return($protocols);
} 

function getProtocol($datasrc, $category, $protocol){
  // Try to prevent rogue users from getting any random file from the server.
  // This should prevent 'category=../../../' style hacks.
  $category = basename($category);
  $protocol = basename($protocol);

  $con = ftp_connect($datasrc->host) or die("Couldn't connect to $datasrc->host");
  if(!ftp_login($con, $datasrc->user, $datasrc->pwd)){
    trigger_error("ftp login to $datasrc->host failed.");
  }else{
    $temp = tmpfile();
    $getFile = $datasrc->protocolDir."/".$category."/".$protocol;
    $stat = ftp_fget($con, $temp, $getFile, FTP_ASCII);
    rewind ($temp);
    $protStr = fread($temp,1000000);
    fclose($temp);
  }
  ftp_quit($con);
  
  // PARSE PROTOCOL FILE

  // For debugging:
  //echo "<pre>$protStr</pre>";

  // First, remove the many useless 'GLOBAL' lines
  $protStr = preg_replace("/global .*\n/", "", $protStr);

  // Extract the protocol description fields
  preg_match("/set PROTNAME \"(.*)\"/", $protStr, $matches);
  $p["name"] = $matches[1];
  preg_match("/set REVNO \"(.*)\"/", $protStr, $matches);
  $p["revno"] = $matches[1];
  preg_match("/set SCANNUM \"(.*)\"/", $protStr, $matches);
  $p["scanNum"] = $matches[1];
  preg_match("/set SERIESNUM \"(.*)\"/", $protStr, $matches);
  $p["seriesNum"] = $matches[1];
  // Now, parse each series
  $ser = explode('proc ',$protStr);
  array_shift($ser);
  foreach($ser as $seriesNum=>$seriesStr){
    $tmp = explode('set ',$seriesStr);
    array_shift($tmp);
    foreach($tmp as $paramNum=>$paramStr){
      preg_match("/(.*) \"(.*)\"/", $paramStr, $matches);
      $p['series'][$seriesNum+1][strtolower(trim($matches[1]))] = $matches[2];
      //echo "$seriesNum $matches[1] $p[$seriesNum+1][$matches[1]]";
    }
  }
  
  return($p);
} 
?>
