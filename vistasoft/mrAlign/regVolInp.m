function [rot, trans, Mf, W] = regVolInp(vol, inp, scaleFac, Rinit, Tinit, NCoarseIter, IntFunc, PbyPflag);
% regVolInp - Main registration routine.
%
% INPUT:
% - vol: volume
% - inp: anatomy inplanes
% - scaleFac: 2x3 matrix with the inverse of voxel sizes for the inplanes
%             (first row) and for the volume (second row)
% - Rinit: initial rotation matrix
% - Tinit: initial translation vector
% - NCoarseIter: number of coarse iterations
% - IntFunc: string containing the function used to estimate the intensity
%            gradient.
% - PbyPflag: flag to operate plane-by-plane during intensity correction
%
% OUTPUT:
% - rot: final rotation matrix
% - trans: final translation vector
% - Mf: transformation matrix (from rot and trans) in homogeneous coordinates.
%
% To obtain the coordinates in the volume reference system, this is the
% global transformation:
% Xvol = S2*Mf*inv(S1)*Xinp
% where S2 = [diag(scaleFac(2,:)) zeros(3,1); 0 0 0 1]
%       S1 = [diag(scaleFac(1,:)) zeros(3,1); 0 0 0 1] 
% This is according to the convention used by the routines that interpolate
% the volume in mrAlign2 (e.g., regInplane), which handle by separate the
% voxel sizes (scaleFac) and the rotation and translation
% (rot and trans, or Mf).
%
% Oscar Nestares - 5/99
%

% ON 5/00 - NEW PARAMETER NzLIMIT that controls if slices are replicated or
%           not in the edges. I've put a high value so that almost ALWAYS the
%           slices are replicated before doing the alignment.
%         - Added an alarm when maximum number of iterations is reached, with
%           the possibility of continuing the iterations.

MAXITER = 20;   % maximum number of iterations
MINDISP = 0.1;  % displacement used to end the iterations
CB = 2.5;       % cutoff parameter for robust estimation
SC = 2;         % scaling parameter for robust estimation
Limit = 4;      % saturation value after correcting the contrast
NzLIMIT = 24;   % if the number of inplanes is less that this, then
                % it puts a border by replicating the first and last
                % inplanes two times.

% progress bar
wbh = waitbar(0,'Interpolating Inplanes...');

% size of the inplanes
[NyI, NxI, NzI] = size(inp);

% initial transformation matrix
Mi = [Rinit Tinit(:); 0 0 0 1];
% scale matrix for inplanes
S1 = diag([scaleFac(1,:) 1]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Correcting inplanes for intensity gradient 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inp = regCorrMeanInt(inp);
% intensity estimation
[Int Noise] = feval(IntFunc, inp, PbyPflag); 
% intensity normalization
inpC = regCorrIntGradWiener(inp, Int, Noise);
% robust mean and contrast normalization
inpCN = regCorrContrast(inpC, Limit); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% volume interpolation to initial motion parameters 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inpM = regInplanes(vol, NxI, NyI, NzI, scaleFac, Rinit, Tinit,NaN);
inpM2 = inpM;
inpM2(find(isnan(inpM)))=0;
% intensity estimation
[IntM NoiseM] = feval(IntFunc, inpM2, PbyPflag);
% intensity normalization
inpMC = regCorrIntGradWiener(inpM, IntM, NoiseM);
% robust mean and contrast normalization
[inpMCN, pM] = regCorrContrast(inpMC,Limit); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initial motion estimation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% updating message of the progress bar
set(get(get(wbh,'Children'),'Title'),'String', 'Initial coarse estimation...');
waitbar(1/(MAXITER+1));

% if the number of slices is too small, repeat the first and last slice
% to avoid running out of data (the derivative computation discards the
% borders in z, tipically 2 slices at the begining and 2 more at the end)
if NzI<NzLIMIT
   inpMCN = cat(3,inpMCN(:,:,1),inpMCN(:,:,1),inpMCN,...
                  inpMCN(:,:,end),inpMCN(:,:,end));
   inpCN = cat(3,inpCN(:,:,1),inpCN(:,:,1),inpCN,...
                 inpCN(:,:,end),inpCN(:,:,end));
end

% estimation of the motion at coarse scale
if NCoarseIter>0
   M = estMotionMulti3(inpMCN, inpCN,...
			[0 NCoarseIter],... % iterations per level
			[],...	      % initial M
                        1,...         % rotFlag
			1,...         % robustFlag
                        CB,...        % cutoff parameter for robust estimation
                        SC);          % scale parameter for robust estimation
else
   M = eye(4);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% refinement of the motion estimate re-interpolating from the volume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% loop until the approximate maximum displacement is less than MINDISP,
% or the maximum number of iterations is reached
% The maximum displacement is calculated aproximately from the sum of
% terms: the displacement corresponding to the rotation of the farthest
% point in the inplanes, plus the norm of the translation.
TOTiter = 0;
UserResponse = 'Yes';
while strcomp(UserResponse, 'Yes')
niter = 0;

while (( ((norm([NxI;NyI;NzI]-M(1:3,1:3)*[NxI;NyI;NzI])...
        +norm(M(1:3,4)))>MINDISP) & niter<MAXITER) | (niter==0))

    disp=(norm([NxI;NyI;NzI]-M(1:3,1:3)*[NxI;NyI;NzI])+norm(M(1:3,4)))
    
   % updating number of iterations and message in progress bar
   niter = niter+1;
   TOTiter = TOTiter+1;
   set(get(get(wbh,'Children'),'Title'),'String',...
                  ['Refinement, iter = ',num2str(TOTiter),'...']);
   waitbar((niter+1)/(MAXITER+1));

   % new initial transformation matrix including the estimated matrix
   Mi = Mi*inv(S1)*inv(M)*S1;

   % interpolation and intensity correction
   inpM = regInplanes(vol, NxI, NyI, NzI, scaleFac, Mi(1:3,1:3), Mi(1:3,4),NaN);
   inpM2 = inpM;
   inpM2(find(isnan(inpM)))=0;
   [IntM NoiseM] = feval(IntFunc, inpM2, PbyPflag);
   inpMC = regCorrIntGradWiener(inpM, IntM, NoiseM);
   [inpMCN pM] = regCorrContrast(inpMC, Limit, pM);

   if NzI<NzLIMIT
      inpMCN = cat(3,inpMCN(:,:,1),inpMCN(:,:,1),inpMCN,...
                     inpMCN(:,:,end),inpMCN(:,:,end));
   end
   % motion estimation (no multiresolution, no iterative)
   [M W] = estMotion3(inpMCN, inpCN,...
                        1,...	      % rotFlag
			1,...	      % robustFlag
                        CB,...        % cutoff parameter for robust estimation
                        SC);          % scale parameter for robust estimation
end
if (niter == MAXITER)
   % question asking if we should continue iterating
   QUEST = strvcat(['Maximum number of iterations (',num2str(MAXITER),') reached.'], '          CONTINUE ITERATING?');
   UserResponse = questdlg(QUEST, 'WARNING', 'Yes', 'No', 'No');
else
   UserResponse = 'No';
end
end

close(wbh);
% final transformation matrix
Mf = Mi*inv(S1)*inv(M)*S1;
rot = Mf(1:3,1:3);
trans =  Mf(1:3,4)';

