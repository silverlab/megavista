function [dt6s,allroiPairs] = ctr_FFA_setDt6RoiPairs

% Usage: [dt6s,allroiPairs] = ctr_FFA_setDt6RoiPairs
%
% dt6s = Cell array. Each cell will have the full path to a dt6 file, with
% the number of cells equal to the number of subjects.
%
% allroiPairs = Cell array containing structs. The number of cells is equal
% to the number of subjects (x). The number of indicies within that cell is
% equal to the number of ROI pairs (y), aka unique structs specific to each
% subject. Example: allroiPairs{x}(y).field. 
% Each struct has 3 fields:
%       .roi1 = full path to the first ROI in a pair 
%       .roi2 = full path to the second ROI in a pair 
%       .fname = string that will be added to the ctrScript and ctrSampler 
%        file names for that ROI pair.
%
% 2008.09.18 DY & MP

%% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\sfn\'; %dp_presentation';
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/sfn'; % /dp_presentation';
end

cd(dtiDir); s = dir('*0*');  subs={s.name}; dt6s={}; allroiPairs={};
% To test this we're only using the first two subjects acg & dy.
% subs=subs(1:2);
% To run subs jpb and kll
% subs = subs([4 15]);

% SFN test %%%%%%%%%%%%%%%%%%%%%%%%%DELETE THIS%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subs=subs(1); fprintf('\nbeware: you are only processing the first subject');

for ii=1:length(subs)
    dt6s{ii}=fullfile(dtiDir,subs{1},'dti30','dt6.mat');
    
    allroiPairs{ii}(1).roi1 = fullfile(mrvDirup(dt6s{1},1),'ROIs','functional','RFFA_MBvACIO_p3d_gmwm1.mat');
    allroiPairs{ii}(1).roi2 = fullfile(mrvDirup(dt6s{1},1),'ROIs','functional','RH_lateral_sfn_gmwm1.mat');
    allroiPairs{ii}(1).fname = 'SFN';

end

return

%% Other code if you have multiple pairs and different pairs for each
%% person. 

%     % roiPairs(1).roi1 = fullfile(mrvDirup(dt6s{1},1),'ROIs','functional','RFFA_MBvACIO_dilate8.mat');
%     % roiPairs(1).roi2 = fullfile(mrvDirup(dt6s{1},1),'ROIs','functional','RLOf_MBvACIO_dilate8.mat');
%     % roiPairs(1).fname = 'RFFA_RLOf';
%     % 
%     % roiPairs(2).roi1 = fullfile(mrvDirup(dt6s{1},1),'ROIs','functional','RFFA_MBvACIO_dilate8.mat');
%     % roiPairs(2).roi2 = fullfile(mrvDirup(dt6s{1},1),'ROIs','functional','RPPA_IOvACMB_dilate8.mat');
%     % roiPairs(2).fname = 'RFFA_RPPA';
%     % 
%     % roiPairs(3).roi1 = fullfile(mrvDirup(dt6s{1},1),'ROIs','functional','RFFA_MBvACIO_dilate8.mat');
%     % roiPairs(3).roi2 = fullfile(mrvDirup(dt6s{1},1),'ROIs','functional','RLO_ACvT_dilate8.mat'); 
%     % roiPairs(3).fname = 'RFFA_RLO';
% 
% allroiPairs=roiPairs; 
% clear roiPairs;
% 
% % ROI Pairs for sub{2}
%     roiPairs(1).roi1 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','RFFA_disk10.mat');
%     roiPairs(1).roi2 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','RLO_disk10.mat'); 
%     roiPairs(1).fname = 'RFFA_RLO';
% 
%     roiPairs(2).roi1 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','LFFA_disk10.mat');
%     roiPairs(2).roi2 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','LLO_disk10.mat'); 
%     roiPairs(2).fname = 'LFFA_LLO';
% 
%     % roiPairs(1).roi1 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','RFFA_MBvACIO_dilate8.mat');
%     % roiPairs(1).roi2 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','RLOf_MBvACIO_dilate8.mat'); 
%     % roiPairs(1).fname = 'RFFA_RLOf';
%     % 
%     % roiPairs(2).roi1 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','RFFA_MBvACIO_dilate8.mat');
%     % roiPairs(2).roi2 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','RPPA_IOvACMB_dilate8.mat'); 
%     % roiPairs(2).fname = 'RFFA_RPPA';
%     % 
%     % roiPairs(3).roi1 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','RFFA_MBvACIO_dilate8.mat');
%     % roiPairs(3).roi2 = fullfile(mrvDirup(dt6s{2},1),'ROIs','functional','RLO_ACvT_dilate8.mat'); 
%     % roiPairs(3).fname = 'RFFA_RLO';
% 
% % allRoiPairs now contains roi1 and roi2 pairs for each subject
% allroiPairs={allroiPairs roiPairs};
