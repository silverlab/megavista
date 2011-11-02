% Script for computing fiber density for many path distributions

subject = 'md';
if(strcmp(subject,'sil'))
    dataDir = 'c:\cygwin\home\sherbond\images\sil_nov05\dti3_ser7\analysis';
    dt6File = fullfile(dataDir,'dti3_ser7_dt6.mat');
    fgDir = 'fibers\gastroc';
    roiFile = fullfile(dataDir,'ROIs','tendon_plate.mat');
    fgFilenames = dir(fullfile(dataDir,fgDir,'paths*.dat'));
elseif(strcmp(subject,'tony'))
    dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis';
    dt6File = fullfile(dataDir,'dti3_dt6.mat');
    fgDir = 'bin\metrotrac\tendon_small';
elseif(strcmp(subject,'thor'))
    dataDir = 'c:\cygwin\home\sherbond\images\thor_nov05\dti4_ser11\analysis';
    dt6File = fullfile(dataDir,'dti4_ser11_dt6.mat');
    fgDir = 'fibers\gastroc';
elseif(strcmp(subject,'md'))
    dataDir = 'c:\cygwin\home\sherbond\images\md040714';
    dt6File = fullfile(dataDir,'md040714_dt6.mat');
    fgDir = 'bin\metrotrac\fine_param_search';
    fgFilenames = dir(fullfile(dataDir,fgDir,'paths*1_fd_image.nii.gz'));
else
    error('Unknown subject.');
end

% XXX Assume that the repeat number is less than 10 and the last number in the
% filename and that the numbers are consecutive NO SKIPPING

output_filename = 'ids_corrs.mat';

vecids = zeros(length(fgFilenames),1);
meanids = zeros(length(fgFilenames),1);
% Loop through each parameter setting as expressed by unique filenames.
for ff = 1:length(fgFilenames)
    % Loop over number of repeats
    subFGName = fgFilenames(ff).name(1:strfind(fgFilenames(ff).name,'_fd_image.nii.gz')-2);
    fgRepeatFilenames = dir(fullfile(dataDir,fgDir,[subFGName '*.nii.gz']));
    for rr = 1:length(fgRepeatFilenames)
        fgName = fgRepeatFilenames(rr).name;
        msg = sprintf('Loading %s ...',fgName);
        disp(msg);
        ni = readFileNifti(fullfile(dataDir,fgDir,fgName));
        repeatNum = round(str2double(fgRepeatFilenames(rr).name(strfind(fgRepeatFilenames(rr).name,'_fd_image.nii.gz')-1)));
        fgImgs(:,:,:,repeatNum) = ni.data;
    end
    % Compare all of the densities
    ccMatrix = zeros(length(fgRepeatFilenames));
    for ii = 1:length(fgRepeatFilenames)
        for jj = ii+1:length(fgRepeatFilenames)
            img1 = fgImgs(:,:,:,ii);
            img2 = fgImgs(:,:,:,jj);
            cc = corrcoef(img1(:),img2(:));
            ccMatrix(ii,jj) = cc(1,2);
        end
    end
    % Get the full symmetric matrix
    ccMatrix = ccMatrix + ccMatrix'.*(ones(length(fgRepeatFilenames))-eye(length(fgRepeatFilenames)));
    
    % Get the Id for the max mean correlation and store it
    meancc = 4/3*mean(ccMatrix,2) % 4/3 is to remove the effect of the zero in the mean
    [junk, max_ind] = max(meancc);
    vecids(ff) = max_ind;
    meanids(ff) = meancc(max_ind);
       
    msg = sprintf('Max ID: %d',max_ind);
    disp(msg);
    msg = sprintf('Finished %g%%',100*ff/length(fgFilenames));
    disp(msg);
end


save(fullfile(dataDir,fgDir,output_filename),'vecids','meanids');

disp('Finished');
vecids

% numrois = 32;
% numrepeats = 4;
% vecids = zeros(numrois,1);
% meanids = zeros(numrois,1);
% 
% for rr = 1:numrois
%     % read all the images
%     
%     for ii = 1:numrepeats        
%         % make image filename
%         fgName = sprintf('paths_%d_%d_fd_image.nii.gz',ii,rr);
%         msg = sprintf('Loading %s ...',fgName);
%         disp(msg);
%         ni = readFileNifti(fullfile(dataDir,fgDir,fgName));
%         fgImgs(:,:,:,ii) = ni.data;
%     end
%     
%     % Compare all of the densities
%     ccMatrix = zeros(numrepeats);
%     for ii = 1:numrepeats
%         for jj = ii+1:numrepeats
%             img1 = fgImgs(:,:,:,ii);
%             img2 = fgImgs(:,:,:,jj);
%             cc = corrcoef(img1(:),img2(:));
%             ccMatrix(ii,jj) = cc(1,2);
%         end
%     end
%             
%     % Get the full symmetric matrix
%     ccMatrix = ccMatrix + ccMatrix'.*(ones(numrepeats)-eye(numrepeats));
%     
%     % Get the Id for the max mean correlation and store it
%     meancc = 4/3*mean(ccMatrix,2) % 4/3 is to remove the effect of the zero in the mean
%     [junk, max_ind] = max(meancc);
%     vecids(rr) = max_ind;
%     meanids(rr) = meancc(max_ind);
%     
%     msg = sprintf('Max ID: %d',max_ind);
%     disp(msg);
%     msg = sprintf('Finished %g%%',100*rr/numrois);
%     disp(msg);
% end
% 
% save(fullfile(dataDir,fgDir,output_filename),'vecids','meanids');
% 
% disp('Finished');
% vecids
% 
% % Take the selected path distributions and copy them somewhere
% for rr = 1:numrois
%     fgImageName = sprintf('paths_%d_%d_fd_image.nii.gz',vecids(rr),rr);
%     fgName = sprintf('paths_%d_%d_dat',vecids(rr),rr);
% end
