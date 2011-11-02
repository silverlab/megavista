function ecogPlotERSP_GUI(par,bef_win,aft_win,condnames,ERSPtype)

% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Last revision date SEP,2009
%
%   ecogPlotERSP(par,bef_win,aft_win,elecs,tag,ERSPtype)
%
% ERSPtype can be 'norm' or 'ersp'
%
% modified j.chen jan 2010
% made into gui for PC att'n jbh feb 2010

% Update path info based on par.basepath
if exist('par','var')
    par = ecogPathUpdate(par);
end

if nargin >= 1
    
    if notDefined('ERSPtype'), ERSPtype = 'norm'; end
    
    
    
    [gp.basepath bd] = fileparts(par.BehavData);
    gp.ERSPtype = ERSPtype;     %
    gp.bef_win = bef_win;       %
    gp.aft_win = aft_win;       %bundling things in a struct for later
    gp.elecs = 1;               %
    gp.condnames = condnames;   %
    gp.par = par;
    
    % gp.pfn = fullfile(basebath,'Print',['normERSP_' par.exptname,condition,windurstr,block '.jpg']);
    
    
    [abrd currblock] = fileparts(par.Results); % hacky way of getting block dirs
    d = dir([abrd filesep currblock(1:2) '*']); % only look for dirs with same first two letters as current block
    gp.blocknames = {d.name};
    
    
    
    figure;
    
    gp.condmenu = uicontrol(gcf,'Style', 'popup',...
        'String', gp.condnames,...
        'Position', [10 10 100 25],...
        'Callback', 'ecogPlotERSP_GUI');
    %
    % gp.printbutton = uicontrol(gcf,'Style', 'pushbutton',...
    %         'String', 'Print',...
    %         'Position', [10 500 75 25],...
    %         'Callback', 'print( gcf, ''-djpeg'', gp.pfn )');
    
    gp.elecmenu = uicontrol(gcf,'Style','edit',...
        'Position', [200 10 75 25],...
        'String',gp.elecs);
    gp.elecbutton = uicontrol(gcf,'Style', 'pushbutton',...
        'String', 'Set',...
        'Position', [300 10 75 25],...
        'Callback', 'ecogPlotERSP_GUI');
    
    gp.blockmenu = uicontrol(gcf,'Style', 'popup',...
        'String', gp.blocknames,...
        'Position', [450 10 100 25],...
        'Callback', 'ecogPlotERSP_GUI');
    
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

%
%     windur = gp.bef_win+gp.aft_win;
% windurstr = strrep(num2str(windur),'.','p');
%
%     gp.pfn = fullfile(gp.basepath,'Print',['normERSP_' gp.par.exptname '_',...
%         condition '_' windurstr '_' block '_elec' get(gp.elecmenu,'String') '.jpg']);
%     % hacky hacky way of getting file name for jpg...
%

ecogPlotter(gp.par,elecs,block,condition,gp.ERSPtype,gp.bef_win,gp.aft_win);

return


function ecogPlotter(par,elecs,block,condition,ERSPtype,bef_win,aft_win)

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

bef_point= floor(bef_win * par.fs_comp);
aft_point= ceil(aft_win * par.fs_comp);
Npoints= bef_point + aft_point+1;


thr=[];
% fn= sprintf(['%s' filesep '..' filesep block],par.Results); %hacky
fn = fullfile(fileparts(par.Results),block); % fixed jc 07/19/10
if strcmp(ERSPtype,'norm')
    try
        load(sprintf('%s/normERSP_%s_%s_%s_%s.mat',fn,par.exptname,condition,windurstr,block)); % Zscore
        Z= Zscore(:,:,elecs);
    catch % don't crash if no files exist for default block -jc
        Z = 0;
    end
    gcf; imagesc(Z,[-5 5]); axis xy
elseif strcmp(ERSPtype,'ersp')
    try
        fname = sprintf('%s/ERSP_%s_%s_%s_%s.mat',fn,par.exptname,condition,windurstr,block);
    load(fname); % just power
    Z = ERSP.elecs(elecs).value;  % hack to use this function for regular power spectrograms
    catch
        errmsg = lasterror;
        fprintf(['ERROR: ' errmsg.message]);
        Z = 0;
    end
    gcf; imagesc(Z,[0 2]); axis xy
elseif strcmp(ERSPtype,'surrogate')
    try
    load(sprintf('%s/surrogate_%s_%s_%s_%s.mat',fn,par.exptname,condition,windurstr,block)); % Zscore
    Z= surrogate.elecs(elecs).MN.value;
    catch 
        Z = 0;
    end
    gcf; imagesc(Z,[0 3]); axis xy
else
    error('Allowable ERSPtypes are "norm," "surrogate" and "ersp".')
end

if aft_win>bef_win
    set(gca,'XTick', linspace(bef_point,Npoints,5))
    set(gca,'XTickLabel',{'0', num2str(aft_win/4), num2str(aft_win/2), num2str(3*aft_win/4) num2str(aft_win)})
elseif aft_win<bef_win
    set(gca,'XTick', linspace(0,bef_point,5));
    set(gca,'XTickLabel',{num2str(-bef_win), num2str(-3*bef_win/4), num2str(-bef_win/2) num2str(-bef_win/4),'0'})
else
    set(gca,'XTick', [bef_point/2, bef_point+1 bef_point+aft_point/2]);
    set(gca,'XTickLabel',{num2str(-bef_win/2),'0',num2str(aft_win/2) })
end
set(gca,'YTick',[5 8 12 18 22 28 33 41])
set(gca,'YTickLabel',{num2str(4.7),num2str(8),num2str(12),num2str(20),num2str(30),num2str(52),num2str(100),num2str(208)})
set(gca,'FontSize',14)
set(gca,'Position',[0.1 0.2 0.8 0.7]);
set(gcf,'Color',[1 1 1]);
xlabel('Time (sec)','FontSize',14);
ylabel('Freq (Hz)','FontSize',14);
title(sprintf('%s %s chan %.3d',condition,block,elecs),'FontSize',18);
colorbar('EastOutside');

return
