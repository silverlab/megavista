<?php
require_once("include.php");
//init_session();
$db = login();
writeHeader("Home", "basic");

?>
<h1>Welcome to mrData!</h1>
<p>What would you like to do?</p>
<ul>
<li><b><font size=+2><a href="buildSession1.php">Run Scan Session Wizard</a></li>
<hr>
<li><a href="studyBrowser.php">Browse Studies</a></li>
<li><a href="subjectBrowser.php">Browse Subjects</a></li>
<hr>
<li><a href="generalsearchMrData.php">General Search</a></li>
<li><a href="advancedsearchMrData.php">Advanced Search</a></li>
</font></b>
<hr>
<li><a href="indexadvanced.php">Access advanced index</a></li>
<hr>
</ul>
<p>Note that you will need to enter a username and password to access mrData.
Contact Bob to get started.</p>

<?php writeFooter(); ?>
