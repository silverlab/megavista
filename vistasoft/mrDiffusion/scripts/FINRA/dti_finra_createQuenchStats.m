% 
% 
% HISTORY: 3.16.11 - LMP wrote the thing.
%         
%% Set directory structure
logDir      = '/biac2b/data1/finra/DTI/';
baseDir     = '/biac2b/data1/finra/';
subs       = {'ap'};
%subs        = {'ap','as','ba','bh','bp','cc','ch','cl','cn','ko','lb','lg','ls','lu','me','mw','nh','nm','rc','sc','sw','sy','te','th','ww'};
dirs        = 'dti40';    

session2    = 0;

if session2 == 1
    baseDir     = '/biac2b/data1/finra/session2';
    subs 	= {'bg','jo','kc','mc','md','na'};
end


%% Set fiber groups
fiberName   = {'scoredFG_FINRA_lthal_lmpfc_top500_clean.pdb','scoredFG_FINRA_rthal_rmpfc_top500_clean.pdb','scoredFG_FINRA_lnacc_lthal_top500_clean.pdb'...
                'scoredFG_FINRA_rnacc_rthal_top500_clean.pdb','scoredFG_FINRA_vta_lnacc_top500_clean.pdb','scoredFG_FINRA_vta_rnacc_top500_clean.pdb'... 
                'scoredFG_FINRA_lnacc_lmpfc_top500_clean.pdb','scoredFG_FINRA_rnacc_rmpfc_top500_clean.pdb'};

%% Run the functions

for ii=1:numel(subs)
    sub = dir(fullfile(baseDir,[subs{ii} '*']));
    if ~isempty(sub)
        subDir   = fullfile(baseDir,sub.name);
        dt6Dir   = fullfile(subDir,'DTI',dirs);
        fiberDir = fullfile(dt6Dir,'fibers','conTrack');
        roiDir   = fullfile(subDir,'dti_rois');

        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));

        fprintf('\nProcessing %s\n', subDir);

        % Read in fiber groups
        for kk=1:numel(fiberName)
            fiberGroup = fullfile(fiberDir, fiberName{kk});

            if exist(fiberGroup,'file')
                disp(['Computing quench stats for ' fiberGroup ' ...']);

                %  nifti FA Map
                dt = dtiLoadDt6(fullfile(dt6dir,'dt6.mat'));
                [vec val] = dtiEig(dt.dt6);
                fa = dtiComputeFA(val);
                faFile = fullfile(dt6dir,'faMap.nii.gz');
                dtiWriteNiftiWrapper(fa,dt.xformToAcpc,faFile);

                % Create Quench stats and write out the fibers

                fg = mtrImportFibers(fullfile(fiberDir,fiberName{kk}));
                statFiberName = 'FA';
                statPointName = 'AVG';
                perPoint = 1;
                t1File = subDir('t1acpc.nii.gz');
                img = readFileNifti(t1File);

                fgS = dtiCreateQuenchStats(fg,statFiberName,statPointName,perPoint,img);
                newFiberName = fullfile(fiberDir,[statFiberName '_' fgS.name '.pdb']);
                mtrExportFibers(fgS,newFiberName);
            else
                fprintf('\nSubject %s does not have specified fiber group %s\n', subs{ii}, fiberGroup);
            end
        end
    else 
        fprintf('% Does not exist, skipping...',subs{ii});
    end
end
