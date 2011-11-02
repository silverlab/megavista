% Plot by Num Fibers (sep subject)
% Generate and save plots for each subject.

% data = '/biac3/wandell4/data/reading_longitude/STS_Project/analysis/masterFiberData.mat';
data = '/Volumes/biac3-wandell4/data/reading_longitude/STS_Project/analysis/masterFiberData.mat';
load(data);

% saveDir = '/home/lmperry/Desktop/DTI_figures';
saveDir = '/Volumes/lmperry/Desktop/DTI_figures';


row = 5; % Num fibers
col = 10; % variable

saveName = 'TEST_fiberRoiVol_numFibers_';
titleText = 'Fiber ROI Volume on CC';
xText = 'Number of Fibers';
yText = 'Roi Volume (mm^3)';

% Set Grid
xMin = 0;
xMax = 16000;
yMin = min(data(:,col))-(.05*(min(data(:,col))));
yMax = max(data(:,col))+(.05*(max(data(:,col))));

% Set Legend
l1 = 'Left Calcarine';
l2 = 'Left LO';
l3 = 'Left MT';
l4 = 'Left STS (RvF)';
l5 = 'Left STS (RvI)';
l6 = 'Left Occipital';
l7 = 'Left SupPar';
l8 = 'Left Temporal';

%% sub1
sub = 'at';

c = 5;
x1 = data(1:c,row);
y1 = data(1:c,col);

c = c+1;
cc = c+4;
x2 = data(c:cc,row);
y2 = data(c:cc,col);

c = cc+1;
cc = c+4;
x3 = data(c:cc,row);
y3 = data(c:cc,col);

c = cc+1;
cc = c+4;
x4 = data(c:cc,row);
y4 = data(c:cc,col);

c = cc+1;
cc = c+4;
x5 = data(c:cc,row);
y5 = data(c:cc,col);

c = cc+1;
cc = c+4;
x6 = data(c:cc,row);
y6 = data(c:cc,col);

c = cc+1;
cc = c+4;
x7 = data(c:cc,row);
y7 = data(c:cc,col);

c = cc+1;
cc = c+4;
x8 = data(c:cc,row);
y8 = data(c:cc,col);

hold off
plot(x1,y1,'-o',x2,y2,'-o',x3,y3,'-o',x4,y4,'-o',x5,y5,'-o',x6,y6,'-o',x7,y7,'-o',x8,y8,'-.o');
xlabel(xText);
ylabel(yText);
textTitle = [titleText ' (' sub ')'];
title(textTitle);
grid on
ld = legend(l1,l2,l3,l4,l5,l6,l7,l8);
set(ld,'Interpreter','tex','Location','NorthEastOutside');
axis([xMin xMax yMin yMax]);
set(gca,'PlotBoxAspectRatio',[1,.7,1]);

saveas(gcf,(fullfile(saveDir,[saveName, sub])),'epsc2');


%% sub 2
sub = 'js';

c = cc+1;
cc = c+4;
x1 = data(c:cc,row);
y1 = data(c:cc,col);

c = cc+1;
cc = c+4;
x2 = data(c:cc,row);
y2 = data(c:cc,col);

c = cc+1;
cc = c+4;
x3 = data(c:cc,row);
y3 = data(c:cc,col);

c = cc+1;
cc = c+4;
x4 = data(c:cc,row);
y4 = data(c:cc,col);

c = cc+1;
cc = c+4;
x5 = data(c:cc,row);
y5 = data(c:cc,col);

c = cc+1;
cc = c+4;
x6 = data(c:cc,row);
y6 = data(c:cc,col);

c = cc+1;
cc = c+4;
x7 = data(c:cc,row);
y7 = data(c:cc,col);

c = cc+1;
cc = c+4;
x8 = data(c:cc,row);
y8 = data(c:cc,col);

hold off
plot(x1,y1,'-o',x2,y2,'-o',x3,y3,'-o',x4,y4,'-o',x5,y5,'-o',x6,y6,'-o',x7,y7,'-o',x8,y8,'-.o');
xlabel(xText);
ylabel(yText);
textTitle = [titleText ' (' sub ')'];
title(textTitle);
grid on
ld = legend(l1,l2,l3,l4,l5,l6,l7,l8);
set(ld,'Interpreter','tex','Location','NorthEastOutside');
axis([xMin xMax yMin yMax]);
set(gca,'PlotBoxAspectRatio',[1,.7,1]);

saveas(gcf,(fullfile(saveDir,[saveName, sub])),'epsc2');


%% sub 3
sub = 'md';

c = cc+1;
cc = c+4;
x1 = data(c:cc,row);
y1 = data(c:cc,col);

c = cc+1;
cc = c+4;
x2 = data(c:cc,row);
y2 = data(c:cc,col);

