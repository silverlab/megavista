function [filePath, fileDirectory, fileName] = rd_getAnalysisFilePath(subjectDirs, scanner, subject, hemi, analysisExtension)
%
% function filePath = rd_getAnalysisFilePath(subjectDirs, scanner, subject, hemi, analysisExtension)
%
% gets the filepath to a specific analysis file for any subject and
% hemisphere. if no analysis file is specified, will still return the file
% directory.

allowWildcardExtension = 1;

if nargin >= 5
    analysisFileSpecified = 1;
else
    analysisFileSpecified = 0;
end

subjectDir{1} = subjectDirs{subject,1};
subjectDir{2} = subjectDirs{subject,2};
subjectDir{3} = subjectDirs{subject,3};

fileDirectory = sprintf('/Volumes/Plata1/LGN/Scans/%s/%s/%s/ROIAnalysis/%s',...
    scanner, subjectDir{1}, subjectDir{2}, subjectDir{3});

if analysisFileSpecified
    fileBase = sprintf('lgnROI%d', hemi);
    
    if allowWildcardExtension
        dataDir = dir(sprintf('%s/%s_%s*.mat', ...
            fileDirectory, fileBase, analysisExtension));
    else
        dataDir = dir(sprintf('%s/%s_%s.mat', ...
            fileDirectory, fileBase, analysisExtension));
    end
    
    % give an error if there are too many or too few matching files
    if numel(dataDir)==0
        error('Zero matches for the requested file, %s.', analysisExtension)
    elseif numel(dataDir)>1
        error('Too many matches for the requested file, %s.', analysisExtension)
    end

    fileName = dataDir.name;
    
    filePath = sprintf('%s/%s', fileDirectory, fileName);
else
    fileName = [];
    filePath = [];
end
