function val = v_dtiRawPreprocess
%
% Validate dtiRawPreprocess.m function.
%
% Copyright Stanford team, mrVista, 2011
%
% FP and MP 7/6/2011
%
% See also mrvValidateAll.m
%
% this function checks that the average FA and B0 values resulting from
% dtiRawPreprocess are consistent with the expected value on different
% platforms (LINUX, WINDOWS, etc.).
%
% TO DO NOW:
% (0) assume: a. a T1 data set exist in the path, b. both anatomical and
%     DTI data are in NIFTI format already, c. T1 and DTi must be acquied
%     in the same session. We assume that the dtiRawPreprocess options are
%     the default ones.
%
%     - Add a DTI and a T1 data set and a .mat file containing saved
%       values of FA, BVECS, B0 etc for the data set in
%       diffusion/dtiRawPreprocess/
%     - Save a montage and a dt6 file in diffusion/dtiRawPreprocess/
%
% (1) run dtiRawPreprocess  on the data set. This will align to the T1 and
% create a B0, BVECS and FA values (it creates more stuff but we only focus on these for the moment).
%
% (2) Show a montage of the T1 and DTI overalyed. Check for LR flips and correct alignment. 
%  
% (3) Show montage of BVECS, B0, and FA.
% 
% (4) Compute FA, Mean diffusivity, radial diffusivity nd Axial diffusivity 
%     across the brain and check the value obtained on different
%     platforms. THis will be done using: [fa,md,rd,ad] = dtiComputeFA(eigVal)
%
% (5) We will save a stored FA, BVECS, and MD, RD, AD for one slice in the
%     data set and show a comparison with the one jus trecomputed on the
%     current platform. Use showMontage.
%
% (6) Attempt tp load the resulting dt6.mat file obtained in the preprocess
%     using dtiFiberUI.m (or mrDiffiusion.m). Make sure this is possible
%
%
% To Do NEXT:
% - create fibers with different algorithms (conTrack or stt) to make sure
%   results are consistent.

val = [];
warning('Not yet implemented') %#ok<WNTAG>
return

%% Initialize the key variables and data path
% Data directory (where the mrSession file is located)
dataDir = fullfile(mrvDataRootPath,'diffusion','dtiRawPreprocess');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Load data structure:
vw = initHiddenInplane(); % Foregoes interface - loads data silently

%% Set data structure properties:
vw = viewSet(vw, 'CurrentDataType', dataType); % Data type

%% Get time series from ROI:
% Format returned is rows x cols x slices x time
tSeries = tSeries4D(vw, scan, [], 'usedefaults', ~isRawTSeries);

val.dim = size(tSeries);
val.mn  = mean(double(tSeries(:)));
val.sd =  std(double(tSeries(:)));

% This is the validation file
% vFile = fullfile(mrvDataRootPath,'validate','tSeries4D');
% stored = load(vFile);
% save(vFile, '-struct', 'val');


cd(curDir)

%% End Script




