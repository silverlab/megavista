% rd_spmDiagnostics
%
% calculate mean and var images and view them

%% Initializations
nScans = 11;
nSlices = 19;
nImCols = ceil(sqrt(nSlices));
nImRows = ceil(nSlices/nImCols);

%% Calculate mean and variance images
for iScan = 1:nScans
    fprintf('Working on epi %d\n', iScan)
    spm_imcalc_ui([], sprintf('Diagnostics/MeanImages/epi%02d_mean.img',iScan),'mean(X)',{1;0;4;0});
    spm_imcalc_ui([], sprintf('Diagnostics/VarImages/epi%02d_var.img',iScan),'var(X)',{1;0;4;0});
end

%% View mean images
for iScan = 1:nScans
    fmean(iScan) = figure('Name',sprintf('Epi %d mean image',iScan));
    scan = readFileNifti(sprintf('Diagnostics/MeanImages/epi%02d_mean.img',iScan));

    for iSlice = 1:nSlices
        subplot(nImRows,nImCols,iSlice)
        imagesc(scan.data(:,:,iSlice))
        colormap gray
        axis off
    end
end

%% View var images
for iScan = 1:nScans
    fvar(iScan) = figure('Name',sprintf('Epi %d variance image',iScan));
    scan = readFileNifti(sprintf('Diagnostics/VarImages/epi%02d_var.img',iScan));

    for iSlice = 1:nSlices
        subplot(nImRows,nImCols,iSlice)
        imagesc(scan.data(:,:,iSlice))
        colormap gray
        axis off
    end
end