load('/biac3/wandell5/data/relaxometry/100405HLF3T/anal/N_9Sub_fibValMat.mat')
load('/biac3/wandell5/data/relaxometry/100405HLF3T/anal/MS_fibValMat.mat')
fgNames={'Cort Spin' 'Inf Front Occ' 'Inf Long' 'Arcuate'};
fa{1}=squeeze(Res.faVal(1:9,1,:))
fa{2}=squeeze(Res.faVal(1:9,2,:))
fa{3}=squeeze(Res.faVal(1:9,9,:))
fa{4}=squeeze(Res.faVal(1:9,10,:))
fa{5}=squeeze(Res.faVal(1:9,11,:))
fa{6}=squeeze(Res.faVal(1:9,12,:))
fa{7}=squeeze(Res.faVal(1:9,17,:))
fa{8}=squeeze(Res.faVal(1:9,18,:))
hlf{1}=squeeze(Res.hlfVal(1:9,1,:))
hlf{2}=squeeze(Res.hlfVal(1:9,2,:))
hlf{3}=squeeze(Res.hlfVal(1:9,9,:))
hlf{4}=squeeze(Res.hlfVal(1:9,10,:))
hlf{5}=squeeze(Res.hlfVal(1:9,11,:))
hlf{6}=squeeze(Res.hlfVal(1:9,12,:))
hlf{7}=squeeze(Res.hlfVal(1:9,17,:))
hlf{8}=squeeze(Res.hlfVal(1:9,18,:))
wf{1}=1-squeeze(Res.wfVal(1:9,1,:))
wf{2}=1-squeeze(Res.wfVal(1:9,2,:))
wf{3}=1-squeeze(Res.wfVal(1:9,9,:))
wf{4}=1-squeeze(Res.wfVal(1:9,10,:))
wf{5}=1-squeeze(Res.wfVal(1:9,11,:))
wf{6}=1-squeeze(Res.wfVal(1:9,12,:))
wf{7}=1-squeeze(Res.wfVal(1:9,17,:))
wf{8}=1-squeeze(Res.wfVal(1:9,18,:))
%MS sub
faM{1}=squeeze(ResMS.faVal(1,1,:))
faM{2}=squeeze(ResMS.faVal(1,2,:))
faM{3}=squeeze(ResMS.faVal(1,9,:))
faM{4}=squeeze(ResMS.faVal(1,10,:))
faM{5}=squeeze(ResMS.faVal(1,11,:))
faM{6}=squeeze(ResMS.faVal(1,12,:))
faM{7}=squeeze(ResMS.faVal(1,17,:))
faM{8}=squeeze(ResMS.faVal(1,18,:))
hlfM{1}=squeeze(ResMS.hlfVal(1,1,:))
hlfM{2}=squeeze(ResMS.hlfVal(1,2,:))
hlfM{3}=squeeze(ResMS.hlfVal(1,9,:))
hlfM{4}=squeeze(ResMS.hlfVal(1,10,:))
hlfM{5}=squeeze(ResMS.hlfVal(1,11,:))
hlfM{6}=squeeze(ResMS.hlfVal(1,12,:))
hlfM{7}=squeeze(ResMS.hlfVal(1,17,:))
hlfM{8}=squeeze(ResMS.hlfVal(1,18,:))
wfM{1}=1-squeeze(ResMS.wfVal(1,1,:))
wfM{2}=1-squeeze(ResMS.wfVal(1,2,:))
wfM{3}=1-squeeze(ResMS.wfVal(1,9,:))
wfM{4}=1-squeeze(ResMS.wfVal(1,10,:))
wfM{5}=1-squeeze(ResMS.wfVal(1,11,:))
wfM{6}=1-squeeze(ResMS.wfVal(1,12,:))
wfM{7}=1-squeeze(ResMS.wfVal(1,17,:))
wfM{8}=1-squeeze(ResMS.wfVal(1,18,:))

