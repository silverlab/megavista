subjectDt6 = '/biac1/wandell/data/radiationNecrosis/dti/al060406_sn2/al060406_dt6_fatSat_SIRL54';
% radiation necrosis patient

tdir = '/biac3/wandell4/data/reading_longitude/templates/child_new/';
tname = 'SIRL54';
avgdir = fullfile(tdir,[tname 'warp3']);
dirSumFile = fullfile(avgdir,'dirSummary.mat');

%% VOXELWISE ANALYSIS
%
if(exist(dirSumFile,'file'))
    disp(['Loading control group PDD direction summary (' dirSumFile ')']);
    load(dirSumFile);
else
    % compute the dir summary
    snFiles = findSubjects(avgdir, '*_sn*',{});
    N = length(snFiles);
    disp(['Loading ' snFiles{1} '...']);
    dt = load(snFiles{1});
	xformToAcPc = dt.xformToAcPc;
	mmPerVox = dt.mmPerVox;
    allDt6 = zeros([size(dt.dt6) N]);
    allDt6(:,:,:,:,1) = dt.dt6;
    meanB0 =  double(dt.b0);
	clear dt;
    for(ii=2:N)
        disp(['Loading ' snFiles{ii} '...']);
        dt = load(snFiles{ii});
        dt.dt6(isnan(dt.dt6)) = 0;
        allDt6(:,:,:,:,ii) = dt.dt6;
        meanB0 = meanB0 + double(dt.b0);
		clear dt;
    end
    meanB0 = meanB0./N;
    mask = meanB0>300 & all(squeeze(allDt6(:,:,:,1,:)),4)>0;
    allDt6_ind = dtiImgToInd(allDt6, mask);
	clear allDt6;
    [eigVec, eigVal] = dtiEig(allDt6_ind);
	clear allDt6_ind;
    eigVal(eigVal<0) = 0;
    [faImg,mdImg] = dtiComputeFA(eigVal);
	clear eigVal;
    fa.mean = mean(faImg,2);
    fa.stdev = std(faImg,0,2);
    fa.n = N;
    md.mean = mean(mdImg,2);
    md.stdev = std(mdImg,0,2);
    md.n = N;
    clear faImg mdImg;
	pdd = permute(eigVec(:,:,1,:),[1 2 4 3]);
    [dir.M, dir.S, dir.N, dir.Sbar] = dtiDirMean(pdd);
    clear eigVec pdd;
    notes.createdOn = datestr(now);
    notes.sourceDataDir = avgdir;
    notes.sourceDataFiles = snFiles;
    save(dirSumFile,'fa','md','dir','meanB0','xformToAcPc','mmPerVox','mask','notes');
end


template = load(fullfile(avgdir,'average_dt6'));
xformDtToAcpc = template.xformToAcPc;

subDir = fileparts(subjectDt6);
ssDt_sn = load(subjectDt6);
%mask = mask&ssDt_sn.dt6(:,:,:,1)>0;

ssDt_ind = dtiImgToInd(ssDt_sn.dt6, mask);
[eigVec, eigVal] = dtiEig(ssDt_ind);

showSlices = [20:60];

outDir = fullfile(subDir,['dirAnalysis_' datestr(now,'yyyymmdd')]);
if(~exist(outDir,'dir')) mkdir(outDir); end
logFile = fopen(fullfile(outDir,'log.txt'),'w');

%%%%%%%%%%%%%
% FA test
%%%%%%%%%%%%%
ss_fa = dtiComputeFA(eigVal);
[Tfa, DISTR, df] = dtiTTest(fa.mean, fa.stdev, fa.n, ss_fa);
TfaImg = dtiIndToImg(Tfa, mask, NaN);
tThresh = tinv(1-10^-4, df(1));
tMax = tinv(1-10^-12, df(1));
TfaImg(abs(TfaImg)>tMax) = tMax;
tMax = max(TfaImg(:));

% Simple FDR analysis for FA
%
fdrVal = 0.05; fdrType = 'general';
Tfa(isnan(Tfa)) = 0;
pvals = 1-tcdf(Tfa, df(1));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
% Convert back to an fThreshold
tThreshFDR = tinv(1-max(pvals(index_signif)), df(1));
str = sprintf('FA TEST: t-threshold for FDR (%s) of %0.3f: %0.2f (%0.3f).\n',...
             fdrType,fdrVal,tThreshFDR,tThreshFDR/tMax);
