% dti_MIND_createFaMaps.m
%
% This script will take a group of subjects in subCodeList and create and
% save a map (nifti) based on values in their dt6.mat file. The
% *_map.nii.gz will be saved in the same directory as the dt6.mat file used
% to create it.
% 
% Different maps can be generated if you set the respective variable == 1.
%
% HISTORY:
% 11.11.09 - LMP wrote the thing.
% 11.12.09 - LMP - added support for creating and saving multiple maps.
%

%% Set directory structure and maps to generate

baseDir = '/home/christine/APP/stanford_DTI/';
subCodeList = '/home/christine/APP/stanford_DTI/APPlist.txt';
subs = textread(subCodeList, '%s'); fprintf('\nWill process %d subjects...\n\n',numel(subs));
dirs = 'dti30trilinrt'; % subFolder that contains the dt6.mat file (eg. dti30trilinrt) 

% Select which maps to generate and save. 1==yes, 0==no.
faMap = 0;
mdMap = 1;
rdMap = 1;
adMap = 1;

%% Loop over subjects and create the maps

for ii=1:numel(subs)
    sub = dir(fullfile(baseDir,[subs{ii} '*']));
    if ~isempty(sub)
        subDir = fullfile(baseDir,sub.name);
        dt6Dir = fullfile(subDir,dirs);

        disp(['Processing ' subDir '...']);

        % Compute a nifti Map
        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
        [eigVec eigVal] = dtiEig(dt.dt6);

        [fa,md,rd,ad] = dtiComputeFA(eigVal);

        clear eigVec eigVal

        
        if faMap == 1
            dtiWriteNiftiWrapper(fa,dt.xformToAcpc,fullfile(dt6Dir,'FA_map'));
            disp(['Writing FA map for ' sub.name]);
        end

        if mdMap == 1;
            dtiWriteNiftiWrapper(md,dt.xformToAcpc,fullfile(dt6Dir,'MD_map'));
            disp(['Writing MD map for ' sub.name]);
        end

        if rdMap == 1
            dtiWriteNiftiWrapper(rd,dt.xformToAcpc,fullfile(dt6Dir,'RD_map'));
            disp(['Writing RD map for ' sub.name]);
        end

        if adMap == 1
            dtiWriteNiftiWrapper(ad,dt.xformToAcpc,fullfile(dt6Dir,'AD_map'));
            disp(['Writing AD map for ' sub.name]);
        end          
    

        clear fa md rd ad

    else
        disp(['NOTE: ' subDir ' is empty.']);
    end
end