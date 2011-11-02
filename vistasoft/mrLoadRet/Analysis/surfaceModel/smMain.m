function [vw, model] = smMain(vw, roiX, roiY, varargin)
% function smMain(vw, roiX, roiY, varargin)
%
% Pipeline for generating surface model RFs, with example
%
%
%--------------------------------------------------------------------------
% INPUTS
%
%     vw:   mrVista view structure (gray view only)
%           [default = getCurView]?   
%
%     roiX: string or integer; name or number of regressor ROI
%           [default = vw.ROIs(1).name]; use -1 to use stimulus instead of
%           ROI as regressor.
%
%     roiY: string or integer; name or number of regressed ROI
%           [default = vw.ROIs(2).name]
%
%   Optional:
%     dataType: integer; dataType in vw containing data for model              
%           [default = current dataTYPE in view]
%
%     scans: integer; scan numbers to include in model    
%           [defalt  = all scans in current dataTYPE]
%
%     modelFile: string;  name of file to store model        
%           [default = 'sm-<roiX>2<roiY>-curdate.mat']
%
%     regressionMethod: string; type of regression
%           [default = 'standard']
%
%     doPCA: Boolean; Whether to do principal component analysis on regressors                 
%           [default = true]
%
%     nPCs: integer; How many PCs to use (if doPCA == true)                  
%           [default = 100]
%
%     projectdir: string; name of dir containing mrv project
%           (needed? what if the project is moved? should the model break?)
%   
%     modeldir: string name of dir containing files associated with model
%           [default = modelFile]
%
%     useResiduals: Boolean; If true, average tSeries for each voxel from
%           all scans with the same stimulus and subtract out mean from the
%           tSeries
%--------------------------------------------------------------------------
%   Example 1: 
%   Use the current view, with the first two ROIs indexed in the current
%   view as the regressor and regressed ROIs. Use 50 PCs. Use the first
%   three scans in the current dataType;
%
%   (Note that there must be at least two ROIs in the current view or we
%   will return an error.)
%
%   vw = getCurView;
%   roiX = 1;
%   roiY = 2;
%   nPCs = 50;      
%   scans = 1:3;
%   
%   [vw, model] = smMain(vw,roiX, roiY, 'nPCs', nPCs, 'scans', scans);
%
%   Example 2: 
%   Calculate a surface model on the residual times series. It 
%   vw = getCurView;
%   roiX = 1;
%   roiY = 2;
%   nPCs = 50;      
%   [groups, scans] = getScanGroups(getCurView);
%
%   [vw, model] = ...
%       smMain(vw,roiX, roiY, 'nPCs', nPCs, 'scans', scans,...
%               'useResiduals', true,...
%               'modelFile', 'mySurfaceModelwithResiduals');
%   
%   Example 3:
%   Calculate a model using the stimulus instead of an ROI as a predictor
%
%   vw = getCurView;
%   roiX = -1;
%   roiY = 1;
%   [vw, model] = smMain(vw, roiX, roiY, 'nPCs', 10);
   
tic
%--------------------------------------------------------------
% Argument checks
%--------------------------------------------------------------
if notDefined('vw'),    vw = getCurView;  end;
if notDefined('roiX'),  roiX = [];  end;
if notDefined('roiY'),  roiY = [];  end;

if nargin > 3,
    addArg = varargin;
else
    addArg = [];
end;

%--------------------------------------------------------------
% Define model structure
%--------------------------------------------------------------
[vw, model] = smDefineParameters(vw,roiX, roiY, addArg);

%--------------------------------------------------------------
% Get t-series of predictor (stimulus or ROI) and outcome ROI
%--------------------------------------------------------------
model       = smGetTseries(vw, model);

%--------------------------------------------------------------
% Specify basis set for predictions
%--------------------------------------------------------------
model       = smSetBasis(model);

%--------------------------------------------------------------
% Regress predictor on outcome
%--------------------------------------------------------------
model       = smRegress(model);

%--------------------------------------------------------------
% Save it
%--------------------------------------------------------------
smSave(model);

%---------------------------------------------------------------
% Done
%---------------------------------------------------------------
fprintf(1, '[%s] Done!', mfilename);
toc

return


