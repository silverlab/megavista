function [SPM,pKX] = spm_spm_local(SPM)
% [Re]ML Estimation of a General Linear Model
% FORMAT [SPM,pKX] = spm_spm_local(SPM)
% 
% Michal and Brian spent a week comparing how SPM computes the beta values
% and comparing that with Rory's/mrVIsta's glm code.
%
% The structure sent in to spm_get_data() contains information that
% specifies how the data will be scaled upon return.  If you only send in
% the file name, the data are unscaled.  We did not determined, however,
% which entry of the structure causes spm_get_data() to scale the returned
% values.
%
% Given the same design matrix and data, the two calculations are
% identical. (We didn't check the covariance stuff, this is assuming no
% whitening).  This can be hard to see because of problems in reading the
% data with SPM.  The routine spm_get_data() apparently can scale the time
% series that it returns.  This has the consequence that the beta weights
% may differ by this scale factor.  But apart from this, the beta weights
% are the same in the two cases, when the design matrix is the same.
%
%         pKX is the pseudo-inverse of the and smoothed (by K) design
%         matrix. 
%
% required fields of SPM:
%
% xY.VY - nScan x 1 struct array of mapped image volumes
%         Images must have the same orientation, voxel size and data type
%       - Any scaling should have already been applied via the image handle
%         scalefactors.
%
% xX    - Structure containing design matrix information
%       - Required fields are:
%         xX.X      - Design matrix (raw, not temporally smoothed)
%         xX.name   - cellstr of parameter names corresponding to columns
%                     of design matrix
%       - Optional fields are:
%         xX.K      - cell of session-specific structures (see spm_filter)
%                   - Design & data are pre-multiplied by K
%                     (K*Y = K*X*beta + K*e)
%                   - Note that K should not smooth across block boundaries
%                   - defaults to speye(size(xX.X,1))
%         xX.W      - Optional whitening/weighting matrix used to give
%                     weighted least squares estimates (WLS). If not specified
%                     spm_spm will set this to whiten the data and render
%                     the OLS estimtes maximum likelihood
%                     i.e. W*W' = inv(xVi.V).
%
% xVi   - structure describing intrinsic temporal non-sphericity
%       - required fields are:
%         xVi.Vi    - array of non-sphericity components
%                   - defaults to {speye(size(xX.X,1))} - i.i.d.
%                   - specifying a cell array of contraints (Qi)
%                     These contraints invoke spm_reml to estimate
%                     hyperparameters assuming V is constant over voxels. 
%                     that provide a high precise estimate of xX.V
%       - Optional fields are:
%         xX.V      - Optional non-sphericity matrix.  Cov(e) = sigma^2*V
%                     If not specified spm_spm will compute this using
%                     a 1st pass to identify signifcant voxels over which
%                     to estimate V.  A 2nd pass is then used to re-estimate
%                     the parameters with WLS and save the ML estimates 
%                     (unless xX.W is already specified)
%
% xM    - Structure containing masking information, or a simple column vector
%         of thresholds corresponding to the images in VY.
%       - If a structure, the required fields are:
%         xM.TH - nVar x nScan matrix of analysis thresholds, one per image
%         xM.I  - Implicit masking (0=>none, 1 => implicit zero/NaN mask)
%         xM.VM - struct array of mapped explicit mask image volumes
% 		- (empty if no explicit masks)
%               - Explicit mask images are >0 for valid voxels to assess.
%               - Mask images can have any orientation, voxel size or data
%                 type. They are interpolated using nearest neighbour
%                 interpolation to the voxel locations of the data Y.
%       - Note that voxels with constant data (i.e. the same value across
%         scans) are also automatically masked out.
%         
%
% In addition, the global default UFp is used to set a critical
% F-threshold for selecting voxels over which the non-sphericity
% is estimated (if required)
%
%_______________________________________________________________________
%
% spm_spm is the heart of the SPM package. Given image files and a
% General Linear Model, it estimates the model parameters, variance
% hyerparameters, and smoothness of standardised residual fields, writing
% these out to disk in the current working directory for later
% interrogation in the results section. (NB: Existing analyses in the
% current working directory are overwritten).  This directory
% now becomes the working directory for this analysis and all saved
% images are relative to this directory.
%
% The model is expressed via the design matrix (xX.X). The basic model
% at each voxel is of the form is Y = X*B + e, for data Y, design
% matrix X, (unknown) parameters B, and residual errors e. The errors
% are assummed to have a normal distribution.
%
% Sometimes confounds (e.g. drift terms in fMRI) are necessary.  These
% can be specified directly in the design matrix or implicitly, in terms
% of a residual forming matrix K to give a generalised linear model
% K*Y = K*X*B + K*e.  In fact K can be any matrix (e.g. a convolution
% matrix).
%
% In some instances i.i.d. assumptions about errors do not hold.  For
% example, with serially correlated (fMRI) data or correlations among the
% levels of a factor in repeated measures designs.  This non-sphericity
% can be specified in terms of components (SPM.xVi.Vi{i}). If specified  
% these covariance components will then be estimated with ReML (restricted
% maximum likelihood) hyperparameters.  This estimation assumes the same
% non-sphericity for voxels that exceed the global F-threshold. The ReML
% estimates can then used to whiten the data giving maximum likelihood (ML)
% or Gauss-Markov estimators.  This entails a second pass of the data
% with an augmented model K*W*Y = K*W*X*B + K*W*e where W*W' = inv(xVi.V).
% xVi.V is the non-sphericity based on the hyperparameter esimates. 
% W is stored in xX.W and cov(K*W*e) in xX.V.  The covariance of the 
% parameter estimates is then xX.Bcov = pinv(K*W*X)*xX.V*pinv(K*W*X)';
%
% If you do not want ML estimates but want to use ordinary least squares
% (OLS) then simply set SPM.xX.W to the identity matrix. Any non-sphericity
% V will still be estimated but will be used to adjust the degrees of freedom
% of the ensuing statistics using the Satterthwaite approximation (c.f.
% the Greenhouse-Giesser corrections)
%
% If [non-spherical] variance components Vi are not specified xVi.Vi and 
% xVi.V default to the identity matrix (i.e. i.i.d). The parameters are 
% then estimated by OLS.  In this instance the OLS and ML estimates are
% the same.
%
% Note that only a single voxel-specific hyperaprameter (i.e. variance
% component) is estimated, even if V is not i.i.d.  This means spm_spm
% always implements a fixed-effects model.
% Random effects models can be emulated using a multi-stage procedure:
% This entails summarising the data with contrasts such that the fixed
% effects in a second model on the summary data are those effects of
% interest (i.e. the population effects). This means contrasts are 
% re-entered into spm_spm to make an inference (SPM) at the next
% level. At this higher hierarchial level the residual variance for the 
% model contains the appropriate variance components from lower levels.
% See spm_RandFX.man for further details and below.
%
% Under the additional assumption that the standardised residual images
% are non-stationary standard Gaussian random fields, results from
% Random field theory can be applied to estimate the significance
% statistic images (SPM's) adjusting p values for the multiple tests
% at all voxels in the search volume. The parameters required for
% this random field correction are the volume, and Lambda, the covariance
% matrix of partial derivatives of the standardised error fields.
%
% spm_est_smoothness estimates the variances of the partial derivatives 
% in the axis directions (the diagonal of Lambda). The covariances (off
% diagonal elements of Lambda) are assumed to be zero.
% 
%                           ----------------
%
%
% The volume analsed is the intersection of the threshold masks,
% explicit masks and implicit masks. See spm_spm_ui for further details
% on masking options.
%
% 
%-----------------------------------------------------------------------
%
% The output of spm_spm takes the form of an SPM.mat file of the analysis
% parameters, and 'float' flat-file images of the parameter and variance
% [hyperparameter] estimates. An 8bit zero-one mask image indicating the
% voxels assessed is also written out, with zero indicating voxels outside
% tha analysed volume.
%
%                           ----------------
%
% The following SPM.fields are set by spm_spm (unless specified)
%
%     xVi.V      - estimated non-sphericity trace(V) = rank(V)
%     xVi.h      - hyperparameters  xVi.V = xVi.h(1)*xVi.Vi{1} + ...
%     xVi.Cy     - spatially whitened <Y*Y'> (used by ReML to estimate h)
%     xVi.CY     - <(Y - <Y>)*(Y - <Y>)'>    (used by spm_spm_Bayes)
%
%                           ----------------
%
%     Vbeta     - struct array of beta image handles (relative)
%     VResMS    - file struct of ResMS image handle  (relative)
%     VM        - file struct of Mask  image handle  (relative)
%
%                           ----------------
%     xX.W      - if not specified W*W' = inv(x.Vi.V)
%     xX.V      - V matrix (K*W*Vi*W'*K') = correlations after K*W is applied
%     xX.xKXs   - space structure for K*W*X, the 'filtered and whitened'
%                 design matrix
%               - given as spm_sp('Set',xX.K*xX.W*xX.X) - see spm_sp
%     xX.pKX    - pseudoinverse of K*W*X, computed by spm_sp
%     xX.Bcov   - xX.pKX*xX.V*xX.pKX - variance-covariance matrix of
%                 parameter estimates
%		  (when multiplied by the voxel-specific hyperparameter ResMS)
%                 (of the parameter estimates. (ResSS/xX.trRV = ResMS)    )
%     xX.trRV   - trace of R*V, computed efficiently by spm_SpUtil
%     xX.trRVRV - trace of RVRV
%     xX.erdf   - effective residual degrees of freedom (trRV^2/trRVRV)
%     xX.nKX    - design matrix (xX.xKXs.X) scaled for display
%                 (see spm_DesMtx('sca',... for details)
%
%                           ----------------
%
%     xVol.M    - 4x4 voxel->mm transformation matrix
%     xVol.iM   - 4x4 mm->voxel transformation matrix
%     xVol.DIM  - image dimensions - column vector (in voxels)
%     xVol.XYZ  - 3 x S vector of in-mask voxel coordinates
%     xVol.S    - Lebesgue measure or volume       (in voxels)
%     xVol.R    - vector of resel counts           (in resels)
%     xVol.FWHM - Smoothness of components - FWHM, (in voxels)
%
%                           ----------------
%
% xCon  - See Christensen for details of F-contrasts.  These are specified
%         at the end of spm_spm after the non-sphericity V has been defined
%         or estimated. The fist contrast tests for all effects of interest
%         assuming xX.iB and xX.iG index confounding or nuisance effects.
%
%     xCon      - Contrast structure (created by spm_FcUtil.m)
%     xCon.name - Name of contrast
%     xCon.STAT - 'F', 'T' or 'P' - for F/T-contrast ('P' for PPMs)
%     xCon.c    - (F) Contrast weights
%     xCon.X0   - Reduced design matrix (spans design space under Ho)
%                 It is in the form of a matrix (spm99b) or the
%                 coordinates of this matrix in the orthogonal basis
%                 of xX.X defined in spm_sp. 
%     xCon.iX0  - Indicates how contrast was specified:
%                 If by columns for reduced design matrix then iX0 contains the
%                 column indices. Otherwise, it's a string containing the
%                 spm_FcUtil 'Set' action: Usuall one of {'c','c+','X0'}
%                 (Usually this is the input argument F_iX0.)
%     xCon.X1o  - Remaining design space (orthogonal to X0).
%                 It is in the form of a matrix (spm99b) or the
%                 coordinates of this matrix in the orthogonal basis
%                 of xX.X defined in spm_sp.
%     xCon.eidf - Effective interest degrees of freedom (numerator df)
%     xCon.Vcon - ...for handle of contrast/ESS image (empty at this stage)
%     xCon.Vspm - ...for handle of SPM image (empty at this stage)
%
%                           ----------------
%
%
% The following images are written to file
%
% mask.{img,hdr}                                   - analysis mask image
% 8-bit (uint8) image of zero-s & one's indicating which voxels were
% included in the analysis. This mask image is the intersection of the
% explicit, implicit and threshold masks specified in the xM argument.
% The XYZ matrix contains the voxel coordinates of all voxels in the
% analysis mask. The mask image is included for reference, but is not
% explicitly used by the results section.
%
%                           ----------------
%
% beta_????.{img,hdr}                                 - parameter images
% These are 16-bit (float) images of the parameter estimates. The image
% files are numbered according to the corresponding column of the
% design matrix. Voxels outside the analysis mask (mask.img) are given
% value NaN.
%
%                           ----------------
%
% ResMS.{img,hdr}                    - estimated residual variance image
% This is a 32-bit (double) image of the residual variance estimate.
% Voxels outside the analysis mask are given value NaN.
%
%                           ----------------
%
% RVP.{img,hdr}                      - estimated resels per voxel image
% This is a 32-bit (double) image of the RESELs per voxel estimate.
% Voxels outside the analysis mask are given value 0.  These images
% reflect the nonstationary aspects the spatial autocorrelations.
%
%
%-----------------------------------------------------------------------
%
% References:
%
% Christensen R (1996) Plane Answers to Complex Questions
%       Springer Verlag
%
% Friston KJ, Holmes AP, Worsley KJ, Poline JP, Frith CD, Frackowiak RSJ (1995)
% ``Statistical Parametric Maps in Functional Imaging:
%   A General Linear Approach''
%       Human Brain Mapping 2:189-210
%
% Worsley KJ, Friston KJ (1995)
% ``Analysis of fMRI Time-Series Revisited - Again''
%       Neuroimage 2:173-181
%
%-----------------------------------------------------------------------
%
% For those interested, the analysis proceeds a "block" at a time,
% The block size conforms to maxMem that can be set as a global variable
% MAXMEM (in bytes) [default = 2^20]
%
%_______________________________________________________________________
% @(#)spm_spm.m	2.66 Andrew Holmes, Jean-Baptiste Poline, Karl Friston 03/03/27
SCCSid   = '2.66';

%-Say hello
%-----------------------------------------------------------------------
SPMid    = spm('FnBanner',mfilename,SCCSid);
Finter   = spm('FigName','Stats: estimation...'); spm('Pointer','Watch')

%-Get SPM.mat if necessary
%-----------------------------------------------------------------------
if nargin ==0
	swd     = spm_str_manip(spm_get(1,'SPM.mat','Select SPM.mat'),'H');
	load(fullfile(swd,'SPM.mat'));
	SPM.swd = swd;
end

%-Change to SPM.swd if specified
%-----------------------------------------------------------------------
try
	cd(SPM.swd);
end

%-Ensure data are assigned
%-----------------------------------------------------------------------
try
	SPM.xY.VY;
catch
	helpdlg({	'Please assign data to this design',...
			'Use fMRI under model specification'});
	spm('FigName','Stats: done',Finter); spm('Pointer','Arrow')
	return
end

%-Delete files from previous analyses
%-----------------------------------------------------------------------
if exist(fullfile('.','mask.img'),'file') == 2

	str   = {'Current directory contains SPM estimation files:',...
		 'pwd = ',pwd,...
		 'Existing results will be overwritten!'};

	abort = spm_input(str,1,'bd','stop|continue',[1,0],1);
	if abort
		spm('FigName','Stats: done',Finter); spm('Pointer','Arrow')
		return
	else
		str = sprintf('Overwriting old results\n\t (pwd = %s) ',pwd)
		warning(str)
		drawnow
	end
end

files = {	'mask.???','ResMS.???','RVP.???',...
		'beta_????.???','con_????.???','ResI_????.???',...
		'ess_????.???', 'spm?_????.???'};

for i=1:length(files)
	if any(files{i} == '*'|files{i} == '?' )
		[j,null] = spm_list_files(pwd,files{i});
		for i=1:size(j,1)
			spm_unlink(deblank(j(i,:)))
		end
	else
		spm_unlink(files{i})
	end
end


%=======================================================================
% - A N A L Y S I S   P R E L I M I N A R I E S
%=======================================================================

%-Initialise
%=======================================================================
fprintf('%-40s: %30s','Initialising parameters','...computing')    %-#
xX            = SPM.xX;
[nScan nBeta] = size(xX.X);


%-If xM is not a structure then assumme it's a vector of thresholds
%-----------------------------------------------------------------------
try
	xM = SPM.xM;
catch
	xM = -ones(nScan,1)/0;
end
if ~isstruct(xM)
	xM = struct(	'T',	[],...
			'TH',	xM,...
			'I',	0,...
			'VM',	{[]},...
			'xs',	struct('Masking','analysis threshold'));
end

%-Check confounds (xX.K) and non-sphericity (xVi)
%-----------------------------------------------------------------------
if ~isfield(xX,'K')
	xX.K  = 1;
end
try
	%-If covariance components are specified use them
	%---------------------------------------------------------------
	xVi   = SPM.xVi;
catch

	%-otherwise assume i.i.d.
	%---------------------------------------------------------------
	xVi   = struct(	'form',  'i.i.d.',...
			'V',	 speye(nScan,nScan));
end


%-Get non-sphericity V
%=======================================================================
try
	%-If xVi.V is specified proceed directly to parameter estimation
	%---------------------------------------------------------------
	V     = xVi.V;
	str   = 'parameter estimation';


catch
	% otherwise invoke ReML selecting voxels under i.i.d assumptions
	%---------------------------------------------------------------
	V     = speye(nScan,nScan);
	str   = '[hyper]parameter estimation';
end

%-Get whitening/Weighting matrix: If xX.W exists we will save WLS estimates
%-----------------------------------------------------------------------
try
	%-If W is specified, use it
	%-------------------------------------------------------
	W     = xX.W;   % imagesc(W); title('Whitening matrix')
catch
	if isfield(xVi,'V')

		% otherwise make W a whitening filter W*W' = inv(V)
		%-------------------------------------------------------
		[u s] = spm_svd(xVi.V);
		s     = spdiags(1./sqrt(diag(s)),0,nScan,nScan);
		W     = u*s*u';
		W     = W.*(abs(W) > 1e-6);
		xX.W  = sparse(W);
	else
		% unless xVi.V has not been estimated - requiring 2 passes
		%-------------------------------------------------------
		W     = speye(nScan,nScan);
		str   = 'hyperparameter estimation (1st pass)';
	end
end


%-Design space and projector matrix [pseudoinverse] for WLS
%=======================================================================

% The first 'Set' initializes the SVD of the design matrix properties. In
% our default analysis, W is the identity matrix. In our case, we set K so
% that it is an impulse. 
xX.xKXs = spm_sp('Set',spm_filter(xX.K,W*xX.X));		% KWX

% Hence, it turns out the with our settings, KWX is just X
% figure(1); subplot(1,3,1), plot(spm_filter(xX.K,W*xX.X)); 
%            subplot(1,3,2), plot(W*xX.X)
%            subplot(1,3,3), plot(xX.xKXs.X)

% Compute the pseudo-inverse of xX.xKXs (from above)
xX.pKX  = spm_sp('x-',xX.xKXs);				% projector

% So, after all this nonsense, it is still the case that pKX remains
% the pseudoinverse of X.
% max(abs(xX.X(:) - xX.xKXs.X(:)))

%-If xVi.V is not defined compute Hsqr and F-threshold under i.i.d.
%-----------------------------------------------------------------------
if ~isfield(xVi,'V')
	Fcname = 'effects of interest';
	iX0    = [SPM.xX.iB SPM.xX.iG];
	xCon   = spm_FcUtil('Set',Fcname,'F','iX0',iX0,xX.xKXs);
	X1o    = spm_FcUtil('X1o', xCon(1),xX.xKXs);
	Hsqr   = spm_FcUtil('Hsqr',xCon(1),xX.xKXs);
	trRV   = spm_SpUtil('trRV',xX.xKXs);
	trMV   = spm_SpUtil('trMV',X1o);
	UFp    = spm('GetGlobal','UFp');
	UF     = spm_invFcdf(1 - UFp,[trMV,trRV]);
end


%-Image dimensions and data
%=======================================================================
VY       = SPM.xY.VY;
M        = VY(1).mat;
DIM      = VY(1).dim(1:3)';
xdim     = DIM(1); ydim = DIM(2); zdim = DIM(3);
YNaNrep  = spm_type(VY(1).dim(4),'nanrep');

%-Maximum number of residual images for smoothness estimation
%-----------------------------------------------------------------------
global     defaults
MAXRES   = defaults.stats.maxres;

%-maxMem is the maximum amount of data processed at a time (bytes)
%-----------------------------------------------------------------------
MAXMEM   = defaults.stats.maxmem;
nSres    = min(nScan,MAXRES);
blksz    = ceil(MAXMEM/8/nScan);				%-block size
nbch     = ceil(xdim*ydim/blksz);				%-# blocks
nbch = 1;
blksz    = ceil(MAXMEM);				%-block size

fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#


%-Initialise output images (unless this is a 1st pass for ReML)
%=======================================================================
if isfield(xX,'W')
fprintf('%-40s: %30s','Output images','...initialising')     %-#

%-Intialise the name of the new mask : current mask & conditions on voxels
%-----------------------------------------------------------------------
VM    = struct(		'fname',	'mask.img',...
			'dim',		[DIM',spm_type('uint8')],...
			'mat',		M,...
			'pinfo',	[1 0 0]',...
			'descrip',	'spm_spm:resultant analysis mask');
VM    = spm_create_vol(VM);


%-Intialise beta image files
%-----------------------------------------------------------------------
Vbeta(1:nBeta) = deal(struct(...
			'fname',	[],...
			'dim',		[DIM',spm_type('float')],...
			'mat',		M,...
			'pinfo',	[1 0 0]',...
			'descrip',	''));
for i = 1:nBeta
	Vbeta(i).fname   = sprintf('beta_%04d.img',i);
	Vbeta(i).descrip = sprintf('spm_spm:beta (%04d) - %s',i,xX.name{i});
	spm_unlink(Vbeta(i).fname)
end
Vbeta = spm_create_vol(Vbeta,'noopen');


%-Intialise residual sum of squares image file
%-----------------------------------------------------------------------
VResMS = struct(	'fname',	'ResMS.img',...
			'dim',		[DIM',spm_type('double')],...
			'mat',		M,...
			'pinfo',	[1 0 0]',...
			'descrip',	'spm_spm:Residual sum-of-squares');
VResMS = spm_create_vol(VResMS,'noopen');


%-Intialise residual images
%-----------------------------------------------------------------------
VResI(1:nSres) = deal(struct(...
			'fname',	[],...
			'dim',		[DIM',spm_type('double')],...
			'mat',		M,...
			'pinfo',	[1 0 0]',...
			'descrip',	'spm_spm:Residual image'));

for i = 1:nSres
	VResI(i).fname   = sprintf('ResI_%04d.img', i);
	VResI(i).descrip = sprintf('spm_spm:ResI (%04d)', i);
	spm_unlink(VResI(i).fname);
end
VResI = spm_create_vol(VResI);
end % (xX,'W')

fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...initialised')        %-#


%=======================================================================
% - F I T   M O D E L   &   W R I T E   P A R A M E T E R    I M A G E S
%=======================================================================


%-Intialise variables used in the loop 
%=======================================================================
xords = [1:xdim]'*ones(1,ydim); xords = xords(:)';  % plane X coordinates
yords = ones(xdim,1)*[1:ydim];  yords = yords(:)';  % plane Y coordinates
S     = 0;                                          % Volume (voxels)
s     = 0;                                          % Volume (voxels > UF)
Cy    = 0;					    % <Y*Y'> spatially whitened
CY    = 0;					    % <Y*Y'> for ReML
EY    = 0;					    % <Y>    for ReML
i_res = round(linspace(1,nScan,nSres))';	    % Indices for residual

%-Initialise XYZ matrix of in-mask voxel co-ordinates (real space)
%-----------------------------------------------------------------------
XYZ   = zeros(3,xdim*ydim*zdim);

%-Cycle over bunches blocks within planes to avoid memory problems
%=======================================================================
% spm_progress_bar('Init',100,str,'');

totalVox = 0;
for z = 1:zdim				%-loop over planes (2D or 3D data)

    % current plane-specific parameters
    %-------------------------------------------------------------------
    zords   = z*ones(xdim*ydim,1)';	%-plane Z coordinates
    CrBl    = [];			%-parameter estimates
    CrResI  = [];			%-normalized residuals
    CrResSS = [];			%-residual sum of squares
    Q       = [];			%-in mask indices for this plane

    for bch = 1:nbch			%-loop over blocks

	%-# Print progress information in command window
	%---------------------------------------------------------------
	str   = sprintf('Plane %3d/%-3d, block %3d/%-3d',z,zdim,bch,nbch);
	fprintf('\r%-40s: %30s',str,' ')                                %-#

	%-construct list of voxels in this block
	%---------------------------------------------------------------
	I     = [1:blksz] + (bch - 1)*blksz;		%-voxel indices
	I     = I(I <= xdim*ydim);			%-truncate
	xyz   = [xords(I); yords(I); zords(I)];		%-voxel coordinates
	nVox  = size(xyz,2);				%-number of voxels

	%-Get data & construct analysis mask
	%===============================================================
	fprintf('%s%30s',sprintf('\b')*ones(1,30),'...read & mask data')%-#
	Cm    = logical(ones(1,nVox));			%-current mask


	%-Compute explicit mask
	% (note that these may not have same orientations)
	%---------------------------------------------------------------
	for i = 1:length(xM.VM)

		%-Coordinates in mask image
		%-------------------------------------------------------
		j      = xM.VM(i).mat\M*[xyz;ones(1,nVox)];

		%-Load mask image within current mask & update mask
		%-------------------------------------------------------
		Cm(Cm) = spm_get_data(xM.VM(i),j(:,Cm)) > 0;
	end
	
	%-Get the data in mask, compute threshold & implicit masks
	%---------------------------------------------------------------
	Y     = zeros(nScan,nVox);
	for i = 1:nScan

		%-Load data in mask
		%-------------------------------------------------------
		if ~any(Cm), break, end			%-Break if empty mask
		Y(i,Cm)  = spm_get_data(VY(i),xyz(:,Cm));

        % tmp = Y(i,Cm); hist(tmp(:));

		Cm(Cm)   = Y(i,Cm) > xM.TH(i);		%-Threshold (& NaN) mask
		if xM.I & ~YNaNrep & xM.TH(i) < 0	%-Use implicit mask
			Cm(Cm) = abs(Y(i,Cm)) > eps;
        end
        max(Y(:))
	end

	%-Mask out voxels where data is constant
	%---------------------------------------------------------------
	Cm(Cm) = any(diff(Y(:,Cm),1));
	Y      = Y(:,Cm);				%-Data within mask
	CrS    = sum(Cm);				%-# current voxels
    
    figure(1); plot(Y); 
    totalVox = CrS + totalVox
    title(sprintf('Current voxels TS %.0f, total: ',CrS,totalVox));
    pause(.2)
    foo = analyzeRead(VY(i).fname);
    hist(foo(:),100)
    imtool(foo/max(foo(:)))
	%===============================================================
	%-Proceed with General Linear Model (if there are voxels)
	%===============================================================
	if CrS

		%-Whiten/Weight data and remove filter confounds
		%-------------------------------------------------------
		fprintf('%s%30s',sprintf('\b')*ones(1,30),'filtering')	%-#

        % For us, W is the identity.  
        % figure(1); imagesc(W)
        % In this case, KWY is just Y, the data
        %     max(abs(KWY(:) - Y(:)))
		KWY   = spm_filter(xX.K,W*Y);

		%-General linear model: Weighted least squares estimation
		%------------------------------------------------------
		fprintf('%s%30s',sprintf('\b')*ones(1,30),' estimation') %-#

        % Wandell notes:
        %
        %  SPM computes the beta weights using the formula
        %
        %    KWY= KX*beta
        %  
        %  Here, pKX is the pseudo-inverse of KX. X is the design matrix,
        %  and K is the term that introduces the convolution with the HRF
        %
        %  KWY is the whitened, filtered, time series. I don't underwstand
        %  why K is on both sides.  Maybe, therefore, I don't understand K.
        %
        %  The formula our glm computes is Y = X*beta
        %  So the differences are that we included the HRF into X and they
        %  assume we did not.  The W is the identity, so it doesn't matter.
        %  If we set up the SPM so that K is the impulse, we should get the
        %  same.  If we set up the SPM so that we pass it X prior to
        %  filtering with the HRF, then we should also get the same.
        
        % So, 
		beta  = xX.pKX*KWY;			%-Parameter estimates   
        pKX   = xX.pKX;             % Wandell added for return
        
		res   = spm_sp('r',xX.xKXs,KWY);	%-Residuals
		ResSS = sum(res.^2);			%-Residual SSQ
		clear KWY				%-Clear to save memory


		%-If ReML hyperparameters are needed for xVi.V
		%-------------------------------------------------------
		if ~isfield(xVi,'V')

			%-F-threshold & accumulate spatially whitened Y*Y'
			%-----------------------------------------------
			j   = sum((Hsqr*beta).^2,1)/trMV > UF*ResSS/trRV;
			j   = find(j);
			if length(j)
				q  = size(j,2);
				s  = s + q;
				q  = spdiags(sqrt(trRV./ResSS(j)'),0,q,q);
				Y  = Y(:,j)*q;
				Cy = Cy + Y*Y';
			end

		end % (xVi,'V')


		%-if we are saving the WLS parameters
		%-------------------------------------------------------
		if isfield(xX,'W')

			%-sample covariance and mean of Y (all voxels)
			%-----------------------------------------------
			CY         = CY + Y*Y';
			EY         = EY + sum(Y,2);

			%-Save betas etc. for current plane as we go along
			%-----------------------------------------------
			CrBl 	   = [CrBl,    beta];
			CrResI     = [CrResI,  res(i_res,:)];
			CrResSS    = [CrResSS, ResSS];

		end % (xX,'W')
		clear Y				%-Clear to save memory

	end % (CrS)

	%-Append new inmask voxel locations and volumes
	%---------------------------------------------------------------
	XYZ(:,S + [1:CrS]) = xyz(:,Cm);		%-InMask XYZ voxel coords
	Q                  = [Q I(Cm)];		%-InMask XYZ voxel indices
	S                  = S + CrS;		%-Volume analysed (voxels)

    end   % (bch)


    %-Plane complete, write plane to image files (unless 1st pass)
    %===================================================================
    if isfield(xX,'W')
 
    	fprintf('%s%30s',sprintf('\b')*ones(1,30),'...saving plane')	%-#

	%-Write Mask image
	%-------------------------------------------------------------------
	j   = sparse(xdim,ydim);
	if length(Q), j(Q) = 1; end
	VM    = spm_write_plane(VM, j, z);

	%-Write beta images
	%-------------------------------------------------------------------
	j   = NaN*ones(xdim,ydim);
	for i = 1:nBeta
		if length(Q), j(Q) = CrBl(i,:); end
		Vbeta(i) = spm_write_plane(Vbeta(i), j, z);
	end

	%-Write residual images
	%-------------------------------------------------------------------
	for i = 1:nSres
		if length(Q), j(Q) = CrResI(i,:); end
		VResI(i) = spm_write_plane(VResI(i), j, z);
   	end

	%-Write ResSS into ResMS (variance) image scaled by tr(RV) above
	%-------------------------------------------------------------------
	if length(Q), j(Q) = CrResSS;    end
	VResMS  = spm_write_plane(VResMS,j,z);
		
    end % (xX,'W')

    %-Report progress
    %-------------------------------------------------------------------
    fprintf('%s%30s',sprintf('\b')*ones(1,30),'...done')             %-#
    spm_progress_bar('Set',100*(bch + nbch*(z - 1))/(nbch*zdim));


end % (for z = 1:zdim)
fprintf('\n')                                                        %-#
spm_progress_bar('Clear')

%=======================================================================
% - P O S T   E S T I M A T I O N   C L E A N U P
%=======================================================================
if S == 0, warning('No inmask voxels - empty analysis!'), end

%-close written image files (unless 1st pass)
%=======================================================================
if isfield(xX,'W')

	fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...closing files')  %-#
	VM              = spm_close_vol(VM);
	Vbeta           = spm_close_vol(Vbeta);
	VResI           = spm_close_vol(VResI);
	VResMS          = spm_close_vol(VResMS);

end % (xVi,'V')

%-average sample covariance and mean of Y (over voxels)
%-----------------------------------------------------------------------
CY          = CY/S;
EY          = EY/S;
CY          = CY - EY*EY';

%-If not defined, compute non-sphericity V using ReML Hyperparameters
%=======================================================================
if ~isfield(xVi,'V')

	%-REML estimate of residual correlations through hyperparameters (h)
	%---------------------------------------------------------------
	str    = 'Temporal non-sphericity (over voxels)';
	fprintf('%-40s: %30s\n',str,'...REML estimation') %-#
	Cy            = Cy/s;

	% ReML for separable designs and covariance components
	%---------------------------------------------------------------
	if isstruct(xX.K)
		m     = length(xVi.Vi);
		h     = zeros(m,1);
		V     = sparse(nScan,nScan); 
		for i = 1:length(xX.K)

			% extract blocks from bases
			%-----------------------------------------------
			q     = xX.K(i).row;
			p     = [];
			Qp    = {};
			for j = 1:m
				if nnz(xVi.Vi{j}(q,q))
					Qp{end + 1} = xVi.Vi{j}(q,q);
					p           = [p j];
				end
			end

			% design space for ReML (with confounds in filter)	
			%-----------------------------------------------
			Xp         = xX.X(q,:);
			try
				Xp = [Xp xX.K(i).X0];
			end

			% ReML
			%-----------------------------------------------
			fprintf('%-30s- %i\n','  ReML Block',i);
			[Vp,hp]  = spm_reml(Cy(q,q),Xp,Qp);
			V(q,q)   = V(q,q) + Vp;
			h(p)     = hp;
		end
	else
		[V,h] = spm_reml(Cy,xX.X,xVi.Vi);
	end
	
	% normalize non-sphericity and save hyperparameters
	%---------------------------------------------------------------
	V           = V*nScan/trace(V);
	xVi.h       = h;
	xVi.V       = V;			% Save non-sphericity xVi.V
	xVi.Cy      = Cy;			%-spatially whitened <Y*Y'>
	SPM.xVi     = xVi;			% non-sphericity structure

	% If xX.W is not specified use W*W' = inv(V) to give ML estimators
	%---------------------------------------------------------------
	if ~isfield(xX,'W')
		save SPM SPM
		clear
		load SPM
		SPM = spm_spm(SPM);
		return
	end
end


%-Use non-sphericity xVi.V to compute [effective] degrees of freedom
%=======================================================================
xX.V            = spm_filter(xX.K,spm_filter(xX.K,W*V*W')');	% KWVW'K'
[trRV trRVRV]   = spm_SpUtil('trRV',xX.xKXs,xX.V);		% trRV (for X)
xX.trRV         = trRV;						% <R'*y'*y*R>
xX.trRVRV       = trRVRV;					%-Satterthwaite
xX.erdf         = trRV^2/trRVRV;				% approximation
xX.Bcov         = xX.pKX*xX.V*xX.pKX';				% Cov(beta)


%-Set VResMS scalefactor as 1/trRV (raw voxel data is ResSS)
%-----------------------------------------------------------------------
VResMS.pinfo(1) = 1/xX.trRV;
VResMS          = spm_create_vol(VResMS,'noopen');


%-Create 1st contrast for 'effects of interest' (all if not specified)
%=======================================================================
Fcname          = 'effects of interest';
try
	iX0     = [xX.iB xX.iG];
catch
	iX0     = [];
end
xCon            = spm_FcUtil('Set',Fcname,'F','iX0',iX0,xX.xKXs);

%-Append contrasts for fMRI - specified by SPM.Sess(s).Fc(i)
%-----------------------------------------------------------------------
if isfield(SPM,'Sess')
    for s = 1:length(SPM.Sess)
	for i = 1:length(SPM.Sess(s).Fc)
	    iX0           = 1:nBeta;
	    iX            = SPM.Sess(s).col(SPM.Sess(s).Fc(i).i);
	    iX0(iX)       = [];
	    Fcname        = sprintf('Sess(%d):%s',s,SPM.Sess(s).Fc(i).name);
	    xCon(end + 1) = spm_FcUtil('Set',Fcname,'F','iX0',iX0,xX.xKXs);
	end
    end
end

%-Smoothness estimates of component fields and RESEL counts for volume
%=======================================================================
try
	FWHM = SPM.xVol.FWHM;
	VRpv = SPM.xVol.VRpv;
	R    = SPM.xVol.R;
catch
	[FWHM,VRpv] = spm_est_smoothness(VResI,VM);
	R           = spm_resels_vol(VM,FWHM)';
end

%-Delete the residuals images
%=======================================================================
for  i = 1:nSres,
	spm_unlink([spm_str_manip(VResI(i).fname,'r') '.img']);
	spm_unlink([spm_str_manip(VResI(i).fname,'r') '.hdr']);
	spm_unlink([spm_str_manip(VResI(i).fname,'r') '.mat']);
end


%-Compute scaled design matrix for display purposes
%-----------------------------------------------------------------------
xX.nKX        = spm_DesMtx('sca',xX.xKXs.X,xX.name);


fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#

%-Save remaining results files and analysis parameters
%=======================================================================
fprintf('%-40s: %30s','Saving results','...writing')                 %-#

%-place fields in SPM
%-----------------------------------------------------------------------
SPM.xVol.XYZ   = XYZ(:,1:S);			%-InMask XYZ coords (voxels)
SPM.xVol.M     = M;				%-voxels -> mm
SPM.xVol.iM    = inv(M);			%-mm -> voxels
SPM.xVol.DIM   = DIM;				%-image dimensions
SPM.xVol.FWHM  = FWHM;				%-Smoothness data
SPM.xVol.R     = R;				%-Resel counts
SPM.xVol.S     = S;				%-Volume (voxels)
SPM.xVol.VRpv  = VRpv;				%-Filehandle - Resels per voxel


SPM.Vbeta      = Vbeta;				%-Filehandle - Beta
SPM.VResMS     = VResMS;			%-Filehandle - Hyperparameter
SPM.VM         = VM;				%-Filehandle - Mask

SPM.xVi        = xVi;				% non-sphericity structure
SPM.xVi.CY     = CY;				%-<(Y - <Y>)*(Y - <Y>)'> 

SPM.xX         = xX;				%-design structure
SPM.xM         = xM;				%-mask structure

SPM.xCon       = xCon;				%-contrast structure

SPM.SPMid      = SPMid;
SPM.swd        = pwd;


%-Save analysis parameters in SPM.mat file
%-----------------------------------------------------------------------
save SPM SPM

%=======================================================================
%- E N D: Cleanup GUI
%=======================================================================
fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#
spm('FigName','Stats: done',Finter); spm('Pointer','Arrow')
fprintf('%-40s: %30s\n','Completed',spm('time'))                     %-#
fprintf('...use the results section for assessment\n\n')             %-#
