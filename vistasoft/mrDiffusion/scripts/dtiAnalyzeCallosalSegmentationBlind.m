% Analyzes the callosal segmentation data. The data must be extracted and
% sumarized by the dtiCallosalSegmentationBlind script before you can run
% this script.
%
% The segmentation data have been summarized by doing the following for all
% fibers:
% - load the CC ROI and use this to find the user-defined mid-sagittal plane.
% - for each fiber, find the point that falls nearest to one of the CC ROI
% points.
%
% fiberCC is an NSubjects x numSegments struct array.  The struct is:
% fiberCoord: the coordinates of each fiber at the position within that fiber
% closest to the mid-sagittal plane.
% dist: the distance of each fiberCoord to its nearest CC ROI point


nnInterp      = true;
erodeCc       = false;
verbose       = true; % true -> lots of intermediate stuff (may generate hundreds of figs!)
nFiberSamples = 0; % number of fiber samples on both sides of mid point; 1 means mid point along the fiber; <1 means all

% % % % % % % % % % % % % % % %
% load summarized data files  %
% % % % % % % % % % % % % % % %

% these were created with dtiCallosalSegmentationBlind
if ispc
    baseDir = '\\white.stanford.edu\biac2-wandell2\data\DTI_Blind';
else
    baseDir = '/biac2/wandell2/data/DTI_Blind';
end

tmp1    = load(fullfile(baseDir, 'segDataClean_Normals.mat'));
tmp2    = load(fullfile(baseDir, 'segDataClean_Blind.mat'));

% get segs structure
segs     = tmp1.segs;
nSegs    = size(segs,2);
segNames = {segs.name};

% setup groups
groups    = {'Normals','Blind'};
nGroups   = 2;
groupCode = [ones(1,size(tmp1.fiberCC,1)) ones(1,size(tmp2.fiberCC,1))*2];

% combine the data in different groups into one
subCode = [tmp1.subCode tmp2.subCode];
fiberCC = vertcat(tmp1.fiberCC, tmp2.fiberCC);
if nnInterp
    fiberDt6 = vertcat(tmp1.fiberDt6NN, tmp2.fiberDt6NN);
else
    fiberDt6 = vertcat(tmp1.fiberDt6Tri, tmp2.fiberDt6Tri);
end
ccCoords = horzcat(tmp1.ccCoords, tmp2.ccCoords);
clear tmp1 tmp2;

nSubs     = size(fiberCC,1);
normals   = groupCode==1;
patients  = groupCode==2;
nNormals  = sum(normals);
nPatients = sum(patients);

% % % % % % % % %
% clean CC ROIs %
% % % % % % % % %

% Clean up the CC ROIs by removing fiber crossing points that are too far
% from the CC ROI, filling holes, and eroding edge pixels (if desired).
% The resulting ROIs should each be a 1mm-spaced grid of voxel centers.

% find boundaries for cc coordinates
ccExtrema = [ min([ccCoords{:}]')-1; max([ccCoords{:}]')+1 ];
ccSz      = diff(ccExtrema)+1;

if verbose, figure; end

