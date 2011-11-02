subjectCode = 'as050307';
baseDir     = '/biac2/wandell2/data/reading_longitude/dti_adults';
leftRight   = {'L','R'};

numResample = 400000;

% set up length penalties that we will calculate
smoothStd     = [0.078 0.157 0.314 0.628 0.814 1.26 1.88 2.51];
lengthPenalty = [0.2 0.35 0.42 0.5 0.6 0.75 0.8 0.85 0.90 0.95];

dataDir   = fullfile(baseDir,subjectCode);
sisrDir   = fullfile(dataDir,'bin','metrotrac','sisr');
pSpaceDir = fullfile(sisrDir,'param_space');

dt6File = fullfile(dataDir,sprintf('%s_dt6_noMask.mat',subjectCode));
dt      = load(dt6File,'xformToAcPc');

for ii = 1:2
    % load original params file
    samplerOptsFile = fullfile(sisrDir,[leftRight{ii},'OR_met_params.txt']);
    mtr             = mtrLoad(samplerOptsFile,dt.xformToAcPc);
    
    % pre-computed paths
    pathsFiles = dir(fullfile(sisrDir,[leftRight{ii},'OpticRadiation*.dat']));
    numFile    = length(pathsFiles);
    fgFiles    = cell(1,numFile);

    for jj = 1:numFile
        fgFiles{jj} = fullfile(sisrDir,pathsFiles(jj).name);
    end

    % resampling
    for ss = 1:length(smoothStd)
        % updates smooth penalty
        mtr        = mtrSet(mtr,'smooth_std',smoothStd(ss));
        smoothName = sprintf('smooth%d',floor(100*smoothStd(ss)));

        for ll = 1:length(lengthPenalty)
            % updates length penalty
            mtr             = mtrSet(mtr,'abs_normal',lengthPenalty(ll));
            
            lenPenName      = sprintf('len%d',floor(100*lengthPenalty(ll)));
            specificName    = sprintf('%sOR_met_params_%s_%s.txt',leftRight{ii},smoothName,lenPenName);
            pathsName       = sprintf('%sOR_reSamp_%s_%s.txt',smoothName,lenPenName);
            samplerOptsFile = fullfile(pSpaceDir,specificName);
            newFgFile       = fullfile(pSpaceDir,[leftRight{ii},'OR_reSamp_',smoothName,'_',lenPenName,'_',datestr(now,30),'.dat']);
           
            % saves new param file
            mtrSave(mtr,samplerOptsFile,dt.xformToAcPc);
            
            % resample with new param
            mtrResampleSISPathways(fgFiles,samplerOptsFile,numResample,newFgFile);
        end
    end
end
