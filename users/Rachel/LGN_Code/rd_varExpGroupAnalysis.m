% rd_varExpGroupAnalysis.m

%% setup
subjectDirs3T = {'AV_20111117_session', 'AV_20111117_n', 'ROIX01';
                'AV_20111128_session', 'AV_20111128_n', 'ROIX01/Runs1-9';
                'CG_20120130_session', 'CG_20120130_n_LOW', 'ROIX01';
                'CG_20120130_session', 'CG_20120130_n_HIGH', 'ROIX01';
                'RD_20120205_session', 'RD_20120205_n', 'ROIX01'};
            
subjectDirs7T = {'KS_20111212_Session', 'KS_20111212_15mm', 'ROIX01';
                'AV_20111213_Session', 'AV_20111213', 'ROIX01';
                'KS_20111214_Session', 'KS_20111214', 'ROIX01';
                'RD_20111214_Session', 'RD_20111214', 'ROIX01'};
            
scanner = '7T';

hemis = [1 2];

plotFigs = 1;

switch scanner
    case '3T'
        subjectDirs = subjectDirs3T;
    case '7T'
        subjectDirs = subjectDirs7T;
end

subjects = 1:size(subjectDirs,1);
nSubjects = numel(subjects);

for iSubject = 1:nSubjects
    subjectIDs{iSubject} = subjectDirs{iSubject,2};
end
            
%% get data from each subject
for iSubject = 1:nSubjects
    subject = subjects(iSubject);
    
    for iHemi = 1:length(hemis)
        hemi = hemis(iHemi);
        
        subjectDir{1} = subjectDirs{subject,1};
        subjectDir{2} = subjectDirs{subject,2};
        subjectDir{3} = subjectDirs{subject,3};
        
        fileDirectory = sprintf('/Volumes/Plata1/LGN/Scans/%s/%s/%s/ROIAnalysis/%s',...
            scanner, subjectDir{1}, subjectDir{2}, subjectDir{3});
        
        fileBase = sprintf('lgnROI%d', hemi);
        analysisExtension = 'multiVoxFigData';
        
        data = load(sprintf('%s/%s_%s.mat', ...
            fileDirectory, fileBase, analysisExtension));
        
        varExp = data.figData.glm.varianceExplained;
        
        varExpMean(iSubject, iHemi) = mean(varExp);
        varExpStd(iSubject, iHemi) = std(varExp);
        nVox(iSubject, iHemi) = numel(varExp);
        
    end
end

%% plot figs
if plotFigs
    figure
    h = barweb(varExpMean, varExpStd./sqrt(nVox), [], subjectIDs, ...
        scanner,[],'prop. variance explained', [.3 .3 .3; .7 .7 .7], [], {'Hemi 1','Hemi 2'});

    set(h.legend,'location','NorthWest')
end

save(sprintf('/Volumes/Plata1/LGN/Group_Analyses/groupVarExp_%s_N%d_%s.mat',...
    scanner, nSubjects, datestr(now,'YYYYMMDD')), ...
    'varExpMean', 'varExpStd', 'nVox', 'scanner', ...
    'subjectDirs7T', 'subjects', 'hemis');

