%script dti_Longitude_MoriFiberProperties

%For all subjects with MoriSLFGroupsCulled
%Compute Fiber Properties for each of the fiber subgroup withing
%MoriSLFGroupsCulled (those would be 15, 16, 19, 20)

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

%This function is obsolete and was used to fix a malicious run. If you are looking to batch-compute fiberProperties, consider looking at dtiLongitudeComputeMoriFiberProperties.  

curr='/biac3/wandell4/users/elenary/longitudinal'; 

datadir='/biac3/wandell4/data/reading_longitude/dti_y1234';
diary([pwd filesep 'summaryFiberProperties.log']);

cd(datadir);
distanceCrit=1.7;
all_subjects=strread(ls('*/dti06rt/Mori/MoriSLFGroupsCulled.mat'), '%s'); 
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
    
    fgname=char(all_subjects(subject, :));  %Loads MoriSLFGroupsCulled
    if ~exist(fgname, 'file') 
        continue; %bail out for the subject that dont have SLF Group yet
    end
    fg=dtiReadFibers(fgname); %Mori groups are still in acpc space    
    for sfg=1:max(fg.subgroup)
        if sum(fg.subgroup==sfg)==0 
           fprintf(1, ['No fibers in fibergroup' num2str(sfg) '\n']);
            continue; 
        else
        myfg=fg;
        myfg.fibers=fg.fibers(fg.subgroup==sfg);
        myfg.subgroup=fg.subgroup(fg.subgroup==sfg);
        myfg.seeds=fg.seeds(fg.subgroup==sfg);
        summary(subject).sfg(sfg).name=labels(sfg); 
        fprintf(1, [char(labels(sfg)) ' ...']);
        [summary(subject).sfg(sfg).numberOfFibers, summary(subject).sfg(sfg).fiberLength, summary(subject).sfg(sfg).FA, summary(subject).sfg(sfg).MD, summary(subject).sfg(sfg).axialADC, summary(subject).sfg(sfg).radialADC, summary(subject).sfg(sfg).linearity, summary(subject).sfg(sfg).planarity, summary(subject).sfg(sfg).fiberGroupVolume] = dtiFiberProperties(myfg, dt, distanceCrit);
        fprintf(1, '\n');
        end
    end
save([curr filesep 'summaryFiberProperties_SLF'], 'summary');     
end
cd(curr);
diary off; 



