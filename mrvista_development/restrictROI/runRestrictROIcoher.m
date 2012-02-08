

% Set directories
genDir='/Volumes/Plata1/DorsalVentral';
expDir =fullfile(genDir,'fmri');
logDir = fullfile(genDir,'fmri','Results');

% Set defaults
dt='Averages';
scan=1;
threshold=0.25;
phWindow=[0 pi];

% Get sessions
setSessions;

%Open and start a txt file
dateAndTime=datestr(now,'mmddyy');
logFile=fullfile(expDir, 'Results', ['RestrictToPH' dateAndTime '.txt']);
fid=fopen(logFile,'w');
fprintf(fid, '\n Threshold: %2.2f, phWindow: [%2.2f %2.2f]\n',...
    threshold, phWindow(1), phWindow(2));
fprintf(fid, '\n Subject\tROI Name\tROI Size');

% Loop through sessions
for ii=1:length(sessions)
    cd(fullfile(expDir, sessions{ii}));
    clear view sessionName
    view=initHiddenInplane(dt,scan,rois{ii});
    %Restrict each ROI and save new ROI
    for jj=1:length(view.ROIs)
        view.selectedROI=jj;
        fprintf(fid, '\n %s', sessions{ii});
        sessionName=load('mrSESSION.mat');
        fprintf('\n Using run: %s .', sessionName.dataTYPES(view.curDataType).scanParams(view.curScan).annotation);
        view=setDisplayMode(view,'ph');
        view = setCothresh(view, threshold);
        view = setPhWindow(view, phWindow);
        view=plotCorVsPhase(view, 'polar', 1);
        newROIName=view.ROIs(view.selectedROI).name;
        newROIsize=length(view.ROIs(view.selectedROI).coords);
        fprintf(fid, '\t %s\t %4.0f', newROIName, newROIsize);
    end
end

cd(fullfile(expDir, 'Results'));