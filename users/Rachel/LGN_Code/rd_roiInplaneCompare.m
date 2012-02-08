% rd_roiInplaneCompare.m
%
% compare tseries from the inplane ("original") data and the roi data from
% the lgn pipeline

% read in time series from 4d nifti file
inplaneDir = 'Inplane/Original/TSeries/Analyze';
% inplaneScan1 = readFileNifti([inplaneDir '/Scan1.img']);

% figure

for i = 96

    roi_vox_num = i;

    epi_roi_coords = lgnROI3Coords(:,roi_vox_num);
    inplane_coords = epi_roi_coords([2 1 3]);

    roi_vox = lgnROI3(:,roi_vox_num);
    inplane_vox = squeeze(inplaneScan1.data(inplane_coords(1), inplane_coords(2), inplane_coords(3), :));

    % now re-baseline and scale inplane time series to match roi time series
    basediff = double(inplane_vox(1) - roi_vox(1));
    scale = double(range(inplane_vox)/range(roi_vox));
    inplane_vox_bs = (double(inplane_vox) - basediff)/scale + roi_vox(1);
    
    % or try just the percent signal change
    % 1) divide by the mean, 2) subtract 1 (the new mean), 3) multiply by 100 (%)
    inplane_vox_percent = (double(inplane_vox)/mean(inplane_vox) - 1)*100;

    clf
    hold on
    plot(roi_vox,'k')
    plot(inplane_vox_percent,'b')
    title(['roi vox number ' num2str(roi_vox_num)])
    pause(.5)

end