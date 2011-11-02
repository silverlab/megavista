baseDir = '//biac2/wandell2/data/reading_longitude/dti_adults'; %on Teal
f = {'ab050307','as050307','aw040809','bw040806','da050311','gm050308',...
        'jl040902','ka040923','mbs040503', 'me050126', 'mz040828',...
        'pp050208', 'rd040630','sn040831','sp050303'};
    
for(ii=1:length(f))
    dt6FileName = fullfile(baseDir, f{ii}, [f{ii} '_dt6.mat']);
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
    %===============================
    
    roiPath = fullfile(fileparts(dt6FileName), 'ROIs','BA44-45');
    fiberPath = fullfile(fileparts(dt6FileName), 'fibers','BA44-45');
    roiNames = {'LBA44_p55_op.mat','LBA45_p55_tr.mat','RBA44_p55_op.mat','RBA45_p55_tr.mat'};
    fgNames = {'wholeBrain+LBA44+45_all.mat','wholeBrain+LBA44+45_all.mat','wholeBrain+RBA44+45_all.mat','wholeBrain+RBA44+45_all.mat'};   
    for(jj=1:length(roiNames))
        roiName = fullfile(roiPath,roiNames{jj});
        fgName = fullfile(fiberPath,fgNames{jj});
        roi = dtiReadRoi(roiName, dt.t1NormParams);
        fg = dtiReadFibers(fgName, dt.t1NormParams);
        newfg = dtiIntersectFibersWithRoi(0, {'and'}, .87, roi, fg);% min distance  - maybe increase this to be more inclusive
        newFgName = fullfile(fileparts(fgName), newfg.name);
        dtiWriteFiberGroup(newfg, [newFgName '.mat'], 1, 'acpc');
        dtiWriteFiberGroup(newfg, [newFgName '_MNI' '.mat'], 1, 'MNI', def);
        clear fg roi newfg;
    end
end

