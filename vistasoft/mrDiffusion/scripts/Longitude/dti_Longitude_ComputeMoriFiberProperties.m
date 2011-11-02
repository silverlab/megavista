function dti_Longitude_ComputeMoriFiberProperties

%For all subjects with 4 years of DTI data /biac3/wandell4/users/elenary/longitudinal/subjectCodesAll4Years
%Compute Fiber Properties for each of the fiber subgroup within allConnectingGM_MoriGroups_DN.mat (initial BM solution) &
%allConnectingGM_DN_MoriGroups.mat (full brain BM solution, mori-classified "BM-selected" fibers)

%This is not a function but a script -- parameters are defined within.

%The results are structured as Davie chose in dtiFiberSummaryNoGUI
% summary(S) = 1 x S struct with fields:
%                                         subject
%                                         sfg
%Here sfg is a subgroup of fibers corresponding to MoriGroup

%summary(S).sfg is a 1x(NumberOfFiberGroups+1) struct array with fields:
%    name
%    numberOfFibers
%    fiberLength
%    FA
%    MD
%    axialADC
%    radialADC
%    linearity
%    planarity
%    fiberGroupVolume

%02/02/2009 ER wrote it
%01/11/2009 ER rewrote it for a more general case to accomodate a variety
%of MoriGroup sets whose properties were evaluated. 
%
minDist=2; %relevant for Roi2Roi_only approach
%1. Specify parameters
resultsDir='/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups';
datadir='/biac3/wandell4/data/reading_longitude/dti_y1234';

%To compute mori dibers for adults
%datadir='/biac3/wandell4/data/reading_longitude/dti_adults';


%For the analyses I want to run, specified input, output files and fiber
%and diameter. 
Analysis = struct('subjectCodesFile', {'/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years', ...
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years', ...
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years', ...
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years', ...
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years', ...
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years', ...
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years', ...
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodes3Adults.mat', ...%%To compute mori fibers for adults
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesY1.mat', ...%%To compute mori fibers for Y1
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years.mat', ...
				    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodes3Adults.mat', ...%%To compute mori fibers for adults
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years', ...
                                    '/biac3/wandell4/users/elenary/longitudinal/data/subjectCodes2Adults4repeats.mat'}, ...
                  'fgFile', {'allConnectingGM_MoriGroups_DN.mat',... % names for the fiber groups of interest
                             'allConnectingGM_DN_MoriGroups.mat',...
                             'allConnectingGM_MoriGroups_DN.mat',...
                             'allConnectingGM_DN_MoriGroups.mat',...
                             'allConnectingGM_MoriGroups.mat', ...
                             'MoriGroups.mat', ...
                             'MoriSymmGroupsCulled.mat',...
                             'MoriGroups.mat', ...
                             'MoriGroups.mat', ...
                             'nonMori.mat',...
                             'allConnectingGM_DN_MoriGroups.mat', ...
                                'MoriGroups.mat', ...
                             'MoriGroups.mat'},...
                              ... % names for the output summary file
                  'summaryFiberPropertiesFile', {'summaryFiberPropertiesMoriGroups_DN_volumeUniqueVoxels', ...
                                                 'summaryFiberProperties_DN_MoriGroups_volumeUniqueVoxels',...
                                                 'summaryFiberPropertiesMoriGroups_DN', ...
                                                 'summaryFiberProperties_DN_MoriGroups',...
                                                 'summaryFiberPropertiesAllConnectingGmMoriGroups_volumeUniqueVoxels', ...
                                                 'summaryFiberPropertiesMoriGroups_volumeUniqueVoxels', ...
                                                 'summaryFiberPropertiesMoriSymm', ...
                                                 'summaryFiberPropertiesMoriGroups_volumeUniqueVoxels_adults.mat', ...
                                                 'summaryFiberPropertiesMoriGroups_volumeUniqueVoxels_Y1.mat', ...
                                                 'summaryFiberPropertiesNonMori_volumeUniqueVoxels',...
                                                 'summaryFiberPropertiesDN_MoriGroups_volumeUniqueVoxels_adults.mat', ...
                                                 'summaryFiberPropertiesMoriGroups_Roi2RoiVolumeUniqueVoxels', ...
                                                 'summaryFiberPropertiesMoriGroups_volumeUniqueVoxels_2adults4repeats.mat'}, ...
                              ...
  'fiberDiameter', {[], [], .2, .2, [], [], 1.7, [], [], [], .2, [], []}); 
Roi2RoiOnly={false, false, false, false, false, false, false, false, false, false, false, true, false}; %Properties will be collected only from the ROI2ROI segments of Mori Tracts. 
global moriRois;
moriRois={'ATR_roi1_L.mat',  'ATR_roi2_L.mat'; 'ATR_roi1_R.mat', 'ATR_roi2_R.mat'; ...
        'CST_roi1_L.mat', 'CST_roi2_L.mat'; 'CST_roi1_R.mat',  'CST_roi2_R.mat'; ...
        'CGC_roi1_L.mat', 'CGC_roi2_L.mat'; 'CGC_roi1_R.mat', 'CGC_roi2_R.mat'; ...
        'HCC_roi1_L.mat', 'HCC_roi2_L.mat'; 'HCC_roi1_R.mat', 'HCC_roi2_R.mat';...
        'FP_R.mat', 'FP_L.mat'; ...
        'FA_L.mat', 'FA_R.mat'; ...
        'IFO_roi1_L.mat', 'IFO_roi2_L.mat'; 'IFO_roi2_R.mat', 'IFO_roi1_R.mat'; ...
        'ILF_roi1_L.mat', 'ILF_roi2_L.mat'; 'ILF_roi1_R.mat', 'ILF_roi2_R.mat'; ...
        'SLF_roi1_L.mat', 'SLF_roi2_L.mat'; 'SLF_roi1_R.mat', 'SLF_roi2_R.mat'; ...
        'UNC_roi1_L.mat', 'UNC_roi2_L.mat'; 'UNC_roi1_R.mat', 'UNC_roi2_R.mat'; ...
        'SLF_roi1_L.mat', 'SLFt_roi2_L.mat'; 'SLF_roi1_R.mat', 'SLFt_roi2_R.mat'}; %This will be used only if the flag ifRoi2RoiOnly above is set to "true"

