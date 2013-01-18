% rd_adjustIndivScanData.m

% excluding runs from indiv scan data
oldRunsString = '1-7'; % RD 7T '1-12', KS 7T2 '1-7'
newRuns = [1 3:7]; % RD 7T 2:12, KS [1 3:7]
newRunsString = '1.3-7'; % RD 7T '2-12', KS '1.3-7'
for hemi = 1:2
    for analysisName = {'multiVoxel','timeCourse'}
        origFile = sprintf('lgnROI%d_indivScanData_%s_20120417.mat', hemi, analysisName{1});
        safeFile = sprintf('OLD_lgnROI%d_indivScanData_%s_20120417_runs%s.mat',...
            hemi, analysisName{1}, oldRunsString);
        newFile = sprintf('lgnROI%d_indivScanData_%s_20130113_runs%s.mat',...
            hemi, analysisName{1}, newRunsString);
        
        load(origFile)
        system(sprintf('mv %s %s', origFile, safeFile))
        uiData = uiData(newRuns);
        save(newFile, 'uiData')
    end
end