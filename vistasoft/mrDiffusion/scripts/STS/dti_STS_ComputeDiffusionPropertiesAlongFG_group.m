% Script: Group analysis of fiber groups: weighted average diffusion properties computed
%         along the FG path. 
%
%ER wrote it 12/2009
%LMP adapted to work with STS data structure 6/10
%
%
%% I. Set up fibersDir, dtDir andd roisDir for each participant 

subs    = {'at0','js0'};%,'md0','mh0','mho0','mm0','rh0','ss0'};
baseDir = '/biac3/wandell4/data/reading_longitude/dti_y1/';
dirs    = 'dti06trilinrt';

fiberName = {'scoredFG_STS_STSnode2_CC_clipRight_top1000_cleaned.pdb','scoredFG_STS_STSnode3_CC_clipRight_top1000_cleaned.pdb','scoredFG_STS_STSnode4_CC_clipRight_top1000_cleaned.pdb','scoredFG_STS_STSnode5_CC_clipRight_top1000_cleaned.pdb'};
rois      = {'STSnode2.mat','STSnode3.mat','STSnode4.mat','STSnode5.mat'};


%% II. Set up parameters
numberOfNodes      = 30; 
propertyofinterest = 'fa'; %Can also be md, rd, ad
fgName             = fiberName; 
numsfgs            = length(fiberName); 
roi1name           = rois; 
roi2name           = 'CC_clipRight.mat';


%% III. Loop
for ii=1:numel(subs)
    sub      = dir(fullfile(baseDir,[subs{ii} '*']));
    subDir   = fullfile(baseDir,sub.name);
    dt6Dir   = fullfile(subDir,dirs);
    fiberDir = fullfile(dt6Dir,'fibers','conTrack'); 
    roiDir   = fullfile(dt6Dir,'ROIs');
    
    dtDir{ii}     = dt6Dir;
    fibersDir{ii} = fiberDir;
    roisDir{ii}   = roiDir;
    
end

for jj=1:numel(subs)
    for sfg=1:numsfgs
        fibersFile = fullfile(fibersDir{jj}, fgName{sfg});
        roi1File   = fullfile(roisDir{jj}, roi1name{sfg});
        roi2File   = fullfile(roisDir{jj}, roi2name);

        % III. 1 LOAD THE DATA
        roi2  = dtiReadRoi(roi1File);
        roi1  = dtiReadRoi(roi2File);
        fg    = mtrImportFibers(fibersFile);

        cd(dtDir{jj}); dt=dtiLoadDt6('dt6.mat');

        % III. 2 Compute
        [fa(:, sfg),md(:, sfg),rd(:, sfg),ad(:, sfg), SuperFibersGroup(sfg)]= dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes);

    end

    %% IV Plot results
    figure;
    title(['Weighted average along the FG trajectory for ' propertyofinterest]);
    plot(eval(propertyofinterest));
    title(propertyofinterest); xlabel(['First node <-> Last node']);
    for sfg=1:numsfgs
        x(sfg) = SuperFibersGroup(sfg).fibers{1}(1, 1);
        y(sfg) = SuperFibersGroup(sfg).fibers{1}(2, 1);
        z(sfg) = SuperFibersGroup(sfg).fibers{1}(3, 1);
        xe(sfg)= SuperFibersGroup(sfg).fibers{1}(1, end);
        ye(sfg)= SuperFibersGroup(sfg).fibers{1}(2, end);
        ze(sfg)= SuperFibersGroup(sfg).fibers{1}(3, end);
    end

    display('Center-of-mass coordinates for superfiber endpoints are displayed as text');

    %You can add a legend if you like -- i did not.
    text(1, 0.5, {['x=' num2str(mean(x)) ], ['y=' num2str(mean(y))],  ['z=' num2str(mean(z))]});
    text(numberOfNodes-3, 0.5, {['x=' num2str(mean(xe)) ], ['y=' num2str(mean(ye))],  ['z=' num2str(mean(ze))]});
    % legend('','') % Goes here
    %%
end