c = cc+1;
cc = c+4;
x3 = data(c:cc,row);
y3 = data(c:cc,col);

c = cc+1;
cc = c+4;
x4 = data(c:cc,row);
y4 = data(c:cc,col);

c = cc+1;
cc = c+4;
x5 = data(c:cc,row);
y5 = data(c:cc,col);

c = cc+1;
cc = c+4;
x6 = data(c:cc,row);
y6 = data(c:cc,col);

c = cc+1;
cc = c+4;
x7 = data(c:cc,row);
y7 = data(c:cc,col);

c = cc+1;
cc = c+4;
x8 = data(c:cc,row);
y8 = data(c:cc,col);

hold off
plot(x1,y1,'-o',x2,y2,'-o',x3,y3,'-o',x4,y4,'-o',x5,y5,'-o',x6,y6,'-o',x7,y7,'-o',x8,y8,'-.o');
xlabel(xText);
ylabel(yText);
textTitle = [titleText ' (' sub ')'];
title(textTitle);
grid on
ld = legend(l1,l2,l3,l4,l5,l6,l7,l8);
set(ld,'Interpreter','tex','Location','NorthEastOutside');
axis([xMin xMax yMin yMax]);
set(gca,'PlotBoxAspectRatio',[1,.7,1]);

saveas(gcf,(fullfile(saveDir,[saveName, sub])),'epsc2');


%% sub 4
sub = 'mh';

c = cc+1;
cc = c+4;
x1 = data(c:cc,row);
y1 = data(c:cc,col);

c = cc+1;
cc = c+4;
x2 = data(c:cc,row);
y2 = data(c:cc,col);

c = cc+1;
cc = c+4;
x3 = data(c:cc,row);
y3 = data(c:cc,col);

c = cc+1;
cc = c+4;
x4 = data(c:cc,row);
y4 = data(c:cc,col);

c = cc+1;
cc = c+4;
x5 = data(c:cc,row);
y5 = data(c:cc,col);

c = cc+1;
cc = c+4;
x6 = data(c:cc,row);
y6 = data(c:cc,col);

c = cc+1;
cc = c+4;
x7 = data(c:cc,row);
y7 = data(c:cc,col);

c = cc+1;
cc = c+4;
x8 = data(c:cc,row);
y8 = data(c:cc,col);

hold off
plot(x1,y1,'-o',x2,y2,'-o',x3,y3,'-o',x4,y4,'-o',x5,y5,'-o',x6,y6,'-o',x7,y7,'-o',x8,y8,'-.o');
xlabel(xText);
ylabel(yText);
textTitle = [titleText ' (' sub ')'];
title(textTitle);
grid on
ld = legend(l1,l2,l3,l4,l5,l6,l7,l8);
set(ld,'Interpreter','tex','Location','NorthEastOutside');
axis([xMin xMax yMin yMax]);
set(gca,'PlotBoxAspectRatio',[1,.7,1]);

saveas(gcf,(fullfile(saveDir,[saveName, sub])),'epsc2');


%% sub 5
sub = 'mho';

c = cc+1;
cc = c+4;
x1 = data(c:cc,row);
y1 = data(c:cc,col);

c = cc+1;
cc = c+4;
x2 = data(c:cc,row);
y2 = data(c:cc,col);

c = cc+1;
cc = c+4;
x3 = data(c:cc,row);
y3 = data(c:cc,col);

c = cc+1;
cc = c+4;
x4 = data(c:cc,row);
y4 = data(c:cc,col);

c = cc+1;
cc = c+4;
x5 = data(c:cc,row);
y5 = data(c:cc,col);

c = cc+1;
cc = c+4;
x6 = data(c:cc,row);
y6 = data(c:cc,col);

c = cc+1;
cc = c+4;
x7 = data(c:cc,row);
y7 = data(c:cc,col);

c = cc+1;
cc = c+4;
x8 = data(c:cc,row);
y8 = data(c:cc,col);


hold off
plot(x1,y1,'-o',x2,y2,'-o',x3,y3,'-o',x4,y4,'-o',x5,y5,'-o',x6,y6,'-o',x7,y7,'-o',x8,y8,'-.o');
xlabel(xText);
ylabel(yText);
textTitle = [titleText ' (' sub ')'];
title(textTitle);
grid on
ld = legend(l1,l2,l3,l4,l5,l6,l7,l8);
set(ld,'Interpreter','tex','Location','NorthEastOutside');
axis([xMin xMax yMin yMax]);
set(gca,'PlotBoxAspectRatio',[1,.7,1]);

saveas(gcf,(fullfile(saveDir,[saveName, sub])),'epsc2');


%% sub 6
sub = 'mm';

c = cc+1;
cc = c+4;
x1 = data(c:cc,row);
y1 = data(c:cc,col);

