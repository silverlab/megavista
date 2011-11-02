function volume = ip2volCorAnal(inplane, volume, selectedScans, forceSave)
%
% function volume = ip2volCorAnal(inplane, volume, [selectedScans], [forceSave=0])
%
% Uses point sampling and nearest neighbor interpolation to map
% co, amp, and ph from inplane view to volume view.  inplane and
% volume views must already be open.  inplane corAnal must 
% be loaded.
%
% selectedScans: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via chooseScans dialog
%
% Output co, amp, and ph are nVoxels x nScans in size where
% nVoxels is the number of volume voxels that correspond to the
% inplanes, i.e., size(volume.coords,2)
%
% If you change this function make parallel changes in:
%    ip2volParMap, ip2volSpatialGradient, ip2volTSeries, 
%    vol2flatCorAnal, vol2flatParMap, vol2flatTSeries
%
% djh, 7/98
%
% Modifications:
% djh, 2/2001
% - Replaced globals with local variables
% - Data are no longer interpolated to the inplane size
% Ress, 2/2004 -- Now performing linear interpolation using myCInterp3
% ras, 08/2007 -- removed method flag, since this seems to be comitted
% to using linear interpolation (is there a rationale to introduce
% a nearest-neighbor option as well, as per ip2volParMap?). Added forceSave
% flag.
global mrSESSION;

if notDefined('forceSave'), forceSave = 0; end

% Don't do this unless inplane is really an inplane and volume is really a volume
if ~strcmp(inplane.viewType,'Inplane')
    myErrorDlg('ip2volCorAnal can only be used to transform from inplane to volume/gray.');
end
if ~strcmp(volume.viewType,'Volume') & ~strcmp(volume.viewType,'Gray')
    myErrorDlg('ip2volCorAnal can only be used to transform from inplane to volume/gray.');
end

% Check that both inplane & volume are properly initialized
if isempty(inplane)
  myErrorDlg('Inplane view must be open.  Use "Open Inplane Window" from the Window menu.');
end
if isempty(volume)
  myErrorDlg('Gray/volume view must be open.  Use "Open Gray/Volume Window" from the Window menu.');
end
if isempty(inplane.co)
  inplane = loadCorAnal(inplane, '', true);
end

nScans = viewGet(inplane, 'numScans');

% (Re-)set scanList
if ~exist('selectedScans','var')
    selectedScans = chooseScans(inplane);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end
if isempty(selectedScans)
  disp('Analysis aborted')
  return
end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
[inplane volume] = checkTypes(inplane, volume);

% Allocate space for the volume data arrays.
% If empty, initialize to cell array. 
% If non-empty, grab it so that it can be updated.
%

if isempty(volume.co)
    try
        loadCorAnal(volume);
    catch
        volume.co = cell(1,nScans);
        volume.ph = cell(1,nScans);
        volume.amp = cell(1,nScans);
    end    
end

if ~isempty(volume.co)
    co = volume.co;
else
    co = cell(1,nScans);
end
if ~isempty(volume.amp)
    amp = volume.amp;
else
    amp = cell(1,nScans);
end
if ~isempty(volume.ph)
    ph = volume.ph;
else
    ph = cell(1,nScans);
end

% put up a wait handle if it's consistent with the VISTA verbose pref:
verbose = prefsVerboseCheck;
if verbose,
	waitHandle = waitbar(0,'Interpolating CorAnal.  Please wait...');
end

% volume.coords are the integer-valued (y,x,z) volume 
% coordinates that correspond to the inplanes.  Convert to
% homogeneous form by adding a row of ones.
%
nVoxels = size(volume.coords,2);
coords = double([volume.coords; ones(1,nVoxels)]);

% vol2InplaneXform is the 4x4 homogeneous transform matrix that
% takes volume (y',x',z',1) coordinates into inplane (y,x,z,1)
% coordinates.
%

vol2InplaneXform = inv(mrSESSION.alignment);
  
% We don't care about the last coordinate in (y,x,z,1), so we
% toss the fourth row of Xform.  Then our outputs will be (y,x,z).
% 
vol2InplaneXform = vol2InplaneXform(1:3,:);

% Transform coords positions to the inplanes.  Hence,
% inplaneCoords contains the inplane position of each of the gray
% matter voxels.  These will generally not fall on integer-valued
% coordinates, rather they will fall between voxels.  We use
% interp3 below to get the data at these between-voxel positions.
% 
coordsXformedTmp = vol2InplaneXform*coords; 

% Need to divide the coords by the upSample factor because the
% inplane data are no longer interpolated to the inplane size.
% This is done below inside the loop because it may vary from
% scan to scan.
coordsXformed= coordsXformedTmp;

% Loop through the scans and use interp3 to transform the values
% from the inplanes to the volume.
%
for curScan = selectedScans
	if verbose,     waitbar((curScan-1)/nScans);  end
    
    % Scale the coords as explained above.
    rsFactor = upSampleFactor(inplane,curScan);
    if length(rsFactor)==1 % isometric upSampleFactor
        coordsXformed(1:2,:)=coordsXformedTmp(1:2,:)/rsFactor;
    else                    % x,y,and z scales are not isometric
        coordsXformed(1,:)=coordsXformedTmp(1,:)/rsFactor(1);
        coordsXformed(2,:)=coordsXformedTmp(2,:)/rsFactor(2);
    end

    if ~isempty(inplane.co{curScan})
        
        % Pull out the correlations, phases, and amplitudes of the
        % inplane data for this scan and all anatomical slices.
        % 
        coInplane = inplane.co{curScan}(:,:,:);
        zInplane = inplane.amp{curScan}(:,:,:) .* exp(i*inplane.ph{curScan}(:,:,:));
        
        % Use the inplane data set values to assign (using linear 
        % interpolation) values to the volume voxels in coInterpVol
        % and zInterpVol.
        dims = size(coInplane);
        newCoords = [coordsXformed(2, :); coordsXformed(1, :); coordsXformed(3, :)]';
        coInterpVol = myCinterp3(coInplane, dims(1:2), dims(3), newCoords);      
        zInterpVol = complex(myCinterp3(real(zInplane), dims(1:2), dims(3), newCoords), ...
          myCinterp3(imag(zInplane), dims(1:2), dims(3), newCoords));
                
        co{curScan} = coInterpVol;
        
        % Pull out amp and ph, wrapping the phases to be all positive.
        %
        amp{curScan} = abs(zInterpVol);
        tmp = angle(zInterpVol);
        indices = find(tmp<0);
        tmp(indices) = tmp(indices) + (2*pi);
        ph{curScan} = tmp;
        clear tmp coInplane zInplane coInterpVol zInterpVol indices
    end 					
end

if verbose, close(waitHandle); end

% Set the fields in volume
%
volume.co = co;
volume.amp = amp;
volume.ph = ph;

% Save the new co, amp, and ph arrays in the Volume
% subdirectory.  if a corAnal file already exists, query user
% about over-writing it.
%
saveCorAnal(volume, [], forceSave);

return
