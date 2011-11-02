%script dti_Longitude_FindMoriGroups

%%Generate Mori fibers - for all the subjects in the londitudial dataset
%ER 01/2010

load('/biac3/wandell4/users/elenary/longitudinal/data/subjectCodesAll4Years.mat');
project_folder='/biac3/wandell4/data/reading_longitude/dti_y1234/';

for s=1:size(subjectCodes, 2); 
    fprintf('%s\n', subjectCodes{s}); 
    cd([project_folder subjectCodes{s}]);
    dt6File=fullfile(pwd, 'dti06trilinrt', 'dt6.mat');
    
    %Find Mori Groups and save
    [ fg, fg_unclassified]=dtiFindMoriTracts(dt6File, fullfile(fileparts(dt6File), 'fibers', 'MoriGroups.mat'), [], [], [],[], true);
    %This code did not save nonMori fibers which we would be curious to look at?
    dtiWriteFiberGroup(fg_unclassified,  fullfile(fileparts(dt6File), 'fibers', 'nonMori.mat')); 
end

%Other analyses included: 
% 1. longitudinal DTI -- adults
% subjectCodes={'ah051003', 'ah070508', 'mbs040503', 'mbs040908', 'rfd040630', 'rfd070508'}; 
% project_folder='/biac3/wandell4/data/reading_longitude/dti_adults/';
% lines 9-... of this script
% 2. crossectional dti - year 1 (those not included in all 4 years)
% subjectCodes={'ad040522', 'ada041018', 'ao041022', 'ar040522', 'bg040719', 'ch040712',  'cp041009', 'ctr040618', 'hy040602', 'js040726', 'jt040717', 'kj040929', 'ks040720', 'lg041019', 'mh040630', 'mm040925', 'nad040610',  'nf040812', 'nid040610', 'rh040630', 'rs040918', 'sg040910', 'sy040706', 'tk040817', 'tv040928', 'vh040719', 'vt040717'};
% project_folder='/biac3/wandell4/data/reading_longitude/dti_y1234/';
% 3. Longitudinal DTI - 2 adults with 4 repeats
% subjectCodes={'er100305', 'er100308', 'er100311', 'rfd100305', 'rfd100308', 'rfd100311', 'er100302', 'rfd100302'};
% project_folder='/biac3/wandell4/data/reading_longitude/dti_adults/';
% lines 9-... of this script