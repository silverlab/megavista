% Script: Group analysis of fiber groups: weighted average diffusion properties computed
%         along the FG path. 
%
% ER wrote it 12/2009
% LMP adapted to work with STS data structure 6/10
%
%
%% I. Set up fibersDir, dtDir andd roisDir for each participant 

subs        = {'AP','AS'};
baseDir = '/viridian/scr1/data/FINRA/';
dirs    = 'dti40';

fiberName   = {'scoredFG_FINRA_lthal_lmpfc_top500_clean.pdb','scoredFG_FINRA_rthal_rmpfc_top500_clean.pdb','scoredFG_FINRA_lnacc_lthal_top500_clean.pdb'...
                'scoredFG_FINRA_rnacc_rthal_top500_clean.pdb','scoredFG_FINRA_vta_lnacc_top500_clean.pdb','scoredFG_FINRA_vta_rnacc_top500_clean.pdb'};
rois      = {'lthal.mat','rthal.mat','lnacc.mat','rnacc.mat','vta.mat','vta.mat'};
rois2     = {'lmpfc.mat','rmpfc.mat','lthal.mat','rthal.mat','lnacc.mat','rnacc.mat'};


%% II. Set up parameters
numberOfNodes      = 30; 
propertyofinterest = 'fa'; %Can also be md, rd, ad
fgName             = fiberName; 
numsfgs            = length(fiberName); 
roi1name           = rois; 
roi2name           = rois2;


%% III. Loop
for ii=1:numel(subs)
    sub      = dir(fullfile(baseDir,[subs{ii} '*']));
    subDir   = fullfile(baseDir,sub.name);
    dt6Dir   = fullfile(subDir,'DTI',dirs);
    fiberDir = fullfile(dt6Dir,'fibers','conTrack'); 
    roiDir   = fullfile(subDir,'DTI','dti_rois');
    
    dtDir{ii}     = dt6Dir;
    fibersDir{ii} = fiberDir;
    roisDir{ii}   = roiDir;
    
end

for jj=1:numel(subs)
    for kk=1:numsfgs
        fibersFile = fullfile(fibersDir{jj}, fgName{kk});
        roi1File   = fullfile(roisDir{jj}, roi1name{kk});
        roi2File   = fullfile(roisDir{jj}, roi2name{kk});

        % III. 1 LOAD THE DATA
        roi2  = dtiReadRoi(roi1File);
        roi1  = dtiReadRoi(roi2File);
        fg    = mtrImportFibers(fibersFile);

        cd(dtDir{jj}); dt=dtiLoadDt6('dt6.mat');

        % III. 2 Compute
        [fa(:, kk),md(:, kk),rd(:, kk),ad(:, kk), SuperFibersGroup(kk)]=...
            dtiComputeDiffusionPropertiesAlongFG(fg, dt, roi1, roi2, numberOfNodes);

    end

    %% IV Plot results
    figure;
    title(['Weighted average along the FG trajectory for ' propertyofinterest]);
    plot(eval(propertyofinterest));
    hold on
    title(propertyofinterest); xlabel(['First node <-> Last node']);
    for ll=1:numsfgs
        x(ll) = SuperFibersGroup(ll).fibers{1}(1, 1);
        y(ll) = SuperFibersGroup(ll).fibers{1}(2, 1);
        z(ll) = SuperFibersGroup(ll).fibers{1}(3, 1);
        xe(ll)= SuperFibersGroup(ll).fibers{1}(1, end);
        ye(ll)= SuperFibersGroup(ll).fibers{1}(2, end);
        ze(ll)= SuperFibersGroup(ll).fibers{1}(3, end);
    end

    display('Center-of-mass coordinates for superfiber endpoints are displayed as text');

    %You can add a legend if you like -- i did not.
    text(1, 0.5, {['x=' num2str(mean(x)) ], ['y=' num2str(mean(y))],  ['z=' num2str(mean(z))]});
    text(numberOfNodes-3, 0.5, {['x=' num2str(mean(xe)) ], ['y=' num2str(mean(ye))],  ['z=' num2str(mean(ze))]});
    % legend('','') % Goes here
    %%
end























