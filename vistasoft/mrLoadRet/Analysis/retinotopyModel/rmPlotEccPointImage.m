function data = rmPlotEccPointImage(v, varExpThresh, doSave)
% rmPlotEccPointImage - plot sigma, point image and CMF versus eccentricity
% in selected ROI for selected pRF model
%
% data = rmPlotEccSigma(v, lr, [fwhm=0], [plot_position_variance], [plotFlag=1]);
%
%  INPUT
%   v: view
%   varExpThresh: Variance explained threshold. Poorly-fit voxels will be
%   excluded
%   doSave: saves data structure and figures under ROI names
%
% 2007/08 SOD: ported from my scripts.
% 2008/11 KA: included the ability to plot position variance
% 2008/11 RAS: added a separate plot flag.
% 2010/07 BMH: Modified to plot point image and CMF from neighborhood
% measurements
if ~exist('v','var') || isempty(v),
    v = getCurView;
end

if ~exist('varExpThresh', 'var') || isempty(varExpThresh)
    varExpThresh=0.3;
end

if ~exist('doSave', 'var') || isempty(varExpThresh)
    doSave=0;
end

%% load stuff
% load retModel information
try
    rmFile   = viewGet(v,'rmFile');
    rmParams = viewGet(v,'rmParams');
catch %#ok<CTCH>
    error('Need retModel information (file)');
end
% load ROI information
try
    roi.coords = v.ROIs(viewGet(v,'currentROI')).coords;
    titleName  = v.ROIs(viewGet(v,'currentROI')).name;
catch %#ok<CTCH>
    error('Need ROI');
end

% load all coords
allCrds  = viewGet(v,'coords');



% get data
rmData   = load(rmFile);
[tmp, roi.iCrds] = intersectCols(allCrds,roi.coords);

%Defines what to get form the pRF model
getStuff = {'ecc','pol','sigma','varexp'};

%Gets point image, CMF and pRF sigma data for layer 1 voxels
[roi.pi, roi.ve, roi.CMF, roi.s, roi.iCrds]=rmGetPointImage(v, rmData.model{1},roi.iCrds, [5 0.6],varExpThresh);
roi.pi=roi.pi(roi.iCrds);
roi.ve=roi.ve(roi.iCrds);
roi.CMF=roi.CMF(roi.iCrds);
roi.s=roi.s(roi.iCrds);

%Gets other measures from model
for m = 1:numel(getStuff),
    tmp = rmGet(rmData.model{1},getStuff{m}, v);
    roi.(getStuff{m}) = tmp(roi.iCrds);
end;

%Sorts data so everything is ordered by eccentricity
[roi.ecc, index]=sort(roi.ecc);
roi.sigma=roi.sigma(index); %Uses pRF sigma from point image voxels only
roi.ve=roi.ve(index);
roi.pi=roi.pi(index);
roi.CMF=roi.CMF(index);
roi.s=roi.s(index);
roi.pol=roi.pol(index);

% bin size (eccentricity range) of the data
if max([rmParams.stim(:).stimSize])>4,
    binsize = 0.25;
else
    binsize = 0.25;
end

%%--- thresholds
thresh.varexp  = varExpThresh;%max(viewGet(v,'cothresh'), rmParams.analysis.fmins.vethresh);

% take all data within the stimulus range, and decrease it by a small 
% amount to be more conservative.
thresh.ecc = [0 max([rmParams.stim(:).stimSize])] + [0.5 -0.75]; 

% basically no sigma threshold
thresh.sig = [0.01 rmParams.analysis.sigmaRatioMaxVal-0.5]; 

%--- plotting parameters
xaxislim = [0 max([rmParams.stim(:).stimSize])];
MarkerSize = 8;

% find useful data given thresholds
ii = roi.varexp > thresh.varexp & ...
     roi.ecc > thresh.ecc(1) & roi.ecc < thresh.ecc(2) & ...
     roi.s > thresh.sig(1) & roi.s < thresh.sig(2);

% weighted linear regression: for sigma
% roi.p = linreg(roi.ecc(ii),roi.s(ii),roi.varexp(ii));
% roi.p = flipud(roi.p(:)); % switch to polyval format
xfit = thresh.ecc;
% yfit = polyval(roi.p,xfit);

