%ER 11/25/2009: This script is out of date and not flexible. Relies on
%precomputed fits. 
%Use  function dti_Longitude_DisplayGrowthCurves.m instead.

%Make growth curve plots for each fiber group of interest, each measure of
%interest -- split by gender
%Input: summaryFiberPropertiesMoriSym.mat produced by script
%dti_Longitude_MoriFiberProperties
%If want regression fits, separate analyses should be conducted (I used
%SPSS -- beta coefficients are from fitting each FG, hs-specific, once, separately) & regression coefficients saved in a separate file. Run this one
%first with PlotHLMfitLines=false (will save fiberMetrics, which are then uploaded into SPSS to compute fits)
%Yes, this is a hack, not a properly done code)
%Plots grouped by Hemisphere

%ER 02/09/2009  Modified from
%dti_Longitude_MoriSymFiberPropertiesGrowthCurves.m
%For now dismissing participants with zero fibers in specific FGs
%altogether (all 4 measures) -- for any given FG

cd('C:\PROJECTS\longitudinal_reading\data\MoriAtlasSymm');
clear;
%get all possible mori labels
tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
labels = readTab(fullfile(tdir,'MNI_JHU_tracts_prob.txt'),',',false);
labels = labels(1:20,2);
load('summaryFiberPropertiesMoriSymm.mat');
%PULL OUT REGRESSION SLOPES FOR ALL -- ER: edit!
%linearfits_file='Age_fixed_RandomHLM_parameterestimates20_InterceptAgeMoriSym.csv';
%linearfits=dlmread(linearfits_file);
%regr_estimates =reshape(linearfits(:, 1), [2 20])'; %first column intercept, second slope
%regr_signif=reshape(linearfits(:, 2), [2 20])'; %Only second column will contain meanigful values
%regr_signifmc=reshape(linearfits(:, 3), [2 20])';%Only second column will contain meanigful values

