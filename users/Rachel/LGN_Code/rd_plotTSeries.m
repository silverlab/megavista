function rd_plotTSeries(tSeries,view,scan)

nCycles   = numCycles(view,scan);
frameRate = getFrameRate(view,scan);
nFrames = length(tSeries);

newGraphWin

fontSize = 14;
t = linspace(0,(nFrames-1)*frameRate,nFrames)';
headerStr = ['tSeries, scan ',num2str(scan)];
set(gcf,'Name',headerStr);
plot(t,tSeries,'LineWidth',2);
% nTicks = size(tSeries,1);
xtick = (0:nFrames*frameRate/nCycles:nFrames*frameRate);
set(gca,'xtick',xtick)
set(gca,'FontSize',fontSize)
xlabel('Time (sec)','FontSize',fontSize) 
ylabel('Percent modulation','FontSize',fontSize) 
set(gca,'XLim',[0,nFrames*frameRate]);
grid on