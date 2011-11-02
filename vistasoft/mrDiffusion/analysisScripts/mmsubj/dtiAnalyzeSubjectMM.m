% locate subject dt6 file
subjectDt6 = '/biac2/wandell2/data/DTI_Blind/mm040325/mm040325_dt6';

% redo spatial normalization or not
doSpatialNormalization = false;

% set template pointers
templateDir  = '/biac2/wandell2/data/templates/adult';
templateName = 'SIRL20adult';
averageDir   = fullfile(templateDir,[templateName,'warp3_averageDataset']);

if doSpatialNormalization

    % % % % % % % % % % % % %
    % SPATIAL NORMALIZATION %
    % % % % % % % % % % % % %
    
    % t1 template
    t1Template = fullfile(templateDir, [templateName,'_brain.img']);

    % load subject dt6
    dt = load(subjectDt6);

    % set spm defaults
    spm_defaults; global defaults; defaults.analyze.flip = 0;
    params = defaults.normalise.estimate;
    params.smosrc = 4;

    im                     = double(dt.anat.img);
    im                     = im./max(im(:));
    xform                  = dt.anat.xformToAcPc;
    im(~dt.anat.brainMask) = 0;

    t1Sn  = mrAnatComputeSpmSpatialNorm(im, xform, t1Template, params);
    t1Rng = [min(dt.anat.img(:)) max(dt.anat.img(:))];
    t1Dt  = dtiSpmDeformer(dt, t1Sn, 1, [1 1 1]);

    t1Dt.anat.img(t1Dt.anat.img<t1Rng(1)) = t1Rng(1);
    t1Dt.anat.img(t1Dt.anat.img>t1Rng(2)) = t1Rng(2);
    t1Dt.anat.img                         = int16(t1Dt.anat.img+0.5);

    t1Dt.xformToAcPc = t1Dt.anat.xformToAcPc * t1Dt.xformToAnat;

    t1Dt                   = rmfield(t1Dt, 't1NormParams');
    t1Dt.t1NormParams.name = templateName;
    
    subjectDt6Sn = sprintf('%s_%s',subjectDt6,templateName);

    dtiSaveStruct(t1Dt, subjectDt6Sn);

else
    subjectDt6Sn = sprintf('%s_%s',subjectDt6,templateName);
end

% % % % % % % % % % % % 
% VOXELWISE ANALYSIS  %
% % % % % % % % % % % %

% get a list of all subjects in the average directory
snFiles = findSubjects(averageDir, '*_sn*',{});
N       = length(snFiles);

% load dt6 files from each subject
disp(['Loading ' snFiles{1} '...']);
dt = load(snFiles{1});
allDt6 = zeros([size(dt.dt6) N]);
allDt6(:,:,:,:,1) = dt.dt6;
meanB0 =  double(dt.b0);
% mask = allDt6(:,:,:,1,1)>0;
for(ii=2:N)
  disp(['Loading ' snFiles{ii} '...']);
  dt = load(snFiles{ii});
  dt.dt6(isnan(dt.dt6)) = 0;
  allDt6(:,:,:,:,ii) = dt.dt6;
  meanB0 = meanB0 + double(dt.b0);
  % mask = mask & allDt6(:,:,:,1,ii)>0;
end

% mean B0
meanB0 = meanB0./N;
mask   = meanB0>250 & all(squeeze(allDt6(:,:,:,1,:)),4)>0;

% load template dt6
templateDt6   = load(fullfile(averageDir,'average_dt6'));
xformDtToAcpc = templateDt6.xformToAcPc;

% load subject dt6
subDir  = fileparts(subjectDt6Sn);
ssDt_sn = load(subjectDt6Sn);
mask    = mask&ssDt_sn.dt6(:,:,:,1)>0;

% create montage of template and subject B0
figure; imagesc(makeMontage(templateDt6.b0)); axis image; colormap gray;
figure; imagesc(makeMontage(ssDt_sn.b0)); axis image; colormap gray;

% convert x,y,z to indices
ssDt_sn_ind = dtiImgToInd(ssDt_sn.dt6, mask);
allDt6_ind  = dtiImgToInd(allDt6, mask);

% append subject dt6 data to the group
allDt6_ind = cat(3, ssDt_sn_ind, allDt6_ind);