%HLM fit lines were obtained from main fixed effects in a no-interaction
%model with AGE and HS.
%Y=intercept+AGE*age+HS*age
ParameterOfInterest='numberOfFibers';
%'FA';
%'fiberLength';
%'numberOfFibers';
%
%    'MD'
%    'axialADC'
%    'radialADC'
%    'linearity'
%    'planarity'
%    'fiberGroupVolume'
fprintf(ParameterOfInterest);
fprintf('\n');
%For some of these parameters, the structure summaryFiberrProperties
%contains 3 values (min, average, max) -- average will be used.
%Important: thi script will only work if each participant has all 4
%datapoints
all4measuresSubjects={'ab', 'ajs', 'am', 'an', 'at', 'clr', 'crb', 'ctb', 'da', 'dh', 'dm', 'es', 'jh', 'lj', 'll', 'mb', 'md', 'mho', 'mn', 'pf', 'pt', 'rd', 'rsh', 'tv', 'vr', 'vt', 'zs'};
%mm
%ss
%Check whether we have a single property values, or min-average-max range.
%Use average in the latter case.  first element in the summary is "all
%fibers", not "first fiber group".
if size(summary(1).sfg(1).(ParameterOfInterest), 2)==3
valInd=2;
elseif  size(summary(1).sfg(1).(ParameterOfInterest), 2)==1
valInd=1;
else fprintf('Hello'); return;
end
subjectCodes={};
filenames=strvcat(summary(:).subject);
filenames=cellstr(filenames);
subjectCodes=[];
datarow=0;
for subjectID=1:numel(all4measuresSubjects)
matchTemp= regexpi(filenames, [ '/' char(all4measuresSubjects(subjectID)) '0']);
for subj_year=find(~cellfun(@isempty, matchTemp))'
datarow=datarow+1;
subjectCodes=[subjectCodes  cellstr(summary(subj_year).subject(50:50+size(char(all4measuresSubjects(subjectID)), 2)+5))];
subjectlabels=strvcat(summary(subj_year).sfg(1:end).name);
for label_fgID=1:numel(labels)
found=0;
for subj_fgID=1:numel(summary(subj_year).sfg)  %Find in this participant where a canonical FG is
fg_has_data=findstr(char(labels(label_fgID)), subjectlabels(subj_fgID, :));
if fg_has_data
found=1;
fiberMetrics(datarow, label_fgID)=summary(subj_year).sfg(subj_fgID).(ParameterOfInterest)(valInd);
end
end %end fiber groups that had at least one fiber in this participant
if found==0
fiberMetrics(datarow, label_fgID)=0;
end
end %end 20 canonical fiber grops of interest
end %end years 1-4
end %end all subject with four measurements
%PULL OUT AGE and gender of scan
%behaveDataFile = 'S:\data\reading_longitude\read_behav_measures_longitude.csv';
behaveDataFile = 'C:\PROJECTS\longitudinal_reading\data\read_behav_measures_longitude.csv';
[behaveData, colNames, subCodeList, subYearList] = dtiGetBehavioralData(subjectCodes, behaveDataFile);
%start forming a file with one row per scan, columns:
%ID dtiYear Age
DTIAge=[];
for subjID=1:size(subjectCodes, 2)
DTIAge(subjID)=behaveData(subjID, find(~cellfun(@isempty, regexp(colNames, ['DTI Age.' num2str(subYearList(subjID))]))));
end
%Pull out gender
gender=[];
for subjID=1:size(subjectCodes, 2)
gender(subjID)=behaveData(subjID, find(~cellfun(@isempty, regexp(colNames, 'Sex')))); %sex: male=1
end
%Go over fibergroups
fiberMetricsR=reshape(fiberMetrics, [4 size(fiberMetrics, 1)/4  size(fiberMetrics, 2)]); %this makes year x subject x fg
DTIAgeR=reshape(DTIAge, [4 size(DTIAge, 2)/4]);
genderR=reshape(gender, [4 size(gender, 2)/4]);
rawFigure=figure;  %Plot as a function of age
demeanedFigure=figure;  %Plot as a function of age
for fg=1:numel(summary(subj_year).sfg)-1
figure(rawFigure);
subplot(4, 5, fg);
plot(DTIAgeR(:, genderR(1, :)==1), fiberMetricsR(:, genderR(1, :)==1, fg), 'b');
hold on; %Green girls, blue boys
plot(DTIAgeR(:, genderR(1, :)==0), fiberMetricsR(:, genderR(1, :)==0, fg), 'g');
title(labels(fg), 'BackgroundColor',[1 1 1]);
figure(demeanedFigure);
subplot(4, 5, fg);
%Also plot demeaned
%Individual intercept (mean across time points, subject-specific,
%fg-specific) removed; Centered around FG-specific mean
fiberMetricsRfgG=fiberMetricsR(:, genderR(1, :)==0, fg);
fiberMetricsDemeanedG=fiberMetricsRfgG-ones(size(fiberMetricsRfgG(:, 1)))*mean(fiberMetricsRfgG)+ones(size(fiberMetricsRfgG))*mean(fiberMetricsRfgG(:));
fiberMetricsRfgB=fiberMetricsR(:, genderR(1, :)==1, fg);
fiberMetricsDemeanedB=fiberMetricsRfgB-ones(size(fiberMetricsRfgB(:, 1)))*mean(fiberMetricsRfgB)+ones(size(fiberMetricsRfgB))*mean(fiberMetricsRfgB(:));
plot(DTIAgeR(:, genderR(1, :)==0), fiberMetricsDemeanedG, 'g'); hold on;
plot(DTIAgeR(:, genderR(1, :)==1), fiberMetricsDemeanedB, 'b');
title(labels(fg), 'BackgroundColor',[1 1 1]);
end
figure(rawFigure);
subplot(4, 5, 1); ylabel(ParameterOfInterest); xlabel('Age');
%Fix up titles for SLF
subplot(4, 5, 15); title({'Superior longitudinal fasciculus L'; '(frontoparietal part)'});
subplot(4, 5, 16); title({'Superior longitudinal fasciculus R'; '(frontoparietal part)'});
subplot(4, 5, 19); title({'Superior longitudinal fasciculus L'; '(temporal part)'});
subplot(4, 5, 20); title({'Superior longitudinal fasciculus R'; '(temporal part)'});
figure(demeanedFigure);
subplot(4, 5, 1); ylabel(ParameterOfInterest); xlabel('Age');
%Fix up titles for SLF

