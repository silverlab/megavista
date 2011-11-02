%ER 11/25/2009: This script is out of date and not flexible. Relies on
%precomputed fits. 
%Use  function dti_Longitude_DisplayGrowthCurves.m instead.

%Make growth curve plots for each fiber group of interest, each measure of
%interest. 
%Input: summaryFiberProperties.mat produced by script
%dti_Longitude_MoriFiberProperties
%If want regression fits, separate analyses should be conducted (I used
%SPSS) & regression coefficients saved in a separate file. 

%ER 12/16/2008
%Contains a special case- hack to display only SLF parts

%For now dismissing participants with zero fibers in specific FGs
%altogether (all 4 measures) -- for that given FG

%cd('/biac3/wandell4/data/reading_longitude/moriGroupAnalysis'); 
%cd('S:\data\reading_longitude\moriGroupAnalysis'); 
cd('C:\PROJECTS\longitudinal_reading\data'); 

clear;
if 1     %special SLF case

load('summaryFiberProperties_SLF.mat'); 
labels={'Anterior thalamic radiation L', 'Anterior thalamic radiation R',     'Corticospinal tract L',     'Corticospinal tract R',...
    'Cingulum (cingulate gyrus) L',     'Cingulum (cingulate gyrus) R',     'Cingulum (hippocampus) L',     'Cingulum (hippocampus) R',...
    'Forceps major',     'Forceps minor',     'Inferior fronto-occipital fasciculus L',     'Inferior fronto-occipital fasciculus R',...
    'Inferior longitudinal fasciculus L',     'Inferior longitudinal fasciculus R',     'Superior longitudinal fasciculus L', ...
    'Superior longitudinal fasciculus R',     'Uncinate fasciculus L',     'Uncinate fasciculus R',    'Superior longitudinal fasciculus (temporal part) L',    'Superior longitudinal fasciculus (temporal part) R'}';
%PULL OUT REGRESSION SLOPES FOR ALL
linearfits_file='Age_fixed_RandomHLM_parameterestimates_SLF.csv';
linearfits=dlmread(linearfits_file);
regr_estimates=zeros(20, 2);
regr_signif=zeros(20, 2);
regr_signifmc=zeros(20, 2);

regr_estimates(15:16, :) =reshape(linearfits(1:4, 1), [2 2])'; %first column intercept, second slope
regr_signif(15:16, :)=reshape(linearfits(1:4, 2), [2 2])'; %Only second column will contain meanigful values
regr_signifmc(15:16, :)=reshape(linearfits(1:4, 3), [2 2])';%Only second column will contain meanigful values

regr_estimates(19:20, :) =reshape(linearfits(5:8, 1), [2 2])'; %first column intercept, second slope
regr_signif(19:20, :)=reshape(linearfits(5:8, 2), [2 2])'; %Only second column will contain meanigful values
regr_signifmc(19:20, :)=reshape(linearfits(5:8, 3), [2 2])';%Only second column will contain meanigful values

else %usuall all 20 FG case
    %load('summaryFiberProperties.mat');
    load('summaryFiberPropertiesMoriSymm.mat');
    labels=vertcat(summary(1).sfg.name);
%PULL OUT REGRESSION SLOPES FOR ALL -- ER: edit!
%linearfits_file='Age_fixed_RandomHLM_parameterestimates18_InterceptAge.csv';
%linearfits=dlmread(linearfits_file);
%regr_estimates =reshape(linearfits(:, 1), [2 18])'; %first column intercept, second slope
%regr_signif=reshape(linearfits(:, 2), [2 18])'; %Only second column will contain meanigful values
%regr_signifmc=reshape(linearfits(:, 3), [2 18])';%Only second column will contain meanigful values

end

DisplayGrandMean=false;
DisplayFgSpecificMean=false;
PlotMissingData=true;
PlotHLMfitLines=false;
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
%Use average in the latter case. 
if size(summary(15).sfg(15).(ParameterOfInterest), 2)==3
valInd=2;
elseif  size(summary(15).sfg(15).(ParameterOfInterest), 2)==1
valInd=1;        
else fprintf('Hello'); return;
end

subjectCodes={}; 

filenames=strvcat(summary(:).subject);
filenames=cellstr(filenames);
subjectCodes=[];
datarow=0;
for subjectID=1:size(all4measuresSubjects, 2)

    matchTemp= regexpi(filenames, [ '/' char(all4measuresSubjects(subjectID)) '0']);
        for subj_year=find(~cellfun(@isempty, matchTemp))'

            datarow=datarow+1; 
            subjectCodes=[subjectCodes  cellstr(summary(subj_year).subject(50:50+size(char(all4measuresSubjects(subjectID)), 2)+5))];

            for fgID=1:size(summary(subj_year).sfg, 2) 
                %Are there 18 only? i found in mori culled some
                %size(summary(subj_year).sfg, 2) =20!!!
                %On the other hand some are 17....

                if(isempty(summary(subj_year).sfg(fgID).(ParameterOfInterest)))
                          summary(subj_year).sfg(fgID).(ParameterOfInterest)= repmat(0 , [1 2*valInd-1]); %In case valInd=2, fake the average to be zero
                end                      
            fiberMetrics(datarow, fgID)=summary(subj_year).sfg(fgID).(ParameterOfInterest)(valInd);
            
            end
        end
