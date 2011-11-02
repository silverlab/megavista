function data = dti_FFA_analyzeFibers

% This script will loop through a set of subjects (TODODIRS) and for each
% subject, analyze specific properties of a list of possible fiber groups
% (FIBERS), and create and save histograms of these measures:
% 1. Length (mean, max, min, std)
% 2. FA (mean, max, min, std)
% 3. MD (mean, max, min, std)
% 4. Number of fibers
% 5. Volume of fiber group
%
% NOTE: Length and volume are hacks. I need to find out how to put real
% units on these. Right now they are just length as number of points along
% fiber, and volume is number of unique voxels (itself a hack) through
% which at least one fiber passes.
%
% DY 2008/04/01

% Set directories
if ispc
    dtiDir = 'W:\projects\Kids\dti\';
else
    dtiDir = '/biac1/kgs/projects/Kids/dti/';
end

% Directory to save figures
saveDir = fullfile(dtiDir,'davie','fiberresults');
subs={'adult_acg','adult_gg','adol_ar','adol_dw','adol_is','adol_kwl','adol_kll'};

todoDirs = {fullfile('adults','3T_AP','acg_38yo_010108'),...
    fullfile('adults','gg_37yo_091507_FreqDirLR'),...
    fullfile('adolescents','3T_AP','ar_12yo_121507'),...
    fullfile('adolescents','3T_AP','dw_14yo_102007'),...
    fullfile('adolescents','3T_AP','is_16yo_120907'),...
    fullfile('adolescents','3T_AP','kwl_14yo_010508'),...
    fullfile('adolescents','kll_18yo_011908_FreqDirLR')};

fibers = {'LFFA_sphere10+LLOf_sphere10.mat',...
    'LFFA_sphere10+LLOf_sphere10_endpts.mat',...
    'LFFA_sphere10+LSTSf_sphere10.mat',...
    'LFFA_sphere10+LSTSf_sphere10_endpts.mat',...
    'LLOf_sphere10+LFFA_sphere10.mat',...
    'LLOf_sphere10+LFFA_sphere10_endpts.mat',...
    'LLOf_sphere10+LSTSf_sphere10.mat',...
    'LLOf_sphere10+LSTSf_sphere10_endpts.mat',...
    'RFFA_sphere10+RLOf_sphere10.mat',...
    'RFFA_sphere10+RLOf_sphere10_endpts.mat',...
    'RFFA_sphere10+RSTSf_sphere10.mat',...
    'RFFA_sphere10+RSTSf_sphere10_endpts.mat',...
    'RLOf_sphere10+RFFA_sphere10.mat',...
    'RLOf_sphere10+RFFA_sphere10_endpts.mat',...
    'RLOf_sphere10+RSTSf_sphere10.mat',...
    'RLOf_sphere10+RSTSf_sphere10_endpts.mat'};

%Initialize data struct
data.subjects = subs;
data.fibers = fibers;
data.notes{1} = 'Number of voxels through which at least one fiber passes, intended as analog to fiber volume. Hack.';
data.notes{2} = 'Number of fibers in fiber group (length(fg.fibers))';
data.notes{3} = 'Mean FAs/FG/subject. Create single matrix of FAs for all pts on all fibers in FG, and take mean of this';
data.notes{4} = 'Mean MDs/FG/subject. Create single matrix of MDs for all pts on all fibers in FG, and take mean of this';
data.notes{5} = 'Mean number of points for each fiber group (mean(length(fg.fibers{:})), intended as analog to length. Hack.';
data.thenumvoxels = zeros(length(todoDirs),length(fibers));
data.thenumfibers = zeros(length(todoDirs),length(fibers));
data.themeanfas = zeros(length(todoDirs),length(fibers));
data.themeanmds = zeros(length(todoDirs),length(fibers));
data.themeanlengths = zeros(length(todoDirs),length(fibers));

