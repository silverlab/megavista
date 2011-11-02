function mtrTwoRoiSamplerScript(dt6File, roi1File, roi2File, samplerOptsFile, fgFile)
% Runs MetroTrac for generating a distribution of pathways between 2 ROIs.
% 
% mtrTwoRoiSamplerScript(dt6File, roi1File, roi2File,samplerOptsFile, fibersFile)
%

% Make sure all inputs to the script exist or get them
if (ieNotDefined('dt6File'))
    [f,p] = uigetfile('*.mat', 'Load the dt6 file');
    dt6File = fullfile(p,f);
end
if (ieNotDefined('samplerOptsFile')) 
    [f,p] = uigetfile('*.txt', 'Load the MetroTrac options file');
    samplerOptsFile = fullfile(p,f);
end
if (ieNotDefined('roi1File')) 
    [f,p] = uigetfile('*.mat', 'Load the ROI 1 file');
    roi1File = fullfile(p,f);
end
if (ieNotDefined('roi2File')) 
    [f,p] = uigetfile('*.mat', 'Load the ROI2 file');
    roi2File = fullfile(p,f);
end
if (ieNotDefined('fgFile'))
    [f,p] = uiputfile('*.dat', 'Save fibers (MetroTrac format)');
    if(isnumeric(f)) error('user canceled.'); end
    fgFile = fullfile(p,f);
end

% Here is the dt6, probably don't need this if we expect the bin directory
% to exist
dt = load(dt6File);
dt.dt6(isnan(dt.dt6)) = 0;

% Get sampler options file
fid = fopen(samplerOptsFile,'r');
if(fid ~= -1)
    fclose(fid);
    mtr = mtrLoad(samplerOptsFile,dt.xformToAcPc);
end

% Put ROIs into MetroTrac structure
roi = dtiReadRoi(roi1File); % roi = dtiReadRoi(roi1File, dt.t1NormParams);
mtr = mtrSet(mtr,'roi',roi.coords,1,'coords');
roi = dtiReadRoi(roi2File); % roi = dtiReadRoi(roi2File, dt.t1NormParams);
mtr = mtrSet(mtr,'roi',roi.coords,2,'coords');

fg = mtrPaths(mtr, dt.xformToAcPc, samplerOptsFile, fgFile);

% No need to write out fibers as that is already done in mtrPaths