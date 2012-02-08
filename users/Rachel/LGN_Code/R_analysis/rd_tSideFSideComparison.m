% rd_tsideFSideComparison.m
%
% Compare time-side analysis done in R to frequency-side analysis done in
% Matlab.

%% load ROI data with freq-side analysis
load lgnROI1-2Data_AvgScan1-4_20101028
csvwrite('dat_files/lgnROI1-2_AvgScan1-4_20101028.dat',roi) % export for R

%% load time-side analysis info from R, indices of voxels with significant
% amp fits, divided into two ROIs based on phase
load('mat_files/sigVoxROIIdx.mat')

%% initializations
nvox = size(lgnROI3,2);

%% show z-score and roi mapping for each voxel
figure
scatter(1:nvox, data3.zScore)
hold on
scatter(roi1_idx, data3.zScore(roi1_idx),'.r')
scatter(roi2_idx, data3.zScore(roi2_idx),'.y')
legend('all voxels','ROI1','ROI2')
xlabel('Voxel number')
ylabel('z-score')

%% coordinates of significant voxels
roi1_coords = lgnROI3Coords(:,roi1_idx);
roi2_coords = lgnROI3Coords(:,roi2_idx);
zthresh_coords = lgnROI3Coords(:,zThresh(1).voxNums);

figure
hold on
scatter3(roi1_coords(1,:), roi1_coords(2,:), roi1_coords(3,:))
scatter3(roi2_coords(1,:), roi2_coords(2,:), roi2_coords(3,:),'r')
scatter3(zthresh_coords(1,:), zthresh_coords(2,:), zthresh_coords(3,:),'.g')