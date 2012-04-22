function acc = rd_mpLocalizerBehavAcc(behavData)
%
% condAcc = rd_mpLocalizerBehavAcc(behavData, plotFigs)
%
% compile and plot accuracy for each run of mpLocalizer task
%
% Rachel Denison
% 17 April 2012

plotFigs = 1;
saveData = 1;
saveFigs = 1;

conds = [1 2];
condNames = {'M','P'};

nRuns = length(behavData);

for iRun=1:nRuns
    runs(iRun,1) = behavData(iRun).run;
    condAcc(iRun,:) = behavData(iRun).task.condAcc;
end
overallAcc = mean(condAcc(:,conds),2);
meanCondAcc = mean(condAcc,1);
meanOverallAcc = mean(overallAcc,1);

acc.subjectID = behavData(1).subjectID;
acc.studyDateTime = behavData(1).p.Gen.whenSaved;
acc.runs = runs;
acc.condAcc = condAcc;
acc.overallAcc = overallAcc;
acc.meanCondAcc = meanCondAcc;
acc.meanOverallAcc = meanOverallAcc;

if plotFigs
    figTitle = sprintf('%s, %s, runs %s', ...
        acc.subjectID, acc.studyDateTime(1:11), num2str(acc.runs'));
    
    % acc across runs
    f1 = figure; 
    hold on
    p1 = plot(overallAcc,'Color',[.8 .8 .8],'LineWidth',1.5);
    set(get(get(p1,'Annotation'),'LegendInformation'),...
        'IconDisplayStyle','off'); % Exclude line from legend

    p2 = plot(condAcc(:,conds),'.-','MarkerSize',10);
    set(p2(1),'Color','r');
    set(p2(2),'Color','b');
    plot([0 nRuns],[.25 .25],'--k')
    ylim([0 1.1])
    xlabel('run')
    ylabel('accuracy')
    title(figTitle)
    legend(condNames, 'Location', 'Best');
    
    % mean cond acc
    f2 = figure;
    bar(meanCondAcc(conds));
    set(gca,'XTickLabel',condNames)
    ylim([0 1])
    ylabel('accuracy')
    title(figTitle)
end

if saveData
    save('behavAcc.mat','acc')
end

if saveFigs
    print(f1, '-djpeg', 'behavAccEachRun')
    print(f2, '-djpeg', 'behavMeanCondAcc')
end

