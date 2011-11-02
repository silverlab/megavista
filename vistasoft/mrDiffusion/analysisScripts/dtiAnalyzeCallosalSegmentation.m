% Analyzes the callosal segmentation data. The data must be extracted and
% sumarized by the dtiCallosalSegmentation script before you can run this
% script.
%
% The segmentation data have been summarized by doing the following for all
% fibers:
% - load the CC ROI and use this to find the user-defined mid-sagittal plane.
% - for each fiber, find the point that falls nearest to one of the CC ROI
% points.
%
% fiberCC is an NSubjects x numSegments struct array.  The struct
% is:
% fiberCoord: the coordinates of each fiber at the position within that fiber
% closest to the mid-sagittal plane.
% dist: the distance of each fiberCoord to its nearest CC ROI point
% normFiberCoord: normalized fiber coords.
%

%% Initialize vars and get subject list
clear all;
close all;

baseDir = '/biac3/wandell4/data/reading_longitude/dti_y1_old';
addpath /home/bob/matlab/stats

dataTableName = 'ccSegmentationData';
tTestTableName = 'ccSegmentation_ttests';
behavDataFile = fullfile('/biac3/wandell4/data/reading_longitude/','read_behav_measures.csv');
%behavDataFile = fullfile(baseDir,'read_behav_measures_longitude.csv');

baseDir = fullfile(baseDir,'cc_segmentationData');
%baseDir = fullfile(baseDir,'dti_y2','cc_segmentationData');

erodeCc = false;
nFiberSamps = 0; % <1 means all
nnInterp = true;
weightByFiberDensity = true;
outDirName = 'junk';

% to be sure we catch all fibers within the bulk of the ROI, the minimum
% minDist is sqrt(.5^2+.5^2)=.7071, which is the distance from the center of a
% 1mm pixel to any corner of that pixel. 
minDist = .71;
useMedian = false;
figs = true;

verbose = false; % true -> lots of intermediate stuff (may generate hundreds of figs!)

figDefaults = 'set(gca,''FontSize'',14,''FontName'',''Helvetica'');';
hemiName = {'left','right'};

% Graph Globals
barColor = [0.0784 0.7843 0.0784; 0.7843 0.0784 0.7843; 0.7843 0.7843 0.0784;0.0784 0.3529 0.7843;...
       0.7843 0.0784 0.0784; 0.9216 0.6471 0.2157; 0.2157 0.6471 0.9216; .75 .75 .75];
tickLabels = { 'Occipital', 'Temporal', 'P-Parietal', 'S-Parietal', ...
    'S-Frontal', 'A-Frontal', 'Orbital' };

% SET THE OUTDIR NAME BASED ON ANALYSIS FLAGS
if(erodeCc) outDirName = [outDirName '_CcErode']; end
if(useMedian) outDirName = [outDirName '_Median']; end
if(~weightByFiberDensity) outDirName = [outDirName '_noFdWeight']; end
outDirName = [outDirName '_' num2str(nFiberSamps,'%02d')];
outDir = fullfile(baseDir, outDirName);
if(~exist(outDir,'dir')) mkdir(outDir); end
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
if(nnInterp)
  tmp1 = load(fullfile(baseDir, 'segDataAdults_interpNN.mat'));
  tmp2 = load(fullfile(baseDir, 'segDataChildren_interpNN.mat'));
else
  tmp1 = load(fullfile(baseDir, 'segDataAdults_interpTL.mat'));
  tmp2 = load(fullfile(baseDir, 'segDataChildren_interpTL.mat'));
end
segs = tmp1.segs;
nSegs = size(segs,2);
segNames = {segs.name};
groupCode = [ones(1,size(tmp1.fiberCC,1)) ones(1,size(tmp2.fiberCC,1))*2];
subCode = [tmp1.subCode tmp2.subCode];
fiberCC = vertcat(tmp1.fiberCC, tmp2.fiberCC);
dt6 = vertcat(tmp1.dt6, tmp2.dt6);
ccCoords = horzcat(tmp1.ccCoords, tmp2.ccCoords);
clear tmp1 tmp2;

%% EXCLUDE SOME SUBJECTS
% 
% We exclude one adult who is an age outlier (bw) and the kids who would be
% classified as dyslexic. The resulting sample can be called
% 'neurologically normal'.
% NOTE: add when segmented rh, rsh, tv, vh
%excludeSubs = {'bw040806' 'bw040922' 'ada041018' 'ajs040629' 'an041018' 'at040918' ...
% 'ctr040618' 'dh040607' 'js040726' 'ks040720' 'lg041019' 'nad040610' 'tk040817'}; 
% tk has distortions from dental work; dh is missing all left
% temporal fibers; rs's dti's are fuzzy (movement?) but look
% usable; an's data are also fuzzy, and their diffusion properties
% are extreme outliers, so we exclude them. 
%excludeSubs = {'bw040806','tk040817','dh040607','an041018'};%;,'rs040918'};
excludeSubs = {'bw040806','dh040607','an041018','hy040602','lg041019','mh040630','tk040817'}
goodSubs = ones(size(subCode));
for(ii=1:length(excludeSubs))
    badSub = strmatch(excludeSubs{ii},subCode);
    goodSubs(badSub) = 0;
end
goodSubs = goodSubs==1;
ccCoords = ccCoords(:,goodSubs);
dt6 = dt6(goodSubs,:,:,:,:);
fiberCC = fiberCC(goodSubs,:,:);
groupCode = groupCode(goodSubs);
subCode = subCode(goodSubs);

nSubs = size(fiberCC,1);
adults = groupCode==1;
children = groupCode==2;
nAdults = sum(adults);
nChildren = sum(children);


%% CLEAN CC ROIs
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

%% EXTRACT FA and MD 
%
% Extract all midsaggital points that are within the cleaned CC
% ROI.
clear fiberYZ fiberNearestCC fiberCoord fiberFa fiberMd fiberPdd iberSdd fiberEigVals;
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
      % Exclude fibers with crazy points
      if(jj==2)
	% clean the temporal fibers by removing fibers with a
	% mid-sag crossing that is anterior of the AC (Y>0).
	badPts = fiberYZ(:,1)'>0;
	if(any(badPts))
	  msg = sprintf('Removing %d of %d points from %s in subject %s.',sum(badPts),length(goodPts),segNames{jj},subCode{ii});
	  disp(msg);
	  fprintf(logFile, msg);
	  goodPts = goodPts&~badPts;
	end
      end
      fiberNearestCC{ii,jj,hs}(~goodPts) = [];
      fiberCoord{ii,jj,hs} = fiberYZ(goodPts,:);
      [eigvec,eigval] = dtiEig(shiftdim(dt6{ii,jj,hs}(goodPts,fiberSampPts,:),-1));
      [fiberFa{ii,jj,hs},fiberMd{ii,jj,hs}] = dtiComputeFA(eigval);
      fiberPdd{ii,jj,hs} = shiftdim(eigvec(:,:,:,:,1),1);
      fiberSdd{ii,jj,hs} = shiftdim(eigvec(:,:,:,:,1),1);
      fiberEigVals{ii,jj,hs} = shiftdim(eigval,1);
      % convert from um^2/sec to um^2/ms
      fiberEigVals{ii,jj,hs} = fiberEigVals{ii,jj,hs}./1000;
      fiberMd{ii,jj,hs} = fiberMd{ii,jj,hs}./1000;
    end
  end
end
clear tmp;
diffusivityUnitStr = '(\mum^2/msec)';


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


