% rd_spmROIDataFromImg2.m
%
% This uses MarsBar to extract ROI data from image files (written to work
% for 3D image files, don't know what happens with 4D).
%
% file_base should be the path to an ROI saved from MarsBar.
% The default save path is the ROI path and name, plus an extension of the
% specified analysis_name.
% im_files is a files x letters in file name string array. It would be nice
% if a more flexible array (like a cell array) could be used -- I don't
% remember if I tried this.
%
% Rachel Denison
% 2 April 2012

% setup
file_base = '/roipath/roiname';
analysis_name = 'betas';
savefile = 0;

% file i/o
im_files = strvcat('beta_0001.img', 'beta_0002.img', ...
    'beta_0003.img', 'beta_0004.img', 'beta_0005.img', ...
    'beta_0006.img');
roi_file = sprintf('%s.mat', file_base);
save_path = sprintf('%s_%s.mat', file_base, analysis_name);

% load roi and extract data
roi_obj = maroi(roi_file);
[Y multv vXYZ mat] = getdata(roi_obj, im_files, 'l');
n_voxels = size(Y, 2);

% save
if savefile
    save(savepath, 'im_files', 'roi_obj', 'Y', 'multv', 'vXYZ', 'mat')
end



