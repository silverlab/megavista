% t_meshFromNifti
%
%


% ni = niftiCreate;

niFile = fullfile(mrvDataRootPath,'mrQ','T1_lsqnabs_SEIR_cfm.nii.gz');
ni = niftiRead(niFile);

% ni = niSet(ni,'fname',XXX)
ni.fname = fullfile(vistaRootPath,'mrScripts','tutorials','deleteMe.nii.gz');

% Create a plane
sz = size(ni.data);
data = zeros(sz);

wm = 16;
r = round(sz(1)/4); w = round(sz(3)/4);
data(r:(r+5),:,w:(w+5)) = wm;

% rightWM = 4;
% r = round((3/4)*sz(1)); w = round((3/4)*sz(3));
% data(r:(r+5),:,w:(w+5)) = rightWM;
% 
ni.data = data;

%
niftiWrite(ni);

%%

msh = meshBuildFromNiftiClass(ni.fname);
msh = meshSmooth(msh);
msh = meshColor(msh);
meshVisualize(msh);



