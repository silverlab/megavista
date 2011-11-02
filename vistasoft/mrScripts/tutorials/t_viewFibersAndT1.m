% s_viewFibersAndT1
%
% Load and view in mrMesh a set of fibers stored in a PDB (v3) file.
%
% Ultimately figure out how to make sure we have colors assigned to the
% groups, maybe other stuff.
% 

%% initialize stuff, probably
% vistaDataPath;

%% Load fibers and T1
t1Name = fullfile(mrvDataRootPath,'quench','bg_images','t1.nii.gz');
fgName = fullfile(mrvDataRootPath,'quench','fibers','LeftArcuate_ver3.pdb');

niT1 = niftiRead(t1Name);
% showMontage(niT1.data);

% See also mtrPdb2to3
fg = mtrImportFibers(fgName);

% ochre:
difDir = fullfile(mrvDataRootPath,'diffusion','sampleData','dti40');
chdir(difDir)

%% dtiStart for scripts
if isunix, disp('Start mrMeshSrv.exe')
else       mrmStart
end

dtiFig = dtiFiberUI(fullfile(difDir,'dt6.mat'));
dtiH   = guidata(dtiFig);

% dtiH = dtiCreate;
%dtiFig = dtiFiberUI();
%set(dtiFig,'visible','off')
%dtiH   = guidata(dtiFig);
% At this point you can use dtiSet/Get on dtiH

% Find a way to read the MR diffusion parameters here.  We will need these
% for the white matter simulation below.

%% Closing the window and then running is  faster than removing actors

% mrmCloseWindow(dtiH.mrMesh.id,dtiH.mrMesh.host);

set(dtiH.cbUseMrMesh, 'Value',1);
set(dtiH.cbShowFibers,'Value',1);
set(dtiH.cbShowMatlab3d,'Value',0);
set(dtiH.popupBackground,'Value',2);

% Add this at least once to get the fibers in there.
dtiH = dtiAddFG(fg,dtiH);

guidata(dtiFig,dtiH);  % Refresh the Matlab window handles.

% overlayThresh = get(handles.slider_overlayThresh, 'Value');
% overlayAlpha = str2double(get(handles.editOverlayAlpha, 'String'));
% curOvNum = get(handles.popupOverlay,'Value');

% showMeshWindow = 1;
% dtiH = dtiRefreshFigure(dtiH, showMeshWindow);


%% We pull out the key routines from dtiRefreshFigure and speed up

% Closing the window and then running this is much faster than removing the
% previous actors.
mrmCloseWindow(dtiH.mrMesh.id,dtiH.mrMesh.host);

% The code below here could be a routine like
% id = dtiMeshView(dtiH);
%
set(dtiH.popupBackground,'Value',5);  % Choose type of background
set(dtiH.rbSagittal,'Value',1);       % Choose which planes
set(dtiH.rbCoronal, 'Value',0);
set(dtiH.rbAxial,   'Value',1);

% With mrMesh - This started with the code from dtiRefreshFogure/dtiFiberUI
% Needs anat, anatXform
[xSliceRgb,ySliceRgb,zSliceRgb,anat,anatXform, ...
    mmPerVoxel,xform,xSliceAxes,ySliceAxes,zSliceAxes] = ...
    dtiGetCurSlices(dtiH);

curPosition = dtiGet(dtiH,'curpos');

% Should be:
% anatXform = dtiGet(dtiH,'anatXform');

[zIm] = dtiGetSlice(anatXform, anat, 3, curPosition(3), [], dtiH.interpType);
[yIm] = dtiGetSlice(anatXform, anat, 2, curPosition(2), [], dtiH.interpType);
[xIm] = dtiGetSlice(anatXform, anat, 1, curPosition(1), [], dtiH.interpType);
% figure; imagesc(zIm); axis image; colormap(gray)

% This is a little slow.
[xIm,yIm,zIm] = dtiMrMeshSelectImages(dtiH,xIm,yIm,zIm);
origin = dtiMrMeshOrigin(dtiH);
dtiH = dtiMrMesh3AxisImage(dtiH, origin, xIm, yIm, zIm);

%%  Manipulating the mesh view

msh = dtiGet(dtiH,'mesh'); % If you have a mrDiffusion guidata in dtiH
mrmRotateCamera(msh.id,'front',1); pause(1)
mrmRotateCamera(msh.id,'back',1);  pause(1)
mrmRotateCamera(msh.id,'top',1);   pause(1)
mrmRotateCamera(msh.id,'bottom',1);pause(1)
mrmRotateCamera(msh.id,'right',1); pause(1)
mrmRotateCamera(msh.id,'left',1);

% Need to permute the rotation matrix, I think, for various cases.

%% Get the diffusion FA data set coregistered with the fibers

FA   = dtiGet(dtiH,'fa data');
ssFA = dtiGet(dtiH,'fa spatial support');
% We want to convert the fiber coordinates (in ACPC units, mm).
fg = dtiGet(dtiH,'fg current');

dt = dtiLoadDt6(fullfile(difDir,'dt6.mat'));

% The coordinates in here
fgImageSpace = dtiXformFiberCoords(fg,inv(dt.xformToAcpc));
% To transform them to image space we need the qto_xyz

%
dtiGetValFromFibers

%% Push the fibers and T1 data to Quench for editing?
% niGet(niT1,'image coords to acpc')
% niGet(niT1,'acpc to image coords')


%% Predict the diffusion in a region given fg and scan parameters
%  Taken from t_mictTutForwardModeling, and simplified

addpath(genpath('C:\Users\Wandell\Documents\MATLAB\svn\vistaproj\microtrack'));

