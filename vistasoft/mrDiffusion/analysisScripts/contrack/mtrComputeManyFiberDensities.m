function mtrComputeManyFiberDensities(subjDir, fgFiles, threshWeightVec)
% Script for computing fiber density for many path distributions

dt6 = load(fullfile(subjDir,'dt6.mat'),'xformToAcPc');

ni = readFileNifti(fullfile(subjDir,'bin','t1.nii.gz'));
img_t1 = ni.data;
imSize = size(img_t1);
%gd = dtiGet(h, 'acpcGrid', h.vec.mat, h.vec.mmPerVoxel, size(h.vec.img(:,:,:,1)));
% We need to get the T1-space image coords from the current anatomy image.
%imgCoords = mrAnatXformCoords(inv(dtiGet(h,'acpcXform')), [gd.X(:) gd.Y(:) gd.Z(:)]);
%xform = inv(h.xformToAcpc);
% TO DO: this should be based on the actual fiber step size, rather than
% assuming that it's 1mm.
mmPerVoxel = [1 1 1];
xformT1ImgToAcPc = ni.qto_xyz;
clear ni;

if ieNotDefined('threshWeightVec')
    threshWeightVec = [];
end

if isstr(fgFiles)
    fgsDir = dir(fgFiles);
    fgFiles = {};
    for ff = 1:length(fgsDir)
        fgFiles{ff} = fgsDir(ff).name;
    end
end

for ff = 1:length(fgFiles)
    [fgDir, filename, junk2, junk3] = fileparts(fgFiles{ff});
    msg = sprintf('Importing fiber group from %s ...',fgFiles{ff});
    disp(msg);
    % Import fibers
    fg_filename = fgFiles{ff};
    fg = mtrImportFibers(fg_filename, dt6.xformToAcPc);
    
    weight = [];
    tempThreshVec = [];
    if ~isempty(threshWeightVec)
        % Get weight so that we can sort
        weight = fg.params{1}.stat;
        [foo, iSort] = sort(weight,'descend');
        % Make sure we don't try to sample more than the current database
        tempThreshVec = threshWeightVec(threshWeightVec<length(fg.fibers));
    end
    % Doing it this way to handle case where max is too big for any fibers
    % ot be selected
    if isempty(tempThreshVec)
        iSort = [1:length(fg.fibers)];
        tempThreshVec = length(fg.fibers);
    end
    
    for tt = tempThreshVec;
        % Calculate density
        disp(['Calculating fiber density map at thresh = ' num2str(tt) ' ...']);
        fgThresh = dtiNewFiberGroup;
        fgThresh.fibers = fg.fibers(iSort(1:tt));
        fdImg = dtiComputeFiberDensityNoGUI(fgThresh, xformT1ImgToAcPc, imSize, 1, 0, 0);
        img_filename = sprintf('%s_thresh_%g_fd_image.nii.gz',filename,tt);
        img_filename = fullfile(fgDir,img_filename);
        % Save out image
        msg = sprintf('Saving density image to %s ...',img_filename);
        disp(msg);
        dtiWriteNiftiWrapper(fdImg, xformT1ImgToAcPc, img_filename);        
    end
    clear('fgThresh','fg','fgImg');
    msg = sprintf('Finished %g%%',100*ff/length(fgFiles));
    disp(msg);
end


% 
% subject = 'md';
% if(strcmp(subject,'sil'))
%     dataDir = 'c:\cygwin\home\sherbond\images\sil_nov05\dti3_ser7\analysis';
%     dt6File = fullfile(dataDir,'dti3_ser7_dt6.mat');
%     fgDir = 'fibers\gastroc';
%     roiFile = fullfile(dataDir,'ROIs','tendon_plate.mat');
%     fgFilenames = dir(fullfile(dataDir,fgDir,'paths*.dat'));
% elseif(strcmp(subject,'tony'))
%     dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis';
%     dt6File = fullfile(dataDir,'dti3_dt6.mat');
%     fgDir = 'bin\metrotrac\tendon_small';
%     roiFile = fullfile(dataDir,'ROIs','tendon_sub_slice.mat');
%     fgFilenames = dir(fullfile(dataDir,fgDir,'paths*.dat'));
% elseif(strcmp(subject,'thor'))
%     dataDir = 'c:\cygwin\home\sherbond\images\thor_nov05\dti4_ser11\analysis';
%     dt6File = fullfile(dataDir,'dti4_ser11_dt6.mat');
%     fgDir = 'fibers\gastroc';
%     roiFile = fullfile(dataDir,'ROIs','tendon_plate.mat');
%     fgFilenames = dir(fullfile(dataDir,fgDir,'paths*.dat'));
% elseif(strcmp(subject,'md'))
%     dataDir = 'c:\cygwin\home\sherbond\images\md040714';
%     dt6File = fullfile(dataDir,'md040714_dt6.mat');
%     fgDir = 'bin\metrotrac\fine_param_search';
%     roiFile = fullfile(dataDir,'ROIs','tendon_sub_slice.mat');
%     fgFilenames = dir(fullfile(dataDir,fgDir,'paths*.dat'));
% %     fgFilenames = dir(fullfile(dataDir,fgDir,'paths*_s15.dat'));
% %     fgFilenames = [fgFilenames; dir(fullfile(dataDir,fgDir,'paths*_s40.dat'))];
% else
%     error('Unknown subject.');
% end
% 
% 
% dt6 = load(dt6File);
% 
% %bb = dtiGet(h,'boundingBox');
% %imSize = diff(bb)+1;
% imSize = size(dt6.anat.img);imSize = imSize(1:3);
% 
% %gd = dtiGet(h, 'acpcGrid', h.vec.mat, h.vec.mmPerVoxel, size(h.vec.img(:,:,:,1)));
% % We need to get the T1-space image coords from the current anatomy image.
% %imgCoords = mrAnatXformCoords(inv(dtiGet(h,'acpcXform')), [gd.X(:) gd.Y(:) gd.Z(:)]);
% %xform = inv(h.xformToAcpc);
% % TO DO: this should be based on the actual fiber step size, rather than
% % assuming that it's 1mm.
% mmPerVoxel = [2 2 2];
% xformImgToAcpc = dt6.anat.xformToAcPc;%/diag([dt6.anat.mmPerVox(1:2) 1 1]);
% 
% for ff = 1:length(fgFilenames)
%     [junk1, filename, junk2, junk3] = fileparts(fgFilenames(ff).name);
%     msg = sprintf('Importing fiber group from %s ...',fgFilenames(ff).name);
%     disp(msg);
%     % Import fibers
%     fg_filename = fullfile(dataDir,fgDir,fgFilenames(ff).name);
%     fg = mtrImportFibers(fg_filename, dt6.xformToAcPc);
%     disp('Calculating fiber density map ...');
%     fdImg = dtiComputeFiberDensityNoGUI(fg, xformImgToAcpc, imSize, 1);
%     img_filename = sprintf('%s_fd_image.nii.gz',filename);
%     msg = sprintf('Saving density image to %s ...',img_filename);
%     disp(msg);
%     img_filename = fullfile(dataDir,fgDir,img_filename);
%     dtiWriteNiftiWrapper(fdImg, dt6.anat.xformToAcPc, img_filename);
%     clear('fg','fgImg');
%     msg = sprintf('Finished %g%%',100*ff/length(fgFilenames));
%     disp(msg);
% end