%%% Visualize SLF (R and L) fronto-parietal (NOT DEMEANED! TRUE DATA!)
regr_estimates=[68 3.19 -15.37; 57.26 7.9 4.7]; %Rows: SLF L/R; Columns: intercept, age, gender=0 betas.
figure;
for fg=15:16
subplot(1, 2, fg-14);
fiberMetricsRfgG=fiberMetricsR(:, genderR(1, :)==0, fg);
%fiberMetricsDemeanedG=fiberMetricsRfgG-ones(size(fiberMetricsRfgG(:, 1)))*mean(fiberMetricsRfgG)+ones(size(fiberMetricsRfgG))*mean(fiberMetricsRfgG(:));
%fiberMetricsRfgB=fiberMetricsR(:, gender(1:27)==1, fg);
%fiberMetricsDemeanedB=fiberMetricsRfgB-ones(size(fiberMetricsRfgB(:, 1)))*mean(fiberMetricsRfgB)+ones(size(fiberMetricsRfgB))*mean(fiberMetricsRfgB(:));
%plot(DTIAgeR(:, gender(1:27)==0), fiberMetricsDemeanedG, 'g'); hold on;
%plot(DTIAgeR(:, gender(1:27)==1), fiberMetricsDemeanedB, 'b');
plot(DTIAgeR(:, genderR(1, :)==1), fiberMetricsR(:, genderR(1, :)==1, fg), 'b');
hold on; %Green girls, blue boys
plot(DTIAgeR(:, genderR(1, :)==0), fiberMetricsR(:, genderR(1, :)==0, fg), 'g');
title(labels(fg), 'BackgroundColor',[1 1 1]);
plot([7 15], regr_estimates(fg-14, 1)+regr_estimates(fg-14, 2)*[7 14]+ regr_estimates(fg-14, 3), 'g', 'LineWidth',2);%girls
plot([7 15], regr_estimates(fg-14, 1)+regr_estimates(fg-14, 2)*[7 14], 'b', 'LineWidth',2);%boys
end
subplot(1, 2, 1); title({'Superior longitudinal fasciculus L'; '(frontoparietal part)'});
subplot(1, 2, 2); title({'Superior longitudinal fasciculus R'; '(frontoparietal part)'});
%Build curves for age-specific gender means
for age=7:15
boys15(age)=mean(fiberMetrics((gender==1) & (round(DTIAge)==age), 15));
girls15(age)=mean(fiberMetrics((gender==0) & (round(DTIAge)==age), 15));
boys16(age)=mean(fiberMetrics((gender==1) & (round(DTIAge)==age), 16));
girls16(age)=mean(fiberMetrics((gender==0) & (round(DTIAge)==age), 16));
end
figure; subplot(2, 2, 1); plot([7:15], boys15(7:15), 'b'); hold on; plot([7:15], girls15(7:15), 'g'); title('SLF frontoparietal L'); legend('boys','girls'); ylabel('Number of fibers'); xlabel('Age'); axis([6 16 60 220]);
subplot(2, 2, 2); plot([7:15], boys16(7:15), 'b'); hold on; plot([7:15], girls16(7:15), 'g');title('SLF frontoparietal R');legend('boys','girls');ylabel('Number of fibers'); xlabel('Age');axis([6 16 60 220]);
%quickly show a histogram of freq
subplot(2, 2, 3); hist(round(DTIAge(gender==1)), [7:15]); title('Boys');
subplot(2, 2, 4); hist(round(DTIAge(gender==0)), [7:15]); title('Girls');