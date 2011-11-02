%ER 11/25/2009: This script is out of date and not flexible. Relies on
%precomputed fits. Corresponds to data reported at HBM 2009. 
%Use  function dti_Longitude_DisplayGrowthCurves.m instead.

%Input: summary structure: MxN struct array with fields 'subject' (filename for FG whose properties summarised) and 'sfg' which is
%1xX struct array with fields:
%    name
%    numberOfFibers
%    fiberLength
%    FA
%    MD
%    axialADC
%    radialADC
%    linearity
%    planarity
%    fiberGroupVolume

%Here MxN would be most typically M=number of brains scanned, N=1 (but
%could be more --, if you performed some repeated analyses on the same brain)
%X-1 would be the number of distinct fiber groups in a brain. The first sfg
%is usually a sum of all the other (2:end) sfgs in the summary array.

%Assumes that these data are longitudinal. Provided subjectInitials (array
%of strings) is matched agaist subject names in summary.subject,
%and the year will be extracted. Data points from the same subject (across
%years) will be connected with lines. Demographics from this subject will
%be pulled out from location on biac.linearfits_file='Age_fixed_RandomHLM_parameterestimates_SLF.csv';
DisplayGrandMean=false;
DisplayFgSpecificMean=false;
PlotMissingData=true;
PlotHLMfitLines=false; %true;
fiberDiameter=.2;

behaveDataFile = '/biac3/wandell4/data/reading_longitude/read_behav_measures_longitude.csv';
%behaveDataFile = 'C:\PROJECTS\longitudinal_reading\data\read_behav_measures_longitude.csv';

%cd C:/PROJECTS/longitudinal_reading/data/
outDir = '/biac3/wandell4/users/elenary/longitudinal/bobs_figures';
if(~exist('outDir','dir')), mkdir(outDir); end
datDir = '/biac3/wandell4/users/elenary/longitudinal/data';
%load(fullfile(datDir,'summaryFiberPropertiesMori_DN.mat'));
load(fullfile(datDir,'summaryFiberPropertiesMoriGroups_DN.mat'));
linearfits_file=fullfile(datDir,'MoriGroups_DN(bluematter)/Age_fixed_RandomHLM_parameterestimates20_InterceptAgeMori_DN.csv');

if ~exist('ParameterOfInterest', 'var')|| isempty(ParameterOfInterest)
    ParameterOfInterest='numberOfFibers';
end

if ~exist('subjectInitials', 'var')|| isempty(subjectInitials)
    subjectInitials={'ab', 'ajs', 'am', 'an', 'at', 'clr', 'crb', 'ctb', 'da', 'dh', 'dm', 'es', 'jh', 'lj', 'll', 'mb', 'md', 'mho', 'mn', 'pf', 'pt', 'rd', 'rsh', 'ss', 'vr', 'vt', 'zs'};
end

%PULL OUT REGRESSION SLOPES FOR ALL
if exist('linearfits_file', 'var') && exist(linearfits_file, 'file')
    linearfits=dlmread(linearfits_file);
    regr_estimates =reshape(linearfits(:, 1), [2 20])'; %first column intercept, second slope
    regr_signif=reshape(linearfits(:, 2), [2 20])'; %Only second column will contain meanigful values
    regr_signifmc=reshape(linearfits(:, 3), [2 20])';%Only second column will contain meanigful values

    %change units on the regression estimates: from fiber counts to crossectional area (linear transform).
    regr_estimates=regr_estimates*pi.*(fiberDiameter/2)^2;


elseif PlotHLMfitLines==1
    display('Where is fits file?')
else
    %nothin
end


%get all possible mori labels
tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
labels = readTab(fullfile(tdir,'MNI_JHU_tracts_prob.txt'),',',false);
labels = labels(1:20,2);
labels(21)={'AllMori'};

%Check whether we have a single property values, or min-average-max range.
%Use average in the latter case.  first element in the summary is "all
%fibers", not "first fiber group".
if size(summary(1).sfg(1).(ParameterOfInterest), 2)==3
    valInd=2;
elseif  size(summary(1).sfg(1).(ParameterOfInterest), 2)==1
    valInd=1;
else fprintf('Error'); return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. Pull out parameter of interest (saved in fiberMetrics)
filenames=strvcat(summary(:).subject);
filenames=cellstr(filenames);
subjectCodes=[];
datarow=0;

for subjectID=1:numel(subjectInitials)

    matchTemp= regexpi(filenames, [ '/' char(subjectInitials(subjectID)) '0']);
    for subj_year=find(~cellfun(@isempty, matchTemp))'

        datarow=datarow+1;
        subjectCodes=[subjectCodes  cellstr(summary(subj_year).subject(50:50+size(char(subjectInitials(subjectID)), 2)+5))];
        summary(subj_year).sfg(1).name='AllMori';

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


%%%%%%%%%%%%%%%%%%%%%
%2. Pull out demographics: Age, Gender
%PULL OUT AGE and gender of scan
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

