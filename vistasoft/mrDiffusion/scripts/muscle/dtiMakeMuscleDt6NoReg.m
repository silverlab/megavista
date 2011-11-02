function [t1,b0] = dtiMakeMuscleDt6NoReg(b0FileName, t1PathName, outPathName, tensorFileName, applyB0BrainMask, showFigs, swapTensorXY)
%
% [t1,b0] = dtiMakeMuscleDt6(b0PathName, t1PathName, outPathName, [applyB0BrainMask=1], [showFigs=1], [swapTensorXY=0])
%
% Takes a set of images from a DTI sequence and saves them out as in a dt6
% matlab file.   The original version of this file is dtiMakeDt6.  This
% version was created in order to work with the muscle images as part of
% the simbios project.  The muscle images differ mostly because of the lack
% of an ACPC, Talairach space or average space.  Therefore, we arbitrarily
% choose to co-register images based on the DTI image's center point.
%
% HOW DO WE KNOW WHEN WE NEED TO ENABLE SWAPTENSORXY??

if(~exist('applyB0BrainMask','var') | isempty(applyB0BrainMask))
    applyB0BrainMask = 0;
end
if(~exist('showFigs','var') | isempty(showFigs))
    showFigs = 1;
end
if(~exist('swapTensorXY','var') | isempty(swapTensorXY))
    swapTensorXY = 0;
end

computeMNI = false;

slice = [0,0,0]; % slice to display for checking coregistration
%bb = [-72 -110 -45; 72 85 85];
bb = [-80,80; -120,90; -200,200]';
mmDt = [1.5625 1.5625 3];
mmAnat = [0.78125 0.78125 3];

if ~exist('b0FileName','var') | isempty(b0FileName)
    [f, p] = uigetfile({'*.nii.gz','NIFTI gz';'*.*','All files'}, 'Select the B0 file...');
    if(isnumeric(f)) error('Need an B0 file to continue...'); end
    b0FileName = fullfile(p, f);
    disp(b0FileName);
end
ni = readFileNifti(b0FileName);
%% HACK for just putting already registered b0 in file
b0.img = ni.data;
%b0.mmPerVox = ni.pixdim;
b0.mmPerVox = mmDt;
clear ni;
b0.baseFname = b0FileName;

