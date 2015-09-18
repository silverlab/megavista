% kb_initializeVista.m
% 
% Kelly Byrne | 09.22.14
%
% initiates an mrVista session for the given subject
%
% run from subject parent directory
%
% required input: user-defined parameters
% desired output: mrInit2_params.mat, mrSESSION.mat, mrSESSION_backup.mat
% ________________________________________________________________________________________________

% user-defined parameters:
subj = 'YL_032714';

% set session path
sess_path = sprintf('/Volumes/Plata2/MRS_amblyopia/DATA/%s', subj);
cd(sess_path)

% set-up functional and par files, inplane, and volume anatomy
epi_list = dir(fullfile(sess_path, 'nifti','epi*'));
for run = 1:numel(epi_list)
    epi_file{run} = fullfile(sess_path, 'nifti', epi_list(run).name); 
    assert(exist(epi_file{run}, 'file')>0);
end

par_list = dir(fullfile(sess_path, 'Stimuli', 'Parfiles', '*par'));
for par = 1:numel(par_list)
    par_file{par} = fullfile(sess_path, 'Stimuli', 'Parfiles', par_list(par).name);
    assert(exist(par_file{par}, 'file')>0);
end
 
inplane_file = fullfile(sess_path, 'nifti','gems.nii.gz'); 
assert(exist(inplane_file, 'file')>0)
 
anat_file = fullfile(sess_path, 'nifti', 'nu.nii.gz');
assert(exist(anat_file, 'file')>0)

% create params struct and specify desired parameters 
params = mrInitDefaultParams; 
params.inplane      = inplane_file; 
params.functionals  = epi_file; 
params.vAnatomy = anat_file;
params.parfile = par_file;
params.sessionDir   = sess_path;
params.subject = subj;
params.annotations = {'localizer' 'plaid1' 'plaid2'};
params.scanGroups = {[1], [2, 3]};

% initialize the session
mrInit2(params)
