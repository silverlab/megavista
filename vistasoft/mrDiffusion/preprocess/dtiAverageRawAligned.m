function dtiAverageRawAligned(dtiAlignedFile, dtiBvalsFile, dtiBvecsFile, dtiAlignedAvgFile)

%dtiAverageRawAligned(dtiAlignedFile, [dtiBvalsFile], [dtiBvecsFile], [dtiAlignedAvgFile])
%E.g., dtiAverageRawAligned('dti_g712_b2000_aligned_trilin.nii.gz',...
%'dti_g712_b2000_aligned_trilin.bvals', ...
%'dti_g712_b2000_aligned_trilin.bvecs',...
%'dti_g712_b2000_aligned_trilin_avg.nii.gz'

% Avg the raw file down to independent parts
%This function averages raw DTI reps
%normalization applied to STT results
%02/23/2009 ER pulled it from mtrNotes 
%ER 09/09 removed redundant code and completely changed input parameters.

if ~exist('dtiBvalsFile', 'var') || isempty(dtiBvalsFile)
    if(strfind(dtiAlignedFile, 'nii.gz'))
       dtiBvalsFile=[dtiAlignedFile(1:end-7) '.bvals'];
    elseif (strcmp(dtiAlignedFile, '.gz'))
       dtiBvalsFile=[dtiAlignedFile(1:end-4) '.bvals'];
    end
end

if ~exist('dtiBvecsFile', 'var') || isempty(dtiBvecsFile)
    if(strfind(dtiAlignedFile, 'nii.gz'))
       dtiBvecsFile=[dtiAlignedFile(1:end-7) '.bvecs'];
    elseif (strcmp(dtiAlignedFile, '.gz'))
       dtiBvecsFile=[dtiAlignedFile(1:end-4) '.bvecs'];
    end
end


if ~exist('dtiAlignedAvgFile', 'var') || isempty(dtiAlignedAvgFile)
    if(strfind(dtiAlignedFile, 'nii.gz'))
       dtiAlignedAvgFile=[dtiAlignedFile(1:end-7) '_avg.nii.gz'];
    elseif (strcmp(dtiAlignedFile, '.gz'))
       dtiAlignedAvgFile=[dtiAlignedFile(1:end-4) '_avg.nii.gz'];
    end
end


if(strfind(dtiAlignedAvgFile, 'nii.gz'))
       dtiAlignedAvgFileBvecs=[dtiAlignedAvgFile(1:end-7) '.bvecs'];
       dtiAlignedAvgFileBvals=[dtiAlignedAvgFile(1:end-7) '.bvals'];
    elseif (strcmp(dtiAlignedAvgFile, '.gz'))
       dtiAlignedAvgFileBvecs=[dtiAlignedAvgFile(1:end-4) '.bvecs'];
       dtiAlignedAvgFileBvals=[dtiAlignedAvgFile(1:end-4) '.bvals'];
end
    
ni = readFileNifti(dtiAlignedFile);
bvals = load(dtiBvalsFile,'-ascii');
bvecs = load(dtiBvecsFile,'-ascii');
ni.fname = dtiAlignedAvgFile;
nD = length(bvals)/sum(bvals==0);
avg_bvals = bvals(1:nD);
avg_bvecs = bvecs(:,1:nD);
ndata = ni.data(:,:,:,1:nD);
for ii=1:nD
    avg_bvecs(:,ii) = mean(bvecs(:,ii:nD:end),2);
    ndata(:,:,:,ii) = mean(ni.data(:,:,:,ii:nD:end),4);
end
ni.data = ndata;
writeFileNifti(ni);
fid = fopen(dtiAlignedAvgFileBvals,'wt');
fprintf(fid, '%1.3f ', avg_bvals); fclose(fid);
fid = fopen(dtiAlignedAvgFileBvecs,'wt');
fprintf(fid, '%1.3f ', avg_bvecs(1,:)); fprintf(fid, '\n'); 
fprintf(fid, '%1.3f ', avg_bvecs(2,:)); fprintf(fid, '\n');
fprintf(fid, '%1.3f ', avg_bvecs(3,:)); fclose(fid);