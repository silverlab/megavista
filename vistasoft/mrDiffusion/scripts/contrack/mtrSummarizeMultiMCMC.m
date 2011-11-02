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

msg = ['Saving summary to ' fg_out_summary ' ...'];
disp(msg);
% Save the new fiber summary
dtiWriteFiberGroup(fg_out, fullfile(dataDir,fgOutDir,fg_out_summary));
