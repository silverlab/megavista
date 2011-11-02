% Script for computing fiber density for many path distributions

dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis';
dt6File = fullfile(dataDir,'dti3_dt6.mat');
fgDir = 'bin\metrotrac\tendon_small';
sel_filename = 'ids_corrs.mat';
sel = load(fullfile(dataDir,fgDir,sel_filename));
samples_per_roi = 100;
num_rois = length(sel.vecids);
rand_ids = rand(num_rois,samples_per_roi);
fgOutDir = 'fibers';
fg_out_summary = 'fg_summary.mat';

% Load dt6
dt6 = load(dt6File,'xformToAcPc');

% Start new fiber group
fg_out = dtiNewFiberGroup;
fg_out.name = ['fg_summary'];
fg_out.colorRgb = [20 20 240];
fg_out.fibers = {}; 

% Take the selected path distributions and copy them somewhere
for rr = 1:num_rois
        
    % Load fibers
    fgFilename = sprintf('paths_%d_%d.dat',sel.vecids(rr),rr);
    msg = sprintf('Importing fiber group from %s ...',fgFilename);
    disp(msg);
    fgFilename = fullfile(dataDir,fgDir,fgFilename);
    fg = mtrImportFibers(fgFilename, dt6.xformToAcPc);
    
    % Get sample
    rand_ids(rr,:) = ceil(rand_ids(rr,:).*length(fg.fibers));
    fg_out.fibers = {fg_out.fibers{:}, fg.fibers{rand_ids(rr,:)}}';
end

% Also try measuring the angles from each tendon_voi independently

dataDir = 'c:\cygwin\home\sherbond\images\tony_nov05\dti3_ser10\analysis';
dt6File = fullfile(dataDir,'dti3_dt6.mat');
fgDir = 'fibers';
fgFilename = 'fg_summary.mat';
roiFile = fullfile(dataDir,'ROIs','tendon_sub_slice.mat');
outputfile = fullfile(dataDir,fgDir,'fg_summary_analysis.mat');

% Load dt6
dt6 = load(dt6File,'xformToAcPc');

% Definitions
arc_dist_measure = 10; %mm
ss = 2; %mm
nnskip = round(arc_dist_measure / ss);

% Load fibergroup
fgFilename = fullfile(dataDir,fgDir,fgFilename);
fg = dtiReadFibers(fgFilename, 'junk');

% Measure pennation angle from starting points
p1 = zeros(3,length(fg.fibers));
p2 = p1;
vec = p1;
for ff = 1:length(fg.fibers)
    fiber = fg.fibers{ff};
    p1(:,ff) = fiber(:,1);
    p2(:,ff) = fiber(:,nnskip+1);
    vec(:,ff) = (p2(:,ff) - p1(:,ff))/norm(p2(:,ff)-p1(:,ff));
end

% Load tendon ROI
roi = dtiReadRoi(roiFile);

% Fit plane to this ROI
[U,S,V] = svd(roi.coords-repmat(mean(roi.coords,1),[size(roi.coords,1),1]),0);

% Find normal to the best-fit plane
Nbestfit = V(:,3)/norm(V(:,3));

% Calculate pennation angle for all vectors
penn_angles = (pi/2 - acos(Nbestfit'*vec));

figure; hist(penn_angles*180/pi);
disp(['Mean: ' num2str(mean(penn_angles*180/pi))]);
disp(['Std: ' num2str(std(penn_angles*180/pi))]);

save(outputfile,'penn_angles','vec','Nbestfit');