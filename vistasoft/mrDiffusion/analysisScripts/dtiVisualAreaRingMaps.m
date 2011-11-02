figNum = gcf;
h = guidata(figNum);

clear fg;
roiNames = {h.rois.name};
minDist = 1.0;
%fgLeft = h.fiberGroups(h.curFiberGroup);
fgLeft = h.fiberGroups(1);
fgRight = h.fiberGroups(2);

lRois(1) = h.rois(strmatch('LV3A', roiNames));
lRois(2) = h.rois(strmatch('LV12d', roiNames));
lRois(3) = h.rois(strmatch('LV12v', roiNames));
lRois(4) = h.rois(strmatch('LV34', roiNames));
rRois(1) = h.rois(strmatch('RV3A', roiNames));
rRois(2) = h.rois(strmatch('RV12d', roiNames));
rRois(3) = h.rois(strmatch('RV12v', roiNames));
rRois(4) = h.rois(strmatch('RV34', roiNames));

disp(['Using fiber group ' fgLeft.name '.']);
[fg(1:5),contentiousFibers] = dtiIntersectFibersWithRoi(h, {'DIVIDE','endPoints'}, minDist, lRois, fgLeft);
percentContentious = sum(contentiousFibers)/length(fgLeft.fibers)*100
fg(1).colorRgb = [20 200 20];
fg(1).name = lRois(1).name;
fg(2).colorRgb = [20 200 200];
fg(2).name = lRois(2).name;
fg(3).colorRgb = [200 20 200];
fg(3).name = lRois(3).name;
fg(4).colorRgb = [200 20 20];
fg(4).name = lRois(4).name;
fg(5).colorRgb = [200 200 20];
fg(5).name = ['not_' lRois(1:3).name];

disp(['Using fiber group ' fgRight.name '.']);
[fg(6:10),contentiousFibers] = dtiIntersectFibersWithRoi(h, {'DIVIDE','endPoints'}, minDist, rRois, fgRight);
percentContentious = sum(contentiousFibers)/length(fgRight.fibers)*100
fg(6).colorRgb = [20 200 20];
fg(6).name = rRois(1).name;
fg(7).colorRgb = [20 200 200];
fg(7).name = rRois(2).name;
fg(8).colorRgb = [200 20 200];
fg(8).name = rRois(3).name;
fg(9).colorRgb = [200 20 20];
fg(9).name = rRois(4).name;
fg(10).colorRgb = [200 200 20];
fg(10).name = ['not_' rRois(1:3).name];

fg(11) = dtiMergeFiberGroups(fg(1),fg(6));
fg(12) = dtiMergeFiberGroups(fg(2),fg(7));
fg(13) = dtiMergeFiberGroups(fg(3),fg(8));
fg(14) = dtiMergeFiberGroups(fg(4),fg(9));

for(ii=1:length(h.fiberGroups))
    h.fiberGroups(ii).visible = 0;
end
for(ii=[1:4,6:9,11:14])
    [h, fgNum] = dtiAddFG(fg(ii), h);
end
guidata(figNum,h);

h = guidata(figNum);
grayView = getSelectedVolume;
nBins = 8;
dataRange = [0,2*pi];
bins(:,1) = linspace(dataRange(1), dataRange(2)*((nBins-1)/nBins), nBins)';
bins(:,2) = bins(:,1) + dataRange(2)*(1/nBins);
bins(end,2) = bins(end,2)+dataRange(2)*0.01;
whichLRlist = {'left','right'};
ssPath = '/tmp/images/';
clear ssSub;
% ssSub = 'bw'; ssSub = 'mbs'; ssSub = 'rd'; ssSub = 'sn'; 
eval('mkdir(ssPath, ssSub);','');
ssPath = fullfile(ssPath, ssSub);
% Do left and right V3A
lFGs = dtiSplitByFunctional(h, grayView, fg(1), bins, 'left', minDist);
rFGs = dtiSplitByFunctional(h, grayView, fg(6), bins, 'right', minDist);
for(jj=1:length(h.fiberGroups))
    h.fiberGroups(jj).visible = 0;
end
for(jj=1:length(lFGs))
    [h, fgNum] = dtiAddFG(dtiMergeFiberGroups(lFGs(jj),rFGs(jj),['R' lFGs(jj).name '_Ring']), h);
end
guidata(figNum,h);
h = guidata(figNum);
dtiSaveImageSlicesOverlays(h, 1, 0, 0, fullfile(ssPath,['LRV3A_Ring_ss8']), 8);
dtiSaveImageSlicesOverlays(h, 1, 0, 0, fullfile(ssPath,['LRV3A_Ring_ss4']), 4);

%     for(ii=[1:4,6:9])
%         newFGs = dtiSplitByFunctional(h, grayView, fg(ii), bins, whichLR, minDist);
%         for(jj=1:length(h.fiberGroups))
%             h.fiberGroups(jj).visible = 0;
%         end
%         for(jj=1:length(newFGs))
%             newFGs(jj).name = [newFGs(jj).name '_' whichLR 'Ring'];
%             [h, fgNum] = dtiAddFG(newFGs(jj), h);
%         end
%         guidata(figNum,h);
%         mkdir(ssPath, 'ss4'); mkdir(ssPath, 'ss8');
%         dtiSaveImageSlicesOverlays(h, 1, 0, 0, fullfile(ssPath,'ss8',[fg(ii).name '_' whichLR 'Ring_ss8']), 8);
%         dtiSaveImageSlicesOverlays(h, 1, 0, 0, fullfile(ssPath,'ss4',[fg(ii).name '_' whichLR 'Ring_ss4']), 4);
%     end
end


