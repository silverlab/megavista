%
% Before you can run this script, you need to run:
%   dtiCallosalSegmentation.m
% and
%   dtiSummarizeCallosumLongitudinal.m
%


%load /biac3/wandell4/data/reading_longitude/callosal_analysis/ccLongitudinal_081016_sum.mat
load /biac3/wandell4/data/reading_longitude/callosal_analysis/ccLongitudinal_090722_sum.mat
outDirName = 'longitude_090722';
outDir = fullfile(baseDir,outDirName);
mkdir(outDir);

%% Assign a unique segment to each ccRoi point
%
for(ii=1:nBrains)
    % What if there are multiple maxima? The following will take the first.
    % This is actually quite rare for our data, so doing something more
    % intelligent isn't necessary.
    [junk,ccSegAssignment{ii}] = max(vertcat(ccYZDensity{ii,:}));
    ccSegAssignment{ii}(junk==0) = 0;
end

disp('Building segment montage...');
[junk,subInd] = sortrows({datSum.subCode}');
figNum = 91;
if(figs)
    % Make a legend
    legImg = ones(143,16,3);
    segNamesLong = {'Occipital','Temporal','Posterior Parietal','Superior Parietal','Superior Frontal','Anterior Frontal','Orbital Frontal','Indeterminate'};
    for(ii=1:nSegs)
        for(jj=1:3)
            yPos = (ii-1)*18+1;
            legImg(yPos:yPos+16,:,jj) = barColor(ii,jj);
        end
    end
    figure(figNum); image(legImg); axis equal off tight;
    mrUtilResizeFigure(figNum, 128, 170);
    set(gca,'units','pixels','position',[8 10 size(legImg,2) size(legImg,1)]);
    for(ii=1:nSegs)
        text(18,(ii-1)*18+9,segNamesLong{ii},'FontSize',10);
    end
    mrUtilPrintFigure(fullfile(outDir,'segLegend'),figNum);
    pause(1);clf;

    ccBounds = [min(vertcat(ccYZCoords{:,:})); max(vertcat(ccYZCoords{:,:}))];

    ccBox = diff(ccBounds)+3; %+7?
    ccOffset = -ccBounds(1,:)+[2 2];
    r = 18;
    c = ceil(nBrains/r);
    ccImg = zeros([ccBox nBrains 3]);
    for(ii=1:nBrains)
        tmp = {ones(ccBox), ones(ccBox), ones(ccBox)};
        % Assign the un-assigned points (use the same color as the scaps)
        goodPts = ccSegAssignment{subInd(ii)}==0;
        x = ccYZCoords{subInd(ii)}(goodPts,1)+ccOffset(1);
        y = ccYZCoords{subInd(ii)}(goodPts,2)+ccOffset(2);
        for(kk=1:3)
            tmp{kk}(sub2ind(ccBox,x,y)) = barColor(nSegs,kk);
        end
        for(jj=nSegs:-1:1)
            goodPts = ccSegAssignment{subInd(ii)}==jj;
            x = ccYZCoords{subInd(ii)}(goodPts,1)+ccOffset(1);
            y = ccYZCoords{subInd(ii)}(goodPts,2)+ccOffset(2);
            for(kk=1:3)
                tmp{kk}(sub2ind(ccBox,x,y)) = barColor(jj,kk);
            end
        end
        for(kk=1:3) ccImg(:,:,ii,kk) = tmp{kk}; end
        % plot the anterior commissure (at ccOffset) for anatomical reference
        ccImg(ccOffset(1),ccOffset(2),ii,:) = [0 0 0];
        [junk,label{ii}] = fileparts(fileparts(datSum(subInd(ii)).datDir));
    end
    ccImg = flipdim(flipdim(permute(ccImg,[2 1 3 4]),1),2);
    ccMontage = makeMontage3(ccImg,[],1,0,label,c,figNum,[1 1 1]);
    imwrite(ccMontage, fullfile(outDir,'ccSegAll.png'));
    ccMontage = imresize(ccMontage,2,'nearest');
    image(ccMontage);axis image; truesize;
    imwrite(ccMontage, fullfile(outDir,'ccSeqAll_2x.png'));
    pause(1); clf;
end


%
% COMPUTE SEGMENT AREA
%
for(ii=1:nBrains)
    totalCcArea(ii) = size(ccYZCoords{ii},1);
    for(jj=1:nSegs)
        for(hs=1:3)
            segArea(ii,jj,hs) = sum(ccSegAssignment{ii}==jj);
            relSegArea(ii,jj,hs) = segArea(ii,jj)./totalCcArea(ii);
        end
    end
end

%excludeSubs = [93 41];
excludeSubs = [];
for(ii=1:numel(datSum))
    subDir{ii} = fileparts(datSum(ii).datDir);
end
mnSegArea = mean(segArea,3);
goodSubs = all(mnSegArea>0,2);
goodSubs(excludeSubs) = 0;
yr = [datSum.year]';
corrcoef([yr(goodSubs) mnSegArea(goodSubs,:)])
subs = unique({datSum.subCode});
nSubs = length(subs);

bd = dtiGetBehavioralDataStruct(subDir,'/biac3/wandell4/data/reading_longitude/read_behav_measures_longitude.csv');

allAge = [bd.DTI_Age];
allPa = [bd.Phonological_Awareness];

% Write some values to a CSV file
fid = fopen(fullfile(outDir,'sum.csv'),'wt');
fprintf(fid,'Sub\tYr\tAge');
vars = {'mnFa','mnMd','mnRd','mnAd'};
for(ii=1:numel(vars)), for(jj=1:nSegs-1), fprintf(fid,'\t%s_%s',segNames{jj},vars{ii}); end; end;
fprintf(fid,'\n');
for(ii=1:numel(datSum))
    fprintf(fid,'%s\t%d\t%2.2f', bd(ii).sc, bd(ii).year, bd(ii).DTI_Age);
    for(jj=1:numel(vars))
        for(kk=1:nSegs-1)
            eval(['y = ' vars{jj} '(ii,kk);']);
            fprintf(fid,'\t%0.3f',y);
            %g = find(~isnan(x) & y>0 & goodSubs(curInds)');
        end
    end
    fprintf(fid,'\n');
end
fclose(fid);

colors = 'bgrcmyk';
figure(10); clf;
n = 0; clear slp int age seg;
for(jj=1:nSegs)
    for(ii=1:nSubs)
        curInds = strmatch(subs{ii},{bd.sc},'exact');
        x = [bd(curInds).DTI_Age];
        %y = mnSegArea(curInds,jj)';
        y = mnFa(curInds,jj)';
        %y = mnEigVals(curInds,jj,1);
        %y = mean(mnEigVals(curInds,jj,2:3),4)';
        g = find(~isnan(x) & y>0 & goodSubs(curInds)');
        tmp = [NaN NaN];
        if(length(g)>1)
            %for(kk=2:length(g))
            %inds = [g(kk-1):g(kk)];
            inds = g;
            tmp = polyfit(x(inds),y(inds),1);
            if(all(isfinite(tmp))&&abs(tmp(1))<=10)
                subplot(3,3,jj); hold on; plot(x(g),y(g),colors(mod(ii-1,length(colors))+1)); hold off;
                n = n+1;
                slp(n) = tmp(1);
                int(n) = tmp(2);
                age(n) = mean(x(inds));
                seg(n) = jj;
            else
                fprintf('bad slope for %d (%s).\n',ii,subs{ii});
            end
            %end
        end
    end
end
% Simple non-parametric sign test:
%sgn = nansum(sign(slp)>0);
%n = sum(~isnan(slp));
for(jj=1:nSegs)
    curInds = seg==jj;
    sgn = nansum(sign(slp(curInds))>0);
    n = sum(seg==jj);
    sgnTest(jj) = binocdf(sgn,n+1,.5);
    mnSlp(jj) = nanmean(slp(curInds));
    mnInt(jj) = nanmean(int(curInds));
end
for(ii=1:nSegs)
    fprintf('% 9s:\tp(-slope)=%0.2f\tp(+slope)=%0.2f\n',segNames{ii},-log10(sgnTest(ii)),-log10(1-sgnTest(ii)));
end


figure(11); clf;
n = 0; clear slp int age seg;
for(jj=1:nSegs)
    for(ii=1:nSubs)
        curInds = strmatch(subs{ii},{bd.sc},'exact');
        x = [bd(curInds).Phonological_Awareness];
        %y = mnSegArea(curInds,jj)';
        y = mnFa(curInds,jj)';
        %y = mnEigVals(curInds,jj,1);
        %y = mean(mnEigVals(curInds,jj,2:3),4)';
        g = find(~isnan(x) & y>0 & goodSubs(curInds)');
        tmp = [NaN NaN];
        if(length(g)>1)
            inds = g;
            tmp = polyfit(x(inds),y(inds),1);
            if(all(isfinite(tmp))&&abs(tmp(1))<=10)
                subplot(3,3,jj); hold on; plot(x(g),y(g),['.' colors(mod(ii-1,length(colors))+1)]); hold off;
                n = n+1;
                slp(n) = tmp(1);
                int(n) = tmp(2);
                age(n) = mean(x(inds));
                seg(n) = jj;
            else
                fprintf('bad slope for %d (%s).\n',ii,subs{ii});
            end
            %end
        end
    end
end

figure(12); clf;
curInds = find([bd.year]==1);
x = [bd(curInds).Phonological_Awareness];
for(jj=1:nSegs)
    y = mnFa(curInds,jj)';
    g = find(~isnan(x) & y>0 & goodSubs(curInds)');
    [r,p] = corrcoef(x(g),y(g)); r = r(2); p = p(2);
    subplot(3,3,jj); plot(x(g),y(g),'.k');
    title(sprintf('r=%0.3f, p=%0.4f',r,p));
end
    


for(ii=1:nSegs)
    fprintf('% 9s:\tp(-slope)=%0.2f\tp(+slope)=%0.2f\n',segNames{ii},-log10(sgnTest(ii)),-log10(1-sgnTest(ii)));
end


error('Stop here');

for(jj=1:nSegs)
    for(ii=1:nSubs)
        curInds = strmatch(subs{ii},{datSum.subCode});
        tmp = [mnMd(curInds,jj)' NaN NaN NaN NaN];
        allMd(ii,jj,:) = tmp(1:4);
        tmp = [mnFa(curInds,jj)' NaN NaN NaN NaN];
        allFa(ii,jj,:) = tmp(1:4);
        %tmp = [mnEigVals(curInds,jj,1)' NaN NaN NaN NaN];
        %allAd(ii,jj,:) = tmp(1:4);
        %tmp = [mean(mnEigVals(curInds,jj,3,2:3),4)' NaN NaN NaN NaN];
        %allRd(ii,jj,:) = tmp(1:4);
    end
end

clear r p;
for(jj=1:nSegs)
    for(yy=1:4)
        x = allAge(:,yy);
        y = allMd(:,jj,yy);
        gv = ~isnan(y)&~isnan(x);
        [tmpr,tmpp] = corrcoef(x(gv),y(gv));
        r(jj,yy) = tmpr(2,1);
        p(jj,yy) = tmpp(2,1);
    end
end
clear r p;
for(jj=1:nSegs)
    x = allAge(:);
    y = allMd(:,jj,:);
    y = y(:);
    gv = ~isnan(y)&~isnan(x);
    [tmpr,tmpp] = corrcoef(x(gv),y(gv));
    r(jj) = tmpr(2,1);
    p(jj) = tmpp(2,1);
end

clear r p n;
for(jj=1:nSegs)
    for(yy=1:4)
        x = allPa(:,yy);
        y = allFa(:,jj,yy);
        gv = ~isnan(y)&~isnan(x);
        [tmpr,tmpp] = corrcoef(x(gv),y(gv));
        r(jj,yy) = tmpr(2,1);
        p(jj,yy) = tmpp(2,1);
        n(jj,yy) = sum(gv);
    end
end

clear r p;
for(jj=1:nSegs)
    x = allPa(:);
    y = allFa(:,jj,:);
    y = y(:);
    gv = ~isnan(y)&~isnan(x);
    [tmpr,tmpp] = corrcoef(x(gv),y(gv));
    r(jj) = tmpr(2,1);
    p(jj) = tmpp(2,1);
end

figure(67);
for(yy=1:4)
    subplot(4,1,yy);
    md=fiberMd{curInds(yy),1,1};
    nanmean(md(:))
    hist(md(:),100);
end

% Check whole-brain MD and FA
clear fa md;
fa = zeros(nBrains,2);
md = zeros(nBrains,2);
for(ii=1:nBrains)
    fprintf('Processing %d of %d (%s)...\n',ii,nBrains,datSum(ii).subCode);
    dt = dtiLoadDt6(datSum(ii).fileName);
    [tmpfa,tmpmd] = dtiComputeFA(dt.dt6);
    gv = tmpfa(:)>0;
    fa(ii,:) = [mean(tmpfa(gv)) median(tmpfa(gv))];
    md(ii,:) = [mean(tmpmd(gv)) median(tmpmd(gv))];
end
clear gv dt eigVec eigVal tmpfa tmpmd;

for(ii=1:nSubs)
    curInds = strmatch(subs{ii},{datSum.subCode});
    tmp = [md(curInds)' NaN NaN NaN NaN];
    wbMd(ii,:) = tmp(1:4);
    tmp = [fa(curInds)' NaN NaN NaN NaN];
    wbFa(ii,:) = tmp(1:4);
end
gv = ~isnan(wbMd(:,1)) & ~isnan(wbMd(:,2)) & wbMd(:,1)>.5;
figure;
plot(allAge(gv),wbMd(gv,1),'.');



[p,t,df] = statTest(totalCcArea(y1),totalCcArea(y2),'p');
fprintf(logFile, '\nTotal CC area:  %s (%0.0f mm^2) vs. %s (%0.0f mm^2): t=%0.2f (p=%0.6f, df=%d)\n', ...
    groups{1}, mean(totalCcArea(y1)), groups{2}, mean(totalCcArea(y2)),...
    t, p, df);

for(jj=1:nSegs)
    [p,t,df] = statTest(segArea(y1,jj,3),segArea(y2,jj,3),'p');
    fprintf(logFile, '%s CC area:  %s (%0.0f mm^2) vs. %s (%0.0f mm^2): t=%0.2f (p=%0.6f, df=%d)\n', ...
        segNames{jj}, groups{1}, mean(segArea(y1,jj,3)), groups{2}, mean(segArea(y2,jj,3)),...
        t, p, df);
    tArea(jj) = t;
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; elseif(p<=0.1) s='  +'; else s='   '; end
    sArea{jj} = s;
end
for(jj=1:nSegs)
    [p,t,df] = statTest(relSegArea(y1,jj,3),relSegArea(y2,jj,3),'t');
    fprintf(logFile, '%s relative CC area:  %s (%0.2f) vs. %s (%0.2f): t=%0.2f (p=%0.6f, df=%d)\n', ...
        segNames{jj}, groups{1}, mean(relSegArea(y1,jj,3)), groups{2}, mean(relSegArea(y2,jj,3)),...
        t, p, df);
    tRelArea(jj) = t;
    if(p<=0.001) s='***'; elseif(p<=0.01) s=' **'; elseif(p<=0.05) s='  *'; else s='   '; end
    sRelArea{jj} = s;
end
fclose(logFile);

%
% CREATE MEAN SUMMARY TABLE
%
% Create comma delimited text file with callosal data
%
fid = fopen(fullfile(outDir,'MeanSummary.csv'), 'wt');
fprintf(fid,'Subject,Segment,FA_Y2,FA_Y1,MD_Y1,MD_Y2,SegArea_Y1,SegArea_Y2\n');
for(ii=1:nSubs)
    for(jj=1:nSegs)
        fprintf(fid,'%d,%s,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f,%0.4f\n',ii,segNames{jj},mnFa(y1Ind(ii),jj,3),...
            mnFa(y2Ind(ii),jj,3),mnMd(y1Ind(ii),jj,3),mnMd(y2Ind(ii),jj,3),segArea(y1Ind(ii),jj,3),segArea(y2Ind(ii),jj,3));
    end
end
fclose(fid);

% % Run two-sample t-tests between year1 and year2 for each
% segment for FA, MD, seg area, and longitudinal and radial diffusivity
logFile = fopen(fullfile(outDir,'log.txt'),'at');
fprintf(logFile, '\n* * * year1 vs. year2 paired t-tests * * *\n');
fprintf(logFile,'FA:\n');
for(ii=[1:7])
    [p,t,df]=statTest(mnFa(y1Ind,ii,3),mnFa(y2Ind,ii,3),'p');
    if(p<=0.001) sFa{ii}='***'; elseif(p<=0.01) sFa{ii}=' **'; elseif(p<=0.05) sFa{ii}='  *'; else sFa{ii}='   '; end
    fprintf(logFile,'%s Y1 %s (%0.3f) vs. Y2 %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
        sFa{ii},segNames{ii},mean(mnFa(y1Ind,ii,3)),segNames{ii},mean(mnFa(y2Ind,ii,3)),t,p,df);
    tFa(ii)=t;
end

fprintf(logFile,'Mean Diffusivity:\n');
for(ii=[1:7])
    [p,t,df]=statTest(mnMd(y1Ind,ii,3),mnMd(y2Ind,ii,3),'t');
    if(p<=0.001) sMd{ii}='***'; elseif(p<=0.01) sMd{ii}=' **'; elseif(p<=0.05) sMd{ii}='  *'; else sMd{ii}='   '; end
    fprintf(logFile,'%s Y1 %s (%0.3f) vs. Y2 %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
        sMd{ii},segNames{ii},mean(mnMd(y1Ind,ii,3)),segNames{ii},mean(mnMd(y2Ind,ii,3)),t,p,df);
    tMd(ii)=t;
end

fprintf(logFile,'Segment Area:\n');
for(ii=[1:7])
    [p,t,df]=statTest(segArea(y1Ind,ii,3),segArea(y2Ind,ii,3),'t');
    if(p<=0.001) sSA{ii}='***'; elseif(p<=0.01) sSA{ii}=' **'; elseif(p<=0.05) sSA{ii}='  *'; else sSA{ii}='   '; end
    fprintf(logFile,'%s Y1 %s (%0.3f) vs. Y2 %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
        sSA{ii},segNames{ii},mean(segArea(y1Ind,ii,3)),segNames{ii},mean(segArea(y2Ind,ii,3)),t,p,df);
    tSA(ii)=t;
end

fprintf(logFile,'Longitudinal diffusivity:\n');
for(ii=[1:7])
    y1Ld = (squeeze(mnEigVals(y1Ind,ii,3,1)));
    y2Ld = (squeeze(mnEigVals(y2Ind,ii,3,1)));
    [p,t,df]=statTest(y1Ld,y2Ld,'t');
    if(p<=0.001) sLd{ii}='***'; elseif(p<=0.01) sLd{ii}=' **'; elseif(p<=0.05) sLd{ii}='  *'; else sLd{ii}='   '; end
    fprintf(logFile,'%s Y1 %s (%0.3f) vs. Y2 %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
        sLd{ii},segNames{ii},mean(y1Ld),segNames{ii},mean(y2Ld),t,p,df);
    tLd(ii)=t;
end

fprintf(logFile,'Radial diffusivity:\n');
for(ii=[1:7])
    y1Rd = mean(squeeze(mnEigVals(y1Ind,ii,3,2:3)),2);
    y2Rd = mean(squeeze(mnEigVals(y2Ind,ii,3,2:3)),2);
    [p,t,df]=statTest(y1Rd,y2Rd,'t');
    if(p<=0.001) sRd{ii}='***'; elseif(p<=0.01) sRd{ii}=' **'; elseif(p<=0.05) sRd{ii}='  *'; else sRd{ii}='   '; end
    fprintf(logFile,'%s Y1 %s (%0.3f) vs. Y2 %s (%0.3f): t=%0.2f (p=%0.4f, df=%d)\n', ...
        sRd{ii}, segNames{ii},mean(y1Rd),segNames{ii},mean(y2Rd),t,p,df);
    tRd(ii)=t;
end

fclose(logFile);


if(figs)
    %% Create bar charts showing DTI values x callosal segment
    % Means and standard deviations are are displayed inside the bars.  Error
    % bars = 2sem.

    % % Create a clustered bar charts comparing year2 and year1 DTI values
    % The t statistic and significance are displayed above the bars.  Error
    % bars = 2sem

    % Graph Globals
    width = 1;

    %
    % Make FA graph here
    %
    year1 = mnFa(y1Ind,1:7,3);
    year2 = mnFa(y2Ind,1:7,3);
    meansYear1 = mean(year1);
    meansYear2 = mean(year2);
    sdYear1 = std(year1);
    sdYear2 = std(year2);
    semYear1 = sdYear1/sqrt(length(mnFa(y1Ind,1,1))-1);
    semYear2 = sdYear2/sqrt(length(mnFa(y2Ind,1,1))-1);
    for(ii=1:length(meansYear1))
        mnFaAll(ii,1) = meansYear1(ii);
        mnFaAll(ii,2) = meansYear2(ii);
    end
    fh = figure(figNum); clf; hold on;
    for(ii=[1:length(mnFaAll)])
        deltas(ii) = (meansYear2(ii)-meansYear1(ii));
        y = zeros(length(mnFaAll), 2);
        y(ii,:) = mnFaAll(ii,:);
        barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
        %text(ii,0.845,sprintf('%s%0.1f',sFa{ii},tFa(ii)),...
        %    'horizontalalignment','center','fontsize',12,'fontWeight','bold');
    end
    % Darken the second bar in each pair
    for(ii=1:length(barHandles))
        curColor = get(barHandles{ii}(2),'FaceColor');
        set(barHandles{ii}(2),'FaceColor',curColor.*0.5);
    end
    clear barHandles;
    errorbar([1:length(meansYear1)]-0.14,meansYear1,(2*semYear1),'k+','linewidth',2);
    errorbar([1:length(meansYear2)]+0.14,meansYear2,(2*semYear2),'k+','linewidth',2);
    hold off;
    set(gca,'box','on','xtick',[1:length(mnFaAll)],'xticklabel',tickLabels,...
        'linewidth',2,'fontsize',12);
    maxErr = max([semYear1 semYear2])*2;
    rng = [floor((min(mnFaAll(:))-maxErr)*20)/20 ceil((max(mnFaAll(:))+maxErr)*20)/20];
    rng = [0.5 0.8];
    set(gca,'ylim',rng,'ytick',[rng(1):.05:rng(2)],'YGrid','on')
    set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
    set(get(gca,'YLabel'),'String','FA','fontsize',14);
    mrUtilResizeFigure(fh, 650, 420);
    set(gca,'Position',[0.09 0.1 .9 .87]);
    mrUtilPrintFigure(fullfile(outDir,'FA_acrossSegs_devel.eps'),fh);

    %
    % Make MD graph here
    %
    year1 = mnMd(y1Ind,1:7,3);
    year2 = mnMd(y2Ind,1:7,3);
    meansYear1 = mean(year1);
    meansYear2 = mean(year2);
    sdYear1 = std(year1);
    sdYear2 = std(year2);
    semYear1 = sdYear1/sqrt(sum(y1Ind)-1);
    semYear2 = sdYear2/sqrt(sum(y2Ind)-1);
    for(ii=1:length(meansYear1))
        mnMdAll(ii,1) = meansYear1(ii);
        mnMdAll(ii,2) = meansYear2(ii);
    end

    fh = figure(figNum); clf; hold on;
    tmp = mnMd(:,1:7,3);
    mu = mean(tmp);
    sd = std(tmp);
    sem = sd/sqrt(length(mnMd(:,1,1))-1);
    for(ii=[1:length(mnMdAll)])
        deltas(ii) = (meansYear2(ii)-meansYear1(ii));
        y = zeros(length(mnMdAll), 2);
        y(ii,:) = mnMdAll(ii,:);
        barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
        %text(ii,1020,sprintf('%s%0.1f',sMd{ii},tMd(ii)),...
        %    'horizontalalignment','center','fontsize',12,'fontWeight','bold');
    end
    % Darken the second bar in each pair
    for(ii=1:length(barHandles))
        curColor = get(barHandles{ii}(2),'FaceColor');
        set(barHandles{ii}(2),'FaceColor',curColor.*0.5);
    end
    clear barHandles;
    errorbar([1:length(meansYear1)]-0.14,meansYear1,(2*semYear1),'k+','linewidth',2);
    errorbar([1:length(meansYear2)]+0.14,meansYear2,(2*semYear2),'k+','linewidth',2);
    hold off;
    maxErr = max([semYear1 semYear2])*2;
    rng = [floor((min(mnMdAll(:))-maxErr)*20)/20 ceil((max(mnMdAll(:))+maxErr)*20)/20];
    rng = [0.8 1.0];
    set(gca,'ylim',rng,'YGrid','on','ytick',[rng(1):0.05:rng(2)])
    set(gca,'box','on','xtick',[1:length(mu)],'xticklabel',tickLabels,...
        'linewidth',2,'fontsize',12)
    set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
    set(get(gca,'YLabel'),'String',['MD ' diffusivityUnitStr],'fontsize',14);
    mrUtilResizeFigure(fh, 650, 420);
    set(gca,'Position',[0.09 0.1 .9 .87]);
    mrUtilPrintFigure(fullfile(outDir,'MD_acrossSegs_devel.eps'),fh);

    %
    % Longitudinal diffusivity
    %
    year1 = (squeeze(mnEigVals(y1Ind,[1:7],3,1)));
    year2 = (squeeze(mnEigVals(y2Ind,[1:7],3,1)));
    meansYear1 = mean(year1);
    meansYear2 = mean(year2);
    sdYear1 = std(year1);
    sdYear2 = std(year2);
    semYear1 = sdYear1/sqrt(length(mnFa(y1Ind,1,1))-1);
    semYear2 = sdYear2/sqrt(length(mnFa(y2Ind,1,1))-1);
    for(ii=1:length(meansYear1))
        mnLdAll(ii,1) = meansYear1(ii);
        mnLdAll(ii,2) = meansYear2(ii);
    end
    fh = figure(figNum); clf; hold on;
    for(ii=[1:length(mnLdAll)])
        deltas(ii) = (meansYear2(ii)-meansYear1(ii));
        y = zeros(length(mnLdAll), 2);
        y(ii,:) = mnLdAll(ii,:);
        barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
    end
    % Darken the second bar in each pair
    for(ii=1:length(barHandles))
        curColor = get(barHandles{ii}(2),'FaceColor');
        set(barHandles{ii}(2),'FaceColor',curColor.*0.5);
    end
    clear barHandles;
    errorbar([1:length(meansYear1)]-0.14,meansYear1,(2*semYear1),'k+','linewidth',2);
    errorbar([1:length(meansYear2)]+0.14,meansYear2,(2*semYear2),'k+','linewidth',2);
    hold off;
    maxErr = max([semYear1 semYear2])*2;
    rng = [floor((min(mnLdAll(:))-maxErr)*20)/20 ceil((max(mnLdAll(:))+maxErr)*20)/20];
    set(gca,'ylim',rng,'YGrid','on','ytick',[rng(1):0.1:rng(2)])
    set(gca,'box','on','xtick',[1:7],'xticklabel',tickLabels,...
        'linewidth',2,'fontsize',12)
    set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
    set(get(gca,'YLabel'),'String',['Parallel ADC ' diffusivityUnitStr],'fontsize',14);
    mrUtilResizeFigure(fh, 650, 420);
    set(gca,'Position',[0.09 0.1 .9 .87]);
    mrUtilPrintFigure(fullfile(outDir,'LD_acrossSegs_devel.eps'),fh);

    %
    % Radial diffusivity
    %
    year1 = mean(mnEigVals(y1Ind,[1:7],3,2:3),4);
    year2 = mean(mnEigVals(y2Ind,[1:7],3,2:3),4);
    meansYear1 = mean(year1);
    meansYear2 = mean(year2);
    sdYear1 = std(year1);
    sdYear2 = std(year2);
    semYear1 = sdYear1/sqrt(length(mnFa(y1Ind,1,1))-1);
    semYear2 = sdYear2/sqrt(length(mnFa(y2Ind,1,1))-1);
    for(ii=1:length(meansYear1))
        mnRdAll(ii,1) = meansYear1(ii);
        mnRdAll(ii,2) = meansYear2(ii);
    end
    fh = figure(figNum); clf; hold on;
    for(ii=[1:length(mnRdAll)])
        deltas(ii) = (meansYear2(ii)-meansYear1(ii));
        y = zeros(length(mnRdAll), 2);
        y(ii,:) = mnRdAll(ii,:);
        barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
    end
    % Darken the second bar in each pair
    for(ii=1:length(barHandles))
        curColor = get(barHandles{ii}(2),'FaceColor');
        set(barHandles{ii}(2),'FaceColor',curColor.*0.5);
    end
    clear barHandles;
    errorbar([1:length(meansYear1)]-0.14,meansYear1,(2*semYear1),'k+','linewidth',2);
    errorbar([1:length(meansYear2)]+0.14,meansYear2,(2*semYear2),'k+','linewidth',2);
    hold off;
    maxErr = max([semYear1 semYear2])*2;
    rng = [floor((min(mnRdAll(:))-maxErr)*20)/20 ceil((max(mnRdAll(:))+maxErr)*20)/20];
    set(gca,'ylim',rng,'YGrid','on','ytick',[rng(1):0.05:rng(2)])
    set(gca,'box','on','xtick',[1:7],'xticklabel',tickLabels,...
        'linewidth',2,'fontsize',12)
    set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
    set(get(gca,'YLabel'),'String',['Radial ADC ' diffusivityUnitStr],'fontsize',14);
    mrUtilResizeFigure(fh, 650, 420);
    set(gca,'Position',[0.09 0.1 .9 .87]);
    mrUtilPrintFigure(fullfile(outDir,'RD_acrossSegs_devel.eps'),fh);
end

%
% MAKE AREA GRAPH
%
logFile = fopen(fullfile(outDir,'log.txt'),'at');
year1 = segArea(y1Ind,1:7,3);
year2 = segArea(y2Ind,1:7,3);
meansYear1 = mean(year1);
meansYear2 = mean(year2);
sdYear1 = std(year1);
sdYear2 = std(year2);
semYear1 = sdYear1/sqrt(sum(y1Ind)-1);
semYear2 = sdYear2/sqrt(sum(y2Ind)-1);
% Save segment stats in log file
for(jj=1:7)
    fprintf(logFile, '%s Area: year1 = %0.1f mm^2 (stdev=%0.2f, n=%d); year2 = %0.1f mm^2 (stdev=%0.2f, n=%d)\n', ...
        segNames{jj},meansYear1(jj),sdYear1(jj),size(year1,1),meansYear2(jj),sdYear2(jj),size(year2,1));
    fprintf('%s Area: year1 = %0.1f mm^2 (stdev=%0.2f, n=%d); year2 = %0.1f mm^2 (stdev=%0.2f, n=%d)\n', ...
        segNames{jj},meansYear1(jj),sdYear1(jj),size(year1,1),meansYear2(jj),sdYear2(jj),size(year2,1));
end

if(figs)
    for(ii=1:length(meansYear1))
        mnAreaAll(ii,1) = meansYear1(ii);
        mnAreaAll(ii,2) = meansYear2(ii);
    end
    fh = figure(figNum); clf; hold on;
    tmp = segArea(:,1:7,3);
    mu = mean(tmp);
    sd = std(tmp);
    sem = sd/sqrt(nSubs-1);
    for(ii=[1:length(mnAreaAll)])
        deltas(ii) = (meansYear2(ii)-meansYear1(ii));
        y = zeros(length(mnAreaAll), 2);
        y(ii,:) = mnAreaAll(ii,:);
        barHandles{ii} = bar(y,width,'group','FaceColor',barColor(ii,:),'linewidth',2);
        %text(ii,165,sprintf('%s%0.1f',sArea{ii},tArea(ii)),...
        %    'horizontalalignment','center','fontsize',12,'fontWeight','bold');
    end
    % Darken the second bar in each pair
    for(ii=1:length(barHandles))
        curColor = get(barHandles{ii}(2),'FaceColor');
        set(barHandles{ii}(2),'FaceColor',curColor.*0.5);
    end
    clear barHandles;
    errorbar([1:length(meansYear1)]-0.14,meansYear1,(2*semYear1),'k+','linewidth',2);
    errorbar([1:length(meansYear2)]+0.14,meansYear2,(2*semYear2),'k+','linewidth',2);
    hold off;
    set(gca,'ylim',[0 130],'ytick',[0 25 50 75 100 125],'YGrid','on')
    set(gca,'box','on','xtick',[1:length(mu)],'xticklabel',tickLabels,...
        'linewidth',2,'fontsize',12)
    set(get(gca,'XLabel'),'String','Callosal Segment','fontsize',14);
    set(get(gca,'YLabel'),'String','Area (mm^2)','fontsize',14);
    mrUtilResizeFigure(fh, 650, 420);
    set(gca,'Position',[0.09 0.1 .9 .87]);
    mrUtilPrintFigure(fullfile(outDir,'Area_acrossSegs_devel.eps'),fh);

    if(verbose)
        figure; plot(mnMd(:,:,3), mnFa(:,:,3), 'k.')
        for(ii=1:length(mu))
            figure; plot(mnMd(:,ii,3), mnFa(:,ii,3), 'k.')
            title({tickLabels{ii}},'fontsize',20,'fontWeight','bold');
        end
    end
end


fclose(logFile);

disp(['Run: cd ' outDir '; pstoimg -antialias -aaliastext -density 300 -type png -crop a *.eps']);
