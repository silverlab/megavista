% rd_fslMakeSliceTimingsFile
%
% From FEAT help: "If a slice timings file is to be used, put one value (ie
% for each slice) on each line of a text file. The units are in TRs, with 
% 0.5 corresponding to no shift. Therefore a sensible range of values will
% be between 0 and 1."
% From FSL's slicetimer: "Positive values shift slices foward in time."
%
% Should run this script from within a dicoms directory.
%
% Rachel Denison
% 3 October 2012

plotFigs = 1;
saveFile = 1;
saveName = 'slicetimeshift.txt';
saveDir = '../..';
saveFilePath = sprintf('%s/%s', saveDir, saveName);

dicomFiles = dir;
sampleDicom = dicomFiles(5).name;

[sliceOrder sliceTiming TR] = rd_getSliceTiming(sampleDicom, plotFigs);

normTiming = sliceTiming/TR;

% This is how much we want FSL to shift the timeseries, in units of TR
shiftInTRs = -1*(normTiming - 0.5);

% Check the shifts
% normTiming + shiftInTRs should = 0.5
shiftCheck = normTiming + shiftInTRs;

if any(shiftCheck~=0.5)
    fprintf('\nSome timings have not been adjusted correctly .. check timings.\n')
else
    fprintf('\nShift check OK.\n')
end

% Save slice timings file
if saveFile
    dlmwrite(sprintf('%s', saveFilePath), shiftInTRs)
    fprintf('\nSlice timings file saved as \n%s\n\n', saveFilePath)
else
    fprintf('\nFile not saved.\n\n')
end


