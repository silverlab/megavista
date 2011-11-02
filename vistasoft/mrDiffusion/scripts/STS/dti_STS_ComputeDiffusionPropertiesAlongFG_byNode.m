%% I. Set up fibersDir, dtDir andd roisDir for each participant 

subs = {'ab0','ad0','ada0','ajs0','am0','an0','ao0','ar0','bg0','ch0','clr0','cp0','crb0','ctb0','ctr0','da0','dh0','dm0','es0','hy0','jh0','jt0','kj0','ks0','lg0','ll0','mb0','mn0','nad0','nf0','nid0','pf0','pt0','rd0','rs0','rsh0','sg0','sl0','sy0','tk0','tm0','tv0','vh0','vr0','vt0','zs0','at0','js0','md0','mh0','mho0','mm0','rh0','ss0'};
baseDir = '/biac3/wandell4/data/reading_longitude/dti_y1/';
dirs    = 'dti06trilinrt';

fiberName = {'scoredFG_STS_STSnode2_CC_clipRight_top1000_cleaned.pdb','scoredFG_STS_STSnode3_CC_clipRight_top1000_cleaned.pdb','scoredFG_STS_STSnode4_CC_clipRight_top1000_cleaned.pdb','scoredFG_STS_STSnode5_CC_clipRight_top1000_cleaned.pdb'};
rois      = {'STSnode2','STSnode3','STSnode4','STSnode5'};

%% II. Set up parameters
numberOfNodes      = 50; 
propertyofinterest = {'fa','md', 'rd', 'ad'};
fgName             = fiberName; 
numsfgs            = length(fiberName); 
roi1name           = rois; 
roi2name           = 'CC_clipRight.mat';

%% III Loop.
for zz = 1:numel(propertyofinterest)
    for kk = 1:numel(fiberName)
        for ii=1:numel(subs)
            sub      = dir(fullfile(baseDir,[subs{ii} '*']));
            subDir   = fullfile(baseDir,sub.name);
            dt6Dir   = fullfile(subDir,dirs);
            fiberDir = fullfile(dt6Dir,'fibers','conTrack');
            roiDir   = fullfile(dt6Dir,'ROIs');
            try
                % III. 1 LOAD THE DATA
                fibersFile = fullfile(fiberDir, fgName{kk});
                fg         = mtrImportFibers(fibersFile);
                roi1File   = fullfile(roiDir, [roi1name{kk} '.mat']);
                roi2File   = fullfile(roiDir, roi2name);
                roi2       = dtiReadRoi(roi1File);
                roi1       = dtiReadRoi(roi2File);
                dt         = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));

                % III. 2 Compute
                [fa(:, ii),md(:, ii),rd(:, ii),ad(:, ii), SuperFibersGroup(ii)]=...
                    dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes);
            catch ME
                disp(ME);
                disp(['PROBLEM with subject: ' subs{ii} '. This subject will NOT be included in the graph!']);
            end
        end
        dtval.(propertyofinterest{zz}).(rois{kk}) = eval(propertyofinterest{zz});
    end
end

%% PLOT DATA

%% IV Plot results

saveDir = '/white/u8/lmperry/Desktop/DTI_figures_STS/dtvalByNode';
save((fullfile(saveDir,'dtval.mat')),'dtval');

    for zz = 1:numel(propertyofinterest) % fa,md,rd,ad
        for kk = 1:numel(rois)
            
            AVG = mean(dtval.(propertyofinterest{zz}).(rois{kk}),2);

            figure;
            plot(dtval.(propertyofinterest{zz}).(rois{kk}));
            hold on
            plot(AVG,'b','LineWidth',5);
            set(gca,'PlotBoxAspectRatio',[1,.7,1]);
                    
           switch propertyofinterest{zz}
                case 'fa'
                    yText = 'FA (weighted)';
                    titleText = ['Fractional Anisotropy Along' rois{kk}];
                case 'md'
                    yText = 'MD \mum^2/msec (weighted)';
                    titleText = ['Mean Diffusivity Along' rois{kk}];
                case 'rd'
                    yText = 'RD \mum^2/msec (weighted)';
                    titleText = ['Radial Diffusivity Along' rois{kk}];
                case 'ad'
                    yText = 'AD \mum^2/msec (weighted)';
                    titleText = ['Axial Diffusivity Along' rois{kk}];
            end

            title(titleText);
            ylabel(yText);
            xlabel('Fiber Group Trajectory');
            set(gca,'xtick',[0 numberOfNodes]);
            set(gca,'xticklabel',{'Callosum','STS'})
            saveName = [rois{kk} propertyofinterest{zz}];
            saveas(gcf,(fullfile(saveDir,saveName)),'epsc2');
        end
    end


%% V Plot results: Each node on the same grapgh.

saveDir = '/white/u8/lmperry/Desktop/DTI_figures_STS/dtvalByVal';
if ~exist(saveDir,'file'), mkdir(saveDir); end
save((fullfile(saveDir,'dtval.mat')),'dtval');

propertyofinterest = {'fa','md', 'rd', 'ad'};
rois               = {'STSnode2','STSnode3','STSnode4','STSnode5'};
col                = jet(numel(rois)); % set colors for graph.

    for zz = 1:numel(propertyofinterest) % fa,md,rd,ad
        figure;
        for kk = 1:numel(rois)
            
            AVG = mean(dtval.(propertyofinterest{zz}).(rois{kk}),2);

            