save([ParameterOfInterest '_MoriGroups_DN'], 'fiberMetrics', 'DTIAge', 'gender');

%3. Reshape the data so that they are organized year x subject x fg
%Go over fibergroups
fiberMetricsR=reshape(fiberMetrics, [4 size(fiberMetrics, 1)/4  size(fiberMetrics, 2)]); %this makes year x subject x fg
DTIAgeR=reshape(DTIAge, [4 size(DTIAge, 2)/4]);

%Compute crossectional area instead
fiberMetricsR=fiberMetricsR.*pi.*(fiberDiameter/2)^2;

figure;  %Plot as a function of age
for fg=1:(numel(summary(subj_year).sfg)-1)
    subplot(4, 5, fg);
    plot(DTIAgeR, fiberMetricsR(:, :, fg));
    k = findstr('(temporal part)', char(labels(fg)));
    if isempty(k)
        title(labels(fg), 'BackgroundColor',[1 1 1]);
    else
        titlelabel=char(labels(fg));
        title({titlelabel(1:(k-1));titlelabel(k:end)}, 'BackgroundColor',[1 1 1]);
    end
    ylabel([ParameterOfInterest]);  xlabel('Age');

end


% fg=21; %all
% figure; plot(DTIAgeR, fiberMetricsR(:, :, fg));
% title(labels(fg), 'BackgroundColor',[1 1 1]);
% 

%%%%%%%%%%%%
%Demean by grand mean regardless of fibergroup (if still interested in
%laterality).

figure('Name', [ParameterOfInterest '(age)']);   %Plot as a function of age; LR in one fig
for fg=1:20
    subplot(3  , 4, round(fg/2));
    %    subplot(4, 5, fg);

    if round(fg/2)==8 %Move slf(pf) forward
        subplot(3  , 4, 9);
    end
    if round(fg/2)==9 %Move uncinate back
        subplot(3  , 4, 8);
    end

    xlabel('Age'); ylabel('Cross-section area, mm^2');

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
    fprintf(1, char(summary(2).sfg(fg).name));

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

subplot(3, 4, 9); title({'Superior longitudinal fasciculus'; '(frontoparietal part)'});
subplot(3, 4, 10); title({'Superior longitudinal fasciculus'; '(temporal part)'});

modifiers={' R', ' L', ' minor', 'major'};
for fg=1:2:20
    
    %Extract structure name without L/R minor/major modifier
    tmp = strrep(labels{fg},modifiers,'');
    % The shortest one is the one with the modifier removed
    tmpLen = cellfun('length',tmp);
    fgName = tmp{min(tmpLen)==tmpLen};
    fgName = strrep(fgName,' ','_');
    fgName = strrep(fgName,'(','');
    fgName = strrep(fgName,')','');

    figure('Name', fgName);

    if fg==9
        % forceps major/minor
        colOdd = {'g','-vk'};
        colEvn = {'m','-^k'};
    else
        colOdd = {'b','-<k'};
        colEvn = {'r','->k'};
    end

    %Individual intercept (mean across time points, subject-specific,
    %fg-specific) removed; Centered around FG-specific mean
    fmMeanOdd = mean(fiberMetricsR(:,:,fg)); 
    fmMeanEvn = mean(fiberMetricsR(:,:,fg+1));
    fiberMetricsDemeanedOdd = fiberMetricsR(:,:,fg)   - repmat(fmMeanOdd,4,1) + mean(fmMeanOdd);
    fiberMetricsDemeanedEvn = fiberMetricsR(:,:,fg+1) - repmat(fmMeanEvn,4,1) + mean(fmMeanEvn);
    
    plot(DTIAgeR, fiberMetricsDemeanedOdd, ['-' colOdd{1}], DTIAgeR, fiberMetricsDemeanedEvn, ['-' colEvn{1}]);
    xlabel('Age'); ylabel('Cross-section area (mm^2)');

    %Also show grand mean, and FG-specific mean here.
    hold on;

    if PlotHLMfitLines
        plot([7 15], regr_estimates(fg  , 1)+regr_estimates(fg  , 2)*[7 14], colOdd{2}, 'LineWidth',2);
        plot([7 15], regr_estimates(fg+1, 1)+regr_estimates(fg+1, 2)*[7 14], colEvn{2}, 'LineWidth',2);
        
        for(k=0:1)
            %report slopes -- unfortunately requires manual editing of the final figure
            %if the labels are too close
            slope_coef = num2str(regr_estimates(fg+k, 2) , '%2.1f\n');
            if regr_signif(fg+k, 2)
                slope_coef=[slope_coef '*'];
            end
            if regr_signifmc(fg+k, 2)
                slope_coef=[slope_coef '*'];
            end

            text(15.5, regr_estimates(fg+k, 1)+regr_estimates(fg+k, 2)*14,slope_coef);
        end
        v=axis;
        axis([6 17 v(3) v(4)]);
    end
