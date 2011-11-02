% go to every subject that has the appropriate fiber groups
% (1) Sphere 30 + Dilate 8 (fMRI)
% (2) Sphere 30 + Dilate 8 (tal)
% (3) OTS -> angular gyrus (fMRI)
% (4) OTS -> angular gyrus (tal)
% load dt6
% compute SN
% save them in a separate dir in MNI space with name and _MNI

% THIS CODE IS FOR ADULTS

baseDir = 'Y:\data\reading_longitude\dti_adults\';
subDirs = {'aab050307', 'aw040809', 'bw040806', 'rfd040630', 'rk050524'};
fiberDir = 'fibers\OTSproject\';

fgName = {'LOTS_w123Vf_sphere30_AND_dilate8_FG.mat', 'ROTS_w123Vf_sphere30_AND_dilate8_FG.mat',...
            'LOTS_w123Vf_sphere30_AND_dilate8+angG.mat', 'ROTS_w123Vf_sphere30_AND_dilate8+angG.mat',...
            'ROTS_wVf_sphere30+dilate8.mat',};

% no tal-defined fiber groups for adults
        
for ii = 1:length(subDirs)
    dt6Dir = fullfile(baseDir,subDirs{ii});
    cd(dt6Dir);
    dt6FileName = fullfile(baseDir, subDirs{ii}, [subDirs{ii} '_dt6.mat']);
    dt = load(dt6FileName, 'xformToAnat', 'anat', 't1NormParams');
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;
    disp(['Processing ' dt6FileName '...']);

    % compute SN for MNI save
    spmDir = fileparts(which('spm_normalise'));
    template = fullfile(spmDir, 'templates', 'T1.mnc');
    spm_defaults;
    params = defaults.normalise.estimate;
    img = mrAnatHistogramClip(double(dt.anat.img), 0.4, 0.985);
    t1NormParams.sn = mrAnatComputeSpmSpatialNorm(img, dt.anat.xformToAcPc, template, params);
%     disp('Appending new normalization to original dt6 file...');
%     save(fname, 't1NormParams', '-APPEND');
    def = t1NormParams;
    [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
    def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
    
    workDir = fullfile(baseDir,subDirs{ii},fiberDir);
    cd(workDir);
    
    % for each ROI, read all fg and merge them
    for jj = 1:length(fgName)
        fiberFile = fullfile(baseDir,subDirs{ii},fiberDir,fgName{jj});
        if exist(fiberFile,'file') % only operate if the fiber group exists
            fg = dtiReadFibers(fgName{jj}, dt.t1NormParams);
            fileName = fullfile(baseDir,'OTS_MNI',[subDirs{ii}(1:3) '_' fgName{jj} '_MNI.mat']);
            dtiWriteFiberGroup(fg,fileName , 1, 'MNI', def);
            clear fg ;
        end
    end
end

