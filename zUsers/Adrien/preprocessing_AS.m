function preprocessing_AS(subjectID)
% ------------------------------------------------------------------------------------------------------------
% fMRI processing pipeline whose goal is to automatize steps as much as
% possible
% ------------------------------------------------------------------------------------------------------------
% Adrien chopin, late Aug 2015
% From the work made by Eunice Yang, Rachel Denison, Kelly Byrne, Summer
% Sheremata
% ------------------------------------------------------------------------------------------------------------
clc
% ------------------------------------------------------------------------------------------------------------
% REPLACE THE FOLLOWING VARIABLE WITH YOUR VALUES
disp(' --------------   CHECKLIST BEFORE STARTING   -----------------')
disp('- DICOM files should be in the subject folder in a folder called 01_Raw_DICOM')
disp('- PAR files should be in the folder 01_PAR')
disp('- Epi, in 01_Raw_DICOM, should be in folders called epi01-whatever, epi02-whatever, ....')
disp('- Gems, in 01_Raw_DICOM, should be in folders called gems-whatever (no capital)')
disp('- mprage, in 01_Raw_DICOM, should be in folders called gems_mprage-whatever (no capital).')
disp('- You should be in the subject folder for the subject that you want to analyse')
beep; answer = input('Is it all correct? 1 = ESC; Enter = OK ','s');
if str2double(answer) == 1; error('ESCAPE'); end
%subject_folder = '/Users/adrienchopin/Desktop/Big_data_STAM/RN31/pre1/NewPipeline'; %no end slash
subject_folder = cd;

if ~exist('subjectID','var'); beep; subjectID = input('Enter subject ID:','s'); end

%Write the following line (not commented, with your correct path) in the
%command line to save the variable in a file called pathFile - move that
%file to your zUsers folder

%%------     LINES TO RUN UNCOMMENTED IN COMMAND WINDOW            -------------%
%megavista_folder = '/Users/adrienchopin/Desktop/Megavista'; %no end slash, update this to your megavista folder
%save('pathFile.mat','megavista_folder');
%%--------               END                                        ----------%

if exist('pathFile.mat','file')~=2; error('pathFile.mat not found...'); end
load('pathFile.mat')
% ------------------------------------------------------------------------------------------------------------

% Naming conventions for the different folders in subject folder
rawDICOMfolder = '01_Raw_DICOM';
PARfolder = '01_PAR';
rawBackup = '02_Raw_DICOM_Backup';
niftiFolder = '03_nifti';
mocoFolder = '04A_MoCo';
mocoCheckFolder = '04B_MoCo_Check';
niftiFixedFolder = '05_nifti_fixed';
mrVistaFolder = '06_mrVista_session';

% Absolute path to those folders
subject_folderDICOM = [subject_folder,'/',rawDICOMfolder];
subject_folderPAR = [subject_folder,'/',PARfolder];
subject_folderNIFTI = [subject_folder,'/',niftiFolder];
subject_folderMoco = [subject_folder,'/',mocoFolder];
subject_folderMocoCheck = [subject_folder,'/',mocoCheckFolder];
subject_folderNiftiFx = [subject_folder,'/',niftiFixedFolder];
subject_folderVista = [subject_folder,'/',mrVistaFolder];

disp(['***********       STARTING PIPELINE  AT  ', dateTime,' for subjectID ', subjectID,'       *******************'])
%check existence of folders
    disp(['Subject folder is : ', subject_folder])
        if exist(subject_folder,'dir')==7; disp('Subject folder exists'); else error('Subject folder does not exist'); end
    disp(['Megavista folder is : ', megavista_folder])
        if exist(megavista_folder,'dir')==7; disp('Megavista folder exists'); else error('Megavista folder does not exist'); end
    disp('************************************************************************************************************************')
    preprocessPath = [megavista_folder, '/silverlab_vista_tools/python_preproc'];
    preprocessPath_alt = [megavista_folder, '/zUsers/Sara']; %this allows to use enhanced MoCo, remove it if you don't have it (motionCorrect_SP.py)

    if exist(preprocessPath,'dir')==7; cd(preprocessPath);
    else disp('Strangely, the folder silverlab_vista_tools/python_preproc does not exist in megavista...'); end

    disp('Your system path is (it should be the line added at beginning of the matlab file):')
        if system('echo $PATH')>0
           error('System call no1 failed') 
        end
    disp('------------------------------------------------------------------------------------------------------------------------')
    disp('Testing whether dcm2nii is found (you should see Chris Rordens dcm2nii help below:')
        if system('dcm2nii')>0
            error('System call to dcn2nii failed') 
        end

