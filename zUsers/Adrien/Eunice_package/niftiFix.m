% 07.01.15
% Kelly Byrne

dataDir = 'C:\Users\Adrien Chopin\Desktop\fMRI\data\RN31\nifti_manual\nifti\';
files = dir;
directoryNames = {files([files.isdir]).name};
directoryNames = directoryNames(~ismember(directoryNames,{'.','..'}));
nCases = length(directoryNames);
for k = 1:nCases
    casePath = [dataDir filesep directoryNames{k} filesep 'nifti'];
    cd(casePath)
    % localizer
    ni = readFileNifti('epi01_localizer_mcf.nii.gz');
    ni.qform = 1;
    ni.sform = 1;
    ni.freq_dim = 1;
    ni.phase_dim = 2;
    ni.slice_dim = 3;
    ni.slice_end = 15; %(number of slices-1)
    ni.slice_duration = 0.0625; %(TR/#slices)
    writeFileNifti(ni);

    % plaids
    ni = readFileNifti('epi02_plaid1_mcf.nii.gz');
    ni.qform = 1;
    ni.sform = 1;
    ni.freq_dim = 1;
    ni.phase_dim = 2;
    ni.slice_dim = 3;
    ni.slice_end = 15; %(number of slices-1)
    ni.slice_duration = 0.0625; %(TR/#slices)
    writeFileNifti(ni);

    ni = readFileNifti('epi03_plaid2_mcf.nii.gz');
    ni.qform = 1;
    ni.sform = 1;
    ni.freq_dim = 1;
    ni.phase_dim = 2;
    ni.slice_dim = 3;
    ni.slice_end = 15; %(number of slices-1)
    ni.slice_duration = 0.0625; %(TR/#slices)
    writeFileNifti(ni);

    % leave a log file
    fid = fopen('epiHeaders_FIXED.txt', 'at');
    fprintf(fid, datestr(now));
    fclose(fid);
end
