function mtrCompareDensities2D(subjDir, fgDensitySrcFile, fgDensityDstFileRoot, ccFile, chSlice, numSlice)

% chSlice specifies either X,Y, or Z

% Load the white matter mask file as well

ni = readFileNifti(fullfile(subjDir,'bin','wmMask.nii.gz'));
img_wm = interp3(ni.data,'nearest');
clear ni;

if ieNotDefined('chSlice')
    chSlice = 'x';
    numSlice = round(size(img_wm,1)/2);
end
% Setup slice selection indices
indSlice = zeros(size(img_wm));
if strcmp(lower(chSlice),'x')
    indSlice(numSlice,:,:) = 1;
elseif strcmp(lower(chSlice),'y')
    indSlice(:,numSlice,:) = 1;
elseif strcmp(lower(chSlice),'z')
    indSlice(:,:,numSlice) = 1;
else
    error('Invalid slice specification!');
end
indSlice = indSlice>0;
img_wm = img_wm(indSlice);


if( ~ieNotDefined('fgDensitySrcFile') && exist(fgDensitySrcFile,'file') )
    % Load source density image
    msg = sprintf('Loading source: %s ...',fgDensitySrcFile);
    disp(msg);
    ni = readFileNifti(fgDensitySrcFile);
    fgSrcImg = ni.data(indSlice);
    fgSrcImg = double(fgSrcImg(img_wm>0)>0);
    clear ni;
    
     % Get all density filenames to compare
    fgDensityFiles = dir([fgDensityDstFileRoot '*nii.gz']);
    % Fill paramData with filenames that we used to compare
    paramData = [];
    fgImgs = zeros(size(fgSrcImg,1),length(fgDensityFiles));
    % Loop over files collecting images
    for ff = 1:length(fgDensityFiles)
        fgName = fgDensityFiles(ff).name;
        msg = sprintf('Loading destination: %s ...',fgName);
        disp(msg);
        ni = readFileNifti(fgName);
        tmpImg = ni.data(indSlice);
        fgImgs(:,ff) = double(tmpImg(img_wm>0)>0);
        clear ni;
        [foo, temp_name, ext] = fileparts(fgName);
        paramData(ff).name = [temp_name ext];
    end
    
    % Compare all of the densities
    ccMatrix = zeros(length(fgDensityFiles));
    for ii = 1:length(fgDensityFiles)
        disp(['Comparing with ' fgDensityFiles(ii).name]);
            img1 = fgSrcImg;
            img2 = fgImgs(:,ii);
            cc = corrcoef(img1(:),img2(:));
            ccMatrix(ii) = cc(1,2);
            disp(['CC: ' num2str(cc(1,2))]);
    end    
else
    error('Density comparison requires a source file!');
end

save(ccFile,'ccMatrix','paramData','fgSrcImg','fgImgs');
msg = sprintf('Saved output to %s.',ccFile);
disp(msg);

