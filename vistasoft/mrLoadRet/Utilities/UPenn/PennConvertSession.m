function mrSession = PennConvertSession(oldSession)
% mrSession = PennConvertSession(oldSession);
%
% Converts the mrSession structure to the new format by adding the
% scanParams field, a struct array having nScans elements. The new
% field contains the original reconParams struct as a subfield.
% The scanParams field contains all temporal and image size
% information from the Pfile header.
%
% 1/28/99   dbr     Wrote it.
% 2/26/03   ggc     Disable FOV since it's available in Analyze.
% 5/16/03   dhb     Add Penn prefix, streamline for our purpose.

% Get version to stick in.
global mrLoadRetVERSION

mrSession.mrLoadRetVersion = mrLoadRetVERSION;
mrSession.title = '';
mrSession.subject = oldSession.subject;
mrSession.examNum = [];

% Copy info about the inplanes:
mrSession.inplanes.cropSize = oldSession.cropInplaneSize;
mrSession.inplanes.crop = oldSession.inplaneCrop;
mrSession.inplanes.fullSize = oldSession.fullInplaneSize;
mrSession.inplanes.voxelSize =  oldSession.voxelSize;
mrSession.inplanes.nSlices = oldSession.nSlices;

% Get the previously fixed but scan-variable parameters:
nJunk = oldSession.junkFirstFrames;
nFrames = oldSession.nFrames;
version = oldSession.reconVersion;

% Strip off undesirable platform designator:
dashIndex = findstr(version, '-');
if length(dashIndex) > 0; version = version(1:dashIndex-1); end

if (oldSession.nScans ~= length(oldSession.reconParams))
    Alert('oldSession.nScans ~= length(oldSession.reconParams). This probably means that some average scans were computed. You should delete those extra tSeries directories. They will not be converted, and instead, will need to be recomputed.');
end

% Make the functionals sub-structure:
for iScan=1:length(oldSession.reconParams)
    rP = oldSession.reconParams(iScan);
    functionals(iScan).totalFrames = rP.totalFrames;
    functionals(iScan).junkFirstFrames = nJunk;
    functionals(iScan).nFrames = nFrames;
    functionals(iScan).slices = 1:rP.nSlices;
    functionals(iScan).fullSize = rP.fullSize;
    functionals(iScan).cropSize = oldSession.cropTSeriesSize;
    functionals(iScan).crop = oldSession.tseriesCrop;
    functionals(iScan).voxelSize = oldSession.fvoxelSize;
    functionals(iScan).framePeriod = rP.frameRate * 0.001;
    functionals(iScan).reconParams = rP;
    
    % Eliminate some of the redundancy between functionals and functionals.reconParams
    if(isfield(functionals(iScan).reconParams, 'inplaneVoxelSize'))
        functionals(iScan).reconParams = rmfield(functionals(iScan).reconParams,'inplaneVoxelSize');
    end
    if(isfield(functionals(iScan).reconParams, 'frameRate'))
        functionals(iScan).reconParams = rmfield(functionals(iScan).reconParams,'frameRate');
    end
    functionals(iScan).reconParams.reconVersion = version;
end
mrSession.functionals = functionals;

% Copy scrensave size
mrSession.screenSaveSize = oldSession.screenSaveSize;

% Copy alignment (if it exists):
if isfield(oldSession, 'alignment')
    mrSession.alignment = oldSession.alignment;
end
