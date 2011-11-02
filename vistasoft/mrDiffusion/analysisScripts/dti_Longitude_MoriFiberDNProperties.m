%script dti_Longitude_MoriFiberDNProperties -- NEEDS A SERIOUS MODIFICATION
%for DN (volume)

addpath(genpath('~/vistasoft')); 
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008'));

%For all subjects with MoriGroupsConnectingGM_DN (blue matter density
%normalized)

%Compute Fiber Properties for each of the fiber subgroup withing


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
%06/01/2009 ER modified to apply to density normalized
%MoriGroupsConnectingGM_DN

curr=pwd; 

datadir='/biac3/wandell4/data/reading_longitude/dti_y1234';
%diary([pwd filesep 'summaryFiberProperties.log']);
diary([pwd filesep 'summaryFiberPropertiesMoriDN.log']);

cd(datadir);
distanceCrit=.1;
all_subjects=strread(ls('*/dti06trilinrt/fibers/MoriGroupsConnectingGM_DN.mat'), '%s');  %This message "id: cannot find name for group ID 31" really  screws it up
summary = struct('subject',{},'sfg',{}); % intialize SUMMARY
% To get the labels for the 20 groups 

labels = readTab(which('MNI_JHU_tracts_prob.txt'),',',false);
labels = labels(:,2);

fprintf(['Subjects total: ' num2str(size(all_subjects, 1)) '\n']);
fprintf('Processing: ');

for subject=1:size(all_subjects, 1)
    
    summary(subject).subject=[datadir filesep char(all_subjects(subject, :))];
    fprintf(1, [' \n' char(all_subjects(subject, :)) ' \n']);
    
    dt6File=[fileparts(fileparts(char(all_subjects(subject, :)))) '/dt6.mat']; 
    dt=dtiLoadDt6(dt6File); 
    
    cd(fileparts(fileparts(fileparts(char(all_subjects(subject, :)))))); 
    fgname=char(all_subjects(subject, :)); 
    fgname=fgname(end-49:end); %superhacky. NEED to fix relative paths. 
    fg=dtiLoadFiberGroup(fgname); %Load fibers; Mori groups are still in acpc space    

summary(subject).sfg=dtiFiberProperties(fg, dt, [], distanceCrit);
save([curr filesep 'summaryFiberPropertiesMoriDN'], 'summary');  %Remember: first one will be "ALL MORI GROUPS");    
cd(datadir);
end
cd(curr);
diary off; 



