function acc = rd_mpLocalizerBehavAcc(behavData)
%
% condAcc = rd_mpLocalizerBehavAcc(behavData, plotFigs)
%
% compile and plot accuracy for each run of mpLocalizer task
%
% Rachel Denison
% 17 April 2012

plotFigs = 1;

conds = [1 2];
condNames = {'M','P'};

nRuns = length(behavData);

for iRun=1:nRuns
    condAcc(iRun,:) = behavData(iRun).task.condAcc;
end
overallAcc = mean(condAcc(:,conds),2);
meanCondAcc = mean(condAcc,1);
meanOverallAcc = mean(overallAcc,1);

acc.condAcc = condAcc;
acc.overallAcc = overallAcc;
acc.meanCondAcc = meanCondAcc;
acc.meanOverallAcc = meanOverallAcc;

if plotFigs
    % acc across runs
    figure 
    hold on
    p1 = plot(overallAcc,'Color',[.8 .8 .8],'LineWidth',1.5);
    set(get(get(p1,'Annotation'),'LegendInformation'),...
        'IconDisplayStyle','off'); % Exclude line from legend

    p2 = plot(condAcc(:,conds),'.-','MarkerSize',10);
    set(p2(1),'Color','r');
    set(p2(2),'Color','b');
    plot([0 nRuns],[.5 .5],'--k')
    ylim([0 1.1])
    xlabel('run')
    ylabel('accuracy')
    title(behavData(1).subjectID)
    legend(condNames, 'Location', 'Best');
    
    % mean cond acc
    figure
    bar(meanCondAcc(conds));
    ylim([0 1])
    set(gca,'XTickLabel',condNames)
    ylabel('accuracy')
    title(behavData(1).subjectID)
end

