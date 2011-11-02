function model = smSet(model, param, val)
% Main function to set values for a surface model of BOLD activity (see
% smMain.m). This is the only function that should be used to set any
% fields in an sm-model. 
% 
%   model = smSet(model, param, val);
%
% See also smGet.m

%---------------------------------------------------------------------



% MAIN SWITCH
switch lower(param)

    %------------------
    % Session information
    %------------------

    case {'datatype', 'dt', 'dtnum', 'dtnumber', 'dtn', 'datatypenumber'}
        model.session.dtNum = val;

    case {'datatypename', 'dtname'}
        model.session.dtName = val;

    case {'scans', 'scan'}
        model.session.scans = val;

    case {'projectdir', 'project'}
        model.session.projectDir = val;
        % is this necessary? we don't want anything to break if we move the
        % project to a new directory

        
    %------------------
    % Stimulus properties
    %------------------
  
    case 'stimulus'
        model.data.stimulus = val;    
    
    case 'instimwindow'
        model.data.stimulus.instimwindow = val;

    case 'stimsize'
        model.data.stimulus.stimsize = val;

    case 'stimwindow'
        model.data.stimulus.stimwindow = val;
    
    %------------------
    % T-series
    %------------------
    % The time series are saved in a matlab file instead of as a field in
    % the struct 'model'. This is to prevent the model struct from getting
    % too large. 
    
    case 'tseries'
        warning('[%s]: Overwriting any and all existing tseries data for this model. To avoid this warning, set the t-series separately for each data set.', mfilename);        
        pth = smGet(model, 'modelDirFull');
        tSeries = val;
        save(fullfile(pth, 'tSeries.mat'), 'tSeries');

    case {'tseriesx', 'tseries.x', 'tseries x', 'x tseries'}
        tSeries = smGet(model,'tSeries');
        tSeries.roiX = val;
        pth = smGet(model, 'modelDirFull');
        save(fullfile(pth, 'tSeries.mat'), 'tSeries');
        
    case {'tseriesy', 'tseries.y', 'tseries y', 'y tseries'}
        tSeries = smGet(model,'tSeries');
        tSeries.roiY = val;
        pth = smGet(model, 'modelDirFull');
        save(fullfile(pth, 'tSeries.mat'), 'tSeries');
        
    case {'tseriesstimulus', 'tseries.stimulus', 'tseriesstim', 'stimulus tseries', 'tseries stimulus'}
        tSeries = smGet(model,'tSeries');
        tSeries.stimulus = val;
        pth = smGet(model, 'modelDirFull');
        save(fullfile(pth, 'tSeries.mat'), 'tSeries');
    %------------------
    % ROIs
    %------------------

    case 'roix'
        model.data.roiX = val;

    case 'roiy'
        model.data.roiY = val;
    
    %------------------
    % Mesh
    %------------------
    case 'roixmesh'
        if (exist(val, 'file'))
            model.data.roiX.meshFile = val;
        else
            model.data.roiX.meshFile = [];
        end
        
    case 'roiymesh'
        if (exist(val, 'file'))
            model.data.roiY.meshFile = val;
        else
            model.data.roiY.meshFile = [];
        end
        
    case 'meshview'
        model.params.meshview = val;
                   
    %------------------
    % Analysis parameters
    %------------------

    % -- Basis set
    case {'basistype'}
        model.params.basisType = val;

    case {'nbasisfunctions', 'numberbasis', 'numbasis', 'n basis', 'num basis'}
        model.params.nBasisFunctions =  val;

    case {'latent', 'pcvar', 'pcvariance', 'pclatent', 'basisvar', 'basis variance', 'basis variance explained'}
        basisSet = smGet(model,'basisSet');
        basisSet.var = val;
        pth = smGet(model, 'modelDirFull');
        save(fullfile(pth, 'basis.mat'), 'basisSet');
        
    case {'score', 'pcscores', 'scores', 'pcscore', 'basis projection', 'basis projections'}
        basisSet = smGet(model,'basisSet');
        basisSet.projection = val;
        pth = smGet(model, 'modelDirFull');
        save(fullfile(pth, 'basis.mat'), 'basisSet');

    case {'coeff', 'pccoeff', 'coeffs', 'pccoeffs', 'basis functions'}
        basisSet = smGet(model,'basisSet');
        basisSet.functions = val;
        pth = smGet(model, 'modelDirFull');
        save(fullfile(pth, 'basis.mat'), 'basisSet');

    % -- Regression
    case {'regressionmethod', 'regression', 'regress', 'regressiontype'}
        model.params.regressionMethod = val;

    case 'useresiduals'
        model.params.useResiduals = val;
        
    case {'usestimulus', 'use stimulus'}
        model.params.useStimulus = val;  
        
    %------------------
    % Results
    %------------------
 
    case {'xform betas' 'xformbetas' 'transform betas' 'sparse betas'}
        model.results.xformBetas = val;
    case 'voxelbetas'
        model.results.voxelBetas = val;
    
    case {'r^2', 'varexplained', 'varianceexplained', 've'}
        model.results.var = val;
        
    %------------------
    % Paths
    %------------------
    case 'modeldir'
        model.paths.modelDir = val;
        d = smGet(model, 'modelDirFull');
        if ~isdir(d), mkdir(d); end
    case 'imagedir'
        model.paths.imageDir = val;
        d = smGet(model, 'imageDirFull');
        if ~isdir(d), mkdir(d); smSave(model); end
    case {'modelfile', 'modelname', 'model'}
        model.paths.modelFile = val;

    otherwise
        fprintf('[%s]: Unknown parameter %s.\n', mfilename, param);
end
%---------------------------------------------------------------------


return