% extract eigenvectors and eigenvalues from the dt6 data
[eigVec,eigVal] = dtiEig(allDt6_ind);

showSlices = [20:60];

% ======= %
% FA test %
% ======= %

% computer FA from the eigenvalues
faInd = dtiComputeFA(eigVal);

% perform t-test on FA
[faTInd, faMInd, faSInd, faDISTR, faDF] = dtiTTestStat(1, 2:N, faInd);

% convert test statistics from index format to image format
faTImg  = dtiIndToImg(faTInd, mask, NaN);

% get the threshold t-statistics for 10^-4
faTThresh = tinv(1-10^-4, faDF(1));

% clip extremely large t values to t-statistics corresponding to 10^-12
faTMax = tinv(1-10^-12, faDF(1));
faTImg(abs(faTImg)>faTMax) = faTMax;

% create montage for FA t-test results
figure; imagesc(makeMontage(abs(faTImg),showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','FA test'); title(sprintf('t-thresh(p<10^-^4) = %0.1f',faTThresh));
dtiWriteNiftiWrapper(abs(faTImg), xformDtToAcpc, fullfile(subDir,['fa_' faDISTR '-test_' num2str(faDF(1)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(faSInd,mask), xformDtToAcpc, fullfile(subDir,'fa_variance.nii.gz'));
fprintf('dtiFiberUI threshold: %0.3f\n',faTThresh/faTMax);

% ============================================ %
% FDR analysis for FA results (Armin's method) %
% ============================================ %

% set FDR threshold
fdrVal = 0.05;

% quantile transformation
faFdrZ     = norminv(cdf(faDISTR, faTInd, faDF(1), faDF(2)));
faFdrDISTR = 'norm';

faFdrHistogram = fdrHist(faFdrZ,0.2);

% set the weights for fitting FDR null model
faFdrZMax    = prctile(faFdrZ,[10 90]);
faFdrWeights = (faFdrHistogram.x > faFdrZMax(1)) & (faFdrHistogram.x < faFdrZMax(2));

% FDR calculation based on theoretical null
[faFdrParams,faFdrParamsCov,faFdrH0] = fdrEmpNull(faFdrHistogram,faFdrWeights,faFdrDISTR,{'mu','s'});
[faFdrCurveVal,faFdrCurveZ]          = fdrCurveHist('FDR', faFdrH0, 1);
faFdrThreshZ                         = fdrThresh(1, faFdrCurveVal(:,1), faFdrCurveZ, fdrVal);
faFdrThreshT                         = tinv(cdf('norm',faFdrThreshZ,0,1),faDF(1));
fprintf('t-threshold for FDR (Armin''s) of %0.3f: %0.5f\n',fdrVal,faFdrThreshT);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',faFdrThreshT/faTMax);

% histogram of test stats
figure; set(gcf, 'name', 'Histograms'); hold on;
faEmpiricalDataHistogram   = bar(faFdrHistogram.x, faFdrHistogram.hist, 1, 'w');
faTheoreticalNullHistogram = plot(faFdrH0.x, faFdrH0.yhat, 'b');
hold off; legend(faTheoreticalNullHistogram, 'Theoretical null',1);
xlabel('z-score'); ylabel('voxel count');

% FDR curves
figure;	set(gcf, 'name', 'FDR'); hold on;
plot(faFdrCurveZ, faFdrCurveVal(:,1), 'b');
plot(faFdrCurveZ, faFdrCurveVal(:,2), 'b:', faFdrCurveZ, faFdrCurveVal(:,3), 'b:');
hold off;
xlabel('z-score'); ylabel('FDR');

% ==================================== %
% 'Simple' FDR analysis for FA results %
% ==================================== %

% set FDR method
fdrType = 'original';

faTInd(isnan(faTInd)) = 0;

% convert FA t-statistics to p-values
% this is for two-tailed test
pvals = 1-tcdf(faTInd,faDF(1));

% calculate FDR
[nSignificantTests,indexSignificanceTests] = fdr(pvals,fdrVal,fdrType,'mean');

% convert back to a threshold for t-statistics
faTThreshFDR = tinv(1-max(pvals(indexSignificanceTests)), faDF(1));
fprintf('t-threshold for FDR (%s) of %0.3f: %0.5f\n',fdrType,fdrVal,faTThreshFDR);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',faTThreshFDR/faTMax);

% =========================== %
% logNormal tensor statistics %
% =========================== %

% Log-transform
eigVal(eigVal<0) = 0;
eigVal           = log(eigVal);
allDt6_ind       = dtiEigComp(eigVec, eigVal);

% ================ %
% Eigenvector test %
% ================ %

% Test for eigenvector differences
[eigVecTInd, eigVecMInd, eigVecSInd, eigVecDISTR, eigVecDF] = dtiLogTensorTest(1, [2:size(allDt6_ind,3)], allDt6_ind, 'vec');

% convert test statistics from index format to image format
eigVecTImg = dtiIndToImg(eigVecTInd, mask);

% get the threshold F-statistics for 10^-4
eigVecFThresh = finv(1-10^-4, eigVecDF(1), eigVecDF(2));

% clip extremely large F values to F-statistics corresponding to 10^-12
eigVecFMax = finv(1-10^-12, eigVecDF(1), eigVecDF(2));
eigVecTImg(eigVecTImg>eigVecFMax) = eigVecFMax;

% create montage for eigenvector F-test results
figure; imagesc(makeMontage(eigVecTImg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Eigenvector test'); title(sprintf('F-thresh(p<10^-^4) = %0.1f',eigVecFThresh));
dtiWriteNiftiWrapper(eigVecTImg, xformDtToAcpc, fullfile(subDir,['eigvec_' eigVecDISTR '-test_' num2str(eigVecDF(1)) ',' num2str(eigVecDF(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(eigVecSInd,mask), xformDtToAcpc, fullfile(subDir,'eigvec_variance.nii.gz'));
fprintf('dtiFiberUI threshold: %0.3f\n',eigVecFThresh/eigVecFMax);

% ========================================================== %
% FDR analysis for Eigenvector test results (Armin's method) %
% ========================================================== %

% set FDR threshold
fdrVal = 0.05;

% quantile transformation
eigVecTInd(isnan(eigVecTInd)) = 0;

eigVecFdrChi2  = chi2inv(cdf(eigVecDISTR, eigVecTInd, eigVecDF(1), eigVecDF(2)),eigVecDF(1));
eigVecFdrDISTR = 'chi2';

eigVecFdrHistogram = fdrHist(eigVecFdrChi2,0.2,1);

% set the weights for fitting FDR null model
eigVecFdrChi2Max = prctile(eigVecFdrChi2,90);
eigVecFdrWeights = (eigVecFdrHistogram.x < eigVecFdrChi2Max);

% FDR calculation based on theoretical null
[eigVecFdrParams,eigVecFdrParamsCov,eigVecFdrH0] = fdrEmpNull(eigVecFdrHistogram,eigVecFdrWeights,eigVecFdrDISTR,{'df','s'},eigVecDF);
[eigVecFdrCurveVal,eigVecFdrCurveChi2]           = fdrCurveHist('FDR', eigVecFdrH0, 1);
eigVecFdrCurvePval                               = 1-cdf('chi2',eigVecFdrCurveChi2,eigVecDF(1));
eigVecFdrThreshChi2                              = fdrThresh(1, eigVecFdrCurveVal(:,1), eigVecFdrCurveChi2, fdrVal);
eigVecFdrThreshPval                              = 1-cdf('chi2',eigVecFdrThreshChi2,eigVecDF(1));
eigVecFdrThreshF                                 = finv(1-eigVecFdrThreshPval,eigVecDF(1),eigVecDF(2));
fprintf('F-threshold for FDR (Armin''s) of %0.3f: %0.5f\n',fdrVal,eigVecFdrThreshF);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',eigVecFdrThreshF/eigVecFMax);

% histogram of test stats
figure; set(gcf, 'name', 'Histograms'); hold on;
eigVecEmpiricalDataHistogram   = bar(eigVecFdrHistogram.x, eigVecFdrHistogram.hist, 1, 'w');
eigVecTheoreticalNullHistogram = plot(eigVecFdrH0.x, eigVecFdrH0.yhat, 'b');
hold off; legend(eigVecTheoreticalNullHistogram, 'Theoretical null',1);
xlabel('chi-square score'); ylabel('voxel count');

% FDR curves
figure;	set(gcf, 'name', 'FDR'); hold on;
plot(eigVecFdrThreshChi2, eigVecFdrCurveVal(:,1), 'b');
plot(eigVecFdrThreshChi2, eigVecFdrCurveVal(:,2), 'b:', eigVecFdrThreshChi2, eigVecFdrCurveVal(:,3), 'b:');
hold off;
xlabel('chi-square score'); ylabel('FDR');

figure;	set(gcf, 'name', 'FDR'); hold on;
plot(eigVecFdrCurvePval, eigVecFdrCurveVal(:,1), 'b');
plot(eigVecFdrCurvePval, eigVecFdrCurveVal(:,2), 'b:', eigVecFdrCurvePval, eigVecFdrCurveVal(:,3), 'b:');
hold off;
xlabel('p-value'); ylabel('FDR');

% ================================================== %
% 'Simple' FDR analysis for Eigenvector test results %
% ================================================== %

% set FDR method
fdrType = 'original';

eigVecTInd(isnan(eigVecTInd)) = 0;

% convert eigenvector F-statistics to p-values
pvals = 1-fcdf(eigVecTInd,eigVecDF(1),eigVecDF(2));

% calculate FDR
[nSignificantTests,indexSignificanceTests] = fdr(pvals,fdrVal,fdrType,'mean');

% convert back to a threshold for F-statistics
eigVecFThreshFDR = finv(1-max(pvals(indexSignificanceTests)), eigVecDF(1), eigVecDF(2));
fprintf('eigenvector F-threshold for FDR (%s) of %0.3f: %0.5f\n',fdrType,fdrVal,eigVecFThreshFDR);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',eigVecFThreshFDR/eigVecFMax);

% display p-value map
eigVecThreshMask = zeros(size(pvals));
eigVecThreshMask(indexSignificanceTests) = 1;

eigVecThreshMask = dtiIndToImg(eigVecThreshMask,mask);
eigVecLogPMap    = dtiIndToImg(-log10(pvals),mask);

eigVecLogPMap(eigVecThreshMask<1) = 0;
figure; imagesc(makeMontage(eigVecLogPMap,showSlices)); axis image; colormap hot; colorbar;
set(gcf,'Name','Eigenvector test'); title('FDR adjusted -log(p) map');

% =============== %
% Eigenvalue test %
% =============== %

% Test for eigenvalue differences
[eigValTInd, eigValMInd, eigValSInd, eigValDISTR, eigValDF] = dtiLogTensorTest(1, [2:size(allDt6_ind,3)], allDt6_ind, 'val');

% convert test statistics from index format to image format
eigValTImg = dtiIndToImg(eigValTInd, mask);

% get the threshold F-statistics for 10^-4
eigValFThresh = finv(1-10^-4, eigValDF(1), eigValDF(2));

% clip extremely large F values to F-statistics corresponding to 10^-12
eigValFMax = finv(1-10^-12, eigValDF(1), eigValDF(2));
eigValTImg(eigValTImg>eigValFMax) = eigValFMax;

% create montage for eigenvector F-test results
figure; imagesc(makeMontage(eigValTImg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Eigenvalue test'); title(sprintf('F-thresh(p<10^-^4) = %0.1f',eigValFThresh));
dtiWriteNiftiWrapper(eigValTImg, xformDtToAcpc, fullfile(subDir,['eigval_' eigVecDISTR '-test_' num2str(eigValDF(1)) ',' num2str(eigValDF(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(dtiIndToImg(eigValSInd,mask), xformDtToAcpc, fullfile(subDir,'eigval_variance.nii.gz'));
fprintf('dtiFiberUI threshold: %0.3f\n',eigValFThresh/eigValFMax);

% ========================================================= %
% FDR analysis for Eigenvalue test results (Armin's method) %
% ========================================================= %

% set FDR threshold
fdrVal = 0.05;

% quantile transformation
eigValTInd(isnan(eigValTInd)) = 0;

eigValFdrChi2  = chi2inv(cdf(eigValDISTR, eigValTInd, eigValDF(1), eigValDF(2)),eigValDF(1));
eigValFdrDISTR = 'chi2';

eigValFdrHistogram = fdrHist(eigValFdrChi2,0.2,1);

% set the weights for fitting FDR null model
eigValFdrChi2Max = prctile(eigValFdrChi2,90);
eigValFdrWeights = (eigValFdrHistogram.x < eigValFdrChi2Max);

% FDR calculation based on theoretical null
[eigValFdrParams,eigValFdrParamsCov,eigValFdrH0] = fdrEmpNull(eigValFdrHistogram,eigValFdrWeights,eigValFdrDISTR,{'df','s'},eigValDF);
[eigValFdrCurveVal,eigValFdrCurveChi2]           = fdrCurveHist('FDR', eigValFdrH0, 1);
eigValFdrCurvePval                               = 1-cdf('chi2',eigValFdrCurveChi2,eigValDF(1));
eigValFdrThreshChi2                              = fdrThresh(1, eigValFdrCurveVal(:,1), eigValFdrCurveChi2, fdrVal);
eigValFdrThreshPval                              = 1-cdf('chi2',eigValFdrThreshChi2,eigValDF(1));
eigValFdrThreshF                                 = finv(1-eigValFdrThreshPval,eigValDF(1),eigValDF(2));
fprintf('F-threshold for FDR (Armin''s) of %0.3f: %0.5f\n',fdrVal,eigValFdrThreshF);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',eigValFdrThreshF/eigValFMax);

% histogram of test stats
figure; set(gcf, 'name', 'Histograms'); hold on;
eigValEmpiricalDataHistogram   = bar(eigValFdrHistogram.x, eigValFdrHistogram.hist, 1, 'w');
eigValTheoreticalNullHistogram = plot(eigValFdrH0.x, eigValFdrH0.yhat, 'b');
hold off; legend(eigValTheoreticalNullHistogram, 'Theoretical null',1);
xlabel('chi-square score'); ylabel('voxel count');

% FDR curves
figure;	set(gcf, 'name', 'FDR'); hold on;
plot(eigValFdrCurveChi2, eigValFdrCurveVal(:,1), 'b');
plot(eigValFdrCurveChi2, eigValFdrCurveVal(:,2), 'b:', eigValFdrCurveChi2, eigValFdrCurveVal(:,3), 'b:');
hold off;
xlabel('chi-square score'); ylabel('FDR');

figure;	set(gcf, 'name', 'FDR'); hold on;
plot(eigValFdrCurvePval, eigValFdrCurveVal(:,1), 'b');
plot(eigValFdrCurvePval, eigValFdrCurveVal(:,2), 'b:', eigValFdrCurvePval, eigValFdrCurveVal(:,3), 'b:');
hold off;
xlabel('p-value'); ylabel('FDR');

% ================================================= %
% 'Simple' FDR analysis for Eigenvalue test results %
% ================================================= %

% set FDR method
fdrType = 'original';

eigValTInd(isnan(eigValTInd)) = 0;

% convert eigenvector F-statistics to p-values
pvals = 1-fcdf(eigValTInd,eigValDF(1),eigValDF(2));

% calculate FDR
[nSignificantTests,indexSignificanceTests] = fdr(pvals,fdrVal,fdrType,'mean');

% convert back to a threshold for F-statistics
eigValFThreshFDR = finv(1-max(pvals(indexSignificanceTests)), eigValDF(1), eigValDF(2));
fprintf('eigenvalue F-threshold for FDR (%s) of %0.3f: %0.5f\n',fdrType,fdrVal,eigValFThreshFDR);
fprintf('FDR adjusted dtiFiberUI threshold: %0.3f\n',eigValFThreshFDR/eigValFMax);

% display p-value map
eigValThreshMask = zeros(size(pvals));
eigValThreshMask(indexSignificanceTests) = 1;

eigValThreshMask = dtiIndToImg(eigValThreshMask,mask);
eigValLogPMap    = dtiIndToImg(-log10(pvals),mask);

eigValLogPMap(eigValThreshMask<1) = 0;
figure; imagesc(makeMontage(eigValLogPMap,showSlices)); axis image; colormap hot; colorbar;
set(gcf,'Name','Eigenvalue test'); title('FDR adjusted -log(p) map');
