%script dti_Longitude_MoriFiberProperties
cd /biac3/wandell4/users/elenary/longitudinal/
addpath(genpath('~/vistasoft')); 
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008'));
subjCodesFile='/biac3/wandell4/users/elenary/longitudinal/subjectCodesAll4Years'; 
resultsDir='/biac3/wandell4/users/elenary/longitudinal/data'

%For all subjects with 4 years of DTI data /biac3/wandell4/users/elenary/longitudinal/subjectCodesAll4Years

%Compute Fiber Properties for each of the fiber subgroup within allConnectingGM_MoriGroups_DN.mat (initial BM solution) &
%allConnectingGM_DN_MoriGroups.mat (full brain BM solution, mori-classified "BM-selected" fibers) 



%The results are structured as Davie chose in dtiFiberSummaryNoGUI
% EXAMPLE: summary(S) = 2 x S struct with fields: 
%                                         subject
%                                         sfg
%Here sfg is a subgroup of fibers corresponding to MoriGroup

% EXAMPLE: summary(S).fiber(F) = 7 x F struct with fields:
%                                         name
%                                         length
%                                         numFibers
%                                         meanFA
%                                         meanMD
%                                         densityVol
%                                         errors
%

%02/02/2009 ER modified to apply to MorySymmGroupsCulled instead of
%MoriGroupsCulled (the latter used to generate figures for HBM abstract)
%This analysis is performed at 02/02/09 only for 27 longitudinal subjects
%who had 4 data points-- everyone else later

%06/13/2009 Elena modified to apply to MoriGroupsConnectingGM_DN results.
%These fibergroups are in new (compressed) format. 

%10/25/2009 ER modify to include processing of both allConnectingGM_MoriGroups_DN.mat (initial BM solution) &
%allConnectingGM_DN_MoriGroups.mat

curr=pwd; 

datadir='/biac3/wandell4/data/reading_longitude/dti_y1234';
load(subjCodesFile);

diary([pwd filesep 'summaryFiberPropertiesMoriGroups_DN.log']);

cd(datadir);
fiberDiameter=.2; %Is that so? The data were ran with parameter fiberDiameter (trueSA) of .2mm. 

summaryAll_Mori_DN = struct('subject',{},'sfg',{}); % intialize SUMMARY
summaryAll_DN_Mori = struct('subject',{},'sfg',{}); % intialize SUMMARY
% To get the labels for the 20 groups (actually MoriGroups generated for
% all subjects include only 18 groups)

labels = readTab(which('MNI_JHU_tracts_prob.txt'),',',false);
labels = labels(:,2);

fprintf(['Subjects total: ' num2str(length(subjectCodes)) '\n']);
fprintf('Processing: ');

for s=1:length(subjectCodes)
    
    summaryAll_Mori_DN(s).subject=fullfile(datadir, subjectCodes{s}, 'dti06trilinrt', 'fibers', 'allConnectingGM_MoriGroups_DN.mat'); 
    summaryAll_DN_Mori(s).subject=fullfile(datadir, subjectCodes{s}, 'dti06trilinrt', 'fibers', 'allConnectingGM_DN_MoriGroups.mat'); 
    
    fprintf(1, '%s\n', subjectCodes{s});
    
    dt6File=fullfile(subjectCodes{s}, 'dti06trilinrt', 'dt6.mat'); 
    dt=dtiLoadDt6(dt6File); 
    
    
    fgAll_Mori_DN=dtiLoadFiberGroup(summaryAll_Mori_DN(s).subject); %Load fibers; Mori groups are still in acpc space    
    fgAll_DN_Mori=dtiLoadFiberGroup(summaryAll_DN_Mori(s).subject); %Load fibers; Mori groups are still in acpc space    

summaryAll_Mori_DN(s).sfg=dtiFiberProperties(fgAll_Mori_DN, dt,[], fiberDiameter);
summaryAll_DN_Mori(s).sfg=dtiFiberProperties(fgAll_DN_Mori, dt,[], fiberDiameter);
save(fullfile(resultsDir, 'summaryFiberPropertiesMoriGroups_DN'), 'summaryAll_Mori_DN');  %Remember: first one will be "ALL MORI GROUPS");    
save(fullfile(resultsDir, 'summaryFiberProperties_DN_MoriGroups'), 'summaryAll_DN_Mori');  %Remember: first one will be "ALL MORI GROUPS");    

end
cd(curr)
diary off; 
load (fullfile(resultsDir, 'summaryFiberPropertiesMoriGroups_DN'));
summary=summaryAll_Mori_DN; 
save(fullfile(resultsDir, 'summaryFiberPropertiesMoriGroups_DN'), 'summary');  %Remember: first one will be "ALL MORI GROUPS");    
load(fullfile(resultsDir, 'summaryFiberProperties_DN_MoriGroups')); 
summary=summaryAll_DN_Mori; 
save(fullfile(resultsDir, 'summaryFiberProperties_DN_MoriGroups'), 'summary');  %Remember: first one will be "ALL MORI GROUPS");    


return

%%%%%%%%%%%%%%%%%%%%%%
%Code to collect reproduceability data (data not there yet)

subjectID={'at040918', 'at051008', 'at060825', 'at070815'};
project_folder='/biac3/wandell4/data/reading_longitude/dti_y1234/';
fiberDiameter=.2;
for s=1:4
    
cd([project_folder subjectID{s}]);
for trial=1:10
fgname=fullfile(project_folder, subjectID{s}, 'dti06trilinrt', 'fibers', ['allConnectingGM_MoriGroups_DN' num2str(trial) '.mat']);
fg=dtiLoadFiberGroup(fgname); %Load fibers; Mori groups are still in acpc space    
dt=dtiLoadDt6(fullfile(project_folder, subjectID{s}, 'dti06trilinrt', 'dt6.mat'));
relsummary(s, trial).sfg=dtiFiberProperties(fg, dt,[], fiberDiameter);

end

end
cd /biac3/wandell4/users/elenary/longitudinal/
save(['reliabilityFiberPropertiesMori_DN'], 'relsummary');  %Remember: first one will be "ALL MORI GROUPS");
