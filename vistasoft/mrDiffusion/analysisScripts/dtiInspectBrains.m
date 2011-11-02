subDir = '/biac2/wandell2/data/reading_longitude/dti/';
[subFiles,subCodes] = findSubjects([subDir '*'], '_dt6', {'es041113','tk040817'});
[behData,colNames] = dtiGetBehavioralData(subCodes);
addpath('/home/bob/matlab/stats');
leftHanders = [5,30,38,52]; % am, md, pf, vt

groupDir = '/biac2/wandell2/data/reading_longitude/dtiGroupAnalysis';
N = length(subFiles);

fname = fullfile(groupDir,'t1All.mat');
%load(fname);
if(~exist('t1','var')|isempty(t1))
    f = subFiles{1}; sc = subCodes{1};
    dt = load(f,'anat');
    t1 = zeros([size(dt.anat.img),N],class(dt.anat.img));
    brainMask = zeros([size(dt.anat.img),N],'uint8');
    t1(:,:,:,1) = dt.anat.img;
    brainMask(:,:,:,1) = dt.anat.brainMask;
    for(ii=2:N)
        f = subFiles{ii}; sc = subCodes{ii};
        dt = load(f,'anat');
        t1(:,:,:,ii) = dt.anat.img;
        brainMask(:,:,:,ii) = dt.anat.brainMask;
    end
    xformToAcPc = dt.anat.xformToAcPc;
    mmPerVox = dt.anat.mmPerVox;
    save(fname, 'subFiles','subCodes','mmPerVox','xformToAcPc','t1','brainMask');
end

ac = mrAnatXformCoords(inv(xformToAcPc),[0 0 0]);
anatSlice = squeeze(t1(round(ac(1)),:,:,:));
anatSlice = flipdim(permute(anatSlice,[2 1 3]),1);

% paScore = zeros(1,N);
% paScore(behData(:,6)<=90) = -1;
% paScore(behData(:,6)>=110) = 1;

bn = 3;
pa = behData(:,bn); % 3= basic reading, 6=pa, 1=sex
pa(isnan(pa)) = mean(pa(~isnan(pa)));
[pa,paSort] = sort(pa);
sz = [50 100];
anat = zeros([sz,N]);
xo = 62; yo = 52;
[X,Y] = meshgrid([xo:xo+sz(2)-1],[yo:yo+sz(1)-1]);
ind = sub2ind(size(anatSlice(:,:,1)), Y, X);
for(ii=1:N)
  tmp = anatSlice(:,:,paSort(ii));
  anat(:,:,ii) = tmp(ind);
  label{ii} = num2str(pa(ii));
end
anat = uint8(anat./max(anat(:))*255+0.5);
makeMontage3(anat,anat,anat,[],1,1,label);
set(gcf,'Name',colNames{bn});
%figure; image(makeMontage(anat));
axis equal tight off; colormap(gray(256));

