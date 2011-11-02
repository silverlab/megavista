function gray = ip2volTSeries(inplane,gray,selectedScans,method)
%
% function gray = ip2volTSeries(inplane,gray,[selectedScans],[method])
%
% Uses point sampling and nearest neighbor interpolation to map
% tSeries from inplane view to gray view. Inplane and
% gray views must already be open. Loads the inplane tSeries as
% it goes.
%
% Output tSeries matrics are (as usual) nFrames x nVoxels in size
% where nVoxels is the number of gray voxels that correspond to the
% inplanes, i.e., size(gray.grayCoords,2).
%
% selectedScans:
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
% %
% method : 'nearest' [default], 'linear' interpolation
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volParMap, ip2volSpatialGradient,
%    vol2flatCorAnal, vol2flatParMap, vol2flatTSeries
%
% djh, 2/2001
% ras, 10/2005, fixed to agree with a concomittant change in
% upSampleFactor.
% sod, 11/2005 added linear interpolation

global mrSESSION;

% Don't do this unless inplane is really an inplane and gray is really a gray
if ~strcmp(inplane.viewType,'Inplane') || ~(strcmp(gray.viewType,'Gray') || strcmp(gray.viewType,'Volume'))
    myErrorDlg('ip2grayTSeries can only be used to transform from inplane to gray.');
end

% Check that both gray & flat are properly initialized
if isempty(inplane)
    myErrorDlg('Inplane view must be open.  Use "Open Inplane Window" from the Window menu.');
end
if isempty(gray)
    myErrorDlg('Gray view must be open.  Use "Open Gray Window" from the Window menu.');
end

% check for compatible data types
checkTypes(inplane,gray);

nScans = viewGet(gray, 'numScans');

% (Re-)set scanList
if ~exist('selectedScans','var') || isempty(selectedScans),
    selectedScans = er_selectScans(inplane);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end
if isempty(selectedScans)
    disp('Analysis aborted')
    return
end

if nargin < 4,
    method = 'nearest';
end;
fprintf('[%s]: using %s interpolation.\n',mfilename,method);

% Size of the output tSeries matrices is: nFrames x nVoxels
% Also need to know number of inplane slices
nVoxels = size(gray.coords,2);

% open waitbar
verbose = prefsVerboseCheck;
if verbose, 
	waitHandle = waitbar(0, 'Interpolating tSeries.  Please wait...');
end

% Compute the transformed coordinates (i.e., where does each gray node fall in the inplanes).
% The logic here is copied from ip2volCorAnal.
%
grayCoords = double([gray.coords; ones(1,nVoxels)]);
vol2InplaneXform = inv(mrSESSION.alignment);
vol2InplaneXform = vol2InplaneXform(1:3,:);

% I'll bet $20 that there will never be a need to put this back in 
% the scan loop:
ipCoords        = vol2InplaneXform*grayCoords;
preserveCoords  = true;
ipCoords        = ip2functionalCoords(inplane, ipCoords, [], preserveCoords);

% Loop through the scans
for scan = selectedScans

    % Scale and round the grayCoords
    fprintf('Xforming scan %i ...\n',scan);

    % only round for nearest neighbor interpolation
    switch method,
        case 'nearest',
            ipCoords=round(ipCoords);
        case 'linear'
        otherwise,
            fprintf('Unknown interpolation method: %s\n',method);
            return
    end

    % ras 12/20/04:
    % occasionally the xformed grayCoords will include a 0
    % coordinate. While it seems this should not happen,
    % I'm applying this band-aid for the time being:
    [badRows badCols] = find(ipCoords==0);
    goodCols = setdiff(1:nVoxels, badCols);
    ipCoords = ipCoords(:,goodCols);
    if length(badCols)>1
        fprintf('%i voxels mapped to slice 0...\n',length(badCols));
    end
    nFrames = viewGet(gray,'numFrames',scan);

    % Reset to NaNs
    tSeries = repmat(single(NaN), [nFrames nVoxels]);
    slices = sliceList(inplane,scan);
    
    % Loop through slices, loading the inplane tSeries and
    % transforming it.
    switch method,
        % nearest neighbor interpolation [default]
        case 'nearest',
            for slice = slices
                slice;
                inplaneTSeries = loadtSeries(inplane,scan,slice);
                grayIndices = find(ipCoords(3,:)==slice);
                if ~isempty(grayIndices)
                    ipIndices = sub2ind(viewGet(inplane, 'sliceDims', scan),...
                        ipCoords(1,grayIndices),ipCoords(2,grayIndices));
                    tSeries(:,grayIndices) = inplaneTSeries(:,ipIndices);
                end
            end

        % trilinear interpolation
        case 'linear',
            funcData = tSeries4D(inplane, scan);
            
            for frame = 1:nFrames
                subData = double(funcData(:,:,:,frame));
                tSeries(frame,:) = interp3(subData, ...
                                          ipCoords(2,:), ...
                                          ipCoords(1,:), ...
                                          ipCoords(3,:), ...
                                          method);
            end

            % other
        otherwise,
            fprintf('Unknown interpolation method: %s\n',method);
    end;

    % Save tSeries
    savetSeries(tSeries, gray, scan, 1);
    
    % update the waitbar
	if verbose,   
		waitbar(find(selectedScans==scan)/nScans, waitHandle);
	end
end

% close waitbar
if verbose, close(waitHandle); end

fprintf('Done xforming tSeries.\n');

return
