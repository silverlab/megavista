function model = smGetTseries(vw, model)
% Get the tSeries for the two ROIs for a surface model of BOLD activity
% (see smMain.m).
%
%  model = smGetTseries(vw, model)

% --------------------------
% Predictor ROI
% --------------------------
scans = smGet(model, 'scans');

useStimulus = smGet(model, 'useStimulus');

if useStimulus,
    fprintf(1, '[%s]: Getting t-series for stimulus ...\n', ...
        mfilename); drawnow;   
    stimulus = smGetStimulus(vw, model, scans);
    stimulus = stimulus.tSeries;

    % Eliminate nans. These cause trouble.
    stimulus.pixelTcs(isnan(stimulus.pixelTcs)) = 0;
    
    % Save it
    model = smSet(model, 'tSeries stimulus', stimulus);

else
    xCoords = smGet(model, 'roiXcoords');
    if ~isempty(xCoords)
        xName = smGet(model, 'roiXname');
        fprintf(1, '[%s]: Getting t-series for predictor ROI (%s)...\n', ...
            mfilename, xName); drawnow;
        
        if smGet(model, 'useResiduals')
            [x.voxelTcs, x.coords] = ...
                smGetTseriesResiduals(vw, model, xCoords, scans);
        else
            [x.voxelTcs, x.coords] = ...
                voxelTSeries(vw, xCoords, scans);
        end
        % Eliminate nans. These cause trouble.
        x.voxelTcs(isnan(x.voxelTcs)) = 0;
        
        % Save it
        model = smSet(model, 'tSeries x', x);
    end
end


% --------------------------
% roiY - outcome ROI
% --------------------------
yCoords = smGet(model, 'roiYcoords');

yName = smGet(model, 'roiYname');

fprintf(1, '[%s]: Getting t-series for dependent ROI (%s)...\n', ...
    mfilename, yName); drawnow;


if smGet(model, 'useResiduals')
    [y.voxelTcs, y.coords] = ...
        smGetTseriesResiduals(vw, model, yCoords, scans);
else
    [y.voxelTcs, y.coords] =...
        voxelTSeries(vw, yCoords, scans);
end

% Eliminate nans. These cause trouble.
y.voxelTcs(isnan(y.voxelTcs)) = 0;

% Save it
model = smSet(model, 'tSeries y', y);


return