%             plot(dtval.(propertyofinterest{zz}).(rois{kk}),'color',col(kk,:));
            hold on
            plot(AVG,'k','LineWidth',5,'color',col(kk,:));
            set(gca,'PlotBoxAspectRatio',[1,.7,1]);
                    
            switch propertyofinterest{zz}
                case 'fa'
                    yText = 'FA (weighted)';
                    titleText = ['Fractional Anisotropy'];
                case 'md'
                    yText = 'MD \mum^2/msec (weighted)';
                    titleText = ['Mean Diffusivity'];
                case 'rd'
                    yText = 'RD \mum^2/msec (weighted)';
                    titleText = ['Radial Diffusivity'];
                case 'ad'
                    yText = 'AD \mum^2/msec (weighted)';
                    titleText = ['Axial Diffusivity '];
            end

            title(titleText);
            ylabel(yText);
            xlabel('Fiber Group Trajectory');
                        
        end
            set(gca,'xtick',[0 numberOfNodes]);
            set(gca,'xticklabel',{'Callosum','STS'})
            ld = legend(rois{1},rois{2},rois{3},rois{4});
            set(ld,'Interpreter','tex','Location','NorthEast');
            saveName = [propertyofinterest{zz}];
            saveas(gcf,(fullfile(saveDir,saveName)),'epsc2');
    end
    
           
    
    
    
%% VI Plot results for each node sorted by subject

saveDir = '/white/u8/lmperry/Desktop/DTI_figures_STS/dtvalByNodeSorted';
if ~exist(saveDir,'file'), mkdir(saveDir); end
% save((fullfile(saveDir,'dtval.mat')),'dtval');
load(fullfile(saveDir,'dtval.mat'));
load(fullfile(mrvDirup(saveDir),'fa_Sorted_Node2.mat'));
load(fullfile(mrvDirup(saveDir),'fa_Sorted_Node3.mat'));
load(fullfile(mrvDirup(saveDir),'fa_Sorted_Node4.mat'));
load(fullfile(mrvDirup(saveDir),'fa_Sorted_Node5.mat'));


propertyofinterest = {'fa'}; % ,'md', 'rd', 'ad'};
rois               = {'STSnode2','STSnode3','STSnode4','STSnode5'};
col                = jet(numel(subs)); % set colors for graph.

for zz = 1:numel(propertyofinterest) % fa,md,rd,ad
    for kk = 1:numel(rois)

        AVG = mean(dtval.(propertyofinterest{zz}).(rois{kk}),2);

        figure;
        hold on
        % Loop over each subject and plot their data using a different color line (col)
        for ss = 1:numel(subs)
            plot(dtval.(propertyofinterest{zz}).(rois{kk})(:,ss),'color',col(ss,:));
        end

        plot(AVG,'b','LineWidth',5);
        set(gca,'PlotBoxAspectRatio',[1,.7,1]);

        switch propertyofinterest{zz}
            case 'fa'
                yText = 'FA (weighted)';
                titleText = ['Fractional Anisotropy Along ' rois{kk}];
            case 'md'
                yText = 'MD \mum^2/msec (weighted)';
                titleText = ['Mean Diffusivity Along ' rois{kk}];
            case 'rd'
                yText = 'RD \mum^2/msec (weighted)';
                titleText = ['Radial Diffusivity Along ' rois{kk}];
            case 'ad'
                yText = 'AD \mum^2/msec (weighted)';
                titleText = ['Axial Diffusivity Along ' rois{kk}];
        end

        title(titleText);
        ylabel(yText);
        xlabel('Fiber Group Trajectory');
        set(gca,'xtick',[0 numberOfNodes]);
        set(gca,'xticklabel',{'Callosum','STS'});
        whitebg;
        saveName = [rois{kk} propertyofinterest{zz}];
        saveas(gcf,(fullfile(saveDir,saveName)),'epsc2');
    end
end


    

    
%% Plot VII Correlation Matrix
   
saveDir = '/white/u8/lmperry/Desktop/DTI_figures_STS/dtvalByNodeSorted';
if ~exist(saveDir,'file'), mkdir(saveDir); end

load(fullfile(mrvDirup(saveDir),'fa_Sorted_Node2.mat'));
load(fullfile(mrvDirup(saveDir),'fa_Sorted_Node3.mat'));
load(fullfile(mrvDirup(saveDir),'fa_Sorted_Node4.mat'));
load(fullfile(mrvDirup(saveDir),'fa_Sorted_Node5.mat'));


rois  = {'STSnode2','STSnode3','STSnode4','STSnode5'};
c = {'2','3','4','5'};

for ii = 1:numel(rois)
    dati = ['fas' c{ii}];
    r = corr(eval(dati)');  
    
    figure; imagesc(r);
        title(['Correlation Matrix for ' (rois{ii})]);
        xlabel('Bin Number');
        ylabel('Bin Number');
        colorbar;
    figure; plot(r(1,:), 'x');
    title(['Bin Correlations for' (rois{ii})]);
        xlabel('Bin Number');
        ylabel('r Value');
end
    
    
    
%     
%       r = corr(fas2');  
%     
%     figure; imagesc(r);
%         title('Correlation Matrix');
%         xlabel('Bin Number');
%         ylabel('Bin Number');
%         colorbar;
%     figure; plot(r(1,:), 'x');
%     title('Bin Correlations');
%         xlabel('Bin Number');
%         ylabel('r Value');
%     
%         
% 
%     
%     
    
    
    
    
    
    
    
    
    
    
    
