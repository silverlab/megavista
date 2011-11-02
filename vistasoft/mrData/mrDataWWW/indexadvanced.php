<?php
require_once("include.php");
//init_session();
$db = login();
writeHeader("Home", "basic");

?>
<h1>mrData advanced index</h1>
<ul>
<li><a href="editTable.php?table=studies">Edit studies</a></li>
<li><a href="editTable.php?table=rois">Edit ROIs</a></li>
<li><a href="editTable.php?table=subjects">Edit subjects</a></li>
<li><a href="editTable.php?table=users">Edit users</a></li>
<li><a href="editTable.php?table=sessions">Edit sessions</a></li>
<li><a href="editTable.php?table=scans">Edit scans</a></li>
<li><a href="editTable.php?table=stimuli">Edit stimuli</a></li>
<li><a href="editTable.php?table=protocols">Edit protocols</a></li>
<li><a href="editTable.php?table=dataFiles">Edit datafiles</a></li>
<li><a href="editTable.php?table=analyses">Edit analyses</a></li>
<hr>
<li><a href="displayTable.php?table=studies">Show studies</a></li>
<li><a href="displayTable.php?table=rois">Show ROIs</a></li>
<li><a href="displayTable.php?table=subjects">Show subjects</a></li>
<li><a href="displayTable.php?table=users">Show users</a></li>
<li><a href="displayTable.php?table=scans">Show scans</a></li>
<li><a href="displayTable.php?table=protocols">Show scan protocols</a></li>
<li><a href="displayTable.php?table=sessions">Show sessions</a></li>
<li><a href="displayTable.php?table=dataFiles">Show data files</a></li>
<li><a href="displayTable.php?table=analyses">Show analyses</a></li>
<hr>
<li><a href="showPfiles.php?scanner=lucas15t">View Lucas 1.5T P-files</a></li>
<li><a href="showPfiles.php?scanner=lucas30t">View Lucas 3.0T P-files</a></li>
<hr>
<li><a href="index.php">Back to main page</a></li>
</ul>

<?php writeFooter(); ?>
