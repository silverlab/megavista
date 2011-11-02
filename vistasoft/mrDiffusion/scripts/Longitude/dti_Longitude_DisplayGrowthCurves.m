function RMS= dti_Longitude_DisplayGrowthCurves(fiberPropertiesFile, ParameterOfInterest, outDir, outName, subjectInitials, behaveDataFile, DisplayGrandMean, DisplayFgSpecificMean, PlotMissingData, PlotHLMfitLines, Demean, x)
%Master Script for Building Growth Charts for properties of fiber groups. 
%
% dti_Longitude_DisplayGrowthCurves(fiberPropertiesFile, ParameterOfInterest, outDir, [subjectInitials=<28 all4years subjects>], ...
%                                   [behaveDataFile=<longitudinal data loc>], [DisplayGrandMean=false], ...
%                                    [DisplayFgSpecificMean=false], [PlotMissingData=true], [PlotHLMfitLines=true], [Demean=false], [x='DTI Age']);
%
% Input: summary structure: MxN struct array with fields 'subject'
% (filename for FG whose properties summarised) and 'sfg' which is 1xX
% struct array with fields:
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
%
% Here MxN would be most typically M=number of brains scanned, N=1 (but
% could be more --, if you performed some repeated analyses on the same
% brain) X-1 would be the number of distinct fiber groups in a brain. The
% first sfg is usually a sum of all the other (2:end) sfgs in the summary
% array.
%
% Assumes that these data are longitudinal. Provided subjectInitials (array
% of strings) is matched agaist subject names in summary.subject, and the
% year will be extracted. Data points from the same subject (across years)
% will be connected with lines. Demographics from this subject will be
% pulled out from location on
% biac.linearfits_file='Age_fixed_RandomHLM_parameterestimates_SLF.csv';
%
% Example:
%
% behavedatafile=...
% dti_Longitude_DisplayGrowthCurves('summaryFiberProperties_DN_MoriGroups.mat','FA', 'figures', 'DN_MoriGroups', [], behaveDataFile);

% HISTORY:
% ER rewritten it 01/2010 based on code snipets used for analysis of
% longitudinal data 2007-

if ~exist('x', 'var') || isempty(x)
x='age';
else
end


load(fiberPropertiesFile);
if ~exist('Demean', 'var') || isempty(Demean)
Demean=false; 
   % fprintf('Displayed curves are demeaned \n'); 
end
if ~exist('DisplayGrandMean', 'var') || isempty(DisplayGrandMean)
DisplayGrandMean=false;
end
if ~exist('DisplayFgSpecificMean', 'var') || isempty(DisplayFgSpecificMean)
DisplayFgSpecificMean=false;
end
if ~exist('PlotMissingData', 'var') || isempty(PlotMissingData)
PlotMissingData=true;
end
if ~exist('PlotHLMfitLines', 'var') || isempty(PlotHLMfitLines)
PlotHLMfitLines=true;
end

if ~exist('subjectInitials', 'var') || isempty(subjectInitials)
subjectInitials={'ab', 'ajs', 'am', 'an', 'at', 'clr', 'crb', 'ctb', 'da', 'dh', 'dm', 'es', 'jh', 'lj', 'll', 'mb', 'md', 'mho', 'mn', 'pf', 'pt', 'rd', 'rsh', 'ss', 'tm', 'vr', 'vt', 'zs'};
end
if ~exist('behaveDataFile', 'var') || isempty(behaveDataFile)
behaveDataFile = '/biac3/wandell4/data/reading_longitude/read_behav_measures_longitude.csv';
end

if ~exist('ParameterOfInterest', 'var')|| isempty(ParameterOfInterest)
   ParameterOfInterest='numberOfFibers';
   %Note: %To compute crossectional area use number of Fibers and
   %fiberDiameter: e.g., fiberDiameter=.2; fiberMetricsR=fiberMetricsR.*pi.*(fiberDiameter/2)^2;
end

%get all possible mori labels
labels=dtiGetMoriLabels; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. Pull out parameter of interest (saved in fiberMetrics == subjectYear in the rows, columns are fiber groups from labels)
[fiberMetrics, subjectCodes, year, group]=dtiGetFGProperties(summary, subjectInitials, ParameterOfInterest, labels); %Note that this function will generate subjectCodes! And they will be ordered alphabetically!
%this makes year x subject x fg
fiberMetricsR(1:4, 1:length(subjectInitials), 1:size(fiberMetrics, 2))=NaN; 
%Reshape for plotting
for yearI=1:4
    try
    fiberMetricsR(yearI, :, :)=fiberMetrics(year==yearI, :, :) ;
    catch
    end
end

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


%3. Reshape the data so that they are organized year x subject x fg (for plotting) 
%Go over fibergroups
DTIAgeR=reshape(DTIAge, [4 size(DTIAge, 2)/4]);

