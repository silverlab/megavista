% rd_plotGroupMeanIndivRunFStats.m

%% setup
load /Volumes/Plata1/LGN/Group_Analyses/fOverallMeans_3T_7T_N4_20120428.mat

delays = [0 1 2 3];

%% hemispheres separated
figure
hold on
p1(1) = errorbar(delays, mean(fOMeans31), std(fOMeans31)./2,'s-');
p1(2) = errorbar(delays, mean(fOMeans32), std(fOMeans32)./2,'^-');
p1(3) = errorbar(delays, mean(fOMeans71), std(fOMeans71)./2,'s-');
p1(4) = errorbar(delays, mean(fOMeans72), std(fOMeans72)./2,'^-');

colors = {'k','k','b','b'};
for i = 1:numel(p1)
    set(p1(i),'Color',colors{i},'MarkerFaceColor',colors{i});
end
set(gca,'XTick',delays)
xlabel('delay (TR)')
ylabel('F statistic')
title(sprintf('Group means and stes of individual run Fs\nfor each hemisphere and field strength'))

%% hemispheres collapsed
figure
hold on
p2(1) = errorbar(delays, mean([fOMeans31; fOMeans32]), ...
    std([fOMeans31; fOMeans32])./sqrt(8),'.-');
p2(2) = errorbar(delays, mean([fOMeans71; fOMeans72]), ...
    std([fOMeans71; fOMeans72])./sqrt(8),'.-');

colors = {'k','b'};
for i = 1:numel(p2)
    set(p2(i),'Color',colors{i},'MarkerFaceColor',colors{i});
end
set(gca,'XTick',delays)
ylim([0 7])
xlabel('delay (TR)')
ylabel('F statistic')
title(sprintf('Group means and stes of individual run Fs\nfor each hemisphere and field strength'))