disp(['---------       01-02  FILE ORGANISATION AND NIFTI CONVERSION (',dateTime,')         ---------------------------------------------------------'])
    %first check the existence of the two initial folders
    if exist(subject_folderDICOM,'dir')==7; disp('Raw DICOM folder in Subject folder exists'); else error('Missing Raw DICOM folder in Subject folder...'); end
    if exist(subject_folderPAR,'dir')==7; disp('PAR folder in Subject folder exists'); else error('Missing PAR folder in Subject folder...'); end

    %check whether nifti conversion was already run successfully or not
    doNiftiConversion = 1; %default
    doReOrg = 1; %default
    if exist(subject_folderNIFTI,'dir')==7; 
        disp('dicom2vista_org.py was previously run and files reorganized (nifti folder detected) - so we skip that step and the next')
        doNiftiConversion = 0;
        doReOrg = 0;
    end
    %next block is skipped if previous condition was validated
    if doNiftiConversion==1 && exist([subject_folderDICOM,'/',rawDICOMfolder,'_backup'],'dir')==7; 
            disp('It seems that dicom2vista_org.py was previously run. What to do?'); 
            disp('1. Run again (will move folder back to where they should be)');
            disp('2. Skip (recommended)');
            disp('3. Escape');
        switch answer
            case {1} %go for it, so first move folders back to starting structure
                disp('Copying folder from backup back to raw dicom folder...')
                    [success, status]=copyfile([subject_folderDICOM,'/',rawDICOMfolder,'_backup/*'],subject_folderDICOM); if success; disp('Done');else error(status); end
                disp('Deleting old folders...')
                    [success, status]=rmdir([subject_folderDICOM,'/',rawDICOMfolder,'_backup'],'s'); if success; disp('Done');else error(status); end
                    [success, status]=rmdir([subject_folderDICOM,'/',rawDICOMfolder,'_nifti'],'s');  if success; disp('Done');else error(status); end
                    [success, status]=rmdir([subject_folderDICOM,'/',rawDICOMfolder,'_dicom'],'s');  if success; disp('Done');else error(status); end
            case {2} %dont go, move to next step
                doNiftiConversion = 0;
            case {3} %escape
                error('Voluntary interruption')
            otherwise
                error('Answer not understood')
        end
    end
    if doNiftiConversion; 
        disp('Starting dicom2vista_org.py...'); 
            success=system(['python dicom2vista_org.py ', subject_folderDICOM]); 
            if success==0 %GOOD
                disp('python dicom2vista_org.py: DONE'); 
            else %NOT GOOD
                error('Something went wrong with last step')
            end
        %check that nifti conversion was successful
        cd([subject_folderDICOM,'/',rawDICOMfolder,'_nifti']);
        [match,dummy] =  regexp(ls,'epi+\w+\.nii\.gz','match','split');%find all nii.gz files starting with epi
            if isempty(match)==0; disp('Nifti conversion seems successful: nifti files detected.'); else error('Unsuccessful nifti conversion'); end
        disp('Finished FILE ORGANISATION AND NIFTI CONVERSION')
    end