%5. get fits####################
switch x
    case 'age'
         %nother
    case 'age group'
        DTIAge = round(DTIAge./2-(floor(min(DTIAge(:))) -1)/2);
        DTIAge(DTIAge==0)=4;
        DTIAgeR = reshape(DTIAge, [4 size(DTIAge, 2)/4]);
        
    case 'year'
        DTIAge=subYearList;
        DTIAgeR=repmat((1:4)', [1 size(DTIAge, 2)/4]); %Instead of age, use measurement occasion
      
    otherwise
       error('X should be "age", "age group" or "year" only'); 
end

[beta, PSI, stats, b, FixedEffectPValues, numObsPerGroup, RMS] =fitGrowthCurves(DTIAge', x, fiberMetrics, ParameterOfInterest, [], group,  [], [], cell(labels), 'per subject'); %I think per subject version does not WORK for "year" whereas it works for "age" -- does is fitGrowthCurves have some incoded stuff to be fixed?
regr_estimates=beta'; %[20 2]
regr_signif=(FixedEffectPValues<.05)'; %[20 2]
regr_signifmc=(FixedEffectPValues<(.05/size(fiberMetricsR, 3)))'; %[20 2]
 

%#############################################################
%6. DISPLAY###                                                
%#############################################################
%numFg= max(arrayfun(@(x) numel(x.sfg), summary));

figure;  %Plot as a function of x (age, or time, depending on x-case)
for fg=1:length(labels)
    subplot(round(sqrt(length(labels))), ceil(sqrt(length(labels))), fg);
    plot(DTIAgeR, fiberMetricsR(:, :, fg));
    %plot(fiberMetricsR(:, :, fg));
    
    k = findstr('(temporal part)', char(labels(fg)));
    if isempty(k)
        title(labels(fg), 'BackgroundColor',[1 1 1]);
    else
        titlelabel=char(labels(fg));
        title({titlelabel(1:(k-1));titlelabel(k:end)}, 'BackgroundColor',[1 1 1]);
    end
    ylabel([ParameterOfInterest]);  
    xlabel(x);
    %xlabel('Measurement (t)'); 
end


%%%%%%%%%%%%

figure('Name', [ParameterOfInterest '(' x ')']);   %Plot as a function of age; LR in one fig
for fg=1:20
    subplot(3  , 4, round(fg/2));
    %    subplot(4, 5, fg);

    if round(fg/2)==8 %Move slf(pf) forward
        subplot(3  , 4, 9);
    end
    if round(fg/2)==9 %Move uncinate back
        subplot(3  , 4, 8);
    end

    xlabel([x]); % ',                  RMS=' num2str(RMS(fg), '%10.5e\n')]);   ylabel([ParameterOfInterest]);  

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
    fprintf(1, '%s \n', labels{fg});

    if ~PlotMissingData
        fprintf(1, ['  subjects dismissed:' num2str(sum(any(fiberMetricsRfg==0))) '\n']);
        DTIAgeRfg(:, any(fiberMetricsRfg==0)')=[];
        fiberMetricsRfg(:, any(fiberMetricsRfg==0)')=[];
    end
    
if Demean

    fiberMetricsDemeaned=fiberMetricsRfg-ones(size(fiberMetricsRfg(:, 1)))*mean(fiberMetricsRfg)+ones(size(fiberMetricsRfg))*mean(fiberMetricsRfg(:));
else
    fiberMetricsDemeaned=fiberMetricsRfg;
end

    %  plot(DTIAgeRfg, fiberMetricsDemeaned, '-k');  BLACK!!!
    plot(DTIAgeRfg, fiberMetricsDemeaned, ['o' colr]);

    %Also show grand mean, and FG-specific mean here.
    hold on;

    if DisplayGrandMean
        plot([round(min(DTIAgeR(:))) round(max(DTIAgeR(:)))],  [mean(fiberMetricsR(:)) mean(fiberMetricsR(:))],  '--bs'); %Grand Mean
    end
    if DisplayFgSpecificMean
        plot([round(min(DTIAgeR(:))) round(max(DTIAgeR(:)))],  repmat(mean(fiberMetricsRfg(:)), [1 2]),'>r'); %FG_specific mean
    end

    if PlotHLMfitLines
        plot([round(min(DTIAgeR(:))) round(max(DTIAgeR(:)))], regr_estimates(fg, 1)+regr_estimates(fg, 2)*[ceil(min(DTIAgeR(:))) floor(max(DTIAgeR(:)))], fitcolr, 'LineWidth',2);
        axis auto;
        %report slopes -- unfortunately requires manual editing of the final figure
        %if the labels are too close
        slope_coef=num2str(regr_estimates(fg, 2) , '%2.3f\n');
        if regr_signif(fg, 2)
            slope_coef=[slope_coef '*'];
        end
        if regr_signifmc(fg, 2)
            slope_coef=[slope_coef '*'];
        end

      %  text(mod(fg, 2)*10+6, regr_estimates(fg, 1)+regr_estimates(fg, 2)*(mod(fg, 2)*10+4),slope_coef);
        text(mod(fg, 2)*.5+round(max(DTIAgeR(:))), regr_estimates(fg, 1)+regr_estimates(fg, 2)*(mod(fg, 2)*10+4),slope_coef);
        v=axis;
        if strmatch(ParameterOfInterest, {'FA', 'MD'})
        v(3)=.3; v(4)=.6; 
        end
        
        axis([round(min(DTIAgeR(:))) round(max(DTIAgeR(:))) v(3) v(4)]);
    end

end

subplot(3, 4, 9); title({'Superior longitudinal fasciculus'; '(frontoparietal part)'});
subplot(3, 4, 10); title({'Superior longitudinal fasciculus'; '(temporal part)'});
 
    mrUtilPrintFigure(fullfile(outDir, [outName '.png']), [], 600);
%    unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fullfile(outDir, [outName '.png']) ' ' fullfile(outDir, [name '.eps'])]);


