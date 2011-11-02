subs={'ak1_5' 'am1_5' 'rfd1_5'  'ah1_5' 'nl1_5' 'ns1_5' 'rb1_5' 'sc1_5'  'as1_5' 'mbs1_5' };% 'ak1202_1_5' 'ak0114_1_5'};
dtDirs={'/biac3/wandell4/data/reading_longitude/dti_adults/ak090724/dti40trilin' ...
    '/biac3/wandell4/data/reading_longitude/dti_adults/am090121/dti06trilinrt' ...
    '/biac3/wandell4/data/reading_longitude/dti_adults/rfd080930/dti40' ...
     '/biac3/wandell4/data/reading_longitude/dti_adults/ah080521_sense/dti40_asset' ...
    '/biac3/wandell4/data/reading_longitude/dti_adults/nl071207/dti30' ...
    '/biac3/wandell4/data/reading_longitude/dti_adults/ns090526/dti40'...
    '/biac3/wandell4/data/reading_longitude/dti_adults/rb080930/dti40' ...
    '/biac3/wandell4/data/reading_longitude/dti_adults/sc060523/dti06trilin'...
    '/biac3/wandell4/data/reading_longitude/dti_adults/as050307/dti06trilinrt' ...
    '/biac3/wandell4/data/reading_longitude/dti_adults/mbs040503/dti06trilinrt'};



%dtDirs = {'/biac3/wandell4/data/reading_longitude/dti_adults/am090121/dti06trilinrt/'};

%loop over subjects
for ii=1:length(subs)
    %load HLF maps DTI data and fiber groups
    HLFpath=['/biac3/wandell5/data/relaxometry/100405HLF3T/anal/' subs{ii} 'lin_2mms/HLF.nii.gz'];
    hlf=readFileNifti(HLFpath);
    dt=dtiLoadDt6([dtDirs{ii} '/dt6.mat']);
    fg=dtiReadFibers([dtDirs{ii} '/fibers/MoriGroupsall.mat']);
    %loop over fiber groups
    fprintf('\n\nLoaded data for subject # %d: %s\nCalculating stats for fiber group:',ii,subs{ii});
    for kk=1:length(fg)
        fprintf(' %d',kk)
        %Get FA MD RD AD values from fiber group kk
        [eigVal, negEig, eigVec] = dtiGetAllEigValsFromFibers(dt, fg(kk));
        [fa,md,rd,ad] = dtiComputeFA(eigVal);
        notNan = ~isnan(fa);
        fa = fa(notNan); md = md(notNan); rd = rd(notNan); ad = ad(notNan);
        %take means of fa md rd ad
        faVals(ii,kk)=mean(fa); mdVals(ii,kk)=mean(md); rdVals(ii,kk)=mean(rd);adVals(ii,kk)=mean(ad);
        %next get HLF values from fiber group kk
        hlfVals(ii,kk)=mean(dtiGetValFromImage(hlf.data, horzcat(fg(kk).fibers{:}),hlf.qto_ijk));
    end
end
%% Make plots
%fiber group names as the are ordered by findMoriGroups.m
% fgNames={' L ATR' 'R ATR' 'L CST' 'R CST' 'L Cingulum(C)' 'R Cingulum(C)' ...
%     'L Cingulum(H)' 'R Cingulum(H)' 'F Maj' 'F Min' 'L IFOF' 'RIFOF' 'L ILF'...
%     'R ILF' 'L SLF' 'R SLF' 'L UF' 'R UF' 'L AF' 'R AF'};
%fiber group names re-ordered for plotting purposes
fgNames={'Thalmic Rad' 'R ATR' 'Cort Spin' 'R CST' 'Cingulum(C)' 'R Cingulum(C)' ...
    'Cingulum(H)' 'R Cingulum(H)' 'Inf Front Occ' 'RIFOF' 'Inf Long'...
    'R ILF' 'Sup Long' 'R SLF' 'Uncinate' 'R UF' 'Arcuate' 'R AF' 'Forc Maj' 'Forc Min'};
%rearange values so forceps major and forcepts minor are last
hlfVals2=horzcat(hlfVals(:,1:8),hlfVals(:,11:20),hlfVals(:,9:10));
faVals2=horzcat(faVals(:,1:8),faVals(:,11:20),faVals(:,9:10));
%define colors
c=vertcat(hsv(9),[.75 .75 .75]);
%calculate corr coeficients and add to plot
rBetween=corr(mean(faVals)',mean(hlfVals)');
for ii=1:20   
rWithin(ii)=corr(faVals2(:,ii),hlfVals2(:,ii));
end
for ii=1:10
    rWithin2(ii)=corr(vertcat(faVals2(:,2*ii),faVals2(:,2*ii-1)),vertcat(hlfVals2(:,2*ii),hlfVals2(:,2*ii-1)));
end
%make plots
figure
hold
for p=1:2:18
    plot(faVals2(:,p),hlfVals2(:,p),'k<','MarkerSize',8,'MarkerFaceColor',c(p/2+.5,:))
    eVec = covEllipsoid(horzcat(faVals2(:,p),hlfVals2(:,p)),1)
    plot(eVec(:,1),eVec(:,2),':','Color',c(p/2+.5,:),'LineWidth',3)
    text(.56,.07+p*.001,fgNames{p},'Color',c(p/2+.5,:),'FontSize',12)
end
for p=2:2:18
    plot(faVals2(:,p),hlfVals2(:,p),'k>','MarkerSize',8,'MarkerFaceColor',c(p/2,:))
    eVec = covEllipsoid(horzcat(faVals2(:,p),hlfVals2(:,p)),1)
    plot(eVec(:,1),eVec(:,2),':','Color',c(p/2,:),'LineWidth',3)
end
%plot callosal groups as squares since there is not a right and left
%forcepts major
plot(faVals2(:,19),hlfVals2(:,19),'ks','MarkerSize',8,'MarkerFaceColor',[.25 .25 .25])
eVec = covEllipsoid(horzcat(faVals2(:,19),hlfVals2(:,19)),1)
plot(eVec(:,1),eVec(:,2),':','Color',[.25 .25 .25],'LineWidth',3)
text(.56,.07+19*.001,fgNames{19},'Color',[.25 .25 .25],'FontSize',12)
text(.63,.07+19*.001,num2str(rWithin(19),2),'Color',[.25 .25 .25],'FontSize',12)
%forcepts minor
plot(faVals2(:,20),hlfVals2(:,20),'ks','MarkerSize',8,'MarkerFaceColor',[.75 .75 .75])
eVec = covEllipsoid(horzcat(faVals2(:,20),hlfVals2(:,20)),1)
plot(eVec(:,1),eVec(:,2),':','Color',[.75 .75 .75],'LineWidth',3)
text(.56,.07+21*.001,fgNames{20},'Color',[.75 .75 .75],'FontSize',12)
text(.63,.07+21*.001,num2str(rWithin(20),2),'Color',[.75 .75 .75],'FontSize',12)
%add corelation coefs
for p=1:9
 text(.63,.069+p*.002,num2str(rWithin2(p),2) ,'Color',c(p,:),'FontSize',12)
end
%Add titles
text(.56,.093,'Fiber Group   |   r within','Color','k','FontSize',14)
text(.47,0.118,['Between Group Correlation: r = ' num2str(rBetween,3)],'Color','k','FontSize',18)
 %edit visual properties of graph
axis([0.3, 0.65, 0.07, 0.12]); xlabel('Mean FA','fontSize',18),ylabel('Mean HLF','fontSize',18)
set(gca,'Color',[.5 .5 .5], 'FontSize',12,'FontName','Times')