% Flip the B0 into the right coordinates
b0.cannonical = diag([-1 -1 -1 1]);
% tmp = b0.cannonical(1,:);
% b0.cannonical(1,:) = b0.cannonical(2,:);
% b0.cannonical(2,:) = tmp;
b0.cannonical(1:2,4) = 128;
[b0.cannonical_img, b0.cannonical_mmPerVox] = applyCannonicalXform(b0.img, b0.cannonical, b0.mmPerVox);
b0.imDim = size(b0.cannonical_img);
b0.anatXform = [diag(b0.mmPerVox), -[size(b0.cannonical_img)./2.*b0.mmPerVox]'; [0 0 0 1]];
b0.acpcXform = b0.anatXform;

if ~exist('t1PathName','var') | isempty(t1PathName)
   [f, p] = uigetfile({'*.nii*','NIFTI (*.nii)';'*.hdr','Analyze (*.hdr)';'*.*','All files'},...
       'Select the T1 volume file...');
   if(isnumeric(f)) error('Need a T1 file to continue...'); end
   t1PathName = fullfile(p, f);
   disp(t1PathName);
end
if(~exist(t1PathName,'file'))
    
end
t1.analyzeFname = t1PathName;
[p,f,e] = fileparts(t1PathName);
t1Type = e;
t1.analyzeBaseFname = fullfile(p,f);

fullpath = fileparts(b0.baseFname);
if(isempty(fullpath)) fullpath = pwd; end
[junk,dirname] = fileparts(fullpath);

if(~exist('outPathName','var') | isempty(outPathName))
    outPathName = fullfile(fullpath, [dirname '_dt6']);
end

if(exist(outPathName,'file') | exist([outPathName '.mat'],'file'))
  disp('output file exists- please rename...');
  [f,p] = uiputfile('*.mat', 'Select output file...', outPathName);
  if(isnumeric(f)) error('User cancelled.'); end
  outPathName = fullfile(p,f);
end
disp(['Data will be saved in ' outPathName '...']);

swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
spm_defaults;
defaults.analyze.flip = 0;

if(strcmpi(t1Type,'.nii')|strcmpi(t1Type,'.gz'))
    ni = readFileNifti(t1.analyzeFname);
    t1.cannonical_img = ni.data;
    t1.cannonical_mmPerVox = ni.pixdim;
    t1.cannonical_mmPerVox(3) = mmAnat(3);
    %t1.acpcXform = ni.qto_xyz;
    % HACK for cannonical transorm
    t1.anatXform = [diag(t1.cannonical_mmPerVox), -[size(t1.cannonical_img)./2.*t1.cannonical_mmPerVox]'; [0 0 0 1]];
    % Have to still hack this manually sometimes
    if(1)%ni.qto_xyz(1,1) < 0)
        t1.anatXform(1,1)=-t1.anatXform(1,1);
        t1.anatXform(1,4)=-t1.anatXform(1,4);
    end
    if(ni.qto_xyz(2,2) < 0)
        t1.anatXform(2,2)=-t1.anatXform(2,2);
        t1.anatXform(2,4)=-t1.anatXform(2,4);
    end
    t1.acpcXform = t1.anatXform;
    clear ni;
else
    disp('Only NIFTI format t1.');
end


if(showFigs>0)
    h = figure;
    showFigure(h, t1, b0, bb, [0,0,0], dirname);
    %set(h,'Position', [10, 50, 1000, 1000]);
    set(h, 'PaperPositionMode', 'auto');
    print(h, '-dpng', '-r90', [outPathName,'_headerAlign.png']);
    if(showFigs==0) close(h); end
end

disp('Coregistering (using spm2 tools)...');
img = double(t1.cannonical_img);

img = mrAnatHistogramClip(img, 0.50, 0.995);
VG.uint8 = uint8(round(img*255));
VG.mat = t1.acpcXform;

img = double(b0.cannonical_img);

%img = mrAnatHistogramClipOptimal(img);
img = mrAnatHistogramClip(img,0.40, 0.99);
VF.uint8 = uint8(round(img*255));
VF.mat = b0.acpcXform;
p = defaults.coreg.estimate;
% NOTE: there seems to be a consistent 1mm (1/2 of B0 voxel) translation
% between the t1 and B0.
transRot = spm_coreg(VG,VF,p);
transRot(1:3) = transRot(1:3)+mmDt/2;
b0.acpcXform = inv(VF.mat\spm_matrix(transRot(:)'));

if(showFigs>0)
    h = figure;
    showFigure(h, t1, b0, bb, [0,0,0], [dirname '- auto aligned (whole brain)']);
    set(h, 'PaperPositionMode', 'auto');
    print(h, '-dpng', '-r90', [outPathName,'_autoAlign.png']);
    if(showFigs==0) close(h); end
end

% Assume we have tensors in Nifti
%dt6_tmp = dtiLoadTensorElements(fullfile(fileparts(b0.baseFname), 'TensorElements.float.'));
if ieNotDefined('tensorsFileName')
    [f, p] = uigetfile({'*.nii.gz','NIFTI gz';'*.*','All files'}, 'Select the tensors file...');
    if(isnumeric(f)) error('Need a tensors file to continue...'); end
    tensorsFileName = fullfile(p, f);
    disp(tensorsFileName);
end
ni = readFileNifti(tensorsFileName);
%% HACK for just putting already registered b0 in file
dt6_tmp = ni.data;

for(ii=1:6)
    dt6(:,:,:,ii) = applyCannonicalXform(dt6_tmp(:,:,:,ii), b0.cannonical, b0.mmPerVox);
end

clear dt6_tmp;

% Reslice everything
disp('Interpolating tensors...');
% Sometimes we need to sway the x and y tensor components. Tensorcalc
% (Roland's code) flips them when the freqdir is LR instead of the usual AP.
if(swapTensorXY)
    dt6 = dt6(:,:,:,[2 1 3 4 6 5]);
    %dt6(:,:,:,2) = -dt6(:,:,:,2);
    %dt6(:,:,:,4) = -dt6(:,:,:,4);
end
%dt6 = permute(dt6, [2 1 3 4]);
dt6 = mrAnatResliceSpm(dt6, inv(b0.acpcXform), bb, mmDt, [1 1 1 0 0 0], showFigs);
dt6(isnan(dt6)) = 0;
% NOTE: we want to apply b0.acpcXform to the tensors, even though we
% resliced them with inv(b0.acpcXform). inv(b0.acpcXform) maps from
% the new space to the old- the correct mapping for the interpolation,
% since we interpolate by creating a grid in the new space and fill it by
% pulling data from the old space. But the tensor reorientation should be
% done using the old-to-new space mapping (b0.acpcXform).

rigidXform = dtiFiniteStrainDecompose(b0.acpcXform);
[t,r] = affineDecompose([rigidXform,[0 0 0]';[0 0 0 1]]);
fprintf('Applying PPD rotation [%0.4f %0.4f %0.4f]...\n',r);
dt6 = dtiXformTensors(dt6, rigidXform);
%figure; imagesc(makeMontage(dt6_new(:,:,:,1))); axis equal; colormap gray

disp('Interpolating B0...');
b0_img = mrAnatResliceSpm(b0.cannonical_img, inv(b0.acpcXform), bb, mmDt, [7 7 7 0 0 0], showFigs);
b0_img(b0_img<0) = 0;
b0_img(isnan(b0_img)) = 0;


%% Can't use other masking for muscle, let's just allow the user to specify
%% the clipping threshold manually
figure;hist(b0_img(:),100);
[thresh,junk] = ginput(1);
dtBrainMask = b0_img > thresh;

dtBrainMask = dtiCleanImageMask(dtBrainMask, 9);
if(applyB0BrainMask)
    dt6(repmat(~dtBrainMask, [1,1,1,6])) = 0;
end

[t,r,s,k] = affineDecompose(inv(t1.acpcXform));
imSz = size(t1.cannonical_img);
bbSz = ceil((diff(bb)+1)./mmAnat);

if(any(abs(r)>0.001) | any(abs(k)>0.001) | any(abs(s-mmAnat)>0.01) | any(imSz~=bbSz))
    disp('Interpolating T1...');
    [anat.img,t1.acpcXform] = mrAnatResliceSpm(t1.cannonical_img, inv(t1.acpcXform), bb, mmAnat, [], showFigs);
    anat.img(anat.img<0) = 0;
    anat.img(isnan(anat.img)) = 0;
    anat.img = int16(round(anat.img));
else
    disp('T1 already in ac-pc space- no need to interpolate.');
    anat.img = t1.cannonical_img;
    if(~isinteger(anat.img))
        anat.img(anat.img<0) = 0;
        anat.img(isnan(anat.img)) = 0;
        anat.img = int16(round(anat.img));
    end
end

mmPerVox = mmDt;
notes = '';
dti.mmPerVox = b0.mmPerVox;
dti.cannonical = b0.cannonical;
dti.acpcXform = b0.acpcXform;
b0 = int16(round(b0_img));
anat.mmPerVox = mmAnat;


origin = bb(1,[1,2,3])-mmDt./2;
xformToAcPc = [diag(mmDt) origin'; [0 0 0 1]]; %swapXY*[diag(mm) origin'; [0 0 0 1]];
anat.xformToAcPc = t1.acpcXform;

disp(['Saving to ' outPathName '...']);
l = license('inuse'); h = hostid;
created = ['Created at ' datestr(now,31) ' by ' l(1).user ' on ' h{1} '.'];

% Bogus value that wasn't created
t1NormParams = 'not created for muscle';
notes = 'NA';
scanInfo = 'NA';

save(outPathName, 'dt6', 'mmPerVox', 'notes', 'xformToAcPc', 'b0', 'dtBrainMask', 'anat', 'dti', 'scanInfo', 't1NormParams', 'created');
%save([outPathName '_anon'], 'dt6', 'mmPerVox', 'xformToAcPc', 'b0');
return;

function showFigure(fig, t1, b0, bb, slice, figName)
% Get X,Y and Z (L-R, A-P, S-I) slices from T1 and b0 volumes
[t1Xsl] = dtiGetSlice(t1.acpcXform,t1.cannonical_img,3,slice(3),bb);
[t1Ysl] = dtiGetSlice(t1.acpcXform,t1.cannonical_img,2,slice(2),bb);
[t1Zsl] = dtiGetSlice(t1.acpcXform,t1.cannonical_img,1,slice(1),bb);
[b0Xsl] = dtiGetSlice(b0.acpcXform,b0.cannonical_img,3,slice(3),bb);
[b0Ysl] = dtiGetSlice(b0.acpcXform,b0.cannonical_img,2,slice(2),bb);
[b0Zsl] = dtiGetSlice(b0.acpcXform,b0.cannonical_img,1,slice(1),bb);
% Max values for image scaling
t1mv = max([t1Xsl(:); t1Ysl(:); t1Zsl(:)]);
b0mv = max([b0Xsl(:); b0Ysl(:); b0Zsl(:)]);
% Create XxYx3 RGB images for each of the axis slices. The green and 
% blue channels are from the T1, the red channel is an average of T1 
% and b=0.
Xsl(:,:,1) = t1Xsl./t1mv.*.5 + b0Xsl./b0mv.*.5;
Xsl(:,:,2) = t1Xsl./t1mv.*.5; Xsl(:,:,3) = t1Xsl./t1mv.*.5;
Ysl(:,:,1) = t1Ysl./t1mv.*.5 + b0Ysl./b0mv.*.5;
Ysl(:,:,2) = t1Ysl./t1mv.*.5; Ysl(:,:,3) = t1Ysl./t1mv.*.5;
Zsl(:,:,1) = t1Zsl./t1mv.*.5 + b0Zsl./b0mv.*.5;
Zsl(:,:,2) = t1Zsl./t1mv.*.5; Zsl(:,:,3) = t1Zsl./t1mv.*.5;

% Show T1 slices
figure(fig); set(fig, 'NumberTitle', 'off', 'Name', figName);
figure(fig); subplot(3,3,1); imagesc(bb(:,1), bb(:,2), t1Xsl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,2); imagesc(bb(:,3), bb(:,1), t1Ysl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,3); imagesc(bb(:,3), bb(:,2), t1Zsl); 
colormap(gray); axis equal tight xy; 
truesize;

% Show b=0 slices
figure(fig); subplot(3,3,4); imagesc(bb(:,1), bb(:,2), b0Xsl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,5); imagesc(bb(:,3), bb(:,1), b0Ysl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,6); imagesc(bb(:,3), bb(:,2), b0Zsl); 
colormap(gray); axis equal tight xy; 
truesize;

% Show combined slices
figure(fig); subplot(3,3,7); imagesc(bb(:,1), bb(:,2), Xsl); 
axis equal tight xy;
figure(fig); subplot(3,3,8); imagesc(bb(:,3), bb(:,1), Ysl); 
axis equal tight xy;
figure(fig); subplot(3,3,9); imagesc(bb(:,3), bb(:,2), Zsl); 
axis equal tight xy; 
truesize;

return;
