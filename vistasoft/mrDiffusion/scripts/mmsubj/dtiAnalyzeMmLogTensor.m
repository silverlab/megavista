outDir = '/biac3/wandell4/data/reading_longitude/dti_adults/netta_stat';
sumFile = fullfile(outDir,'mmSum.mat');

if(~exist(sumFile,'file'))
    template = 'MNI_EPI';
    subDir = '/biac3/wandell4/data/reading_longitude/dti_adults';
    dd = 'dti06';
    subs = {'mm_temp040325','aab050307','ah051003','am090121','ams051015','as050307',...
            'aw040809','bw040922','ct060309','db061209','dla050311','gd040901',...
            'gf050826','gm050308','jl040902','jm061209','jy060309','ka040923',...
            'mbs040503','me050126','mo061209','mod070307','mz040828','pp050208',...
            'rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};

    % Compute the control group spatial norms
    for(ii=21:numel(subs))
        dt = dtiLoadDt6(fullfile(subDir, subs{ii}, dd, 'dt6'));
        % Get the B0 read for alignment with the template. We histogram clip to
        % avoid problems when spm converts it to uint8. We also replace zeros
        % with NaNs to avoid considering parts of the brain that might have
        % been cut off by a tight Rx.
        im = mrAnatHistogramClip(double(dt.b0),0.4,0.98);
        dt.b0 = im;
        im(bwareaopen(im==0,10000,6)) = NaN;
        sn{ii} = mrAnatComputeSpmSpatialNorm(im, dt.xformToAcpc, template);
        dt_sn = dtiSpmDeformer(dt,sn{ii});
        b0{ii} = dt_sn.b0;
        dt6{ii} = dt_sn.dt6;
        bm{ii} = dt_sn.brainMask;
    end
    xformToAcpc = dt_sn.xformToAcpc;
    clear im dt dt_sn

    % NOTE: may want to save the normalized data here
    save('/tmp/mmAll.mat','subDir','dd','subs','sn','b0','dt6','bm','xformToAcpc');

    % Compute the log-tensor difference maps
    dt6 = cat(5,dt6{:});
    b0 = cat(4,b0{:});
    bm = cat(4,bm{:});

    % strip things down to the minimal data needed to avoid memory issues
    brainMask = all(bm,4);
    meanB0 = mean(b0,4);
    dt6 = dtiImgToInd(dt6,brainMask);
    clear b0 bm;
    save(sumFile,'subDir','dd','subs','sn','meanB0','dt6','brainMask','xformToAcpc');
else
    disp(['Loading summary data from ' sumFile '...']);
    load(sumFile);
end


showSlices = [10:60];
sl = [-32:4:64];

% One-sample test:
[vec,val] = dtiEig(dt6,1);
% For PDness:
val(val<0.01) = 0.01;
val = log(val);
logDt6 = dtiEigComp(vec,val);
% We'll compare the first subject to all the rest
[M, S, N] = dtiLogTensorMean(logDt6(:,:,2:end));
S = sqrt(S);

%
%% Eigenvector test
%
[T, DISTR, df] = dtiLogTensorTest('vec', M, S, N, logDt6(:,:,1));
Timg = dtiIndToImg(T, brainMask);

fThresh = finv(1-10^-3, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Vec test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
Simg = dtiIndToImg(S,brainMask);
figure; imagesc(makeMontage(Simg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Vec test variance'); 

fdrVal = 0.05; 
fdrType = 'original'; % general or original
T(isnan(T)) = 0;
pvals = 1-fcdf(T, df(1), df(2));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
disp(n_signif);max(pvals(index_signif))
% Convert back to an fThreshold
pThreshFDR = max(pvals(index_signif));
fThreshFDR = finv(1-pThreshFDR, df(1), df(2));
str = sprintf('Log-Norm EigVec Test: f-threshold for FDR (%s method) of %0.3f: %0.2f.\n',...
             fdrType,fdrVal,fThreshFDR);
disp(str);
logPimg = dtiIndToImg(-log10(pvals), brainMask);
cmap = autumn(256);
maxLogP = 10;
minLogP = -log10(pThreshFDR);

anatIm = meanB0;
anatXform = xformToAcpc;
dtXform = xformToAcpc;
clusterThresh = 1;
imgRgb = mrAnatOverlayMontage(logPimg, dtXform, anatIm, anatXform, cmap, [minLogP,maxLogP], sl, [], 3, 1, true, 0, [], clusterThresh);

%mrAnatOverlayMontage(Timg, dtXform, anatIm, anatXform, cmap, [fThresh fMax], sl, [], 3, 1, true, 0, [], clusterThresh);

%
%% Eigenvalue test
%
[T, DISTR, df] = dtiLogTensorTest('val', M, S, N, logDt6(:,:,1));
Timg = dtiIndToImg(T, brainMask);

fThresh = finv(1-10^-4, df(1), df(2));
fMax = finv(1-10^-12, df(1), df(2));
Timg(Timg>fMax) = fMax;
fMax = max(Timg(:));
figure; imagesc(makeMontage(Timg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Val test'); title(sprintf('fthresh (p<10^-^4) = %0.1f',fThresh));
Simg = dtiIndToImg(S,brainMask);
figure; imagesc(makeMontage(Simg,showSlices)); axis image; colormap hot; colorbar; 
set(gcf,'Name','Val test variance'); 

fdrVal = 0.01;
T(isnan(T)) = 0;
pvals = 1-fcdf(T, df(1), df(2));
[n_signif,index_signif] = fdr(pvals,fdrVal,fdrType,'mean');
disp(n_signif);max(pvals(index_signif))
% Convert back to an fThreshold
pThreshFDR = max(pvals(index_signif));
fThreshFDR = finv(1-pThreshFDR, df(1), df(2));
str = sprintf('Log-Norm EigVec Test: f-threshold for FDR (%s method) of %0.3f: %0.2f (%0.3f).\n',...
             fdrType,fdrVal,fThreshFDR,fThreshFDR/fMax);
disp(str);
logPimg = dtiIndToImg(-log10(pvals), brainMask);
cmap = autumn(256);
maxLogP = 10;
minLogP = -log10(pThreshFDR);

anatIm = meanB0;
anatXform = xformToAcpc;
dtXform = xformToAcpc;
clusterThresh = 10;
imgRgb = mrAnatOverlayMontage(logPimg, dtXform, anatIm, anatXform, cmap, [minLogP,maxLogP], sl, [], 3, 1, true, 0, [], clusterThresh);


