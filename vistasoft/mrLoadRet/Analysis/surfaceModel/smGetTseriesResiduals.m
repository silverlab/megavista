function [residualTcs, coords] = smGetTseriesResiduals(vw, model, coords, scans)
% Get the resiudal tSeries for the two ROIs for a surface model of BOLD
% activity (see smMain.m). 
%
%  model = smGetTseries(vw, model)
%
% The residuals are the differences between the mean tSeries for all scans
% in a group and the tSeries for the individual scans in the group.
% Presumably, the group will be a set of scans with the same stimulus.
% Hence the residual tSeries is effectively the non-stimulus driven
% component of the response.

% loop through each group of scans
for group = 1:length(scans)
    % get the list of scans in the current grouping
    thisscangroup = scans{group};
    
    % get the time series
    [voxelTcs, coords] = voxelTSeries(vw, coords, thisscangroup);

    % get the number of frames per indiv scan
    nFrames = size(voxelTcs,1) / length(thisscangroup);     
    
    % initialize the mean time series
    meanTcs = zeros(nFrames, size(voxelTcs,2));
    
    % sum the t-series across scans
    for scan = 1:length(thisscangroup)
        meanTcs = meanTcs + voxelTcs(1+(scan-1)*nFrames:scan*nFrames, :);
    end

    % get the average by dividing by the num of scans
    meanTcs = meanTcs / length(thisscangroup);
    
    % repeat the average to make subtraction easy
    meanTcs = repmat(meanTcs, length(thisscangroup), 1);
        
    groupResidualTcs  = voxelTcs - meanTcs;

    if group == 1,  residualTcs = groupResidualTcs;
    else            residualTcs = [groupResidualTcs; residualTcs]; end

end


return
