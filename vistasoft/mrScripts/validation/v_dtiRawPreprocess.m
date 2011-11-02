function val = v_dtiRawPreprocess
%
% Validate dtiRawPreprocess.m function.
%
% Copyright Stanford team, mrVista, 2011
%
% FP and MP 7/6/2011
%
% See also mrvValidateAll.m
%
% this function checks that the average FA and B0 values resulting from
% dtiRawPreprocess are consistent with the expected value on different
% platforms (LINUX, WINDOWS, etc.).
%
% it requires vistadata and vistasoft.
%
% The folder: vistadata/diffusion/dtiRawPreprocess/GE contains all the files
% necessary.
% 
% To validate this function does the following:
%
% (1) run dtiRawPreprocess on the files in the raw folder. This will align to the T1 and
% create a B0, BVECS and FA values (it creates more stuff but we only focus on these for the moment).
%
% (2) Show a montage of Alignment i.e., the T1 and DTI overalyed. Check for LR flips and correct alignment. 
%  
% (3) Compute FA, Mean diffusivity, radial diffusivity nd Axial diffusivity 
%     across the brain and check the value obtained on different
%     platforms. THis will be done using: [fa,md,rd,ad] = dtiComputeFA(eigVal)
%
% (5) Load the stored FA, MD, RD, AD for the whole brain in:
%     GE/storedMeanDiffusionVals.mat
%     
% (6) Recompute them from the data
% 
% (7) Compute the difference between the stored and the recomputed ones.

 
%% Get the data pathdata path
dataDir = fullfile(mrvDataRootPath,'diffusion','dtiRawPreprocess','GE');

%% Retain original directory, change to data directory
curDir = pwd;
cd(dataDir);

%% Run Preprocess
dtiRawPreprocess('raw/dti_g87_b1000.nii.gz', 't1.nii.gz',[],[],'always'); % setting clobber to 'always', so that output files will be silently replaced.

%% Show alignment to t1
imshow(imread('dti40trilin/t1pdd.png')); % this was automatically computed by dtiRawPreprocess.m

%% Compute mean FA, RD, MD, AD values and check them with the stored one.

% load the stored values
load('storedMeanDiffusionVals.mat');

% load the dti file.
dt = dtiLoadDt6('dti40trilin/dt6.mat');

% extract the eigen values.
eigVal = dt.dt6;

% compute the fractional, mean, radial and axial diffusivity
[fa,md,rd,ad] = dtiComputeFA(eigVal);

% compute the meana cross the whole brain
mean_fa = nanmean(fa(:));
mean_md = nanmean(md(:));
mean_rd = nanmean(rd(:));
mean_ad = nanmean(ad(:));

% check the computed with the stored values
val.faErr = diff([mean_fa,meanVals.fa]);
val.mdErr = diff([mean_md,meanVals.md]);
val.rdErr = diff([mean_rd,meanVals.rd]);
val.adErr = diff([mean_ad,meanVals.ad]);

% show results on matlab output
errFields = fields(val);
meanFields = fields(meanVals);
for i = 1:length(fields(val))
 fprintf('[%s] Error in ''%s'': %2.8f\n',mfilename, meanFields{i}, val.(errFields{i}));
end

%% go back to the original directory, done!
cd(curDir)

return




