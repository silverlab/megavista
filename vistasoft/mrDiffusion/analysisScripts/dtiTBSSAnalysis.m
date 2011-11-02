
% TBSS doesn't keep track of the subject order, so we need to make
% sure that we get it right. We'll find all the subjects in the
% TBSS origdata dir and use that order. It should be the same as
% the data order in the skeletonized file.

clear all;

tbssDir = '/teal/scr1/dti/tbss/child_y1';
d = dir(fullfile(tbssDir,'origdata','*.nii.gz'));
N = length(d);
for(ii=1:N)
  subCode{ii} = d(ii).name(1:findstr(d(ii).name,'_')-1);
end
[behData, colNames] = dtiGetBehavioralData(subCode);
slAcpc = [-20:50];
clusterThresh = 5;
fdrThresh = 0.10;

mnFa = readFileNifti(fullfile(tbssDir,'stats','mean_FA.nii.gz'));
mnFa.data = double(mnFa.data)./10000;
xform = mnFa.qto_xyz;
sl = mrAnatXformCoords(inv(xform),[zeros(length(slAcpc),2) slAcpc']);
sl = unique(round(sl(:,3)));

oneThird = round(N./3);
testType = 't'; % t or r
structName = 'FA'; % FA, radialADC, axialADC
if(strcmpi(structName,'FA')) scale = 10000; else scale = 2000; end
statsFile = fullfile(tbssDir,[structName '_' testType '_stats.mat']);
if(exist(statsFile,'file'))
  load(statsFile);
else
  % Compute stats on structural data
  dataFile = ['all_' structName '_skeletonised.nii.gz'];
  disp(['Loading ' fullfile(tbssDir,'stats',dataFile) '...']);
  skel = readFileNifti(fullfile(tbssDir,'stats',dataFile));
  skel.data = double(skel.data)./scale;
  mn = mean(skel.data,4);
  mask = mn>0;
  for(ii=1:N)
    tmp = skel.data(:,:,:,ii);
    data(ii,:) = tmp(mask);
  end
  clear skel;
  % mn = mn(mask(:));
  % sd = std(data,0,2);
  % Z =(data-repmat(mn, [1 N])) ./ repmat(sd, [1 N]);
  
  %r = zeros(length(colNames),length(mn));
  clear r df p;
  for(ii=1:length(colNames))
    fprintf('Computing stats for %s vs. %s.\n',colNames{ii},structName);
    bd = behData(:,ii);
    if(testType=='r')
      [p(ii,:),s(ii,:),df(ii,:)] = myStatTest(bd,data,'k');
    else
      % divide into thirds based on percentile
      [bdSorted,inds] = sort(bd);
      inds(isnan(bdSorted)) = [];
      botThird = inds(1:oneThird);
      topThird = inds(end-oneThird+1:end);
      [h,p(ii,:),ci,stats] = ttest2(data(botThird,:), data(topThird,:),0.05,'both','unequal');
      df = stats.df;
      s = stats.tstat;
    end
    %   notNan = ~isnan(bd); 
    %   df = sum(notNan)-3;
    %   mn_beh = mean(bd(notNan));
    %   sd_beh = std(bd(notNan));
    %   beh_Z = (bd-mn_beh) ./ sd_beh;
    %   for(jj=find(notNan)')
    %     r(ii,:) = r(ii,:) + Z(:,jj)'.*beh_Z(jj);
    %   end
    %   r(ii,:) = r(ii,:)./numNotNan;
    %   fZ = 0.5*(log((1+r(ii,:))./(1-r(ii,:))));
    %   p = erfc((abs(fZ)*sqrt(df))/sqrt(2));
  end
  save(statsFile,'s','p','df','mask','data');
end

% Threshold probs
for(ii=1:length(colNames))
  fprintf('%s vs. %s.\n',colNames{ii},structName);
  pnorm(:,ii) = -log10(p(ii,:)');
  [nSig(ii),index_signif] = fdr(p(ii,:),fdrThresh,'original','mean');
  if(nSig(ii)>0)
    thresh(ii) = pnorm(index_signif(1),ii);
    fprintf('   FDR=%d: %d significant voxels\n',round(fdrThresh*100),nSig(ii));
  else
    thresh(ii) = NaN;
  end
  [nSig2x(ii)] = fdr(p(ii,:),fdrThresh*2,'original','mean');
  if(nSig2x(ii)>0)
    fprintf('   (FDR=%d would produce %d significant voxels)\n',round(fdrThresh*200),nSig2x(ii));
  else
    fprintf('   No significant voxels at FDR=%d\n',round(fdrThresh*200));
  end
end

% Try testing significance using a bootstrap, to avoid falling prey to the
% heavy influence of outliers.
% bootSamp = bootstrp(10000,@corr,gpa,lsat);
% mn = mean(bootSamp);
% se = std(bootSamp);
% p = normcdf(0,mn,se);
% Is this correct? We can also try deleting outliers (see outlier.m)
%
%img = zeros(numel(mask),1);
%img(find(mask(:))) = mn;
%img = reshape(img,size(mask));
%figure;imagesc(makeMontage(img,sl));axis image off;colormap gray;colorbar

fprintf('\nAnalyzing clusters (clusterThresh = %d, fdr = %0.2f)...\n',clusterThresh,fdrThresh);
cmap = autumn(64);
sigInds = find(~isnan(thresh)&nSig>=clusterThresh);
maskInds = find(mask(:));
for(ii=sigInds)
  statMap = pnorm(:,ii);
  statMap(statMap<thresh(ii)) = 0;
  img = zeros(numel(mask),1);
  % Scale statMap to use the full range of the color map.
  maxStatMap = max(statMap)+0.1;
  minStatMap = thresh(ii);
  statMap = statMap-minStatMap;
  statMap = statMap./(maxStatMap-minStatMap);
  statMap = statMap.*(size(cmap,1)-1)+1;
  statMap(statMap<1) = 0;
  img(maskInds) = round(statMap);
  img = reshape(img,size(mask));
  overlayMask = ~(img<1);
  % Apply cluster threshold
  overlayMask = bwareaopen(overlayMask, clusterThresh, 26);
  if(~any(overlayMask(:))) continue; end
  
  [clustLabel,clustN] = bwlabeln(overlayMask, 26);
  fprintf('%s vs. %s: %d clusters passed the size threshold of %d.\n',colNames{ii},structName,clustN,clusterThresh);
  figure;
  set(gcf,'Name',sprintf('%s vs. %s Scatter',structName,colNames{ii}));
  nRow = ceil(sqrt(clustN)); nCol = ceil(clustN./nRow);
  for(jj=1:clustN)
    % Get the original data for each cluster and summarize it.
    curClust = clustLabel==jj;
    nvox = sum(curClust(:));
    clustInds = find(curClust(:));
    [inMask,maskLoc] = ismember(clustInds,maskInds);
    [x,y,z] = ind2sub(size(mask),clustInds);
    mniCoords = mrAnatXformCoords(xform, [x,y,z]);
    mnMni = mean(mniCoords);
    fprintf('   Cluster %d: size = %d voxels; max p = 10^-%0.1f; mean MNI: [%d %d %d]\n',...
	    jj, nvox, max(pnorm(maskLoc,ii)), round(mnMni));
    % Plot the mean data within the cluster vs. behavior
    mnDataVal = mean(data(:,maskLoc),2);
    bd = behData(:,ii);
    notNan = ~isnan(bd);
    [curP,curR,curDf] = myStatTest(mnDataVal(notNan),bd(notNan),'r');
    [curKP,curKR] = myStatTest(mnDataVal(notNan),bd(notNan),'k');
    subplot(nRow,nCol,jj,'align');
    plot(mnDataVal(notNan),bd(notNan),'ko');
    title(sprintf('[%d %d %d]: r=%0.2f, tau=%0.2f (p=%0.0e), n=%d',round(mnMni),curR,curKR,curKP,nvox));
    xlabel(structName);
    ylabel(colNames{ii});
  end
  
  clustZ = find(squeeze(sum(sum(overlayMask,1),2)));
  clustAcpc = mrAnatXformCoords(xform,[zeros(length(clustZ),2) clustZ]);
  R = uint8(round(mnFa.data*255)); G = R; B = R;
  B(mask) = 255; R(mask) = R(mask)./2;
  R(overlayMask) = uint8(round(cmap(img(overlayMask),1)*255));
  G(overlayMask) = uint8(round(cmap(img(overlayMask),2)*255));
  B(overlayMask) = uint8(round(cmap(img(overlayMask),3)*255));
  upsamp = 0;
  warning('off');
  %im = makeMontage3(R, G, B, sl, 1, upsamp);
  makeMontage3(R, G, B, clustZ, 1, upsamp, clustAcpc(:,3));
  warning('on');
  set(gcf,'Name',[structName ' vs. ' colNames{ii}]);
  %cbar = linspace(0,max(-log10(p(:))),10);
  %figure; imagesc(cbar, [0], cbar); colormap(cmap); axis equal tight;
end

% To save a nifti file:
if(0)
ni = mnFa;
ni.data = pnorm(:,ii);
ni.descrip = sprintf('-log10(p) for correlation between %s and %s (n=%d)',dataFile,colNames{ii},N);
ni.filename = fullfile(baseDir, 'outFile.nii.gz');
writeFileNifti(ni);
end
