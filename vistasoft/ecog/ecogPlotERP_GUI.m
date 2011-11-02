function ecogPlotERP_GUI(par,bef_win,aft_win,condnames)

% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Last revision date SEP,2009
%
%   ecogPlotERP(par,bef_win,aft_win,elecs,tag,ERSPtype)
%
% modified j.chen jan 2010
% made into gui for PC att'n jbh feb 2010
% changed from ersp to erp jbh feb 2010

% Update path info based on par.basepath
if exist('par','var')
    par = ecogPathUpdate(par);
end

if nargin >= 1
    
    
    [gp.basepath bd] = fileparts(par.BehavData);
    gp.bef_win = bef_win;       %
    gp.aft_win = aft_win;       %bundling things in a struct for later
    gp.elecs = 1;               %
    gp.condnames = condnames;   %
    gp.par = par;
       
   
    gp.cbstate = 0; %set check box for hold on off
    
    [abrd currblock] = fileparts(par.Results); % hacky way of getting block dirs
    d = dir([abrd filesep currblock(1:2) '*']); % only look for dirs with same first two letters as current block
    gp.blocknames = {d.name};
    
    
    
    figure;
    
    gp.condmenu = uicontrol(gcf,'Style', 'popup',...
        'String', gp.condnames,...
        'Position', [10 10 100 25],...
        'Callback', 'ecogPlotERP_GUI');
    
    gp.holdbox = uicontrol(gcf,'Style','checkbox',...
        'Position', [150 10 25 25]);
    
    
    gp.elecmenu = uicontrol(gcf,'Style','edit',...
        'Position', [200 10 75 25],...
        'String',gp.elecs);
    gp.elecbutton = uicontrol(gcf,'Style', 'pushbutton',...
        'String', 'Set',...
        'Position', [300 10 75 25],...
        'Callback', 'ecogPlotERP_GUI');
    
    gp.blockmenu = uicontrol(gcf,'Style', 'popup',...
        'String', gp.blocknames,...
        'Position', [450 10 100 25],...
        'Callback', 'ecogPlotERP_GUI');
    
    set(gcf,'UserData',gp);
    upPlot(gp);
else
    
    gp = get(gcf,'UserData');
    upPlot(gp);
end

return

function gp = upPlot(gp)
condition=gp.condnames{get(gp.condmenu,'Value')};
elecs=str2double(get(gp.elecmenu,'String'));
block = gp.blocknames{get(gp.blockmenu,'Value')};
hflag = get(gp.holdbox,'Value');

ecogPlotter(gp.par,elecs,block,condition,gp.bef_win,gp.aft_win,hflag);

return


function ecogPlotter(par,elecs,block,condition,bef_win,aft_win,hflag)

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

bef_point= floor(bef_win * par.ieegrate);
aft_point= ceil(aft_win * par.ieegrate);
Npoints= bef_point + aft_point+1;


% fn= sprintf(['%s' filesep '..' filesep block],par.Results); %hacky
fn = fullfile(fileparts(par.Results),block); % fixed jc 10/08/10
try % don't crash if file not found -jc
    load(sprintf('%s/ERP_%s_%s_%s_%s.mat',fn,par.exptname,condition,windurstr,block)); % Zscore
    mean_erp = ERP.elecs(elecs).mean;
    std_erp = ERP.elecs(elecs).std;
    n_erp = ERP.elecs(elecs).n;
    fprintf([condition ' ' num2str(n_erp) ' trials\n']);
    if isempty(n_erp) % an unanalyzed channel, probably epileptic/bad
        mean_erp = 0;
        std_erp = 0;
        n_erp = 0;
    end
catch
    mean_erp = 0;
    std_erp = 0;
    n_erp = 0;
end

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


return
