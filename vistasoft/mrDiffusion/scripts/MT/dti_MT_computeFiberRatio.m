% dti_MT_computeFiberRatio.m
%
% This script will compute the ratio of homotopic fibers in a given fiber
% group. 
%
%  We want to compute a homotopic fiber ratio: which will be the number of
%  homotopic fiber endpoints in the callosum divided by the total number of
%  fiber endpoints.
%        * These numbers can be computed by loading the fibers with
%     dtiReadFibers and comupting a fibers summary. The number of fibers is
%     the lengh of the index of fiber points. 
%     - Or simply the number of fibers as reported by the summary? 
%        * (leftHom)/(leftClean)=lHomRatio
%     -- Computed out of script 
%        * (rightHom)/(rightClean)=rHomRatio --
%     Computed out of script
%        o dtiReadFibers o dtiFiberSummary o WriteOutStats to excel file
%
% HISTORY:
% 2009.03.17 MP wrote the thing.
%

% TO DO: Write out the ratios into a text file.

%%
baseDir = '/biac3/wandell4/data/reading_longitude/';
dtiYr = {'dti_y1'};   %, 'dti_y2','dti_y3','dti_y4'};
logDir = fullfile(baseDir, 'MT_Project');


subs = {'am0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
   'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
    'sl0','sy0','tk0','tv0','vh0','vr0'}; % 'ao0'- none exist

%%

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
textFile = fullfile(logDir,['MtFiberRatio.txt']);
fid=fopen(textFile,'w');

fprintf(fid,'Subject \t Total Fibers \t Total Fibers Left \t Total Fibers Right \t Left Homotopic Fibers \t Right Homotopic Fibers \t Left Homotopic Fiber Ratio (LHOM/LTOTAL) \t Right Homotopic Fiber Ratio (RHOM/RTOTAL) \t Left Heterotopic Fibers \t Right Heterotopic Fibers \t Left Heterotopic Fiber Ratio \t Right Heterotopic Fiber Ratio \n');

for ii=1:length(subs)
    for jj=1:length(dtiYr)
        sub = dir(fullfile(baseDir,dtiYr{jj},[subs{ii},'*']));  
        if ~isempty(sub)
            subDir = fullfile(baseDir,dtiYr{jj},sub.name);
            fDir = fullfile(subDir,'dti06','fibers','MT');
            dt6 = fullfile(subDir,'dti06','dt6.mat');
            dt = dtiLoadDt6(dt6);
            
            lHom = dtiReadFibers(fullfile(fDir,'scoredFG_MTproject_100k_200_5_top1000_LEFT_clean_hom.mat'));
            numlHom = length(lHom.fibers);
            
            
            rHom = dtiReadFibers(fullfile(fDir,'scoredFG_MTproject_100k_200_5_top1000_RIGHT_clean_hom.mat'));
            numrHom = length(rHom.fibers);
            
            
            lHet = dtiReadFibers(fullfile(fDir,'scoredFG_MTproject_100k_200_5_top1000_LEFT_clean_het.mat'));
            numlHet = length(lHet.fibers);
            
            
            rHet = dtiReadFibers(fullfile(fDir,'scoredFG_MTproject_100k_200_5_top1000_RIGHT_clean_het.mat'));
            numrHet = length(rHet.fibers);
            
            
            lTotal = dtiReadFibers(fullfile(fDir,'scoredFG_MTproject_100k_200_5_top1000_LEFT_clean.mat'));
            numlTotal = length(lTotal.fibers);
            
            rTotal = dtiReadFibers(fullfile(fDir,'scoredFG_MTproject_100k_200_5_top1000_RIGHT_clean.mat'));          
            numrTotal = length(rTotal.fibers);
            
            totalFibers = (numlTotal+numrTotal);
            lHomRatio = (numlHom/numlTotal);
            rHomRatio = (numrHom/numrTotal);
            lHetRatio = (numlHet/numlTotal);
            rHetRatio = (numrHet/numrTotal);
            
            fprintf(fid,'%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n',sub.name,totalFibers,numlTotal,numrTotal,numlHom,numrHom,lHomRatio,rHomRatio,numlHet,numrHet,lHetRatio,rHetRatio);
            
        else
            disp('No data found. Skipping...');
        end
    end
end



