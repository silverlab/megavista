% rd_combineROIs.m

% Combine 2 ROIs, ie. perfom some logical operation on their coordinates,
% as specified by 'combineMethod'.
% Make a new ROI with these coordinates and save it.
% Default is to save the new ROI in the session 1 ROI directory.

%% setup
combineMethod = 'union'; % 'intersect','union','xor','a not b'
color = 'k'; % 'w' for intersect, 'k' for union

saveNewROI = 1;

%% file i/o
roiName = 'ROI201';
roiSaveName = 'ROI201-u7T17T2';

studyDir = '/Volumes/Plata1/LGN/Scans';

% session1Dir = '3T/RD_20120205_session/RD_20120205_n';
% session2Dir = '7T/RD_20111214_session/RD_20111214';

% session1Dir = '3T/AV_20111117_session/AV_20111117_n';
% session2Dir = '3T/AV_20111128_session/AV_20111128_n';

% session1Dir = '3T/AV_20111117_session/AV_20111117_n';
% session2Dir = '7T/AV_20111213_session/AV_20111213';

% session1Dir = '3T/AV_20111128_session/AV_20111128_n';
% session2Dir = '7T/AV_20111213_session/AV_20111213';

session1Dir = '7T/KS_20111212_session/KS_20111212_15mm';
session2Dir = '7T/KS_20111214_session/KS_20111214';

roiDir = 'Volume/ROIs';

roi1Path = sprintf('%s/%s/%s/%s.mat', studyDir, session1Dir, roiDir, roiName);
roi2Path = sprintf('%s/%s/%s/%s.mat', studyDir, session2Dir, roiDir, roiName);

roiSavePath = sprintf('%s/%s/%s/%s.mat', studyDir, session1Dir, roiDir, roiSaveName);

%% load ROIs and get coords
roi1 = load(roi1Path);
roi2 = load(roi2Path);

coords1 = roi1.ROI.coords;
coords2 = roi2.ROI.coords;

%% find intersection of coords 
% use mrVista function combineCoords
coords = combineCoords(coords1, coords2, combineMethod);

%% make new ROI file
ROI = roi1.ROI;
ROI.name = roiSaveName; % added this line on 2013-01-15
ROI.color = color;
ROI.coords = coords;
ROI.created = datestr(now);
ROI.modified = datestr(now);

%% save ROI
if saveNewROI
    save(roiSavePath,'ROI');
end
