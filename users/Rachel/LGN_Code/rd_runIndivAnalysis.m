% rd_runIndivAnalysis.m

scanner = '7T';

[subjectDirs3T subjectDirs7T] = rd_lgnSubjects;
switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
    case '7T'
        subjectDirs = subjectDirs7T;
end

subjects = [3]; % 3T: deal with 2 (AV2), 3 & 4 (CGh/l); 7T: deal with 1 (KS1) and 4 (RD) 
% subjects = 1:size(subjectDirs,1);
nSubjects = numel(subjects);

% run specified individual analysis script in subject directory
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    [fpath fdir] = rd_getAnalysisFilePath(subjectDirs, scanner, subject);
    
    % go to subject directory
    cd(fdir)
    
    % run script
%     % timeCourse or multiVoxel UI
%     cd ../.. % need to be in subject directory for rd_mrRunUI
%     rd_mrRunUI
    
%     % F-tests on indiv scans
%     load lgnROI1_indivScanData_multiVoxel_20120417
%     for iScan = 1:numel(uiData)
%         iScan
%         rd_fTestGLM
%         close('all')
%     end

%     % plot behavioral results
%     cd ../../Behavior
%     behavFile = dir('*behavData.mat');
%     load(behavFile.name)
%     rd_mpLocalizerBehavAcc(behavData);

    % plot behav/F/varExp comparisons
    rd_compareIndivRunStats
    
end