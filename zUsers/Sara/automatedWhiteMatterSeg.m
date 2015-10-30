function automatedWhiteMatterSeg(subjectID)
% ------------------------------------------------------------------------------------------------------------
% fMRI processing pipeline whose goal is to automatize steps as much as
% possible
% ------------------------------------------------------------------------------------------------------------
% Sara Popham, October 2015
% From the work made by Adrien Chopin, Eunice Yang, Rachel Denison, Kelly 
% Byrne, Summer Sheremata
% ------------------------------------------------------------------------------------------------------------
% subjectID = name of folder in freesurfer SUBJECTS_DIR to be created
% 
% This allows either itkGray or mrGray file conversion based on user input.
% ------------------------------------------------------------------------------------------------------------

%% FOLDER SETUP AND INITIAL CHECKS
disp('You should be in the 06_mrVista_session folder for the subject that you are analyzing.');
answer = input('Is this correct? (y/n)  ','s');
if strmatch('y',lower(answer))
    disp(' ');
elseif strmatch('n',lower(answer))
    error('Please start in the correct path and try again.');
else
    error('Input not understood.');
end

mrVistaFolder = cd;
mprageFile = [mrVistaFolder '/nifti/nu.nii.gz'];

%make new segmentation folder inside the mrVista session folder
if ~(exist([mrVistaFolder '/Segmentation'],'dir')==7)
    mkdir(mrVistaFolder,'Segmentation');
end
destinationFolder = [mrVistaFolder '/Segmentation'];

if exist('mrRxSettings.mat','file')==2
    disp('mrRxSettings.mat file found.  We will continue with white matter segmentation...');
    disp(' ');
else
    error('mrRxSettings.mat file not found.  Please align high-res and low-res anatomicals before continuing.');
end


%% WHITE MATTER SEGMENTATION
white_matter_seg = 1; %default is that this step will be run

if exist([getenv('SUBJECTS_DIR') '/' subjectID],'dir')==7
    disp(['A subject folder for this participant already exists in ' getenv('SUBJECTS_DIR')]);
    answer = input('Have you already run white matter segmentation for this participant? (y/n)  ','s');
    disp(' ');
    if strmatch('y',lower(answer))
        white_matter_seg = 0; %recon-all step will not be run
    elseif strmatch('n',lower(answer))
        error('Please change subjectID or delete subject folder and run white matter segmentation again.');
    else
        error('Input not understood.');
    end
end

if white_matter_seg  %only skipped if user input says that they have already run the white matter segmentation
                     %this will be double-checked on the next step by looking for the existance of the ribbon.mgz file
    disp('Starting white matter segmentation.  May take 8-10 hours to complete...');
    disp(' ');
    success = system(['recon-all -i ' mprageFile ' -subjid ' subjectID ' -all']);
    if success~=0
        error('Error in white matter segmentation... See other messages in command window for details.');
    end
end

cd([getenv('SUBJECTS_DIR') '/' subjectID '/mri'])

%% MGZ TO NII CONVERSION
if ~(exist('ribbon.mgz','file')==2) %existance of this file indicates that recon-all step has been run
    error('White matter segmenation for this subject was not completed.');
end
if ~(exist([subjectID '_ribbon.nii.gz'],'file')==2)
    %run the mgz to nii conversion since it has not yet been done
    success = system(['mgz2nii.sh ' subjectID]);
    if success~=0
        error('Error in conversion from mgz to nii file type.');
    end
else
    disp('mgz2nii conversion step has previously been done.  Skipping it...');
    disp(' ');
end


%% SETTING UP FILES FOR ITKGRAY OR MRGRAY (User input choice)
if ~(exist([subjectID '_ribbon.nii.gz'],'file')==2) %existance of this file indicates that mgz2nii step has been run
    error('White matter segmenation for this subject does not exist.');
end

answer = input('Do you want to set up files for itkGray? (y/n)  ','s');
disp(' ');
if strmatch('y',lower(answer)) %yes, I want to set up for itkGray
    fs_ribbon2itk(subjectID,[],[],[getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_nu.nii.gz'],[],'RAS');
    
    %copy files to 06_mrVista_session/Segmentation/ folder
    success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_nu.nii.gz'],destinationFolder);
    if success; disp(['Copying ' subjectID '_nu.nii.gz file... Done']);else error(status); end
    success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_ribbon.nii.gz'],destinationFolder);
    if success; disp(['Copying ' subjectID '_ribbon.nii.gz file... Done']);else error(status); end
    success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/t1_class.nii.gz'],destinationFolder);
    if success; disp('Copying t1_class.nii.gz file... Done');else error(status); end
    disp(' ');
    
    %check that itkGray files were actually put in the correct place
    cd(destinationFolder);
    if exist('t1_class.nii.gz','file')==2 && exist([subjectID '_nu.nii.gz'],'file')==2 && exist([subjectID '_ribbon.nii.gz'],'file')==2
        disp('Necessary files for itkGray successfully copied!');
        disp(['Process complete for ' subjectID '!!']);
    else
        error('Some itkGray files missing!');
    end
    
elseif strmatch('n',lower(answer)) %no, I do not want to set up for itkGray
    %give alternative choice to set up for mrGray
    answer2 = input('Do you want to set up files for mrGray? (y/n)  ','s');
    disp(' ');
    if strmatch('y',lower(answer2)) %yes, I want to set up for mrGray
        
        disp('On any pop-ups that appear, save in the default location presented to you.  Press any key to continue.');
        pause
        disp(' ');
        
        createVolAnatSKERI([subjectID '_nu.nii.gz']);
        fs4_ribbon2class([subjectID '_ribbon.nii.gz']);
        
        %copy files to 06_mrVista_session/Segmentation/ folder
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_nu.nii.gz'],destinationFolder);
        if success; disp(['Copying ' subjectID '_nu.nii.gz file... Done']);else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_ribbon.nii.gz'],destinationFolder);
        if success; disp(['Copying ' subjectID '_ribbon.nii.gz file... Done']);else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/UnfoldParams.mat'],destinationFolder);
        if success; disp('Copying UnfoldParams.mat file... Done');else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/vAnatomy.dat'],destinationFolder);
        if success; disp('Copying vAnatomy.dat file... Done');else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/left.Class'],destinationFolder);
        if success; disp('Copying left.Class file... Done');else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/right.Class'],destinationFolder);
        if success; disp('Copying right.Class file... Done');else error(status); end
        disp(' ');
        
        %check that mrGray files were actually put in the correct place
        cd(destinationFolder);
        if exist([subjectID '_nu.nii.gz'],'file')==2 && exist([subjectID '_ribbon.nii.gz'],'file')==2 && exist('vAnatomy.dat','file')==2 ...
                && exist('vAnatomy.dat','file')==2 && exist('left.Class','file')==2 && exist('right.Class','file')==2
            disp('Necessary files for mrGray successfully copied!');
            disp(['Process complete for ' subjectID '!!']);
        else
            error('Some mrGray files missing!');
        end
        close all %closing any figures that 
        
    elseif strmatch('n',lower(answer2)) %no, I do not want to set up for mrGray
        disp('OK, setup for both itkGray and mrGray were skipped.');
        cd(destinationFolder);
    else
        error('Input not understood.');
    end
else
    error('Input not understood.');
end


