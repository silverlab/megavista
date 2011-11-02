function pbcSetupMRDiffusion(brainDir)
%Setup mrDiffusion files for BlueMatter Pgbh tests.
%
%   nfgSetupMRDiffusion(phantomDir)
%
% 
% AUTHORS:
%   2009.09.05 : AJS wrote it
%
% NOTES: 
%

% Directories
dtDir = nfgGetName('dtDir',brainDir);
% Input Files
pbcGradVecsFile = nfgGetName('pbcGradVecsFile',brainDir);
pbcGradValsFile = nfgGetName('pbcGradValsFile',brainDir);
noisyImg = nfgGetName('noisyImg',brainDir);
% Output Files
bvalsFile = nfgGetName('bvalsFile',brainDir);
bvecsFile = nfgGetName('bvecsFile',brainDir);

% Just copy the bvals and bvecs file from the Pgbh directory

% Convert NFG grad file to ours n
disp(' '); disp('Converting NFG gradient file to mrDiffusion format ...');
%copyfile(pbcGradVecsFile,bvecsFile);
%copyfile(pbcGradValsFile,bvalsFile);
bvecs = load(pbcGradVecsFile,'-ascii');
bvals = load(pbcGradValsFile,'-ascii');
fid = fopen(bvalsFile,'wt');
fprintf(fid, '%1.3f ', bvals); 
fclose(fid);
fid = fopen(bvecsFile,'wt');
fprintf(fid, '%1.4f ', bvecs(1,:)); fprintf(fid, '\n'); 
fprintf(fid, '%1.4f ', bvecs(2,:)); fprintf(fid, '\n');
fprintf(fid, '%1.4f ', bvecs(3,:)); 
fclose(fid);

% Do tensor fitting
numBootstraps=30;
disp(' '); disp(['Tensor fitting with ' num2str(numBootstraps) ' bootstraps ...']);
dtiRawFitTensorMex(noisyImg, bvecsFile, bvalsFile, dtDir, numBootstraps);

% Fix automatically generated brain mask
% disp(' '); disp('Fixing automatically generated brain mask ...');
% ni = readFileNifti(brainMaskFile);
% ni.data(:) = 1;
% writeFileNifti(ni);

% Need to produce pdf image now
disp(' '); disp('Creating ConTrack PDF file ...');
mtrCreateConTrackOptionsFromROIs(0,1,dtDir);

return;