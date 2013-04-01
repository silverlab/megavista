% rd_runIndivAnalysis.m

scanner = '7T';

[subjectDirs3T subjectDirs7T] = rd_lgnSubjectsX09;
switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
    case '7T'
        subjectDirs = subjectDirs7T;
end

subjects = [1 2 3 4 5 7 8];
% subjects = 1:size(subjectDirs,1);
nSubjects = numel(subjects);

% run specified individual analysis script in subject directory
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    [fpath fdir] = rd_getAnalysisFilePath(subjectDirs, scanner, subject);
    
    % go to subject directory
    cd(fdir)
    
    % run script   
%     % reliability sequence
%     % timeCourse or multiVoxel UI
%     cd ../.. % need to be in subject directory for rd_mrRunUI
%     rd_mrRunUI
%
%     rd_mpBetaReliability

%     % F-tests on indiv scans
%     load lgnROI1_indivScanData_multiVoxel_20130315
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

%     % quick plot F stats for indiv runs
%     load lgnROI2_indivRunStats_20120425
%     fO = squeeze(fOverallMeans)';
%     figure; errorbar(mean(fO),std(fO)./sqrt(size(fO,1))); title(subject)
%     fOMeans(iSubject,:) = mean(fO);

%     % aggregate indiv run data from all subjects
%     % (first initialize allData to empty)
%     appendDims = [3 3 3 1 2 1 1];
%     hemi = 2;
%     dataFilePattern = sprintf('lgnROI%d_indivRunStats*', hemi);
%     allData = rd_appendData(dataFilePattern, allData, appendDims);

%     % delete incorrect figures
%     cd figures
%     ls *timeCoursesAdaptation*
%     ok = input('ok to delete? (y/n)','s');
%     if ok
%         !rm *timeCoursesAdaptation*
%     else
%         error('exiting ...')
%     end

%     % *** set cothresh and ROIS in rd_mrRestrictROIs ***
%     cd ../.. % need to be in main session directory
%     rd_mrRestrictROIs
%     cd ROIAnalysis/
%     mkdir ROIX09 figures

%     % calculate ROI volume
%     cd ../.. % need to be in main session directory
%     rois = {'ROI109','ROI209'};
%     roiVolume(iSubject,:) = rd_mrROISize(rois);
%     % save /Volumes/Plata1/LGN/Group_Analyses/roiSizes_7T_N7_ROIX01_20130329.mat roiVolume rois subjects subjectDirs

%     % run time course and multi voxel analysis for all scans together
%     % *** choose the ROI number in rd_mrRunUIAll ***
%     cd ../.. % need to be in main session directory
%     uiTypes = {'timeCourse','multiVoxel'};
%     for hemi = 1:2
%         for iUI = 1:numel(uiTypes)
%             uiType = uiTypes{iUI};
%             rd_mrRunUIAll
%         end
%     end

%     % center of mass sequence
%     % *** set var exp range in rd_centerOfMass_multiVoxData ***
    for hemi = 1:2
        for mapName = {'betaM-P','betaM','betaP'}
            rd_centerOfMass_multiVoxData(hemi,mapName{1});
            rd_mrXformCentersCoordsToVolCoords(hemi,mapName{1}); % convert to Volume coords
            rd_mrXformCentersVolCoordsToTalCoords(hemi,mapName{1}); % convert to Volume to Talairach coords
            rd_normalizeCenterOfMass(hemi,mapName{1},'Epi'); % choose coords option
            rd_normalizeCenterOfMass(hemi,mapName{1},'Talairach'); % choose coords option
        end
    end
%     close all
    
%     rd_centerOfMassNormGroupAnalysis % (makes the good XZ plots)
%     rd_centerOfMassGroupAnalysis % (used for center of mass interaction)
%     rd_centerOfMassGroupMPInteraction

end


