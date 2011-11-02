function dti_Longitude_TrimCstFibersBelowROIs(fg.fibers, roi)
%Trim CST fibers by removing nodes below CST rois

%Elena wrote it 12/16

%This returns all the coordinates that are under

fg = dtiClipFiberGroup(myfg, [], [], []);


cellfun(@(x) x(:, x(3, :)<min(roi.coords(:, 3))), fg.fibers, 'UniformOutput',false)
