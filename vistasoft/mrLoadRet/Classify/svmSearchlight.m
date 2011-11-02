function svmSearchlight(path, foldIteration, growByVoxels, varargin)
    global growBy
    global dims
    global svm
    global options
    
    % Do some weird juggling so I can have these are global.  I know
    % globals are cruddy to use, but they allow me to do some more
    % efficient stuff with cellfun.
    tic;
    if (notDefined('path')), path = pwd; end
    if (notDefined('foldIteration')), foldIteration = [1 1 1]; end
    if (notDefined('growByVoxels')), growByVoxels = 3; end

    growBy = growByVoxels;
    fold = foldIteration(1);
    foldsPerCall = foldIteration(3);
    folds = foldIteration(2) * foldsPerCall;

    curdir = pwd;
    cd(path);
    
    options = svmInitOptions(varargin{:});
    options.verbose = false;
    
    vw = initHiddenInplane;
    global mrSESSION
    
    vw.ROIs(1).name = 'searchlight';
    vw.ROIs(1).coords = [1; 1; 1];
    vw.selectedROI = 1;
    rs = upSampleFactor(vw);
    
    % 
    data = mrSESSION.functionals(1);
    sz = data.cropSize;
    xlen = sz(1);
    ylen = sz(2);
    zlen = length(data.slices);
    dims  = [xlen; ylen; zlen];
    
    % 
    xvals = 1:xlen;
    yvals = 1:ylen;
    zvals = 1:zlen;
    total = xlen * ylen * zlen;
    
    % Generate 3 x nCoords matrix of all coordinates in inplane space
    xCoords = reshape(repmat(xvals, [ylen*zlen 1]), [1 xlen*ylen*zlen]);
    yCoords = repmat(reshape(repmat(yvals, [zlen 1]), [1 ylen*zlen]), [1 xlen]); 
    zCoords = repmat(zvals, [1 xlen*ylen]);
    allCoords = [xCoords; yCoords; zCoords];
    
    %
    vw.ROIs(1).coords = allCoords .* repmat(rs', [1 total]);
    svm = svmInit('view', vw, 'measure', 'tscores');

    
    % Generate start/end indices for partitions to process in parallel
    nPerFold    = floor(total / folds);
    tmp         = ones(1, folds) * nPerFold;
    sInds       = tmp .* (0:(folds - 1)) + 1;
    eInds       = tmp .* (1:folds);
    eInds(end)  = total;
    
    runFolds = (((fold - 1) * foldsPerCall):(fold * foldsPerCall - 1)) + 1;
    for i = runFolds
        homeDir = viewGet(vw, 'homedir');
        filename = sprintf('%s/searchlight%04d.mat', homeDir, i);
        if (exist(filename, 'file'))
            fprintf('[%d/%d] Fold already completed.  Proceeding...', i, folds);
            continue;
        end
        sInd    = sInds(i);
        eInd    = eInds(i);
        count   = eInd - sInd + 1;
        coords  = allCoords(:, sInd:eInd);
        allCoordsCell = mat2cell(coords, 3, ones(1, count));

        fprintf('[%d/%d] Computing coordinates...', i, folds);
        cubes = cellfun(@growCube, ...
            allCoordsCell, ...
            'UniformOutput', false);
        fprintf('done.\n');

        fprintf('[%d/%d] Running models...', i, folds);
        meanAccs = cellfun(@svmRunWrapper, ...
             cubes, ...
            'UniformOutput', false);
        fprintf('done.\n');

        fprintf('[%d/%d] Saving...', i, folds);
        time = toc;  
        save(filename, 'meanAccs', 'coords', 'growBy', 'time','-v7.3');
        fprintf('done.\n');
    end
    
    if (isSearchlightComplete(homeDir, folds))
        fprintf('Processing completed searchlight...');
        processSearchlight(homeDir, folds);
    end
    
    cd(curdir);
end

function cubeCoords = growCube(center)
    global growBy
    global dims
    
    minmax = repmat(center, [1 2]);
    minmax(:, 1) = minmax(:, 1) - growBy;
    minmax(:, 2) = minmax(:, 2) + growBy;
    if (sum(minmax(:,1) < 1) || sum(minmax(:,2) > dims)), cubeCoords = []; return; end % out of bounds
    
    cubewidth = growBy * 2 + 1;
    xcoords = reshape(repmat(minmax(1, 1):minmax(1, 2), [cubewidth^2 1]), [1 cubewidth^3]);
    ycoords = repmat(reshape(repmat(minmax(2, 1):minmax(2, 2), [cubewidth 1]), [1 cubewidth^2]), [1 cubewidth]);
    zcoords = repmat(minmax(3, 1):minmax(3, 2), [1 cubewidth^2]);
    
    cubeCoords = [xcoords; ycoords; zcoords];
end

function meanAcc = svmRunWrapper(cubeCoords)
    global svm
    global options
    
    if (isempty(cubeCoords)), meanAcc = []; return; end
    svmTmp = svm;
    [cTrans svmInds] = intersectCols(svm.coords, cubeCoords);
    svmTmp.data = svm.data(:, svmInds);
    svmTmp.coords = [];
    svmTmp.voxel = [];
    [models meanAcc] = svmRun(svmTmp, 'options', options);
end

function bool = isSearchlightComplete(homeDir, folds)
    for i = 1:folds
        if (~exist(sprintf('%s/searchlight%04d.mat', homeDir, i), 'file'))
            bool = false;
            return;
        end
    end
    bool = true;         
end

function processSearchlight(homeDir, folds)
    global dims
    global svm
    
    svm.data = []; % this is to save space
    totalTime = 0;
    coords = [];
    map{1} = zeros(dims(1), dims(2), dims(3));
    for i = 1:folds
        filename = sprintf('%s/searchlight%04d.mat', homeDir, i);
        tmp = load(filename);
        coords = [coords tmp.coords];
        nCoords = length(tmp.coords);
        for j = 1:nCoords
            if (~isempty(tmp.meanAccs{j}))
                map{1}(tmp.coords(1, j), tmp.coords(2, j), tmp.coords(3, j)) = tmp.meanAccs{j};
            end
        end
        totalTime = totalTime + tmp.time;
        delete(filename);
    end
    growBy = tmp.growBy;
    fprintf('done.\n');
    
    filename = sprintf('%s/searchlight.mat', homeDir);
    mapName = 'searchlight';
    save(filename, 'map', 'mapName', 'coords', 'growBy', 'svm', '-v7.3');
    fprintf('Searchlight complete in %0.2f seconds.\n', totalTime);
    fprintf('Saved to: %s\n', filename); 
end
