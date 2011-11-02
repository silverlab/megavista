function img = ecogPlotERSP(par,bef_win,aft_win,elecs,tag,ERSPtype)

% Writen by Mohammad Dastjerdi, Parvizi Lab, Stanford
% Last revision date SEP,2009
%
%   img = ecogPlotERSP(par,bef_win,aft_win,elecs,tag,ERSPtype)
%
% ERSPtype can be 'norm' or 'ersp'
%
% modified j.chen jan 2010

if notDefined('ERSPtype'), ERSPtype = 'norm'; end

windur = bef_win+aft_win;
windurstr = strrep(num2str(windur),'.','p');

bef_point= floor(bef_win * par.fs_comp);
aft_point= ceil(aft_win * par.fs_comp);
Npoints= bef_point + aft_point+1;

jj=0;
for ci= elecs
    thr=[];
    jj=jj+1;
    fn= sprintf('%s',par.Results);
    if strcmp(ERSPtype,'norm')
        load(sprintf('%s/normERSP_%s_%s_%s_%s.mat',fn,par.exptname,tag,windurstr,par.block)); % Zscore
        img= Zscore(:,:,ci);
        figure(gcf+1),gcf; imagesc(img,[-5 5]); axis xy
    elseif strcmp(ERSPtype,'ersp')
        load(sprintf('%s/ERSP_%s_%s_%s_%s.mat',fn,par.exptname,tag,windurstr,par.block)); % straight power
        img = ERSP.elecs(ci).value;  % hack to use this function for regular power spectrograms
        %img = 10*log10(img);
        figure(gcf+1),gcf; imagesc(img,[0 3]); axis xy
    else
        error('Allowable ERSPtypes are "norm" and "ersp".')
    end

    colorbar('EastOutside');
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
%     set(gca,'YTick',[5 8 12 18 22 28 33 41])
%     set(gca,'YTickLabel',{num2str(4.7),num2str(8),num2str(12),num2str(20),num2str(30),num2str(52),num2str(100),num2str(208)})
    lognums = logspace(log10(4),log10(length(par.freq)),10);  % 10 values in log space
    set(gca,'YTick',lognums)
    for xx = 1:length(lognums)
        ylab{xx} = num2str(round(par.freq(round(lognums(xx)))));  % find corresponding y values in frequencies for ticks
    end
    set(gca,'YTickLabel',ylab)
    set(gca,'FontSize',14)
    xlabel('Time (sec)','FontSize',14);
    ylabel('Freq (Hz)','FontSize',14);
    title(sprintf('%s %s chan %.3d',tag,par.block,ci),'FontSize',18);
%     if strcmp(ERSPtype,'norm')  % only write out the normalized ones
%         fp= sprintf('%s/iERSP_%s_%s_%.3d.jpg',par.print_dir,tag,par.block,ci);
%     end
    %print('-f99','-djpeg',fp);  % commented out by amr
end
