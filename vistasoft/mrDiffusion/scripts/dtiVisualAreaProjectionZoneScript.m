figNum = gcf;
h = guidata(figNum);

clear fg;
roiNames = {h.rois.name};
minDist = 3.0;
mutuallyExcludeUnilateral = 0;
mutuallyExcludeBilateral = 0;

fgOrig = h.fiberGroups(h.curFiberGroup);
disp(['Using fiber group ' fgOrig.name '.']);

lRois(1) = h.rois(strmatch('LV3AB', roiNames));
lRois(2) = h.rois([strmatch('LV12fov', roiNames), strmatch('LV123fov', roiNames)]);
lRois(3) = h.rois(strmatch('LV12periph', roiNames));
rRois(1) = h.rois(strmatch('RV3AB', roiNames));
rRois(2) = h.rois([strmatch('RV12fov', roiNames), strmatch('RV123fov', roiNames)]);
rRois(3) = h.rois(strmatch('RV12periph', roiNames));

% Process the Left
[fg(1:4),contentiousFibers] = dtiIntersectFibersWithRoi(h, {'DIVIDE','endPoints'}, minDist, lRois, fgOrig);
percentContentious = sum(contentiousFibers)/length(fgOrig.fibers)*100
fg(1).colorRgb = [20 200 20];
fg(1).name = lRois(1).name;
fg(2).colorRgb = [20 90 200];
fg(2).name = lRois(2).name;
fg(3).colorRgb = [235 165 20];
fg(3).name = lRois(3).name;
fg(4).colorRgb = [200 20 20];
fg(4).name = ['not_' lRois(1:3).name];

% Process the Right
[fg(5:8),contentiousFibers] = dtiIntersectFibersWithRoi(h, {'DIVIDE','endPoints'}, minDist, rRois, fgOrig);
percentContentious = sum(contentiousFibers)/length(fgOrig.fibers)*100
fg(5).colorRgb = [20 200 20];
fg(5).name = rRois(1).name;
fg(6).colorRgb = [20 90 200];
fg(6).name = rRois(2).name;
fg(7).colorRgb = [235 165 20];
fg(7).name = rRois(3).name;
fg(8).colorRgb = [200 20 20];
fg(8).name = ['not_' rRois(1:3).name];

% Find homo-hetero
% Here we AND each of the 6 FGs with each of the ROIs
% The order of things matters here- the fiber group order will be 
% [1 2 3 5 6 7], which should be [LV3AB LV12f LV12p RV3AB RV12f RV12p]
% so we'll want the ROI order to be:
fiberCounts = {};
for(ii=1:3)
    totalNumFibers = length(fg(ii).fibers);
    [tmpFg,contentiousFibers] = dtiIntersectFibersWithRoi(h, {'DIVIDE','endPoints'}, minDist, rRois, fg(ii));
    percentContentious = sum(contentiousFibers)/length(fg(ii).fibers)*100
    for(jj=1:3)
        fg(end+1) = tmpFg(jj);
        fiberCounts{end+1} = {tmpFg(jj).name, length(tmpFg(jj).fibers), totalNumFibers};
    end
end
for(ii=5:7)
    totalNumFibers = length(fg(ii).fibers);
    [tmpFg,contentiousFibers] = dtiIntersectFibersWithRoi(h, {'DIVIDE','endPoints'}, minDist, lRois, fg(ii));
    percentContentious = sum(contentiousFibers)/length(fg(ii).fibers)*100
    for(jj=1:3)
        fg(end+1) = tmpFg(jj);
        fiberCounts{end+1} = {tmpFg(jj).name, length(tmpFg(jj).fibers), totalNumFibers};
    end
end

fprintf('\n\n');
for(ii=1:length(fiberCounts))
    fc = fiberCounts{ii}{2}; fcTot = fiberCounts{ii}{3};
    fprintf('%40s\t% 4d /% 4d\t%0.0f%%\n', fiberCounts{ii}{1}, fc, fcTot, fc/fcTot*100);
end

subject = h.subName;
originalFiberGroup = fgOrig.name;
date = datestr(now,0);
notes = 'see dtiVisualAreaProjectionZone script for more info.';
defaultFname = '//white/u2/bob/callosal_areaMaps/data_files/[subname]_visAreaFibers.csv';
% Save tab-delimited file with fiber counts
[f,p] = uiputfile('*.csv','Save analysis (spreadsheet)...',defaultFname);
if(~isnumeric(f))
    fp = fopen(fullfile(p,f),'at');
    fprintf(fp, '\n\n%s\n%s\n%s\n', subject, originalFiberGroup, date);
    for(ii=1:length(fiberCounts))
        fc = fiberCounts{ii}{2}; fcTot = fiberCounts{ii}{3};
        fprintf(fp, '%s,%d,%d\n', fiberCounts{ii}{1}, fc, fcTot);
    end
    fclose(fp);
end
% [j,f] = fileparts(f);
% [f,p] = uiputfile('*.mat','Save analysis (mat file)...',fullfile(p,[f '.mat']));
% if(~isnumeric(f))
%     save(fullfile(p,f), 'fg','names','totals','notes','date','subject','originalFiberGroup');
% end

% Run this if you want to load *all* these fiber groups to dtiFiberUI:
if(1)
for(ii=1:length(h.fiberGroups))
    h.fiberGroups(ii).visible = 0;
end
for(ii=[1:3,5:7])
    [h, fgNum] = dtiAddFG(fg(ii), h);
end
guidata(figNum,h);
end

if(0)
    h = guidata(figNum);
    hemi = 'L';
    sc = h.subName(1:2);
    dataDir = '/white/u2/bob/callosal_areaMaps/Figures/04 callosal segmentation/support/';
    mkdir(dataDir,sc);
    dataDir = fullfile(dataDir, sc);
    for(talYcoord = [-40,-45,-50,-55,-60])
        fname = fullfile(dataDir, [sc '_' hemi num2str(talYcoord)]);
        curPosTal = [0 talYcoord 0];
        set(h.editPositionTal, 'String', sprintf('%.1f, %.1f, %.1f', curPosTal));
        curPosAcpc = mrAnatTal2Acpc(h, curPosTal);
        set(h.editPosition, 'String', sprintf('%.1f, %.1f, %.1f', curPosAcpc));
        h = dtiRefreshFigure(h, 0);
        guidata(figNum, h);
        dtiSaveImageSlicesOverlays(h,1,0,0,fname);
    end
end
