% dti_MIND_RePreprocess.m
%
% This script will read in a list of subjects (subCodeList) and run
% dtiRawPreprocess (with tri-linear interpolation) on each of those
% subjects. After this step, dtiRawFitTensor.m will be run with robust
% tensor fitting set to 'on', which implements the RESTORE algorithm. If a
% subject has been run through dtiRawPreprocess.m (and dti30trilin/dt6.mat
% exists) only dtiRawFitTensor.m will be run on that subject. 
% 
% The code assumes a few things:
% 1. All the subjectes directories are in the same directory (baseDir).
% 2. All subjects were scanned with the same protocol.
% 3. All dti data has been run through dcm2nii and is in the raw directory
%    with a raw dti nifti file name that ends with 001.nii.gz (let michael know
%    if this is not the case).
% 4. The t1 file is saved in a t1 directory. (eg.
%    subCode/t1/subCode_t1.nii.gz).
% 5. Assumed data structure. 
%    *subCode*/raw/*rawDtiData*.nii.gz
%    *subCode*/raw/*rawDtiData*.bvals
%    *subCode*/raw/*rawDtiData*.bvecs
%    *subCode*/t1/*subCode*t1.nii.gz
% 6. Should leave you with:
%    *subCode*/dti30trilin/dt6.mat...
%    *subCode*/dti30trilinrt/dt6.mat...%    
% 
% dtiRawPreprocess(dwRawFileName, t1FileName, bvalue, gradDirsCode, clobber, dt6BaseName, assetFlag, numBootStrapSamples, eddyCorrect, excludeVols, bsplineInterpFlag, phaseEncodeDir))
% dtiRawFitTensor([dwRaw=uigetfile],[bvecsFile=uigetfile], [bvalsFile=uigetfile], [outBaseDir=uigetdir],[bootstrapParams=[]], [fitMethod='ls'],[adcUnits=dtiGuessAdcUnits], [xformToAcPc=dwRaw.qto_xyz])
% 
%
% HISTORY:
% 09.11.09 - LMP wrote the thing. (dtiPreProcessMIND)
% 12.01.09 - LMP included some code that removes old directories and files
% so that a new alignement is computed, and robust tensor fitting is done
% on the newly aligned data.


%% Run Preprocessing
baseDir = '/home/christine/APP/stanford_DTI/';
subCodeList = '/home/christine/APP/stanford_DTI/APPlist.txt';
subs = textread(subCodeList, '%s'); fprintf('\nWill process %d subjects...\n\n',numel(subs));
outDir = 'dti30trilin';

for ii=1:length(subs)
    disp(['Processing (' subs{ii} ')...']);
    
    subDir = fullfile(baseDir,subs{ii});
    
    rawDir = fullfile(subDir,'raw');
    t1Dir = fullfile(subDir,'t1');
    cd(t1Dir)
    t1 = dir([subs{ii},'*t1.nii.gz']);
    t1 = fullfile(t1Dir,t1.name);
    
    % Remove the aligned files, as well as the xFormToAcpc.mat and the
    % dti30* directories.
    cd(subDir)
    system('rm -rf dti30*');     
    cd(rawDir)
    system('rm -f *acpcXform.mat *aligned*.nii.gz');
    
    % Assuems that the file with 001.nii.gz at the end is
    % the raw nifti file.
    nifti = dir('*001.nii.gz');
    niftiRaw = fullfile(rawDir,nifti.name);
    
    if ~exist(fullfile(subDir,outDir),'file')
        try
            outName = fullfile(subDir, outDir);
            % Run initial preprocessing.
            dtiRawPreprocess(niftiRaw, t1, [], [], false, outDir, [], [], [], [], false, 2);
            [tmp outBaseDir] = fileparts(niftiRaw);
            [junk outBaseDir] = fileparts(outBaseDir);
            outBaseDir = fullfile(tmp,[outBaseDir,'_aligned_trilin']);
            % fit the tensor again with the RESTORE method.
            dtiRawFitTensor([outBaseDir '.nii.gz'], [outBaseDir '.bvecs'], [outBaseDir '.bvals'], [outName 'rt'], [], 'rt');
        catch ME
            disp('FAILED.');
        end
    else
        disp(['This subject, ' subs{ii} ', has already been processed through dtiRawPreProcess.m']);
        if exist(fullfile(subDir,outDir),'file') && ~exist(fullfile(subDir,[outDir 'rt']),'file')
            disp(['Running RESTORE algorithm on ',subs{ii}, '!']);
            try
                [tmp outBaseDir] = fileparts(niftiRaw);
                [junk outBaseDir] = fileparts(outBaseDir);
                outBaseDir = fullfile(tmp,[outBaseDir,'_aligned_trilin']);
                dtiRawFitTensor([outBaseDir '.nii.gz'], [outBaseDir '.bvecs'], [outBaseDir '.bvals'], [dt 'rt'], [], 'rt');
            catch ME
                disp('FAILED.');
            end
        end
    end
end

disp('***DONE!***');

return
