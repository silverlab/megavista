function niftiFixHeader2(dataDir)
% 07.01.15
% Kelly Byrne
% modified version - Adrien Chopin, 2015

%the function opens the below directory and find all COMPRESSED nifty files
%to fix them, if their names start with keywords epi, gems or nu (for mprage)

    % %the function opens the below directory and find all directory in it
    % %then it goes through each one and find all nifty files to fix them
if ~exist('dataDir','var')==1
    dataDir = '/Users/adrienchopin/Desktop/Big_data_STAM/RN31/pre1/test2/nifti/';
end
cd(dataDir)
% files = dir;
% directoryNames = {files([files.isdir]).name}; %makes a list of dir in the dir
% directoryNames = directoryNames(~ismember(directoryNames,{'.','..'})); %remove the . and .. dirs
% nCases = length(directoryNames);
% for k = 1:nCases %go through each dir and find the nii files
   % casePath = [dataDir filesep directoryNames{k} filesep 'nifti'];
   % cd(casePath)
   fixed = 1;
   disp(['Looking for nii files in ', dataDir])
   fileList = dir;
   fileListName = {fileList.name};
   niiFileList={}; %this is a list of nii files for that dir
   for i = 1:numel(fileListName)
       if numel(fileListName{i})>5 && strcmp(fileListName{i}(end-5:end),'nii.gz')==1 %min of 6 letters for the name
           niiFileList{end+1} = fileListName{i};
       end
   end
if numel(niiFileList)>0
   disp('Will now fix the following files:') 
   disp(niiFileList')
   
    for j=1:numel(niiFileList)
        ni = readFileNifti(niiFileList{j});
       % if ismember(ni.descrip,{'GEMS_stam','epi_stam'})
       if strcmp(ni.fname(1:3),'epi') || strcmp(ni.fname(1:4),'gems')
            ni.qform = 1; %we used method 3, which is why we assign both qform and sform to 1
            ni.sform = 1; %you could decide differently
            %However, if method 2 was used on your nifti conversion, you will get
            %an error when you force method 3 here in nifti header because it will copy
            %below the null sto_xyz to the qto_xyz
            ni.freq_dim = 1; % i is 1, j is 2, k is 3
            ni.phase_dim = 2; 
            ni.slice_dim = 3;
            ni.slice_end = 37; %(number of slices-1)
            if length(ni.pixdim)>3 % pixdim(4) = TR    %EPI
                TR = ni.pixdim(4);
            else %GEMS
                TR = 0; %to be safe, given the error with mprage (but we are not sure this is actually correcting an error for gems)
            end
            disp(['Check that your TR is: ',num2str(TR), ' sec'])
            ni.slice_duration = TR/(ni.slice_end+1); %(TR/#slices)
            if ni.sform==1
                ni.qto_xyz = ni.sto_xyz; 
            else
                ni.sto_xyz = ni.qto_xyz; 
            end
            writeFileNifti(ni);
            disp(['EPI or GEMS file ', niiFileList{j},' is fixed'])
            checkNifti(niiFileList{j})
       elseif strcmp(ni.fname(1:2),'nu') %MPRAGE
            ni.qform = 1; %we used method 3, which is why we assign both qform and sform to 1
            ni.sform = 1; %you could decide differently
            %However, if method 2 was used on your nifti conversion, you will get
            %an error when you force method 3 here in nifti header because it will copy
            %below the null sto_xyz to the qto_xyz
            ni.freq_dim = 0; %O for mprage because no phase/freq encoding (it's specific to EPI)
            ni.phase_dim = 0; %O for mprage because no phase/freq encoding (it's specific to EPI)
            ni.slice_dim = 3;
            ni.slice_end = 159; %(number of slices-1)
            ni.slice_duration = 0; % it has to be 0 to avoid slice timing correction and some further error
            if ni.sform==1
                ni.qto_xyz = ni.sto_xyz; 
            else
                ni.sto_xyz = ni.qto_xyz; 
            end
            writeFileNifti(ni);
            disp(['MPRAGE nu file ', niiFileList{j},' is fixed'])
            checkNifti(niiFileList{j})
        else
            disp(['Non-recognized file ', niiFileList{j},' is skipped'])
            fixed = 0;
        end
    end
   
else
       disp('No nii.gz files found')
       fixed = 0;
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
