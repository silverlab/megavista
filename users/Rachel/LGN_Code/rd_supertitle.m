function rd_supertitle(supertitle)
%
% rd_supertitle(supertitle)
%
% places supertitle as the title of a current figure. useful for subplots.

set(gcf,'NextPlot','add');
axes;
h = title(supertitle);
set(gca,'Visible','off');
set(h,'Visible','on');