%hlf=wf
%number of subjects
n=length(fa)
%colors for plots
c=hsv(9)
c=vertcat(c(2,:),c(5,:),c(6,:),c(9,:))
%calculate summary stats and plot for left hemisphere
figure
for ii=1:2:n
    mHLF=mean(hlf{ii})
    mFA=mean(fa{ii})
    sdHLF=std(hlf{ii})
    sdFA=std(fa{ii})
    seHLF=sdHLF/sqrt(n)
    seFA=sdFA/sqrt(n)

    subplot(4,2,ii);plot(mHLF,'Color','k','LineWidth',5)
    ylabel('HLF','FontSize',12);title(fgNames{ii/2+.5},'FontSize',14)
    hold
    subplot(4,2,ii);plot(mHLF,'Color',c(ii/2+.5,:),'LineWidth',3)
    subplot(4,2,ii);plot(mHLF+2*seHLF,'Color',c(ii/2+.5,:),'LineWidth',3,'LineStyle',':')
    subplot(4,2,ii);plot(mHLF-2*seHLF,'Color',c(ii/2+.5,:),'LineWidth',3,'LineStyle',':')
    subplot(4,2,ii);plot(mHLF+2*seHLF,'Color','k')
    subplot(4,2,ii);plot(mHLF-2*seHLF,'Color','k')
    %for MS patient
    subplot(4,2,ii);plot(hlfM{ii},'Color','r','LineWidth',2,'LineStyle','--');
    set(gca,'Color',[.5 .5 .5])
    %plotFA
    subplot(4,2,ii+1);plot(mFA,'Color','k','LineWidth',5)
    ylabel('FA','FontSize',12);title(fgNames{ii/2+.5},'FontSize',14)
    hold
    subplot(4,2,ii+1);plot(mFA,'Color',c(ii/2+.5,:),'LineWidth',3)
    subplot(4,2,ii+1);plot(mFA+2*seFA,'Color','k')
    subplot(4,2,ii+1);plot(mFA-2*seFA,'Color','k')
    subplot(4,2,ii+1);plot(mFA+2*seFA,'Color',c(ii/2+.5,:),'LineWidth',3,'LineStyle',':')
    subplot(4,2,ii+1);plot(mFA-2*seFA,'Color',c(ii/2+.5,:),'LineWidth',3,'LineStyle',':')
    %for MS patient
    subplot(4,2,ii+1);plot(faM{ii},'Color','r','LineWidth',2,'LineStyle','--');
    set(gca,'Color',[.5 .5 .5])
end

%add righ hemi to plots
figure
for ii=2:2:n
    mHLF=mean(hlf{ii})
    mFA=mean(fa{ii})
    sdHLF=std(hlf{ii})
    sdFA=std(fa{ii})
    seHLF=sdHLF/sqrt(n)
    seFA=sdFA/sqrt(n)

    subplot(4,2,ii-1);plot(mHLF,'Color',[.8 .8 .8],'LineWidth',5)
    hold
    subplot(4,2,ii-1);plot(mHLF,'Color',c(ii/2,:),'LineWidth',3)
    subplot(4,2,ii-1);plot(mHLF+2*seHLF,'Color',[.8 .8 .8])
    subplot(4,2,ii-1);plot(mHLF-2*seHLF,'Color',[.8 .8 .8])
    subplot(4,2,ii-1);plot(mHLF+2*seHLF,'Color',c(ii/2,:),'LineWidth',3,'LineStyle',':')
    subplot(4,2,ii-1);plot(mHLF-2*seHLF,'Color',c(ii/2,:),'LineWidth',3,'LineStyle',':')
    %for MS patient
    subplot(4,2,ii-1);plot(hlfM{ii},'Color','r','LineWidth',2, 'LineStyle','--');
    set(gca,'Color',[.5 .5 .5])
    %plotFA
    subplot(4,2,ii);plot(mFA,'Color',[.8 .8 .8],'LineWidth',5)
    hold
    subplot(4,2,ii);plot(mFA,'Color',c(ii/2,:),'LineWidth',3)
    subplot(4,2,ii);plot(mFA+2*seFA,'Color',[.8 .8 .8])
    subplot(4,2,ii);plot(mFA-2*seFA,'Color',[.8 .8 .8])
    subplot(4,2,ii);plot(mFA+2*seFA,'Color',c(ii/2,:),'LineWidth',3,'LineStyle',':')
    subplot(4,2,ii);plot(mFA-2*seFA,'Color',c(ii/2,:),'LineWidth',3,'LineStyle',':')
    %for MS patient
    subplot(4,2,ii);plot(faM{ii},'Color','r','LineWidth',2,'LineStyle','--');
    set(gca,'Color',[.5 .5 .5])
end