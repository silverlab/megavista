function dti_Longitude_WMGMGrowthCurves
cd C:\PROJECTS\longitudinal_reading\data;
%Step1: plot/display SPM segmentation-based data
%Step2: plot/display SIENAX segmentation-based data. 

if 0
%STEP1 (SPM): FETCH TISSUE VOLUME DATA
%regrestimates: obtained from HLM fits  (rows: wm, gm, total); 
regr_estimates=[247.7 11.07; 722.1 11.41; 1290.1 17.7];
significance={'**', '**', '**'};

load reading_longitud_wmgmcsf;
%wm_all->wm_cc3 transform: wm_cc3=wm_all/(255*1000)
%Units are meaninfull. Total_cc3 is in the range of 1500 cubic cm, which is
%what we expect. 
wm_cc3=wm_all/(1000); 
gm_cc3=gm_all/(1000); 
total_cc3=(wm_all+csf_all+gm_all)/(1000);

%FETCH BEHAVIORAL DATA
load('subjectCodes27.mat'); %27 ptpnts
behaveDataFile = 'C:\PROJECTS\longitudinal_reading\data\read_behav_measures_longitude.csv';
DTIAge=getDTIAge(subjectCodes,  behaveDataFile);

%PLOT
plotGMWMgrowthCurves(wm_cc3, gm_cc3, total_cc3, regr_estimates, significance, DTIAge, '(SPM segmented)');
end

%%%TODO: Impose gender-specific regression curves. 
%%%The coefficient come from three solutions, one per each 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%STEP2 WM/GM/Total %TODO: is there a more transparent way to read these in
%from the SPSS output?
NV_regr_estimates=[598165.36 8202.44;  1102712.17 -7781.22; 1700712.22 435.41; ]./1000;
NVsignificance={'**', '*', ''};

UNV_regr_estimates=[369828.06 11695.28; 706930.56 2464.98; 1074861.17 14317.22]./1000;
UVsignificance={'**', '', '**'};

%these estimates were obtained before the data were turned to CC3 units.
%Hence neeeded to be rescaled. 

%FETCH TISSUE VOLUME DATA
load reading_longitud_wmgmcsfSienax; 

%FETCH BEHAVIORAL DATA
load('subjectCodesAll4Years.mat'); %28 ptpnts
behaveDataFile = 'C:\PROJECTS\longitudinal_reading\data\read_behav_measures_longitude.csv';
DTIAge=getDTIAge(subjectCodes,  behaveDataFile);

%PLOT
%Normalized volumes
plotGMWMgrowthCurves(wm_nv/(1000), gm_nv/(1000), total_nv/(1000), NV_regr_estimates, NVsignificance, DTIAge, '(sienax normalized)');
%Unnormalized volumes
plotGMWMgrowthCurves(wm_uv/(1000), gm_uv/(1000), total_uv/(1000), UNV_regr_estimates,UVsignificance, DTIAge, '(sienax unnormalized)');


return;

function plotGMWMgrowthCurves(wm_cc3, gm_cc3, total_cc3, regr_estimates, significance, DTIAge, titleStringAdd)
if ~exist('titleStringAdd', 'var') || isempty(titleStringAdd)
    titleStringAdd='';
end
fitcolr='-r'; colr='--k';

%RESHAPE THE DATA FOR PLOTTING
DTIAgeR=reshape(DTIAge, [4 size(DTIAge, 2)/4]);
wm_cc3R=reshape(wm_cc3, [4 numel(wm_cc3)/4  ]); %this makes year x subject
gm_cc3R=reshape(gm_cc3, [4 numel(gm_cc3)/4  ]); %this makes year x subject
total_cc3R=reshape(total_cc3, [4 numel(total_cc3)/4  ]); %this makes year x subject