disp(['---------      03   REORGANISATION II   (',dateTime,')    ---------------------------------------------------------------------------'])
    %check whether reorganization was already run successfully or not
    if exist([subject_folder,'/',rawBackup],'dir')==7; 
        disp('You may have run the reorgaisation II code before (Raw DICOM backup folder detected). What to do?');  
        disp('2. Skip (recommended)');
        beep; answer = input('3. Escape ');
        switch answer
            case {2} %dont go, move to next step
                doReOrg = 0;
                disp('Skipped');
            case {3} %escape
                error('Voluntary interruption')
            otherwise
                error('Answer not understood')
        end
    end

    if doReOrg==1 %reorganisation II
        disp(['Creating backup folder: ', rawBackup])
            [success, status]=mkdir([subject_folder,'/',rawBackup]); if success; disp('Done');else error(status); end
        disp('Moving DICOM files to backup folder and back to initial folder')
            [success, status]=copyfile([subject_folderDICOM,'/',rawDICOMfolder,'_backup/*'],[subject_folder,'/',rawBackup]); if success; disp('Done');else error(status); end
            [success, status]=copyfile([subject_folderDICOM,'/',rawDICOMfolder,'_backup/*'],[subject_folder,'/',rawDICOMfolder]); if success; disp('Done');else error(status); end
        disp(['Creating nifti folder: ', niftiFolder])
            [success, status]=mkdir(subject_folderNIFTI); if success; disp('Done');else error(status); end
        disp('Moving nifti files to nifti folder')
            [success, status]=copyfile([subject_folderDICOM,'/',rawDICOMfolder,'_nifti/*'],subject_folderNIFTI); if success; disp('Done');else error(status); end
        disp('Deleting old folders...')
            [success, status]=rmdir([subject_folderDICOM,'/',rawDICOMfolder,'_backup'],'s'); if success; disp('Done');else error(status); end
            [success, status]=rmdir([subject_folderDICOM,'/',rawDICOMfolder,'_nifti'],'s');  if success; disp('Done');else error(status); end
            [success, status]=rmdir([subject_folderDICOM,'/',rawDICOMfolder,'_dicom'],'s');  if success; disp('Done');else error(status); end
        disp('Finished REORGANISATION II ')
    else
        disp('Reorganisation II skipped')
    end

disp(['---------      04A   MOTION CORRECTION    (',dateTime,')   ---------------------------------------------------------------------------'])
    %python motioncorrect.py [01_Raw_DICOM folder path]
    doMotionCorrection = 1; %default
    %check that nifti folder exists
    if ~(exist(subject_folderNIFTI,'dir')==7);  error('Missing nifti folder in Subject folder'); end
    
    %check whether code was already run successfully or not
    if exist(subject_folderMoco,'dir')==7;  disp('You may have run the MoCo code before (moco folder detected). What to do?'); 
        disp('2. Skip (recommended)');
            beep; answer = input('3. Escape ');
            switch answer
                case {2} %dont go, move to next step
                    doMotionCorrection = 0;
                    disp('Skipped');
                case {3} %escape
                    error('Voluntary interruption')
                otherwise
                error('Answer not understood')
            end            
    end
    if doMotionCorrection==1
        disp(['Creating MoCo folder and subfolders: ', mocoFolder])
            [success, status]=mkdir(subject_folderMoco); if success; disp('Done');else error(status); end
            %the py program needs that subfolder in the root folder
            [success, status]=mkdir([subject_folderMoco,'/',mocoFolder,'_nifti']); if success; disp('Done');else error(status); end 
            %it also needs this one to build a reference DICOM file
    %to do: LETS COPY ONLY EPI01 IN THAT DICOM
            [success, status]=mkdir([subject_folderMoco,'/',mocoFolder,'_dicom']); if success; disp('Done');else error(status); end 
        disp('Copying nifti files to MoCo subfolders...')
            [success, status]=copyfile([subject_folderNIFTI,'/*'],[subject_folderMoco,'/',mocoFolder,'_nifti']); if success; disp('Done');else error(status); end
            [success, status]=copyfile([subject_folderDICOM,'/*'],[subject_folderMoco,'/',mocoFolder,'_dicom']); if success; disp('Done');else error(status); end
        disp('Starting motioncorrect/SP.py in:'); 
        if exist([preprocessPath_alt '/motioncorrect_SP.py'],'file')==2
            cd(preprocessPath_alt); %if you have the file for updated motion correction, use it
            disp('Updated motion correction file found in megavista/zUsers/Sara/ will be used.');
            disp('This will align all epi files to the middle volume of the middle epi.');
            disp('Press any key to continue. Cancel the process if you wish to use a different motion correction method.');
            disp('Starting...')
            beep; pause;
            success = system(['python motioncorrect_SP.py ', subject_folderMoco]);
        else 
            cd(preprocessPath); %otherwise use old version to align to epi01
            disp('Old motion correction file found in megavista/silverlab_vista_tools/python_preproc will be used.');
            disp('This will align all epi files to the first volume of the first epi.');
            disp('Press any key to continue. Cancel the process if you wish to use a different motion correction method.');
            beep; pause;
            disp('Starting...')
            success = system(['python motioncorrect.py ', subject_folderMoco]);
        end 
             
        if success==0 %GOOD
                disp('python motioncorrect/SP.py: DONE'); 
                % CHECK PARAMS HERE
                %Need to write voxel size to a .txt file for
                %motionparams.py to read in for the version in zUsers/Sara
                first_epi_file = dir([subject_folderNIFTI '/epi01*']);
                ni = readFileNifti([subject_folderNIFTI '/' first_epi_file.name]);
                voxel_size = ni.pixdim(1:3);
                fileID = fopen([subject_folderMoco '/' mocoFolder '_nifti/voxelinfo.txt'],'w');
                fprintf(fileID,'%8.5f',voxel_size);
                fclose(fileID);
                disp('Please check the motion correction results...')
