# phpMyAdmin MySQL-Dump
# version 2.4.0-rc1
# http://www.phpmyadmin.net/ (download page)
#
# Host: localhost
# Generation Time: May 02, 2003 at 02:03 PM
# Server version: 3.23.54
# PHP Version: 4.2.2
# Database : `mrDataDB`

#
# Dumping data for table `analyses`
#


#
# Dumping data for table `dataFiles`
#


#
# Dumping data for table `displayCalibration`
#


#
# Dumping data for table `displays`
#

INSERT INTO displays VALUES (1, '3t projector', 'Projecting onto fmriCoil built in screen');

#
# Dumping data for table `grants`
#

INSERT INTO grants VALUES (1, 'NIH', 'WAND1F', 2, '2003-05-02', '2003-05-02', '0.00', 'Color mechanisms');

#
# Dumping data for table `people`
#

INSERT INTO people VALUES (1, 'Alex', 'Wade', 'SKI', 'wade@ski.org', 'wade', '1972-03-17', '2003-05-02', 'test', 'no');
INSERT INTO people VALUES (2, 'Brian', 'Wandell', 'Stanford', 'brian@white.stanford.edu', 'brian', '1952-12-10', '2003-05-02', 'PI', '');

#
# Dumping data for table `scans`
#

INSERT INTO scans VALUES (1, '', 'Localizer', 'On/off checkerboard ', '6 cycles, 24 secs/cycles, full contrast, 4Hz flicker, 20degs diameter', 1, 1, 'Retinotopy');

#
# Dumping data for table `sessions`
#

INSERT INTO sessions VALUES (1, '', '2003-05-02 18:00:00', '2003-05-02 21:00:00', 0, 2, 1, 1, 'test', 1, 1, 'Lucas 1.5T');

#
# Dumping data for table `studies`
#

INSERT INTO studies VALUES (1, 'ColNIH', 'NIH Color investigation', 0, 'color computations in human cortex', 'Test');

#
# Dumping data for table `xAnalysesDataFiles`
#


#
# Dumping data for table `xAnalysesScans`
#


#
# Dumping data for table `xLinks`
#

INSERT INTO xLinks VALUES ('dataFiles', 'scanID', 'scans', 'id');
INSERT INTO xLinks VALUES ('dataFiles', 'ownerID', 'people', 'id');
INSERT INTO xLinks VALUES ('displayCalibration', 'displayID', 'displays', 'id');
INSERT INTO xLinks VALUES ('displayCalibration', 'measuredBy', 'people', 'id');
INSERT INTO xLinks VALUES ('grants', 'principalID', 'people', 'id');
INSERT INTO xLinks VALUES ('scans', 'sessionID', 'sessions', 'id');
INSERT INTO xLinks VALUES ('scans', 'primaryStudyID', 'studies', 'id');
INSERT INTO xLinks VALUES ('sessions', 'displayID', 'displays', 'id');
INSERT INTO xLinks VALUES ('sessions', 'subjectID', 'people', 'id');
INSERT INTO xLinks VALUES ('sessions', 'operatorID', 'people', 'id');
INSERT INTO xLinks VALUES ('sessions', 'primaryStudyID', 'studies', 'id');
INSERT INTO xLinks VALUES ('sessions', 'whoReserved', 'people', 'id');
INSERT INTO xLinks VALUES ('sessions', 'fundedBy', 'grants', 'id');
INSERT INTO xLinks VALUES ('studies', 'contactID', 'people', 'id');
INSERT INTO xLinks VALUES ('analyses', 'analyzerID', 'people', 'id');
INSERT INTO xLinks VALUES ('xAnalysesScans', 'analysisID', 'analyses', 'id');
INSERT INTO xLinks VALUES ('xAnalysesScans', 'scanID', 'scans', 'id');
INSERT INTO xLinks VALUES ('xAnalysesDataFiles', 'analysisID', 'analyses', 'id');
INSERT INTO xLinks VALUES ('xAnalysesDataFiles', 'dataFileID', 'dataFiles', 'id');
INSERT INTO xLinks VALUES ('xStudiesAnalyses', 'studyID', 'studies', 'id');
INSERT INTO xLinks VALUES ('xStudiesAnalyses', 'analysisID', 'analyses', 'id');

#
# Dumping data for table `xStudiesAnalyses`
#