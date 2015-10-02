function niftiFixHeader(dataDir)
% 07.01.15
% Kelly Byrne
% modified version - Adrien Chopin, 2015

%the function opens the below directory and find all COMPRESSED nifty files to fix them

    % %the function opens the below directory and find all directory in it
    % %then it goes through each one and find all nifty files to fix them
if ~exist('dataDir','var')==1
    dataDir = cd;
end
cd(dataDir)
% files = dir;
% directoryNames = {files([files.isdir]).name}; %makes a list of dir in the dir
% directoryNames = directoryNames(~ismember(directoryNames,{'.','..'})); %remove the . and .. dirs
% nCases = length(directoryNames);
% for k = 1:nCases %go through each dir and find the nii files
   % casePath = [dataDir filesep directoryNames{k} filesep 'nifti'];
   % cd(casePath)
   fixed = 0;
   disp(['Looking for nii files in ', dataDir])
   fileList = dir;
   fileListName = {fileList.name};
   niiFileList={}; %this is a list of nii files for that dir
   for i = 1:numel(fileListName)
       if numel(fileListName{i})>3 && strcmp(fileListName{i}(end-5:end),'nii.gz')==1 
           niiFileList{end+1} = fileListName{i}; 
       end
   end
if numel(niiFileList)>0
   disp('Will now fix the following files:') 
   disp(niiFileList')
   
    for j=1:numel(niiFileList)
        ni = readFileNifti(niiFileList{j});
       % if ismember(ni.descrip,{'GEMS_stam','epi_stam'})
       if strcmp(ni.fname(1:3),'epi') || strcmp(ni.fname(1:3),'gem')
            ni.qform = 1; %we used method 3, which is why we assign both qform and sform to 1
            ni.sform = 1; %you could decide differently
            %However, if method 2 was used on your nifti conversion, you will get
            %an error when you force method 3 here in nifti header because it will copy
            %below the null sto_xyz to the qto_xyz
            ni.freq_dim = 1;
            ni.phase_dim = 2;
            ni.slice_dim = 3;
            ni.slice_end = 37; %(number of slices-1)
            ni.slice_duration = 0.059257; %(TR/#slices)
            if ni.sform==1
                ni.qto_xyz = ni.sto_xyz; 
            else
                ni.sto_xyz = ni.qto_xyz; 
            end
            writeFileNifti(ni);
            disp(['EPI or GEMS file ', niiFileList{j},' is fixed'])
            checkNifti(niiFileList{j})
            fixed = 1;
       elseif strcmp(ni.fname(1:3),'mpr')
            ni.qform = 1; %we used method 3, which is why we assign both qform and sform to 1
            ni.sform = 1; %you could decide differently
            %However, if method 2 was used on your nifti conversion, you will get
            %an error when you force method 3 here in nifti header because it will copy
            %below the null sto_xyz to the qto_xyz
            ni.freq_dim = 2;
            ni.phase_dim = 1;
            ni.slice_dim = 3;
            ni.slice_end = 159; %(number of slices-1)
            ni.slice_duration = 0; %(TR/#slices) CHECK THAT 0.014375
            if ni.sform==1
                ni.qto_xyz = ni.sto_xyz; 
            else
                ni.sto_xyz = ni.qto_xyz; 
            end
            writeFileNifti(ni);
            disp(['MPRAGE file ', niiFileList{j},' is fixed'])
            checkNifti(niiFileList{j})
            fixed = 1;
        else
            disp(['Non-recognized file ', niiFileList{j},' is skipped'])
        end
    end
   
else
       disp('No nii.gz files found')
end
   
    if fixed == 1
            % leave a log file
        fid = fopen('epiHeaders_FIXED.txt', 'at');
        fprintf(fid, datestr(now));
        %fprintf(fid, 'Files fixed are:/n');
        %fprintf(fid, );
        fclose(fid);
    end
    
%end
