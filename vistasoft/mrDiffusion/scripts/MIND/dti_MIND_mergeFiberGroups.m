% dti_MIND_mergeFiberGroups

% This code will load the 8 callosal fiber groups created with Quench and...
% 1. Merge them.
% 2. Cut them, so that only 10mm on each side of the callosum remains.
% 3. Group them so that the groups that comprise the genu, body, and
%    splenium are able to be analyzed as seperate groups.
% 4. Along the way...
%    * Rename the fibers directory from 'fibers_delete' to 'fibers'
%    * Get dtiComputeFiberProperties to work as a function (secondary).

%% Set directory structure, fiberGroups and options

baseDir = '/home/christine/APP/stanford_DTI/';
subCodeList = '/home/christine/APP/stanford_DTI/APPlist.txt';
subs = textread(subCodeList, '%s'); fprintf('\nWill process %d subjects...\n\n',numel(subs));
dirs = 'dti30trilinrt'; % This is the subFolder that contains the dt6.mat file (eg. dti30trilinrt) 

fiber = {'Mori_LOrb_Mori_ROrb.pdb','Mori_LLatFront_Mori_RLatFront.pdb','Mori_LAntFront_Mori_RAntFront.pdb'...
    'Mori_LSupFront_Mori_RSupFront.pdb','Mori_LPostPar_Mori_RPostPar.pdb','Mori_LSupPar_Mori_RSupPar.pdb'...
    'Mori_LTemp_Mori_RTemp.pdb','Mori_LOcc_Mori_ROcc.pdb'};


%% Merge Fibers

for ii=1:numel(subs)
    sub = dir(fullfile(baseDir,[subs{ii} '*']));
    if ~isempty(sub)
        subDir = fullfile(baseDir,sub.name);
        dt6Dir = fullfile(subDir,dirs);
        fiberDir = fullfile(dt6Dir,'fibers');
        if ~exist(fiberDir, 'file')
            cd(dt6dir)
            system('mv fibers_Delete fibers')
        else 
        end
        
        disp(['Processing ' subDir '...']);
try
        % Read in fiber groups 
        fg1 = mtrImportFibers(fullfile(fiberDir,fiber{1}));
        fg2 = mtrImportFibers(fullfile(fiberDir,fiber{2}));
        fg3 = mtrImportFibers(fullfile(fiberDir,fiber{3}));
        fg4 = mtrImportFibers(fullfile(fiberDir,fiber{4}));
        fg5 = mtrImportFibers(fullfile(fiberDir,fiber{5}));
        fg6 = mtrImportFibers(fullfile(fiberDir,fiber{6}));
        fg7 = mtrImportFibers(fullfile(fiberDir,fiber{7}));
        fg8 = mtrImportFibers(fullfile(fiberDir,fiber{8}));


        % Merge the groups, two at a time...
        fga = dtiMergeFiberGroups(fg1,fg2);
        clear fg1 fg2
        fgb = dtiMergeFiberGroups(fg3,fg4);
        fgc = dtiMergeFiberGroups(fg5,fg6);
        clear fg5 fg6
        fgd = dtiMergeFiberGroups(fg7,fg8);
        clear fg7

        % Merge Groups for CC seg: Genu, Midbody,Splenium
        genuFg = dtiMergeFiberGroups(fga,fg3);
        midBodyFg = dtiMergeFiberGroups(fg4,fgc);
        splFg = fg8;
        clear fg8


        fgA = dtiMergeFiberGroups(fga,fgb);
        clear fga fgb
        fgB = dtiMergeFiberGroups(fgc,fgd);
        clear fgc fgd

        allMergedFg = dtiMergeFiberGroups(fgA,fgB);
        clear fgA fgB

        allMergedFg = dtiFiberMidSagSegment(allMergedFg,10,'b');
        allMergedFg.name = 'CallosumSubGroupsMerged';

        dtiWriteFibersPdb(allMergedFg,[],fullfile(fiberDir,'CallosumSubGroupsMerged.pdb'));
        disp('success');

% This catch might be a problem while debugging.         
catch ME
    disp('One or more fiber groups not found. Merge will need to be done manually');
end

    else disp('No data found.');
        
    end
end
        
            
            
            
            