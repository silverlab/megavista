% rd_centerOfMassGroupAnalysis.m

%% setup
[subjectDirs3T subjectDirs7T] = rd_lgnSubjects;
            
scanner = '7T';
mapName = 'betaM-P';
prop = 0.5;
analysisExtension = sprintf('centerOfMass_%s_prop%d_*', mapName, round(prop*100));
hemis = [1 2];

plotFigs = 1;
saveAnalysis = 0;

MCol = [220 20 60]./255; % red
PCol = [0 0 205]./255; % medium blue
colors = {MCol, PCol};

switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
    case '7T'
        subjectDirs = subjectDirs7T;
end

subjects = 1:size(subjectDirs,1);
nSubjects = numel(subjects);
            
%% get data from each subject
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    for iHemi = 1:length(hemis)
        hemi = hemis(iHemi);
        
        filePath = rd_getAnalysisFilePath(subjectDirs, scanner, ...
            subject, hemi, analysisExtension);

        data = load(filePath);
        
        groupData.varThreshs(:,iSubject,iHemi) = data.C.varThreshs;
        groupData.centers1(:,:,iSubject,iHemi) = data.C.centers1;
        groupData.centers2(:,:,iSubject,iHemi) = data.C.centers2;
        groupData.nSuperthreshVox(:,iSubject,iHemi) = data.C.nSuperthreshVox;
    end
end

%% mean across subjects
groupMean.varThreshs = squeeze(mean(groupData.varThreshs,2)); % [varThreshs x hemi]
groupMean.centers1 = squeeze(mean(groupData.centers1,3)); % [varThresh x dim x hemi]
groupMean.centers2 = squeeze(mean(groupData.centers2,3)); % [varThresh x dim x hemi]
groupMean.nSuperthreshVox = squeeze(mean(groupData.nSuperthreshVox,2)); % [varThreshs x hemi]

%% standard deviation/error across subjects
groupStd.varThreshs = squeeze(std(groupData.varThreshs,0,2)); % [varThreshs x hemi]
groupStd.centers1 = squeeze(std(groupData.centers1,0,3)); % [varThresh x dim x hemi]
groupStd.centers2 = squeeze(std(groupData.centers2,0,3)); % [varThresh x dim x hemi]
groupStd.nSuperthreshVox = squeeze(std(groupData.nSuperthreshVox,0,2)); % [varThreshs x hemi]

fn = fieldnames(groupStd);
for iFn = 1:numel(fn)
    groupSte.(fn{iFn}) = groupStd.(fn{iFn})./sqrt(nSubjects);
end

%% NORMALIZATION
%% normalize coordinates by mean coordinates for each subject
nThresh = numel(data.C.varThreshs);
meanCenters1 = repmat(mean(groupData.centers1,1),[nThresh,1,1,1]);
meanCenters2 = repmat(mean(groupData.centers2,1),[nThresh,1,1,1]);

normData.centers1 = groupData.centers1 - meanCenters1;
normData.centers2 = groupData.centers2 - meanCenters2;

%% mean of normalized data across subjects
normMean.varThreshs = squeeze(mean(normData.varThreshs,2)); % [varThreshs x hemi]
normMean.centers1 = squeeze(mean(normData.centers1,3)); % [varThresh x dim x hemi]
normMean.centers2 = squeeze(mean(normData.centers2,3)); % [varThresh x dim x hemi]
normMean.nSuperthreshVox = squeeze(mean(normData.nSuperthreshVox,2)); % [varThreshs x hemi]

%% standard deviation/error of normalized dataacross subjects
normStd.varThreshs = squeeze(std(normData.varThreshs,0,2)); % [varThreshs x hemi]
normStd.centers1 = squeeze(std(normData.centers1,0,3)); % [varThresh x dim x hemi]
normStd.centers2 = squeeze(std(normData.centers2,0,3)); % [varThresh x dim x hemi]
normStd.nSuperthreshVox = squeeze(std(normData.nSuperthreshVox,0,2)); % [varThreshs x hemi]

fn = fieldnames(groupStd);
for iFn = 1:numel(fn)
    normSte.(fn{iFn}) = normStd.(fn{iFn})./sqrt(nSubjects);
end