% Loops through each of the to-do directories
for ii=1:length(todoDirs)
    thisDir = fullfile(dtiDir,todoDirs{ii},'dti30');
    fname = fullfile(thisDir,'dt6.mat');
    disp(['Processing ' fname '...']); %displays a string on the screen
    dt = dtiLoadDt6(fname); % this will load the dt6 file
    fiberDir = fullfile(thisDir,'fibers','functional');
    
    for jj=1:length(fibers)
        if(exist(fullfile(fiberDir,fibers{jj}),'file'))
            
            % If fiber file exists and there are fibers in it
            fg=dtiReadFibers(fullfile(fiberDir,fibers{jj}));
            if(length(fg.fibers)>0)
                
                % Compute FAs
                fa=[];
                fgfas = dtiGetValFromFibers(dt.dt6,fg,inv(dt.xformToAcpc),'fa');
                % Take out endpoints, because these can go to edge of brain
                % mask and have untrustworthy values
                for(ll=1:length(fgfas))
                    fa=[fa; fgfas{ll}(2:end-1)];
                end
                % This will create figures and save them to file.
                % Can also save and show image as jpeg: saveas('jpg'), imshow('jpg')
                % To view saved figures --> open('fig'): no need to call
                % figure first
                figure;hist(fa,30);hold on;
                xlabel('FA');ylabel('Number of fiber points');
                title(fibers{jj},'Interpreter','none'); % Print underscores
                h=gcf;set(h,'name',['Distribution of FAs for ' fibers{jj}]);
                savename=fullfile(saveDir,[subs{ii} '_' fibers{jj} '_FA.fig']);
                saveas(h,savename,'fig');

                % Compute MDs
                md=[];
                fgmds = dtiGetValFromFibers(dt.dt6,fg,inv(dt.xformToAcpc),'md');
                for(ll=1:length(fgmds))
                    md=[md; fgmds{ll}(2:end-1)];
                end
                figure;hist(md,30);hold on;
                xlabel('MD');ylabel('Number of fiber points');
                title(fibers{jj},'Interpreter','none'); % Print underscores
                h=gcf;set(h,'name',['Distribution of MDs for ' fibers{jj}]);
                savename=fullfile(saveDir,[subs{ii} '_' fibers{jj} '_MD.fig']);
                saveas(h,savename,'fig');
                
                % Compute lengths
                lengths=[];
                for ll=1:length(fg.fibers)
                    lengths=[lengths length(fg.fibers{ll}(2:end-1))];
                end
                figure;hist(lengths,30);hold on;
                xlabel('Length');ylabel('Number of fibers');
                title(fibers{jj},'Interpreter','none'); % Print underscores
                h=gcf;set(h,'name',['Distribution of lengths for ' fibers{jj}]);
                savename=fullfile(saveDir,[subs{ii} '_' fibers{jj} '_Length.fig']);
                saveas(h,savename,'fig');
%                 
                % Count number of fibers
                numFibers=length(fg.fibers);
                
                % Compute fiber density volume hack: basically this will
                % count the number of unique voxels through which at least
                % one fiber passes.
                %
                % NOTE: not sure if this is valid. Check against value
                % obtained by the GUI and ask Bob for feedback.
                voxels = [];
                for ll=1:length(fg.fibers)
                    voxels=[voxels; unique(round(fg.fibers{ll})','rows')];
                end
                numVoxels=(unique(voxels,'rows'));
                numVoxels=length(numVoxels);
                
                % Update data arrays with values for each FG
                data.thenumvoxels(ii,jj)=numVoxels;
                data.thenumfibers(ii,jj)=numFibers;
                data.themeanfas(ii,jj)=mean(fa);
                data.themeanmds(ii,jj)=mean(md);
                data.themeanlengths(ii,jj)=mean(lengths);
            end
            clear fg

        elseif(~exist(fullfile(fiberDir,fibers{jj}),'file'))
            % Put some kind of marker in the data matrix so that we do
            % not treat subject the same as if they did have the
            % relevant ROIs, but just no fibers were tracked
            data.thenumvoxels(ii,jj)=NaN;
            data.thenumfibers(ii,jj)=NaN;
            data.themeanfas(ii,jj)=NaN;
            data.themeanmds(ii,jj)=NaN;
            data.themeanlengths(ii,jj)=NaN;
        end
    end
end

savedataname=fullfile(saveDir, ['data_nofirstlast_' date '.mat']);
save(savedataname,'data')