for ii=1:nSubs
    % defined a "box" that containes the cc
    % set cc coordinates relative to ccExtrema(1,:)
    ccBox  = zeros(ccSz);
    coords = ccCoords{ii};
    coords = round(coords-repmat(ccExtrema(1,:)',1,size(coords,2))+1);

    % set cc "pixels" to 1, fill holes
    ccBox(sub2ind(ccSz, coords(1,:), coords(2,:))) = 1;
    ccBoxCleaned = imfill(ccBox==1,'holes');

    % erode edges if erodeCc is true
    if erodeCc
        ccBoxCleaned = imerode(ccBoxCleaned==1,strel('square',2));
    end
    
    % showing cc for each subject
    if verbose
        subplot(ceil(sqrt(nSubs)),floor(sqrt(nSubs)),ii);
        imagesc(ccBoxCleaned'); axis xy image off;
        title(subCode(ii));
    end
    % figure; imagesc(reshape(ccBox-ccBoxCleaned,ccSz)'); axis xy image;

    [x,y]  = ind2sub(ccSz, find(ccBoxCleaned==1));
    coords = [x,y]';
    coords = coords+repmat(ccExtrema(1,:)',1,size(coords,2))-1;

    ccCoordsCleaned{ii} = coords;
end

% get the number of samples per fiber
nSamplesPerFiber = size(fiberCC(1,1,1).fiberCoord,3);

% get the mid point along the fiber
midFiberSample = round((nSamplesPerFiber+1)/2);

% define which fiber points to be analyzed
if nFiberSamples==1
    fiberSampPts = midFiberSample;
elseif nFiberSamples<1
    fiberSampPts = [1:nSamplesPerFiber];
else
    fiberSampPts = [midFiberSample-nFiberSamples:midFiberSample+nFiberSamples];
end

% to be sure we catch all fibers within the bulk of the ROI, the minimum
% minDist is sqrt(.5^2+.5^2)=.7071, which is the distance from the center of a
% 1mm pixel to any corner of that pixel. 
minDist = .71;

for ii=1:nSubs
    ccYZCoords{ii} = ccCoordsCleaned{ii}';
    nCcCoords = size(ccYZCoords{ii},1);
    for jj=1:nSegs
        for hs=1:2
            clear fiberYZ;
            tmp = fiberCC(ii,jj,hs).fiberCoord;
            fiberYZ(:,1) = squeeze(tmp(2,:,midFiberSample));
            fiberYZ(:,2) = squeeze(tmp(3,:,midFiberSample));
            [fiberNearestCC{ii,jj,hs},distSq] = nearpoints2d(fiberYZ', ccYZCoords{ii}');
            goodPts = distSq < minDist.^2;
            fiberNearestCC{ii,jj,hs}(~goodPts) = [];
            fiberCoord{ii,jj,hs} = fiberYZ(goodPts,:);
        end
        % Compute the fiber intersection density for each point in the ccRoi
        ccYZDensity{ii,jj} = hist([fiberNearestCC{ii,jj,:}],[1:nCcCoords]);
    end
end


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% create figure showing callosal segmentation on mid-sag plane  %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

barColor = [0.0784 0.7843 0.0784; 0.7843 0.0784 0.7843; 0.7843 0.7843 0.0784;0.0784 0.3529 0.7843;...
       0.7843 0.0784 0.0784; 0.9216 0.6471 0.2157; 0.2157 0.6471 0.9216; .75 .75 .75];

%% Assign a unique segment to each ccRoi point
%
ccBounds = [min(vertcat(ccYZCoords{:,:})); max(vertcat(ccYZCoords{:,:}))];
r = ceil(sqrt(nSubs));
c = ceil(nSubs/r);
fh = figure;
% mrUtilResizeFigure(gcf,1600,800,1);
for(ii=1:nSubs)
    % What if there are multiple maxima? The following will take the first.
    % This is actually quite rare for our data, so doing something more
    % intelligent isn't necessary.
    [junk,ccSegAssignment{ii}] = max(vertcat(ccYZDensity{ii,:}));
    ccSegAssignment{ii}(junk==0) = 0;
    subplot(r,c,ii); hold on;
    % Assign the un-assigned points (use the same color as the scaps)
    goodPts = ccSegAssignment{ii}==0;
    h = plot(ccYZCoords{ii}(goodPts,1), ccYZCoords{ii}(goodPts,2), '.');
    set(h,'Color',barColor(nSegs,:));
    for(jj=nSegs:-1:1)
        goodPts = ccSegAssignment{ii}==jj;
    	h = plot(ccYZCoords{ii}(goodPts,1), ccYZCoords{ii}(goodPts,2), '.');
        set(h,'Color',barColor(jj,:));
    end
    % plot the anterior commissure for anatomical reference
    plot(0,0,'ko');
    axis xy image off; axis(ccBounds(:)');
    contour(ccYZCoords{ii}(:,1), ccYZCoords{ii}(:,2), ones(size(ccYZCoords{ii}(:,1))), 1, 'k-','LineWidth',1);
    title(subCode(ii));
    hold off;
end
% Draw a 1cm scale bar
subplot(r,c,ii);
line([-30 -20],[0 0],'Color','k','LineWidth',3);
pause(3); % allow time to finish rendering


mrUtilPrintFigure(fullfile(baseDir,'allSubsAllSegs'), fh);
%% Initialize vars and get subject list

clear all;
close all;

if(ispc)
    baseDir = '//171.64.204.10/biac2-wandell2/data/reading_longitude/dti/cc_segmentationData';
    addpath //171.64.204.10/home/bob/matlab/stats
else
    baseDir = '/biac2/wandell2/data/reading_longitude/dti/cc_segmentationData';
    addpath /home/bob/matlab/stats
end

dataTableName = 'ccSegmentationData';
tTestTableName = 'ccSegmentation_ttests';

erodeCc = false;
clipByMd = false;
nFiberSamps = 0; % <1 means all
nnInterp = true;
outDirName = 'all';
% to be sure we catch all fibers within the bulk of the ROI, the minimum
% minDist is sqrt(.5^2+.5^2)=.7071, which is the distance from the center of a
% 1mm pixel to any corner of that pixel. 
minDist = .71;
useMedian = false;

verbose = false; % true -> lots of intermediate stuff (may generate hundreds of figs!)

figDefaults = 'set(gca,''FontSize'',14,''FontName'',''Helvetica'');';
hemiName = {'left','right'};

% Graph Globals
barColor = [0.0784 0.7843 0.0784; 0.7843 0.0784 0.7843; 0.7843 0.7843 0.0784;0.0784 0.3529 0.7843;...
       0.7843 0.0784 0.0784; 0.9216 0.6471 0.2157; 0.2157 0.6471 0.9216; .75 .75 .75];
tickLabels = { 'Occipital', 'Temporal', 'Post Parietal', 'Sup Parietal', ...
    'Sup Frontal', 'Ant Frontal', 'Orbital' };

% SET THE OUTDIR NAME BASED ON ANALYSIS FLAGS
if(clipByMd) outDirName = [outDirName '_MdClip'];
else outDirName = [outDirName '_NoMdClip']; end
if(erodeCc) outDirName = [outDirName '_CcErode']; end
if(useMedian) outDirName = [outDirName '_Median']; end
outDirName = [outDirName '_' num2str(nFiberSamps,'%02d')];
outDir = fullfile(baseDir, outDirName);
if(~exist(outDir,'dir'))
    mkdir(outDir);
end
% Open a log file to hold all the textual details
logFile = fopen(fullfile(outDir,'log.txt'),'wt');
s=license('inuse'); userName = s(1).user;
fprintf(logFile, '* * * Analysis run by %s on %s * * *\n', userName, datestr(now,31));
fprintf(logFile, 'baseDir = %s\n', baseDir);

%% Load summarized data files
%
% These were created with dtiCallosalSegmentation 
groups = {'Adults','Children'};
nGroups = 2;
tmp1 = load(fullfile(baseDir, 'segDataClean_Adults.mat'));
tmp2 = load(fullfile(baseDir, 'segDataClean_Children.mat'));
segs = tmp1.segs;
nSegs = size(segs,2);
segNames = {segs.name};
groupCode = [ones(1,size(tmp1.fiberCC,1)) ones(1,size(tmp2.fiberCC,1))*2];
subCode = [tmp1.subCode tmp2.subCode];
fiberCC = vertcat(tmp1.fiberCC, tmp2.fiberCC);
if(nnInterp)
  fa = vertcat(tmp1.nfa, tmp2.nfa);
  md = vertcat(tmp1.nmd, tmp2.nmd);
  pdd = vertcat(tmp1.npdd, tmp2.npdd);
else
  fa = vertcat(tmp1.fa, tmp2.fa);
  md = vertcat(tmp1.md, tmp2.md);
  pdd = vertcat(tmp1.pdd, tmp2.pdd);
end
ccCoords = horzcat(tmp1.ccCoords, tmp2.ccCoords);
clear tmp1 tmp2;

% 
% EXCLUDE SOME SUBJECTS
% 
% We exclude one adult who is an age outlier (bw) and the kids who would be
% classified as dyslexic. The resulting sample can be called
% 'neurologically normal'.
% NOTE: add when segmented rh, rsh, tv, vh
%excludeSubs = {'bw040806' 'ada041018' 'ajs040629' 'an041018' 'at040918' 'ctr040618' 'js040726',...
%               'ks040720' 'lg041019' 'nad040610'}; 
excludeSubs = {'bw040806'};						   
goodSubs = ones(size(subCode));
for(ii=1:length(excludeSubs))
    badSub = strmatch(excludeSubs{ii},subCode);
    goodSubs(badSub) = 0;
end
goodSubs = goodSubs==1;
ccCoords = ccCoords(:,goodSubs);
fa = fa(goodSubs,:,:,:);
md = md(goodSubs,:,:,:);
pdd = pdd(goodSubs,:,:,:,:);
fiberCC = fiberCC(goodSubs,:,:);
groupCode = groupCode(goodSubs);
subCode = subCode(goodSubs);

nSubs = size(fiberCC,1);
adults = groupCode==1;
children = groupCode==2;
nAdults = sum(adults);
nChildren = sum(children);

%% Clean CC ROIs
%
% Clean up the CC ROIs by removing fiber crossing points that are too far
% from the CC ROI, filling holes, and eroding edge pixels (if desired).
% The resulting ROIs should each be a 1mm-spaced grid of voxel centers.
ccExtrema = [min([ccCoords{:}]')-1; max([ccCoords{:}]')+1];
ccSz = diff(ccExtrema)+1;
if(verbose) figure; end
for(ii=1:nSubs)
    ccBox = zeros(ccSz);
    coords = ccCoords{ii};
    coords = round(coords-repmat(ccExtrema(1,:)',1,size(coords,2))+1);
	ccBox(sub2ind(ccSz, coords(1,:), coords(2,:))) = 1;
    ccBoxCleaned = imfill(ccBox==1,'holes');
    %figure;imagesc(ccBox'); axis xy image;
    if(erodeCc)
        ccBoxCleaned = imerode(ccBoxCleaned==1,strel('square',2));
    end
    if(verbose)
        subplot(ceil(sqrt(nSubs)),floor(sqrt(nSubs)),ii);
        imagesc(ccBox'); axis xy image off;
    end
    %figure;imagesc(reshape(ccBox-ccBoxCleaned,ccSz)'); axis xy image;
    [x,y] = ind2sub(ccSz, find(ccBoxCleaned==1));
    coords = [x,y]';
    coords = coords+repmat(ccExtrema(1,:)',1,size(coords,2))-1;
    ccCoordsCleaned{ii} = coords;
end

nSampsAlongFiber = size(fiberCC(1,1,1).fiberCoord,3);
midFiberSamp = round((nSampsAlongFiber+1)/2);
if(nFiberSamps==1)
  fiberSampPts = midFiberSamp;
elseif(nFiberSamps<1)
  fiberSampPts = [1:nSampsAlongFiber];
else
  fiberSampPts = [midFiberSamp-nFiberSamps:midFiberSamp+nFiberSamps];
end

%
% EXTRACT FA and MD 
%
% Extract all midsaggital points that are within the cleaned CC
% ROI.
clear fiberYZ fiberNearestCC fiberCoord fiberFa fiberMd fiberPdd;
for(ii=1:nSubs)
    ccYZCoords{ii} = ccCoordsCleaned{ii}';
    %normCcCoord{ii} = normCcCoords{ii}(:,2:3);
    for(jj=1:nSegs)
        for(hs=1:2)
	    clear fiberYZ;
	    tmp = fiberCC(ii,jj,hs).fiberCoord;
            fiberYZ(:,1) = squeeze(tmp(2,:,midFiberSamp));
	    fiberYZ(:,2) = squeeze(tmp(3,:,midFiberSamp));
            [fiberNearestCC{ii,jj,hs},distSq] = nearpoints2d(fiberYZ', ccYZCoords{ii}');
            goodPts = distSq < minDist.^2;
            fiberNearestCC{ii,jj,hs}(~goodPts) = [];
            fiberCoord{ii,jj,hs} = fiberYZ(goodPts,:);
            %normFiberCoord{ii,jj,hs}
            %=[fiberCC(ii,jj,hs).normFiberCoord(goodPts,2:3)];
            fiberFa{ii,jj,hs} = mean([fa{ii,jj,hs}(goodPts,fiberSampPts)],2);
            fiberMd{ii,jj,hs} = mean([md{ii,jj,hs}(goodPts,fiberSampPts)],2);
	    fiberPdd{ii,jj,hs} = squeeze(mean([pdd{ii,jj,hs}(goodPts,fiberSampPts,:)],2));
        end
    end
end

%
% COMPUTE MD CLIP
%
if(clipByMd)
    % Here, we take a look at the distribution of mean diffusivity in the
    % callosum.  We clip the lower and upper tails of the distribution in order
    % to eliminate partial volumed data points.  The limits for clipping are
    % currently determined through a visual inspection of the data.
    allMd = vertcat(fiberMd{:});
    [junk,clipVals] = mrAnatHistogramClip(allMd, 0.01, .90);
    minMD = clipVals(1);
    maxMD = clipVals(2);
    allFa = vertcat(fiberFa{:});
    goodPts = allMd>=minMD&allMd<=maxMD;
    if(verbose)
        figure(1); hist(allFa, 100);
        figure(2); hist(allFa(goodPts), 100);
        figure(3); hist(allMd, 100);
        figure(4); plot(allFa,allMd,'k.')
        figure(5); plot(allFa(goodPts),allMd(goodPts),'k.');
    end
else
    minMD = 0;
    maxMD = 10000;
end

if(verbose)
  fh = figure;
  r = ceil(sqrt(nSubs));
  c = ceil(nSubs/r);
  for(ii=1:nSubs)
    subplot(r,c,ii); hold on;
    for(jj=nSegs:-1:1)
      for(hs=1:2)
	goodPts = fiberMd{ii,jj,hs}>=minMD&fiberMd{ii,jj,hs}<=maxMD;
	h = plot(fiberCoord{ii,jj,hs}(goodPts,1), fiberCoord{ii,jj,hs}(goodPts,2), '.');
	set(h,'Color',barColor(jj,:).*.75);
	%plot(fiberCoord{ii,jj,hs}(~goodPts,1), fiberCoord{ii,jj,hs}(~goodPts,2), 'kx');
      end
    end
    axis equal off tight; hold off;
  end
  mrUtilPrintFigure(fullfile(outDir,'allSubsAllSegsFiberPts'), fh);
  
  %
  % FA AND MD HISTOGRAMS
  %
  % MD Adults vs. Children
  figure(97);
  for(jj=1:nSegs)
    callosumMd{1} = vertcat(md{adults,jj,:});
    callosumMd{2} = vertcat(md{children,jj,:});
    for(ii=1:2)
      subplot(2,nSegs,(ii-1)*nSegs+jj,'align');
      hist(callosumMd{ii}, 100);
      set(gca,'XLim',[0 2000]);
      title([segNames{jj} ' ' groups{ii}]);
    end
  end
  mrUtilResizeFigure(gcf,1280,640,1);
  % Histograms of all subjects
  for(jj=1:nSegs)
    figure(98);
    allSegMd{jj} = vertcat(fiberMd{:,jj,:});
    subplot(2,4,jj);hist(allSegMd{jj}, 100);
    set(gca,'XLim',[0 2000]);
    title(segNames{jj});
    figure(99);
    goodPts = allSegMd{jj}>=minMD&allSegMd{jj}<=maxMD;
    allSegFa{jj} = vertcat(fiberFa{:,jj,:});
    subplot(2,4,jj);hist(allSegFa{jj}, 50);
    set(gca,'XLim',[.4 1]);
    title(segNames{jj});
  end
  mrUtilPrintFigure(fullfile(outDir,'ccMdHist'), 97);
  mrUtilPrintFigure(fullfile(outDir,'MdHist'), 98);
  mrUtilPrintFigure(fullfile(outDir,'FaHist'), 99);
  save(fullfile(outDir,'histograms.mat'),'allSegFa', 'allSegMd', 'segNames', 'minMD', 'maxMD', 'groups', 'groupCode');
end

%
% CLEAN BASED ON MD CLIP VALUES
%
fprintf(logFile, '\nClipping to >=min MD and <=max MD = [%0.1f, %0.1f]\n', minMD, maxMD);
for(ii=1:nSubs)
    %fprintf('Cleaning %s\n', subCode{ii});
    for(jj=1:nSegs)
        for(hs=1:2)
            goodPts = logical((fiberMd{ii,jj,hs} <= maxMD)' .* (fiberMd{ii,jj,hs} >= minMD)');
            %fprintf(logFile, '   %s %s fibers: %d retained out of %d\n', hemiName{hs}, segNames{jj},sum(goodPts),length(goodPts));
            if(sum(goodPts) < 10) fprintf(logFile, '   %s has only %d Left %s fibers\n', subCode{ii}, sum(goodPts), segNames{jj}); end;
            fiberFa{ii,jj,hs} = [fiberFa{ii,jj,hs}(goodPts)];
            fiberMd{ii,jj,hs} = [fiberMd{ii,jj,hs}(goodPts)];
            fiberNearestCC{ii,jj,hs} = [fiberNearestCC{ii,jj,hs}(goodPts)];
        end
    end
end
 
%% SUMMARIZE SEGMENTS
%
% We collapse all fiber point measurements into one measurement per segment
% per subject. 
%
if(useMedian) avgFuncName = 'median'; 
else avgFuncName = 'mean'; end
fprintf(logFile, '\nCentral tendency function is "%s".\n', avgFuncName);
for(ii=1:nSubs)
   for(jj=1:nSegs)
     mnFa(ii,jj,1) = feval(avgFuncName, fiberFa{ii,jj,1});
     n(ii,jj,1) = length(fiberFa{ii,jj,1});
     mnFa(ii,jj,2) = feval(avgFuncName, fiberFa{ii,jj,2});
     n(ii,jj,2) = length(fiberFa{ii,jj,2});
     mnFa(ii,jj,3) = feval(avgFuncName, [fiberFa{ii,jj,1}; fiberFa{ii,jj,2}]);
     n(ii,jj,3) = length([fiberFa{ii,jj,1}; fiberFa{ii,jj,2}]);
     mnMd(ii,jj,1) = feval(avgFuncName, fiberMd{ii,jj,1});
     mnMd(ii,jj,2) = feval(avgFuncName, fiberMd{ii,jj,2});
     mnMd(ii,jj,3) = feval(avgFuncName, [fiberMd{ii,jj,1}; fiberMd{ii,jj,2}]);
     % Compute the fiber intersection density for each point in the ccRoi
     nCcCoords = size(ccYZCoords{ii},1);
     ccYZDensity{ii,jj} = hist([fiberNearestCC{ii,jj,:}],[1:nCcCoords]);
   end
end



%
% COMPUTE SEGMENT AREA
%
for(ii=1:nSubs)
    totalCcArea(ii) = size(ccYZCoords{ii},1);
    for(jj=1:nSegs)
        segArea(ii,jj) = sum(ccSegAssignment{ii}==jj);
        relSegArea(ii,jj) = segArea(ii,jj)./totalCcArea(ii);
    end 
end
[p,t,df] = statTest(totalCcArea(groupCode==1),totalCcArea(groupCode==2),'t');
fprintf(logFile, '\nTotal CC area:  %s (%0.0f mm^2) vs. %s (%0.0f mm^2): t=%0.2f (p=%0.6f, df=%d)\n', ...
    groups{1}, mean(totalCcArea(groupCode==1)), groups{2}, mean(totalCcArea(groupCode==2)),...
    t, p, df);

for(jj=1:nSegs)
    [p,t,df] = statTest(segArea(groupCode==1,jj),segArea(groupCode==2,jj),'t');
    fprintf(logFile, '%s CC area:  %s (%0.0f mm^2) vs. %s (%0.0f mm^2): t=%0.2f (p=%0.6f, df=%d)\n', ...
        segNames{jj}, groups{1}, mean(segArea(groupCode==1,jj)), groups{2}, mean(segArea(groupCode==2,jj)),...
        t, p, df);
    tArea(jj) = t;
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    sArea{jj} = s;
end
for(jj=1:nSegs)
    [p,t,df] = statTest(relSegArea(groupCode==1,jj),relSegArea(groupCode==2,jj),'t');
    fprintf(logFile, '%s relative CC area:  %s (%0.2f) vs. %s (%0.2f): t=%0.2f (p=%0.6f, df=%d)\n', ...
        segNames{jj}, groups{1}, mean(relSegArea(groupCode==1,jj)), groups{2}, mean(relSegArea(groupCode==2,jj)),...
        t, p, df);
    tRelArea(jj) = t;
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; else s='   '; end
    sRelArea{jj} = s;
end

        
%
% CREATE MEAN SUMMARY TABLE
% 
% Create comma delimited text file with callosal data
%
fid = fopen(fullfile(outDir,dataTableName), 'wt');
fprintf(fid,'Subject,Group,Segment,FA_Left,FA_Right,FA_ALL,MD_Left,MD_Right,MD_all,SegArea,RelSegArea\n');
for(ii=1:nSubs)
   for(jj=1:nSegs)
     fprintf(fid,'%d,%s,%d,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f\n',ii,groups{groupCode(ii)},jj,mnFa(ii,jj,1),...
         mnFa(ii,jj,2),mnFa(ii,jj,3),mnMd(ii,jj,1),mnMd(ii,jj,2),mnMd(ii,jj,3),segArea(ii,jj),relSegArea(ii,jj));
   end
end
fclose(fid);

% % Run paired t-tests between segments on DTI values results are displayed in the command window
% Also, Create comma delimited text file with the t-test matrix  
fid = fopen(fullfile(outDir,tTestTableName), 'wt');
fprintf(fid, ',%s,%s,%s,%s,%s,%s,%s\n',segNames{1:7});
disp('---');disp('Paired t-test between segment FA:');
for(ii=[1:7])
  fprintf(fid,'%s',segNames{ii});
  for(jj=[1:7])
    [p,t,df]=statTest(mnFa(:,ii,3),mnFa(:,jj,3),'p');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; else s='   '; end
    fprintf('%s %s (%0.3f) vs. %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
            s, segNames{ii},mean(mnFa(:,ii,3)),segNames{jj},mean(mnFa(:,jj,3)),t,p,df);
    fprintf(fid,',%s%0.3f',s,t);

%% Run FA t-tests and print results for each hemisphere separately
%     [p,t,df]=statTest(mnFa(:,ii,1),mnFa(:,jj,1),'t');
%     fprintf('Left %s (%0.3f) vs. %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
%             segNames{ii},mean(mnFa(:,ii,1)),segNames{jj},mean(mnFa(:,jj,1)),t,p,df);
%     [p,t,df]=statTest(mnFa(:,ii,2),mnFa(:,jj,2),'t');
%     fprintf('Right %s (%0.3f) vs. %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
%             segNames{ii},mean(mnFa(:,ii,2)),segNames{jj},mean(mnFa(:,jj,2)),t,p,df);
  end
  fprintf(fid,'\n');
end
fprintf(fid,'\n');

fprintf(fid, ',%s,%s,%s,%s,%s,%s,%s\n',segNames{1:7});
disp('---');disp('Paired t-test between segment MD:');
for(ii=[1:7])
  fprintf(fid,'%s',segNames{ii});
  for(jj=[1:7])
    [p,t,df]=statTest(mnMd(:,ii,3),mnMd(:,jj,3),'p');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; else s='   '; end
    fprintf('%s %s (%0.3f) vs. %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
            s, segNames{ii},mean(mnMd(:,ii,3)),segNames{jj},mean(mnMd(:,jj,3)),t,p,df);
    fprintf(fid,',%s%0.3f',s,t);

%% Run MD t-tests and print results for each hemisphere separately
%     [p,t,df]=statTest(mnMd(:,ii,1),mnMd(:,jj,1),'t');
%     fprintf('Left %s (%0.3f) vs. %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
%             segNames{ii},mean(mnMd(:,ii,1)),segNames{jj},mean(mnMd(:,jj,1)),t,p,df);
%     [p,t,df]=statTest(mnMd(:,ii,2),mnMd(:,jj,2),'t');
%     fprintf('Right %s (%0.3f) vs. %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
%             segNames{ii},mean(mnMd(:,ii,2)),segNames{jj},mean(mnMd(:,jj,2
%             )),t,p,df);
  end
  fprintf(fid,'\n');
end
fclose(fid);

% % Run two-sample t-tests between adults and children for each 
% segment for FA and then MD

disp('---');disp('two-sample t-test between adults and children segment FA:');
for(ii=[1:7])
    [p,t,df]=statTest(mnFa(children,ii,3),mnFa(adults,ii,3),'t');
    if(p<=0.001) sFa{ii}='***'; elseif(p<=0.01) sFa{ii}=' **'; elseif(p<=0.05) sFa{ii}='  *'; else sFa{ii}='   '; end
     fprintf('%s Child %s (%0.3f) vs. Adult %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
             sFa{ii}, segNames{ii},mean(mnFa(children,ii,3)),segNames{ii},mean(mnFa(adults,ii,3)),t,p,df);
    tFa(ii)=t;
end

disp('---');disp('two-sample t-test between adults and children segment MD:');
for(ii=[1:7])
    [p,t,df]=statTest(mnMd(children,ii,3),mnMd(adults,ii,3),'t');
    if(p<=0.001) sMd{ii}='***'; elseif(p<=0.01) sMd{ii}=' **'; elseif(p<=0.05) sMd{ii}='  *'; else sMd{ii}='   '; end
     fprintf('%s Child %s (%0.3f) vs. Adult %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
            sMd{ii}, segNames{ii},mean(mnMd(children,ii,3)),segNames{ii},mean(mnMd(adults,ii,3)),t,p,df);
    tMd(ii)=t;
end


% 
% TEST FOR AGREEMENT BETWEEN HEMISPHERES
%
if(verbose)
  minFaR = 1; minMdR = 1;
  fprintf(logFile, '\nTesting agreement between hemispheres:\n');
  for(jj=[1:7])
    [p,t,df]=statTest(mnFa(:,jj,1),mnFa(:,jj,2),'p');
    [pr,r,dfr]=statTest(mnFa(:,jj,1),mnFa(:,jj,2),'r');
    if(r<minFaR) minFaR = r; end
    fprintf(logFile, '   FA Left %s (%0.3f) vs. Right %s (%0.3f): r=%0.3f, t=%0.2f (p=%0.4f, df=%d)\n', ...
            segNames{ii},mean(mnFa(:,jj,1)),segNames{jj},mean(mnFa(:,jj,2)),r,t,p,df);
    [p,t,df]=statTest(mnMd(:,ii,1),mnMd(:,ii,2),'p');
    [pr,r,dfr]=statTest(mnMd(:,jj,1),mnMd(:,jj,2),'r');
    if(r<minMdR) minMdR = r; end
    fprintf(logFile, '   MD Left %s (%0.3f) vs. Right %s (%0.3f): r=%0.3f, t=%0.2f (p=%0.4f, df=%d)\n', ...
            segNames{jj},mean(mnMd(:,jj,1)),segNames{jj},mean(mnMd(:,jj,2)),r,t,p,df);
  end
  fprintf(logFile, '   Minimum left-right FA r = %0.3f, MD r = %0.3f\n',minFaR,minMdR);
  fh = figure; set(gcf,'Name','left-right FA'); hold on;
  for(jj=[1:7])
    h=plot(mnFa(:,jj,1),mnFa(:,jj,2),'.');
    set(h,'Color',barColor(jj,:));
  end
  eval(figDefaults);
  xlabel('Left FA'); ylabel('Right FA');
  axis equal; axis([0 1 0 1]);
  set(gca,'XTick',[0 .2 .4 .6 .8 1.0],'YTick',[0 .2 .4 .6 .8 1.0]);
  mrUtilResizeFigure(gcf, 300, 300);
  mrUtilPrintFigure(fullfile(outDir,'leftRightAgreement'), fh);
end

%% Create bar charts showing DTI values x callosal segment 
% Means and standard deviations are are displayed inside the bars.  Error
% bars = 2sem.


%
% FA GRAPH
% 
fh = figure;
hold on;
tmp = mnFa(:,1:7,3);
mu = mean(tmp);
sd = std(tmp);
sem = sd/sqrt(length(tmp(:,1,1))-1);
for(ii=[1:length(mu)])
    y = zeros(1,length(mu));
    y(ii) = mu(ii);
    h = bar(y,'FaceColor',barColor(ii,:),'linewidth',2);
    text(ii,0.57,'Mean','horizontalalignment','center','fontsize',12,'fontWeight','bold');
    text(ii,0.55,sprintf('%0.2f',mu(ii)),'horizontalalignment','center','fontsize',12,'fontWeight','bold');
    text(ii,0.52,'S.D.','horizontalalignment','center','fontsize',12,'fontWeight','bold');
    text(ii,0.50,sprintf('%0.3f',sd(ii)),'horizontalalignment','center','fontsize',12,'fontWeight','bold');
end

errorbar(1:length(mu),mu,(2*sem),'k+','linewidth',2);
hold off;
set(gca,'box','on','xtick',[1:length(mu)],'xticklabel',tickLabels,...
    'linewidth',2,'fontsize',14)
set(gca,'ylim',[0.4 0.85])
set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
set(get(gca,'YLabel'),'String','FA','fontsize',14);
mrUtilResizeFigure(fh, 1041, 420);
%title({'Fractional Anisotropy (FA) by Callosal Segment',sprintf('%s n=%d',graphSubj,length(mnFa(:,1,1)))},'fontsize',20,'fontWeight','bold');
mrUtilPrintFigure(fullfile(outDir,'FA_acrossSegs'),fh);

%
% MD GRAPH
%
fh = figure;
hold on;
tmp = mnMd(:,1:7,3);
mu = mean(tmp);
sd = std(tmp);
sem = sd/sqrt(length(mnMd(:,1,1))-1);

for(ii=[1:length(mu)])
    y = zeros(1,length(mu));
    y(ii) = mu(ii);
    h = bar(y,'FaceColor',barColor(ii,:),'linewidth',2);
     text(ii,800,'Mean','horizontalalignment','center','fontsize',12,'fontWeight','bold');
     text(ii,788,sprintf('%0.0f',mu(ii)),'horizontalalignment','center','fontsize',12,'fontWeight','bold');
     text(ii,773,'S.D.','horizontalalignment','center','fontsize',12,'fontWeight','bold');
     text(ii,761,sprintf('%0.1f',sd(ii)),'horizontalalignment','center','fontsize',12,'fontWeight','bold');
end
errorbar(1:length(mu),mu,(2*sem),'k+','linewidth',2);
hold off;
set(gca,'ylim',[700 1000])
%set(gca,'ylim',[0 1100])
set(gca,'box','on','xtick',[1:length(mu)],'xticklabel',tickLabels,...
    'linewidth',2,'fontsize',14)
set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
set(get(gca,'YLabel'),'String','MD (10^-^6 mm^2/sec)','fontsize',14);
mrUtilResizeFigure(fh, 1041, 420);
mrUtilPrintFigure(fullfile(outDir,'MD_acrossSegs'),fh);

% % Create a clustered bar charts comparing adult and child DTI values 
% The t statistic and significance are displayed above the bars.  Error
% bars = 2sem

% Graph Globals
width = 1;

%
% Make FA graph here
%
child = mnFa(children,1:7,3);
adult = mnFa(adults,1:7,3);
meansChild = mean(child);
meansAdult = mean(adult);
sdChild = std(child);
sdAdult = std(adult);
semChild = sdChild/sqrt(length(mnFa(children,1,1))-1);
semAdult = sdAdult/sqrt(length(mnFa(adults,1,1))-1);
for(ii=1:length(meansChild))
        mnFaAll(ii,1) = meansChild(ii);
        mnFaAll(ii,2) = meansAdult(ii);
end
fh = figure; hold on;
for(ii=[1:length(mnFaAll)])
        deltas(ii) = (meansAdult(ii)-meansChild(ii));
        y = zeros(length(mnFaAll), 2);
        y(ii,:) = mnFaAll(ii,:);
        barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
        %text(ii,0.845,sprintf('%s%0.1f',sFa{ii},tFa(ii)),...
        %    'horizontalalignment','center','fontsize',12,'fontWeight','bold');
end
% Darken the second bar in each pair
for(ii=1:length(barHandles))
    curColor = get(barHandles{ii}(2),'FaceColor');
    set(barHandles{ii}(2),'FaceColor',curColor.*0.5);
end
clear barHandles;
errorbar([1:length(meansChild)]-0.14,meansChild,(2*semChild),'k+','linewidth',2);
errorbar([1:length(meansAdult)]+0.14,meansAdult,(2*semAdult),'k+','linewidth',2);
hold off;
set(gca,'box','on','xtick',[1:length(mnFaAll)],'xticklabel',tickLabels,...
    'linewidth',2,'fontsize',12);
set(gca,'ylim',[0.5 .85],'ytick',[.5 .6 .7 .8],'YGrid','on')
set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
set(get(gca,'YLabel'),'String','FA','fontsize',14);
mrUtilResizeFigure(fh, 800, 420);
set(gca,'Position',[0.08 0.1 .91 .89]);
mrUtilPrintFigure(fullfile(outDir,'FA_acrossSegs_devel'),fh);

%
% Make MD graph here
%
child = mnMd(children,1:7,3);
adult = mnMd(adults,1:7,3);
meansChild = mean(child);
meansAdult = mean(adult);
sdChild = std(child);
sdAdult = std(adult);
semChild = sdChild/sqrt(sum(children)-1);
semAdult = sdAdult/sqrt(sum(adults)-1);
for(ii=1:length(meansChild))
    mnMdAll(ii,1) = meansChild(ii);
    mnMdAll(ii,2) = meansAdult(ii);
end

fh = figure; hold on;
tmp = mnMd(:,1:7,3);
mu = mean(tmp);
sd = std(tmp);
sem = sd/sqrt(length(mnMd(:,1,1))-1);
for(ii=[1:length(mnMdAll)])
    deltas(ii) = (meansAdult(ii)-meansChild(ii));
    y = zeros(length(mnMdAll), 2);
    y(ii,:) = mnMdAll(ii,:);
    barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
    %text(ii,1020,sprintf('%s%0.1f',sMd{ii},tMd(ii)),...
    %    'horizontalalignment','center','fontsize',12,'fontWeight','bold');
end
% Darken the second bar in each pair
for(ii=1:length(barHandles))
    curColor = get(barHandles{ii}(2),'FaceColor');
    set(barHandles{ii}(2),'FaceColor',curColor.*0.5);
end
clear barHandles;
errorbar([1:length(meansChild)]-0.14,meansChild,(2*semChild),'k+','linewidth',2);
errorbar([1:length(meansAdult)]+0.14,meansAdult,(2*semAdult),'k+','linewidth',2);
hold off;
set(gca,'ylim',[800 970],'YGrid','on','ytick',[800,850,900,950])
set(gca,'box','on','xtick',[1:length(mu)],'xticklabel',tickLabels,...
    'linewidth',2,'fontsize',12)
set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
set(get(gca,'YLabel'),'String','MD (10^-^6 mm^2/sec)','fontsize',14);
mrUtilResizeFigure(fh, 800, 420);
set(gca,'Position',[0.08 0.1 .91 .89]);
mrUtilPrintFigure(fullfile(outDir,'MD_acrossSegs_devel'),fh);

%
% MAKE AREA GRAPH
%
child = segArea(children,1:7);
adult = segArea(adults,1:7);
meansChild = mean(child);
meansAdult = mean(adult);
sdChild = std(child);
sdAdult = std(adult);
semChild = sdChild/sqrt(sum(children)-1);
semAdult = sdAdult/sqrt(sum(adults)-1);
for(ii=1:length(meansChild))
    mnAreaAll(ii,1) = meansChild(ii);
    mnAreaAll(ii,2) = meansAdult(ii);
end
fh = figure;hold on;
tmp = segArea(:,1:7);
mu = mean(tmp);
sd = std(tmp);
sem = sd/sqrt(nSubs-1);
for(ii=[1:length(mnAreaAll)])
    deltas(ii) = (meansAdult(ii)-meansChild(ii));
    y = zeros(length(mnAreaAll), 2);
    y(ii,:) = mnAreaAll(ii,:);
    barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
    %text(ii,165,sprintf('%s%0.1f',sArea{ii},tArea(ii)),...
    %    'horizontalalignment','center','fontsize',12,'fontWeight','bold');
end
% Darken the second bar in each pair
for(ii=1:length(barHandles))
    curColor = get(barHandles{ii}(2),'FaceColor');
    set(barHandles{ii}(2),'FaceColor',curColor.*0.5);
end
clear barHandles;
errorbar([1:length(meansChild)]-0.14,meansChild,(2*semChild),'k+','linewidth',2);
errorbar([1:length(meansAdult)]+0.14,meansAdult,(2*semAdult),'k+','linewidth',2);
hold off;
set(gca,'ylim',[0 175],'ytick',[0 25 50 75 100 125 150],'YGrid','on')
set(gca,'box','on','xtick',[1:length(mu)],'xticklabel',tickLabels,...
    'linewidth',2,'fontsize',12)
set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
set(get(gca,'YLabel'),'String','Area (mm^2)','fontsize',14);
mrUtilResizeFigure(fh, 800, 420);
set(gca,'Position',[0.08 0.1 .91 .89]);
mrUtilPrintFigure(fullfile(outDir,'Area_acrossSegs_devel'),fh);


if(verbose)
    figure; plot(mnMd(:,:,3), mnFa(:,:,3), 'k.')
    for(ii=1:length(mu))
        figure; plot(mnMd(:,ii,3), mnFa(:,ii,3), 'k.')
        title({tickLabels{ii}},'fontsize',20,'fontWeight','bold');
    end
end

fclose(logFile);


%%%%%BEHAVIORAL CORRELATIONS%%%%%

[bd,bdColNames] = dtiGetBehavioralData(subCode,'/biac2/wandell2/data/reading_longitude/read_behav_measures_w-birthdate.csv');
bdInds = [1 3 4 5 6 7 8 9 10 11 12 21 22];
%bdInds = [1:length(bdColNames)];
% Analyze only children
goodSubs = bd(:,2)==1;

for(jj=[1:7])
  for(ii=bdInds)
    [p,r,df]=statTest(bd(goodSubs,ii),mnFa(goodSubs,jj,3),'r');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s FA vs. %s:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
            s, segNames{jj},bdColNames{ii},r,p,df);

% Run FA correlations and print results for each hemisphere separately 
%     [p,r,df]=statTest(bd(:,ii),mnFa(:,jj,1),'r');
%     fprintf('Left %s FA vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
%             segNames{jj},bdColNames{ii},r,p,df);
%     [p,r,df]=statTest(bd(:,ii),mnFa(:,jj,2),'r');
%     fprintf('Right %s FA vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
%             segNames{jj},bdColNames{ii},r,p,df); 
  end
end

paInd = 9;
for(jj=[1:7])
  fh = figure;
  mrUtilResizeFigure(fh, 300, 600);
  x = bd(goodSubs,paInd);
  y = mnFa(goodSubs,jj,3);
  p = polyfit(x, y, 1);
  lx = [min(x), max(x)];
  subplot(2,1,1); axis;
  line(lx, p(1)*lx+p(2),'Color',[.5 .5 .5],'LineWidth',1);
  hold on; plot(x, y, 'k.'); hold off;
  axis square;
  title([tickLabels{jj} ' Callosal Pathawys']);
  set(gca,'fontsize',12);
  %set(gca,'ylim',[.45 .85],'ytick',[.5 .6 .7 .8]);
  set(get(gca,'YLabel'),'String',['Fractional Anisotropy'],'fontsize',12);
  set(get(gca,'XLabel'),'String',bdColNames{paInd},'fontsize',12);
  y = mnMd(goodSubs,jj,3);
  p = polyfit(x, y, 1);
  subplot(2,1,2);
  line(lx, p(1)*lx+p(2),'Color',[.5 .5 .5],'LineWidth',1);
  hold on; plot(x, y, 'k.'); hold off;
  axis square;
  set(gca,'fontsize',12);
  %set(gca,'ylim',[750 1150],'ytick',[800,900,1000,1100]);
  set(get(gca,'YLabel'),'String',['Mean Diffusivity (10^-^6 mm^2/sec)'],'fontsize',12);
  set(get(gca,'XLabel'),'String', bdColNames{paInd},'fontsize',12);
  mrUtilPrintFigure(fullfile(outDir,['Scatter_' segNames{jj} '_vs_' strrep(bdColNames{paInd},' ','_')]),fh);
end

for(jj=[1:7])
  for(ii=bdInds)
    [p,r,df]=statTest(bd(goodSubs,ii),mnMd(goodSubs,jj,3),'r');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s MD vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
            s, segNames{jj},bdColNames{ii},r,p,df);
% Run MD correlations and print results for each hemisphere separately 
%     [p,r,df]=statTest(bd(:,ii),mnMd(:,jj,1),'r');
%     fprintf('Left %s MD vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
%             segNames{jj},bdColNames{ii},r,p,df);
%     [p,r,df]=statTest(bd(:,ii),mnMd(:,jj,2),'r');
%     fprintf('Right %s MD vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
%             segNames{jj},bdColNames{ii},r,p,df);
  end
end

for(jj=[1:7])
  for(ii=bdInds)
    [p,r,df]=statTest(bd(goodSubs,ii),segArea(goodSubs,jj),'r');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s SegArea vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
            s, segNames{jj},bdColNames{ii},r,p,df);
  end
end

% Analyze all subjects on age & sex
bdInds = [1 3];
for(jj=[1:7])
  for(ii=bdInds)
    [p,r,df]=statTest(bd(:,ii),mnFa(:,jj,3),'r');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s FA vs. %s:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
            s, segNames{jj},bdColNames{ii},r,p,df);
    [p,r,df]=statTest(bd(:,ii),mnMd(:,jj,3),'r');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s MD vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
            s, segNames{jj},bdColNames{ii},r,p,df);
    [p,r,df]=statTest(bd(:,ii),segArea(:,jj),'r');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s SegArea vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
            s, segNames{jj},bdColNames{ii},r,p,df);
  end
end

error('stop here');














% Create a grid that conceptually is on the mid-sagittal plane.  Each
% subject will has nSegs grids.  
gridSpace = 1;   % Millimeters
gridSize = [45 20];    % Endpoints of the grid in millimeters
useMeanShift = false;
useNormedCoords = true;
printEps = false;
tickSpace = 10;
% the contour threshold to be applied to the mean CC image.
ccThresh = repmat(nSubs.*.6, 1,2);
gridColor = 0.5*[1 1 1];
cm = gray(256); cm = flipud(cm);

if(useMeanShift) figName = 'shifted'; 
else figName = 'unshifted'; end
if(useNormedCoords) figName = [figName '_norm']; end

% This is the distance from a grid cell center to a corner (hypotenuse)
maxDistSq = 2*(gridSpace/2)^2;
xSamples = [-gridSize(1):gridSpace:gridSize(1)];
ySamples = [-gridSize(2):gridSpace:gridSize(2)];
[gridX,gridY] = ndgrid(xSamples,ySamples);
gridPoints = [gridX(:) gridY(:)];
z = ones(size(gridX(:)));

centerCoord = [-5 15];
% The cc ROI points are sometimes shifted by 1/2 mm relative to fiber points
%roiFiberOffset = [-0.5 0.5];
roiFiberOffset = [0 0];

% For each subject, and then for all subjects, we count the number of
% fibers in each grid cell (i.e., bin).
allDensity = zeros([size(gridX),nSegs]);
allCC = zeros([size(gridX)]);
for(ii=1:nSubs)
  if(useNormedCoords)
    meanCoord = mean(vertcat(normFiberCoord{ii,:}),1);
    cc = normCcCoord{ii};
  else
    meanCoord = mean(vertcat(fiberCoord{ii,:}),1);
    cc = ccYZCoords{ii}; 
  end
  meanShift(:,ii) = meanCoord(:);
  if(useMeanShift)
    cc(:,1) = cc(:,1)-(meanCoord(1)+roiFiberOffset(1)); 
    cc(:,2) = cc(:,2)-(meanCoord(2)+roiFiberOffset(2));
  else
    cc(:,1) = cc(:,1)-(centerCoord(1)+roiFiberOffset(1)); 
    cc(:,2) = cc(:,2)-(centerCoord(2)+roiFiberOffset(2));
  end

  [ccNearest, bestSqDist] = nearpoints([cc ones(size(cc(:,1)))]', [gridPoints z]');
  for(jj=1:length(ccNearest))
    if(bestSqDist(jj)<=maxDistSq)
      allCC(ccNearest(jj)) = allCC(ccNearest(jj))+1;
    end
  end

  for(segNum=1:nSegs)

    % We arrange the left and right grids 
    tmpDensity = zeros(size(gridX));
    if(useNormedCoords)
      tmpFiberCoord = [normFiberCoord{ii,segNum}];
    else
      tmpFiberCoord = [fiberCoord{ii,segNum}];
    end
    

    % Convert the x,y coords to a mean-centered coordinate system so that
    % all subjects will fit on the same grid. It might be interesting to
    % see how well the splenium aligns across subjects using this method.
    if(useMeanShift)
      if(~isempty(tmpFiberCoord))
        tmpFiberCoord(:,1) = tmpFiberCoord(:,1) - meanCoord(1); 
        tmpFiberCoord(:,2) = tmpFiberCoord(:,2) - meanCoord(2);
      end
    else
      tmpFiberCoord(:,1) = tmpFiberCoord(:,1) - centerCoord(1); 
      tmpFiberCoord(:,2) = tmpFiberCoord(:,2) - centerCoord(2);
    end
    % For each fiber point, find the nearest grid point.
    if(~isempty(tmpFiberCoord))
      [nearest, bestSqDist] = nearpoints([tmpFiberCoord ones(size(tmpFiberCoord(:,1)))]', [gridPoints z]');
      %if(max(bestSqDist)>maxDistSq) warning(sprintf('grid may be too
      %small! (%0.3f)',max(bestSqDist))); end
      % Count how many fibers are in each grid cell
      for(jj=1:length(nearest))
        if(bestSqDist(jj)<=maxDistSq)
          tmpDensity(nearest(jj)) = tmpDensity(nearest(jj))+1;
        end
      end
    end
    allDensity(:,:,segNum) = allDensity(:,:,segNum)+tmpDensity;
  end
end

xtick = [0:tickSpace:max(xSamples)]; xtick = [-1*fliplr(xtick(2:end)), xtick];
ytick = [0:tickSpace:max(ySamples)]; ytick = [-1*fliplr(ytick(2:end)), ytick];
binArea = gridSpace^2; fprintf('Bin area = %.3f (mm^2)\n',binArea);

%meanCC = blur(allCC,2,'binom5');
meanCC = imfilter(allCC,fspecial('gaussian',[7 7],0.75));

figure(88);
imagesc(xSamples,ySamples,meanCC'); axis equal tight xy; colormap(flipud(gray(256)));
set(gca,'xtick',xtick,'ytick',ytick,'Position',[.03 0.03 .94 .94])
set(gca,'Xcolor',gridColor,'Ycolor',gridColor,'xticklabel',[],'yticklabel',[]);
p = get(gcf,'Position'); 
set(gcf,'PaperPositionMode','auto','Name','mean CC','Position',[p(1:2) gridSize*10]);
print(gcf, '-dpng', '-r200', [figName '_cc.png']);
%if(printEps) 
%  print(gcf, '-deps', '-tiff', [figName '_cc.eps']); 
%  mrUtilMakeColorbar(cm, round(linspace(0,max(meanCC(:)),4)), 'Point
%  Density', [figName '_ccLegend'], 87);
%else
%  mrUtilMakeColorbar(cm, round(linspace(0,max(meanCC(:)),4)), 'Point
%  Density', [figName '_ccLegend.png'], 87);
%end

nz = allDensity>0;

maxDensity = ceil(max(allDensity(:))./10).*10;
cbLabel = round(linspace(0,maxDensity./binArea,4)./10).*10;
if(printEps) 
  mrUtilMakeColorbar(cm, cbLabel, 'Fiber Density (fibers/mm^2)', [figName '_AllLegend'], 98);
else
  mrUtilMakeColorbar(cm, cbLabel, 'Fiber Density (fibers/mm^2)', [figName '_AllLegend.png'], 98); 
end
for(segNum=1:nSegs)
  fn = [strrep(segNames{segNum},' ','_') '_' figName];
  figNum = segNum+12;
  
  figure(figNum); clf; colormap(cm);
  image(xSamples,ySamples,uint8(allDensity(:,:,segNum)'./maxDensity.*255+0.5));
  axis equal tight xy;
  hold on; contour(xSamples,ySamples,meanCC',ccThresh,'k-','LineWidth',3); hold off;
  grid on
  set(gca,'xtick',xtick,'ytick',ytick,'Position',[.03 0.03 .94 .94])
  set(gca,'Xcolor',gridColor,'Ycolor',gridColor,'xticklabel',[],'yticklabel',[]);
  p = get(gcf,'Position'); 
  set(gcf,'PaperPositionMode','auto','Name',fn,'Position',[p(1:2) gridSize*10]);
  print(gcf, '-dpng', '-r200', [fn '_allDensity.png']);
  if(printEps) print(gcf, '-deps', '-tiff', [fn '_allDensity.eps']); end
  pause(1);
end



% Show all segments together
fn = ['all_' figName];
figNum = figNum+1;
d = sum(allDensity(:,:,1:nSegs),3);
figure(figNum); clf; colormap(cm);
image(xSamples,ySamples,uint8(d'./maxDensity.*255+0.5));
axis equal tight xy;
hold on; contour(xSamples,ySamples,meanCC',ccThresh,'k-','LineWidth',3); hold off;
grid on
set(gca,'xtick',xtick,'ytick',ytick,'Position',[.03 0.03 .94 .94])
set(gca,'Xcolor',gridColor,'Ycolor',gridColor,'xticklabel',[],'yticklabel',[]);
p = get(gcf,'Position'); 
set(gcf,'PaperPositionMode','auto','Name',fn,'Position',[p(1:2) gridSize*10]);
print(gcf, '-dpng', '-r200', [fn '_allDensity.png']);
if(printEps) print(gcf, '-deps', '-tiff', [fn '_allDensity.eps']); end


%colors = [0 0 1; 0 .5 1; 0 .5 0; .75 .5 0; .75 0 0; .75 0 1; .5 .5 .5];
colors = [1 .8 0; .6 .5 0; 0 .7 1; .6 .5 0; 0 .5 0; 0 .5 0; 0 0 1; .8 .8 .8];
useMeanShift = false;
useNormedCoords = false;
doSegs = [1:7];
nSegs = length(doSegs);
for(ii=1:nSubs)
  subDensity = zeros([size(gridX),nSegs]);
  subCC = zeros([size(gridX)]);
  if(useNormedCoords)
    meanCoord = mean(vertcat(normFiberCoord{ii,:}),1);
    cc = normCcCoord{ii};
  else
    meanCoord = mean(vertcat(fiberCoord{ii,:}),1);
    cc = ccYZCoords{ii}; 
  end
  meanShift(:,ii) = meanCoord(:);
  if(useMeanShift)
    cc(:,1) = cc(:,1)-(meanCoord(1)+roiFiberOffset(1)); 
    cc(:,2) = cc(:,2)-(meanCoord(2)+roiFiberOffset(2));
  else
    cc(:,1) = cc(:,1)-(centerCoord(1)+roiFiberOffset(1)); 
    cc(:,2) = cc(:,2)-(centerCoord(2)+roiFiberOffset(2));
  end
  [ccNearest, bestSqDist] = nearpoints([cc ones(size(cc(:,1)))]', [gridPoints z]');
  for(jj=1:length(ccNearest))
    if(bestSqDist(jj)<=maxDistSq)
      subCC(ccNearest(jj)) = subCC(ccNearest(jj))+1;
    end
  end
  for(segNum=doSegs)
    tmpDensity = zeros(size(gridX));
    if(useNormedCoords)
      tmpFiberCoord = [normFiberCoord{ii,segNum}];
    else
      tmpFiberCoord = [fiberCoord{ii,segNum}];
    end
    if(useMeanShift)
      if(~isempty(tmpFiberCoord))
        tmpFiberCoord(:,1) = tmpFiberCoord(:,1) - meanCoord(1); 
        tmpFiberCoord(:,2) = tmpFiberCoord(:,2) - meanCoord(2);
      end
    else
      tmpFiberCoord(:,1) = tmpFiberCoord(:,1) - centerCoord(1); 
      tmpFiberCoord(:,2) = tmpFiberCoord(:,2) - centerCoord(2);
    end
   
    % For each fiber point, find the nearest grid point.
    if(~isempty(tmpFiberCoord))
      [nearest, bestSqDist] = nearpoints([tmpFiberCoord ones(size(tmpFiberCoord(:,1)))]', [gridPoints z]');
      % Count how many fibers are in each grid cell
      for(jj=1:length(nearest))
        if(bestSqDist(jj)<=maxDistSq)
          tmpDensity(nearest(jj)) = tmpDensity(nearest(jj))+1;
        end
      end
    end
    subDensity(:,:,segNum) = subDensity(:,:,segNum)+tmpDensity;
  end
  meanCC = imfilter(subCC,fspecial('gaussian',[7 7],0.75));

  %figure(75);imagesc(xSamples,ySamples,meanCC'); axis equal tight xy; colormap(flipud(gray(256)));
  fn = [subCode{ii} '_' figName];
  figure(ii); clf; colormap(colors);
  image(xSamples,ySamples,ones([size(meanCC'),3]));
  set(gcf,'Name',subCode{ii});
  grid on
  set(gca,'xtick',xtick,'ytick',ytick,'Position',[.03 0.03 .94 .94])
  set(gca,'Xcolor',gridColor,'Ycolor',gridColor,'xticklabel',[],'yticklabel',[]);
  p = get(gcf,'Position'); 
  set(gcf,'PaperPositionMode','auto','Name',fn,'Position',[p(1:2) gridSize*10]);
  axis equal tight xy;
  hold on; 
  for(segNum=doSegs)
    dh = subDensity(:,:,segNum);
    dh = sort(dh(:),1,'descend');
    totalDensity = sum(dh);
    thresh = find(cumsum(dh)>=totalDensity*0.9);
    segArea(ii,segNum) = thresh(1)*binArea;
    thresh = dh(thresh(1));
    %contour(xSamples,ySamples,subDensity(:,:,segNum)',[thresh
    %thresh],'LineWidth',2,'Color',colors(segNum,:)); 
    [c,h] = contourf(xSamples,ySamples,subDensity(:,:,segNum)',[thresh thresh],'Color',colors(segNum,:));
    c = get(h,'Children');
    for(ci=1:length(c))
      set(c,'FaceColor',colors(segNum,:));
    end
  end
  contour(xSamples,ySamples,meanCC',[0.25 0.25],'LineWidth',3,'Color',[.1 .1 .1]);
  hold off;
  print(gcf, '-dpng', '-r200', [fn '_seg.png']);
  if(printEps) print(gcf, '-deps', '-tiff', [fn '_seg.eps']); end
  
  %figure(ii); clf; colormap(cm);
  %set(gcf,'Name',subCode{ii});
  %for(segNum=doSegs)
  %  maxDensity = max(subDensity(:));
  %  fn = [strrep(segNames{segNum},' ','_') '_' figName];
  %  subplot(nSegs,1,segNum);
  %  image(xSamples,ySamples,uint8(subDensity(:,:,segNum)'./maxDensity.*255+0.5));
  %  hold on; contour(xSamples,ySamples,meanCC',[0.25 0.25],'k-'); hold off;
  %  grid on
  %  set(gca,'xtick',xtick,'ytick',ytick,'xticklabel',[],'yticklabel',[]);
  %  axis equal tight xy;
  %end
end
