function dti_Longitude_rmAnova
%rm_anova to evaluate the amount of variability 
% - due to repeated measurement in growing population
% - due to repeated measurement in adults
% - due to individual differences among subjects
% - due to fiber group
clear
cd /biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups

%% IN REPEATED ADULTS (2x4) DATASET
summaryFile='summaryFiberPropertiesMoriGroups_volumeUniqueVoxels_2adults4repeats.mat';
load(summaryFile); 
ParameterOfInterest='fiberGroupVolume'; 
labels = dtiGetMoriLabels;
subjectInitials={'er', 'rfd'};
[fiberMetrics, subjectCodes, year, group]=dtiGetFGProperties(summary, subjectInitials, ParameterOfInterest, labels, '1');
%COLLAPSE DATA FOR 9 FIBER GROUPS
collapsingVector2=[1 1 2 2 3 3 3 3 4 5 6 6 7 7 8 8 9 9 8 8]; %will collapse symmetric fiber groups into one, will combine cingulum cingulate and hc, and will combine slf_t and slf_fp. 
[fiberMetrics_collapsed, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics, labels, collapsingVector2, 'sum');
tMeasurement=[1 2 3 4 1 2 3 4]; %1:4 longitudinaly measurements
stats_adults = performAnova(fiberMetrics, tMeasurement, subjectInitials)
stats_adults_collapsed = performAnova(fiberMetrics_collapsed, tMeasurement, subjectInitials)

%% IN LONGITUDINAL DATASET
load summaryFiberPropertiesMoriGroups_volumeUniqueVoxels.mat
load('/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years'); 
subjectInitials=unique(cellfun(@(x) x(1:end-6), subjectCodes, 'UniformOutput', false));
[fiberMetrics, subjectCodes, year, group]=dtiGetFGProperties(summary, subjectInitials, ParameterOfInterest, labels, '0');
%COLLAPSE DATA FOR 9 FIBER GROUPS
collapsingVector2=[1 1 2 2 3 3 3 3 4 5 6 6 7 7 8 8 9 9 8 8]; %will collapse symmetric fiber groups into one, will combine cingulum cingulate and hc, and will combine slf_t and slf_fp. 
[fiberMetrics_collapsed, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics, labels, collapsingVector2, 'sum');
tMeasurement=year; %1:4 longitudinaly measurements
stats_long = performAnova(fiberMetrics, tMeasurement, subjectInitials)
stats_collapsed_long = performAnova(fiberMetrics_collapsed, tMeasurement, subjectInitials)

%% RESULTS: 
%                                          stats_adults | stats_long
%          subject-related variance (MS) | 1.2671e+006  | 1.4841e+006   %          comparable
%                                time    | 2.5169e+006  | 3.8156e+007   %  
%                            Fiber Group | 2.7342e+008  | 2.6497e+009   % big difference due to the fact that some subjects in longitudinal dataset did not have some fiber groups; disregard this piece of info. 
% ! Time-related diff greater in longitudinal dataset. 
% ! Time-related difference is twice than between-subject-variance.  Does
% this mean our measurements are actually very powerful? 

% I will need to perform this analysis on data collapsed to 9 fiber groups
% (symmetric joined)


function stats = performAnova(fiberMetrics, tMeasurement, subjectInitials)
fprintf(1, 'Reordering data\n'); 
fiberMetricsR(1:4, 1:length(subjectInitials), 1:size(fiberMetrics, 2))=NaN; 


for t=1:4
    try
        fiberMetricsR(t, :, :)=fiberMetrics(t==tMeasurement, :, :) ;
    catch
    end
end

fiberMetricsR(isnan(fiberMetricsR))=0;  %is this appropriate even?
[I1,I2,I3] = ind2sub(size(fiberMetricsR), 1:length(fiberMetricsR(:)));

fprintf(1, 'Performing ANOVA \n'); 
%    Y          dependent variable (numeric) in a column vector
%    S          grouping variable for SUBJECT
%    F1         grouping variable for factor #1
%    F2         grouping variable for factor #2
%    F1name     name (character array) of factor #1
%    F2name     name (character array) of factor #2
FACTNAMES={'Time', 'FiberGroup'}; 
Y=fiberMetricsR(:); S = I2;  F1=I1; %F1: time
F2=I3; %F2: fiber group;
stats = rm_anova2(Y,S',F1',F2',FACTNAMES);
