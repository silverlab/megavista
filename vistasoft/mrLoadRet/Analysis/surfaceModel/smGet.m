function val = smGet(model, param, varargin)
% Main function to get values from a surface model of BOLD activity (see
% smMain.m). This is the only function that should be used to get any
% fields from an sm-model. 
% 
%   val = smGet(model, param);
%
% See also smSet.m

%---------------------------------------------------------------------
% MAIN SWITCH
switch lower(param)
    
    %------------------
    % Source of the data
    %------------------
    
    % -- dataTypes
    case {'datatype', 'dt', 'dtnum', 'dtnumber', 'dtn', 'datatypenumber'}
        if checkfields(model, 'session', 'dtNum')
            val = model.session.dtNum;
        else
            val = [];
        end
        
    case {'datatypename', 'dtname'}
        if checkfields(model, 'session', 'dtName')
            val = model.session.dtName;
        else
            val = [];
        end
    
    % -- scans
    case {'scans', 'scan'}
        if checkfields(model, 'session', 'scans')
            val = model.session.scans;
        else
            val = [];
        end

    % -- stimulus parameters
    case 'usestimulus'
        if checkfields(model, 'params', 'useStimulus')
            val = model.params.useStimulus;
        else
            val = [];
        end
            

    case 'instimwindow'
        if checkfields(model, 'data', 'stimulus', 'instimwindow')
            val = model.data.stimulus.instimwindow; 
        else
            val = [];
        end
        
    case {'stimsize', 'stim size', 'stimulus size', 'radius', 'stim radius', 'stimulus radius'}
        if checkfields(model, 'data', 'stimulus', 'stimsize')
            val = model.data.stimulus.stimsize;
        else
            val = [];
        end
    case {'stimres', 'stim res', 'stimulus res', 'resolution', 'stim resolution', 'stimulus resolution'}
        if checkfields(model, 'data', 'stimulus', 'stimres')
            val = model.data.stimulus.stimres;
        else
            val = [];
        end        
    case 'stimwindow'
        if checkfields(model, 'data', 'stimulus', 'stimwindow')
            val = model.data.stimulus.stimwindow;
        else
            val = [];
        end
        
    % -- project dir
    case {'projectdir', 'project'}
        if checkfields(model, 'session', 'projectDir')
            val = model.session.projectDir;
        else
            val = [];
        end

    %--t-Series
    case {'tseriesx', 'tseries.x'}
        pth = smGet(model, 'modelDirFull');
        pth = fullfile(pth, 'tSeries.mat');
        if exist(pth, 'file')
            load(pth);
            if isempty(varargin), val = tSeries.roiX.voxelTcs;
            else                  val = tSeries.roiX.voxelTcs(:,varargin{1}); end
        else
            val = [];
        end
        
    case {'tseriesy', 'tseries.y'}
        pth = smGet(model, 'modelDirFull');
        pth = fullfile(pth, 'tSeries.mat');
        if exist(pth, 'file')
            load(pth);
            if isempty(varargin), val = tSeries.roiY.voxelTcs;
            else                  val = tSeries.roiY.voxelTcs(:,varargin{1}); end
        else
            val = [];
        end

    case {'tseriesstimulus', 'tseries.stimulus', 'tseriesstim', 'stimulus tseries', 'tseries stimulus'}
        pth = smGet(model, 'modelDirFull');
        pth = fullfile(pth, 'tSeries.mat');
        if exist(pth, 'file')
            load(pth);
            if isempty(varargin), val = tSeries.stimulus.pixelTcs;
            else                  val = tSeries.stimulus.pixelTcs(:,varargin{1}); end
        else
            val = [];
        end

        
        
    case {'tseriespredictor', 'tseries predictor'}
        if smGet(model, 'useStimulus')
           if isempty(varargin), val = smGet(model, 'tSeries stimulus');
           else                  val = smGet(model, 'tSeries stimulus', varargin);
           end
        else
           if isempty(varargin), val = smGet(model, 'tSeries x');
           else                  val = smGet(model, 'tSeries x', varargin);
           end            
        end        
        
    case {'tseriesxtestdata', 'tseriesxtest','tseries.x.testdata', 'tseries.x.test'}
        vw = getCurView;
        scans = varargin{1};
        if strcmpi(smGet(model, 'roiXname'), 'stimulus')
            val = smGetStimulus(vw, model, scans);
        else
            val = voxelTSeries(vw, smGet(model, 'ROIXcoords'), scans);
        end

    case {'tseriesytestdata', 'tseriesytest','tseries.y.testdata', 'tseries.y.test'}
        vw = getCurView;
        scans = varargin{1};
        val = voxelTSeries(vw, smGet(model, 'ROIYcoords'), scans);
        
    case 'tseries'
        pth = smGet(model, 'modelDirFull');
        if exist(fullfile(pth, 'tSeries.mat'), 'file')
            load(fullfile(pth, 'tSeries.mat'));
            val = tSeries;
        else
            val = [];
        end

    case 'stimulus'
        if checkfields(model, 'data', 'stimulus')
            val = model.data.stimulus;
        else
            val = [];
        end

    %------------------
    % data
    %------------------
    case 'roix'
        if checkfields(model, 'data', 'roiX')
            val = model.data.roiX;
        else
            val = [];
        end

    case 'roiy'
        if checkfields(model, 'data', 'roiY')
            val = model.data.roiY;
        else
            val = [];
        end

    case 'roixname'
        if checkfields(model, 'data', 'roiX', 'name')
            val = model.data.roiX.name;
        else
            val = [];
        end
        
    case 'roiyname'
        if checkfields(model, 'data', 'roiY', 'name')
            val = model.data.roiY.name;
        else
            val = [];
        end

    case 'roixmesh'
        if checkfields(model, 'data', 'roiX', 'meshFile')
            val = model.data.roiX.meshFile;
        else
            val = [];
        end
        
    case 'roiymesh'
        if checkfields(model, 'data', 'roiY', 'meshFile')
            val = model.data.roiY.meshFile;
        else
            val = [];
        end
        
    case 'meshview'
        if checkfields(model, 'params', 'meshview')
            val = model.params.meshview;
        else
            val = [];
        end
        
    case {'roixcoords', 'xcoords'}
        if checkfields(model, 'data', 'roiX', 'coords')
            if isempty(varargin), val = model.data.roiX.coords;
            else val =  model.data.roiX.coords(:, varargin{1}); end
        else
            val = [];
        end

    case {'roiycoords', 'ycoords'}
        if checkfields(model, 'data', 'roiY', 'coords')
            if isempty(varargin), val = model.data.roiY.coords;
            else val =  model.data.roiY.coords(:, varargin{1}); end
        else
            val = [];
        end

    case {'stimulus indices', 'stim indices', 'stimindices', 'stimulus ind', 'stim ind', 'stimind'}
        if checkfields(model, 'data', 'stimulus', 'instimwindow')
            val = model.data.stimulus.instimwindow;            
        else
            val = [];
        end
        
        
    case {'roixind', 'roixindices', 'roixindex'}
        if checkfields(model, 'data', 'roiX', 'coords')
            if isempty(varargin), val = 1:size(model.data.roiX.coords,2);
            else
                inputCoords = varargin{1};
                if size(inputCoords,1) ~= 3, inputCoords = inputCoords'; end
                [commonCoords roiInd]  =  ...
                    intersectCols(model.data.roiX.coords, inputCoords);
                if ~isempty(roiInd), val = roiInd; 
                else
                    val = []; 
                    warning('No voxel found with these coordinates'); 
                end
            end
        else
            val = [];
        end

    case {'roiyind', 'roiyindices', 'roiyindex'}
        if checkfields(model, 'data', 'roiY', 'coords')
            if isempty(varargin), val = 1:size(model.data.roiY.coords,2);
            else
                inputCoords = varargin{1};
                if size(inputCoords,1) ~= 3, inputCoords = inputCoords'; end
                [commonCoords roiInd]  =  ...
                    intersectCols(model.data.roiY.coords, inputCoords);
                val = roiInd;                    
                if length(roiInd) < size(inputCoords,2)
                    warning('No coords found for %d voxels',...
                        size(inputCoords,2)-length(roiInd));  %#ok<WNTAG>
                end
            end
        else
            val = [];
        end

    case 'stimulus'
        if checkfields(model, 'data', 'stimulus')
            val = model.data.stimulus;
        else
            val = [];
        end
        
    %------------------
    % Analysis parameters
    %------------------

    % -- Basis Set
    case 'basistype'
        if checkfields(model, 'params', 'basisType')
            val = model.params.basisType;
        else
            val = [];
        end

    case {'nbasisfunctions', 'numberbasis', 'numbasis', 'n basis', 'num basis'}
        if checkfields(model, 'params', 'nBasisFunctions')
            val = model.params.nBasisFunctions;
        else
            val = [];
        end
        
    case {'npredictors', 'number predictors', 'numpredictors', 'n predictors', 'num predictors'}
        if smGet(model, 'useStimulus')
            val = length(smGet(model, 'stimulus indices'));            
        else
            val = length(smGet(model, 'roiXind'));
        end
        
    case {'basisset', 'basis set', 'basis'}
        pth = smGet(model, 'modelDirFull');
        pth = fullfile(pth, 'basis.mat');
        if exist(pth, 'file')
            load(pth);            
            val = basisSet;
        else
            val = [];
        end

    case {'latent', 'pcvar', 'pcvariance', 'pclatent', 'basisvar', 'basis variance', 'basis variance explained'}
        pth = smGet(model, 'modelDirFull');
        pth = fullfile(pth, 'basis.mat');
        if exist(pth, 'file')
            load(pth);
            % We might want the variance explained for all the basis
            % functions or for only a subset.
            if isempty(varargin),
                nBasisFunctions = smGet(model, 'nBasisFunctions');
                val = basisSet.var(1:nBasisFunctions);
            else val =basisSet.var(varargin{1});
            end
        else
            val = [];
        end
                
    case {'score', 'pcscores', 'scores', 'pcscore', 'basis projection', 'basis projections', 'xform score', 'xform scores', 'xform projection'}
        pth = smGet(model, 'modelDirFull');
        pth = fullfile(pth, 'basis.mat');
        if exist(pth, 'file')
            load(pth);
            nBasisFunctions = smGet(model, 'nBasisFunctions');
            val = basisSet.projection(:, 1:nBasisFunctions);            
        else
            val = [];
        end

        
    case {'coeff', 'pccoeff', 'coeffs', 'pccoeffs', 'basis functions', 'xform functions'}
       pth = smGet(model, 'modelDirFull');
        pth = fullfile(pth, 'basis.mat');
        if exist(pth, 'file')
            load(pth);
            % Why would there be a varargin? When would we want fewer basis
            % functions than are stored?
            if isempty(varargin),
                nBasisFunctions = smGet(model, 'nBasisFunctions');
                val = basisSet.functions(:, 1:nBasisFunctions);
            else val = basisSet.functions(:, varargin{1});
            end
        else
            val = [];
        end
           
    % -- Regression
    case {'regressionmethod', 'regression', 'regress', 'regressiontype'}
       if checkfields(model, 'params', 'regressionMethod')
            val = model.params.regressionMethod;
        else
            val = [];
        end

    case {'useresiduals' , 'residuals'}
       if checkfields(model, 'params', 'useResiduals')
           val = model.params.useResiduals;
       else
           val = [];
       end
       
    %------------------
    % Results
    %------------------    
    case {'xform betas' 'xformbetas' 'transform betas' 'sparse betas'}
        if checkfields(model, 'results', 'xformBetas')
            if isempty(varargin), val = model.results.xformBetas;
            else val = model.results.xformBetas(varargin{1}, :); end
        else
            val = [];
        end
        
    case 'voxelbetas'
        if checkfields(model, 'results', 'voxelBetas')
            if isempty(varargin), val = model.results.voxelBetas;
            else val = model.results.voxelBetas(varargin{1}, :); end
        else
            val = [];
        end

    case {'r^2', 'varexplained', 'varianceexplained'}
        if checkfields(model, 'results', 'var')
            if isempty(varargin),  val = model.results.var;
            else val = model.results.var(varargin{1}); end
        else
            val = [];
        end

    %------------------
    % Paths
    %------------------
    case 'modeldir'
        if checkfields(model, 'paths', 'modelDir')
            val =  model.paths.modelDir;
        else
            val = [];
        end
        
    case 'modeldirfull'
        if checkfields(model, 'paths', 'modelDir')
            dt = smGet(model, 'dtname');
            val = fullfile...
                ('Gray', dt, model.paths.modelDir);
        else
            val = [];
        end

    case {'modelfile', 'modelname'}
        % note: when getting model dir, add 'Gray'/dataType/
        if checkfields(model, 'paths', 'modelFile')
            val = model.paths.modelFile;
        else
            val = [];
        end

    case {'modelfilefull', 'modelnamefull'}
        % note: when getting model dir, add 'Gray'/dataType/
        if checkfields(model, 'paths', 'modelFile')
            modelDirFull = smGet(model, 'modelDirFull');
            val = fullfile...
                (modelDirFull, model.paths.modelFile);
        else
            val = [];
        end

    case {'imagedir', 'imagesdir'}
        % check to see if imageDir is defined in the model
        if checkfields(model, 'paths', 'imageDir')
            val =  model.paths.imageDir;    
        else
            % check to see whether a dir called 'Images' exists
            modelDirFull = smGet(model, 'modelDirFull');
            thepath = fullfile(modelDirFull, 'Images');
            if ~exist(thepath, 'dir')
                disp('Image directory does not exist. Creating one now.');
                model = smSet(model, 'imagedir', 'Images');
                val = model.paths.imageDir;
            else
                val = 'Images';
            end
        end        
            
    case {'imagedirfull', 'imagedirfull'}
        imageDir = smGet(model, 'imageDir');
        modelDirFull = smGet(model, 'modelDirFull');
        val = fullfile(modelDirFull, imageDir);
        
    otherwise
        val = [];
        fprintf('[%s]: Unknown parameter %s.\n', mfilename, param);
               
end
%---------------------------------------------------------------------

return