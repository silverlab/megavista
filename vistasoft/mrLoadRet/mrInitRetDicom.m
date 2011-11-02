function mrInitRetDicom(sessionName,rawInplaneDir,rawFuncScanDirs,nFrames,nSlices)
% mrInitRetDicom(sessionName,rawInplaneDir,rawFuncScanDirs,nFrames,nSlices)
% 
% mrInitRetDicom
% Similar to mrInitRet except that it operates on DICOM format
% data sets as output by, say, the UCSF China Basin scanner
% This scanner spits out a set of directories 
% numbers 1-n with 1 being the localizers, 2 being the inplanes and 
% 3:end being the functional data directories. 
% Inside the functional data dirs are sets of DICOM images 
% with 1 image per slice per TR (so potentially thousands of images)
% This routine does something similar to mrInitRet:
%
% Does the following step:
% - crop inplanes (These are also stored as DICOM files) - generate
% anat.mat file
% - build mrSESSION (& modify if necessary?)
% - build dataTYPES
% - modify analysis parameters in dataTYPES 
% - create Readme
% - extract time series from DICOM files.
% - corAnal
% Last modified $Date: 2007/04/24 02:50:09 $
% Note: this is now a function rather than a script: - you pass in the sessionName : (something
% like 'E839' which forms the root of all the dicom file names.
% The script expects to find a folder called RawDicom in the pwd
% It will generate Inplane, Gray, Raw etc...


mrGlobals

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Opening dialogs

initOptions = {'DB Query',...
        'Crop inplane images',...
        'Create/edit data structures',...
        'Extract time series',...
        'Perform blocked analysis'};

initReply = buttondlg('mrInitRet', initOptions);
if isempty(find(initReply, 1)), return; end
doDBQuery=initReply(1);

doCrop = initReply(2);
doSession = initReply(3);
doTSeries = initReply(4);
doCorrel = initReply(5);

HOMEDIR = pwd;
rawDir = [HOMEDIR,filesep,'RawDicom'];
disp(rawDir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the inplane anatomies 
% Get the scan params from the DICOM files if possible

scanParams = GetScanParamsDicom(rawDir,sessionName,rawFuncScanDirs,nFrames,nSlices);
if(doDBQuery)
    lastName=scanParams(1).lastName;
    scanDate=scanParams(1).date;
    db_makeReadme(lastName,scanDate,'readme_db.txt');
end

% Load the inplane-anatomy images and initialize the inplanes structure
[anat, inplanes, doCrop] = InitAnatomyDicom(HOMEDIR, rawDir,rawInplaneDir, doCrop);

if isempty(anat)
    disp('Aborted')
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do crop

% At this point we should have a valid inplane anatomy, and the
% doCrop flag indicates if it can and should be cropped
if doCrop
    % Calculate the cropRatio from inplanes.fullSize and functionals(:).fullSize
    cropRatio = 1;
    for scan = 1:length(scanParams)
        cropRatio = max([cropRatio, inplanes.fullSize ./ scanParams(scan).fullSize]);
    end
    
    % Crop the inplane anatomy if requested or not previously done:
    [anat, inplanes] = CropInplanes(rawDir, anat, inplanes, cropRatio);
    if isempty(anat)
        disp('Crop inplanes aborted');
        return
    end
    
    % Delete tSeries (if there are any); they are out of date because the crop has changed
    datadir = fullfile(HOMEDIR,'Inplane','Original','TSeries');
    [nscans,scanDirList] = countDirs(fullfile(datadir,'Scan*'));
    if nscans > 0
        deleteFlag = questdlg('The existing tSeries are out of date because the crop has changed. Delete existing TSeries?',...
            'Delete tSeries','Yes','No','Yes');
        if strcmp(deleteFlag,'Yes')
            for s=1:nscans
                delete(fullfile(datadir,scanDirList{s},'*.mat'));
            end
        end
    end
    
else
    % Check that previous crop information is present:
    if ~isfield(inplanes, 'crop')
        % Whoops -- no previous crop info. Try to get from anat.mat file:
        Alert('Problems with inplane crop');
        return
    end
end

% Save anat
anatFile = fullfile(HOMEDIR, 'Inplane', 'anat.mat');
save(anatFile, 'anat', 'inplanes');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create/load mrSESSION and dataTYPES, modify them, and save

% If mrSESSION already exits, load it.
sessionFile = fullfile(HOMEDIR, 'mrSESSION.mat');
if exist(sessionFile, 'file')
    loadSession;
    % if docrop, make sure that the mrSESSION is up-to-date
    if doCrop
        mrSESSION.inplanes = inplanes;
        mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams);
        saveSession;
    end
end

if doSession
    % If we don't yet have a session structure, make a new one.
    if (~exist('mrSESSION','var'))
        mrSESSION = CreateNewSession(HOMEDIR, inplanes, mrLoadRetVERSION);
    end
    

    if isempty(mrSESSION)
        mrSESSION = CreateNewSession(HOMEDIR, inplanes, mrLoadRetVERSION);
    end
    
    % Update mrSESSION.functionals with scanParams corresponding to any new Pfiles.
    % Set mrSESSION.functionals(:).crop & cropSize fields
    mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams);
    
    % Dialog for editing mrSESSION params:
    [mrSESSION,ok] = EditSession(mrSESSION);
    if ~ok
        disp('Aborted'); 
        return
    end
    
    % Create/edit dataTYPES
    if isempty(dataTYPES)
        dataTYPES = CreateNewDataTypes(mrSESSION);
    else
        dataTYPES = UpdateDataTypes(dataTYPES,mrSESSION);
    end
    dataTYPES(1) = EditDataType(dataTYPES(1));
    
    % Save any changes that may have been made to mrSESSION & dataTYPES
    saveSession;
    
    % Create Readme.txt file
    %mrCreateReadmeDicom(mrSESSION);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract time series & perform corAnal

% Create time series files
if doTSeries
    GetDicomRecon(rawDir,sessionName,rawFuncScanDirs,0); % Set this fleg to 0 for no roation or 1 for 90 degrees of CW rotation.
    
end

% Perform correlation analysis
if doCorrel
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up

clear all
