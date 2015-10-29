function automatedWhiteMatterSeg(subjectID)
% ------------------------------------------------------------------------------------------------------------
% fMRI processing pipeline whose goal is to automatize steps as much as
% possible
% ------------------------------------------------------------------------------------------------------------
% Sara Popham, October 2015
% From the work made by Adrien Chopin, Eunice Yang, Rachel Denison, Kelly 
% Byrne, Summer Sheremata
% ------------------------------------------------------------------------------------------------------------

%% FOLDER SETUP AND INITIAL CHECKS
disp('You should be in the 06_mrVista_session folder for the subject that you are analyzing.');
answer = input('Is this correct? (y/n)  ','s');
if strmatch('y',lower(answer))
    disp('OK, continuing...');
    disp(' ');
elseif strmatch('n',lower(answer))
    error('Please start in the correct path and try again.');
else
    error('Input not understood.');
end

destinationFolder = cd;
mprageFile = [destinationFolder '/nifti/nu.nii.gz'];

answer = input('Have you already aligned high-res and low-res anatomicals? (y/n)   ','s');
%safer - check for a file that we know is issued during alignment - like
%mrRxSettings.mat
if strmatch('y',lower(answer))
    disp('Hooray, you are competent! We will now continue to white matter segmentation...');
    disp(' ');
elseif strmatch('n',lower(answer))
    error('Please complete that step before continuing with segmentation.');
else
    error('Input not understood.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CANNOT FIGURE OUT HOW TO GET tcsh TO WORK SO AM TRYING AN ALTERNATIVE %
% Let me know if this is bad, but I don't think it will change anything %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%seems alright!

%% WHITE MATTER SEGMENTATION
if exist([getenv('SUBJECTS_DIR') '/' subjectID])==7
    disp(['A subject folder for this participant already exists in ' getenv('SUBJECT_DIR')]);
    error('Please change subjectID to run white matter segmentation again.');
end

% here - one can put a question to be able to skip that part (it's long,
% and what if next part crashes)
success = system(['recon-all -i ' mprageFile ' -subjid ' subjectID ' -all']);
if success~=0
    error('Error in white matter segmentation... See other messages in command window for details.');
end

cd([getenv('SUBJECTS_DIR') '/' subjectID '/mri'])

%% MGZ TO NII CONVERSION
%given we may have skipped previous part, check here for the existence of
%output files from recon-all

% here - one can put a question to be able to skip that part
success = system(['mgz2nii.sh ' subjectID]);
if success~=0
    error('Error in conversion from mgz to nii file type.');
end

%% SETTING UP FILES FOR ITKGRAY
%given we may have skipped previous part, check here for the existence of
%output files from mgz2nii.sh

% here - one can put a question to be able to skip that part

%would be safer to give the full path directly to the ribbon.mgz file here,
%instead of only the subjectID
fs_ribbon2itk(subjectID,[],[],[getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_nu.nii.gz'],[],'RAS');

%check true success by looking for output files

%at that point, it would be cool to create a segmentation folder in the
%session folder and to move everything linked to the segmentation into it
%(eunice does that and it is much clearer)
success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_nu.nii.gz'],destinationFolder);
if success; disp(['Copying ' subjectID '_nu.nii.gz file... Done']);else error(status); end
success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/t1_class.nii.gz'],destinationFolder);
if success; disp('Copying t1_class.nii.gz file... Done');else error(status); end
