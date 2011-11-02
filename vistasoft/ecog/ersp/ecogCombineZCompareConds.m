function Zd = ecogCombineZCompareConds(Z,activeCond,baselineCond,nrows,ncols,elecCounter,textOff,bef_point,bef_win,aft_point,aft_win,minax,maxax,figNum,freq,z_cut,plotType)

%
%  function to plot a difference of Z scores between 2 conditions.  This
%  has not be de-bugged or cleaned!!!
%
%  Zd = ecogCombineZCompareConds(activeCond,baselineCond,bef_point,bef_win,aft_point,aft_win,minax,maxax,figNum)
%

if notDefined('figNum')
    figNum = 100;
end

Npoints= bef_point + aft_point+1;

% To get difference in Z scores between 1st and 2nd condition, subtract Zs
% and divide by sqrt of 2
Zd= (Z(:,:,activeCond) - Z(:,:,baselineCond))/sqrt(2);
tag= 'diff';
figure(figNum),gcf; h = subplot(nrows,ncols,elecCounter);  imagesc(Zd,[-5 5]); axis xy

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
if ~textOff
    set(gca,'YTick',[5 8 12 18 22 28 33 41])
    set(gca,'YTickLabel',{num2str(4.7),num2str(8),num2str(12),num2str(20),num2str(30),num2str(52),num2str(100),num2str(208)})
    set(gca,'FontSize',14)
    xlabel('Time (sec)','FontSize',14);
    ylabel('Frequency (Hz)','FontSize',14);
%    title(sprintf('%s chan %.3d',tag,ci),'FontSize',18);
else
    colorbar off
    axis off
end
% fp= sprintf('%s/avgiERP_%s_%.3d.jpg',print_root,tag,ci);
% print(sprintf('-f%d',3),'-djpeg',fp);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tag= 'diff_pcolor';
%[x,y]= meshgrid(1:Npoints,freq);
x=1:Npoints;
y=1:length(freq);
to_plot = double(Zd.*(Zd>z_cut | Zd<-z_cut));  % Z score cutoff
%figure(figNum+1),h= pcolor(x,y,Zd);
figure(figNum+1), subplot(nrows,ncols,elecCounter);

% Different types of plots
if strcmp(plotType,'imagesc')
    % One way of plotting directly
    imagesc(Z(:,:,jj),[minax maxax]); axis xy

elseif strcmp(plotType,'interp') || strcmp(plotType,'3D')
    % Other ways of plotting with interpolation shading and Z score cutoffs
    x=1:Npoints;
    y=1:length(freq);
    to_plot = double(Zd.*(Zd>z_cut | Zd<-z_cut));  % Z score cutoff
    %figure(figNum+1), subplot(nrows,ncols,elecCounter);
    if strcmp(plotType,'3D')
        h= surf(x,y,to_plot);
        zlim([minax*2 maxax*2])
    else
        h= pcolor(x,y,to_plot);
    end
    set(h,'edgecolor','none');
    caxis([minax maxax]);shading interp;
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
if ~textOff
    set(gca,'YTick',[5 8 12 18 22 28 33 41])
    set(gca,'YTickLabel',{num2str(4.7),num2str(8),num2str(12),num2str(20),num2str(30),num2str(52),num2str(100),num2str(208)})
    set(gca,'FontSize',14)
    xlabel('Time (sec)','FontSize',14);
    ylabel('Frequency (Hz)','FontSize',14);
%    title(sprintf('%s chan %.3d',tag,ci),'FontSize',18);
    %fp= sprintf('%s/avgiERP_%s_%.3d.jpg',print_root,tag,ci);
    %print(sprintf('-f%d',4),'-djpeg',fp);
else
    colorbar off
    axis off
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting same as figure above but with a logarithmic y-axis
%     tag= 'diff_log_pcolor';
%     [x,y]= meshgrid(1:Npoints,log10(freq));
%     % figure(5),h= pcolor(x,y,Zd);
%     figure(5), subplot(nrows,ncols,elecCounter);
%
%     if surfPlot
%         h= surf(x,y,to_plot);
%     else
%         h= pcolor(x,y,to_plot);
%     end
%
%     set(h,'edgecolor','none'); caxis([minax maxax]);shading interp;
%
%     colorbar('EastOutside');
%     if aft_win>bef_win
%         set(gca,'XTick', linspace(bef_point,Npoints,5))
%         set(gca,'XTickLabel',{'0', num2str(aft_win/4), num2str(aft_win/2), num2str(3*aft_win/4) num2str(aft_win)})
%     elseif aft_win<bef_win
%         set(gca,'XTick', linspace(0,bef_point,5));
%         set(gca,'XTickLabel',{num2str(-bef_win), num2str(-3*bef_win/4), num2str(-bef_win/2) num2str(-bef_win/4),'0'})
%     else
%         set(gca,'XTick', [bef_point/2, bef_point+1 bef_point+aft_point/2]);
%         set(gca,'XTickLabel',{num2str(-bef_win/2),'0',num2str(aft_win/2) })
%     end
%     %yticks=log10([5 8 12 18 22 28 33 41]);
%     %set(gca,'YTick',yticks)
%     %set(gca,'YTickLabel',{num2str(4.7),num2str(8),num2str(12),num2str(20),num2str(30),num2str(52),num2str(100),num2str(208)})
%     %set(gca,'YTick',[5 8 12 18 22 28 33 41])
%     set(gca,'FontSize',14)
%     xlabel('Time (sec)','FontSize',14);
%     ylabel('Logarithm of Frequency (Hz)','FontSize',14);
%     title(sprintf('%s chan %.3d',tag,ci),'FontSize',18);
%     fp= sprintf('%s/avgiERP_%s_%.3d.jpg',print_root,tag,ci);
%     print(sprintf('-f%d',5),'-djpeg',fp);