%% SUMMARIZE SEGMENTS
%
% We collapse all fiber point measurements into one measurement per segment
% per subject. 
%
if(useMedian) avgFuncName = 'nanmedian'; 
else avgFuncName = 'nanmean'; end
fprintf(logFile, '\nCentral tendency function is "%s".\n', avgFuncName);
mnFa = ones([nSubs,nSegs,3])*NaN;
mnMd = mnFa;
mnRd = mnFa;
mnPdd = ones([nSubs,nSegs,3,3])*NaN;
mnSdd = ones([nSubs,nSegs,3,3])*NaN;
mnEigVals = mnPdd;
for(ii=1:nSubs)
    for(jj=1:nSegs)
        for(hs=1:3)
            if(hs==3)
                tmpFa = vertcat(fiberFa{ii,jj,1}(:), fiberFa{ii,jj,2}(:));
                tmpMd = vertcat(fiberMd{ii,jj,1}(:), fiberMd{ii,jj,2}(:));
                tmpPdd = vertcat(reshape(fiberPdd{ii,jj,1},size(fiberPdd{ii,jj,1},1)*size(fiberPdd{ii,jj,1},2),3),...
                    reshape(fiberPdd{ii,jj,2},size(fiberPdd{ii,jj,2},1)*size(fiberPdd{ii,jj,2},2),3));
                tmpSdd = vertcat(reshape(fiberSdd{ii,jj,1},size(fiberSdd{ii,jj,1},1)*size(fiberSdd{ii,jj,1},2),3),...
                    reshape(fiberSdd{ii,jj,2},size(fiberSdd{ii,jj,2},1)*size(fiberSdd{ii,jj,2},2),3));
                tmpEigVals = vertcat(reshape(fiberEigVals{ii,jj,1},size(fiberEigVals{ii,jj,1},1)*size(fiberEigVals{ii,jj,1},2),3),...
                    reshape(fiberEigVals{ii,jj,2},size(fiberEigVals{ii,jj,2},1)*size(fiberEigVals{ii,jj,2},2),3));
            else
                tmpFa = fiberFa{ii,jj,hs}(:);
                tmpMd = fiberMd{ii,jj,hs}(:);
                tmpPdd = reshape(fiberPdd{ii,jj,hs},size(fiberPdd{ii,jj,hs},1)*size(fiberPdd{ii,jj,hs},2),3);
                tmpSdd = reshape(fiberSdd{ii,jj,hs},size(fiberSdd{ii,jj,hs},1)*size(fiberSdd{ii,jj,hs},2),3);
                tmpEigVals = reshape(fiberEigVals{ii,jj,hs},size(fiberEigVals{ii,jj,hs},1)*size(fiberEigVals{ii,jj,hs},2),3);
            end
            % FA vals of exactly zero were NaNs. We reset them to NaN so
            % that they get ignored in the averaging.
            tmpFa(tmpFa==0) = NaN;
            tmpFa(tmpFa>=1) = NaN;
            tmpMd(tmpMd==0) = NaN;
            if(~weightByFiberDensity)
                [junk,uniquePdd] = unique(tmpPdd,'rows');
                [junk,uniqueEV] = unique(tmpEigVals,'rows');
                uniqueVals = intersect(uniquePdd,uniqueEV);
                tmpFa = tmpFa(uniqueVals);
                tmpMd = tmpMd(uniqueVals);
                tmpPdd = tmpPdd(uniqueVals,:);
                tmpSdd = tmpSdd(uniqueVals,:);
                tmpEigVals = tmpEigVals(uniqueVals,:);
            end

            n(ii,jj,hs) = length(tmpFa);
            if(n(ii,jj,hs)>0)
                mnFa(ii,jj,hs) = feval(avgFuncName, tmpFa);
                mnMd(ii,jj,hs) = feval(avgFuncName, tmpMd);
                % It doesn't make sense to average PDDs with mean or
                % median. The following will account for the fact that,
                % eg. [0 0 1] is equivalent to [0 0 -1]. Note that
                % dtiDirMean collapses across the 'subject' dimension (the
                % last dim), so we need the fancy reshaping to get it to do
                % what we want.
                tmpPdd = tmpPdd(~(isnan(tmpPdd(:,1))|isnan(tmpPdd(:,2))|isnan(tmpPdd(:,3))),:);
                [mnPdd(ii,jj,hs,:),S] = dtiDirMean(shiftdim(tmpPdd',-1));
                % convert dispersion into an angle, in degrees
                dispPdd(ii,jj,hs,:) = asin(sqrt(S))./pi.*180;
                tmpSdd = tmpSdd(~(isnan(tmpSdd(:,1))|isnan(tmpSdd(:,2))|isnan(tmpSdd(:,3))),:);
                [mnSdd(ii,jj,hs,:),S] = dtiDirMean(shiftdim(tmpSdd',-1));
                dispSdd(ii,jj,hs,:) = asin(sqrt(S))./pi.*180;
                mnEigVals(ii,jj,hs,:) = feval(avgFuncName, tmpEigVals, 1);
                mnRd(ii,jj,hs) = mean(mnEigVals(ii,jj,hs,2:3));
            end
        end
        % Compute the fiber intersection density for each point in the ccRoi
        nCcCoords = size(ccYZCoords{ii},1);
        ccYZDensity{ii,jj} = hist([fiberNearestCC{ii,jj,:}],[1:nCcCoords]);
    end
end
clear tmpFa tmpMd tmpPdd tmpSdd tmpEigVals;
clear fiberFa fiberMd fiberPdd fiberSdd fiberEigVals;

%% Assign a unique segment to each ccRoi point
%
for(ii=1:nSubs)
    % What if there are multiple maxima? The following will take the first.
    % This is actually quite rare for our data, so doing something more
    % intelligent isn't necessary.
    [junk,ccSegAssignment{ii}] = max(vertcat(ccYZDensity{ii,:}));
    ccSegAssignment{ii}(junk==0) = 0;
end
% Generate ROIs for each segment
roiDir = fullfile(outDir,'ROIs');
if(~exist(roiDir,'dir')) mkdir(roiDir); end
for(ii=1:nSubs)
  for(jj=1:nSegs)
    coords = ccCoordsCleaned{ii}(:,ccSegAssignment{ii}==jj);
    nc = size(coords,2);
    coords = [[repmat(-1,1,nc);coords],[repmat(0,1,nc);coords],[repmat(1,1,nc);coords]];
    color = barColor(jj,:);
    name = segNames{jj};
    fname = fullfile(roiDir,[subCode{ii} '_' segNames{jj}]);
    roi = dtiNewRoi(name, color, coords);
    dtiWriteRoi(roi, fname);
  end
end

figNum = 91;
  
if(figs)
  % Make a legend
  legImg = ones(143,16,3);
  segNamesLong = {'Occipital','Temporal','Posterior Parietal','Superior Parietal','Superior Frontal','Anterior Frontal','Orbital Frontal','Indeterminate'};
  for(ii=1:nSegs)
    for(jj=1:3)
      yPos = (ii-1)*18+1;
      legImg(yPos:yPos+16,:,jj) = barColor(ii,jj);
    end
  end
  figure(figNum); image(legImg); axis equal off tight;
  mrUtilResizeFigure(figNum, 128, 170);
  set(gca,'units','pixels','position',[8 10 size(legImg,2) size(legImg,1)]);
  for(ii=1:nSegs)
    text(18,(ii-1)*18+9,segNamesLong{ii},'FontSize',10);
  end
  mrUtilPrintFigure(fullfile(outDir,'segLegend'),figNum);
  pause(1);clf;

  ccBounds = [min(vertcat(ccYZCoords{:,:})); max(vertcat(ccYZCoords{:,:}))];
  ccBox = diff(ccBounds)+3;
  ccOffset = -ccBounds(1,:)+[2 2];
  %r = ceil(sqrt(nSubs));
  r = 8;
  c = ceil(nSubs/r);
  ccImg = ones([ccBox nSubs 3]);
  for(ii=1:nSubs)
    tmp = {ones(ccBox), ones(ccBox), ones(ccBox)};
    % Assign the un-assigned points (use the same color as the scaps)
    goodPts = ccSegAssignment{ii}==0;
    x = ccYZCoords{ii}(goodPts,1)+ccOffset(1);
    y = ccYZCoords{ii}(goodPts,2)+ccOffset(2);
    for(kk=1:3)
      tmp{kk}(sub2ind(ccBox,x,y)) = barColor(nSegs,kk);
    end
    for(jj=nSegs:-1:1)
      goodPts = ccSegAssignment{ii}==jj;
      x = ccYZCoords{ii}(goodPts,1)+ccOffset(1);
      y = ccYZCoords{ii}(goodPts,2)+ccOffset(2);
      for(kk=1:3)
	tmp{kk}(sub2ind(ccBox,x,y)) = barColor(jj,kk);
      end
    end
    for(kk=1:3) ccImg(:,:,ii,kk) = tmp{kk}; end
    % plot the anterior commissure (at ccOffset) for anatomical reference
    ccImg(ccOffset(1),ccOffset(2),ii,:) = [0 0 0];
  end
  % swap x,y and flipdim to the correct orintation
  ccImg = flipdim(flipdim(permute(ccImg,[2 1 3 4]),1),2);
  ccMontage = makeMontage3(ccImg,[],1,0,[],c,figNum,[1 1 1]);
  imwrite(ccMontage, fullfile(outDir,'allSubsAllSegs.png'));
  ccMontage = imresize(ccMontage,2,'nearest');
  imwrite(ccMontage, fullfile(outDir,'allSubsAllSegs2x.png'));
  pause(1);clf;

  % Do it again for just the kids
  %
  ccBounds = [min(vertcat(ccYZCoords{:,children})); max(vertcat(ccYZCoords{:,children}))];
  ccBox = diff(ccBounds)+[3 9]; %[[3 3] +7?
  ccOffset = -ccBounds(1,:)+[2 5];
  addMeanImage = false;
  r = 10; % 7
  c = ceil(nChildren/r);
  subInd = find(children);
  % create a binary mask for each of the segments, plus the
  % unassigned voxels.
  maskIms = cell(nChildren,nSegs);
  for(ii=1:nChildren)
    for(jj=1:nSegs)
      maskIms{ii,jj} = zeros(ccBox);
      goodPts = ccSegAssignment{subInd(ii)}==jj;
      x = ccYZCoords{subInd(ii)}(goodPts,1)+ccOffset(1);
      y = ccYZCoords{subInd(ii)}(goodPts,2)+ccOffset(2);
      maskIms{ii,jj}(sub2ind(ccBox,x,y)) = 1;
    end
    % Include the un-assigned points in the scraps (the last segment)
    goodPts = ccSegAssignment{subInd(ii)}==0;
    x = ccYZCoords{subInd(ii)}(goodPts,1)+ccOffset(1);
    y = ccYZCoords{subInd(ii)}(goodPts,2)+ccOffset(2);
    maskIms{ii,nSegs}(sub2ind(ccBox,x,y)) = 1;
  end
  if(addMeanImage)
    for(jj=1:nSegs)
      tmp = cat(3,maskIms{:,jj});
      maskIms{nChildren+1,jj} = mean(tmp,3);
    end
  end
  n = length(maskIms);
  kern = fspecial('gaussian',5,0.6);
  for(ii=1:n)
    for(jj=1:nSegs)
      maskIms{ii,jj} = imfilter(maskIms{ii,jj},kern,'replicate');
      maskIms{ii,jj} = upSample(maskIms{ii,jj},3);
    end
  end
  
  thresh = 0.2;
  sz = size(maskIms{1,1});
  ccImg = zeros([sz n 3]);
  for(ii=1:n)
    tmp = {ones(sz) ones(sz) ones(sz)};
    for(jj=nSegs:-1:1)
      for(kk=1:3)
	tmp{kk}(maskIms{ii,jj}>=thresh) = barColor(jj,kk);
      end
    end
    for(kk=1:3) 
      ccImg(:,:,ii,kk) = tmp{kk}; 
    end
    % plot the anterior commissure (at ccOffset) for anatomical reference
    %ccImg(ccOffset(1),ccOffset(2),ii,:) = [0 0 0];
  end
  ccImg = flipdim(flipdim(permute(ccImg,[2 1 3 4]),1),2);
  ccMontage = makeMontage3(ccImg,[],1,0,[],c,figNum,[1 1 1]);
  imwrite(ccMontage, fullfile(outDir,'childrenAllSegs.png'));
  %ccMontageBig = imresize(ccMontage,2,'nearest');
  %ccMontageBig(ccMontageBig<0)=0;ccMontageBig(ccMontageBig>1)=1;
  %image(ccMontageBig);axis image; truesize;
  %imwrite(ccMontageBig, fullfile(outDir,'childrenAllSegs2x.png'));
  pause(1); clf;
  error('stop here');
end

%% COMPUTE SEGMENT AREA
%
for(ii=1:nSubs)
  totalCcArea(ii) = size(ccYZCoords{ii},1);
  for(jj=1:nSegs)
    for(hs=1:3)
      segArea(ii,jj,hs) = sum(ccSegAssignment{ii}==jj);
      relSegArea(ii,jj,hs) = segArea(ii,jj)./totalCcArea(ii);
    end
  end 
end
[p,t,df] = statTest(totalCcArea(groupCode==1),totalCcArea(groupCode==2),'t');
fprintf(logFile, '\nTotal CC area:  %s (%0.0f mm^2) vs. %s (%0.0f mm^2): t=%0.2f (p=%0.6f, df=%d)\n', ...
    groups{1}, mean(totalCcArea(groupCode==1)), groups{2}, mean(totalCcArea(groupCode==2)),...
    t, p, df);

for(jj=1:nSegs)
    [p,t,df] = statTest(segArea(groupCode==1,jj,3),segArea(groupCode==2,jj,3),'t');
    fprintf(logFile, '%s CC area:  %s (%0.0f mm^2) vs. %s (%0.0f mm^2): t=%0.2f (p=%0.6f, df=%d)\n', ...
        segNames{jj}, groups{1}, mean(segArea(groupCode==1,jj,3)), groups{2}, mean(segArea(groupCode==2,jj,3)),...
        t, p, df);
    tArea(jj) = t;
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    sArea{jj} = s;
end
for(jj=1:nSegs)
    [p,t,df] = statTest(relSegArea(groupCode==1,jj,3),relSegArea(groupCode==2,jj,3),'t');
    fprintf(logFile, '%s relative CC area:  %s (%0.2f) vs. %s (%0.2f): t=%0.2f (p=%0.6f, df=%d)\n', ...
        segNames{jj}, groups{1}, mean(relSegArea(groupCode==1,jj,3)), groups{2}, mean(relSegArea(groupCode==2,jj,3)),...
        t, p, df);
    tRelArea(jj) = t;
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; else s='   '; end
    sRelArea{jj} = s;
end

%% GET BEHAVIORAL DATA
%

%[bd,bdColNames] = dtiGetBehavioralData(subCode,behavDataFile);
[bd,bdColNames] = dtiGetBehavioralData(subCode,'/biac3/wandell4/data/reading_longitude/read_behav_measures_longitude_bob.csv');
%ageInd = strmatch('DTI Age.1',bdColNames);
%paInd = strmatch('Phonological Awareness.1',bdColNames);
%adhdInd = strmatch('Conners ADHD Index t-score',bdColNames);
%readerTypeInd = strmatch('Type of Reader.1',bdColNames);
ageInd = strmatch('Age (Y1)',bdColNames);
paInd = strmatch('Phonological Awareness',bdColNames);
adhdInd = strmatch('Conners ADHD Index t-score',bdColNames);
readerTypeInd = strmatch('Type of Reader',bdColNames);
goodReaders = bd(:,readerTypeInd)'>=0;
children =  ~[isnan(bd(:,ageInd))|bd(:,ageInd)>=18]';
%children = children&goodReaders;


%% CREATE MEAN SUMMARY TABLE
% 
% Create comma delimited text file with callosal data
%
fid = fopen(fullfile(outDir,dataTableName), 'wt');
fprintf(fid,'Subject,Group,Segment,FA_Left,FA_Right,FA_ALL,MD_Left,MD_Right,MD_all,SegArea,RelSegArea\n');
for(ii=1:nSubs)
   for(jj=1:nSegs)
     fprintf(fid,'%d,%s,%d,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f\n',ii,groups{groupCode(ii)},jj,mnFa(ii,jj,1),...
         mnFa(ii,jj,2),mnFa(ii,jj,3),mnMd(ii,jj,1),mnMd(ii,jj,2),mnMd(ii,jj,3),segArea(ii,jj,3),relSegArea(ii,jj,3));
   end
end
fclose(fid);

% Run paired t-tests between segments on DTI values results are displayed in the command window
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
% segment for FA, MD, seg area, longitudinal diffusivity, and radial
% diffusivity
fprintf(logFile, '\n* * * Adults vs. children * * *\n');
fprintf(logFile,'FA, two-sample t-test:\n');
for(ii=[1:7])
    [p,t,df]=statTest(mnFa(children,ii,3),mnFa(adults,ii,3),'t');
    if(p<=0.001) sFa{ii}='***'; elseif(p<=0.01) sFa{ii}=' **'; elseif(p<=0.05) sFa{ii}='  *'; else sFa{ii}='   '; end
     fprintf(logFile,'%s Child %s (%0.3f) vs. Adult %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
             sFa{ii}, segNames{ii},mean(mnFa(children,ii,3)),segNames{ii},mean(mnFa(adults,ii,3)),t,p,df);
    tFa(ii)=t;
end

fprintf(logFile,'Mean Diffusivity, two-sample t-test:\n');
for(ii=[1:7])
    [p,t,df]=statTest(mnMd(children,ii,3),mnMd(adults,ii,3),'t');
    if(p<=0.001) sMd{ii}='***'; elseif(p<=0.01) sMd{ii}=' **'; elseif(p<=0.05) sMd{ii}='  *'; else sMd{ii}='   '; end
     fprintf(logFile,'%s Child %s (%0.3f) vs. Adult %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
            sMd{ii}, segNames{ii},mean(mnMd(children,ii,3)),segNames{ii},mean(mnMd(adults,ii,3)),t,p,df);
    tMd(ii)=t;
end

fprintf(logFile,'Segment Area, two-sample t-test:\n');
for(ii=[1:7])
    [p,t,df]=statTest(segArea(children,ii,3),segArea(adults,ii,3),'t');
    if(p<=0.001) sSA{ii}='***'; elseif(p<=0.01) sSA{ii}=' **'; elseif(p<=0.05) sSA{ii}='  *'; else sSA{ii}='   '; end
     fprintf(logFile,'%s Child %s (%0.3f) vs. Adult %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
            sSA{ii},segNames{ii},mean(segArea(children,ii,3)),segNames{ii},mean(segArea(adults,ii,3)),t,p,df);
    tSA(ii)=t;
end

fprintf(logFile,'Longitudinal diffusivity, two-sample t-test:\n');
for(ii=[1:7])
  childLd = (squeeze(mnEigVals(children,ii,3,1)));
  adultLd = (squeeze(mnEigVals(adults,ii,3,1)));
  [p,t,df]=statTest(childLd,adultLd,'t');
  if(p<=0.001) sLd{ii}='***'; elseif(p<=0.01) sLd{ii}=' **'; elseif(p<=0.05) sLd{ii}='  *'; else sLd{ii}='   '; end
  fprintf(logFile,'%s Child %s (%0.3f) vs. Adult %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
	  sLd{ii}, segNames{ii},mean(childLd),segNames{ii},mean(adultLd),t,p,df);
  tLd(ii)=t;
end

fprintf(logFile,'Radial diffusivity, two-sample t-test:\n');
for(ii=[1:7])
  childRd = mean(squeeze(mnEigVals(children,ii,3,2:3)),2);
  adultRd = mean(squeeze(mnEigVals(adults,ii,3,2:3)),2);
  [p,t,df]=statTest(childRd,adultRd,'t');
  if(p<=0.001) sRd{ii}='***'; elseif(p<=0.01) sRd{ii}=' **'; elseif(p<=0.05) sRd{ii}='  *'; else sRd{ii}='   '; end
  fprintf(logFile,'%s Child %s (%0.3f) vs. Adult %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
	  sRd{ii}, segNames{ii},mean(childRd),segNames{ii},mean(adultRd),t,p,df);
  tRd(ii)=t;
end

%% TEST FOR AGREEMENT BETWEEN HEMISPHERES
%
% TODO: compute fiber density correlations
%
minFaR = 1; minMdR = 1;
fprintf(logFile, '\n * * * Testing agreement between hemispheres * * *\n');
for(jj=[1:7])
  [p,t,df]=statTest(mnFa(:,jj,1),mnFa(:,jj,2),'p');
  [pr,r,dfr]=statTest(mnFa(:,jj,1),mnFa(:,jj,2),'r');
  if(r<minFaR) minFaR = r; end
  fprintf(logFile, '   FA Left %s (%0.3f) vs. Right %s (%0.3f): r=%0.3f, t=%0.2f (p=%0.4f, df=%d)\n', ...
	  segNames{jj},mean(mnFa(:,jj,1)),segNames{jj},mean(mnFa(:,jj,2)),r,t,p,df);
  fprintf('   FA Left %s (%0.3f) vs. Right %s (%0.3f): r=%0.3f, t=%0.2f (p=%0.4f, df=%d)\n', ...
	  segNames{jj},mean(mnFa(:,jj,1)),segNames{jj},mean(mnFa(:,jj,2)),r,t,p,df);
  [p,t,df]=statTest(mnMd(:,ii,1),mnMd(:,ii,2),'p');
  [pr,r,dfr]=statTest(mnMd(:,jj,1),mnMd(:,jj,2),'r');
  if(r<minMdR) minMdR = r; end
  fprintf(logFile, '   MD Left %s (%0.3f) vs. Right %s (%0.3f): r=%0.3f, t=%0.2f (p=%0.4f, df=%d)\n', ...
	  segNames{jj},mean(mnMd(:,jj,1)),segNames{jj},mean(mnMd(:,jj,2)),r,t,p,df);
  fprintf('   MD Left %s (%0.3f) vs. Right %s (%0.3f): r=%0.3f, t=%0.2f (p=%0.4f, df=%d)\n', ...
	  segNames{jj},mean(mnMd(:,jj,1)),segNames{jj},mean(mnMd(:,jj,2)),r,t,p,df);
end
fprintf(logFile, '   Minimum left-right FA r = %0.3f, MD r = %0.3f\n',minFaR,minMdR);
fprintf('   Minimum left-right FA r = %0.3f, MD r = %0.3f\n',minFaR,minMdR);
if(figs)
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
%
if(figs)
  % Means and standard deviations are are displayed inside the bars.  Error
  % bars = 2sem.
  
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
  fh = figure(figNum); clf; hold on;
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
  set(gca,'ylim',[0.5 .8],'ytick',[.5 .6 .7 .8],'YGrid','on')
  set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
  set(get(gca,'YLabel'),'String','FA','fontsize',14);
  mrUtilResizeFigure(fh, 650, 420);
  set(gca,'Position',[0.09 0.1 .9 .87]);
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
  
  fh = figure(figNum); clf; hold on;
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
  set(gca,'ylim',[0.8 1.0],'YGrid','on','ytick',[0.80,0.85,0.90,0.95,1.0])
  set(gca,'box','on','xtick',[1:length(mu)],'xticklabel',tickLabels,...
	  'linewidth',2,'fontsize',12)
  set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
  set(get(gca,'YLabel'),'String',['MD ' diffusivityUnitStr],'fontsize',14);
  mrUtilResizeFigure(fh, 650, 420);
  set(gca,'Position',[0.09 0.1 .9 .87]);
  mrUtilPrintFigure(fullfile(outDir,'MD_acrossSegs_devel'),fh);  
  
  %
  % Longitudinal diffusivity
  % 
  child = (squeeze(mnEigVals(children,[1:7],3,1)));
  adult = (squeeze(mnEigVals(adults,[1:7],3,1)));
  meansChild = mean(child);
  meansAdult = mean(adult);
  sdChild = std(child);
  sdAdult = std(adult);
  semChild = sdChild/sqrt(length(mnFa(children,1,1))-1);
  semAdult = sdAdult/sqrt(length(mnFa(adults,1,1))-1);
  for(ii=1:length(meansChild))
    mnLdAll(ii,1) = meansChild(ii);
    mnLdAll(ii,2) = meansAdult(ii);
  end
  fh = figure(figNum); clf; hold on;
  for(ii=[1:length(mnLdAll)])
    deltas(ii) = (meansAdult(ii)-meansChild(ii));
    y = zeros(length(mnLdAll), 2);
    y(ii,:) = mnLdAll(ii,:);
    barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
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
  set(gca,'ylim',[1.4 2.0],'YGrid','on','ytick',[1.4:0.2:2])
  set(gca,'box','on','xtick',[1:7],'xticklabel',tickLabels,...
	  'linewidth',2,'fontsize',12)
  set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
  set(get(gca,'YLabel'),'String',['Parallel ADC ' diffusivityUnitStr],'fontsize',14);
  mrUtilResizeFigure(fh, 650, 420);
  set(gca,'Position',[0.09 0.1 .9 .87]);
  mrUtilPrintFigure(fullfile(outDir,'LD_acrossSegs_devel'),fh);
  
  %
  % Radial diffusivity
  % 
  child = mean(mnEigVals(children,[1:7],3,2:3),4);
  adult = mean(mnEigVals(adults,[1:7],3,2:3),4);
  meansChild = mean(child);
  meansAdult = mean(adult);
  sdChild = std(child);
  sdAdult = std(adult);
  semChild = sdChild/sqrt(length(mnFa(children,1,1))-1);
  semAdult = sdAdult/sqrt(length(mnFa(adults,1,1))-1);
  for(ii=1:length(meansChild))
    mnRdAll(ii,1) = meansChild(ii);
    mnRdAll(ii,2) = meansAdult(ii);
  end
  fh = figure(figNum); clf; hold on;
  for(ii=[1:length(mnRdAll)])
    deltas(ii) = (meansAdult(ii)-meansChild(ii));
    y = zeros(length(mnRdAll), 2);
    y(ii,:) = mnRdAll(ii,:);
    barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
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
  set(gca,'ylim',[0.3 0.6],'YGrid','on','ytick',[0.3:0.1:0.6])
  set(gca,'box','on','xtick',[1:7],'xticklabel',tickLabels,...
	  'linewidth',2,'fontsize',12)
  set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
  set(get(gca,'YLabel'),'String',['Radial ADC ' diffusivityUnitStr],'fontsize',14);
  mrUtilResizeFigure(fh, 650, 420);
  set(gca,'Position',[0.09 0.1 .9 .87]);
  mrUtilPrintFigure(fullfile(outDir,'RD_acrossSegs_devel'),fh);
end

%% MAKE AREA GRAPH
%
child = segArea(children,1:7,3);
adult = segArea(adults,1:7,3);
meansChild = mean(child);
meansAdult = mean(adult);
sdChild = std(child);
sdAdult = std(adult);
semChild = sdChild/sqrt(sum(children)-1);
semAdult = sdAdult/sqrt(sum(adults)-1);
% Save segment stats in log file
for(jj=1:7)
  fprintf(logFile, '%s Area: child = %0.1f mm^2 (stdev=%0.2f, n=%d); adult = %0.1f mm^2 (stdev=%0.2f, n=%d)\n', ...
	  segNames{jj},meansChild(jj),sdChild(jj),size(child,1),meansAdult(jj),sdAdult(jj),size(adult,1));
  fprintf('%s Area: child = %0.1f mm^2 (stdev=%0.2f, n=%d); adult = %0.1f mm^2 (stdev=%0.2f, n=%d)\n', ...
	  segNames{jj},meansChild(jj),sdChild(jj),size(child,1),meansAdult(jj),sdAdult(jj),size(adult,1));
end

if(figs)
  for(ii=1:length(meansChild))
    mnAreaAll(ii,1) = meansChild(ii);
    mnAreaAll(ii,2) = meansAdult(ii);
  end
  fh = figure(figNum); clf; hold on;
  tmp = segArea(:,1:7,3);
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
  mrUtilResizeFigure(fh, 650, 420);
  set(gca,'Position',[0.09 0.1 .9 .87]);
  mrUtilPrintFigure(fullfile(outDir,'Area_acrossSegs_devel'),fh);
  
  if(verbose)
    figure; plot(mnMd(:,:,3), mnFa(:,:,3), 'k.')
    for(ii=1:length(mu))
      figure; plot(mnMd(:,ii,3), mnFa(:,ii,3), 'k.')
      title({tickLabels{ii}},'fontsize',20,'fontWeight','bold');
    end
  end
end
fclose(logFile);
  
% %% Analyze all subjects on age & sex
% %
% bdInds = [1 3];
% for(jj=[1:7])
%   for(ii=bdInds)
%     [p,r,df]=statTest(bd(:,ii),mnFa(:,jj,3),'r');
%     if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
%     fprintf(logFile,'%s %s FA vs. %s:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
%             s, segNames{jj},bdColNames{ii},r,p,df);
%     [p,r,df]=statTest(bd(:,ii),mnMd(:,jj,3),'r');
%     if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
%     fprintf(logFile,'%s %s MD vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
%             s, segNames{jj},bdColNames{ii},r,p,df);
%     [p,r,df]=statTest(bd(:,ii),segArea(:,jj),'r');
%     if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
%     fprintf(logFile,'%s %s SegArea vs. %s: r=%0.2f (p=%0.4f, df=%d)\n', ...
%             s, segNames{jj},bdColNames{ii},r,p,df);
%   end
% end
% fclose(logFile);
  
%% BEHAVIORAL CORRELATIONS
%
%bdInds = [1:length(bdColNames)];
%bdInds = [39:58];
%bdInds = [3 4 6 8 9 10 12 13 16 21]; % Original submission
%bdInds = [1 2 3 5 7 9 11 12 13 16 18 21]; % now include WISK WM index
%bdNameList = {'Sex (1=male)','SES','Conners ADHD Index t-score','DTI Age.1',...
%              'Word ID ss.1','Word attack ss.1','Phonological Awareness.1',...
%              'Passage Comprehension.1','Rapid Naming.1','Phonological Memory.1',...
%              'GORT Reading Quotient.1','WISC Working Memory Index.1','WISC Full-Scale IQ.1'};
bdNameList = {'Sex (1=male)','Age (Y1)','Phonological Awareness','Passage Comprehension','visart.yr1','music.yr1','dance.yr1','drama.yr1','allarts.yr1','musicinschoolhrsavg','visualinschoolhrsavg','danceinschoolhrsavg'};
bdInds = zeros(length(bdNameList),1);
for(ii=1:length(bdNameList))
    bdInds(ii) = strmatch(bdNameList{ii},bdColNames,'exact');
end
% CTOPP high-level scores: phonological awareness, phonological
% memory, rapid naming. Of the computer tasks, the pseudohomophone
% task has some correlations, but there are quite a few missing
% subjects and alot of noise. Also, it is highly correlated with
% PA (both conceptually and empiricaly), so there isn't much added
% in terms of variance explained.
% Analyze only children
goodSubs = children';
N = sum(goodSubs);

%% PDD/SDD consistency analysis
logFile = fopen(fullfile(outDir,'log.txt'),'at');
fprintf(logFile, '\n* * * PDD consistency test * * *\n');
fprintf('\n* * * PDD consistency test * * *\n');
for(jj=[1:7])
  [pddMean(jj,:), pddDisp(jj)] = dtiDirMean(shiftdim(squeeze(mnPdd(:,jj,3,:))',-1));
  % Convert dispersion to degrees angle
  pddDisp(jj) = asin(sqrt(pddDisp(jj)))./pi.*180;
  mnWithinSegPddDisp(jj) = mean(squeeze(dispPdd(:,jj,3,:)));
  % make sure all means point the same way
  if(pddMean(jj,1)<0) pddMean(jj,:) = pddMean(jj,:).*-1; end
  lrDeviationPdd(jj) = acos(dot(pddMean(jj,:),[1 0 0]))/pi*180;
  fprintf('%s PDD: mean = [%0.3f, %0.3f, %0.3f], dispersion = %0.4f deg (%0.4f deg within seg), L/R Deviation = %0.3f deg.\n', ...
	  segNames{jj},pddMean(jj,1),pddMean(jj,2),pddMean(jj,3),pddDisp(jj),mnWithinSegPddDisp(jj),lrDeviationPdd(jj));
  fprintf(logFile, '%s PDD: mean = [%0.3f, %0.3f, %0.3f], dispersion = %0.4f deg (%0.4f deg within seg), L/R Deviation = %0.3f deg.\n', ...
	  segNames{jj},pddMean(jj,1),pddMean(jj,2),pddMean(jj,3),pddDisp(jj),mnWithinSegPddDisp(jj),lrDeviationPdd(jj));
end
fprintf(logFile, '\n* * * SDD consistency test * * *\n');
fprintf('\n* * * SDD consistency test * * *\n');
for(jj=[1:7])
  [sddMean(jj,:), sddDisp(jj)] = dtiDirMean(shiftdim(squeeze(mnSdd(:,jj,3,:))',-1));
  % Convert dispersion to degrees angle
  sddDisp(jj) = asin(sqrt(sddDisp(jj)))./pi.*180;
  mnWithinSegSddDisp(jj) = mean(squeeze(dispSdd(:,jj,3,:)));
  % make sure all means point the same way
  %if(sddMean(jj,2)<0) sddMean(jj,:) = sddMean(jj,:).*-1; end
  apDeviationSdd(jj) = acos(dot(sddMean(jj,:),[0 1 0]))/pi*180;
  fprintf('%s SDD: mean = [%0.3f, %0.3f, %0.3f], dispersion = %0.4f deg (%0.4f deg within seg), A/P Deviation = %0.3f deg.\n', ...
	  segNames{jj},sddMean(jj,1),sddMean(jj,2),sddMean(jj,3),sddDisp(jj),mnWithinSegSddDisp(jj),apDeviationSdd(jj));
  fprintf(logFile, '%s SDD: mean = [%0.3f, %0.3f, %0.3f], dispersion = %0.4f deg (%0.4f deg within seg), A/P Deviation = %0.3f deg.\n', ...
	  segNames{jj},sddMean(jj,1),sddMean(jj,2),sddMean(jj,3),sddDisp(jj),mnWithinSegSddDisp(jj),apDeviationSdd(jj));
end

for(jj=[1:7])
  for(ii=1:length(bdInds))
    bdIndex = bdInds(ii);
    notNan = ~isnan(bd(:,bdIndex));
    x = bd(goodSubs&notNan,bdIndex);
    y = squeeze(mnPdd(goodSubs&notNan,jj,3,:));
    y = acos(dot(y,repmat([1 0 0],size(y,1),1),2));
    [pddP(ii,jj),pddR(ii,jj),pddDf(ii,jj)] = statTest(x,y,'r');
    if(pddP(ii,jj)<=0.001) s='***'; elseif(pddP(ii,jj)<=0.01) s=' **'; 
    elseif(pddP(ii,jj)<=0.05) s='  *'; elseif(pddP(ii,jj)<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s %s vs. PDD L/R deviation:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
	    s, segNames{jj},bdColNames{bdIndex},pddR(ii,jj),pddP(ii,jj),pddDf(ii,jj));
    fprintf(logFile,'%s %s %s vs. PDD L/R deviation:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
	    s, segNames{jj},bdColNames{bdIndex},pddR(ii,jj),pddP(ii,jj),pddDf(ii,jj));
    y = squeeze(dispPdd(goodSubs&notNan,jj,3,:));
    [pddP(ii,jj),pddR(ii,jj),pddDf(ii,jj)] = statTest(x,y,'r');
    if(pddP(ii,jj)<=0.001) s='***'; elseif(pddP(ii,jj)<=0.01) s=' **'; 
    elseif(pddP(ii,jj)<=0.05) s='  *'; elseif(pddP(ii,jj)<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s %s vs. PDD dispersion:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
	    s, segNames{jj},bdColNames{bdIndex},pddR(ii,jj),pddP(ii,jj),pddDf(ii,jj));
    fprintf(logFile,'%s %s %s vs. PDD dispersion:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
	    s, segNames{jj},bdColNames{bdIndex},pddR(ii,jj),pddP(ii,jj),pddDf(ii,jj));
    y = squeeze(mnSdd(goodSubs&notNan,jj,3,:));
    y = acos(dot(y,repmat([0 1 0],size(y,1),1),2));
    [sddP(ii,jj),sddR(ii,jj),sddDf(ii,jj)] = statTest(x,y,'r');
    if(sddP(ii,jj)<=0.001) s='***'; elseif(sddP(ii,jj)<=0.01) s=' **'; 
    elseif(sddP(ii,jj)<=0.05) s='  *'; elseif(sddP(ii,jj)<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s %s vs. SDD A/P deviation:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
	    s, segNames{jj},bdColNames{bdIndex},sddR(ii,jj),sddP(ii,jj),sddDf(ii,jj));
	fprintf(logFile,'%s %s %s vs. SDD A/P deviation:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
	    s, segNames{jj},bdColNames{bdIndex},sddR(ii,jj),sddP(ii,jj),sddDf(ii,jj));
    y = squeeze(dispSdd(goodSubs&notNan,jj,3,:));
    [sddP(ii,jj),sddR(ii,jj),sddDf(ii,jj)] = statTest(x,y,'r');
    if(sddP(ii,jj)<=0.001) s='***'; elseif(sddP(ii,jj)<=0.01) s=' **'; 
    elseif(sddP(ii,jj)<=0.05) s='  *'; elseif(sddP(ii,jj)<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s %s vs. SDD dispersion:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
	    s, segNames{jj},bdColNames{bdIndex},sddR(ii,jj),sddP(ii,jj),sddDf(ii,jj));
    fprintf(logFile,'%s %s %s vs. SDD dispersion:\tr=%0.2f\t(p=%0.4f, df=%d)\n', ...
	    s, segNames{jj},bdColNames{bdIndex},sddR(ii,jj),sddP(ii,jj),sddDf(ii,jj));
  end
end
% Monte-carlo estimate of SDD idspersion given a fixed PDD
% (ie. dispersion on a circle rather than on the sphere)
nSamps = 100000;
theta = rand(nSamps,1).*(2*pi)-pi;
phi = rand(nSamps,1).*(2*pi)-pi;
%randSdd = [cos(phi) cos(theta).*sin(phi) sin(theta).*sin(phi)];
randSdd = [zeros(size(phi)) cos(theta).*sin(phi) sin(theta).*sin(phi)];
randSdd = randSdd./repmat(sqrt(sum(randSdd.*randSdd,2)),1,3);
% dtiDirMean collapses across the 'subject' dimension (the last
% dim), so we need the reshaping to get it to do what we want.
[mnRandSdd,S] = dtiDirMean(shiftdim(randSdd',-1));
% convert dispersion into an angle, in degrees
randDispSdd = asin(sqrt(S))./pi.*180;
% randSdd = dtiDirSample(2/3, nSamps, [0 0 1]); randSdd = randSdd';
% figure; plot3(randSdd(:,1), randSdd(:,2), randSdd(:,3),'.'); axis equal;
fprintf('Dispersion of random directions given a fixed axis of rotation = %0.2f deg\n', randDispSdd);
fprintf(logFile,'Dispersion of random directions given a fixed axis of rotation = %0.2f deg\n', randDispSdd);
fclose(logFile);

%% Compute Behavior/brain stats
%
% To exclude the borderline ADHD subject:
goodSubs = goodSubs&bd(:,adhdInd)<=65;

logFile = fopen(fullfile(outDir,'log.txt'),'at');
fprintf(logFile, '\n* * * Behavioral tests * * *\n');
fprintf('\n* * * Behavioral tests * * *\n');
brainVarName = {'FA','mnFa';'MD','mnMd';'Area','segArea';'rADC','mnRd'};
maxBdNameLen = max(cellfun('size',bdColNames(bdInds),2));
clear r_p r_val r_df r_boot s_p s_val s_df t_p t_val t_df;
for(jj=[1:7])
  for(ii=1:length(bdInds))
    bdIndex = bdInds(ii);
    notNan = ~isnan(bd(:,bdIndex));
    for(kk=1:size(brainVarName,1))
      x = bd(goodSubs&notNan,bdIndex);
      oneThird = round(length(x)./3);
      eval(['y = ' brainVarName{kk,2} '(goodSubs&notNan,jj,3);']);
      % correlation coefficient
      [r_val(ii,jj,kk),r_p(ii,jj,kk)] = corr(x,y,'type','Pearson');
      r_df(ii,jj,kk) = length(x)-2;
      r_boot(ii,jj,kk,:) = bootstrp(1000,@corr,x,y);
      % Compute the 95% CIs based on the bootstrap r-values
      [pdfY,pdfX] = ksdensity(squeeze(r_boot(ii,jj,kk,:)));
      cs = cumsum(pdfY./length(pdfY));
      ub = find(cs<=0.975);
      r_ub(ii,jj,kk) = pdfX(ub(end));
      lb = find(cs>=0.025); 
      r_lb(ii,jj,kk) = pdfX(lb(1));
      % Spearman rank-order correlation
      [s_val(ii,jj,kk),s_p(ii,jj,kk)] = corr(x,y,'type','Spearman');
      s_df(ii,jj,kk) = length(x)-2;
      %[r_p(ii,jj,kk),r_val(ii,jj,kk),r_df(ii,jj,kk)]=statTest(x,y,'r');
      % t-test on upper and lower thirds (0-33 & 66-100 percentiles)
      [xSorted,inds] = sort(x);
      inds(isnan(xSorted)) = [];
      botThird = inds(1:oneThird);
      topThird = inds(end-oneThird+1:end);
      [t_p(ii,jj,kk),t_val(ii,jj,kk),t_df(ii,jj,kk)]=statTest(y(botThird),y(topThird),'u');
      %[h,p(ii,:),ci,stats] = ttest2(y(botThird), y(topThird),0.05,'both','unequal');df = stats.df;s = stats.tstat;
      fprintf(logFile,'%s %s vs. %s:\tr=%0.3f\t(p=%0.2g, df=%d)\ts=%0.3f\t(p=%0.2g, df=%d)\tt=%0.1f\t(p=%0.2g, df=%0.1f)\n', ...
	      segNames{jj},bdColNames{bdIndex},brainVarName{kk,1},r_val(ii,jj,kk),r_p(ii,jj,kk),...
	      r_df(ii,jj,kk),s_val(ii,jj,kk),s_p(ii,jj,kk),s_df(ii,jj,kk),t_val(ii,jj,kk),t_p(ii,jj,kk),t_df(ii,jj,kk));
%      fprintf('%s %s vs. %s:\tr=%0.3f\t(p=%0.2g, df=%d)\tt=%0.1f\t(p=%0.2g, df=%0.1f)\n', ...
%	      segNames{jj},bdColNames{bdIndex},brainVarName{kk,1},r_val(ii,jj,kk),r_p(ii,jj,kk),...
%	      r_df(ii,jj,kk),t_val(ii,jj,kk),t_p(ii,jj,kk),t_df(ii,jj,kk));
    end
  end
end
fclose(logFile);

% Bootstrap histogram for PA/FA temporal-callosal correlations
bs = squeeze(r_boot(bdInds==paInd,2,1,:));
fh = figure(figNum); clf; mrUtilResizeFigure(fh, 600, 400);
subplot(2,1,1); ksdensity(bs); subplot(2,1,2); hist(bs,20);
mrUtilPrintFigure(fullfile(outDir,['Temporal_PA-FA_Bootstrap_hist']),fh);
clf
  
% Display anything significant at 0.05 uncorrected on either the
% correlation OR the t-test on upper and lower thirds (0-33 & 66-100 %iles)
logFile = fopen(fullfile(outDir,'log.txt'),'at');
[sigI,sigJ,sigK] = ind2sub(size(t_p),find(t_p<0.05|r_p<0.05|s_p<0.05));
for(ii=1:length(sigI))
  curR = r_val(sigI(ii),sigJ(ii),sigK(ii));
  curRP = r_p(sigI(ii),sigJ(ii),sigK(ii));
  % Compute the 95% CIs based on the bootstrap r-values
  [pdfY,pdfX] = ksdensity(squeeze(r_boot(sigI(ii),sigJ(ii),sigK(ii),:)));
  cs = cumsum(pdfY./length(pdfY));
  curRUB = find(cs<=0.975); curRUB=pdfX(curRUB(end));
  curRLB = find(cs>=0.025); curRLB=pdfX(curRLB(1));
  curS = s_val(sigI(ii),sigJ(ii),sigK(ii));
  curSP = s_p(sigI(ii),sigJ(ii),sigK(ii));
  curT = t_val(sigI(ii),sigJ(ii),sigK(ii));
  curTP = t_p(sigI(ii),sigJ(ii),sigK(ii));
  bdIndex = bdInds(sigI(ii));
  fprintf(['%-10s %-4s vs. %-' num2str(maxBdNameLen) 's: r=%+0.3f (p=%0.2e, 95%%CI=[%0.3f %0.3f])\ts=%+0.3f (p=%0.2e)\tt=%+0.1f (p=%0.2e)\n'], ...
	  segNames{sigJ(ii)},brainVarName{sigK(ii),1},bdColNames{bdIndex},curR,curRP,curRLB,curRUB,curS,curSP,curT,curTP);
  fprintf(logFile,'%-10s %-4s vs. %-35s: r=%+0.3f (p=%0.2e, 95%%CI=[%0.3f %0.3f])\ts=%+0.3f (p=%0.2e)\tt=%+0.1f (p=%0.2e)\n', ...
	  segNames{sigJ(ii)},brainVarName{sigK(ii),1},bdColNames{bdIndex},curR,curRP,curRLB,curRUB,curS,curSP,curT,curTP);
end
fclose(logFile);

% Dunn-Sidak correction:
logFile = fopen(fullfile(outDir,'log.txt'),'at');
alpha = [0.1 0.05 0.01];
%nTests = length(bdInds)*7*2;
nTests = 8*7*2;
meanCorr = mean(abs(r_val(1:nTests)));
fwAlpha = 1-(1-alpha).^(1./nTests.^(1-meanCorr));
fprintf(logFile, '\nDunn-Sidak correction: nTests = %d; meanCorr = %0.3f; alpha = %0.3f %0.3f %0.3f; FW alpha = %0.8f %0.8f %0.8f\n',nTests,meanCorr,alpha,fwAlpha);
fprintf('\nDunn-Sidak correction: nTests = %d; meanCorr = %0.3f; alpha = %0.3f %0.3f %0.3f; FW alpha = %0.8f %0.8f %0.8f\n',nTests,meanCorr,alpha,fwAlpha);
fclose(logFile);
alpha = [0.01 0.001 0.0001];

%% CREATE STATS SUMMARY TABLE
%
fid(1) = fopen(fullfile(outDir,'behavioral_stats_FA.csv'), 'wt');
fid(2) = fopen(fullfile(outDir,'behavioral_stats_MD.csv'), 'wt');
fprintf(fid(1),' '); fprintf(fid(2),' ');
for(jj=1:nSegs-1) 
  for(kk=1:2)
    fprintf(fid(kk),'\t%s %s',segNames{jj}); 
  end
end
fprintf(fid(1),'\n'); fprintf(fid(2),'\n');
for(ii=1:length(bdInds))
    fprintf(fid(1),'%s',bdColNames{bdInds(ii)});
    fprintf(fid(2),'%s',bdColNames{bdInds(ii)});
    for(jj=1:nSegs-1)
        for(kk=1:2)
            if(r_p(ii,jj,kk)<alpha(3)) sig = '***';
            elseif(r_p(ii,jj,kk)<alpha(2)) sig = '**';
            elseif(r_p(ii,jj,kk)<alpha(1)) sig = '*';
            else sig = ''; end
            fprintf(fid(kk),'\t%0.2g (%0.2g, %0.2g) %s',r_val(ii,jj,kk),r_lb(ii,jj,kk),r_ub(ii,jj,kk),sig);
        end
    end
    fprintf(fid(1),'\n'); fprintf(fid(2),'\n');
end
fclose(fid(1)); fclose(fid(2));

%% CREATE BEHAVIORAL DESCRIPTIVE STATS TABLE
%
clear fid;
fid = fopen(fullfile(outDir,'behavioral_descriptives.csv'), 'wt');
fprintf(fid,' \tMean\tStdev\tRange\n');
for(jj=1:length(bdInds))
  ii = bdInds(jj);
  fmt = '%s\t%0.1f\t%0.2f\t%0.1f-%0.1f\n';
  fprintf(fid,fmt,bdColNames{ii},nanmean(bd(goodSubs,ii)),nanstd(bd(goodSubs,ii)),...
	  min(bd(goodSubs,ii)),max(bd(goodSubs,ii)));
end
fclose(fid);


%% CREATE BEHAVIORAL CORRELATION TABLE
%
alpha = [0.01 0.001 0.0001];
[r,p] = corr(bd(:,bdInds),'rows','pairwise');
utl = triu(ones(size(p)))==1;
clear fid;
fid = fopen(fullfile(outDir,'behavioral_correlations.csv'), 'wt');
fprintf(fid,'  \t');
for(jj=1:length(bdInds)) 
	fprintf(fid,'%s\t',bdColNames{bdInds(jj)}); 
end
fprintf(fid,'\n');
for(ii=1:length(bdInds))
    fprintf(fid,'%s\t',bdColNames{bdInds(ii)});
    for(jj=1:length(bdInds))
        if(r(jj,ii)==1)
            fprintf(fid,'1\t');
        elseif(utl(ii,jj))
            if(p(ii,jj)<alpha(3)) sig = '***';
            elseif(p(ii,jj)<alpha(2)) sig = '**';
            elseif(p(ii,jj)<alpha(1)) sig = '*';
            else sig = ''; end
            fprintf(fid,'%0.2f %s\t',r(jj,ii),sig);
        else
            fprintf(fid,'%0.2f (%0.2e)\t',r(jj,ii),p(jj,ii));
        end
    end
    fprintf(fid,'\n');
end
fclose(fid);

%% TTESTS FOR SEX DIFFERENCES
logFile = fopen(fullfile(outDir,'log.txt'),'at');
fprintf(logFile,'\nSex differences\n');
boys = bd(:,1)==1&goodSubs;
girls = bd(:,1)==0&goodSubs;
fprintf(logFile, '(Sample includes %d boys out of %d total.)\n',sum(boys),sum(boys+girls));
for(ii=1:7)
    [tp, tt, tdf] = myStatTest(mnFa(boys,ii,3), mnFa(girls,ii,3), 't');
    fprintf(logFile, '  %s FA: boys=%0.3f, girls=%0.3f (t=%0.2f, p=%0.2e, df=%d)\n',...
        segNames{ii}, mean(mnFa(boys,ii,3)), mean(mnFa(girls,ii,3)), tt, tp, tdf);
    [tp, tt, tdf] = myStatTest(mnMd(boys,ii,3), mnMd(girls,ii,3), 't');
    fprintf(logFile, '  %s MD: boys=%0.3f, girls=%0.3f (t=%0.2f, p=%0.2e, df=%d)\n',...
        segNames{ii}, mean(mnMd(boys,ii,3)), mean(mnMd(girls,ii,3)), tt, tp, tdf);
end
fclose(logFile);

%% FA/MD SCATTERPLOTS
%
faRng = [min(mnFa(goodSubs,[1:7],3)); max(mnFa(goodSubs,[1:7],3))];
%faRng = [min(min(mnFa(goodSubs,[1:7],3))); max(max(mnFa(goodSubs,[1:7],3)))];
% Adjust to an aesthetically pleasing range
faRng = [floor((faRng(1,:)-.005)*20)./20; ceil((faRng(2,:)+.005)*20)./20];
% standardize the first 4
faRng(:,1:4) = [repmat(min(faRng(1,1:4)),1,4); repmat(max(faRng(2,1:4)),1,4)];
mdRng = [min(mnMd(goodSubs,[1:7],3)); max(mnMd(goodSubs,[1:7],3))];
mdRng = [floor((mdRng(1,:)-0.01)*20)./20; ceil((mdRng(2,:)+0.01)*20)./20];
mdRng(:,1:4) = [repmat(min(mdRng(1,1:4)),1,4); repmat(max(mdRng(2,1:4)),1,4)];
fh = figure(figNum); clf; mrUtilResizeFigure(fh, 300, 275);
for(ii=1:length(bdInds))
    bdInd = bdInds(ii);
    for(jj=[1:7])
        x = bd(goodSubs,bdInd);
        y = mnFa(goodSubs,jj,3);
        p = polyfit(x, y, 1);
        lx = [min(x), max(x)];
        %line(lx, p(1)*lx+p(2),'Color',[.5 .5 .5],'LineWidth',1);
        hold on; plot(x, y, 'k.'); hold off;
        axis square;
        %title([tickLabels{jj} ' Callosal Pathawys']);
        set(gca,'fontsize',12,'ylim',faRng(:,jj),'ytick',[faRng(1,jj):0.1:faRng(2,jj)]);
        set(get(gca,'YLabel'),'String',['Fractional Anisotropy'],'fontsize',12);
        set(get(gca,'XLabel'),'String',bdColNames{bdInd},'fontsize',12);
        mrUtilPrintFigure(fullfile(outDir,['ScatterFA_' segNames{jj} '_vs_' strrep(bdColNames{bdInd},' ','_') '.eps']),fh);
        clf;
        y = mnMd(goodSubs,jj,3);
        p = polyfit(x, y, 1);
        %fh = figure; mrUtilResizeFigure(fh, 300, 275);
        %line(lx, p(1)*lx+p(2),'Color',[.5 .5 .5],'LineWidth',1);
        hold on; plot(x, y, 'k.'); hold off;
        axis square;
        set(gca,'fontsize',12,'ylim',mdRng(:,jj));
        %set(gca,'ylim',[750 1150],'ytick',[800,900,1000,1100]);
        set(get(gca,'YLabel'),'String',['Mean Diffusivity ' diffusivityUnitStr],'fontsize',12);
        set(get(gca,'XLabel'),'String', bdColNames{bdInd},'fontsize',12);
        mrUtilPrintFigure(fullfile(outDir,['ScatterMD_' segNames{jj} '_vs_' strrep(bdColNames{bdInd},' ','_') '.eps']),fh);
        clf
    end
end

%% PARTIAL-CORRELATION ANALYSIS
%
[r,p]=partialcorr(bd(goodSubs,bdInds(7)), mnFa(goodSubs,2,3), bd(goodSubs,bdInds(4)))


%error('stop here');

%% Eigenvalue Scatter Plots
%
logFile = fopen(fullfile(outDir,'log.txt'),'at');
fprintf(logFile, '\n* * * Eigenvalue tests * * *\n');
fprintf('\n* * * Eigenvalue tests * * *\n');
%bdInds = [1 3 4 5 6 7 8 9 10 12 16 17 18 19 21 22 27 28 29 30 31];
evSym = {'ks','k^','ko'};
evCol = {[0 0 0],[0.4 0.4 0.4],[0 0 0]};
s = {'   ','  +','  *',' **','***'};
doFigs = true;
for(ii=paInd)
  for(jj=[1:7])
    ev = squeeze(mnEigVals(goodSubs,jj,3,:));
    x = bd(goodSubs,ii);
    if(doFigs)	
      % We'll break the y-axis just above the maximum of the second EVs.
      breakLow = ceil((max(mnEigVals(goodSubs,jj,3,2))+0.02)*10)./10;
      breakHigh = floor((min(mnEigVals(goodSubs,jj,3,1))-0.02)*10)./10;
      fh = figure(figNum); clf; mrUtilResizeFigure(fh, 300, 275); %400,375
      for(evNum=1:3)
	y = mnEigVals(goodSubs,jj,3,evNum);
	% shift the first ev down
	if(evNum==1) y = y-breakHigh+breakLow; end
	p = polyfit(x, y, 1);
	lx = [min(x), max(x)];
	line(lx, p(1)*lx+p(2),'Color',evCol{evNum},'LineWidth',1);
	hold on; h=plot(x, y, evSym{evNum}); hold off;
	set(h,'MarkerEdgeColor',evCol{evNum});
      end
      axis square;
      set(gca,'fontsize',12);
      set(get(gca,'YLabel'),'String',['Diffusivity ' diffusivityUnitStr],'fontsize',12);
      set(get(gca,'XLabel'),'String', bdColNames{ii},'fontsize',12);
      ytl = get(gca,'YTickLabel');
      newYtl = str2num(ytl);
      newYtl(newYtl>=breakLow) = newYtl(newYtl>=breakLow)+breakHigh-breakLow;
      set(gca,'YTickLabel',newYtl);
      % Now add an indicator that the axis is broken
      xlim = get(gca,'xlim');
      ytick = get(gca,'YTick');
      dx = (xlim(2)-xlim(1))./100;
      dy = (ytick(2)-ytick(1))./20;
      yy = breakLow-2*dy+rand(101,1).*2.*dy;
      xx = xlim(1)+dx.*(0:100);
      patch([xx(:);flipud(xx(:))], [yy(:);flipud(yy(:)-2.*dy)], [.8 .8 .8]);
      mrUtilPrintFigure(fullfile(outDir,['ScatterEV_' segNames{jj} '_vs_' strrep(bdColNames{ii},' ','_') '.eps']),fh);
    end
    % test correlations between all vars
    [r,p] = corrcoef([x,ev]);
    r = r([2,3,4]);
    p = p([2,3,4]);
    ns(p>.05)=1;ns(p<.05)=2;ns(p<.01)=3;ns(p<.001)=4;ns(p<.0005)=5;
    df = length(x)-2;
    for(kk=1:length(p))
      fprintf('%s %s EV%d vs. %s:\tr=%0.3f\t(p=%0.8f, df=%d)\n',s{ns(kk)},segNames{jj},kk,bdColNames{ii},r(kk),p(kk),df);
      fprintf(logFile,'%s %s EV%d vs. %s:\tr=%0.3f\t(p=%0.8f, df=%d)\n',s{ns(kk)},segNames{jj},kk,bdColNames{ii},r(kk),p(kk),df);
    end
  end
end
fclose(logFile);

% Scatterplots for each pair of eigenvalues for each segment
evPair = [1 2; 1 3; 2 3];
for(jj=[2])
  ev = squeeze(mnEigVals(goodSubs,jj,3,:));
  [r,p] = corrcoef(ev);
  r = r([2,3,6]);
  p = p([2,3,6]);
  ns=ones(size(p));ns(p<.05)=2;ns(p<.01)=3;ns(p<.001)=4;ns(p<.0001)=5;
  df = size(ev,1)-2;
  for(kk=[1:3])
    fh = figure(figNum); clf; mrUtilResizeFigure(fh, 300, 275);
    x = mnEigVals(goodSubs,jj,3,evPair(kk,1));
    y = mnEigVals(goodSubs,jj,3,evPair(kk,2));
    pfit = polyfit(x, y, 1);
    lx = [min(x), max(x)];
    line(lx, pfit(1)*lx+pfit(2),'Color','k','LineWidth',1);
    hold on; h=plot(x, y, 'k.'); hold off;
    ax = [min([x',y']) max([x',y'])];
    axis([ax ax]);
    set(gca,'fontsize',12);
    set(get(gca,'XLabel'),'String',sprintf('\\lambda_%d Diffusivity %s',evPair(kk,1),diffusivityUnitStr),'fontsize',12);
    set(get(gca,'YLabel'),'String',sprintf('\\lambda_%d Diffusivity %s',evPair(kk,2),diffusivityUnitStr),'fontsize',12);
    mrUtilPrintFigure(fullfile(outDir,sprintf('ScatterEV_%s_EV%d_vs_EV%d.eps',segNames{jj},evPair(kk,1),evPair(kk,2))),fh);
    fprintf('%s EV%d vs EV%d:\tr=%0.3f\t(slope=%0.3f, p=%0.6f, df=%d)\n',...
	    segNames{jj},evPair(kk,1),evPair(kk,2),r(kk),pfit(1),p(kk),df);
    %fprintf(logFile,'%s EV%d vs EV%d:\tr=%0.2f\t(slope=%0.2f, p=%0.4f, df=%d)\n',...
    % segNames{jj},evPair(kk,1),evPair(kk,2),r(kk),pfit(1),p(kk),df);
  end
end

%% RADIAL DIFFUSIVITY SCATTERPLOTS
%
logFile = fopen(fullfile(outDir,'log.txt'),'at');
fprintf(logFile, '\n* * * Radial Diffusivity tests * * *\n');
fprintf('\n* * * Radial Diffusivity tests * * *\n');
%goodSubs = bd(:,2)==1;
%goodSubs(43) = 0;
for(ii=paInd)
  x = bd(goodSubs,ii);
  lx = [min(x), max(x)];
  for(jj=[1:7])
    ev = (squeeze(mnEigVals(goodSubs,jj,3,:)));
    y = (ev(:,2)+ev(:,3))./2;
    fh = figure(figNum); clf; mrUtilResizeFigure(fh, 300, 275);
    pfit = polyfit(x, y, 1);
    line(lx, pfit(1)*lx+pfit(2),'Color','k','LineWidth',1);
    hold on; h=plot(x, y, 'k.'); hold off;
    axis square;
    yRng = get(gca,'ylim');
    set(gca,'fontsize',12,'ytick',[yRng(1):0.1:yRng(2)]);
    set(get(gca,'YLabel'),'String',sprintf('Radial diffusivity %s',diffusivityUnitStr),'fontsize',12);
    set(get(gca,'XLabel'),'String', bdColNames{ii},'fontsize',12);
    mrUtilPrintFigure(fullfile(outDir,sprintf('ScatterEV_%s_EV2+EV3_vs_%s.eps',segNames{jj},strrep(bdColNames{ii},' ','_'))),fh);
    [p,r,df]=statTest(x,y,'r');
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    fprintf('%s %s Radial diffusivity vs. %s:\tr=%0.3f\tr^2=%0.2f\t(p=%0.8f, df=%d)\n',s,segNames{jj},bdColNames{ii},r,r.^2,p,df);
    fprintf(logFile,'%s %s Radial diffusivity vs. %s:\tr=%0.3f\tr^2=%0.2f\t(p=%0.8f, df=%d)\n',s,segNames{jj},bdColNames{ii},r,r.^2,p,df);
  end
end
fclose(logFile);

if(0)
ev = (squeeze(mnEigVals(goodSubs,2,3,:)));
y = (ev(:,2)+ev(:,3))./2;
pfit = polyfit(x, y, 1);
mnXDiff =  pfit(1)*lx+pfit(2);
pfit = polyfit(x, ev(:,1), 1);
pDiff = pfit(1)*lx+pfit(2);
figure;ellipsoid(0,0,0,mnXDiff(1),mnXDiff(1),pDiff(1),30);axis equal off; grid off; colormap gray;
mrUtilPrintFigure(fullfile(outDir,sprintf('ellipsoid_%03d_%03d.eps',round(mnXDiff(1)*1000),round(pDiff(1)*1000))));
figure;ellipsoid(0,0,0,mnXDiff(2),mnXDiff(2),pDiff(2),30);axis equal off; grid off; colormap gray;
mrUtilPrintFigure(fullfile(outDir,sprintf('ellipsoid_%03d_%03d.eps',round(mnXDiff(2)*1000),round(pDiff(2)*1000))));
end

%[b,bint,r,rint,stats] = regress(bd(goodSubs,ii),[ev(:,3),ones(size(ev(:,3)))]) 

disp(['Run: cd ' outDir '; pstoimg -antialias -aaliastext -density 300 -type png -crop a *.eps']);

%ti = 200:10:800;
%[xi,yi] = meshgrid(ti,ti);
%zi = griddata(ev(:,2),ev(:,3),bd(goodSubs,paInd),xi,yi,'cubic');
%figure;surf(xi,yi,zi), hold on, plot3(ev(:,2),ev(:,3),bd(goodSubs,paInd),'o'), hold off

%% Misc. tests 
%


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