% For DN (BM) files, fiberDiameter=.2; %Is that so? The data were ran with parameter fiberDiameter (trueSA) of .2mm. 
%distanceCrit of 1.7 was used for culling MoriGroups obtained using symmetrified Mori Atlas. 
AnalysesToPerform=[12]; 

%2. Perform analyses
cd(datadir);


for A=AnalysesToPerform
  dtiComputeFiberProperties_batch(Analysis(A).subjectCodesFile, datadir, Analysis(A).fgFile, resultsDir, Analysis(A).summaryFiberPropertiesFile, Analysis(A).fiberDiameter,Roi2RoiOnly{A}, minDist );
end

end

function dtiComputeFiberProperties_batch(subjectCodesFile, datadir, fgFile, resultsDir, summaryFiberPropertiesFile, fiberDiameter, Roi2RoiOnly,  minDist)
global moriRois;      
  load(subjectCodesFile);
        summary = struct('subject',{},'sfg',{}); % intialize SUMMARY
        % To get the labels for the 20 groups (actually MoriGroups generated for
        % all subjects include only 18 groups)

        labels = readTab(which('MNI_JHU_tracts_prob.txt'),',',false);
        labels = labels(:,2);

        fprintf(['Subjects total: ' num2str(length(subjectCodes)) '\n']);
        fprintf('Processing: ');

        for s=1:length(subjectCodes)

            summary(s).subject=fullfile(datadir, subjectCodes{s}, 'dti06trilinrt', 'fibers', fgFile);
            fprintf(1, '%s\n', subjectCodes{s});

            dt6File=fullfile(subjectCodes{s}, 'dti06trilinrt', 'dt6.mat');
            [dt, t1]=dtiLoadDt6(dt6File);
            if ~isfield(dt.files, 't1')
             dt.files.t1=fullfile(fileparts(fileparts(fileparts(dt.files.b0))), 't1', 't1.nii.gz');
             t1=readFileNifti(dt.files.t1); 
             t1.xformToAcpc =t1.qto_xyz;
            end
            partialVolumeMapsFilename=fullfile(datadir, subjectCodes{s}, 'dti06trilinrt', 'fibers', [prefix(fgFile) '_PV.nii.gz']);

            fg=dtiLoadFiberGroup(summary(s).subject); %Load fibers; Mori groups are still in acpc space

	    if Roi2RoiOnly
fprintf(1, 'The properties will be computed only on Roi2Roi segments of Mori fibers\n'); 
fgMoriClipped=dtiNewFiberGroup([fg.name '_clipped']); 
fgMoriClipped.subgroupNames=fg.subgroupNames; 

fgArray=dtiFiberGroupToFgArray(fg);
fgMoriClipped.subgroup=[];
subFGIDs=unique(fg.subgroup);
for subFGid = 1:length(subFGIDs) 
    
		roi1=dtiReadRoi(fullfile(fileparts(dt6File), 'ROIs', moriRois{subFGIDs(subFGid), 1})); 
                roi2=dtiReadRoi(fullfile(fileparts(dt6File), 'ROIs', moriRois{subFGIDs(subFGid), 2})); 
fgTemp = dtiClipFiberGroupToROIs(fgArray(subFGid), roi1, roi2, minDist); 
fgMoriClipped.fibers=[fgMoriClipped.fibers; fgTemp.fibers]; 
fgMoriClipped.subgroup=[fgMoriClipped.subgroup repmat(subFGIDs(subFGid), [1 length(fgTemp.fibers)])]; 
end
fg=fgMoriClipped; 
end

            [summary(s).sfg, partialVolumeImg] = dtiFiberProperties(fg, dt,[], fiberDiameter);
            dtiWriteNiftiWrapper(double(partialVolumeImg), t1.xformToAcpc, partialVolumeMapsFilename) ;   
            save(fullfile(resultsDir, summaryFiberPropertiesFile), 'summary');  %Remember: first one will be "ALL MORI GROUPS");

        end
end

%%%%%%%%%%%%%%%%%%%%%%
% %Code to collect reproduceability data (data not there yet)
% 
% subjectID={'at040918', 'at051008', 'at060825', 'at070815'};
% project_folder='/biac3/wandell4/data/reading_longitude/dti_y1234/';
% fiberDiameter=.2;
% for s=1:4
%     
% cd([project_folder subjectID{s}]);
% for trial=1:10
% fgname=fullfile(project_folder, subjectID{s}, 'dti06trilinrt', 'fibers', ['allConnectingGM_MoriGroups_DN' num2str(trial) '.mat']);
% fg=dtiLoadFiberGroup(fgname); %Load fibers; Mori groups are still in acpc space    
% dt=dtiLoadDt6(fullfile(project_folder, subjectID{s}, 'dti06trilinrt', 'dt6.mat'));
% relsummary(s, trial).sfg=dtiFiberProperties(fg, dt,[], fiberDiameter);
% 
% end
% 
% end
% cd /biac3/wandell4/users/elenary/longitudinal/
% save(['reliabilityFiberPropertiesMori_DN'], 'relsummary');  %Remember: first one will be "ALL MORI GROUPS");

