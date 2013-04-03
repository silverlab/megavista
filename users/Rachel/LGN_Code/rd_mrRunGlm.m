% rd_mrRunGlm.m
%
% vw is view, eg. getCurView
% dt is dataType, eg. 1 (for the Originals dataType)
% scans is a 1xnScans vector of scan numbers, eg. 2:9
% params is a structure with event-related parameters, including extra
% parameters, such as 'annotation'.
%
% if anything is empty or left out, applyGlm will use the defaults.
% see applyGlm for more info.
%
% Rachel Denison
% 12 April 2012

vw = INPLANE{1};
dt = 1;
scanSets = {2,3,4,5,6,7,8,9};
% scanSets = {2};
params = [];
newDtName = [];

for iSS = 1:numel(scanSets)
    scans = scanSets{iSS};
    [vw, newScan] = applyGlm(vw, dt, scans, params, newDtName);
end