% Go to all the subjects in the list
% 1. Load dt6
% 2. Compute SN (and "t1normparams")
% 3. Load 2 fiber groups: LH+LFFA, RH+RFFA
% 4. Save fiber groups in the target dir in MNI space with name and _MNI
% 5. Save dt6.mat with normalization parameters (otherwise, cannot view
% normalized fibers on that brain)
%
% DY 04/2008
% Modified from dti_OTS_fibers2MNI and dti_OTS_Cohen8mmMNI
% Fixed on 4/11/08 by RFD (correct template path, save normparams to dt6) 

if ispc
    dtiDir = 'W:\projects\Kids\dti\';
else
    dtiDir = '/biac1/kgs/projects/Kids/dti';
end

todoDirs = {fullfile('adults','3T_AP','acg_38yo_010108'),...
    fullfile('adults','gg_37yo_091507_FreqDirLR'),...
    fullfile('adolescents','3T_AP','ar_12yo_121507'),...
    fullfile('adolescents','3T_AP','dw_14yo_102007'),...
    fullfile('adolescents','3T_AP','is_16yo_120907'),...
    fullfile('adolescents','3T_AP','kwl_14yo_010508'),...
    fullfile('adolescents','kll_18yo_011908_FreqDirLR')};

subs={'adult_acg','adult_gg','adol_ar','adol_dw','adol_is','adol_kwl','adol_kll'};

roiDir = fullfile('ROIs','functional');
fiberDir = fullfile('fibers','functional');
fgName = {'LH+LFFA_sphere10.mat', 'RH+RFFA_sphere10.mat'};
targetMNIdir = fullfile(dtiDir,'davie','fibersMNI');

for ii = 1:length(todoDirs)
    thisDir = fullfile(dtiDir,todoDirs{ii},'dti30');
    fname = fullfile(thisDir,'dt6.mat');
    dt = dtiLoadDt6(fname);
    disp(['Processing ' fname '...']);
    
    % Compute 'def' - xform for saving in MNI space -- this is equivalent
    % to choosing File -> Add normalized map (and selecting a nifti)
    template = fullfile(fileparts(which('mrDiffusion')),'templates','MNI_EPI.nii.gz');

    spm_defaults; global defaults;
    params = defaults.normalise.estimate;
    img = mrAnatHistogramClip(double(dt.b0), 0.4, 0.985);
    t1NormParams.sn = mrAnatComputeSpmSpatialNorm(img, dt.xformToAcpc, template, params);
    def = t1NormParams;
    [def.deformX, def.deformY, def.deformZ] = mrAnatInvertSn(def.sn);
    def.inMat = inv(def.sn.VF.mat); % xform from acpc space to deformation field space
    def.outMat = eye(4);

    % Append spatial norm information to the dt6 file (adding T1NORMPARAMS
    % to the dt6 struct, which is itself a struct with xform information)
    t1NormParams.name = 'MNI';
    save(fname, 't1NormParams', '-APPEND');

    for jj = 1:length(fgName)
        fiberFile = fullfile(thisDir, fiberDir, fgName{jj});
        if exist(fiberFile,'file') % only operate if the fiber group exists
            fg = dtiReadFibers(fiberFile);
            fg.name = [subs{ii} '_' fgName{jj}(1:end-4) '_MNI.mat'];
            fileName = fullfile(targetMNIdir,fg.name);
            dtiWriteFiberGroup(fg,fileName , 1, 'MNI', def);
            clear fg ;
        end
    end
end