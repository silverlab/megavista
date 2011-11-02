function convertDatToMat(tSeriesPath)
% function convertDatToMat(tSeriesPath)
%
% This routine changes the tSeries from dat to mat format.
%
% djh, 2/17/2001

global mrSESSION

if isempty(mrSESSION)
    loadSession;
end
if ~exist('tSeriesPath','var')
    tSeriesPath = fullfile(mrSESSION.homeDir,'Inplane','Original','TSeries');
end

nFrames = mrSESSION.nFrames;

[numScans,scanDirList] = countDirs('Scan*',tSeriesPath);
if numScans==0
    disp(['Hey! There are not any tSeries files here: ',tSeriesPath]);
    return
end
for scan=1:numScans
    disp(['Converting dat to mat, scan num: ' num2str(scan)]);
    dirPath = fullfile(tSeriesPath,scanDirList{scan});
    [numSlices,fileList] = countFiles('tSeries*.dat',dirPath);        
    for slice=1:numSlices
        disp(['Slice num: ' num2str(slice)]);
        tSeriesName = strtok(fileList{slice},'.'); % Strip off extension
        matFileName = fullfile(dirPath,[tSeriesName '.mat']);
        datFileName = fullfile(dirPath,[tSeriesName '.dat']);
        if exist(datFileName,'file')
            tSeries = loadtSeriesDat(datFileName);
        else
            disp(['Hey!  There are not any .dat tSeries here:',dirPath]);
        end
        
        if nFrames ~= size(tSeries,1)
            disp('WARNING: nFrames ~= size(tSeries,1).');
        end
        
        disp('Finished reading old tSeries- now writing out new file.');
        save(matFileName,'tSeries');
        
        delete(datFileName);
    end
end
