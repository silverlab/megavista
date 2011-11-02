%function [] = dtiAnalyzeFA(subjectDir,fileFragment,fileOut)
% [] = dtiAnalyzeFA(subjectDir,fileFragment,filename)
% Voxel-based morphometric measures of group data
%
% Produces correlation maps of FA in normalized brains (i.e. warped to a
% template brain) and basic reading score. 

% Input: 
% subjectDir, fileFragment: file location of brains (for findSubjects)
% fileFragment: string present in every image filename (for findSubjects)
% fileOut: Filename for output stat file of r values and Fisher's z values

subjectDir = '/biac2/wandell2/data/reading_longitude/templates/child_new/SIRL54warp3';
fileFragment = '*sn*';

try
  load(fullfile(subjectDir,'allFa'));
  N = length(subCode);
catch
  [s,subCode] = findSubjects(subjectDir,fileFragment,{'tk040817'});
  N = length(s);
  
  disp(['Processing ' s{1} '...']);
  dt = load(s{1},'dt6','b0');
  sz = size(dt.b0);
  fa = zeros([sz N]);
  md = fa; cl = fa; cp = fa; cs = fa;
  [eigVec,eigVal] = dtiEig(dt.dt6);
  [fa(:,:,:,1),md(:,:,:,1)] = dtiComputeFA(eigVal);
  [cl(:,:,:,1), cp(:,:,:,1), cs(:,:,:,1)] = dtiComputeWestinShapes(eigVal);
  b0mean = double(dt.b0);
  for (ii=2:N)
    disp(['Processing ' s{ii} '...']);
    dt = load(s{ii},'dt6','b0','xformToAcPc');
    [eigVec,eigVal] = dtiEig(dt.dt6);
    [fa(:,:,:,ii),md(:,:,:,ii)] = dtiComputeFA(eigVal);
    [cl(:,:,:,ii), cp(:,:,:,ii), cs(:,:,:,ii)] = dtiComputeWestinShapes(eigVal);
    b0mean = b0mean+double(dt.b0);
  end
  b0mean = b0mean./N;

  %Clear out NANs
  fa(isnan(fa(:))) = 0;
  md(isnan(md(:))) = 0;
  cl(isnan(cl(:))) = 0;
  cp(isnan(cp(:))) = 0;
  cs(isnan(cs(:))) = 0;
  
  save(fullfile(subjectDir,'allFa'), 'subCode', 'fa', 'md', 'cl', 'cp', 'cs', 'b0mean');
end

[behData,colNames] = dtiGetBehavioralData(subCode);

%smooth_fa = fa;
%for (ii=1:N)
%  disp(['Smoothing ' s{ii} '...']);
%  smooth_fa(:,:,:,ii) = dtiSmooth3(fa(:,:,:,ii), 3);
%end
%orig_fa = fa;
%fa = smooth_fa;

if(0)
  % Remove bad FA values and replace them with their cross-subject
  % mean
  mn_fa = mean(fa, 4);
  % NOTE: it would be better to replace the bad vals with the mean of
  % the non-bad vals, but I couldn't figure out how to do that
  % without an ugly loop.
  badVals = find(fa>=1);
  [bvY,bvX,bvZ,bvS] = ind2sub(sz, badVals);
  faOrig = fa;
  for(ii=1:length(bvS))
    fa(bvY(ii), bvX(ii), bvZ(ii), bvS(ii)) = mn_fa(bvY(ii), bvX(ii), bvZ(ii));
  end
end

beh = behData(:,8);
mn_beh = mean(beh);
sd_beh = std(beh);
beh_Z = (beh-mn_beh) ./ sd_beh;

valNames = {'fa','md','cl','cp','cs'};
for(ii=1:length(valNames))
  eval(['mn=mean(' valNames{ii} ',4);']);
  eval(['sd=std(' valNames{ii} ',0,4);']);
  eval(['Z =(' valNames{ii} '-repmat(mn, [1 1 1 N])) ./ repmat(sd, [1 1 1 N]);']);
  %Compute correlations
  r = 0;
  for(jj=1:N)
    r = r + Z(:,:,:,jj).*beh_Z(jj);
  end
  r = r./N;

  % Alternate p-val calc
  %tstat = repmat(Inf,size(r));
  %tstat(r<0) = -Inf;
  %denom = (1 - r.^2);
  %nz = denom>0;
  %tstat(nz) = r(nz).*sqrt((N-3)./denom(nz));
  %p = 1-tcdf(tstat, N-3);
  
  % compute Fischer's z'
  fZ = 0.5*(log((1+r)./(1-r)));
  df = N-3;
  p = erfc((abs(fZ)*sqrt(df))/sqrt(2));
  %Threshold probs
  eval([valNames{ii} '_pnorm = -log10(p);']);

  [n_signif,index_signif] = fdr(p(:),0.1,'original','mean');
  % Convert back to an fThreshold
  %tThreshFDR = tinv(1-max(pvals(index_signif)), df(1));
end
clear mn sd Z p fZ r; 

% *** WORK HERE

%imR = makeMontage(imrotate(r,90),[20:49]);figure; imagesc(imR); axis image; colorbar;
%imP = makeMontage(imrotate(p,90),[20:49]);figure; imagesc(imP); axis image; colorbar;

%Threshold probs
p_norm = p_norm./max(p_norm(:));
p_norm = round(p_norm*255+1);
cmap = hsv(256);
mn_fa = mn_fa/max(mn_fa(:));
R = mn_fa; G = mn_fa; B = mn_fa;
mask_P = p<0.01 & mn_fa>0.10;
R(mask_P) = cmap(p_norm(mask_P),1);
G(mask_P) = cmap(p_norm(mask_P),2);
B(mask_P) = cmap(p_norm(mask_P),3);
upsamp = 0;
im = makeMontage3(R,G,B,[20:60], 2, upsamp);
%figure; image(im); axis image; title('FA Thresholded Probabilities')
cbar = linspace(0,max(-log10(p(:))),10);
figure; imagesc(cbar, [0], cbar); colormap(cmap); axis equal tight;


%Saving out file
stat{1} = r; stat{2} = z; stat{3} = p;
statName{1} = 'r'; statName{2} = 'z'; statName{3} = 'p';
atlas = templateFilename;
notes = 'FA correlated with basic reading';
if ~exist('fileOut','var')
    fileOut = fullfile(subjectDir,'statMapFA')
end
save(fileOut,'stat','statName','atlas','notes');
disp(['Stats saved to ',str2mat(fileOut)]);

return 


% Get ac-pc coords for a selected point on a montage of axial
% images (eyes pointing right)
[brSort,brSortInd] = sort(basicRead);
upsamp = 1;
imPerRow = 7;
firstIm = 20;
sp = ginput(1);
sp = sp./upsamp;
sz=size(fa);
y = mod(sp(1),sz(2));
x = mod(sp(2),sz(1));
z = floor(sp(2)/sz(1))*imPerRow+floor(sp(1)/sz(2))+firstIm;
acpc = mrAnatXformCoords(dt.xformToAcPc, [x y z]);
fprintf(['motage coords = [%0.1f %0.1f]; Image coords = [%0.1f %0.1f ' ...
'%0.1f]; AcPc coords = [%0.1f %0.1f %0.1f]\n'], sp, x, y, z, acpc);
x=round(x); y=round(y); z=round(z);
faR = squeeze(fa(:,:,z,:));
faG = faR; faB = faR;
faR(x,y,:) = 1;
m = makeMontage3(faR,faG,faB,brSortInd,2,1,cellstr(num2str(brSort)));
figure;scatter(basicRead, fa(x,y,z,:));
