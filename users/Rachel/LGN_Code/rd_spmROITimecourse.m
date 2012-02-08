% rd_spmROITimecourse.m

%% extract mean (or summary) data from rois
roiFiles = spm_get(Inf,'*roi.mat', 'Select ROI files');
designPath = spm_get(1, 'SPM.mat', 'Select SPM.mat');
R = maroi('load_cell', roiFiles); % make maroi ROI objects
D = mardo(designPath);  % make mardo design object
mY = get_marsy(R{:}, D, 'mean'); % extract data into marsy data object
Y  = summary_data(mY);  % get summary time course(s)

%% extract time series from individual ROI voxels
imFiles = spm_get(Inf,'r*.img', 'Select epi files');
R = maroi('rois/sphere_4mm_roi2_roi.mat');
[Y multv vXYZ mat] = getdata(R, imFiles, 'l');