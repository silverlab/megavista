% This code is for analyzing the DATA struct output by the function
% DTI_FFA_ANALYZEFIBERS.
%
% 2008/04/02

% Calculate number of subjects who had a particular fiber group. This
% should include all subjects whose number of fibers is not 0 and whose
% Analysis across subjects for a particular fiber group can proceed in this
% way:  

dataDir='W:\projects\Kids\dti\davie\fiberresults';
load(fullfile(dataDir,'data_nofirstlast04-Apr-2008.mat'));

for ii=1:length(data.fibers)
    fprintf(1,'\nSummary for fiber group %s\n',data.fibers{ii});
    alltracked=sum(~isnan(data.thenumfibers(:,ii)));
    hasfibers=((data.thenumfibers(:,ii)>0));
    alltrackedwfg=sum(hasfibers);
    fprintf(1,'%d subjects of %d tracked have at least one fiber in FG\n',...
        alltrackedwfg,alltracked);

    % Volume
    themean=mean(data.thenumvoxels(hasfibers,ii));
    themin=min(data.thenumvoxels(hasfibers,ii));
    themax=max(data.thenumvoxels(hasfibers,ii));
    thestd=std(data.thenumvoxels(hasfibers,ii));
    fprintf(1,'Volume (voxels, mm^3): Mean: %.02f, Min: %.02f, Max: %.02f, Std: %.02f (n=%d)\n',...
        themean,themin,themax,thestd,alltrackedwfg);
    summaryvolumes(ii)=themean;
    summaryvolumesstd(ii)=thestd;
    
    % Number of fibers
    themean=mean(data.thenumfibers(hasfibers,ii));
    themin=min(data.thenumfibers(hasfibers,ii));
    themax=max(data.thenumfibers(hasfibers,ii));
    thestd=std(data.thenumfibers(hasfibers,ii));
    fprintf(1,'Number of fibers: Mean: %.02f, Min: %.02f, Max: %.02f, Std: %.02f (n=%d)\n',...
        themean,themin,themax,thestd,alltrackedwfg);
    summarynumfibers(ii)=themean;
    summarynumfibersstd(ii)=thestd;
    
    % Mean FA
    themean=mean(data.themeanfas(hasfibers,ii));
    themin=min(data.themeanfas(hasfibers,ii));
    themax=max(data.themeanfas(hasfibers,ii));
    thestd=std(data.themeanfas(hasfibers,ii));
    fprintf(1,'Mean FA: Mean: %.04f, Min: %.04f, Max: %.04f, Std: %.04f (n=%d)\n',...
        themean,themin,themax,thestd,alltrackedwfg);
    summaryfa(ii)=themean;
    summaryfastd(ii)=thestd;
    
    % Mean diffusivity
    themean=mean(data.themeanmds(hasfibers,ii));
    themin=min(data.themeanmds(hasfibers,ii));
    themax=max(data.themeanmds(hasfibers,ii));
    thestd=std(data.themeanmds(hasfibers,ii));
    fprintf(1,'Mean diffusivity (um^2/ms): Mean: %.04f, Min: %.04f, Max: %.04f, Std: %.04f (n=%d)\n',...
        themean,themin,themax,thestd,alltrackedwfg);
    summarymd(ii)=themean;
    summarymdstd(ii)=thestd;

    % Mean length
    themean=mean(data.themeanlengths(hasfibers,ii));
    themin=min(data.themeanlengths(hasfibers,ii));
    themax=max(data.themeanlengths(hasfibers,ii));
    thestd=std(data.themeanlengths(hasfibers,ii));
    fprintf(1,'Mean length (numPoints,mm?): Mean: %.04f, Min: %.04f, Max: %.04f, Std: %.04f (n=%d)\n',...
        themean,themin,themax,thestd,alltrackedwfg);
    summarylength(ii)=themean;
    summarylengthstd(ii)=thestd;
end

% Lengths figure
locations=linspace(1,.5*length(data.fibers),.5*length(data.fibers));
barlabels={'FFA+LO','FFA+LOe','FFA+STS','FFA+STSe','LO+FFA','LO+FFAe','LO+STS','LO+STSe'};
h=figure; set(h,'name','Mean lengths by fiber group (std)');
summarycols=[summarylength(1:8); summarylength(9:16)]';
summarystdcols=[summarylengthstd(1:8); summarylengthstd(9:16)]';
b=bar(locations,summarycols)
errorpositions=[(1:8)-.15; (1:8)+.15]'
hold on; errorbar(errorpositions,summarycols,summarystdcols,'k.')
title('Mean lengths by fiber group (std)');
legend('L','R')
ylabel('Mean length (numPoints--mm?)');
xlabel('ROIs');
set(gca,'XTickLabel',barlabels)
set(gca,'XTick',locations)
set(gca,'Position',[.08 .08 .85 .85]);
set(gca,'FontName','Helvetica');
set(gca,'FontSize',10);
xlim([.5 .5*length(data.fibers)+.5])
savename=fullfile(dataDir, 'Summary_lengths.fig');
saveas(h,savename,'fig'); close(h);