% bootstrap confidence intervals for sigma
if exist('bootstrp', 'file') 
    B = bootstrp(1000,@(x) localfit(x,roi.ecc(ii),roi.s(ii),roi.varexp(ii)),[1:numel(roi.ecc(ii))]);
    B = B';
    pct1 = 100*0.05/2;
    pct2 = 100-pct1;
    b_lower = prctile(B',pct1);
    b_upper = prctile(B',pct2);
    roi.p=fliplr(prctile(B', 50));
    yfit = polyval(roi.p,xfit);
    keep1 = B(1,:)>b_lower(1) &  B(1,:)<b_upper(1);
    keep2 = B(2,:)>b_lower(2) &  B(2,:)<b_upper(2);
    keep = keep1 & keep2;
    b_xfit = linspace(min(xfit),max(xfit),100)';
    fits = [ones(100,1) b_xfit]*B(:,keep);
    b_upper = max(fits,[],2);
    b_lower = min(fits,[],2);
end


%Choose which voxels to bootstrap for point image data
x2fit=[1.5 5.5]; %fitting eccentricity range for lines
x2fitBin=[0.5 5.5]; %fitting eccentricity range for bins
iib = roi.varexp > thresh.varexp & ...
    roi.ecc > x2fit(1) & roi.ecc < x2fit(2) & ...
    roi.s > thresh.sig(1) & roi.s < thresh.sig(2);
%bootsrap residuals to give bootstrapped best fit line for point image data
% xecc=[ones(size(roi.pi(iib)')), roi.ecc(iib)'];
% b=regress(roi.pi(iib)',xecc);
% yfitb=xecc*b;
% resid=roi.pi(iib)'-yfitb;
% 
% sppi1=bootstrp(1000, @(x) regress1var(yfitb+x,xecc,2), resid);
% sppi2=bootstrp(1000, @(x) regress1var(yfitb+x,xecc,1), resid);
% roi.p2(1)=mean(sppi1);
% roi.p2(2)=mean(sppi2);
% y2fit = polyval(roi.p2,x2fit);

%Bootstrap confidence intervals for point image data
if exist('bootstrp', 'file')
    B2 = bootstrp(1000,@(x) localfit(x,roi.ecc(iib),roi.pi(iib),roi.varexp(iib)),[1:numel(roi.ecc(iib))]);
    B2 = B2';
    pct1 = 100*0.05/2;
    pct2 = 100-pct1;
    b2_lower = prctile(B2',pct1);
    b2_upper = prctile(B2',pct2);
    roi.p2=fliplr(prctile(B2', 50));
    y2fit = polyval(roi.p2(:),x2fit);
    keep1 = B2(1,:)>b2_lower(1) &  B2(1,:)<b2_upper(1);
    keep2 = B2(2,:)>b2_lower(2) &  B2(2,:)<b2_upper(2);
    keep = keep1 & keep2;
    b2_xfit = linspace(min(x2fit),max(x2fit),100)';
    fits = [ones(100,1) b2_xfit]*B2(:,keep);
    b2_upper = max(fits,[],2);
    b2_lower = min(fits,[],2);
end



%




if isfield(roi,'CMF')
%     %Bootstrap residual to give best fit line
%     xecc=[ones(size(roi.CMF(ii)')), roi.ecc(ii)'];
%     c=regress(1./roi.CMF(ii)',xecc);
%     yfitc=xecc*c;
%     resid=1./roi.CMF(ii)'-yfitc;
%     
%     scmf1=bootstrp(1000, @(x) regress1var(yfitc+x,xecc,2), resid);
%     scmf2=bootstrp(1000, @(x) regress1var(yfitc+x,xecc,1), resid);
%     roi.p3(1)=mean(scmf1);
%     roi.p3(2)=mean(scmf2);
%     y3fit = polyval(roi.p3,(thresh.ecc(1):binsize:thresh.ecc(2))');
%     y3fit=1./y3fit;
    
    %Bootstrap data to give confidence intervals
    if exist('bootstrp', 'file')
        %B3 = bootstrp(1000,@(x) localfit(x,roi.ecc(ii),1./roi.CMF(ii),roi.varexp(ii)),[1:numel(roi.ecc(ii))]);
        B3 = bootstrp(1000,@(x) cmfFit(x,roi.ecc(ii),roi.CMF(ii),roi.varexp(ii)),1:numel(roi.ecc(ii)));
        B3 = B3';
        roi.p3=B3;
        pct1 = 100*0.05/2;
        pct2 = 100-pct1;
        y3fit=prctile(B3', 50);
        b3_lower = prctile(B3',pct1);
        b3_upper = prctile(B3',pct2);      
        keep1 = B3(1,:)>b3_lower(1) &  B3(1,:)<b3_upper(1);
        keep2 = B3(2,:)>b3_lower(2) &  B3(2,:)<b3_upper(2);
        keep = keep1 & keep2;
        x3fit = linspace(min(xfit),max(xfit),100)';
        y3fit=1./(x3fit.*y3fit(1)+y3fit(2));
        fits = 1./([x3fit ones(100,1)]*B3(:,keep));
        b3_upper = max(fits,[],2);
        b3_lower = min(fits,[],2);
    end
    
end



% Define output struct
data.xfit = xfit(:);
data.yfit = yfit(:);
data.x    = (thresh.ecc(1):binsize:thresh.ecc(2))';
data.x2    = (x2fitBin(1):binsize:x2fitBin(2))';
data.y    = nan(size(data.x));
data.ysterr = nan(2,length(data.x));
data.z    = zeros(size(data.x));


data.y2fit = y2fit(:);
data.y2    = nan(size(data.x2));
data.y2sterr = nan(2,length(data.x2));
data.y3fit = y3fit(:);
data.y3    = nan(size(data.x));
data.y3sterr = nan(2,length(data.x));
data.x3fit   = x3fit(:);
bii=[];

% Determine data for bins
for b=thresh.ecc(1):binsize:thresh.ecc(2),
    %Determine which voxels are in each bin
    bii = roi.ecc >  b-binsize./2 & ...
          roi.ecc <= b+binsize./2 & ii;
    if any(bii),
        
        %Fit which eccentricity bin this corresponds to
        ii2 = find(data.x==b);
        
        %Bootstrap to find mean pRF sigma for each bin
        s=bootstrp(1000, @(x) weightedMean(x, roi.s(bii), roi.varexp(bii)),[1:sum(bii)]);
        data.y(ii2) = prctile(s,50);
        
        s = wstat(roi.s(bii),roi.varexp(bii));
        data.ysterr(:,ii2) = s.sterr;        

        %Bootstrap to find mean cmf for each bin
        sCMF=bootstrp(1000, @(x) weightedMean(x, roi.CMF(bii), roi.varexp(bii)),[1:sum(bii)]);
 
        data.y3(ii2) = prctile(sCMF,50);
        s = wstat(roi.CMF(bii),roi.varexp(bii));
        data.y3sterr(:,ii2) =s.sterr;
%         data.y3sterr(1,ii2) = 1/prctile(sCMF,50+34.5);
%         data.y3sterr(2,ii2) = 1/prctile(sCMF,50-34.5);
    else
       fprintf(1,'[%s]:Warning:No data in eccentricities %.1f to %.1f.\n',...
            mfilename,b-binsize./2,b+binsize./2);
    end;
end;

%Determine bin data for point image voxels. Different range, so done
%separately
for b=x2fitBin(1):binsize:x2fitBin(2),
    bii = roi.ecc >  b-binsize./2 & ...
        roi.ecc <= b+binsize./2 & ii;
    if any(bii),
        ii2 = find(data.x2==b);
        ssigma=bootstrp(1000, @(x) weightedMean(x, roi.pi(bii), roi.varexp(bii)),[1:sum(bii)]);
        data.y2(ii2) = prctile(ssigma,50);
        ssigma = wstat(roi.pi(bii),roi.varexp(bii));
        data.y2sterr(:,ii2) = ssigma.sterr;
    end
end

set(0, 'DefaultAxesFontSize', 16)


% plot first figure - all the individual voxels
data.fig(1) = figure('Color', 'w');
subplot(2,1,1); hold on;
plot(roi.ecc(~ii),roi.s(~ii),'ko','markersize',2);
plot(roi.ecc(ii), roi.s(ii), 'ro','markersize',2);
ylabel('pRF size (sigma, deg)');xlabel('Eccentricity (deg)');
h=axis;
axis([xaxislim(1) xaxislim(2) 0 min(h(4),thresh.sig(2))]);
title(titleName, 'Interpreter', 'none');

subplot(2,1,2);hold on;
plot(roi.ecc(~ii),roi.varexp(~ii),'ko','markersize',2);
plot(roi.ecc(ii), roi.varexp(ii), 'ro','markersize',2);
line(thresh.ecc, [thresh.varexp thresh.varexp], 'Color', [.3 .3 .3], ...
    'LineWidth', 1.5, 'LineStyle', '--'); % varexp cutoff
ylabel('variance explained (%)');xlabel('Eccentricity (deg)');
axis([xaxislim(1) xaxislim(2) 0 1 ]);
if doSave==1
    hgsave(data.fig(1), strcat(titleName, 'scatter'));
end


%Plot second figure: pRF sigma    
data.fig(2) = figure('Color', 'w'); hold on;
h=errorbar(data.x,data.y,data.ysterr(1,:),data.ysterr(1,:),'ro',...
    'MarkerFaceColor','r',...
    'MarkerSize',MarkerSize);
if exist('yfit', 'var')
    plot(xfit,yfit','r','LineWidth',2);
    if exist('yfitLow', 'var')
        plot(xfit,yfitLow','r','LineWidth',1);
    end
    if exist('yfitHi', 'var')
        plot(xfit,yfitHi','r','LineWidth',1);
    end
end

if exist('bootstrp','file')
    plot(b_xfit,b_upper,'k-');
    plot(b_xfit,b_lower,'k-');
end

title( sprintf('%s: Line: y=%.2fx+%.2f', titleName, roi.p(1), roi.p(2)),'FontSize', 32 );
ylabel('pRF size (deg)','FontSize', 32);xlabel('Eccentricity (deg)','FontSize',32);
h=axis;
axis([h(1) h(2) 0 0.5*ceil(h(4)*2)]);
data.ecc=roi.ecc;
data.pol=roi.pol;
data.sigma=roi.sigma;
data.sigmaL1=roi.s;
data.ve=roi.ve;
if doSave==1
    hgsave(data.fig(2), strcat(titleName, 'pRF'));
end

data.pi=roi.pi;
%Plot third figure, point image
data.fig(3) = figure('Color', 'w'); hold on;
errorbar(data.x2,data.y2,data.y2sterr(1,:),data.y2sterr(2,:),'ko',...
    'MarkerFaceColor','b',...
    'MarkerSize',MarkerSize);
if isfield(roi,'p2')
    data.y2fit=y2fit;
    title( sprintf('%s: Line: y=%.2fx+%.2f', titleName, roi.p2(1), roi.p2(2)),'FontSize', 32 );
    if exist('y2fit', 'var')
        plot(x2fit,y2fit','b','LineWidth',2);
        if exist('bootstrp','file')
            plot(b2_xfit,b2_upper,'k-');
            plot(b2_xfit,b2_lower,'k-');
        end
    end
end
h=axis;
axis([h(1) h(2) 0 0.5*ceil(h(4)*2)]);
ylabel('Population point image (mm)','FontSize', 24);xlabel('Eccentricity (deg)','FontSize',32);
if doSave==1
    hgsave(data.fig(3), strcat(titleName, 'pPI'));
end


%Plot fourth figure, CMF    
if isfield(roi,'CMF')
    data.CMF=roi.CMF;
    data.roi=roi;
    data.y3fit=y3fit;
    %         data.y3fitLow=y3fitLow;
    %         data.y3fitHi=y3fitHi;
    data.fig(4) = figure('Color', 'w'); hold on;
    errorbar(data.x,data.y3,data.y3sterr(1,:),data.y3sterr(2,:),'ko',...
        'MarkerFaceColor','g',...
        'MarkerSize',MarkerSize);
    if exist('y3fit', 'var')
        %             title(sprintf('%s: y=1/(%.2fx+%.2f), Upper: y=1/(%.2fx+%.2f), Lower: y=1/(%.2fx+%.2f)', titleName, roi.p3(1), roi.p3(2), roi.p3Hi(1), roi.p3Hi(2), roi.p3Low(1), roi.p3Low(2)), ...
        %                 'FontSize', 32 );
        title(sprintf('%s: y=1/(%.2fx+%.2f)', titleName, roi.p3(1), roi.p3(2)),'FontSize', 32 );
        
        plot(x3fit',y3fit','g','LineWidth',2);
        if exist('bootstrp','file')
            plot(x3fit,b3_upper,'k-');
            plot(x3fit,b3_lower,'k-');
        end
    end
    h=axis;
    axis([h(1) h(2) 0 0.5*ceil(h(4)*2)]);
    ylabel('Cortical Magnification Factor (mm/deg)','FontSize', 16);xlabel('Eccentricity (deg)','FontSize',32);
    if doSave==1
        hgsave(data.fig(4), strcat(titleName, 'CMF'));
    end
end

if doSave==1
    save(strcat(titleName, '.mat'), 'data');
end

return;


function b=regress1var(y,x, whichVar)
b=regress(y,x);
b=b(whichVar);
return

function b=regress1var_split(x)
b=regress(x(:,1),x(:,2:end));
b=b(2);
return

function B=cmfFit(ii,x,y,ve)
x = x(ii); y = y(ii); ve = ve(ii);
B = fminsearch(@(z) mycmffit(z,x,y,ve),[0.05;0.2]);
return

function e=mycmffit(z,x,y,ve)
e=sum(ve.*(y-(1./(z(1).*x+z(2)))).^2)./sum(ve);
return


function B=localfit(ii,x,y,ve)
B = linreg(x(ii),y(ii),ve(ii));
B(:);
return

function m=weightedMean(ii, v, w)
m = sum(v(ii).*w(ii))./sum(w(ii));
return
