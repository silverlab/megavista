
startupFile = '/home/span/matlabfiles/startup.m';
run(startupFile);


%%
baseDir = '/biac2b/data1/finra/session2/';
subs = {'bg031710','jo042210','kc031610','kk030910','mc032510','md032310','na032310'};

for ii=1:numel(subs)
    subDir = fullfile(baseDir,subs{ii});
    dtDir = dir(subDir);
    dtDir = dtDir(3).name;
    dtDir = fullfile(subDir,dtDir);
    rawDir = fullfile(dtDir,'raw');

    if ~exist(rawDir,'file'), mkdir(rawDir), disp(['Created ' rawDir]); end
    if ~exist(fullfile(rawDir,'006'),'file'), cd(dtDir), system('mv 00* raw'); end

    disp(['Data Directory = ' dtDir]);

    %% Process Raw DTI
    ni006 = fullfile(rawDir,'dti_g87_b900_006.nii.gz');
    ni007 = fullfile(rawDir,'dti_g87_b900_007.nii.gz');
    ni013 = fullfile(rawDir,'dti_g87_b900.nii.gz');

    % Iff the nifti files don't exist we create them
    if ~exist(ni006,'file') && ~exist(ni007,'file')
        cd(rawDir);
       
            disp('Creating raw nifti files. Be patient...');
            
            [status,result] = unix('dinifti -g -s 60 006 dti_g87_b900_006','-echo');
            disp(status);
            [status,result] = unix('dinifti -g -s 60 007 dti_g87_b900_007','-echo');
            disp(status);
            
        else disp('Nifti files already created with dinifti: exist = true');
    end

    if ~exist(ni013,'file')
        disp('Combining raw nifti files...');
        cd(rawDir);
        ni1 = readFileNifti('dti_g87_b900_006.nii.gz');
        ni2 = readFileNifti('dti_g87_b900_007.nii.gz');
        ni1.data = cat(4, ni1.data, ni2.data);
        ni1.fname = 'dti_g87_b900.nii.gz';
        writeFileNifti(ni1);
        
        if exist(ni013,'file'), disp(['Successfully created ' ni1.fname]); else disp('Something went wrong combining the raw nifti files in matlab'); end
        
        clear ni1 ni2
    end

    %% Process Raw T1
    if ~exist(fullfile(dtDir,'t1.nii.gz'),'file') && ~exist(fullfile(dtDir,'t1acpc.nii.gz'),'file') && ~exist(fullfile(rawDir,'t1'),'file')
        cd(dtDir)
        disp('Creating the t1 nifti file');
        niftiFromDicom('raw/005','raw/t1');
    end
    
    
    %% Run the preprocessing
    if exist(fullfile(dtDir,'t1acpc.nii.gz'),'file') && ~exist(fullfile(dtDir,'dti40'),'file')
        cd(dtDir);
        disp('Running dtiRawPreprocess. This will take some time ...');
        dtiRawPreprocess('raw/dti_g87_b900.nii.gz','t1acpc.nii.gz',.9,87,'false',[],[],[],[],[],true)
    end
end
