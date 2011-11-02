function [mean_erp,std_erp] = ecogPlotERP(par,elecs,block,condition,bef_win,aft_win,hflag)
%
%   [mean_erp,std_erp] = ecogPlotERP(par,elecs,block,condition,bef_win,aft_win,hflag)
%
% Function to plot ERPs
%
% added mean_erp and std_erp as outputs for other processing

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

bef_point= floor(bef_win * par.ieegrate);
aft_point= ceil(aft_win * par.ieegrate);
Npoints= bef_point + aft_point+1;


fn= sprintf(['%s' filesep '..' filesep block],par.Results); %hacky

load(sprintf('%s/ERP_%s_%s_%s_%s.mat',fn,par.exptname,condition,windurstr,block)); % Zscore
mean_erp = ERP.elecs(elecs).mean;
std_erp = ERP.elecs(elecs).std;
n_erp = ERP.elecs(elecs).n;


gcf;
if hflag
    hold on
%     numLines = 1+length(get(gca,'Children'))/3;
    lineColor = 'r'; %so hacky it hurts
else
    hold off
    lineColor = 'b';
end


plot(mean_erp+std_erp/sqrt(n_erp),['--' lineColor],'LineWidth',1)
hold on,plot(mean_erp,lineColor,'LineWidth',2),
hold on,plot(mean_erp-std_erp/sqrt(n_erp),['--' lineColor],'LineWidth',1)
set(gca,'XTick', linspace(bef_point,Npoints,5))
set(gca,'XTickLabel',{'0', num2str(aft_win/4), num2str(aft_win/2), num2str(3*aft_win/4) num2str(aft_win)})
set(gca,'FontSize',14)
xlabel('Time (sec)','FontSize',14);
ylabel('Voltage (AU)','FontSize',14);
set(gca,'Position',[0.1 0.2 0.8 0.7]);
axis tight
title(sprintf('%s %s chan %.3d',condition,block,elecs),'FontSize',18);