% Volume figure
locations=linspace(1,.5*length(data.fibers),.5*length(data.fibers));
barlabels={'FFA+LO','FFA+LOe','FFA+STS','FFA+STSe','LO+FFA','LO+FFAe','LO+STS','LO+STSe'};
h=figure; set(h,'name','Mean volume by fiber group (voxels)');
summarycols=[summaryvolumes(1:8); summaryvolumes(9:16)]';
summarystdcols=[summaryvolumesstd(1:8); summaryvolumesstd(9:16)]';
b=bar(summarycols)
errorpositions=[(1:8)-.15; (1:8)+.15]'
hold on; errorbar(errorpositions,summarycols,summarystdcols,'k.')
title('Mean volume by fiber group (std)');
legend('L','R')
ylabel('Mean volume (numVoxels--mm^3?)');
xlabel('ROIs');
set(gca,'XTickLabel',barlabels)
set(gca,'XTick',locations)
set(gca,'Position',[.08 .08 .85 .85]);
set(gca,'FontName','Helvetica');
set(gca,'FontSize',10);
xlim([.5 .5*length(data.fibers)+.5])
savename=fullfile(dataDir 'Summary_volumes.fig']);
saveas(h,savename,'fig'); close(h);

% FA figure
locations=linspace(1,.5*length(data.fibers),.5*length(data.fibers));
barlabels={'FFA+LO','FFA+LOe','FFA+STS','FFA+STSe','LO+FFA','LO+FFAe','LO+STS','LO+STSe'};
h=figure; set(h,'name','Mean FA by fiber group (range:0-1)');
summarycols=[summaryfa(1:8); summaryfa(9:16)]';
summarystdcols=[summaryfastd(1:8); summaryfastd(9:16)]';
b=bar(summarycols)
errorpositions=[(1:8)-.15; (1:8)+.15]'
hold on; errorbar(errorpositions,summarycols,summarystdcols,'k.')
title('Mean FA by fiber group (std)');
legend('L','R')
ylabel('Mean FA (range:0-1)');
xlabel('ROIs');
set(gca,'XTickLabel',barlabels)
set(gca,'XTick',locations)
set(gca,'Position',[.08 .08 .85 .85]);
set(gca,'FontName','Helvetica');
set(gca,'FontSize',10);
xlim([.5 .5*length(data.fibers)+.5])
savename=fullfile(dataDir 'Summary_fas.fig']);
saveas(h,savename,'fig'); close(h);

% MD figure
locations=linspace(1,.5*length(data.fibers),.5*length(data.fibers));
barlabels={'FFA+LO','FFA+LOe','FFA+STS','FFA+STSe','LO+FFA','LO+FFAe','LO+STS','LO+STSe'};
h=figure; set(h,'name','Mean diffusivity by fiber group (um^2/ms)');
summarycols=[summarymd(1:8); summarymd(9:16)]';
summarystdcols=[summarymdstd(1:8); summarymdstd(9:16)]';
b=bar(summarycols)
errorpositions=[(1:8)-.15; (1:8)+.15]'
hold on; errorbar(errorpositions,summarycols,summarystdcols,'k.')
title('Mean diffusivity by fiber group (std)');
legend('L','R')
ylabel('Mean diffusivity (um^2/ms)');
xlabel('ROIs');
set(gca,'XTickLabel',barlabels)
set(gca,'XTick',locations)
set(gca,'Position',[.08 .08 .85 .85]);
set(gca,'FontName','Helvetica');
set(gca,'FontSize',10);
xlim([.5 .5*length(data.fibers)+.5])
savename=fullfile(dataDir 'Summary_mds.fig']);
saveas(h,savename,'fig'); close(h);

% Number of fibers
locations=linspace(1,.5*length(data.fibers),.5*length(data.fibers));
barlabels={'FFA+LO','FFA+LOe','FFA+STS','FFA+STSe','LO+FFA','LO+FFAe','LO+STS','LO+STSe'};
h=figure; set(h,'name','Mean diffusivity by fiber group (um^2/ms)');
summarycols=[summarynumfibers(1:8); summarynumfibers(9:16)]';
summarystdcols=[summarynumfibersstd(1:8); summarynumfibersstd(9:16)]';
b=bar(summarycols)
errorpositions=[(1:8)-.15; (1:8)+.15]'
hold on; errorbar(errorpositions,summarycols,summarystdcols,'k.')
title('Mean number of fibers per fiber group (std)');
legend('L','R')
ylabel('Mean number of fibers');
xlabel('ROIs');
set(gca,'XTickLabel',barlabels)
set(gca,'XTick',locations)
set(gca,'Position',[.08 .08 .85 .85]);
set(gca,'FontName','Helvetica');
set(gca,'FontSize',10);
xlim([.5 .5*length(data.fibers)+.5])
savename=fullfile(dataDir 'Summary_numfibers.fig']);
saveas(h,savename,'fig'); close(h);