%                 cd(preprocessPath);
                success = system(['python motionparams_SP.py ', subject_folderMoco]);
                if success==0 %GOOD
                    disp('python motionparams/SP.py: DONE')
                    beep; answer = input('Figure: Is everything OK? (y)es / (n)o: ', 's');
                    if strcmpi(answer, 'n')==1; error('Something went wrong, according to you...');end
                else %NOT GOOD
                    error('python motionparams/SP.py: Something went wrong with last step')
                end
        else %NOT GOOD
            error('python motioncorrect/SP.py: Something went wrong with last step')
        end
        disp('Moving files back to moco root folder...')
                [success, status]=copyfile([subject_folderMoco,'/',mocoFolder,'_nifti/*'],subject_folderMoco); if success; disp('Done');else error(status); end
        disp('Deleting old folders...')
                [success, status]=rmdir([subject_folderMoco,'/',mocoFolder,'_nifti'],'s'); if success; disp('Done');else error(status); end
                [success, status]=rmdir([subject_folderMoco,'/',mocoFolder,'_dicom'],'s'); if success; disp('Done');else error(status); end

        %CHECK SUCCESS here (presence of MCF FILES)
        %for that, find any file that matches ('*_mcf.nii.gz')
            cd(subject_folderMoco);
            [match,dummy] =  regexp(ls,'epi+\w+_mcf\.nii\.gz','match','split');%find all nii.gz files containing word mcf
            if isempty(match)==0; disp('Motion correction seems successful: mcf files detected.'); else error('Unsuccessful motion correction'); end
       disp('Finished MOTION CORRECTION')
    end
    
    disp(['---------      04B  MOTION CORRECTION CHECK   (',dateTime,')   ---------------------------------------------------------------------------'])
    doMotionCorrectionCheck = 1; %default
    %check that nifti folder exists
    if ~(exist(subject_folderMoco,'dir')==7);  error('Missing Moco folder in Subject folder'); end
    
    %check whether code was already run successfully or not
    if exist(subject_folderMocoCheck,'dir')==7;  disp('You may have run the MoCo Check test code before (moco check folder detected). What to do?'); 
        disp('1. Start this step over (delete existing 04B folder)');
        disp('2. Skip (recommended)');
            beep; answer = input('3. Escape ');
            switch answer
                case {1} %delete subject_folderMocoCheck
                    %added because deleting this folder manually everytime
                    %i wanted to redo this step during debugging was very
                    %annoying -- Sara Popham
                    %ERROR HERE - [success, status]=rmdir([subject_folderMocoCheck,'/',mocoCheckFolder,'_nifti'],'s'); if success; disp('Deleted');else error(status); end
                    [success, status]=rmdir(subject_folderMocoCheck,'s'); if success; disp('Deleted');else error(status); end
                case {2} %dont go, move to next step
                    doMotionCorrectionCheck = 0;
                    disp('Skipped');
                case {3} %escape
                    error('Voluntary interruption')
                otherwise
                error('Answer not understood')
            end            
    end
    
    if doMotionCorrectionCheck==1
        disp(['Creating MoCo Check folder and subfolders: ', mocoCheckFolder])
            [success, status]=mkdir(subject_folderMocoCheck); if success; disp('Done');else error(status); end
            %the py program needs that subfolder in the root folder
            [success, status]=mkdir([subject_folderMocoCheck,'/',mocoCheckFolder,'_nifti']); if success; disp('Done');else error(status); end 
            [success, status]=mkdir([subject_folderMocoCheck,'/',mocoCheckFolder,'_dicom']); if success; disp('Done');else error(status); end 
        disp('Copying nifti files to MoCo subfolders...')
            [success, status]=copyfile([subject_folderMoco,'/*_mcf.nii.gz'],[subject_folderMocoCheck,'/',mocoCheckFolder,'_nifti']); if success; disp('Done');else error(status); end
            [success, status]=copyfile([subject_folderDICOM,'/epi*'],[subject_folderMocoCheck,'/',mocoCheckFolder,'_dicom']); if success; disp('Done');else error(status); end
        %rename epi_whatever to epi_whatever_mcf
        epiFolders = dir([subject_folderMocoCheck,'/',mocoCheckFolder,'_dicom/epi*']);
        for i=1:length(epiFolders)
            movefile([subject_folderMocoCheck,'/',mocoCheckFolder,'_dicom/',epiFolders(i).name],[subject_folderMocoCheck,'/',mocoCheckFolder,'_dicom/',epiFolders(i).name,'_mcf']);
        end
            disp('Starting motioncorrect/SP.py in:');
        if exist([preprocessPath_alt '/motioncorrect_SP.py'],'file')==2
            cd(preprocessPath_alt); %if you have the file for updated motion correction, use it
            disp('Updated motion correction file found in megavista/zUsers/Sara/ will be used.');
            disp('This will align all epi files to the middle volume of the middle epi.');
            disp('Press any key to continue. Cancel the process if you wish to use a different motion correction method.');
            beep; pause;
            disp('Starting...')
            success = system(['python motioncorrect_SP.py ', subject_folderMocoCheck]); 
        else 
            cd(preprocessPath); %otherwise use old version to align to epi01
            disp('Old motion correction file found in megavista/silverlab_vista_tools/python_preproc will be used.');
            disp('This will align all epi files to the first volume of the first epi.');
            disp('Press any key to continue. Cancel the process if you wish to use a different motion correction method.');
            beep; pause;
            disp('Starting...')
            success = system(['python motioncorrect.py ', subject_folderMocoCheck]); 
        end  
        if success==0 %GOOD
               disp('python motioncorrect/SP.py: DONE'); 
                   % CHECK PARAMS HERE
                disp('Please check the motion correction results...')
                [success, status] = copyfile([subject_folderMoco '/voxelinfo.txt'],[subject_folderMocoCheck '/' mocoCheckFolder '_nifti/voxelinfo.txt']);
                if success; disp('voelinfo.txt file copied...');else error(status); end
                success = system(['python motionparams_SP.py ', subject_folderMocoCheck]);
                if success==0 %GOOD
                    disp('python motionparams/SP.py: DONE')
                    beep; answer = input('Figure: Is everything OK? (y)es / (n)o: ', 's');
                    if strcmpi(answer, 'n')==1; error('Something went wrong, according to you...');end
                else %NOT GOOD
                    error('python motionparams/SP.py: Something went wrong with last step')
                end
        else %NOT GOOD
            error('python motioncorrect/SP.py: Something went wrong with last step')
        end
        disp('Moving files back to mococheck root folder...')
                [success, status]=copyfile([subject_folderMocoCheck,'/',mocoCheckFolder,'_nifti/*'],subject_folderMocoCheck); if success; disp('Done');else error(status); end
        disp('Deleting old folders...')
                [success, status]=rmdir([subject_folderMocoCheck,'/',mocoCheckFolder,'_nifti'],'s'); if success; disp('Done');else error(status); end
                [success, status]=rmdir([subject_folderMocoCheck,'/',mocoCheckFolder,'_dicom'],'s'); if success; disp('Done');else error(status); end

        %CHECK SUCCESS here (presence of MCF_MCF FILES)
        %for that, find any file that matches ('*mcf_mcf.nii.gz')
            cd(subject_folderMocoCheck);
            [match,dummy] =  regexp(ls,'epi+\w+mcf_mcf\.nii\.gz','match','split');%find all nii.gz files containing word mcf
            if isempty(match)==0; disp('Motion correction check seems successful: mcf files detected.'); else error('Unsuccessful motion correction check'); end
       disp('Finished MOTION CORRECTION CHECK')
    end
    
    disp(['---------     05    RENAMING 1 / FIX NIFTI HEADERS  (',dateTime,')     ------------------------------------------------------------'])
        renaming1 = 1; %default
        %check that nifti folder exists
            if ~(exist(subject_folderNIFTI,'dir')==7);  error('Missing nifti folder in Subject folder'); end
            if ~(exist(subject_folderMoco,'dir')==7);  error('Missing moco folder in Subject folder'); end
            
            %check whether code was already run successfully or not
            if exist(subject_folderNiftiFx,'dir')==7;  disp('You may have run the renaming 1 / nifti fix code before (niftiFixedFolder detected). What to do?'); 
                disp('2. Skip (recommended)');
                    beep; answer = input('3. Escape ');
                    switch answer
                        case {2} %dont go, move to next step
                            renaming1 = 0;
                            disp('Skipped');
                        case {3} %escape
                            error('Voluntary interruption')
                        otherwise
                            error('Answer not understood')
                    end            
            end
        if renaming1==1
            disp(['Creating ',niftiFixedFolder,' folder...'])
                [success, status]=mkdir(subject_folderNiftiFx); if success; disp('Done');else error(status); end               
            disp(['Copying moco nifti files to : ',niftiFixedFolder])
                cd(subject_folderMoco);
                [match,dummy] =  regexp(ls,'epi+\w+_mcf\.nii\.gz','match','split');%find all nii.gz files containing word mcf
                for i=1:numel(match)
                   [success, status]=copyfile(match{i},subject_folderNiftiFx); if success; disp('Done');else error(status); end
                end
            disp(['Copying gems and mprage from nifti folder to: ',niftiFixedFolder])
                cd(subject_folderNIFTI);
                [matchMPRAGE,dummy] =  regexp(ls,'^((?<![co])\w*)mprage\w*\.nii\.gz','match','split'); %find all nii.gz files containing word mprage except ones starting by co and o
                [matchGEMS,dummy] =  regexp(ls,'gems\w*\.nii\.gz','match','split'); %find all nii.gz files containing word gems
                for i=1:numel(matchMPRAGE)
                       [success, status]=copyfile(matchMPRAGE{i},subject_folderNiftiFx); if success; disp('Done');else error(status); end
                end
                for i=1:numel(matchGEMS)
                       [success, status]=copyfile(matchGEMS{i},subject_folderNiftiFx); if success; disp('Done');else error(status); end
                end
             disp('Renaming mprage file to mprage.nii.gz')
                  cd(subject_folderNiftiFx);
                 if numel(matchMPRAGE)>1
                     error('More than one mprage file found...')
                 else
                     [success, status]=movefile(matchMPRAGE{1},'mprage.nii.gz'); if success; disp('Done');else error(status); end
                 end
             disp('Renaming gems* file to gems.nii.gz')
                  cd(subject_folderNiftiFx);
                 if numel(matchGEMS)>1
                     error('More than one gems file found...')
                 else
                     if strcmpi(matchGEMS{1},'gems.nii.gz')==0
                        [success, status]=movefile(matchGEMS{1},'gems.nii.gz'); if success; disp('Done');else error(status); end
                     else
                        disp('Gems file is already called gems.nii.gz.')
                     end
                 end
        
            % FIX HEADERS
                 beep; answer = input('Have you edited niftiFixHeader2 for your needs? (y)es/(n)o: ','s');
                 if strcmpi(answer,'n'); error('Please proceed and edit the code before fixing headers...');end
            doFixHeaders = 1; %default
            %check whether code was already run successfully or not
                cd(subject_folderNiftiFx)
                if exist('epiHeaders_FIXED.txt','file')==2;  disp('CAREFUL: You may have run the -fixing header- code before on these same files (epiHeaders_FIXED.txt detected). What to do?'); 
                    disp('1. Do it again (first remove epiHeaders_FIXED.txt file)');
                    disp('2. Skip (recommended)');
                        beep; answer = input('3. Escape ');
                        switch answer
                            case {1} %move on
                                delete('epiHeaders_FIXED.txt');
                            case {2} %dont go, move to next step
                                doFixHeaders = 0;
                                disp('Skipped');
                            case {3} %escape
                                error('Voluntary interruption')
                            otherwise
                                error('Answer not understood')
                        end            
                end
            if doFixHeaders == 1
                 disp('Fixing headers')
                    niftiFixHeader2(subject_folderNiftiFx);
                    if exist('epiHeaders_FIXED.txt','file')==2
                        disp('Header fixing was successful.')
                    else
                        error('Some files could not be fixed')
                    end
                    disp('Take some time here to check that the headers are all OK (freq_dim/phase_dim/slice_duration should not be OK for gems/mprage). Press any key.'); beep; pause;
            end
        end
  
      disp(['---------     06   Start of mrVista session   (',dateTime,')    -------------------------------------------------------------------'])
       doMrVista = 1; %default
       %check that nifti folder exists
            if ~(exist(subject_folderPAR,'dir')==7);  error('Missing PAR folder in Subject folder (for par files)'); end
            if ~(exist(subject_folderNiftiFx,'dir')==7);  error('Missing fixed nifti folder in Subject folder'); end
            
            %check whether code was already run successfully or not
            if exist([subject_folderVista,'/Inplane'],'dir')==7;  disp('You may have run the mrVista code before (subject_folderVista/Inplane detected). What to do?'); 
                disp('2. Skip (recommended)');
                    beep; answer = input('3. Escape ');
                    switch answer
                        case {2} %dont go, move to next step
                            doMrVista = 0;
                            disp('Skipped');
                        case {3} %escape
                            error('Voluntary interruption')
                        otherwise
                            error('Answer not understood')
                    end            
            end
       if doMrVista == 1
           disp('Creating nifti folder, for epi, gems, and mprage')
                [success, status]=mkdir([subject_folderVista,'/nifti']); if success; disp('Done');else error(status); end
           disp('Creating Parfiles folder, for par files')
                [success, status]=mkdir([subject_folderVista,'/Stimuli/Parfiles']); if success; disp('Done');else error(status); end
           disp('Copying files to nifti and Parfiles subfolders')
                cd(subject_folderNiftiFx);
                [match,dummy] =  regexp(ls,'\w+\.nii\.gz','match','split');%find all nii.gz files
                for i=1:numel(match)
                   [success, status]=copyfile(match{i},[subject_folderVista,'/nifti']); if success; disp('Done');else error(status); end
                end
                cd(subject_folderPAR);
                for i=1:numel(match)
                   [success, status]=copyfile('*',[subject_folderVista,'/Stimuli/Parfiles']); if success; disp('Done');else error(status); end
                end
           disp('Running adapted Kelly/Winaver code to inialize a mrVista session...')
                kb_initializeVista2(subject_folderVista, subjectID)
           disp('Lets check that...') %the success of initialization
                cd(subject_folderVista);
                if exist('mrSESSION.mat','file')==2 && exist('mrSESSION_backup.mat','file')==2 && exist('mrInit2_params.mat','file')==2 &&...
                        exist('Inplane','dir')==7 && exist('Inplane/anat.mat','file')==2 
                    disp('Success confirmed')
                else
                    error('Some files/folders are missing')
                end
       end
 

    
disp(['***********       PIPELINE FINISHED  AT  ', dateTime,' for subjectID ', subjectID,'       *******************'])
beep;
