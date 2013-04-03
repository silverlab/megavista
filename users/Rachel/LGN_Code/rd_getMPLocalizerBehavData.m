% rd_getMPLocalizerBehavData.m

saveData = 1;

[exptFileDirs, exptFilePaths] = rd_lgnExptFilesPaths;

% subjects = 1;
subjects = 1:length(exptFilePaths);

for iSubject = 1:numel(subjects);
    subject = subjects(iSubject);
    
    behavFiles = dir(sprintf('%s/data/mpLocalizer*%s*', ...
        exptFilePaths{subject}, exptFileDirs{subject,1}(1:2)));
    
    clear behavData
    for iRun = 1:numel(behavFiles)
        behavFileName = behavFiles(iRun).name;
        fprintf('%s\n', behavFileName)
        behavData(iRun) = load(sprintf('%s/data/%s', exptFilePaths{subject}, behavFileName));
    end
    fprintf('\n')
    
    if saveData
        save(sprintf('~/Desktop/%s_behavData.mat', exptFileDirs{subject}), 'behavData');
    end
end
