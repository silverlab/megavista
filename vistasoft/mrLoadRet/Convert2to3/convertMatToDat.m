function convertMatToDat(tSeriesPath)
% function convertMatToDat(tSeriesPath)
%
% This routine changes the tSeries from mat to dat format.
%
% 98.12.23 - Written by Bill and Bob.
%
% agp, 01/13/99
% modified so that the function doesn't exit on error when an empty Scan 
% directory is encoutered.
% 
% djh, 2/17/2001
% - eliminated change directories, using fullfile instead
% - eliminated 'dir', using countFiles instead
% - eliminated tSeries.dat files because thay are no longer more efficient 
%   than matlab's .mat files

global mrSESSION
global HOMEDIR

if isempty(mrSESSION)
    loadSession;
end
if ~exist('tSeriesPath','var')
    tSeriesPath = fullfile(HOMEDIR,'Inplane','Original','TSeries')
end

nFrames = mrSESSION.nFrames;
nRows = mrSESSION.cropInplaneSize(1);
nCols = mrSESSION.cropInplaneSize(2);

[numScans,scanDirList] = countDirs('Scan*',tSeriesPath);
if numScans==0
    disp(['Hey! There are not in tSeries files here:',tSeriesPath]);
    break
end
for scan=1:numScans
    disp(['Scan num: ' num2str(scan)]);
    dirPath = fullfile(tSeriesPath,scanDirList{scan});
    [numSlices,fileList] = countFiles('tSeries*.mat',dirPath);
    for slice=1:numSlices
        disp(['Slice num: ' num2str(slice)]);
        tSeriesName = strtok(fileList{slice},'.'); % Strip off extension
        matFileName = fullfile(dirPath,[tSeriesName '.mat']);
        datFileName = fullfile(dirPath,[tSeriesName '.dat']);
        if exist(matFileName,'file')
            load(matFileName);
            nVals = prod(size(tSeries));
        else
            disp(['Hey!  There are not any .mat tSeries here:',dirPath]);
        end
        
        if round(nVals/nFrames) ~= nVals/nFrames
            error('nVals/nFrames is not an integer!');
        end
        
        if nFrames ~= size(tSeries,1)
            disp('WARNING: nFrames ~= size(tSeries,1).');
        end
        disp('Finished reading old tSeries- now writting out new file.');
        %savetSeriesDat(datFileName,tSeries,nRows,nCols);
        savetSeriesDat(datFileName,tSeries);
        
        delete(matFileName);
    end
end