%COMPUTE DEMEANED VALUES
wm_cc3RDemeaned=wm_cc3R-ones(size(wm_cc3R(:, 1)))*mean(wm_cc3R)+ones(size(wm_cc3R))*mean(wm_cc3R(:));
gm_cc3RDemeaned=gm_cc3R-ones(size(gm_cc3R(:, 1)))*mean(gm_cc3R)+ones(size(gm_cc3R))*mean(gm_cc3R(:));
total_cc3RDemeaned=total_cc3R-ones(size(total_cc3R(:, 1)))*mean(total_cc3R)+ones(size(total_cc3R))*mean(total_cc3R(:));

figure; 
%Not mean-centered
subplot(2, 3, 1); 
plot(DTIAgeR, wm_cc3R); 
title(['Brain white matter volume ' titleStringAdd]);
ylabel('Volume, cc');
xlabel('Age');

subplot(2, 3, 2); 
plot(DTIAgeR, gm_cc3R); 
title(['Brain gray matter volume ' titleStringAdd]);
ylabel('Volume, cc');
xlabel('Age');

subplot(2, 3, 3); 
plot(DTIAgeR, total_cc3R); 
title(['Total brain volume ' titleStringAdd]);
ylabel('Volume, cc');
xlabel('Age');

%mean-centered
subplot(2, 3, 4); 
plot(DTIAgeR, wm_cc3RDemeaned, colr); 
title(['Brain white matter volume ' titleStringAdd]);
ylabel('Mean-centered volume, cc');
xlabel('Age'); hold on; 
%Plot regression estimates
plot([7 15], regr_estimates(1, 1)+regr_estimates(1, 2)*[7 14], fitcolr, 'LineWidth',2);
slope_coef=num2str(regr_estimates(1, 2) , '%2.1f\n');
text(16, regr_estimates(1, 1)+regr_estimates(1, 2)*14, [slope_coef significance{1} ' cc/year']); 
v=axis;
axis([5 18 v(3) v(4)]);

subplot(2, 3, 5); 
plot(DTIAgeR, gm_cc3RDemeaned, colr); 
title(['Brain gray matter volume ' titleStringAdd ]);
ylabel('Mean-centered volume, cc');
xlabel('Age'); hold on;
%Plot regression estimates
plot([7 15], regr_estimates(2, 1)+regr_estimates(2, 2)*[7 14], fitcolr, 'LineWidth',2);
slope_coef=num2str(regr_estimates(2, 2) , '%2.1f\n');
text(16, regr_estimates(2, 1)+regr_estimates(2, 2)*14, [slope_coef significance{2} ' cc/year']); 
v=axis;
axis([5 18 v(3) v(4)]);

subplot(2, 3, 6); 
plot(DTIAgeR, total_cc3RDemeaned, colr); 
title(['Total brain volume ' titleStringAdd]);
ylabel('Mean-centered volume, cc');
xlabel('Age'); hold on;
%Plot regression estimates
plot([7 15], regr_estimates(3, 1)+regr_estimates(3, 2)*[7 14], fitcolr, 'LineWidth',2);
slope_coef=num2str(regr_estimates(3, 2) , '%2.1f\n');
text(16, regr_estimates(3, 1)+regr_estimates(3, 2)*14, [slope_coef significance{3} ' cc/year']); 
v=axis;
axis([5 18 v(3) v(4)]);

function DTIAge=getDTIAge(subjectCodes,  behaveDataFile)
[behaveData, colNames, subCodeList, subYearList] = dtiGetBehavioralData(subjectCodes, behaveDataFile);

%Start forming a file with one row per scan, columns: 
%ID dtiYear Age 
DTIAge=[];
for subjID=1:size(subjectCodes, 2)
   DTIAge(subjID)=behaveData(subjID, find(~cellfun(@isempty, regexp(colNames, ['DTI Age.' num2str(subYearList(subjID))]))));
end
%Pull out gender
gender=[];
for subjID=1:size(subjectCodes, 2)
   gender(subjID)=behaveData(subjID, find(~cellfun(@isempty, regexp(colNames, 'Sex'))));
end