%    mrUtilResizeFigure(gcf,300,200);
%    fname = fullfile(outDir,fgName);
%    mrUtilPrintFigure([fname '.eps']);
%    unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fname '.png ' fname '.eps']);
    
end

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Display reliability data
% We performed density normalization 10 tines for each time point (ages are 11:14) of 'at'
% subject
cd /biac3/wandell4/users/elenary/longitudinal/
load reliabilityFiberPropertiesMori_DN
%ParameterOfInterest='numberOfFibers'; %
ParameterOfInterest='fiberLength';
%ParameterOfInterest='fiberGroupVolume';

if size(relsummary(1).sfg(1).(ParameterOfInterest), 2)==3
    valInd=2;
elseif  size(relsummary(1).sfg(1).(ParameterOfInterest), 2)==1
    valInd=1;
else fprintf('Error'); return;
end


datarow=0;
for year=1:4


    for trial=1:size(relsummary, 2)
        relsummary(year, trial).sfg(1).name='AllMori';

        datarow=datarow+1;
        subjectlabels=strvcat(relsummary(year).sfg(1:end).name);

        for label_fgID=1:numel(labels)
            found=0;
            for subj_fgID=1:numel(relsummary(year, trial).sfg)  %Find in this participant where a canonical FG is
                fg_has_data=findstr(char(labels(label_fgID)), subjectlabels(subj_fgID, :));
                if fg_has_data
                    found=1;
                    fiberMetrics(datarow, label_fgID)=relsummary(year, trial).sfg(subj_fgID).(ParameterOfInterest)(valInd);
                end
            end %end fiber groups that had at least one fiber in this participant
            if found==0
                fiberMetrics(datarow, label_fgID)=0;
            end
        end

    end
end


fiberMetricsReshaped=reshape(fiberMetrics, [10 4 21]);

fiberMetricsReshapedMean=mean(fiberMetricsReshaped, 1); fiberMetricsReshapedMean=permute(fiberMetricsReshapedMean, [2 3 1]);
fiberMetricsReshapedStd=std(fiberMetricsReshaped, 1); fiberMetricsReshapedStd=permute(fiberMetricsReshapedStd, [2 3 1]);

%Plot
h=figure;
for fg=1:2:19

    subplot(3, 4, round(fg/2));
    errorbar(11:14, fiberMetricsReshapedMean(:, fg),fiberMetricsReshapedStd(:, fg));  hold on;
    errorbar(11:14, fiberMetricsReshapedMean(:, fg+1),fiberMetricsReshapedStd(:, fg+1), 'r');
    titlelabel=char(labels(fg));
    title(titlelabel(1:end-2), 'BackgroundColor',[1 1 1]);

end
%summary
subplot(3, 4, 12);
errorbar(11:14, fiberMetricsReshapedMean(:, 21),fiberMetricsReshapedStd(:, 21));  title(labels(21));

%Fix up titles for SLF
subplot(3, 4, 5); title({'Forceps major (blue)'; 'Forceps minor (red)'});
subplot(3, 4, 8); title({'Superior longitudinal fasciculus'; '(frontoparietal part)'});
subplot(3, 4, 10); title({'Superior longitudinal fasciculus'; '(temporal part)'});
saveas(h,['atGrowth_BMreliabilityTest' ParameterOfInterest '.jpg']);



%%%Report average cross-sections of the fiber groups.
%fiberDiameter=.2;

%NumFibers is pretty robust. Are these solutions "unique"?
for s=1:4
    DN_ind_s=[];
    for trial=1:10
        fgname=fullfile(project_folder, subjectID{s}, 'dti06trilinrt', 'fibers', ['MoriGroupsConnectingGM_DN' num2str(trial) '.mat']);

        fid=fopen(fullfile(project_folder, subjectID{s}, 'dti06trilinrt', 'fibers', ['MoriGroupsConnectingGM_DN' num2str(trial) '.ind']));
        %TrueSA solution are indices of fibers to keep--in the space of MoriGroupsConnectingGM. PLUS1!!! (those indices count from 0)
        DN_ind{trial}=textscan(fid, '%d');DN_ind_s=[DN_ind_s DN_ind{trial}{1}']; fclose(fid);

    end
    c{s} = intersect(DN_ind{1}{1},intersect(DN_ind{2}{1},intersect(DN_ind{3}{1},intersect(DN_ind{5}{1},intersect(DN_ind{4}{1},intersect(DN_ind{3}{1}, intersect(DN_ind{2}{1}, DN_ind{1}{1})))))));
end

%Unique 18017 from 160395 total across 10 trials.
%Present in all 10 solutions:
%y1    14684
%y2    17743
%y3    17415
%y4    18812
fiberMetricsReshapedMean(:, 21)
16039
19517
19414
20591
%So about 90% overlap (and the rest of the 10% is probably not too far from.)