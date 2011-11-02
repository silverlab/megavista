function mtrCompareDensities(subjDir, fgDensitySrcFile, fgDensityDstFileRoot, paramData, ccFile)

% Assume paramData has two items each item has name and actual values used
% e.g. paramData(1).name = 'k1'; paramData(1).values = [-1 0 1];

% Load the white matter mask file as well

ni = readFileNifti(fullfile(subjDir,'bin','wmMask.nii.gz'));
img_wm = interp3(ni.data,'nearest');
clear ni;

if( ~ieNotDefined('fgDensitySrcFile') && exist(fgDensitySrcFile,'file') )
    % Load source density image
    msg = sprintf('Loading source: %s ...',fgDensitySrcFile);
    disp(msg);
    ni = readFileNifti(fgDensitySrcFile);
    fgSrcImg = double(ni.data(img_wm>0)>0);
    clear ni;
    
     % Get all density filenames to compare
    fgDensityFiles = dir([fgDensityDstFileRoot '*nii.gz']);
    % Fill paramData with filenames that we used to compare
    paramData = [];
    
    % Loop over files collecting images
    for ff = 1:length(fgDensityFiles)
        fgName = fgDensityFiles(ff).name;
        msg = sprintf('Loading destination: %s ...',fgName);
        disp(msg);
        ni = readFileNifti(fgName);
        fgImgs(:,ff) = double(ni.data(img_wm>0)>0);
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

%     ccMatrix = zeros(length(paramData(1).values),length(paramData(2).values));
% 
%     for pp1 = 1:length(paramData(1).values)
%         for pp2 = 1:length(paramData(2).values)
%             iter = (pp1-1)*length(paramData(2).values) + pp2;
%             fgDensityDstname = sprintf('%s_%s_%g_%s_%g_k3_0_fd_image.nii.gz',fgDensityDstFileRoot,paramData(1).name,paramData(1).values(pp1),paramData(2).name, paramData(2).values(pp2));
%             msg = sprintf('Comparing to %s ...',fgDensityDstname);
%             disp(msg);
%             ni = readFileNifti(fullfile(subjDir,fgDensityDstname));
%             fgDstImg = ni.data;
%             cc = corrcoef(fgSrcImg(:),fgDstImg(:));
%             ccMatrix(pp1,pp2) = cc(1,2);
%             msg = sprintf('CC %g',cc(1,2));
%             disp(msg);
%             clear('fgDstImg');
%             msg = sprintf('Finished %g%%',100*((pp1-1)*length(paramData(2).values)+pp2)/(length(paramData(1).values)*length(paramData(2).values)));
%             disp(msg);
%         end
%     end

else
    % All pairs comparisons
    
    % Get all density filenames to compare
    fgDensityFiles = dir([fgDensityDstFileRoot '*nii.gz']);
    % Fill paramData with filenames that we used to compare
    paramData = [];
    
    % Loop over files collecting images
    for ff = 1:length(fgDensityFiles)
        fgName = fgDensityFiles(ff).name;
        msg = sprintf('Loading %s ...',fgName);
        disp(msg);
        ni = readFileNifti(fgName);
        fgImgs(:,ff) = double(ni.data(img_wm>0)>0);
        clear ni;
        [foo, temp_name, ext] = fileparts(fgName);
        paramData(ff).name = [temp_name ext];
    end
    
    % Compare all of the densities
    ccMatrix = zeros(length(fgDensityFiles));
    for ii = 1:length(fgDensityFiles)
        disp(['Comparing all with ' fgDensityFiles(ii).name]);
        for jj = ii+1:length(fgDensityFiles)
            img1 = fgImgs(:,ii);
            img2 = fgImgs(:,jj);
            cc = corrcoef(img1(:),img2(:));
            ccMatrix(ii,jj) = cc(1,2);
            disp(['CC: ' num2str(cc(1,2))]);
        end
    end
    
    % Get the full symmetric matrix
    ccMatrix = ccMatrix + ccMatrix'.*(ones(length(fgDensityFiles))-eye(length(fgDensityFiles)));
end

save(ccFile,'ccMatrix','paramData');
msg = sprintf('Saved output to %s.',ccFile);
disp(msg);

