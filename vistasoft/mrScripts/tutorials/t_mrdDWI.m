%%  Examples of loading and manipulating diffusion weighted images
%
% OBSOLETE
%
%
% (c) Stanford VISTA Team, 2011

%% Load diffusion weighted imaging data
dataDir = fullfile(mrvDataRootPath,'diffusion','sampleData');
dwiData = dwiLoad(fullfile(dataDir,'raw'));
dwiPlot('bvecs',dwiData);

%% Look at the diffusion ADC coefficients in 3space

% All the bvecs and bvals
bvecs = dwiData.bvecs;
bvals = dwiData.bvals;

% Find the non-difussion data (b=0).  The mean of these is S0.
% Remove the non-diffusion data from the diffusion data.
b0 = (bvals == 0);      % b = 0 conditions
bvecsP = bvecs(~b0,:);  % Non b=0 vectors, bvecsP should be unit length.
bvalsP = bvals(~b0);    % Non b=0 values
S0 = mean(d(b0));       % Mean b=0 conditions

% Try coordinates around the midpoint (see above)
% coords = [35 54 43];  % Good for debugging.  Like CSF
coords = [44 54 43];  % Pretty directional, like a fiber
% coords = [47 54 43];  % Circular
% coords = [44 56 43];  
d = double(dwiData.data(coords(1),coords(2),coords(3),:));
d = squeeze(d);

mrvNewGraphWin;
plot(d)
xlabel('Directions')
ylabel('Diffusion signal');

%% The signal loss as a percentage of the b=0 (S0) conditions.  
%
% The model is 
%
%    d = S0 exp(-b (u'Qu))
%
% where b is gradient strength (bval) and u is a unit length vector in some
% direction (bvec).  The ADC can be estimated as
%
%  ADC = u'Qu = (-1/b)*ln(d/S0)
% 

% Here are the ADCs for all the data, including non-diffusion weighted
ADC = - diag( (bvals).^-1 )*log(d(:)/S0);  % um2/ms
mrvNewGraphWin;
plot(ADC)

% This plots the diffusion-weighted only, as a 3D rendering
%% Calculate the tensor from the ADC coefficients

% Plot the predicted and observed ADC values
dwiPlot('adc',dwiData,ADC,Q);




%%

