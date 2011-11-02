% go to every subject in the BA44-45 list
% load dt6
% compute SN
% load 4 fiber groups: ?BA*_cleaned.mat
% save them in a separate dir in MNI space with name and _MNI


baseDir = 'U:\data\reading_longitude\dti_adults\';
% subDirs = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
%         'jl040902','ka040923','mbs040503', 'me050126', 'mz040828',...
%         'pp050208', 'rd040630','sp050303'}; %
subDirs = {'sn040831'};
fiberDir = 'fibers\BA44-45\dissections\';
fgName = {'LBA44_cleaned', 'LBA45_cleaned','RBA44_cleaned','RBA45_cleaned'};
targetMNIdir = {'ba44-45_cleaned_MNI'};

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
        fg = dtiReadFibers(fgName{jj}, dt.t1NormParams);
        fileName = fullfile(baseDir,targetMNIdir,[subDirs{ii}(1:2) '_' fgName{jj} '_MNI.mat']);
        dtiWriteFiberGroup(fg,fileName , 1, 'MNI', def);
        clear fg ;
    end
end