c = cc+1;
cc = c+4;
x2 = data(c:cc,row);
y2 = data(c:cc,col);

c = cc+1;
cc = c+4;
x3 = data(c:cc,row);
y3 = data(c:cc,col);

c = cc+1;
cc = c+4;
x4 = data(c:cc,row);
y4 = data(c:cc,col);

c = cc+1;
cc = c+4;
x5 = data(c:cc,row);
y5 = data(c:cc,col);

c = cc+1;
cc = c+4;
x6 = data(c:cc,row);
y6 = data(c:cc,col);

c = cc+1;
cc = c+4;
x7 = data(c:cc,row);
y7 = data(c:cc,col);

c = cc+1;
cc = c+4;
x8 = data(c:cc,row);
y8 = data(c:cc,col);

hold off
plot(x1,y1,'-o',x2,y2,'-o',x3,y3,'-o',x4,y4,'-o',x5,y5,'-o',x6,y6,'-o',x7,y7,'-o',x8,y8,'-.o');
xlabel(xText);
ylabel(yText);
textTitle = [titleText ' (' sub ')'];
title(textTitle);
grid on
ld = legend(l1,l2,l3,l4,l5,l6,l7,l8);
set(ld,'Interpreter','tex','Location','NorthEastOutside');
axis([xMin xMax yMin yMax]);
set(gca,'PlotBoxAspectRatio',[1,.7,1]);

saveas(gcf,(fullfile(saveDir,[saveName, sub])),'epsc2');


%% sub 7
sub = 'rh';

c = cc+1;
cc = c+4;
x1 = data(c:cc,row);
y1 = data(c:cc,col);

c = cc+1;
cc = c+4;
x2 = data(c:cc,row);
y2 = data(c:cc,col);

c = cc+1;
cc = c+4;
x3 = data(c:cc,row);
y3 = data(c:cc,col);

c = cc+1;
cc = c+4;
x4 = data(c:cc,row);
y4 = data(c:cc,col);

c = cc+1;
cc = c+4;
x5 = data(c:cc,row);
y5 = data(c:cc,col);

c = cc+1;
cc = c+4;
x6 = data(c:cc,row);
y6 = data(c:cc,col);

c = cc+1;
cc = c+4;
x7 = data(c:cc,row);
y7 = data(c:cc,col);

c = cc+1;
cc = c+4;
x8 = data(c:cc,row);
y8 = data(c:cc,col);

hold off
plot(x1,y1,'-o',x2,y2,'-o',x3,y3,'-o',x4,y4,'-o',x5,y5,'-o',x6,y6,'-o',x7,y7,'-o',x8,y8,'-.o');
xlabel(xText);
ylabel(yText);
textTitle = [titleText ' (' sub ')'];
title(textTitle);
grid on
ld = legend(l1,l2,l3,l4,l5,l6,l7,l8);
set(ld,'Interpreter','tex','Location','NorthEastOutside');
axis([xMin xMax yMin yMax]);
set(gca,'PlotBoxAspectRatio',[1,.7,1]);

saveas(gcf,(fullfile(saveDir,[saveName, sub])),'epsc2');


%% sub 8
sub = 'ss';

c = cc+1;
cc = c+4;
x1 = data(c:cc,row);
y1 = data(c:cc,col);

c = cc+1;
cc = c+4;
x2 = data(c:cc,row);
y2 = data(c:cc,col);

c = cc+1;
cc = c+4;
x3 = data(c:cc,row);
y3 = data(c:cc,col);

c = cc+1;
cc = c+4;
x4 = data(c:cc,row);
y4 = data(c:cc,col);

c = cc+1;
cc = c+4;
x5 = data(c:cc,row);
y5 = data(c:cc,col);

c = cc+1;
cc = c+4;
x6 = data(c:cc,row);
y6 = data(c:cc,col);

c = cc+1;
cc = c+4;
x7 = data(c:cc,row);
y7 = data(c:cc,col);

c = cc+1;
cc = c+4;
x8 = data(c:cc,row);
y8 = data(c:cc,col);


hold off
plot(x1,y1,'-o',x2,y2,'-o',x3,y3,'-o',x4,y4,'-o',x5,y5,'-o',x6,y6,'-o',x7,y7,'-o',x8,y8,'-.o');
xlabel(xText);
ylabel(yText);
textTitle = [titleText ' (' sub ')'];
title(textTitle);
grid on
ld = legend(l1,l2,l3,l4,l5,l6,l7,l8);
set(ld,'Interpreter','tex','Location','NorthEastOutside');
axis([xMin xMax yMin yMax]);
set(gca,'PlotBoxAspectRatio',[1,.7,1]);

saveas(gcf,(fullfile(saveDir,[saveName, sub])),'epsc2');

