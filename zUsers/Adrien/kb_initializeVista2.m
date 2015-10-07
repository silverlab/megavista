function kb_initializeVista2(sess_path, subj)
% from kb_initializeVista.m
% 
% Kelly Byrne | 09.22.14
%
% initiates an mrVista session for the given subject
%
% run from subject parent directory
%
% required input: user-defined parameters
% desired output: mrInit2_params.mat, mrSESSION.mat, mrSESSION_backup.mat
% Modified by Adrien Chopin, 2015, to make the code more general and
% integrate it to the automated pipeline
% ________________________________________________________________________________________________

% user-defined parameters:
if ~exist('subj','var'); subj = 'RN31'; end
if ~exist('sess_path','var');sess_path = '/Users/adrienchopin/Desktop/Big_data_STAM/RN31/pre1/test2/'; end
  
% path to the folder where the session should be started in
% It should contain a nifti folder and a Parfiles folder
cd(sess_path)

% set-up functional and par files, inplane, and volume anatomy
epi_list = dir(fullfile(sess_path, 'nifti','epi*'));
nbRuns = numel(epi_list);
for run = 1:nbRuns
    epi_file{run} = fullfile(sess_path, 'nifti', epi_list(run).name);
    disp(['Epi detected: ',epi_file{run}])
    assert(exist(epi_file{run}, 'file')>0);
end

par_list = dir(fullfile(sess_path, 'Stimuli/Parfiles', '*par'));
for par = 1:numel(par_list)
    par_file{par} = fullfile(sess_path, 'Stimuli/Parfiles', par_list(par).name);
    disp(['Processing: ',par_file{par}])
    assert(exist(par_file{par}, 'file')>0);
end
 
inplane_file = fullfile(sess_path, 'nifti','gems.nii.gz');
disp('Gems file detected:')
disp(inplane_file);
assert(exist(inplane_file, 'file')>0)
 
anat_file = fullfile(sess_path, 'nifti', 'nu.nii.gz');
disp('Mprage file detected:')
disp(anat_file)
assert(exist(anat_file, 'file')>0)

% create params struct and specify desired parameters 
params = mrInitDefaultParams; 
params.inplane      = inplane_file; 
params.functionals  = epi_file; 
params.vAnatomy = anat_file;
params.parfile = par_file;
params.sessionDir   = sess_path;
params.subject = subj;

%with this, you can annotate
%each epi/scans in the order that mrVista reads them here in the list created above
params.annotation = {};
for i=1:nbRuns
    params.annotations(i) = {['epi',sprintf('%02.f',i)]}; 
end

 %I group all my epi together for the main experiment
    %with this, you can group scans
%together for average when doing stats - in the exemple here {[1], [2, 3]}, 1 is a group,
%2 and 3 will be a group too (the order is one from the list created above)
% initialize the session
params.scanGroups = {1:nbRuns};

success = mrInit2(params);

if success==1; disp('Initialization seems successful'); else error('Initialization failed...'); end

