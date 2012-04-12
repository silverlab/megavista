% rd_SNRWithinSubjectComparison.m

%% load data
data3T = load('groupFStat_3T_N5_20120217.mat');
data7T = load('groupFStat_7T_N4_20120217.mat');

subjectIdx3T = 1;
subjectIdx7T = 2;

%% check that we have the right subject/session
fprintf('\n3T session: %s\n', data3T.subjectDirs3T{subjectIdx3T,1})
fprintf('7T session: %s\n\n', data7T.subjectDirs{subjectIdx7T,1})

%% get f stats
fOverall{1} = squeeze(data3T.fOverallMean(subjectIdx3T,:,:)); % [delay x hemi]
fOverall{2} = squeeze(data7T.fOverallMean(subjectIdx7T,:,:));

fCond{1} = squeeze(data3T.fCondMean(:,:,subjectIdx3T,:));  % [delay x cond x hemi]
fCond{2} = squeeze(data7T.fCondMean(:,:,subjectIdx7T,:));

%% plot figures
ylims = [0 70];

f(1) = figure('Position',[0 0 1300 400]);
subplot(1,3,1)
bar([fOverall{1} fOverall{2}])
xlabel('delay (TR)')
ylabel('F statistic')
title(sprintf('subject %d/%d, overall', subjectIdx3T, subjectIdx7T))
% legend('3T left','3T right', '7T left','7T right')
% ylim(ylims)

subplot(1,3,2)
bar([squeeze(fCond{1}(:,1,:)) squeeze(fCond{2}(:,1,:))])
xlabel('delay (TR)')
ylabel('F statistic')
title(sprintf('subject %d/%d, M-stim', subjectIdx3T, subjectIdx7T))
% legend('3T left','3T right', '7T left','7T right')
% ylim(ylims)

subplot(1,3,3)
bar([squeeze(fCond{1}(:,2,:)) squeeze(fCond{2}(:,2,:))])
xlabel('delay (TR)')
ylabel('F statistic')
title(sprintf('subject %d/%d, P-stim', subjectIdx3T, subjectIdx7T))
legend('3T left','3T right', '7T left','7T right')
% ylim(ylims)

%% save figures
print(f(1),'-dpng',...
    sprintf('figures/%s_fStat3T7TComparison',data7T.subjectDirs{subjectIdx7T,1}(1:2)))

