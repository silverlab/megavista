% mr_timeSeriesCorrelate.m
%
% This computes the similarity between two time series. You can call this
% function once mrVista is started for your subject and the ROIs of
% interest are loaded. Similarity is measured as the cosine of the angle
% between two timeseries vectors. The script returns the largest cosine
% value computed over a number of timeshifts (as specified by the user),
% along with which timeshift yielded the maximal correlation.
%
% Input arguments: 
% -inplane: the global struct INPLANE containing all data, ROI
% coordinates, and scan number needed for this analysis  
% -param: specifies which type of camparison you want to compute.  see
% below for options.
% -nTShifts: The number of TRs in a single direction by which the first ROI
% in the INPLANE should be shifted and the correlation be computed.  If
% nTShifts = 3, the correlation will be comuted for each timeshift between
% -3 and 3, and the largest correlation will be returned.  If nTShifts = 0,
% the correlation will be computed on the unshifted timeseries data only.
%
% Output variables: 
% -cosAngle: when two ROIs are being compared, this variable contains a
% single number indicating the cosine of the angle between two timeseries
% vectors. When an ROI is being compared to all voxels in all slices, this
% variable contains an nVoxels X nSlices matrix where each cell contains a
% value indicating the cosine of the angle between the ROI and the voxel
% represented by the cell. The value of cosAngle is the same as the
% correlation coefficient, and should fall between 0 (if the vectors are
% completely orthogonal) and 1/-1. 
% -maxTShift: indicates the number of timeshifts required to obtain the
% maximal correlation.  When two ROIs are being compared, maxTShifts is a
% single integer between -nTShifts and +nTshifts.  When an ROI is being
% compared to voxels, maxTshifts is an nVoxels X nSlices array of such
% integers.
% 
% Input options for 'param' are:
% 'roi-roi': computes the mean timeseries for each ROI and compares them
% 'fiber-endpts': similar to roi-roi, but ROIs are defined by splitting DTI
% fiber endpts at a certain slice 
% 'roi-voxel': computes the mean timeseries for one ROI and compares this
% to all other voxels in all other slices
% 'voxel-voxel': not yet implemented. 
%
% For some reason, 'roi-roi' seems to work well. It even spits out a figure
% that shows convincingly how correlated the two timeseries are. However,
% 'roi-voxel' yields very low values. Also, 'voxel-voxel' is not yet
% implemented, nor are we sure of the best way to do this. 
%
% 2007/05/29
% by Alexia Toskos and Davie Yoon
% modified from mr_ReadTimeSeries, by Brian Wandell and Alexia Toskos
% with help from Michal Ben-Shachar, 2007/05/31

function [cosAngle, maxTShift] = mr_timeSeriesCorrelate(inplane,param,nTShifts)

scan  = viewGet(inplane, 'curScan'); % you better be on the desired scan already

