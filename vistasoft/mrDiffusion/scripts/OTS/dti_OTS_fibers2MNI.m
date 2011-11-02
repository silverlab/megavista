% Go to all the subjects in the list
% 1. Load dt6
% 2. Compute SN
% 3. Load 4 fiber groups: LOTS_sphere8, LOTS_dorsal, ROTS_sphere8,
% ROTS_dorsal
% 4. Save them in the target dir in MNI space with name and _MNI
%
% DY 05/2007
% Modified from dtiBroca_saveMNI.m
% Cleaned up by RFD 06/2007

baseDir = 'Y:\data\reading_longitude\dti\';
cd(baseDir); d = dir('*0*'); subDirs = {d.name};
% %Or you can list desired subjects as below
% subDirs = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
%         'jl040902','ka040923','mbs040503', 'me050126', 'mz040828',...
%         'pp050208', 'rd040630','sp050303'}; %
fiberDir = 'fibers\OTSproject';
fgName = {'LOTS_sphere8', 'LOTS_dorsal','ROTS_sphere8','ROTS_dorsal'};
targetMNIdir = 'zzz_reading_longitude_dti_analysis\OTSfibers_analysis\OTS_MNI_dorsal';

for ii = 18:length(subDirs)
    dt6Dir = fullfile(baseDir,subDirs{ii});
    cd(dt6Dir);
    dt6FileName = fullfile(baseDir, subDirs{ii}, [subDirs{ii} '_dt6.mat']);
    if exist(dt6FileName,'file')
        dt = load(dt6FileName, 'xformToAnat', 'anat', 't1NormParams');

        disp(['Processing ' dt6FileName '...']);

        % compute SN for MNI save
        spmDir = fileparts(which('spm_normalise'));
        d = dir(fullfile(spmDir, 'templates','T1.*'));
        template = fullfile(spmDir, 'templates', d(1).name);
        spm_defaults; global defaults;
        params = defaults.normalise.estimate;
        img = mrAnatHistogramClip(double(dt.anat.img), 0.4, 0.985);
        t1NormParams.sn = mrAnatComputeSpmSpatialNorm(img, dt.anat.xformToAcPc, template, params);
        def = t1NormParams;
        [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
        def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
        def.outMat = eye(4);
        workDir = fullfile(baseDir,subDirs{ii},fiberDir);
        cd(workDir);
        % for each ROI, read all fg and merge them
        for jj = 1:length(fgName)
            fiberFile = [fgName{jj} '.mat'];
            if exist(fiberFile,'file') % only operate if the fiber group exists
                fg = dtiReadFibers(fiberFile);
                fileName = fullfile(baseDir,targetMNIdir,[subDirs{ii}(1:2) '_' fgName{jj} '_MNI.mat']);
                dtiWriteFiberGroup(fg,fileName , 1, 'MNI', def);
                clear fg ;
            end
        end
    end
end
