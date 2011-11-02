function [t1,b0] = dtiMakeMuscleDt6(b0PathName, t1PathName, outPathName, applyB0BrainMask, showFigs, swapTensorXY)
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
mmAnat = [0.625 0.625 3];

if ~exist('b0PathName','var') | isempty(b0PathName)
   [f, p] = uigetfile({'B0_001*','B0 files';'*.*','All files'}, 'Select one of the B0 I-files...');
   if(isnumeric(f)) error('Need a B0 file to continue...'); end
   b0PathName = fullfile(p, f);
   disp(b0PathName);
end
b0.fname = b0PathName;

if ~exist('t1PathName','var') | isempty(t1PathName)
   [f, p] = uigetfile({'*.hdr','Analyze (*.hdr)';'*.nii*','NIFTI (*.nii)';'*.*','All files'},...
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

% Compute the transform that would happen if we made this into an analyze
% format file using our code, which imposes a particular data orientation
% (axial, neurological convention). Note that the transform returned here
% should consits of just flips and mirror-reversals. There will be no
% scales, skews or translations.
[b0.cannonical, b0.baseFname, b0.mmPerVox, b0.imDim, b0.notes] = computeCannonicalXformFromIfile(b0.fname);
% % HACK for no cannonical transform
% b0.cannonical = diag([1 1 1 1]);
b0.baseFname = b0.fname;

[su_hdr,ex_hdr,se_hdr,im_hdr] = readImageHeader(b0.fname);
scanInfo.examNumber = ex_hdr.ex_no;
scanInfo.examTimestamp = ex_hdr.ex_datetime;
scanInfo.subjectName = char(ex_hdr.patname');
scanInfo.psd = char(im_hdr.psd_iname');
scanInfo.fov = im_hdr.dfov;
scanInfo.matrixSize = [im_hdr.imatrix_X, im_hdr.imatrix_Y];
scanInfo.volSize = [im_hdr.dim_X, im_hdr.dim_Y, im_hdr.slquant];
scanInfo.mmPerVox = [im_hdr.pixsize_X, im_hdr.pixsize_Y, im_hdr.slthick+im_hdr.scanspacing];
scanInfo.tr = im_hdr.tr/1000;
scanInfo.ti = im_hdr.ti/1000;
scanInfo.te = im_hdr.te/1000;
scanInfo.nEchos = im_hdr.numecho;
scanInfo.flip = im_hdr.mr_flip;
scanInfo.nex = im_hdr.nex;
scanInfo.sarAvg = im_hdr.saravg;
scanInfo.sarAvg = im_hdr.sarpeak;
disp(scanInfo);

fullpath = fileparts(fileparts(b0.baseFname));
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
    [t1.cannonical_img, t1.cannonical_mmPerVox, t1.cannonical_hdr] = loadAnalyze(t1.analyzeFname);
    try,
        % sometimes (in my case) the _talairach file was not done or
        t1.talairach = load([t1.analyzeBaseFname '_talairach']);
        % We also want a transform that will go into ac-pc space (ie.
        % Talairach, but without any scaling). We can compute that by
        % adjusting the scale factors in the talairach transform.
        t1.talXform = t1.talairach.vol2Tal.transRot'*swapXY;
        [trans,rot,scale,skew] = affineDecompose(t1.talXform);
        % We also have to rescale the translations.
        scaleDiff = t1.cannonical_mmPerVox./scale;
        trans = trans.*scaleDiff;
        scale = t1.cannonical_mmPerVox;
        t1.acpcXform = affineBuild(trans,rot,scale,skew);
    catch,
        t1.acpcXform = t1.cannonical_hdr.mat;
        %t1.acpcXform = [diag(t1.cannonical_mmPerVox), -[size(t1.cannonical_img)./2.*t1.cannonical_mmPerVox]'; [0 0 0 1]];;
    end;
end

% Build B0
b0.img = makeCubeIfiles(b0.baseFname, b0.imDim(1:2));
[b0.cannonical_img, b0.cannonical_mmPerVox] = applyCannonicalXform(b0.img, b0.cannonical, b0.mmPerVox);

% Auto-align works pretty well, so we just need to get this remotely close.
% Since our cannonical xform orients things roughly axial with left-is-left
% and with superior at the top, the following inital guess works well.
% However, if the slice prescription were substantially different from what
% we typically do (which is roughly ac-pc algined), then we'd probably have
% to do a bit more work to get a good initial estimate.
% Note that the initial guess 

b0.anatXform = [diag(b0.cannonical_mmPerVox), -[size(b0.cannonical_img)./2.*b0.cannonical_mmPerVox]'; [0 0 0 1]];
b0.acpcXform = b0.anatXform;
% b0.acpcXform(2,4) = b0.acpcXform(2,4)-10;
% b0.acpcXform(3,4) = b0.acpcXform(3,4)+10;

if(showFigs>0)
    h = figure;
    showFigure(h, t1, b0, bb, [0,0,0], dirname);
    %set(h,'Position', [10, 50, 1000, 1000]);
    set(h, 'PaperPositionMode', 'auto');
    print(h, '-dpng', '-r90', [outPathName,'_headerAlign.png']);
    if(showFigs==0) close(h); end
end

bDoFullCoreg = true;

disp('Coregistering (using spm2 tools)...');
%figure(999); hist(t1.cannonical_img(:),255); [clip,y] =
%ginput(2);
 img = double(t1.cannonical_img);

if (~bDoFullCoreg)
    img = img(:,:,round(size(img,3)/2));
    img = repmat(img, [1 1 3]);
end

%img = mrAnatHistogramClipOptimal(img);
img = mrAnatHistogramClip(img, 0.50, 0.995);
VG.uint8 = uint8(round(img*255));
VG.mat = t1.acpcXform;
%figure(999); hist(b0.cannonical_img(:),255); [x,y] = ginput(2);

img = b0.cannonical_img;

if (~bDoFullCoreg)
    img = img(:,:,round(size(img,3)/2));
    img = repmat(img, [1 1 3]);
end

%img = mrAnatHistogramClipOptimal(img);
img = mrAnatHistogramClip(img,0.40, 0.99);
VF.uint8 = uint8(round(img*255));
VF.mat = b0.acpcXform;
p = defaults.coreg.estimate;
%p.params = [0 0 0, 0 0 0];
%p.tol(1:6) = [0.04 0.04 0.04 0.002 0.002 0.002];
% NOTE: there seems to be a consistent 1mm (1/2 of B0 voxel) translation
% between the t1 and B0.
transRot = spm_coreg(VG,VF,p);
transRot(1:3) = transRot(1:3)+mmDt/2;
b0.acpcXform = inv(VF.mat\spm_matrix(transRot(:)'));
% % Now align again, this time allowing scale and skew to be free parameters.
% % We really want to fix everything except the second (A-P) scale and the first
% % skew (about A-P axis).
% p.params = [rotTrans 1 1 1 0 0 0];
% p.tol = [0.02 0.02 0.02, 0.001 0.001 0.001, 0.01 0.01 0.01, 0.001 0.001 0.001];
% rotTrans2 = spm_coreg(VG,VF,p);
% b0.acpcXform = inv(VF.mat\spm_matrix(rotTrans2(:)'));
% Sorry Nestares & Heeger- spm_coreg (from spm2) kicks estMotion3's butt.
%M = estMotion3(b0_img, t1_img, 3, M, 1, 1);

if(showFigs>0)
    h = figure;
    showFigure(h, t1, b0, bb, [0,0,0], [dirname '- auto aligned (whole brain)']);
    set(h, 'PaperPositionMode', 'auto');
    print(h, '-dpng', '-r90', [outPathName,'_autoAlign.png']);
    if(showFigs==0) close(h); end
end


% Now build and save the dt6 data
%[eigVec, eigVal] = dtiLoadTensor(fullfile(fileparts(b0.baseFname), 'Vectors.float.'));
%dt6_tmp = dtiRebuildTensor(eigVec, eigVal);
dt6_tmp = dtiLoadTensorElements(fullfile(fileparts(b0.baseFname), 'TensorElements.float.'));
%dt6_tmp = permute(dt6_tmp,[2 1 3 4]);
 
for(ii=1:6)
    dt6(:,:,:,ii) = applyCannonicalXform(dt6_tmp(:,:,:,ii), b0.cannonical, b0.mmPerVox);
end

%dt6 = permute(dt6,[2 1 3 4]);
clear dt6_tmp;

% Reslice everything
disp('Interpolating tensors...');
%dt6A = dtiResliceTensorAffine(dt6, inv(b0.acpcXform), b0.cannonical_mmPerVox, bb, mmDt);
%dt6A = permute(dt6A,[2 1 3 4]);
% Sometimes we need to sway the x and y tensor components. Tensorcalc
% (Roland's code) flips them when the freqdir is LR instead of the usual AP.
if(swapTensorXY)
    dt6 = dt6(:,:,:,[2 1 3 4 6 5]);
    %dt6(:,:,:,2) = -dt6(:,:,:,2);
    %dt6(:,:,:,4) = -dt6(:,:,:,4);
end
dt6 = permute(dt6, [2 1 3 4]);
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
%b0_img = dtiResliceVolume(b0.cannonical_img, inv(b0.acpcXform), bb, mmDt);
b0_img = mrAnatResliceSpm(b0.cannonical_img, inv(b0.acpcXform), bb, mmDt, [7 7 7 0 0 0], showFigs);
b0_img(b0_img<0) = 0;
b0_img(isnan(b0_img)) = 0;

% % % create and (optionally) apply a brain mask to the dt6 data
% % try
% %     disp('Trying BET for DT brain mask...');
% %     [dtBrainMask,checkSlices] = mrAnatExtractBrain(double(b0_img), mmDt, 0.25);
% %     imwrite(checkSlices, [outPathName,'_dtBrainMask_BET25.png']);
% % catch
%     disp('BET failed (not installed?)- using thresholded b=0 image...');
%     disp('Because this is muscle and we are not segmenting brain.');
%     [c,v] = mrAnatHistogramSmooth(b0_img,256,0.05);
%     % derivative of the thresholded derivative gives us the locations where a
%     % rising or falling trend begins. In general, we can just take the first
%     % rising trend (ie. just after the background noise) to find the brain.
%     % We then back off from that by 25% (an empirically determined heuristic).
%     peakStart = find(diff(diff(c)>0)>0);
%     thresh = v(peakStart(1)+2);
%     thresh = thresh.*0.75;
%     dtBrainMask = b0_img > thresh;
% % end

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
notes = b0.notes;
b0 = int16(round(b0_img));
anat.mmPerVox = mmAnat;

%origin = bb(1,[2,1,3])-mmDt./2;
origin = bb(1,[1,2,3])-mmDt./2;
%xformToAnat = [diag(mmDt./mmAnat) [0 0 0]'; [0 0 0 1]];
xformToAcPc = [diag(mmDt) origin'; [0 0 0 1]]; %swapXY*[diag(mm) origin'; [0 0 0 1]];
anat.xformToAcPc = t1.acpcXform;
%anat.vol2Tal = t1.talairach.vol2Tal;
%anat.vol2Tal.acpcXform = t1.acpcXform;

disp('Avoiding Talairach and MNI coordinate transformations.');
% 
% try,
%     rp = t1.talairach.refPoints;
%     % Why swap coords like this? Well, the real reason has to do with the
%     % history of ComputeTalairach. We could figure this out in a more general
%     % way using t1.talairach.refPoints.mat, which tells us how the coords were
%     % transformed in ComputeTalairach. In the end, the following reordering
%     % works for our data, since the pre-processing is consistent.
%     mm = t1.cannonical_mmPerVox([2 3 1]);
%     anat.talScale.notes = ['Scale factors to go from subject mm to Talairach mm.' ...
%         'Eg. talCoord = anat.talScale.sac * imgCoord.' ...
%         'The scales are (in order) superior, inferior, left, right ' ...
%         'and anterior of AC, ac-to-pc and posterior of pc.'];
%     anat.talScale.sac = 72./sqrt(sum(((rp.acXYZ-rp.sacXYZ).*mm).^2));
%     anat.talScale.iac = 42./sqrt(sum(((rp.acXYZ-rp.iacXYZ).*mm).^2));
%     anat.talScale.lac = 62./sqrt(sum(((rp.acXYZ-rp.lacXYZ).*mm).^2));
%     anat.talScale.rac = 62./sqrt(sum(((rp.acXYZ-rp.racXYZ).*mm).^2));
%     anat.talScale.aac = 68./sqrt(sum(((rp.acXYZ-rp.aacXYZ).*mm).^2));
%     anat.talScale.acpc = 24./sqrt(sum(((rp.acXYZ-rp.pcXYZ).*mm).^2));
%     % The PPC is referenced to the PC. It is at Talairach (0,-102,0) and the PC
%     % is at (0,-24,0), so it is 78 mm beyond the PC.
%     anat.talScale.ppc = 78./sqrt(sum(((rp.pcXYZ-rp.ppcXYZ).*mm).^2));
% catch 
%     disp('TALSCALE FAILED- perhaps talairach file is missing?');
% end
% 
% if(computeMNI)
%     % Compute SPM normalization params
%     template = fullfile(fileparts(which('spm_defaults')), 'templates', 'T1.mnc');
%     im = mrAnatHistogramClip(double(anat.img), 0.4, 0.985);
%     t1NormParams.name = 'MNI';
%     t1NormParams.sn = mrAnatComputeSpmSpatialNorm(im, anat.xformToAcPc, template);
% end
% 
% try
%     disp('Computing brain mask using FSL-BET...');
%     [anat.brainMask,checkSlices] = mrAnatExtractBrain(double(anat.img), anat.mmPerVox, 0.5);
%     imwrite(checkSlices, [outPathName,'_BET50.png']);
% catch 
%     disp('   FAILED.');
% end

disp(['Saving to ' outPathName '...']);
l = license('inuse'); h = hostid;
created = ['Created at ' datestr(now,31) ' by ' l(1).user ' on ' h{1} '.'];

% Bogus value that wasn't created
t1NormParams = 'not created for muscle';

save(outPathName, 'dt6', 'mmPerVox', 'notes', 'xformToAcPc', 'b0', 'dtBrainMask', 'anat', 'scanInfo', 't1NormParams', 'created');
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
