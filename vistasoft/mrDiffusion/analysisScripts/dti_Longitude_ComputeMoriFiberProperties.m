%script dti_Longitude_MoriFiberProperties

addpath(genpath('~/vistasoft')); 
addpath(genpath('/usr/local/matlab/toolbox/mri/spm5_r2008'));

%For all subjects with MoriGroupsCulled
%Compute Fiber Properties for each of the fiber subgroup withing
%MoriGroupsCulled

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

curr=pwd; 

datadir='/biac3/wandell4/data/reading_longitude/dti_y1234';
%diary([pwd filesep 'summaryFiberProperties.log']);
diary([pwd filesep 'summaryFiberPropertiesMoriSymm.log']);

cd(datadir);
distanceCrit=1.7;
all_subjects=strread(ls('*/dti06rt/Mori/MoriSymmGroupsCulled.mat'), '%s'); 
summary = struct('subject',{},'sfg',{}); % intialize SUMMARY
% To get the labels for the 20 groups (actually MoriGroups generated for
% all subjects include only 18 groups)

labels = readTab(which('MNI_JHU_tracts_prob.txt'),',',false);
labels = labels(:,2);

fprintf(['Subjects total: ' num2str(size(all_subjects, 1)) '\n']);
fprintf('Processing: ');

for subject=1:size(all_subjects, 1)
    
    summary(subject).subject=[datadir filesep char(all_subjects(subject, :))];
    fprintf(1, [' \n' char(all_subjects(subject, :)) ' \n']);
    
    dt6File=[fileparts(fileparts(char(all_subjects(subject, :)))) '/dt6.mat']; 
    dt=dtiLoadDt6(dt6File); 
    
    fgname=char(all_subjects(subject, :));  %Loads MoriGroupsSymmCulled
    load(fgname); %Load fibers; Mori groups are still in acpc space    

% Commented out hacky old way of computing properties for subgroups -- dtiFiberProperties now does subgroups
%  for sfg=1:max(fg.subgroup)
%        if sum(fg.subgroup==sfg)==0 
%           fprintf(1, 'No fibers in this fibergroup \n');
%            continue; 
%        else
%       myfg=fg;
%        myfg.fibers=fg.fibers(fg.subgroup==sfg);
%        myfg.subgroup=fg.subgroup(fg.subgroup==sfg);
%        myfg.seeds=fg.seeds(fg.subgroup==sfg);
%        summary(subject).sfg(sfg).name=labels(sfg); 
%        fprintf(1, [char(labels(sfg)) ' ...']);
%        [summary(subject).sfg(sfg).numberOfFibers, summary(subject).sfg(sfg).fiberLength, summary(subject).sfg(sfg).FA, summary(subject).sfg(sfg).MD, summary(subject).sfg(sfg).axialADC, summary(subject).sfg(sfg).radialADC, summary(subject).sfg(sfg).linearity, summary(subject).sfg(sfg).planarity, summary(subject).sfg(sfg).fiberGroupVolume] = dtiFiberProperties(myfg, dt, distanceCrit);
%         fprintf(1, '\n');
%        end
%    end

summary(subject).sfg=dtiFiberProperties(fg, dt, distanceCrit);
save([curr filesep 'summaryFiberPropertiesMoriSymm'], 'summary');  %Remember: first one will be "ALL MORI GROUPS");    
end
cd(curr);
diary off; 



