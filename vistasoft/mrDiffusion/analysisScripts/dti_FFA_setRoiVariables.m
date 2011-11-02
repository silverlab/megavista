function [intersectRois,roiList]=dti_FFA_setRoiVariables(roi1,roi1name,roi2,roi2name,roi3,roi3name)

% This is modularized because I call it so many times, but it's very
% specialized. It creates the cell array variables INTERSECTROIS and
% ROILIST. INTERSECTROIS is a cell array of ROIs to intersect with the
% first ROI (roi1), out of two possible choices (roi2,roi3). ROILIST is a
% cell array of prefix strings for file naming purposes later on.  
%
% Input arguments are the full path to three ROIs: ROI1,ROI2,ROI3
% as well as the prefix strings for each of these ROIs
%
% ROI1 = seed ROI
% ROI2 and ROI3 = potential intersecting ROIs
%
% DY 04/01/2008
% DY 04/02/2008: added second ELSE option to deal with no ROIs found

roiList{1} = roi1name;

% Create list of intersecting ROIs, depending on if they exist or not.
if(exist(roi2,'file') && strcmp(roi2(end-3:end),'.mat'))
    intersectRois{1}=roi2;
    roiList{2}=roi2name;
    if(exist(roi3,'file') && strcmp(roi3(end-3:end),'.mat'))
        intersectRois{2}=roi3;
        roiList{3}=roi3name;
    end
elseif(exist(roi3,'file') && strcmp(roi3(end-3:end),'.mat'))
    intersectRois{1}=roi3;
    roiList{2}=roi3name;
else % if no suitable intersecting ROIs exist, pass empties
    intersectRois{1}='';
    roiList{1}='';
end