% We will need to find a way to get the MR parameters for the fg data that
% we are simulating.

% Instantiate white matter model and load fibers (pathways)
wmm = mictWhiteMatterModel('invivo');
wmm.read(pathways_filename);  % .pdb or .mat format
wmm.qto_xyz = mi.ni.qto_xyz;

% Set white matter model properties
% These are variables are public parts of the white matter model

% This should have a constant value for a given scanning sequence.
% ad_linear is a good estimate for the axial diffusivity.  d_par means
% parallel diffusivity.
%
% Does this have a syntax like wmm.d_par.set(ad_linear)?
%
wmm.d_par    = ad_linear; 

% Fraction of the streamline that will be composed of restricted water or
% within axons. Controls perp diffusivity. This formula is based on a
% tortuosity argument from Szafer, MRM, 1995, Theoretical model for water
% diffusion in tissues.  Both extracellular and intracellular are % the
% same.  The signal loss is explained entirely by the water molecules
% that do not move because they are near the cell membrane boundaries.
% (1 - volF)*axialD = radialD
wmm.vol_fraction = 1.0 - rd_linear/ad_linear; 

wmm.axon_radius  = 0; % Not used in the dti simulation
wmm.slow_fraction= 0; % Not used in the dti simulation

% Assign fascicle radius to the white matter model
wmm.fasc_radius  = fasc_radius; 

%% Instantiate the MR simulator

% This simulator produces the predicted diffusion data given fiber
% properties.
%
% This simulator defaults to the DTI simulation based on the forward model
% in a Basser paper (citation to go here).  In this case the raw signal, S, is
% the base signal (non-diffusion, S0), times a weighted sum of compartments
% within the white matter and CSF of the voxel.
%
% Each compartment has a tensor.  The CSF is isotropic, and the white
% matter components are defined by a tensor that has a PDD, ad and rd
% estimated from the data (high linearity cutoff points).
% 
% S0 * ((1-sum_i(wi))*exp(-b*DiffConstant) + sum_i( wi*exp(-b*(q Ti q) )) )
%
% The simulator is initiated with the data directory and the parameters of
% the white matter model.
mri_sim = mictMRISim(m_tree, wmm);

%% Simulate original

% Force clear option: Clears the cache (simulator). 
force_clean = 1; 

% Simulate isotropic option:  fills non fiber (pathways, projections) voxel
% compartments with CSF or some other isotropic source.  We will set this
% to zero as we are interested in maintaining the residual signal left over
% from the white matter signal
use_iso = 0;

% Residual data: Could be sent to the simulation to add in a residual, but
% right now we don't have one
res = [];

% Computes osim, the predicted MR signal given the fibers. res is the
% difference between the prediction and the measurements. We should be able
% to visualize the error.  Let's do it here. error should be err and it is
% the sum of square residuals at each voxel. 
[osim, res, errMap] = mri_sim.simulate(res,use_iso,force_clean);

% errMap.show
% direction = 20;
% meas_images = m_tree.load_measurements(); meas_images.show(direction)  
% osim.show(direction)
% res.show(direction)

% For orig sim, res+sim gives you full brain. Should match measured. In
% general, this calc makes your osim equal your measured, regardless of any
% simulated alterations
osim.ni.data = osim.ni.data + res.ni.data; 
osim.write(osim_results_name);

%% Do DTI analysis on simulated data

% Create the fa and rd volumes for the simulated data.
s_mictForwardModelingExample_AnalyzeSimData(m_tree, osim_results_name, fa_pred_result_name, rd_pred_result_name);

% Calculate difference between simulated and original fa
fa_orig = d_model.dtshape('fa');  % Original fa

% Predicted fa and then subtract off the original
fa_diff = mictImages(fa_pred_result_name);
fa_diff.ni.data = fa_diff.ni.data - fa_orig.ni.data;

fa_diff.write(fa_pred_diff_result_name);

%
% fa_diff.show; colormap('jet')

%% Perturb WM microstructure and simulate new data including previous

% The new white matter model has a different volume fraction for the
% fibers. 
wmm.vol_fraction = wmm.vol_fraction*vol_frac_change;

% We predict with the new white matter model of the fibers, using the saved
% residuals
force_clean = 1;
use_iso = 0;
asim = mri_sim.simulate(res, use_iso, force_clean);
asim.write(asim_results_name);

%% Analysis on simulated data based on fibers with different volume fraction 
s_mictForwardModelingExample_AnalyzeSimData(m_tree, asim_results_name, fa_alt_result_name, rd_alt_result_name);

% Calculate difference image
fa = d_model.dtshape('fa');
fa_diff = mictImages(fa_alt_result_name);
fa_diff.ni.data = fa_diff.ni.data - fa.ni.data;
fa_diff.write(fa_alt_diff_result_name);

% fa_diff.show; colormap('jet')

%% Visualize
vis = mictVis();

% Voxelwise
% You can use fslview to find voxel you want to look at. 
% Make sure to add 1 to each coord. 
voxel = [41,44,39]; 
vis.view_voxel_measurements( m_tree, d_model, voxel, asim );

% Images and pathways with Quench
vis_images = {fa_pred_result_name, fa_alt_diff_result_name};
vis.quench( m_tree, wmm, vis_images, ones(size(vis_images)));

%% Compare predicted and measured in dt6.

% This works through mrDiffusion.  FIgure out that interface.
% handles = dtiLoadDt6Gui(fig, handles, varargin{1});
foo = load('dt6.mat');
foo2 = dtiLoadDt6('C:\Users\Wandell\Documents\MATLAB\svn\vistadata\mictDiffusion\dti06trilinrt\dt6.mat');