end

%PULL OUT AGE and year of scan
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
   gender(subjID)=behaveData(subjID, find(~cellfun(@isempty, regexp(colNames, 'Sex (1=male)'))));
end


%Go over fibergroups
fiberMetricsR=reshape(fiberMetrics, [4 size(fiberMetrics, 1)/4  size(fiberMetrics, 2)]); %this makes year x subject x fg
DTIAgeR=reshape(DTIAge, [4 size(DTIAge, 2)/4]);

%get FG labels for the first 18 groups (i this the other two were not
%computed/saved for everyone...)


if 0
figure;  %Plot as a function of age
for fg=1:size(summary(subj_year).sfg, 2) 
    subplot(4, 5, fg);
    plot(DTIAgeR, fiberMetricsR(:, :, fg)); 
    title(labels(fg), 'BackgroundColor',[1 1 1]); 
end
subplot(4, 5, 19); text(.5, .5, [ParameterOfInterest '(age)']); 
axis off; 
end

%figure;  %Plot as a function of study year
%for fg=1:18
%    subplot(4, 5, fg);
%    plot(fiberMetricsR(:, :, fg)); 
%    title(labels(fg), 'BackgroundColor',[1 1 1]); 
%end
%subplot(4, 5, 19); text(.5, .5, [ParameterOfInterest '(study year)']); 
%axis off; 

%Demean by grand mean regardless of fibergroup (if still interested in
%laterality).

figure('Name', [ParameterOfInterest '(age)']);   %Plot as a function of age; LR in one fig
for fg=1:size(summary(subj_year).sfg, 2) 
     subplot(3  , 4, round(fg/2));
%    subplot(4, 5, fg);

%Extract structure name without L/R minor/major modifier

modifiers={' R', ' L', ' minor', 'major'};
for k = 1:size(modifiers, 2)
    kk=strfind(labels{fg}, modifiers{k});
if ~isempty(kk)
    title(labels{fg}(:, 1:kk), 'BackgroundColor',[1 1 1]); 
    break
end
end

%MAKE ODDS (LH) green EVEN (RH) blue
if mod(fg, 2)==1
    colr='b';
    fitcolr='-<k';
else colr='r';
    fitcolr='->k';
end


if fg==9
    %forceps major
    colr='g';
    fitcolr='-vk';
elseif fg==10
    %forceps minor
    colr='m';
    fitcolr='-^k';
end

    %Individual intercept (mean across time points, subject-specific,
    %fg-specific) removed; Centered around FG-specific mean
    fiberMetricsRfg=fiberMetricsR(:, :, fg);

    %Treat zeros as missing data
    DTIAgeRfg=DTIAgeR;
    fprintf(1, char(summary(1).sfg(fg).name)); 
 
  if ~PlotMissingData
    fprintf(1, ['  subjects dismissed:' num2str(sum(any(fiberMetricsRfg==0))) '\n']); 
    DTIAgeRfg(:, any(fiberMetricsRfg==0)')=[];
    fiberMetricsRfg(:, any(fiberMetricsRfg==0)')=[];
  end
  
    fiberMetricsDemeaned=fiberMetricsRfg-ones(size(fiberMetricsRfg(:, 1)))*mean(fiberMetricsRfg)+ones(size(fiberMetricsRfg))*mean(fiberMetricsRfg(:));
  %  plot(DTIAgeRfg, fiberMetricsDemeaned, '-k');  BLACK!!!
    plot(DTIAgeRfg, fiberMetricsDemeaned, ['-' colr]);
  
    %Also show grand mean, and FG-specific mean here. 
    hold on;

    if DisplayGrandMean
         plot([7 15],  [mean(fiberMetricsR(:)) mean(fiberMetricsR(:))],  '--bs'); %Grand Mean
    end
    if DisplayFgSpecificMean
        plot([7 15],  repmat(mean(fiberMetricsRfg(:)), [1 2]),'>r'); %FG_specific mean
    end

    if PlotHLMfitLines
        plot([7 15], regr_estimates(fg, 1)+regr_estimates(fg, 2)*[7 14], fitcolr, 'LineWidth',2);
axis auto;
%report slopes -- unfortunately requires manual editing of the final figure
%if the labels are too close
        slope_coef=num2str(regr_estimates(fg, 2) , '%2.1f\n');
        if regr_signif(fg, 2)
            slope_coef=[slope_coef '*'];
        end
        if regr_signifmc(fg, 2)
            slope_coef=[slope_coef '*'];
        end
        
        text(16, regr_estimates(fg, 1)+regr_estimates(fg, 2)*14,slope_coef); 

v=axis;
axis([5 18 v(3) v(4)]);
    end
    
end

save(ParameterOfInterest, 'fiberMetrics');