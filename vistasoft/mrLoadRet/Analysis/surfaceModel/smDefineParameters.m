function [vw, model] = smDefineParameters(vw,roiX, roiY, varargin)
% Define the initial parameters for a surface-based model 
%   
%   [vw, model] = smDefineParameters(vw,roiX, roiY, varargin)
%--------------------------------------------------------------------------
% INPUTS
%
%   Required
%     vw:   mrVista view structure (gray view only)
%           [default = getCurView]?   
%
%     roiX: string; name of regressor ROI
%           [default = vw.ROIs(1).name]?
%
%     roiY: string; name of regressed ROI
%           [default = vw.ROIs(2).name]?
%
%   Optional
%     dataType: integer; dataType in vw containing data for model              
%           [default = current dataTYPE in view]
%
%     scans: integer; scan numbers to include in model    
%           [defalt  = all scans in current dataTYPE]
%
%
%     doPCA: Boolean; Whether to do principal component analysis on regressors                 
%           [default = true]
%
%     nPCs: integer; How many PCs to use (if doPCA == true)                  
%           [default = 100]
%
%     regressionMethod: string; regression algorithm
%           [default = 'standard']
%           TODO: add other types of regression, like robustFit, LASSO, lars, etc. 
%
%     modelFile: string;  name of file to store model        
%           [default = 'sm-<roiX>2<roiY>-curdate.mat']
%
%     
%     modeldir: string; name of dir containing files associated with model
%           [default = modelFile]    
%           We have a model directory in case there are large structures
%           that we would rather save as a separate file than as part of
%           the model struct, and because we may later want to make images
%           or other files associated with the model. This gives us a place
%           to put things.
%
%     projectdir: string; name of dir containing mrv project
%           (needed? what if the project is moved? should the model break?)
%
%     useResiduals: Boolean; If true, average tSeries for each voxel from
%           all scans with the same stimulus and subtract out mean from the
%           tSeries
%
%     roixmesh: name of the file containing the inflated mesh containing
%           the roi.
%
%     roiymesh: name of the file containing the inflated mesh containing
%           the roi.
%   
%     meshview: name of the already saved meshview. default is 'V1V2'
%--------------------------------------------------------------------------
%
%   Example: Use the current view, with the first two ROIs indexed in the
%   current view as the regressor and regressed ROIs. Use 100 PCs. Use the
%   first scan in the current dataType;
%
%   (Note that there must be at least two ROIs in the current view or we
%   will return an error.)
%
%   vw = getCurView;
%   roiX = 1;
%   roiY = 2;
%   nPCs = 100;      
%       
% [vw, model] = smDefineParameters(vw,roiX, roiY, 'nPCs',100, 'scans',1);
%

mrGlobals;

%-----------------------------------
% Required variables
%-----------------------------------
% We need a mrVista view structure, an 'outcome' ROI (ROI Y) whose data we
% want to explain, and a predictor time series, either from another ROI
% (ROI X) or from the the stimulus. All parameters and results will be
% stored in the model struct.

model = []; 

if notDefined('vw'),    vw      = getCurView;   end;
if notDefined('roiX'),  roiX    = [];           end;
if notDefined('roiY'),  roiY    = [];           end;

roiX  = smGetROI(vw, roiX, 1);
roiY  = smGetROI(vw, roiY, 2);

model = smSet(model, 'roiX', roiX);
model = smSet(model, 'roiY', roiY);

%-----------------------------------
% Optional variables
%-----------------------------------
% Check for optional variables
if nargin > 3,
    addArg = varargin;
    if numel(addArg) == 1,
        addArg=addArg{1};
    end;
else
    addArg = [];
end;

[vw model] = smParseOptionalInputs(vw, model, addArg);

%----------------------------
% Check and move on
% ---------------------------
% If required fields are not set, use defaults 
[model vw] = smParamsCheck(model, vw);

return

end

% -------------------------------------------------------------
function [vw model] = smParseOptionalInputs(vw, model, addArg)
% Parse optional inputs

mrGlobals;

fprintf(1,'[%s]:Setting parameters:',mfilename);
for n=1:2:numel(addArg),
    data = addArg{n+1};
    fprintf(1,' %s,',addArg{n});
    switch lower(addArg{n}),

        case {'datatype', 'dt', 'dtnum', 'dtnumber', 'dtn', 'datatypenumber'}
            model = smSet(model, 'dtNum', data);
            vw = viewSet(vw, 'curdatatype', smGet(model, 'dtNum'));
            model = smSet(model, 'dtName', viewGet(vw, 'dtName')); 

        case {'scans', 'scan'}
            model = smSet(model, 'scans', data);
            
        case {'modelfile', 'modelname', 'model'}        
            model = smSet(model, 'modelFile', data);
            
        case {'regressionmethod', 'regression', 'regress', 'regressiontype'}
            model = smSet(model, 'regressionMethod', data);
            
        case {'basistype'}
            model = smSet(model, 'basisType', data);
            
        case {'nbasisfunctions', 'numberbasis', 'numbasis', 'n basis', 'num basis'}
            model = smSet(model, 'nbasisfunctions', data);
            
        case {'projectdir'}
            model = smSet(model, 'projectDir' , data);
            
        case {'modeldir'}
            model = smSet(model, 'modelDir', data);
           
        case{'useresiduals', 'residuals'}
            model = smSet(model, 'useResiduals', data);
            
        case{'roixmesh'}
            model = smSet(model, 'roixmesh', data);
            
        case{'roiymesh'}
            model = smSet(model, 'roiymesh', data);
            
        case{'meshview'}
            model = smSet(model, 'meshview', data);
        
        case{'stimulus', 'usestimulus'}
            model = smSet(model, 'useStimulus', data);

        otherwise,
            fprintf(1,'[%s]:IGNORING unknown parameter: %s\n',...
                mfilename,addArg{n});
    end;
end;
fprintf(1,'.\n');


% If requested, we get a stimulus instead of or in addition to a predictor
% ROI. This will be used as a regressor to predict the time series 
% users instead of getting the defaults every time.
if smGet(model, 'useStimulus')
    fprintf(1, '[%s]:Getting stimulus. We will be regressing on it\n', mfilename);
    [stimulus vw] = smGetStimulus(vw, model);
    model         = smSet(model, 'stimulus', stimulus);
    %model         = smSet(model, 'tseries stimulus', stimulus.tSeries);
end

end