modifiers={' R', ' L', ' minor', 'major'};
return    

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
    xlabel(x); ylabel(ParameterOfInterest);

    %Also show grand mean, and FG-specific mean here.
    hold on;

    if PlotHLMfitLines
        plot([min(DTIAge) max(DTIAge)], regr_estimates(fg  , 1)+regr_estimates(fg  , 2)*[7 14], colOdd{2}, 'LineWidth',2);
        plot([min(DTIAge) max(DTIAge)], regr_estimates(fg+1, 1)+regr_estimates(fg+1, 2)*[7 14], colEvn{2}, 'LineWidth',2);
        
        for(k=0:1)
            %report slopes -- unfortunately requires manual editing of the final figure
            %if the labels are too close
            slope_coef = num2str(regr_estimates(fg+k, 2) , '%2.1f\n');
            if regr_signif(fg+k)
                slope_coef=[slope_coef '*'];
            end
            if regr_signifmc(fg+k)
                slope_coef=[slope_coef '*'];
            end

            text(15.5, regr_estimates(fg+k, 1)+regr_estimates(fg+k, 2)*14,slope_coef);
        end
        v=axis;
        axis([6 17 v(3) v(4)]);
    end
    mrUtilResizeFigure(gcf,300,200);
    fname = fullfile(outDir,[outName '_' fgName]);
    mrUtilPrintFigure([fname '.eps']);
    unix(['pstoimg -antialias -aaliastext -density 300 -type png -crop a -trans -out ' fname '.png ' fname '.eps']);
end    

return

%More examples
%
% dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberProperties_DN_MoriGroups.mat', 'fiberGroupVolume', '/biac3/wandell4/users/elenary/longitudinal/figures', 'DN_MoriGroups_mle');
% dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberPropertiesMoriGroups_DN.mat', 'fiberGroupVolume', '/biac3/wandell4/users/elenary/longitudinal/figures', 'MoriGroups_DN_mle');
%
% dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberProperties_DN_MoriGroups_volumeUniqueVoxels.mat', 'fiberGroupVolume', '/biac3/wandell4/users/elenary/longitudinal/figures', 'DN_MoriGroups_UniqueVoxels_mle');
% dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberPropertiesMoriGroups_DN_volumeUniqueVoxels.mat', 'fiberGroupVolume', '/biac3/wandell4/users/elenary/longitudinal/figures', 'MoriGroups_DN_UniqueVoxels_mle');
%
% dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberPropertiesAllConnectingGmMoriGroups_volumeUniqueVoxels.mat', 'fiberGroupVolume', '/biac3/wandell4/users/elenary/longitudinal/figures', 'AllConnectingGmMoriGroups_UniqueVoxels_mle');
% dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberPropertiesMoriGroups_volumeUniqueVoxels.mat', 'FA', '/biac3/wandell4/users/elenary/longitudinal/figures', 'MoriGroups_FA_mle');
% dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberPropertiesMoriGroups_volumeUniqueVoxels.mat', 'FA', [], [], [], [], [], [], [], [], [], 'age group');
dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberPropertiesMoriGroups_Roi2RoiVolumeUniqueVoxels', 'fiberGroupVolume', '/biac3/wandell4/users/elenary/longitudinal/figures', 'MoriGroups_Volume_Roi2Roi_mle');
dti_Longitude_DisplayGrowthCurves('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberPropertiesMoriGroups_Roi2RoiVolumeUniqueVoxels', 'FA', '/biac3/wandell4/users/elenary/longitudinal/figures', 'MoriGroups_FA_Roi2Roi_mle');