fprintf(logFile,str); disp(str);
% Display FA test
figure; imagesc(makeMontage(TfaImg,showSlices)); axis image; colormap cool; colorbar; 
set(gcf,'Name','FA test'); title(sprintf('tthresh, no FDR (p<10^-^4) = %0.1f',tThresh));
%dtiWriteNiftiWrapper(TfaImg, xformDtToAcpc, fullfile(outDir,['fa_' DISTR '-test_' num2str(df(1)) 'df.nii.gz']));
%dtiWriteNiftiWrapper(dtiIndToImg(fa.stdev,mask), xformDtToAcpc, fullfile(outDir,'fa_variance.nii.gz'));

%
% Schwartzman test of PDD differences
%
wmMask = fa.mean>0.3&ss_fa>0.2;
[M1, S1, N1, Sbar1] = dtiDirMean(squeeze(eigVec(:,:,1)));
[Tdir, DISTR, df] = dtiDirTest(dir.Sbar, dir.N, Sbar1, N1);
Tdir(isnan(Tdir)|~wmMask) = 0;
TdirImg = dtiIndToImg(Tdir, mask, NaN);
fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
TdirImg(TdirImg>fMax) = fMax;
figure; imagesc(makeMontage(TdirImg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','PDD dir test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
Simg = dtiIndToImg(dir.S,mask);
figure; imagesc(makeMontage(Simg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','PDD dir test variance'); 
dtiWriteNiftiWrapper(Timg, xformDtToAcpc, fullfile(outDir,['PDD_' DISTR '-test_' num2str(df(1)) ',' num2str(df(2)) 'df.nii.gz']));
dtiWriteNiftiWrapper(Simg, xformDtToAcpc, fullfile(outDir,'PDD_variance.nii.gz'));

fdrVal = 0.10; fdrType = 'general';
pvals = 1-fcdf(Tdir, df(1), df(2));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
disp(n_signif);max(pvals(index_signif))
% Convert back to an fThreshold
pThreshFDR = max(pvals(index_signif));
fThreshFDR = finv(1-pThreshFDR, df(1), df(2));
str = sprintf('PDD dir Test: f-threshold for FDR (%s method) of %0.3f: %0.2f (%0.3f).\n',...
             fdrType,fdrVal,fThreshFDR,fThreshFDR/fMax);
fprintf(logFile,str); disp(str);
logPimg = dtiIndToImg(-log10(pvals), mask);
cmap = autumn(256);
maxLogP = 10;
minLogP = -log10(pThreshFDR);

anatRgb = repmat(mrAnatHistogramClip(double(ssDt_sn.anat.img),0.4,0.98),[1,1,1,3]);
tmp = mrAnatResliceSpm(logPimg, inv(ssDt_sn.xformToAcPc), [], ssDt_sn.anat.mmPerVox, [1 1 1 0 0 0]);
tmp(tmp>maxLogP) = maxLogP;
tmp = (tmp-minLogP)./(maxLogP-minLogP);
overlayMask = tmp>=0;
tmp(~overlayMask) = 0;
overlayMask = repmat(overlayMask,[1 1 1 3]);
overlayRgb = reshape(cmap(round(tmp*255+1),:),[size(tmp) 3]);
anatRgb(overlayMask) = overlayRgb(overlayMask);
% reorient so that the eyes point up
anatRgb = flipdim(permute(anatRgb,[2 1 3 4]),1);
sl = [2:2:40];
for(ii=1:length(sl)) slLabel{ii} = sprintf('Z = %d',sl(ii)); end
slImg = inv(ssDt_sn.anat.xformToAcPc)*[zeros(length(sl),2) sl' ones(length(sl),1)]';
slImg = round(slImg(3,:));
anatOverlay = makeMontage3(anatRgb, slImg, ssDt_sn.anat.mmPerVox(1), 0, slLabel);
fn = fullfile(outDir,'ss_t1_pddDirSPM');
mrUtilPrintFigure(fn);
legendLabels = explode(',',sprintf('%0.1f,',[minLogP:1:maxLogP]));
legendLabels{end} = ['>=' num2str(maxLogP)];
mrUtilMakeColorbar(cmap, legendLabels, '-log10(p)', [fn '_legend']);



