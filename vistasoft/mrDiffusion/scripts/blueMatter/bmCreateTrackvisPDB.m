function [fg] = bmCreateTrackvisPDB(subjectDir,numSeeds)
%Create Trackvis PDB for BlueMatter tests.
%
%   nfgCreateTrackvisPDB(subjectDir)
%
% 
% AUTHORS:
%   2009.09.05 : AJS wrote it
%
% NOTES: 


% Directories
trkDir = bmGetName('trkDir',subjectDir);
% Input Files
bvalsFile = bmGetName('bvalsFile',subjectDir);
bvecsFile = bmGetName('bvecsFile',subjectDir);
rawFile = bmGetName('rawFile',subjectDir);
wmTrkROIFile = bmGetName('wmTrkROIFile',subjectDir);
ctrparamsFile = bmGetName('ctrparamsFile',subjectDir);
% Output Files
trkGradFile = bmGetName('trkGradFile',subjectDir);
trkImg = bmGetName('trkImg',subjectDir);
trkHardiMatFile = bmGetName('trkHardiMatFile',subjectDir);
trkOdfReconRoot = bmGetName('trkOdfReconRoot',subjectDir);
trkTRKFile = bmGetName('trkTRKFile',subjectDir);
trkPDBFile = bmGetName('trkPDBFile',subjectDir);

if ~isdir(trkDir)
    disp(' '); disp('Setting up Trackvis files...');
    mkdir(trkDir);
    
    % Convert bvals and bvecs into trackvis grad table and get b=0 measurements
    % in front of data.
    disp(' '); disp('Converting bvals and bvecs files to TrackVis format ...');
    bvals = load(bvalsFile,'-ascii');
    bvecs = load(bvecsFile,'-ascii');
    % Get the data
    data = readFileNifti(rawFile);
    
    % Get b0 to the front of the data
    bvals = bvals(:)';
    bvecs = cat(2, bvecs(:,bvals==0), bvecs(:,bvals~=0));
    data.data = cat(4, data.data(:,:,:,bvals==0), data.data(:,:,:,bvals~=0));
    bvals = [bvals(bvals==0) bvals(bvals~=0)];
    
    % Write out trackvis grad table file and data
    numb0 = sum(bvals==0);
    numdirs = length(bvals) - numb0;
    dlmwrite(trkGradFile,bvecs(:,numb0+1:end)', ',');
    data.fname = trkImg;
    writeFileNifti(data);
    
    % Now call the hardi reconstruction program
    cmd = ['hardi_mat ' trkGradFile ' ' trkHardiMatFile];
    disp(' '); disp(cmd);
    system(cmd,'-echo');
    % Now call the odf reconstruction program
    cmd = ['odf_recon ' trkImg ' ' num2str(numdirs) ' 181 ' trkOdfReconRoot ' -mat ' trkHardiMatFile ' -b0 ' num2str(numb0)];
    disp(' '); disp(cmd);
    system(cmd,'-echo');
end

disp(' '); disp('Using the HARDI ODF tracker...');
% Now call the odf tracking program
cmd = ['odf_tracker '  trkOdfReconRoot ' ' trkTRKFile ' -m ' wmTrkROIFile ' -ix' ' -rseed ' num2str(numSeeds) ' -at 35'];
%cmd = ['odf_tracker '  trkOdfReconRoot ' ' trkTRKFile ' -m ' wmTrkROIFile ' -ix'];
disp(' '); disp(cmd);
system(cmd,'-echo');
% Now convert it to PDB file
mtrTrackVis2PDB(wmTrkROIFile, trkTRKFile, trkPDBFile);

% Now limit the fibers to those that connect the gray matter
% Call contrack_score to limit fibers to those intersecting the GM ROI
disp('Removing fibers that do not have both endpoints in GM ROI ...');
pParamFile = [' -i ' ctrparamsFile];
pOutFile = [' -p ' trkPDBFile];
pInFile = [' ' trkPDBFile];
pThresh = [' --thresh ' num2str(10000000)];
cmd = ['contrack_score' pParamFile pOutFile pThresh ' --find_ends' pInFile];
disp(cmd);
%system(cmd,'-echo');

%fg = mtrImportFibers(trkPDBFile);

return;
