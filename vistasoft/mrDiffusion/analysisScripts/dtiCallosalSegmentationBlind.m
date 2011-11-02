% This script can be used to generate summary files for the callosal
% segmentation in normals and blind patients.
% 
% This script does the following:
% 1. Generates the paths using a variant of MetroTrac
% 2. Runs resampling of the paths
% 3. Cleans and saves the fiber groups
% 4. Summarizes the properties of the fiber groups

doControls   = false;
mmBeyond     = 35;

outDir = '/biac2/wandell2/data/DTI_Blind';

if doControls
    baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults/*0*';
    % skip these subjects in the normally sighted group
    skipSubjectList = { 'ams051015','bw040922','dla050311','gd040901',...
        'jl040806','kt040517','rk050524','sc060523','sd050527','sr040513',...
        'tl051015' };
    sumFileSuffix = 'Normals';
else
    baseDir = '/biac2/wandell2/data/DTI_Blind/*0*';
    % skip these subjects in the blind group
    skipSubjectList = { 'mm021126' };
    sumFileSuffix = 'Blind';
end

% set the names of the output files
outFileName   = sprintf('segDataClean_%s',sumFileSuffix);
avgTensorFile = sprintf('avgCCTensor_%s',sumFileSuffix);

% locate the individual dt6 files
[f,sc] = findSubjects(baseDir, '*_dt6', skipSubjectList);

% create log file
logFile = fopen(fullfile(outDir,['callosalSegLog_' datestr(now,'yymmdd_HHMM') '.txt']),'at');
s = license('inuse'); userName = s(1).user;
fprintf(logFile, '* * * Analysis run by %s on %s * * *\n', userName, datestr(now,31));

N = length(f);
maxFiberLen = 250;

% set up parameters for different segments
segNames = {'Occ','Temp','PostPar','SupPar','SupFront','AntFront','Orb'};%,'LatFront'};
nSegs = length(segNames);
% NaN means no clip plane, 0 means clip at the SI/LR plane passing
% through the CC midpoint, -1 clips at the SI/LR plane passing
% through the posterior edge of the CC, and +1 clips at the
% anterior edge of the CC.
% We clip fibers from the anterior frontal FGs that go too
% far posterior. (eg. some tapetum fibers that make a wrong
% turn pass through the anterior frontal ROI.), and similarly
% for posterior FGs that extend too far anterior.
clipPlane = [0 NaN 0 0.166 NaN 0 0];
colors = [20 200 20; 200 20 200; 200 200 20; 20 90 200; 200 20 20; 235 165 55; 55 165 235; 20 20 100];

clear segs;
segs = zeros(nSegs+1,1);
for ii=1:nSegs
    segs(ii).name      = segNames{ii};
    segs(ii).roi       = ['Mori_%s' segNames{ii}];
    segs(ii).color     = colors(ii,:);
    segs(ii).clipPlane = clipPlane(ii);
end
segs(end+1).name = 'Scraps';
segs(end).color  = [100 100 100];

% % % % % % % % % % % % % % % % % %
% generate callosal fiber groups  %
% % % % % % % % % % % % % % % % % % 

% Find the fibers by intersecting with pre-defined ROIs
clear fg subCode fileName;
nSubs   = 0;
allSegs = 1:nSegs;
for ii=1:N
    clear newFg;
    fname = f{ii};
    disp(['Processing ' fname '...']);
    fprintf(logFile, ['Processing ' fname ': ']);

    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath   = fullfile(fileparts(fname), 'ROIs');

    % check if roi directory exists AND roi definition for CC exists
    if ~exist(roiPath,'dir') || ~exist(fullfile(roiPath, 'CC_FA.mat'),'file')
        disp('no CC_FA roi - skipping...');
        fprintf(logFile, 'no CC_FA roi - skipping.\n');
        continue;
    end
    cc = dtiReadRoi(fullfile(roiPath, 'CC_FA'));

    % skip if number of Mori ROIs is less than expected (at least 10)
    if length(dir(fullfile(roiPath,'Mori_*'))) < 10
        disp('no Mori ROIs found - skipping...');
        fprintf(logFile, 'no Mori ROIs - skipping.\n');
    else
        try
            % Load all the ROIs
            roiL = zeros(nSegs,1);
            roiR = zeros(nSegs,1);
            for jj=1:nSegs
                roiL(jj) = dtiReadRoi(fullfile(roiPath, sprintf(segs(jj).roi,'L')));
                roiR(jj) = dtiReadRoi(fullfile(roiPath, sprintf(segs(jj).roi,'R')));
            end
        catch
            disp('some Mori ROIs missing - skipping...');
            fprintf(logFile, 'some missing Mori ROIs - skipping.\n');
            continue;
        end

        % load and clean left and right callosal fibers
        lfgName = fullfile(fiberPath,'LFG+CC_FA.mat');
        rfgName = fullfile(fiberPath,'RFG+CC_FA.mat');
        fgL     = dtiReadFibers(fullfile(fiberPath,'LFG+CC_FA.mat'));
        fgL     = dtiCleanFibers(fgL,[],maxFiberLen);
        fgR     = dtiReadFibers(fullfile(fiberPath,'RFG+CC_FA.mat'));
        fgR     = dtiCleanFibers(fgR,[],maxFiberLen);

        for jj=1:nSegs
            tmpFgL = dtiIntersectFibersWithRoi(0, {'and'}, 1, roiL(jj), fgL);
            tmpFgR = dtiIntersectFibersWithRoi(0, {'and'}, 1, roiR(jj), fgR);
            % Remove fibers that intersect with other ROIs with exception for temp
            % fibers do not exclude those that follow ILF into orb and anterior
            % frontal ROIs
            if jj==2
                tmpFgL = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:jj-1,jj+1:5]), tmpFgL);
                tmpFgR = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiR([1:jj-1,jj+1:5]), tmpFgR);
            else
                tmpFgL = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL([1:jj-1,jj+1:nSegs]), tmpFgL);
                tmpFgR = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiR([1:jj-1,jj+1:nSegs]), tmpFgR);
            end

            if ~isnan(segs(jj).clipPlane)
                ccLength = max(cc.coords(:,2))-min(cc.coords(:,2));
                ccMid = min(cc.coords(:,2))+ccLength/2;
                apClip = segs(jj).clipPlane*0.5*ccLength+ccMid;
                tmpFgL = dtiCleanFibers(tmpFgL, [NaN apClip NaN]);
                tmpFgR = dtiCleanFibers(tmpFgR, [NaN apClip NaN]);
            end
            newFg(1,jj,1)          = tmpFgL;
            newFg(1,jj,1).name     = [segs(jj).name 'L'];
            newFg(1,jj,1).colorRgb = segs(jj).color;
            newFg(1,jj,2)          = tmpFgR;
            newFg(1,jj,2).name     = [segs(jj).name 'R'];
            newFg(1,jj,2).colorRgb = segs(jj).color;
            newFg(1,jj,3)          = dtiMergeFiberGroups(tmpFgL,tmpFgR);
            newFg(1,jj,3).name     = [segs(jj).name 'Both'];
            newFg(1,jj,3).colorRgb = segs(jj).color;
        end
        
        % The last ROI is for the 'scraps'- those not caught by any ROI
        newFg(1,nSegs+1,1)      = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiL(1:nSegs), fgL);
        newFg(1,nSegs+1,2)      = dtiIntersectFibersWithRoi(0, {'not'}, 1, roiR(1:nSegs), fgR);
        newFg(1,nSegs+1,3)      = dtiMergeFiberGroups(newFg(1,nSegs+1,1),newFg(1,nSegs+1,2));
        newFg(1,nSegs+1,1).name = 'ScrapsL';
        newFg(1,nSegs+1,2).name = 'ScrapsR';
        newFg(1,nSegs+1,3).name = 'ScrapsBoth';

        nSubs = nSubs+1;
        fg(nSubs,:,:)   = newFg;
        subCode(nSubs)  = sc(ii);
        fileName(nSubs) = f(ii);
        fprintf(logFile, 'SUCCESS!\n');
    end
end
clear cc tmpFgL tmpFgR roiL roiR fgL fgR newFg;
fclose(logFile);

% % % % % % % % % % % % % % % % % % % % 
% align fiber coordinates to mid-sag  %
% % % % % % % % % % % % % % % % % % % %

% number of 1-mm steps per fiber
nSamplesPerFiber = mmBeyond*2+1;

ccCoords = cell(nSubs,1);
fiberCC  = zeros(size(fg));
for ii=1:nSubs
    fname = fileName{ii};
    disp(sprintf('Extracting points for %d of %d: %s...', ii, nSubs, subCode{ii}));

    fiberPath = fullfile(fileparts(fname), 'fibers');
    roiPath   = fullfile(fileparts(fname), 'ROIs');
    cc        = dtiReadRoi(fullfile(roiPath, 'CC_FA'));

    % find mid-sag fiber crossings
    ccCoords{ii} = cc.coords(cc.coords(:,1)==min(abs(cc.coords(:,1))),:)';

    for kk=1:size(fg,2)
        for ll=1:size(fg,3)
            nFibers = length(fg(ii,kk,ll).fibers);
            fiberCC(ii,kk,ll).fiberCoord = zeros(3,nFibers,nSamplesPerFiber)*NaN;
            for jj=1:nFibers
                % For each fiber point, find the nearest CC ROI point
                [nearCoords, distSq] = nearpoints(fg(ii,kk,ll).fibers{jj}, ccCoords{ii});
                % For all fiber points, select the one that is closest to a
                % midSag point. We'll store this one as the point where this
                % fiber passes through the mid sag plane.
                nearest = find(distSq==min(distSq));
                nearest = nearest(1);
                fiberCC(ii,kk,ll).dist(jj) = sqrt(distSq(nearest));
                fiberCoords = nearest-mmBeyond:nearest+mmBeyond;
                fiberCoords(fiberCoords<1) = NaN;
                fiberCoords(fiberCoords>size(fg(ii,kk,ll).fibers{jj},2)) = NaN;
                fiberCC(ii,kk,ll).fiberCoord(:,jj,~isnan(fiberCoords)) = ...
                    fg(ii,kk,ll).fibers{jj}(:,fiberCoords(~isnan(fiberCoords)));
            end
        end
    end
    ccCoords{ii} = ccCoords{ii}(2:3,:);
end
clear cc fg;

% % % % % % % % % % % % % % % % % % % % % % %
% create dt6 matrices for the fiber groups  %
% % % % % % % % % % % % % % % % % % % % % % %

fiberDt6Tri = cell(size(fiberCC));
fiberDt6NN  = cell(size(fiberCC));
for ii=1:nSubs
    disp(sprintf('Loading tensors for %d of %d: %s (SLOW!)...', ii, nSubs, subCode{ii}));
    dt = load(fileName{ii}, 'dt6','xformToAcPc');
    for jj=1:size(fiberCC,2) % different segments
        for kk=1:size(fiberCC,3) % left, right, and both
            nFibers = size(fiberCC(ii,jj,kk).fiberCoord,2);
            coords  = reshape(fiberCC(ii,jj,kk).fiberCoord,3,nFibers*nSamplesPerFiber);
            coords  = mrAnatXformCoords(inv(dt.xformToAcPc), coords);
            % Trilinear interpolation
            tdt6 = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','trilin');
            fiberDt6Tri{ii,jj,kk} = reshape(tdt6, nFibers, nSamplesPerFiber, 6);
            % Do it again using nearest-neighbor interpolation
            tdt6 = dtiGetValFromTensors(dt.dt6, coords, [], 'dt6','nearest');
            fiberDt6NN{ii,jj,kk} = reshape(tdt6, nFibers, nSamplesPerFiber, 6);
        end
    end
end

% % % % % % % % % % %
% save the outputs  %
% % % % % % % % % % %

save(fullfile(outDir,outFileName),'subCode','fileName','ccCoords',...
    'fiberCC','segs','fiberDt6Tri','fiberDt6NN');

% % % % % % % % % % % % % % % % % % % % % % % % %
% calculate mean tensor along each fiber group  %
% % % % % % % % % % % % % % % % % % % % % % % % %

avgFiberDt6NN = repmat(struct( 'M', zeros(nSamplesPerFiber,6,nSubs)*NaN, ...
    'S', zeros(nSamplesPerFiber,nSubs)*NaN, ...
    'N', zeros(1,nSubs) ), size(fiberDt6NN,2), 1 );
for ii=1:nSubs
    for jj=1:(size(fiberDt6NN,2)-1)
        avgFiberDt6NN(jj).name = segNames{jj};
        
        dt6              = shiftdim(fiberDt6NN{ii,jj,3},1);
        dt6(isnan(dt6))  = 1e-50;
        dt6(dt6==0)      = 1e-50;
        [eigVec,eigVal]  = dtiEig(dt6);
        eigVal(eigVal<0) = 1e-50;
        logDt6           = dtiEigComp(eigVec,log(eigVal));
        [M,S,N]          = dtiLogTensorMean(logDt6);
        
        avgFiberDt6NN(jj).M(:,:,ii) = M;
        avgFiberDt6NN(jj).S(:,ii) = S;
        avgFiberDt6NN(jj).N(ii) = N;
    end
end

save(fullfile(outDir,avgTensorFile),'subCode','fileName','segs','avgFiberDt6NN');
