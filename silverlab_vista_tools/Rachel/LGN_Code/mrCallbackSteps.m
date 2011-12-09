% Cor Anal
Selected Menu Item: 
 Label: Average tSeries 
 Handle: 69.002075 
 Callback: averageTSeries(INPLANE{1}, 'dialog');

Selected Menu Item: 
 Label: Compute corAnal (current scan) 
 Handle: 85.002075 
 Callback: INPLANE{1}=computeCorAnal(INPLANE{1},getCurScan(INPLANE{1})); INPLANE{1}=refreshScreen(INPLANE{1});
 
% GLM
Selected Menu Item: 
 Label: Apply GLM, scan group 
 Handle: 470.002075 
 Callback: INPLANE{1} = applyGlm(INPLANE{1});

% Time Course UI
Selected Menu Item: 
 Label: Scan Group 
 Handle: 484.002075 
 Callback: tc_plotScans(INPLANE{1},1);
 
Selected Menu Item: 
 Label: Visualize GLM Results 
 Handle: 1547.063843 
 Callback: TMP_H = get(gcbo, 'UserData'); TMP = get(gcf, 'UserData'); set(TMP_H, 'Checked', 'off'); set(gcbo, 'Checked', 'on'); TMP.plotType = find(TMP_H==gcbo); set(gcf, 'UserData', TMP); timeCourseUI; clear TMP_H TMP; 
 
Selected Menu Item: 
 Label: Dump Data to Workspace 
 Handle: 1587.063843 
 Callback: tc_dumpDataToWorkspace;
 
% Multi Voxel UI
Selected Menu Item: 
 Label: Scan Group 
 Handle: 488.002075 
 Callback: mv_plotScans(INPLANE{1},1);
 
Selected Menu Item: 
 Label: Visualize GLMs 
 Handle: 1546.064209 
 Callback: mv_selectPlotType(9); mv_visualizeGlm; 
 
Selected Menu Item: 
 Label: Dump Data to Workspace 
 Handle: 1571.064209 
 Callback: tc_dumpDataToWorkspace;
 
% GLM Contrast Maps
Selected Menu Item: 
 Label: Compute Contrast Map 
 Handle: 471.002075 
 Callback: INPLANE{1} = contrastGUI(INPLANE{1});
 

 
 
 
 