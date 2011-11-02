%ER 11/25/2009: This script is out of date and not flexible. Relies on
%precomputed fits. 
%Use  function dti_Longitude_DisplayGrowthCurves.m instead.


%Make growth curve plots for each fiber group of interest, each measure of
%interest. 
%Input: summaryFiberPropertiesMoriSym.mat produced by script
%dti_Longitude_MoriFiberProperties
%If want regression fits, separate analyses should be conducted (I used
%SPSS -- beta coefficients are from fitting each FG, hs-specific, once, separately) & regression coefficients saved in a separate file. Run this one
%first with PlotHLMfitLines=false (will save fiberMetrics, which are then uploaded into SPSS to compute fits) 
%Yes, this is a hack, not a properly done code)
%Plots grouped by Hemisphere

%ER 12/16/2008 wrote to handle data produced by original MoriAtlas
%ER 02/02/2009  Modified to use fiber labeling from custom symmetrified
%Mori Atlas (the latest analyses used a modified dtiFiberProperties, hence the code needed to be update to handle new dtiFiberProperties output format). 

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
linearfits_file='Age_fixed_RandomHLM_parameterestimates20_InterceptAgeMoriSym.csv';
linearfits=dlmread(linearfits_file);
regr_estimates =reshape(linearfits(:, 1), [2 20])'; %first column intercept, second slope
regr_signif=reshape(linearfits(:, 2), [2 20])'; %Only second column will contain meanigful values
regr_signifmc=reshape(linearfits(:, 3), [2 20])';%Only second column will contain meanigful values


DisplayGrandMean=false;
DisplayFgSpecificMean=false;
PlotMissingData=true;
PlotHLMfitLines=true;
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
   gender(subjID)=behaveData(subjID, find(~cellfun(@isempty, regexp(colNames, 'Sex'))));
end

%Go over fibergroups
fiberMetricsR=reshape(fiberMetrics, [4 size(fiberMetrics, 1)/4  size(fiberMetrics, 2)]); %this makes year x subject x fg
DTIAgeR=reshape(DTIAge, [4 size(DTIAge, 2)/4]);

%get FG labels for the first 18 groups (i this the other two were not
%computed/saved for everyone...)

if 0
figure;  %Plot as a function of age
for fg=1:numel(summary(subj_year).sfg) 
    subplot(4, 5, fg);
    plot(DTIAgeR, fiberMetricsR(:, :, fg)); 
    title(labels(fg), 'BackgroundColor',[1 1 1]); 
end
subplot(4, 5, 19); text(.5, .5, [ParameterOfInterest '(age)']); 
axis off; 
end

%figure;  %Plot as a function of study year
%for fg=1:20
%    subplot(4, 5, fg);
%    plot(fiberMetricsR(:, :, fg)); 
%    title(labels(fg), 'BackgroundColor',[1 1 1]); 
%end
%subplot(4, 5, 19); text(.5, .5, [ParameterOfInterest '(study year)']); 
%axis off; 

%Demean by grand mean regardless of fibergroup (if still interested in
%laterality).

figure('Name', [ParameterOfInterest '(age)']);   %Plot as a function of age; LR in one fig
for fg=1:20 
     subplot(3  , 4, round(fg/2));
%    subplot(4, 5, fg);

if round(fg/2)==8
       subplot(3  , 4, 9);
end
if round(fg/2)==9
       subplot(3  , 4, 8);
end


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

%Fix up titles for SLF
subplot(3, 4, 9); title({'Superior longitudinal fasciculus'; '(frontoparietal part)'});
    subplot(3, 4, 10); title({'Superior longitudinal fasciculus'; '(temporal part)'});
    subplot(3, 4, 3); title({'Cingulum(cingulate gyrus)'});
subplot(3, 4, 4); title({'Cingulum(hippocampus)'});
%save([ParameterOfInterest '_MoriSymm'], 'fiberMetrics');