switch lower(param)
    % roi-roi: gets mean tSeries from two ROIs, and compares them to each
    % other. assumes that you have already defined and have loaded two
    % ROIs. NOTE: fix this so it can handle n ROIs?  Maybe it's easier to
    % deal with output from just 2 at a time? 
    case 'roi-roi'
       roi1 = inplane.ROIs(1).coords;
       roi2 = inplane.ROIs(2).coords;
       
       [roiTSeries1,roiTSE1] = meanTSeries(inplane,scan,roi1);
       roiTSeriesU1 = roiTSeries1 / norm(roiTSeries1);
       [roiTSeries2,roiTSE2] = meanTSeries(inplane,scan,roi2);
       roiTSeriesU2 = roiTSeries2 / norm(roiTSeries2);
       
       % One way to compare the similarity of two vectors is to compute the
       % inner product of the norm'd (unit length) vectors. The vector
       % length is also called the norm.
       cosAngles = zeros(1,nTShifts*2+1);
       for tShift = -nTShifts:nTShifts
           shiftedTSeries = shift(roiTSeriesU1,tShift); % only the first TSeries is shifted
           cosAngles(tShift+nTShifts+1) = shiftedTSeries'*roiTSeriesU2;
       end
       [cosAngle, maxTShift] = max(abs(cosAngles));
       cosAngle = cosAngles(maxTShift);  % retrieve the negative values
       maxTShift = maxTShift-nTShifts-1; % re-center max TShifts around 0
       
       % If you compute the correlation between un-normed timeseries, you
       % can see that the correlation coefficient is identical to the
       % cosine of the angle between the two normed timeseries. 
       corr = corrcoef(roiTSeries1,roiTSeries2); 
       corr=corr(1,2);

       % Plot the two ROI timeseries
       t = 1:length(roiTSeries1); 
       figure;
       plot(t,roiTSeriesU1(:,1),'g',t,roiTSeriesU2(:,1),'r')
       grid on; xlabel('TR'); ylabel('Norm''d time series');
    
    % fiber-endpts: asks user to pick a slice number to divide the ROI
    % coordinates. all coordinates on slices below that number will go into
    % the first ROI and coordinates on slices above that number will go
    % into the second ROI (coodinates on the given slice are discarded).
    % gets mean tSeries from twoROIs and compares them to each  other (same
    % as 'roi-roi'
    case 'fiber-endpts'
       
       % User chooses which ROI should be examined. Coordinates are split
       % into two ROIs according to the user-defined slice number. This can
       % be changed so that input arguments specify these parameters, but
       % this is most convenient for the moment.
       r = input('Which ROI do you want to examine?: ');
       sliceNum = input('At what slice do you want to split the fibers?: ');
       upperEndpts = find(inplane.ROIs(r).coords(3,:)<sliceNum);
       lowerEndpts = find(inplane.ROIs(r).coords(3,:)>sliceNum);
       roi1 = inplane.ROIs(r).coords(:,upperEndpts);
       roi2 = inplane.ROIs(r).coords(:,lowerEndpts);
       
       [roiTSeries1,roiTSE1] = meanTSeries(inplane,scan,roi1);
       roiTSeriesU1 = roiTSeries1 / norm(roiTSeries1);
       [roiTSeries2,roiTSE2] = meanTSeries(inplane,scan,roi2);
       roiTSeriesU2 = roiTSeries2 / norm(roiTSeries2);
       
       % One way to compare the similarity of two vectors is to compute the
       % inner product of the norm'd (unit length) vectors. The vector
       % length is also called the norm.
       cosAngles = zeros(1,nTShifts*2+1);
       for tShift = -nTShifts:nTShifts
           shiftedTSeries = shift(roiTSeriesU1,tShift);  % only the first TSeries is shifted
           cosAngles(tShift+nTShifts+1) = shiftedTSeries'*roiTSeriesU2;
       end
       [cosAngle, maxTShift] = max(abs(cosAngles));
       cosAngle = cosAngles(maxTShift);   % retrieve the negative values
       maxTShift = maxTShift-nTShifts-1;  % re-center max TShifts around 0
       
       % cosAngles(tShift+nTShifts+1) = shiftedTSeries(3:end)'*roiTSeriesU2(3:end); 
       % for the case where it appears that you do not want to include the
       % whole timeseries
       
       % Compute correlation between un-normed timeseries
       corr = corrcoef(roiTSeries1,roiTSeries2); 
       corr=corr(1,2);

       % Plot the two ROI timeseries
       t = 1:length(roiTSeries1); 
       figure;
       plot(t,roiTSeriesU1(:,1),'g',t,roiTSeriesU2(:,1),'r')
       grid on; xlabel('TR'); ylabel('Norm''d time series');
       
    % roi-voxel: gets mean tSeries from one ROI, and compares this to all
    % other voxels in all n slices. Will take the first ROI on the list
    % (INPLANE{1}.ROIs(1)). NOTE: fix this so it will do this for all ROIs.  
    case 'roi-voxel'
       roi1 = inplane.ROIs(1).coords;
       fprintf(1,'%s',inplane.ROIs(1).name);
       [roiTSeries1,roiTSE1] = meanTSeries(inplane,scan,roi1);
       roiTSeriesU1 = roiTSeries1 / norm(roiTSeries1);
       nFrames = length(roiTSeries1);
       
       % Find out how many slices there are
       dimensions = size(inplane.anat);
       slices = dimensions(3);
       
       % Derive dimensions (voxels, frames, etc) of the timeseries
       voxels = loadtSeries(inplane,scan,slices);
       dimensions=size(voxels);
       nVoxels = dimensions(2);
       
       % Normalize the time series
       sliceTSeries = zeros(nFrames,nVoxels,slices); 
       sliceTSeriesU = zeros(nFrames,nVoxels,slices); 
       cosAngle = zeros(nVoxels,slices);
       cosAngles = zeros(nVoxels,nTShifts*2+1);
       maxTShift = zeros(nVoxels,slices);
       for i=1:slices
           sliceTSeries(:,:,i) = loadtSeries(inplane,scan,i);
           for j=1:nVoxels
               sliceTSeriesU(:,j,i) = sliceTSeries(:,j,i)/norm(sliceTSeries(:,j,i));
           end
           % One way to compare the similarity of two vectors is to compute the
           % inner product of the norm'd (unit length) vectors. The vector
           % length is also called the norm.
           for tShift = -nTShifts:nTShifts
               shiftedTSeries = shift(roiTSeriesU1,tShift);  % only the first TSeries is shifted
               cosAngles(:,tShift+nTShifts+1) = shiftedTSeries'*sliceTSeriesU(:,:,i);
           end
           [cosAngle(:,i), maxTShift(:,i)] = max(abs(cosAngles),[],2);
           for voxel = 1:nVoxels
               cosAngle(voxel,i) = cosAngles(voxel, maxTShift(voxel,i)); % retrieve the negative values
           end
           maxTShift(:,i) = maxTShift(:,i)-nTShifts-1; % re-center max TShifts around 0
       end
        
    % voxel-voxel: gets tSeries from one voxel and compares this to all
    % other voxels in the brain
    case 'voxel-voxel'
        % to be implemented
        fprintf(1, 'not yet implemented, sorry'); 
end
 
