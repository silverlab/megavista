% go to every subject that has the appropriate fiber groups
% (1) Sphere 30 + Dilate 8 (fMRI)
% (2) Sphere 30 + Dilate 8 (tal)
% (3) OTS -> angular gyrus (fMRI)
% (4) OTS -> angular gyrus (tal)
% load dt6
% compute SN
% save them in a separate dir in SIRL54 space with name and _SIRL54

% THIS CODE IS FOR KIDS

baseDir = '/biac2/wandell2/data/reading_longitude/dti';
cd(baseDir)
d = dir('*0*'); % lists all directories to do everybody at once
subDirs = {d.name};
fiberDir = 'fibers/OTSproject/';

fgName = {'LOTS_sphere30+dilate8', 'ROTS_sphere30+dilate8',...
            'LOTS_tal_sph8_FG','ROTS_tal_sph8_FG',...
            'LOTS_sphere30+dilate8+angG', 'ROTS_sphere30+dilate8+angG',...
            'LOTS_tal_sph8+angG', 'ROTS_tal_sph8+angG'};

for ii = 1:length(subDirs)
    dt6Dir = fullfile(baseDir,subDirs{ii});
    cd(dt6Dir);
    dt6FileName = fullfile(baseDir, subDirs{ii}, [subDirs{ii} '_dt6.mat']);
    dt = load(dt6FileName, 'xformToAnat', 'anat', 't1NormParams');
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    disp(['Processing ' dt6FileName '...']);

    spmDir = fileparts(which('spm_normalise'));
    spm_defaults;
    params = defaults.normalise.estimate;
    img = mrAnatHistogramClip(double(dt.anat.img), 0.4, 0.985);
    % Compute MNI normalization
    template = fullfile(spmDir, 'templates', 'T1.mnc');
    t1NormParams(1).sn = mrAnatComputeSpmSpatialNorm(img, dt.anat.xformToAcPc, template, params);
    t1NormParams(1).name = 'MNI';

    % compute SN for SIRL and save
    template = fullfile(spmDir, 'templates', 'SIRL','child','SIRL54ms_warp2_T1_brain.img');
    if(~isfield(dt.anat,'brainMask') || isempty(dt.anat.brainMask) ...
            || ~all(size(dt.anat.brainMask)==size(img)))
        error(['No brain mask for ' dt6FileName '! (See dtiExtractBrains or brain mask option under dtiFIberUI analyze menu).']);
    end
    img(~dt.anat.brainMask) = 0;
    t1NormParams(2).sn = mrAnatComputeSpmSpatialNorm(img, dt.anat.xformToAcPc, template, params);
    t1NormParams(2).name = 'SIRL54';
    
    % save MNI and SIRL54 xforms
    disp('Appending new normalizations to original dt6 file...');
    save(dt6FileName, 't1NormParams', '-APPEND');
    
    %set the deformation to SIRL 54 for saving all fgs in that space
    def = t1NormParams(2);
    [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
    def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
    
    % set subject's fibers dir for reading the existing fgs in native space
    workDir = fullfile(baseDir,subDirs{ii},fiberDir);
    cd(workDir);
    
    % for each sub, read all fg and save as sn
    for jj = 1:length(fgName)
        fiberFile = [fgName{jj} '.mat'];
        if exist(fiberFile,'file') % only operate if the fiber group exists
            fg = dtiReadFibers(fiberFile, dt.t1NormParams);
            fileName = fullfile(baseDir,'OTS_SIRL54_child',[subDirs{ii}(1:3) '_' fgName{jj} '_SIRL54.mat']);
            dtiWriteFiberGroup(fg,fileName , 1, 'SIRL54', def);
            clear fg ;
        end
    end
end






% % THIS CODE IS FOR ADULTS
% 
% baseDir = 'Y:\data\reading_longitude\dti_adults\';
% subDirs = {'aab050307', 'aw040809', 'bw040806', 'rfd040630', 'rk050524'};
% fiberDir = 'fibers\OTSproject\';
% 
% fgName = {'LOTS_w123Vf_sphere30_AND_dilate8_FG', 'ROTS_w123Vf_sphere30_AND_dilate8_FG',...
%             'LOTS_w123Vf_sphere30_AND_dilate8+angG', 'ROTS_w123Vf_sphere30_AND_dilate8+angG',...
%             'ROTS_wVf_sphere30+dilate8',};
% 
% % no tal-defined fiber groups for adults
%         
% for ii = 1:length(subDirs)
%     dt6Dir = fullfile(baseDir,subDirs{ii});
%     cd(dt6Dir);
%     dt6FileName = fullfile(baseDir, subDirs{ii}, [subDirs{ii} '_dt6.mat']);
%     dt = load(dt6FileName, 'xformToAnat', 'anat', 't1NormParams');
%     dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
%     disp(['Processing ' dt6FileName '...']);
% 
%     % compute SN for MNI save
%     spmDir = fileparts(which('spm_normalise'));
%     template = fullfile(spmDir, 'templates', 'T1.mnc');
%     spm_defaults;
%     params = defaults.normalise.estimate;
%     img = mrAnatHistogramClip(double(dt.anat.img), 0.4, 0.985);
%     t1NormParams.sn = mrAnatComputeSpmSpatialNorm(img, dt.anat.xformToAcPc, template, params);
% %     disp('Appending new normalization to original dt6 file...');
% %     save(fname, 't1NormParams', '-APPEND');
%     def = t1NormParams;
%     [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
%     def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
%     
%     workDir = fullfile(baseDir,subDirs{ii},fiberDir);
%     cd(workDir);
%     
%     % for each ROI, read all fg and merge them
%     for jj = 1:length(fgName)
%         fiberFile = [fgName{jj},'.mat']);
%         if exist(fiberFile,'file') % only operate if the fiber group exists
%             fg = dtiReadFibers(fiberFile, dt.t1NormParams);
%             fileName = fullfile(baseDir,'OTS_MNI',[subDirs{ii}(1:3) '_' fgName{jj} '_MNI.mat']);
%             dtiWriteFiberGroup(fg,fileName , 1, 'MNI', def);
%             clear fg ;
%         end
%     end
% end
% 
