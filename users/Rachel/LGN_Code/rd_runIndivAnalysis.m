% rd_runIndivAnalysis.m

scanner = '7T';

[subjectDirs3T subjectDirs7T] = rd_lgnSubjects;
switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
    case '7T'
        subjectDirs = subjectDirs7T;
end

% subjects = [1];
subjects = 1:size(subjectDirs,1);
nSubjects = numel(subjects);

% run specified individual analysis script in subject directory
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    [fpath fdir] = rd_getAnalysisFilePath(subjectDirs, scanner, subject);
    
    % go to subject directory
    cd(fdir)
    
    % run script
%     cd ../.. % need to be in subject directory for rd_mrRunUI
%     rd_mrRunUI
    load lgnROI1_indivScanData_multiVoxel_20120415
    for iScan = 1:numel(uiData)
        iScan
        rd_fTestGLM
        close('all')
    end
end